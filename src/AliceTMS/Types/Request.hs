{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module AliceTMS.Types.Request
  ( BookShipmentRequest(..)
  , CommandAddress(..)
  , CommandColli(..)
  , DangerousGoods(..)
  ) where

import AliceTMS.Internal.JSON (jsonOpts, prefixOpts)

import Data.Aeson (FromJSON(..), ToJSON(..), genericParseJSON, genericToJSON)
import Data.Text (Text)
import Data.Time (Day, TimeOfDay)
import GHC.Generics (Generic)

data BookShipmentRequest = BookShipmentRequest
  { waybillNo              :: Maybe Text
  , collis                 :: Maybe [CommandColli]
  , note                   :: Maybe Text
  , reference1             :: Maybe Text
  , reference2             :: Maybe Text
  , reference3             :: Maybe Text
  , pickupDate             :: Day
  , deliveryDate           :: Day
  , pickupTimeStart        :: Maybe TimeOfDay
  , pickupTimeEnd          :: Maybe TimeOfDay
  , deliveryTimeStart      :: Maybe TimeOfDay
  , deliveryTimeEnd        :: Maybe TimeOfDay
  , services               :: Maybe [Text]
  , senderAddress          :: CommandAddress
  , recipientAddress       :: CommandAddress
  , fullExchangePallets    :: Int
  , halfExchangePallets    :: Int
  , quarterExchangePallets :: Int
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
  , colliWeight         :: Double
  , colliDangerousGoods :: Maybe [DangerousGoods]
  } deriving (Show, Generic)

instance ToJSON CommandColli where
  toJSON = genericToJSON (prefixOpts 5)
instance FromJSON CommandColli where
  parseJSON = genericParseJSON (prefixOpts 5)

-- | Fields prefixed with @dg@ to avoid the reserved word @class@.
data DangerousGoods = DangerousGoods
  { dgName              :: Maybe Text
  , dgUnNumber          :: Maybe Text
  , dgTunnelCode        :: Maybe Text
  , dgClass             :: Maybe Text
  , dgWaybillString     :: Maybe Text
  , dgPackageGroup      :: Maybe Text
  , dgTransportCategory :: Maybe Text
  , dgImdg              :: Maybe Text
  , dgLiquid            :: Bool
  , dgEnvironmental     :: Bool
  , dgNetWeightKg       :: Double
  , dgGrossWeightKg     :: Double
  , dgVolumeM3          :: Double
  , dgColliQuantity     :: Int
  , dgPackaging         :: Maybe Text
  , dgPoint             :: Maybe Int
  } deriving (Show, Generic)

instance ToJSON DangerousGoods where
  toJSON = genericToJSON (prefixOpts 2)
instance FromJSON DangerousGoods where
  parseJSON = genericParseJSON (prefixOpts 2)
