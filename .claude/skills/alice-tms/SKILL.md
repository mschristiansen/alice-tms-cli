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

### Book a shipment

```bash
# From a JSON file
alice-tms book shipment.json

# From stdin (pipe or interactive)
echo '{ ... }' | alice-tms book
```

The JSON body is a `BookShipmentRequest`. All fields are optional. Example:

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
      "length": 60,
      "width": 40,
      "height": 30,
      "barcodes": ["PKG001"]
    }
  ],
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

## Typical workflow

1. **Build** a shipment JSON (write to a temp file or pipe directly)
2. **Book** it: `alice-tms book shipment.json`
3. Note the `trackingNumber` and `shipmentId` from the response
4. **Check status**: `alice-tms status -t <trackingNumber>`
5. **Get label**: `alice-tms label -s <shipmentId>`
6. **Track events**: `alice-tms events -s <shipmentId>`

## Global options

- `--base-url URL` — override the API base URL (default: `https://api.alicetms.net`)

## Collis JSON field notes

In the JSON payload, colli fields use short names: `type`, `description`, `barcodes`, `height`, `length`, `width`, `volume`, `loadMeter`, `weight`, `dangerousGoods`. The Haskell types use prefixed names (`colliType`, etc.) but Aeson serialization strips the prefix automatically.

Dangerous goods fields similarly use short JSON names: `name`, `unNumber`, `tunnelCode`, `class`, `waybillString`, `packageGroup`, `transportCategory`, `imdg`, `liquid`, `environmental`, `netWeightKg`, `grossWeightKg`, `volumeM3`, `colliQuantity`, `packaging`, `point`.

## Error handling

- All output goes to stdout as JSON on success
- Errors go to stderr prefixed with `error:`
- HTTP errors show the status code and response body
