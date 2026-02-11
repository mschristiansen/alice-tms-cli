module AliceTMS.Internal.JSON
  ( jsonOpts
  , prefixOpts
  ) where

import Data.Aeson (Options, defaultOptions, omitNothingFields, fieldLabelModifier)
import Data.Char (toLower)

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
