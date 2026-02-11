module AliceTMS.Validation
  ( validateColliDimensions
  ) where

import AliceTMS.Types.Request (BookShipmentRequest(..), CommandColli(..))
import Data.Maybe (catMaybes, fromMaybe)

-- | Max colli dimensions in meters (standard European trailer).
maxLength_, maxWidth_, maxHeight_ :: Double
maxLength_ = 14.0
maxWidth_  = 2.6
maxHeight_ = 3.0

-- | Validate that all colli dimensions are within truck limits.
-- Returns a list of human-readable error messages (empty = valid).
validateColliDimensions :: BookShipmentRequest -> [String]
validateColliDimensions req =
  let items = fromMaybe [] (collis req)
  in concatMap checkColli (zip [1::Int ..] items)
  where
    checkColli (i, c) = catMaybes
      [ check i "length" maxLength_ =<< colliLength c
      , check i "width"  maxWidth_  =<< colliWidth c
      , check i "height" maxHeight_ =<< colliHeight c
      ]
    check i dim maxVal val
      | val < 0     = Just $ "colli #" <> show i <> " " <> dim <> " is negative (" <> show val <> "m)"
      | val > maxVal = Just $ "colli #" <> show i <> " " <> dim <> " is " <> show val <> "m, max is " <> show maxVal <> "m"
      | otherwise    = Nothing
