module Main where

import AliceTMS.CLI (Command(..), Opts(..), runCLI)
import AliceTMS.Client (bookShipment, bookShipmentV1, checkStatus, getEvents, getLabel, newManager)
import AliceTMS.Types (Config(..))

import Data.Aeson (ToJSON, eitherDecode, encode)
import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString.Lazy.Char8 as LBS8
import qualified Data.Text as T
import System.Environment (lookupEnv)
import System.Exit (exitFailure)
import System.IO (hPutStrLn, stderr)

main :: IO ()
main = do
  opts <- runCLI

  mKey <- lookupEnv "ALICE_TMS_API_KEY"
  key <- case mKey of
    Nothing -> exitErr "ALICE_TMS_API_KEY environment variable not set"
    Just k  -> pure (T.pack k)

  let cfg = Config (optBaseUrl opts) key
  mgr <- newManager

  case optCommand opts of
    Book path -> do
      raw <- if path == "-" then LBS.getContents else LBS.readFile path
      case eitherDecode raw of
        Left err  -> exitErr $ "Invalid JSON: " <> err
        Right req -> bookShipment mgr cfg req >>= printResult

    BookV1 path -> do
      raw <- if path == "-" then LBS.getContents else LBS.readFile path
      case eitherDecode raw of
        Left err  -> exitErr $ "Invalid JSON: " <> err
        Right req -> bookShipmentV1 mgr cfg req >>= printResult

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
