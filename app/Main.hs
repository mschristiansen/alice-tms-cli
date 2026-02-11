module Main where

import AliceTMS.CLI (Command(..), Opts(..), runCLI)
import AliceTMS.Client (bookShipment, bookShipmentV1, checkStatus, getEvents, getLabel, newManager)
import AliceTMS.Types (Config(..), BookShipmentRequest(..), CommandColli(..))

import Configuration.Dotenv (defaultConfig, loadFile)
import Control.Monad (void, when)
import Data.Aeson (ToJSON, eitherDecode, encode)
import Data.Maybe (fromMaybe, mapMaybe)
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
    Nothing  -> maybe defaultBaseUrl id <$> lookupEnv "ALICE_TMS_BASE_URL"

  let cfg = Config baseUrl key
  mgr <- newManager

  case optCommand opts of
    Book path -> do
      raw <- if path == "-" then LBS.getContents else LBS.readFile path
      case eitherDecode raw of
        Left err  -> exitErr $ "Invalid JSON: " <> err
        Right req -> do
          validateColliDimensions req
          bookShipment mgr cfg req >>= printResult

    BookV1 path -> do
      raw <- if path == "-" then LBS.getContents else LBS.readFile path
      case eitherDecode raw of
        Left err  -> exitErr $ "Invalid JSON: " <> err
        Right req -> do
          validateColliDimensions req
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

-- | Max colli dimensions in meters (standard European trailer).
maxLength, maxWidth, maxHeight :: Double
maxLength = 14.0
maxWidth  = 2.6
maxHeight = 3.0

-- | Validate that all colli dimensions are within truck limits.
-- Dimensions are expected in meters.
validateColliDimensions :: BookShipmentRequest -> IO ()
validateColliDimensions req = do
  let items = fromMaybe [] (collis req)
      errors = concatMap checkColli (zip [1::Int ..] items)
  mapM_ (exitErr . ("Colli dimension out of range: " <>)) errors
  where
    checkColli (i, c) = mapMaybe id
      [ check i "length" maxLength =<< colliLength c
      , check i "width"  maxWidth  =<< colliWidth c
      , check i "height" maxHeight =<< colliHeight c
      ]
    check i dim maxVal val
      | val < 0     = Just $ "colli #" <> show i <> " " <> dim <> " is negative (" <> show val <> "m)"
      | val > maxVal = Just $ "colli #" <> show i <> " " <> dim <> " is " <> show val <> "m, max is " <> show maxVal <> "m"
      | otherwise    = Nothing
