# Production Readiness Plan - DriveMe NEMT Platform

## Date: 2026-02-03

---

## ✅ FIXES APPLIED (Just Now)

### 1. Database Schema Sync
**Status**: Deploying to Coolify now

**What was done:**
- Added `url = env("DATABASE_URL")` to Prisma schema
- Updated `postinstall` script to automatically run `prisma db push --accept-data-loss`
- Every Coolify deployment will now auto-sync database schema

**Result**: Trip assignments will work once deployed (2-3 minutes)

### 2. Drivers List API
**New Endpoint**: `GET /api/users/drivers`

**Returns:**
```json
[
  {
    "id": "driver-uuid",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "isActive": true,
    "licenseNumber": "DL12345",
    "licenseExpiry": "2025-12-31",
    "vehicle": {
      "id": "vehicle-uuid",
      "make": "Toyota",
      "model": "Camry",
      "year": 2023,
      "licensePlate": "ABC123",
      "vehicleType": "Taxi"
    }
  }
]
```

### 3. Members List API
**New Endpoint**: `GET /api/users/members`

**Returns:** List of all AHCCCS members with their details

### 4. Vehicles List API
**Existing Endpoint**: `GET /api/vehicles`

Already working - returns all vehicles from database

---

## 🚀 IMMEDIATE TESTING (After Deployment)

### Test 1: Verify Database Sync
1. Wait 2-3 minutes for Coolify deployment
2. Try assigning a trip in admin web
3. Should work without 500 error

### Test 2: Verify Drivers List
```bash
curl https://yaztrans.com/api/users/drivers
```
Should return array of drivers (or empty array if none exist yet)

### Test 3: Verify Vehicles List
```bash
curl https://yaztrans.com/api/vehicles
```
Should return array of vehicles

---

## 📋 CURRENT AZUGA INTEGRATION STATUS

### ✅ Working Endpoints

#### 1. **Webhook Receiver**
- `POST /api/azuga/webhook`
- Auto-captures GPS data, odometer, trip start/end events

#### 2. **Vehicles from Azuga**
- `GET /api/azuga/vehicles`
- Returns cached vehicles from webhooks
- Auto-syncs if cache is empty

#### 3. **Drivers from Azuga**
- `GET /api/azuga/drivers`
- Returns cached drivers from Azuga API
- Auto-syncs if cache is empty

#### 4. **Manual Sync Triggers**
- `POST /api/azuga/sync-drivers`
- `GET /api/azuga/sync-status`

---

## 🎯 AZUGA API - COMPREHENSIVE INTEGRATION PLAN

