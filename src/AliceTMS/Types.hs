{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}

module AliceTMS.Types
  ( Config(..)
    -- * V2 Book Shipment
  , BookShipmentRequest(..)
  , CommandAddress(..)
  , CommandColli(..)
  , DangerousGoods(..)
  , BookShipmentResponse(..)
    -- * Queries
  , CheckStatusResponse(..)
  , GetLabelResponse(..)
  , GetEventsResponse(..)
  , Scan(..)
  ) where

import Data.Aeson
import Data.Char (toLower)
import Data.Text (Text)
import Data.Time (Day, TimeOfDay, UTCTime)
import GHC.Generics (Generic)

-- | API connection configuration.
data Config = Config
  { baseUrl :: String
  , apiKey  :: Text
  } deriving (Show)

-- | JSON options that omit Nothing fields.
jsonOpts :: Options
jsonOpts = defaultOptions { omitNothingFields = True }

-- | JSON options that strip a prefix and lower-case the remainder.
prefixOpts :: Int -> Options
prefixOpts n = jsonOpts
  { fieldLabelModifier = \s -> case drop n s of
      []     -> s
      (c:cs) -> toLower c : cs
  }

-- --------------------------------------------------------------------
-- V2 Book Shipment
-- --------------------------------------------------------------------

data BookShipmentRequest = BookShipmentRequest
  { waybillNo              :: Maybe Text
  , collis                 :: Maybe [CommandColli]
  , note                   :: Maybe Text
  , reference1             :: Maybe Text
  , reference2             :: Maybe Text
  , reference3             :: Maybe Text
  , pickupDate             :: Maybe Day
  , deliveryDate           :: Maybe Day
  , pickupTimeStart        :: Maybe TimeOfDay
  , pickupTimeEnd          :: Maybe TimeOfDay
  , deliveryTimeStart      :: Maybe TimeOfDay
  , deliveryTimeEnd        :: Maybe TimeOfDay
  , services               :: Maybe [Text]
  , senderAddress          :: Maybe CommandAddress
  , recipientAddress       :: Maybe CommandAddress
  , fullExchangePallets    :: Maybe Int
  , halfExchangePallets    :: Maybe Int
  , quarterExchangePallets :: Maybe Int
  , ready                  :: Maybe Bool
  } deriving (Show, Generic)

instance ToJSON BookShipmentRequest where
  toJSON = genericToJSON jsonOpts
instance FromJSON BookShipmentRequest where
  parseJSON = genericParseJSON jsonOpts

data CommandAddress = CommandAddress
  { street        :: Maybe Text
  , zipCode       :: Maybe Text
  , city          :: Maybe Text
  , countryCode   :: Maybe Text
  , name          :: Maybe Text
  , contactPerson :: Maybe Text
  , contactEmail  :: Maybe Text
  , contactPhone  :: Maybe Text
  , note          :: Maybe Text
  } deriving (Show, Generic)

instance ToJSON CommandAddress where
  toJSON = genericToJSON jsonOpts
instance FromJSON CommandAddress where
  parseJSON = genericParseJSON jsonOpts

-- | Fields prefixed with @colli@ to avoid the reserved word @type@.
data CommandColli = CommandColli
  { colliType           :: Maybe Text
  , colliDescription    :: Maybe Text
  , colliBarcodes       :: Maybe [Text]
  , colliHeight         :: Maybe Double
  , colliLength         :: Maybe Double
  , colliWidth          :: Maybe Double
  , colliVolume         :: Maybe Double
  , colliLoadMeter      :: Maybe Double
  , colliWeight         :: Maybe Double
  , colliDangerousGoods :: Maybe [DangerousGoods]
  } deriving (Show, Generic)

instance ToJSON CommandColli where
  toJSON = genericToJSON (prefixOpts 5)
instance FromJSON CommandColli where
  parseJSON = genericParseJSON (prefixOpts 5)

-- | Fields prefixed with @dg@ to avoid the reserved word @class@.
data DangerousGoods = DangerousGoods
  { dgName              :: Text
  , dgUnNumber          :: Text
  , dgTunnelCode        :: Maybe Text
  , dgClass             :: Maybe Text
  , dgWaybillString     :: Text
  , dgPackageGroup      :: Maybe Text
  , dgTransportCategory :: Maybe Text
  , dgImdg              :: Maybe Text
  , dgLiquid            :: Maybe Bool
  , dgEnvironmental     :: Maybe Bool
  , dgNetWeightKg       :: Maybe Double
  , dgGrossWeightKg     :: Maybe Double
  , dgVolumeM3          :: Maybe Double
  , dgColliQuantity     :: Maybe Int
  , dgPackaging         :: Maybe Text
  , dgPoint             :: Maybe Int
  } deriving (Show, Generic)

instance ToJSON DangerousGoods where
  toJSON = genericToJSON (prefixOpts 2)
instance FromJSON DangerousGoods where
  parseJSON = genericParseJSON (prefixOpts 2)

-- --------------------------------------------------------------------
-- Responses
-- --------------------------------------------------------------------

data BookShipmentResponse = BookShipmentResponse
  { trackingNumber :: Maybe Text
  , shipmentId     :: Maybe Text
  , labelData      :: Maybe Text
  , wayBillNo      :: Maybe Text
  , trackAndTrace  :: Maybe Text
  } deriving (Show, Generic)

instance ToJSON BookShipmentResponse where
  toJSON = genericToJSON jsonOpts
instance FromJSON BookShipmentResponse where
  parseJSON = genericParseJSON jsonOpts

data CheckStatusResponse = CheckStatusResponse
  { status            :: Maybe Text
  , startedProcessing :: Maybe UTCTime
  , failed            :: Maybe UTCTime
  , completed         :: Maybe UTCTime
  } deriving (Show, Generic)

instance ToJSON CheckStatusResponse where
  toJSON = genericToJSON jsonOpts
instance FromJSON CheckStatusResponse where
  parseJSON = genericParseJSON jsonOpts

data GetLabelResponse = GetLabelResponse
  { labelUri :: Maybe Text
  } deriving (Show, Generic)

instance ToJSON GetLabelResponse where
  toJSON = genericToJSON jsonOpts
instance FromJSON GetLabelResponse where
  parseJSON = genericParseJSON jsonOpts

data GetEventsResponse = GetEventsResponse
  { waybillNo     :: Maybe Text
  , trackAndTrace :: Maybe Text
  , scans         :: Maybe [Scan]
  } deriving (Show, Generic)

instance ToJSON GetEventsResponse where
  toJSON = genericToJSON jsonOpts
instance FromJSON GetEventsResponse where
  parseJSON = genericParseJSON jsonOpts

data Scan = Scan
  { scanDateTime :: Maybe UTCTime
  , scanType     :: Maybe Text
  , barcode      :: Maybe Text
  , podText      :: Maybe Text
  , podImage     :: Maybe Text
  , longitude    :: Maybe Double
  , latitude     :: Maybe Double
  } deriving (Show, Generic)

instance ToJSON Scan where
  toJSON = genericToJSON jsonOpts
instance FromJSON Scan where
  parseJSON = genericParseJSON jsonOpts
