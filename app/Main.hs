module Main where

import AliceTMS.CLI (Command(..), Opts(..), runCLI)
import AliceTMS.Client (bookShipment, bookShipmentV1, checkStatus, getEvents, getLabel, newManager)
import AliceTMS.Types (Config(..))
import AliceTMS.Validation (validateColliDimensions)

import Configuration.Dotenv (defaultConfig, loadFile)
import Control.Monad (void, when)
import Data.Aeson (ToJSON, eitherDecode, encode)
import Data.Maybe (fromMaybe)
import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString.Lazy.Char8 as LBS8
import qualified Data.Text as T
import System.Directory (doesFileExist)
import System.Environment (lookupEnv)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

defaultBaseUrl :: String
defaultBaseUrl = "https://api.alicetms.net"

main :: IO ()
main = do
  hasEnv <- doesFileExist ".env"
  when hasEnv $ void (loadFile defaultConfig)

  opts <- runCLI

  mKey <- lookupEnv "ALICE_TMS_API_KEY"
  key <- case mKey of
    Nothing -> exitErr "ALICE_TMS_API_KEY environment variable not set"
    Just k  -> pure (T.pack k)

  baseUrl <- case optBaseUrl opts of
    Just url -> pure url
    Nothing  -> fromMaybe defaultBaseUrl <$> lookupEnv "ALICE_TMS_BASE_URL"

  let cfg = Config baseUrl key
  mgr <- newManager

  case optCommand opts of
    Book path -> do
      raw <- if path == "-" then LBS.getContents else LBS.readFile path
      case eitherDecode raw of
        Left err  -> exitErr $ "Invalid JSON: " <> err
        Right req -> do
          mapM_ (exitErr . ("Colli dimension out of range: " <>)) (validateColliDimensions req)
          bookShipment mgr cfg req >>= printResult

    BookV1 path -> do
      raw <- if path == "-" then LBS.getContents else LBS.readFile path
      case eitherDecode raw of
        Left err  -> exitErr $ "Invalid JSON: " <> err
        Right req -> do
          mapM_ (exitErr . ("Colli dimension out of range: " <>)) (validateColliDimensions req)
          bookShipmentV1 mgr cfg req >>= printResult

    Status tid -> checkStatus mgr cfg tid >>= printResult
    Label  sid -> getLabel mgr cfg sid    >>= printResult
    Events sid -> getEvents mgr cfg sid   >>= printResult

printResult :: ToJSON a => Either String a -> IO ()
printResult (Left err)  = exitErr err
printResult (Right val) = LBS8.putStrLn (encode val)

exitErr :: String -> IO a
exitErr msg = do
  hPutStrLn stderr $ "error: " <> msg
  exitFailure
