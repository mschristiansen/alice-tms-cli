module AliceTMS.Config
  ( Config(..)
  , ApiKey(..)
  , BaseUrl(..)
  , TrackingNumber(..)
  , ShipmentId(..)
  , defaultBaseUrl
  ) where

import Data.Text (Text)

-- | API key for authentication.
newtype ApiKey = ApiKey { unApiKey :: Text }
  deriving (Show, Eq)

-- | Base URL for the API.
newtype BaseUrl = BaseUrl { unBaseUrl :: String }
  deriving (Show, Eq)

-- | API connection configuration.
data Config = Config
  { baseUrl :: BaseUrl
  , apiKey  :: ApiKey
  } deriving (Show)

newtype TrackingNumber = TrackingNumber { unTrackingNumber :: Text }
  deriving (Show, Eq)

newtype ShipmentId = ShipmentId { unShipmentId :: Text }
  deriving (Show, Eq)

-- | Default API base URL.
defaultBaseUrl :: BaseUrl
defaultBaseUrl = BaseUrl "https://api.alicetms.net"
