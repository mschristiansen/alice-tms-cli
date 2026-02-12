module AliceTMS.CLI
  ( Command(..)
  , Opts(..)
  , runCLI
  ) where

import AliceTMS.Config (TrackingNumber(..), ShipmentId(..))

import qualified Data.Text as T
import Options.Applicative
import Options.Applicative.Help.Pretty (Doc, hardline, pretty)

data Opts = Opts
  { optBaseUrl :: Maybe String
  , optCommand :: Command
  } deriving (Show)

data Command
  = Book FilePath          -- ^ JSON file path, or @-@ for stdin (V2)
  | BookV1 FilePath        -- ^ JSON file path, or @-@ for stdin (V1)
  | Status TrackingNumber  -- ^ tracking number (UUID)
  | Label ShipmentId       -- ^ shipment ID (UUID)
  | Events ShipmentId      -- ^ shipment ID (UUID)
  deriving (Show)

runCLI :: IO Opts
runCLI = execParser parserInfo

parserInfo :: ParserInfo Opts
parserInfo = info (optsP <**> helper)
  (  fullDesc
  <> header "alice-tms - CLI client for the Alice TMS API"
  <> progDesc "Book shipments and track deliveries via the Alice TMS API"
  <> footer "Requires ALICE_TMS_API_KEY environment variable. A .env file in the working directory is auto-loaded if present. Run 'alice-tms book --help' for the JSON request format and example."
  )

optsP :: Parser Opts
optsP = Opts
  <$> optional (strOption
      (  long "base-url"
      <> metavar "URL"
      <> help "API base URL (default: https://api.alicetms.net, or ALICE_TMS_BASE_URL env var)"
      ))
  <*> subparser
      (  command "book"   (bookCmdInfo "Book a shipment (V2)" bookP)
      <> command "book1"  (bookCmdInfo "Book a shipment (V1)" bookV1P)
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
statusP = Status . TrackingNumber . T.pack <$> strOption
  (  long "tracking-number"
  <> short 't'
  <> metavar "UUID"
  <> help "Tracking number from book response"
  )

labelP :: Parser Command
labelP = Label . ShipmentId . T.pack <$> strOption
  (  long "shipment-id"
  <> short 's'
  <> metavar "UUID"
  <> help "Shipment ID from book response"
  )

eventsP :: Parser Command
eventsP = Events . ShipmentId . T.pack <$> strOption
  (  long "shipment-id"
  <> short 's'
  <> metavar "UUID"
  <> help "Shipment ID from book response"
  )

bookCmdInfo :: String -> Parser Command -> ParserInfo Command
bookCmdInfo desc p = info (p <**> helper)
  (  progDesc desc
  <> footerDoc (Just bookExampleDoc)
  )

bookExampleDoc :: Doc
bookExampleDoc = foldl (\a b -> a <> hardline <> b) mempty
               . map pretty
               $ bookExampleLines

bookExampleLines :: [String]
bookExampleLines =
  [ "JSON format (dimensions in meters, weights in kg):"
  , ""
  , "  {"
  , "    \"pickupDate\": \"2025-06-15\","
  , "    \"deliveryDate\": \"2025-06-16\","
  , "    \"reference1\": \"ORDER-123\","
  , "    \"reference2\": \"ORDER-456\","
  , "    \"reference3\": null,"
  , "    \"senderAddress\": {"
  , "      \"name\": \"Warehouse A\","
  , "      \"street\": \"Industrivej 10\","
  , "      \"zipCode\": \"8000\","
  , "      \"city\": \"Aarhus\","
  , "      \"countryCode\": \"DK\","
  , "      \"contactPerson\": \"Hans Jensen\","
  , "      \"contactPhone\": \"+4512345678\","
  , "      \"contactEmail\": \"hans@example.com\","
  , "      \"note\": null"
  , "    },"
  , "    \"recipientAddress\": {"
  , "      \"name\": \"Customer B\","
  , "      \"street\": \"Hovedgaden 5\","
  , "      \"zipCode\": \"2100\","
  , "      \"city\": \"Copenhagen\","
  , "      \"countryCode\": \"DK\""
  , "    },"
  , "    \"collis\": ["
  , "      {"
  , "        \"type\": \"package\","
  , "        \"description\": \"Fragile goods\","
  , "        \"weight\": 12.5,"
  , "        \"length\": 0.6,"
  , "        \"width\": 0.4,"
  , "        \"height\": 0.3,"
  , "        \"barcodes\": [\"PKG001\"]"
  , "      }"
  , "    ],"
  , "    \"fullExchangePallets\": 0,"
  , "    \"halfExchangePallets\": 0,"
  , "    \"quarterExchangePallets\": 0,"
  , "    \"ready\": true"
  , "  }"
  , ""
  , "Required fields: pickupDate, deliveryDate, senderAddress, recipientAddress,"
  , "fullExchangePallets, halfExchangePallets, quarterExchangePallets."
  , "All other fields are optional (omit or set to null)."
  , ""
  , "Response includes shipmentId and trackingNumber for use with status/label/events."
  ]