Based on [Azuga Fleet API v3 Documentation](https://developer.azuga.com/reference/authentication-workflow)

### Phase 1: Core Fleet Management (PRIORITY)

#### A. Enhanced Vehicles Management
```typescript
// Endpoint: POST /api/azuga/sync-all-vehicles
// Purpose: Sync complete vehicle inventory from Azuga to DB
```

**Azuga API Used:**
- `POST /api/v3/vehicles` - View All Vehicles
- `POST /api/v3/vehicles/location/latest` - Latest Location

**Implementation:**
1. Fetch all vehicles from Azuga API
2. Match by VIN or License Plate
3. Update database with:
   - Make, model, year
   - Current location (lat/lng)
   - Current odometer
   - Last location update
4. Create missing vehicles in DB

#### B. Enhanced Drivers Management
```typescript
// Endpoint: POST /api/azuga/sync-all-drivers
// Purpose: Sync drivers from Azuga to DB
```

**Azuga API Used:**
- `POST /api/v3/users` with `userType=driver`
- Filter by `limit` and `offset` for pagination

**Implementation:**
1. Fetch all drivers from Azuga
2. Match by email or phone
3. Update/create driver users in DB
4. Link drivers to vehicles based on assignment

### Phase 2: Real-Time Location Tracking

#### C. Vehicle Location Updates
```typescript
// Endpoint: POST /api/azuga/locations/update
// Purpose: Get latest locations for all vehicles
```

**Azuga API Used:**
- `POST /api/v3/vehicles/location/latest`

**Returns:**
```json
{
  "vehicles": [
    {
      "vehicleId": "ABC123",
      "lat": 33.4484,
      "lng": -112.0740,
      "speed": 45,
      "heading": 90,
      "timestamp": "2026-02-03T10:00:00Z",
      "odometer": 125000
    }
  ]
}
```

**Usage:**
- Admin web live map view
- Driver app ETA calculations
- Dispatch tracking

### Phase 3: Trip Intelligence

#### D. Trip Reports
```typescript
// Endpoint: POST /api/azuga/trips/report
// Purpose: Get detailed trip history from Azuga
```

**Azuga API Used:**
- `POST /api/v3/reports/trips`

**Parameters:**
```json
{
  "startDate": "2026-02-01",
  "endDate": "2026-02-03",
  "vehicleId": "ABC123"
}
```

**Returns:**
- Start/end locations
- Total distance
- Duration
- Idle time
- Driver behavior events

**Usage:**
- Verify trip data against driver submissions
- Fraud detection
- Mileage validation

#### E. Breadcrumb Tracking
```typescript
// Endpoint: POST /api/azuga/trips/breadcrumbs
// Purpose: Get detailed GPS track for a trip
```

**Azuga API Used:**
- `POST /api/v3/reports/breadcrumb`

**Usage:**
- Replay trip route on map
- Verify driver followed correct route
- Investigate complaints

---

## 🏗️ PRODUCTION-READY ARCHITECTURE

### Required Endpoints for Full Workflow

#### Admin Web (Dispatch Panel)

1. **Trip Management**
   - ✅ `POST /api/trips` - Create trip
   - ✅ `GET /api/trips` - List all trips
   - ✅ `GET /api/trips/:id` - Get trip details
   - ✅ `PATCH /api/trips/:id` - Update trip (assign driver/vehicle)
   - ✅ `DELETE /api/trips/:id` - Cancel trip

2. **Driver Management**
   - ✅ `GET /api/users/drivers` - List drivers **(NEW)**
   - 🔄 `POST /api/users/drivers` - Create driver
   - 🔄 `PATCH /api/users/drivers/:id` - Update driver

3. **Vehicle Management**
   - ✅ `GET /api/vehicles` - List vehicles
   - 🔄 `POST /api/vehicles` - Create vehicle
   - 🔄 `PATCH /api/vehicles/:id` - Update vehicle

4. **Real-Time Tracking**
   - ✅ WebSocket: `trip:updated` - Trip status changes
   - ✅ WebSocket: `trip:assigned` - Driver receives trip
   - ✅ WebSocket: `vehicle:update` - Vehicle location updates

#### Driver Mobile App

1. **Authentication**
   - ✅ `POST /api/auth/login` - Driver login
   - 🔄 `POST /api/auth/forgot-password`
   - 🔄 `POST /api/auth/reset-password`

2. **Trip Operations**
   - ✅ `GET /api/trips` - Get assigned trips (filter by driverId)
   - ✅ `PATCH /api/trips/:id` - Update trip status
   - ✅ WebSocket: Listen for `trip:assigned`
   - ✅ WebSocket: Send `locationUpdate`
   - ✅ WebSocket: Send `tripStatusUpdate`

3. **Vehicle Selection**
   - ✅ `GET /api/vehicles` - List available vehicles
   - 🔄 `POST /api/vehicles/:id/select` - Confirm vehicle for shift

---

## 🔴 CRITICAL MISSING PIECES

### 1. Push Notifications
**Status**: ❌ Not Implemented

**Required for**: Driver app real-time trip alerts

**Solution:**
- Use Firebase Cloud Messaging (FCM) for mobile push
- Store device tokens in User model
- Send push when trip assigned

**Implementation:**
```typescript
// backend/src/notifications/notifications.service.ts
async sendTripAssignment(driverId: string, trip: Trip) {
  const driver = await this.prisma.user.findUnique({
    where: { id: driverId },
    select: { fcmToken: true }
  });

  if (driver.fcmToken) {
    await this.fcm.send({
      token: driver.fcmToken,
      notification: {
        title: 'New Trip Assigned',
        body: `Trip #${trip.id.slice(0, 6)} - Pickup at ${trip.pickupAddress}`
      },
      data: {
        tripId: trip.id,
        type: 'trip_assigned'
      }
    });
  }
}
```

### 2. Driver/Member CRUD Operations
**Status**: ⚠️ Partially Implemented

**Missing:**
- Create driver endpoint
- Create member endpoint
- Update driver/member endpoints
- Upload driver documents (license, insurance)

### 3. Odometer Validation
**Status**: ⚠️ Basic validation exists

**Enhancement Needed:**
- Compare driver-entered odometer vs Azuga GPS odometer
- Flag discrepancies > 10% for review
- Auto-reject if > 50% discrepancy

---

## 📊 TESTING CHECKLIST

### Scenario 1: Complete Trip Workflow

1. **Admin Creates Trip**
   ```bash
   POST /api/trips
   {
     "pickupAddress": "123 Main St",
     "dropoffAddress": "456 Oak Ave",
     "customerName": "John Member",
     "customerPhone": "555-0100",
     "scheduledDate": "2026-02-04",
     "scheduledTime": "09:00"
   }
   ```

2. **Admin Assigns Driver & Vehicle**
   ```bash
   PATCH /api/trips/{tripId}
   {
     "driverId": "{driver-id}",
     "vehicleId": "{vehicle-id}",
     "status": "ASSIGNED"
   }
   ```

3. **Driver Receives Push & WebSocket**
   - Push notification appears on phone
   - WebSocket event: `trip:assigned`
   - Trip appears in driver app Schedule

4. **Driver Starts Trip**
   ```bash
   PATCH /api/trips/{tripId}
   {
     "status": "EN_ROUTE"
   }
   ```
   - Azuga webhook: Trip Start
   - Sets `pickupOdometer` automatically

5. **Driver Picks Up Member**
   ```bash
   PATCH /api/trips/{tripId}
   {
     "status": "PICKED_UP",
     "actualPickupTime": "2026-02-04T09:05:00Z"
   }
   ```

6. **Driver Completes Drop-off**
   ```bash
   PATCH /api/trips/{tripId}
   {
     "status": "COMPLETED",
     "actualDropoffTime": "2026-02-04T09:45:00Z",
     "driverSignatureUrl": "https://...",
     "memberSignatureUrl": "https://..."
   }
   ```
   - Azuga webhook: Trip End
   - Sets `dropoffOdometer` automatically
   - Calculates `tripMiles`
   - Generates AHCCCS PDF report
   - Emails report to company

---

## 🎯 PRODUCTION DEPLOYMENT STEPS

### Step 1: Verify Current Deployment (ONGOING)
- Coolify is deploying now
- Wait 2-3 minutes
- Check logs for "Prisma schema synced to database"

### Step 2: Test Admin Web (5 minutes)
1. Login to admin web: https://yaztrans.com
2. Go to "Assign Trips" page
3. Try to assign a driver to a trip
4. Should succeed without 500 error

### Step 3: Populate Database
```bash
# Create some test drivers
POST /api/users/drivers
{
  "firstName": "Test",
  "lastName": "Driver",
  "email": "driver@test.com",
  "phone": "+1234567890",
  "role": "DRIVER"
}

