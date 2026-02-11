# alice-tms

CLI client for the [Alice TMS API](https://api.alicetms.net/index.html) — book shipments and track deliveries from the terminal.

## Prerequisites

- GHC >= 9.4
- Cabal >= 3.8
- An Alice TMS API key

## Installation

```bash
cabal build
cabal install
```

## Configuration

Set your API key as an environment variable:

```bash
export ALICE_TMS_API_KEY="your-api-key-here"
```

## Usage

```bash
alice-tms book shipment.json           # book a shipment from a JSON file
alice-tms book                         # book from stdin
alice-tms status -t <tracking-uuid>    # check booking status
alice-tms label -s <shipment-uuid>     # get label URL (valid 1 hour)
alice-tms events -s <shipment-uuid>    # get tracking events
```

Use `--base-url` to override the default API endpoint.

### Booking a shipment

Create a JSON file matching the V2 BookShipment schema:

```json
{
  "pickupDate": "2025-03-01",
  "deliveryDate": "2025-03-02",
  "senderAddress": {
    "name": "Sender Co",
    "street": "Vestergade 1",
    "zipCode": "8000",
    "city": "Aarhus",
    "countryCode": "DK"
  },
  "recipientAddress": {
    "name": "Recipient ApS",
    "street": "Nørregade 10",
    "zipCode": "1165",
    "city": "København",
    "countryCode": "DK"
  },
  "collis": [
    {
      "type": "package",
      "description": "Electronics",
      "barcodes": ["PKG-001"],
      "weight": 12.5
    }
  ]
}
```

Then book it:

```bash
alice-tms book shipment.json
```

The response includes `trackingNumber` and `shipmentId` for use with the other commands.

### Workflow

```bash
# 1. Book
alice-tms book shipment.json
# → {"trackingNumber":"...","shipmentId":"...","labelData":"..."}

# 2. Check status (records kept 24 hours)
alice-tms status -t <tracking-number>

# 3. Get label
alice-tms label -s <shipment-id>

# 4. Track events
alice-tms events -s <shipment-id>
```

All commands output JSON to stdout. Errors go to stderr.
