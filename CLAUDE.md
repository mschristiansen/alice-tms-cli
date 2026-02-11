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
app/Main.hs              -- entry point: CLI parsing, env var handling, dispatch
src/AliceTMS/
  CLI.hs                  -- optparse-applicative command definitions
  Types.hs                -- all API request/response types with Aeson instances
  Client.hs               -- HTTP client functions (one per API endpoint)
```

**Types.hs naming conventions**: `CommandColli` fields are prefixed `colli` (e.g. `colliType` → JSON `"type"`) and `DangerousGoods` fields are prefixed `dg` (e.g. `dgClass` → JSON `"class"`) to avoid Haskell reserved words. Prefix stripping is handled by `prefixOpts` with generic Aeson derivation. All other types use natural field names with `DuplicateRecordFields`.

**Client.hs**: API key is passed as query parameter `apiKey` on all requests. GET endpoints use `mkGetRequest` helper; POST uses inline construction. All client functions return `Either String a`.

## API Endpoints Covered

| CLI command | HTTP | Path |
|-------------|------|------|
| `book`      | POST | `/bookings/v2/bookShipment` |
| `book1`     | POST | `/bookings/v1/bookShipment` |
| `status`    | GET  | `/bookings/v1/status` |
| `label`     | GET  | `/bookings/v1/label` |
| `events`    | GET  | `/bookings/v1/Events` |

## Key Dependencies

- **aeson** — JSON serialization via Generic deriving
- **http-client** + **http-client-tls** — HTTP requests
- **optparse-applicative** — CLI argument parsing
- **time** — `Day`, `TimeOfDay`, `UTCTime` for date/time fields
