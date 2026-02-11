# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CLI client for the [Alice TMS API](https://api.alicetms.net/swagger/v1/swagger.json) — a transport management system for booking shipments and tracking deliveries. Written in Haskell, built with Cabal.

## Build & Run

```bash
cabal build              # compile
cabal run alice-tms      # run the CLI
cabal run alice-tms -- --help
```

## CLI Usage

Requires `ALICE_TMS_API_KEY` environment variable. Accepts `--base-url` to override the default (`https://api.alicetms.net`).

Also reads `ALICE_TMS_BASE_URL` env var as a fallback when `--base-url` is not passed. A `.env` file in the working directory is auto-loaded if present.

```bash
alice-tms book shipment.json           # book from file (V2 endpoint)
alice-tms book                         # book from stdin (V2)
alice-tms book1 shipment.json          # book from file (V1 endpoint)
alice-tms book1                        # book from stdin (V1)
alice-tms status -t <tracking-uuid>    # check booking status
alice-tms label -s <shipment-uuid>     # get label URL
alice-tms events -s <shipment-uuid>    # get tracking events
```

## Architecture

```
app/Main.hs                    -- entry point: CLI parsing, env var handling, dispatch
src/AliceTMS/
  Booking.hs                    -- pure decode+validate pipeline for book commands
  CLI.hs                        -- optparse-applicative command definitions
  Client.hs                     -- HTTP client functions (one per API endpoint)
  Config.hs                     -- Config, ApiKey, BaseUrl, TrackingNumber, ShipmentId
  Error.hs                      -- AliceTMSError ADT and formatError
  Validation.hs                 -- pure colli dimension validation
  Types/
    Request.hs                  -- BookShipmentRequest, CommandAddress, CommandColli, DangerousGoods
    Response.hs                 -- BookShipmentResponse, CheckStatusResponse, GetLabelResponse, etc.
  Internal/
    JSON.hs                     -- jsonOpts, prefixOpts (not exported from library)
```

**Request type naming conventions**: `CommandColli` fields are prefixed `colli` (e.g. `colliType` → JSON `"type"`) and `DangerousGoods` fields are prefixed `dg` (e.g. `dgClass` → JSON `"class"`) to avoid Haskell reserved words. Prefix stripping is handled by `prefixOpts` in `Internal.JSON` with generic Aeson derivation. All other types use natural field names with `DuplicateRecordFields`.

**Config.hs**: `ApiKey` and `BaseUrl` are newtypes wrapping `Text` and `String` respectively. Use `unApiKey`/`unBaseUrl` to unwrap.

**Client.hs**: API key is passed as query parameter `apiKey` on all requests. GET endpoints use `mkGetRequest` helper; POST uses `mkPostRequest`. All client functions return `Either AliceTMSError a`.

**Booking.hs**: Pure pipeline `decodeAndValidateRequest :: ByteString -> Either AliceTMSError BookShipmentRequest` that decodes JSON then validates colli dimensions. Used by Main.hs for both `book` and `book1` commands.

## API Endpoints Covered

| CLI command | HTTP | Path |
|-------------|------|------|
| `book`      | POST | `/bookings/v2/bookShipment` |
| `book1`     | POST | `/bookings/v1/bookShipment` |
| `status`    | GET  | `/bookings/v1/status` |
| `label`     | GET  | `/bookings/v1/label` |
| `events`    | GET  | `/bookings/v1/Events` |

## Gotchas

- **Colli dimension validation**: `book`/`book1` reject colli with dimensions exceeding European trailer limits (length 14m, width 2.6m, height 3m) or negative values. This is a client-side check before the API call.

## Key Dependencies

- **aeson** — JSON serialization via Generic deriving
- **http-client** + **http-client-tls** — HTTP requests
- **optparse-applicative** — CLI argument parsing
- **time** — `Day`, `TimeOfDay`, `UTCTime` for date/time fields
- **dotenv** — auto-loads `.env` file when present
