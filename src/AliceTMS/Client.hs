{-# LANGUAGE OverloadedStrings #-}

module AliceTMS.Client
  ( bookShipment
  , bookShipmentV1
  , checkStatus
  , getLabel
  , getEvents
  , newManager
  ) where

import AliceTMS.Error
import AliceTMS.Types

import Data.Aeson (FromJSON, ToJSON, eitherDecode, encode)
import qualified Data.ByteString as BS
import qualified Data.Text.Encoding as TE
import Network.HTTP.Client hiding (newManager)
import qualified Network.HTTP.Client as HC
import Network.HTTP.Client.TLS (tlsManagerSettings)
import Network.HTTP.Types.Status (statusCode)

type QueryParams = [(BS.ByteString, Maybe BS.ByteString)]

-- | Create a TLS-capable HTTP manager.
newManager :: IO Manager
newManager = HC.newManager tlsManagerSettings

mkApiParams :: Config -> QueryParams -> QueryParams
mkApiParams cfg extra = ("apiKey", Just (TE.encodeUtf8 (apiKey cfg))) : extra

mkGetRequest :: Config -> String -> QueryParams -> IO Request
mkGetRequest cfg urlPath extra = do
  req <- parseRequest (baseUrl cfg <> urlPath)
  pure $ setQueryString (mkApiParams cfg extra) req

doRequest :: FromJSON a => Manager -> Request -> IO (Either AliceTMSError a)
doRequest mgr req = do
  resp <- httpLbs req mgr
  let sc = statusCode (responseStatus resp)
      body = responseBody resp
  if sc >= 200 && sc < 300
    then case eitherDecode body of
      Left err  -> pure $ Left (JsonDecodeError err)
      Right val -> pure $ Right val
    else pure $ Left (HttpError sc body)

mkPostRequest :: ToJSON body => Config -> String -> body -> IO Request
mkPostRequest cfg urlPath body = do
  initReq <- parseRequest (baseUrl cfg <> urlPath)
  pure $ setQueryString (mkApiParams cfg []) $ initReq
    { method = "POST"
    , requestBody = RequestBodyLBS (encode body)
    , requestHeaders = [("Content-Type", "application/json")]
    }

-- | Book a shipment (V2).
bookShipment :: Manager -> Config -> BookShipmentRequest -> IO (Either AliceTMSError BookShipmentResponse)
bookShipment mgr cfg body = do
  req <- mkPostRequest cfg "/bookings/v2/bookShipment" body
  doRequest mgr req

-- | Book a shipment (V1).
bookShipmentV1 :: Manager -> Config -> BookShipmentRequest -> IO (Either AliceTMSError BookShipmentResponse)
bookShipmentV1 mgr cfg body = do
  req <- mkPostRequest cfg "/bookings/v1/bookShipment" body
  doRequest mgr req

-- | Check the processing status of a booking.
checkStatus :: Manager -> Config -> TrackingNumber -> IO (Either AliceTMSError CheckStatusResponse)
checkStatus mgr cfg tn = do
  req <- mkGetRequest cfg "/bookings/v1/status"
    [("trackingNumber", Just (TE.encodeUtf8 (unTrackingNumber tn)))]
  doRequest mgr req

-- | Retrieve the label URI for a shipment.
getLabel :: Manager -> Config -> ShipmentId -> IO (Either AliceTMSError GetLabelResponse)
getLabel mgr cfg sid = do
  req <- mkGetRequest cfg "/bookings/v1/label"
    [("shipmentId", Just (TE.encodeUtf8 (unShipmentId sid)))]
  doRequest mgr req

-- | Retrieve tracking events for a shipment.
getEvents :: Manager -> Config -> ShipmentId -> IO (Either AliceTMSError GetEventsResponse)
getEvents mgr cfg sid = do
  req <- mkGetRequest cfg "/bookings/v1/Events"
    [("shipmentId", Just (TE.encodeUtf8 (unShipmentId sid)))]
  doRequest mgr req
