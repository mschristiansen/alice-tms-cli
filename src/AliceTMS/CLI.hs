module AliceTMS.CLI
  ( Command(..)
  , Opts(..)
  , runCLI
  ) where

import Data.Text (Text)
import qualified Data.Text as T
import Options.Applicative

data Opts = Opts
  { optBaseUrl :: Maybe String
  , optCommand :: Command
  } deriving (Show)

data Command
  = Book FilePath    -- ^ JSON file path, or @-@ for stdin (V2)
  | BookV1 FilePath  -- ^ JSON file path, or @-@ for stdin (V1)
  | Status Text      -- ^ tracking number (UUID)
  | Label Text       -- ^ shipment ID (UUID)
  | Events Text      -- ^ shipment ID (UUID)
  deriving (Show)

runCLI :: IO Opts
runCLI = execParser parserInfo

parserInfo :: ParserInfo Opts
parserInfo = info (optsP <**> helper)
  (  fullDesc
  <> header "alice-tms - CLI client for the Alice TMS API"
  <> progDesc "Book shipments and track deliveries via the Alice TMS API"
  )

optsP :: Parser Opts
optsP = Opts
  <$> optional (strOption
      (  long "base-url"
      <> metavar "URL"
      <> help "API base URL (default: https://api.alicetms.net, or ALICE_TMS_BASE_URL env var)"
      ))
  <*> subparser
      (  command "book"   (info (bookP   <**> helper) (progDesc "Book a shipment (V2)"))
      <> command "book1"  (info (bookV1P <**> helper) (progDesc "Book a shipment (V1)"))
      <> command "status" (info (statusP <**> helper) (progDesc "Check booking status"))
      <> command "label"  (info (labelP  <**> helper) (progDesc "Get shipment label URL"))
      <> command "events" (info (eventsP <**> helper) (progDesc "Get shipment tracking events"))
      )

bookP :: Parser Command
bookP = Book <$> strArgument
  (  metavar "FILE"
  <> value "-"
  <> help "JSON file with shipment data (- for stdin)"
  )

bookV1P :: Parser Command
bookV1P = BookV1 <$> strArgument
  (  metavar "FILE"
  <> value "-"
  <> help "JSON file with shipment data (- for stdin)"
  )

statusP :: Parser Command
statusP = Status . T.pack <$> strOption
  (  long "tracking-number"
  <> short 't'
  <> metavar "UUID"
  <> help "Tracking number from book response"
  )

labelP :: Parser Command
labelP = Label . T.pack <$> strOption
  (  long "shipment-id"
  <> short 's'
  <> metavar "UUID"
  <> help "Shipment ID from book response"
  )

eventsP :: Parser Command
eventsP = Events . T.pack <$> strOption
  (  long "shipment-id"
  <> short 's'
  <> metavar "UUID"
  <> help "Shipment ID from book response"
  )
