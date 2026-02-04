# Azuga GPS Webhook Integration

## Overview
The backend now automatically captures vehicle GPS data, odometer readings, and trip miles from Azuga webhooks.

## Features

### 1. Vehicle Tracking
The webhook captures and updates:
- Current location (latitude/longitude)
- Current speed
- Odometer readings
- Ignition status
- Last location update timestamp

### 2. Automatic Trip Odometer Updates
The system automatically updates trip odometer readings based on vehicle status:

| Trip Status | Action |
|------------|--------|
| `EN_ROUTE` | Sets `pickupOdometer` when trip starts (if not already set) |
| `PICKED_UP` | Updates `dropoffOdometer` continuously |
| `COMPLETED` | Calculates final `tripMiles` = (dropoffOdometer - pickupOdometer) |

### 3. Miles Calculation
Trip miles are automatically calculated when the driver completes the trip:
```
tripMiles = (dropoffOdometer - pickupOdometer) / 10
```
(Azuga typically sends odometer in tenths of miles)

## Webhook Configuration

### Step 1: Get Your Webhook URL
Your webhook endpoint is:
```
https://your-backend-domain.com/azuga/webhook
```

### Step 2: Configure in Azuga Dashboard
1. Log in to your Azuga dashboard
2. Navigate to **Settings > Webhooks** or **Integrations**
3. Add a new webhook with the URL above
4. Select the following event types:
   - Vehicle Location Updates
   - Ignition Events
   - Odometer Updates
   - Trip Events

### Step 3: Configured Event Types
The following Azuga event types are configured and processed:

#### Trip Tracking Events (High Priority)
- **Trip Start** - Captures pickup odometer when driver starts trip
- **Trip End** - Captures dropoff odometer and calculates total miles
- **Trip Address** - Provides location/address updates during trip
- **GPS MESSAGE** - Continuous GPS location updates

#### Safety Events (Monitored)
- **Over Speeding** - Driver exceeds speed limit
- **Hard Acceleration** - Sudden acceleration detected
- **Hard Brake** - Hard braking event detected

#### Vehicle Status Events
- **Connect/Disconnect** - Ignition on/off events
- **Vehicle Pairing** - Vehicle paired with device
- **Stop Time** - Vehicle stopped/idling

#### Other Monitored Events
- **Low Fuel** - Fuel level alert
- **Geofence** - ENTERED_GEOFENCE, EXIT_GEOFENCE, Geofence Timer In
- **Idling Ended** - Idling period ended
- **Posted Speed Alert** - Speed limit zone alert

### Step 4: Webhook Payload Fields
The webhook processor looks for these fields (in order of preference):

**Vehicle Identifier:**
- `vehicleId`, `serialNumber`, `vin`, `assetId`, or `deviceId`

**Location Data:**
- Latitude: `latitude`, `lat`, or `gpsLatitude`
- Longitude: `longitude`, `lng`, or `gpsLongitude`
- Speed: `speed` or `gpsSpeed`

**Odometer Data:**
- `odometer`, `odometerReading`, `currentOdometer`, `totalDistance`, or `mileage`

**Driver Data:**
- Driver Name: `driverName`, `driver.name`, or `driverFirstName` + `driverLastName`
- Driver ID: `driverId` or `driverExternalId`

## Testing the Webhook

### Manual Test
You can test the webhook with a POST request:

```bash
curl -X POST https://your-backend-domain.com/azuga/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "vehicleId": "TEST123",
    "latitude": 33.4484,
    "longitude": -112.0740,
    "speed": 35,
    "odometer": 125000,
    "ignitionStatus": "Ignition On",
    "driverName": "John Doe"
  }'
```

### Check Logs
Monitor the backend logs to see webhook processing:
```bash
# Look for these log messages:
# - "Received Azuga Webhook"
# - "Cached vehicle {name}: {lat}, {lng} @ {speed} mph"
# - "Updating vehicle {id} odometer to {value}"
# - "Auto-set pickup odometer for trip {id}"
# - "Auto-calculated trip miles for trip {id}"
```