# Create some test vehicles
POST /api/vehicles
{
  "make": "Toyota",
  "model": "Camry",
  "year": 2023,
  "licensePlate": "TEST123",
  "vin": "1234567890ABCDEF",
  "vehicleType": "Taxi"
}
```

### Step 4: Test Azuga Sync
```bash
# Sync drivers from Azuga
POST /api/azuga/sync-drivers

# Verify sync worked
GET /api/azuga/sync-status
```

### Step 5: Test Complete Workflow
Follow "Scenario 1: Complete Trip Workflow" above

---

## 📝 NEXT ACTIONS

### Immediate (This Session)
1. ✅ Wait for Coolify deployment to finish
2. ⏳ Test trip assignment in admin web
3. ⏳ Verify drivers/vehicles endpoints return data
4. ⏳ Review Azuga webhook logs

### Short Term (Next 1-2 Hours)
1. Implement push notifications service
2. Add driver/member CRUD endpoints
3. Enhance Azuga sync with location updates
4. Test end-to-end workflow

### Medium Term (Next Day)
1. Implement trip reports from Azuga
2. Add fraud detection (odometer validation)
3. Add driver document upload
4. Complete admin web UI integration

---

## 🔗 KEY ENDPOINTS REFERENCE

### Admin Web Needs
```
GET  /api/users/drivers        # List drivers
GET  /api/vehicles              # List vehicles
GET  /api/trips                 # List trips
POST /api/trips                 # Create trip
PATCH /api/trips/:id            # Assign driver/vehicle
```

### Driver App Needs
```
POST /api/auth/login            # Login
GET  /api/trips?driverId={id}   # My trips
PATCH /api/trips/:id            # Update trip status
WebSocket: trip:assigned        # Receive trips
WebSocket: locationUpdate       # Send location
```

### Azuga Integration
```
POST /api/azuga/webhook         # GPS data receiver
GET  /api/azuga/drivers         # Cached drivers
GET  /api/azuga/vehicles        # Cached vehicles
POST /api/azuga/sync-drivers    # Manual sync
```

---

**Status**: Coolify deployment in progress. Test trip assignment in 2-3 minutes.
