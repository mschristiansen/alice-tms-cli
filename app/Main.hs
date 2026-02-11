module Main where

import AliceTMS.CLI (Command(..), Opts(..), runCLI)
import AliceTMS.Client (bookShipment, bookShipmentV1, checkStatus, getEvents, getLabel, newManager)
import AliceTMS.Error (AliceTMSError(..), formatError)
import AliceTMS.Types (BookShipmentRequest, BookShipmentResponse, Config(Config))
import AliceTMS.Validation (validateColliDimensions)

import Configuration.Dotenv (defaultConfig, loadFile)
import Control.Monad (void, when)
import Data.Aeson (ToJSON, eitherDecode, encode)
import Data.Maybe (fromMaybe)
import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString.Lazy.Char8 as LBS8
import qualified Data.Text as T
import Network.HTTP.Client (Manager)
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
    Nothing -> exitErr (formatError (ConfigError "ALICE_TMS_API_KEY environment variable not set"))
    Just k  -> pure (T.pack k)

  baseUrl <- case optBaseUrl opts of
    Just url -> pure url
    Nothing  -> fromMaybe defaultBaseUrl <$> lookupEnv "ALICE_TMS_BASE_URL"

  let cfg = Config baseUrl key
  mgr <- newManager

  case optCommand opts of
    Book   path -> handleBookCommand mgr cfg bookShipment   path
    BookV1 path -> handleBookCommand mgr cfg bookShipmentV1 path
    Status tid  -> checkStatus mgr cfg tid  >>= printResult
    Label  sid  -> getLabel mgr cfg sid     >>= printResult
    Events sid  -> getEvents mgr cfg sid    >>= printResult

readInput :: FilePath -> IO LBS.ByteString
readInput "-"  = LBS.getContents
readInput path = LBS.readFile path

handleBookCommand :: Manager -> Config
                  -> (Manager -> Config -> BookShipmentRequest -> IO (Either AliceTMSError BookShipmentResponse))
                  -> FilePath -> IO ()
handleBookCommand mgr cfg bookFn path = do
  raw <- readInput path
  case eitherDecode raw of
    Left err  -> exitErr (formatError (JsonDecodeError err))
    Right req -> case validateColliDimensions req of
      []   -> bookFn mgr cfg req >>= printResult
      errs -> exitErr (formatError (ValidationError errs))

printResult :: ToJSON a => Either AliceTMSError a -> IO ()
printResult (Left err)  = exitErr (formatError err)
printResult (Right val) = LBS8.putStrLn (encode val)

exitErr :: String -> IO a
exitErr msg = do
  hPutStrLn stderr $ "error: " <> msg
  exitFailure
