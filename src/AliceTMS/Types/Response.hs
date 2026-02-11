{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}

module AliceTMS.Types.Response
  ( BookShipmentResponse(..)
  , CheckStatusResponse(..)
  , GetLabelResponse(..)
  , GetEventsResponse(..)
  , Scan(..)
  ) where

import AliceTMS.Internal.JSON (jsonOpts)

import Data.Aeson (FromJSON(..), ToJSON(..), genericParseJSON, genericToJSON)
import Data.Text (Text)
import Data.Time (UTCTime)
import GHC.Generics (Generic)

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

newtype GetLabelResponse = GetLabelResponse
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
