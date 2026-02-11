{-# LANGUAGE OverloadedStrings #-}

module AliceTMS.Client
  ( bookShipment
  , checkStatus
  , getLabel
  , getEvents
  , newManager
  ) where

import AliceTMS.Types

import Data.Aeson (FromJSON, eitherDecode, encode)
import qualified Data.ByteString as BS
import qualified Data.Text.Encoding as TE
import Data.Text (Text)
import Network.HTTP.Client hiding (newManager)
import qualified Network.HTTP.Client as HC
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Network.HTTP.Types.Status (statusCode)

type QueryParams = [(BS.ByteString, Maybe BS.ByteString)]

-- | Create a TLS-capable HTTP manager.
newManager :: IO Manager
newManager = HC.newManager tlsManagerSettings

mkGetRequest :: Config -> String -> QueryParams -> IO Request
mkGetRequest cfg urlPath extra = do
  req <- parseRequest (baseUrl cfg <> urlPath)
  let params = ("apiKey", Just (TE.encodeUtf8 (apiKey cfg))) : extra
  pure $ setQueryString params req

doRequest :: FromJSON a => Manager -> Request -> IO (Either String a)
doRequest mgr req = do
  resp <- httpLbs req mgr
  let sc = statusCode (responseStatus resp)
  if sc >= 200 && sc < 300
    then pure $ eitherDecode (responseBody resp)
    else pure $ Left $ "HTTP " <> show sc <> ": " <> show (responseBody resp)

-- | Book a shipment (V2).
bookShipment :: Manager -> Config -> BookShipmentRequest -> IO (Either String BookShipmentResponse)
bookShipment mgr cfg body = do
  initReq <- parseRequest (baseUrl cfg <> "/bookings/v2/bookShipment")
  let params = [("apiKey", Just (TE.encodeUtf8 (apiKey cfg)))]
      req = setQueryString params $ initReq
        { method = "POST"
        , requestBody = RequestBodyLBS (encode body)
        , requestHeaders = [("Content-Type", "application/json")]
        }
  doRequest mgr req

-- | Check the processing status of a booking.
checkStatus :: Manager -> Config -> Text -> IO (Either String CheckStatusResponse)
checkStatus mgr cfg trackingId = do
  req <- mkGetRequest cfg "/bookings/v1/status"
    [("trackingNumber", Just (TE.encodeUtf8 trackingId))]
  doRequest mgr req

-- | Retrieve the label URI for a shipment.
getLabel :: Manager -> Config -> Text -> IO (Either String GetLabelResponse)
getLabel mgr cfg sid = do
  req <- mkGetRequest cfg "/bookings/v1/label"
    [("shipmentId", Just (TE.encodeUtf8 sid))]
  doRequest mgr req

-- | Retrieve tracking events for a shipment.
getEvents :: Manager -> Config -> Text -> IO (Either String GetEventsResponse)
getEvents mgr cfg sid = do
  req <- mkGetRequest cfg "/bookings/v1/Events"
    [("shipmentId", Just (TE.encodeUtf8 sid))]
  doRequest mgr req
