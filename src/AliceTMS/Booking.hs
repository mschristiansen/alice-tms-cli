module AliceTMS.Booking
  ( decodeAndValidateRequest
  ) where

import AliceTMS.Error (AliceTMSError(..))
import AliceTMS.Types.Request (BookShipmentRequest)
import AliceTMS.Validation (validateColliDimensions)

import Data.Aeson (eitherDecode)
import qualified Data.ByteString.Lazy as LBS

-- | Decode JSON into a 'BookShipmentRequest' and validate colli dimensions.
-- Pure pipeline: decode -> validate -> result.
decodeAndValidateRequest :: LBS.ByteString -> Either AliceTMSError BookShipmentRequest
decodeAndValidateRequest raw =
  case eitherDecode raw of
    Left err  -> Left (JsonDecodeError err)
    Right req -> case validateColliDimensions req of
      []   -> Right req
      errs -> Left (ValidationError errs)