## How It Works

### Workflow
1. **Azuga sends webhook** → Event type + Vehicle location + Odometer
2. **Backend processes by event type**:
   - **Trip Start**: Sets `pickupOdometer` for EN_ROUTE trips
   - **GPS MESSAGE**: Updates vehicle location continuously
   - **Trip End**: Sets `dropoffOdometer` and calculates `tripMiles`
   - **Safety Events**: Logs for reporting (future: send alerts)
3. **Real-time updates** → WebSocket broadcasts to connected clients
4. **Trip completion** → Miles automatically calculated

### Example Scenario

#### Complete Trip Flow with Azuga Events:

1. **Driver starts vehicle**
   - Azuga sends: `Connect` event (Ignition On)
   - System: Updates vehicle status

2. **Driver begins trip in app** → Status: `EN_ROUTE`
   - Azuga sends: `Trip Start` event with odometer: 100000
   - System: Sets `pickupOdometer = 100000`

3. **Driver drives to pickup location**
   - Azuga sends: Continuous `GPS MESSAGE` events
   - System: Updates vehicle location in real-time
   - May trigger: `Over Speeding` or `Hard Brake` safety events

4. **Driver picks up passenger** → Status: `PICKED_UP`
   - Azuga sends: `Trip Address` events during drive
   - System: Continues tracking location

5. **Driver completes drop-off in app** → Status: `COMPLETED`
   - Azuga sends: `Trip End` event with odometer: 100150
   - System: Sets `dropoffOdometer = 100150`
   - System: Calculates `tripMiles = (100150 - 100000) / 10 = 15.0 miles`

6. **Driver stops vehicle**
   - Azuga sends: `Stop Time` event
   - Azuga sends: `Disconnect` event (Ignition Off)
   - System: Updates vehicle status

## Troubleshooting

### Odometer not updating?
- Check Azuga webhook payload includes odometer field
- Verify odometer value is numeric and > 0
- Check backend logs for "Updating vehicle {id} odometer" message

### Trip miles not calculating?
- Ensure trip has both `pickupOdometer` and `dropoffOdometer` values
- Verify trip status progression: `EN_ROUTE` → `ARRIVED` → `PICKED_UP` → `COMPLETED`
- Check that `dropoffOdometer` > `pickupOdometer`

### No webhooks received?
- Verify webhook URL is accessible from internet
- Check Azuga dashboard webhook configuration
- Ensure no firewall blocking incoming requests
- Test manually with curl command above

## Environment Variables

Make sure these are set in your `.env`:
```
AZUGA_API_KEY=your_api_key_here
AZUGA_BASE_URL=https://api.azuga.com
```

## Database Schema

Relevant fields in the `Trip` model:
```prisma
model Trip {
  pickupOdometer     Int?    // Set when trip starts (EN_ROUTE)
  dropoffOdometer    Int?    // Updated while PICKED_UP
  tripMiles          Float?  // Calculated on completion

  secondPickupOdometer  Int? // For round trips
  secondDropoffOdometer Int? // For round trips
}
```

Relevant fields in the `Vehicle` model:
```prisma
model Vehicle {
  currentOdometer      Int?      // Updated from webhook
  currentLat           Float?    // Current latitude
  currentLng           Float?    // Current longitude
  currentSpeed         Float?    // Current speed
  lastLocationUpdate   DateTime? // Last update timestamp
}
```

## API Endpoints

### Get Cached Vehicles
```
GET /azuga/vehicles
```
Returns cached vehicle data from webhooks.

### Get Vehicle Locations
```
GET /azuga/vehicles/locations
```
Returns current locations of all vehicles.

### Webhook Receiver
```
POST /azuga/webhook
```
Receives webhook events from Azuga.

## Next Steps

1. Configure the webhook URL in your Azuga dashboard
2. Monitor backend logs to verify webhooks are being received
3. Test with a real trip to see odometer updates
4. Verify trip miles calculation on trip completion
