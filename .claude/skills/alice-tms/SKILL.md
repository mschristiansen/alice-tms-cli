---
name: alice-tms
description: Run alice-tms CLI commands to book shipments, check status, get labels, and track events via the Alice TMS API. Use when the user wants to interact with Alice TMS — booking, tracking, labels, or shipment status.
argument-hint: "[command] [args...]"
allowed-tools:
  - Bash
  - Read
  - Write
---

You are operating the `alice-tms` CLI — a Haskell tool for the Alice TMS transport management API.

## Prerequisites

The environment variable `ALICE_TMS_API_KEY` must be set. If a command fails with "ALICE_TMS_API_KEY environment variable not set", ask the user to set it.

The `alice-tms` executable must be installed (via `cabal install`). If the command is not found, run:

```bash
cabal install --overwrite-policy=always
```

## Commands

### Book a shipment (V2)

```bash
# From a JSON file
alice-tms book shipment.json

# From stdin (pipe or interactive)
echo '{ ... }' | alice-tms book
```

### Book a shipment (V1)

```bash
alice-tms book1 shipment.json
echo '{ ... }' | alice-tms book1
```

Both `book` (V2) and `book1` (V1) accept the same JSON body structure but differ in required fields and response. V2 returns additional fields (`labelData`, `wayBillNo`, `trackAndTrace`) in the response.

### Required vs optional fields

**Shipment-level required fields** (both V1 and V2):
- `pickupDate` — date (YYYY-MM-DD)
- `deliveryDate` — date (YYYY-MM-DD)
- `senderAddress` — object (see address fields below)
- `recipientAddress` — object (see address fields below)
- `fullExchangePallets` — integer (use `0` if not applicable)
- `halfExchangePallets` — integer (use `0` if not applicable)
- `quarterExchangePallets` — integer (use `0` if not applicable)

**Shipment-level optional fields:**
- `reference1`, `reference2`, `reference3` — all optional text
- `waybillNo` — optional text
- `note` — optional text
- `collis` — optional array (but you almost always want this)
- `pickupTimeStart`, `pickupTimeEnd`, `deliveryTimeStart`, `deliveryTimeEnd` — optional time (HH:MM:SS)
- `services` — optional array of text
- `ready` — optional boolean

**Address fields** (all optional in the Haskell type, but the API likely expects at least name/street/zip/city/country):
- `name`, `street`, `zipCode`, `city`, `countryCode` — ISO 2-letter country code (e.g. `"DK"`, `"SE"`, `"DE"`)
- `contactPerson`, `contactEmail`, `contactPhone`, `note`

**Colli fields** (both V1 and V2): only `weight` is required. All other colli fields are optional.

**Colli optional fields:** `type`, `description`, `barcodes`, `height`, `length`, `width`, `volume`, `loadMeter`, `dangerousGoods`.

**Colli `type`**: Free-text string — the API does not enforce an enum. Default to `"package"` unless the user specifies otherwise. Other common value: `"pallet"`.

**Exchange pallets**: These represent pallet exchange counts between sender and carrier. Set all three to `0` unless the shipment involves physical pallet exchange (common in Scandinavian/European logistics where carriers swap empty pallets for loaded ones).

**Date defaults**: If the user doesn't specify dates, default to `pickupDate` = today and `deliveryDate` = next business day. For Friday pickups, suggest Monday delivery. Always confirm the dates with the user before booking.

The JSON body is a `BookShipmentRequest`. Example:

```json
{
  "pickupDate": "2025-06-15",
  "deliveryDate": "2025-06-16",
  "reference1": "ORDER-123",
  "senderAddress": {
    "name": "Warehouse A",
    "street": "Industrivej 10",
    "zipCode": "8000",
    "city": "Aarhus",
    "countryCode": "DK",
    "contactPerson": "Hans Jensen",
    "contactPhone": "+4512345678"
  },
  "recipientAddress": {
    "name": "Customer B",
    "street": "Hovedgaden 5",
    "zipCode": "2100",
    "city": "Copenhagen",
    "countryCode": "DK"
  },
  "collis": [
    {
      "type": "package",
      "weight": 12.5,
      "length": 0.6,
      "width": 0.4,
      "height": 0.3,
      "barcodes": ["PKG001"]
    }
  ],
  "fullExchangePallets": 0,
  "halfExchangePallets": 0,
  "quarterExchangePallets": 0,
  "ready": true
}
```

**Response** includes `trackingNumber` and `shipmentId` — save these for subsequent commands.

### Check booking status

```bash
alice-tms status -t <tracking-number-uuid>
```

Returns `status`, `startedProcessing`, `failed`, and `completed` timestamps.

### Get label URL

```bash
alice-tms label -s <shipment-id-uuid>
```

Returns `labelUri` — a URL to download the shipping label.

### Get tracking events

```bash
alice-tms events -s <shipment-id-uuid>
```

Returns `waybillNo`, `trackAndTrace` URL, and a list of `scans` with timestamps, scan types, barcodes, and GPS coordinates.

## Important

**Always ask for final confirmation before executing a booking** (`book` or `book1`). Show the user a summary of the shipment (sender, recipient, dates, collis) and wait for explicit approval before running the command.

## Typical workflow

1. **Build** a shipment JSON (write to a temp file or pipe directly)
2. **Confirm** — show a summary and get explicit user approval
3. **Book** it: `alice-tms book shipment.json`
3. Note the `trackingNumber` and `shipmentId` from the response
4. **Check status**: `alice-tms status -t <trackingNumber>`
5. **Get label**: `alice-tms label -s <shipmentId>`
6. **Track events**: `alice-tms events -s <shipmentId>`

## Global options

- `--base-url URL` — override the API base URL (default: `https://api.alicetms.net`)

## Units

- **Dimensions** (length, width, height): **meters** — e.g. `0.6` for 60 cm. Client-side validation rejects dimensions exceeding European trailer limits (length 14m, width 2.6m, height 3m) or negative values.
- **Weight**: kilograms

## Collis JSON field notes

In the JSON payload, colli fields use short names: `type`, `description`, `barcodes`, `height`, `length`, `width`, `volume`, `loadMeter`, `weight`, `dangerousGoods`. The Haskell types use prefixed names (`colliType`, etc.) but Aeson serialization strips the prefix automatically.

Dangerous goods fields similarly use short JSON names: `name`, `unNumber`, `tunnelCode`, `class`, `waybillString`, `packageGroup`, `transportCategory`, `imdg`, `liquid`, `environmental`, `netWeightKg`, `grossWeightKg`, `volumeM3`, `colliQuantity`, `packaging`, `point`.

## Error handling

- All output goes to stdout as JSON on success
- Errors go to stderr prefixed with `error:`
- HTTP errors show the status code and response body
