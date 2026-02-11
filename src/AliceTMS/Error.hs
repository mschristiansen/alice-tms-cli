module AliceTMS.Error
  ( AliceTMSError(..)
  , formatError
  ) where

import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString.Lazy.Char8 as LBS8

data AliceTMSError
  = HttpError Int LBS.ByteString    -- ^ HTTP status code + response body
  | JsonDecodeError String           -- ^ Aeson parse failure
  | ValidationError [String]         -- ^ Colli dimension errors
  | ConfigError String               -- ^ Missing env var etc.
  deriving (Show, Eq)

formatError :: AliceTMSError -> String
formatError (HttpError code body) =
  "HTTP " <> show code <> ": " <> LBS8.unpack body
formatError (JsonDecodeError msg) =
  "Invalid JSON: " <> msg
formatError (ValidationError errs) =
  unlines (map ("Colli dimension out of range: " <>) errs)
formatError (ConfigError msg) = msg
