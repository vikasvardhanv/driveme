# YazDrive

YazDrive is a comprehensive Non-Emergency Medical Transportation (NEMT) platform designed for compliance with Arizona AHCCCS standards. It bridges the gap between drivers, dispatchers, and healthcare providers using modern real-time technology.

## 🏗 System Architecture

The system is composed of three main parts:

1.  **Mobile App (Flutter)**:
    -   **Consumer**: iOS & Android (Drivers).
    -   **Function**: GPS Tracking, Trip Management, Signature Capture.
    -   **Tech**: Flutter, `google_maps_flutter`, `geolocator`, `socket_io_client`.

2.  **Backend API (NestJS)**:
    -   **Consumer**: Cloud Server.
    -   **Function**: REST API for data, WebSockets for live tracking, PDF Generation.
    -   **Tech**: Node.js, NestJS, Prisma ORM, JWT Auth.
a
3.  **Database (PostgreSQL + PostGIS)**:
    -   **Consumer**: Cloud Database (AWS RDS / Google Cloud SQL).
    -   **Function**: Persistent storage, Spatial queries (e.g., "Find driver within 5 miles").
    -   **Tech**: PostgreSQL 15, PostGIS extension.

## 🚀 How It Works

1.  **Dispatch**: Admin creates a trip in the Web Portal (React/Flutter Web) or API.
2.  **Assignment**: Trip is stored in Postgres. Backend notifies the assigned driver via WebSocket/Push.
3.  **Execution**:
    -   Driver opens the App (iOS/iPad).
    -   Accepts trip -> "Start Trip".
    -   **Live Tracking**: App sends `{lat, lng, speed}` every 10 meters to Backend via WebSocket.
    -   **Storage**: Backend saves location history to PostGIS.
4.  **Completion**:
    -   Driver arrives -> "Complete Trip".
    -   App captures E-Signature.
    -   Backend generates **AHCCCS Daily Trip Report (PDF)** automatically.

## 🛠 Project Structure

-   `/lib`: Flutter Mobile App code.
-   `/backend`: NestJS Server code.
-   `/backend/prisma/schema.prisma`: Database Schema.
-   `/ios`, `/android`: Native configuration.

## 🚦 Roadmap & Pending Implementation

To achieve a fully functional MVP, the following items must be implemented:

### Phase 1: Backend Foundation (Active)
-   [x] **Scaffold NestJS Project** (`/backend`)
-   [x] **Database Schema** (`schema.prisma`) with Users, Vehicles, Trips.
-   [ ] **API: Authentication**: Implement JWT Login/Register endpoints.
-   [ ] **API: Trips**: CRUD endpoints (`POST /trips`, `GET /trips`).
-   [ ] **Gateway: Tracking**: WebSocket Gateway to receive `locationUpdate` events and save to DB.

### Phase 2: Mobile App Core (Active)
-   [x] **Location Logic**: `LocationService.dart` implemented.
-   [ ] **UI: Login Screen**: Connect to Backend Auth API.
-   [ ] **UI: Trip List**: Fetch trips from Backend API instead of mock data.
-   [ ] **UI: Map View**: Integrate Google Maps to show route and current location.
-   [ ] **Logic: Trip Actions**: Wire "Start/Stop" buttons to API calls.

### Phase 3: Compliance & Reporting
-   [ ] **Backend: PDF Gen**: Implement `pdf-lib` or `pdfkit` to generate AHCCCS-compliant reports on trip completion.
-   [ ] **Backend: EDI**: (Later) Implement EDI 837P file generation.

## ⚡ Getting Started

### 1. Start Database
```bash
docker-compose up -d
```

### 2. Start Backend
```bash
cd backend
npm install
npx prisma migrate dev
npm run start:dev
```

### 3. Run Mobile App
```bash
flutter pub get
flutter run
```





Based on my review of your YazDrive project, here are clear deployment instructions for Android and iOS apps:

Prerequisites
Backend deployed and accessible at a specific URL (e.g., https://api.yourdomain.com)
Database (PostgreSQL) is running and connected to backend
Flutter installed on your machine
For Android: Android Studio + Java/Kotlin setup
For iOS: Xcode + macOS machine + Apple Developer Account
Update the API endpoint in `lib/services/api_service.dart`:

The app is now configured to use the production URL by default:

```dart
static const String _productionUrl = 'https://backend.yaztrans.com';
static String get baseUrl => _productionUrl;
```

All other services (`UserService`, `TripService`, `LocationService`) already reference `ApiService.baseUrl` for consistency.
Do the same for any other services that connect to the backend (check trip_service.dart, vehicle_service.dart, location_service.dart).

Step 2: Configure Android App
2.1 Update Application ID
Edit android/app/build.gradle:16 and android/app/build.gradle:40:


namespace = "com.yazdrive.app"  // Change from com.mycompany.CounterApp
applicationId = "com.yazdrive.app"  // Same change here
2.2 Add Google Maps API Key
Get an API key from Google Cloud Console
Edit android/app/src/main/AndroidManifest.xml and add:

<application>
  <meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
  ...
</application>
2.3 Create Signing Key for Release

keytool -genkey -v -keystore ~/yazdrive-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias yazdrive
Create android/key.properties:


storePassword=your_store_password
keyPassword=your_key_password
keyAlias=yazdrive
storeFile=/path/to/yazdrive-release-key.jks
2.4 Build Android APK/AAB

# For APK (testing)
flutter build apk --release

# For Google Play Store (AAB)
flutter build appbundle --release
Output: build/app/outputs/flutter-apk/app-release.apk or build/app/outputs/bundle/release/app-release.aab

2.5 Deploy Android App
Testing: Transfer APK to device and install
Production: Upload AAB to Google Play Console
Step 3: Configure iOS App
3.1 Update Bundle Identifier
Open ios/Runner.xcworkspace in Xcode
Select Runner → General → Bundle Identifier
Change to: com.yazdrive.app (must be unique)
3.2 Add Google Maps API Key
Edit ios/Runner/AppDelegate.swift (or create if missing):


import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
3.3 Configure Signing & Capabilities
In Xcode:

Select Runner target → Signing & Capabilities
Select your Team (Apple Developer Account required)
Enable Background Modes: Location updates
Enable Location permissions (already in Info.plist)
3.4 Install CocoaPods Dependencies

cd ios
pod install
cd ..
3.5 Build iOS App

# For simulator (testing)
flutter build ios --release --no-codesign

# For real device (requires Apple Developer account)
flutter build ios --release
3.6 Deploy iOS App
Option A: TestFlight (Internal Testing)

Open Xcode → Product → Archive
Upload to App Store Connect
Invite testers via TestFlight
Option B: App Store (Production)

Archive in Xcode
Upload to App Store Connect
Submit for review
Once approved, release to App Store
Step 4: Test the Deployment
Install the app on a real device
Verify backend connection:
Open app and try to login
Check if data loads from your deployed backend
Check Network logs for API calls to your domain
Test GPS tracking (requires real device, not simulator)
Test trip management features
Important Notes
Google Maps API Key: You need separate keys for Android and iOS (can use same key if configured properly)
iOS requires paid Apple Developer Account ($99/year) for App Store distribution
Test on real devices for GPS/location features
Update version numbers in pubspec.yaml:4 before each release
Add app icons: Currently points to assets/icons/dreamflow_icon.jpg - ensure this exists or update path
Quick Commands Summary

# 1. Update backend URL in lib/services/*_service.dart files

# 2. Build Android
flutter clean
flutter pub get
flutter build apk --release

# 3. Build iOS
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release

# 4. Test
flutter run --release



Summary of Implementation

  1. Real-time Trip Sync via WebSocket

  - Backend (tracking.gateway.ts): Added WebSocket events for:
    - trip:assigned - broadcasts to specific drivers when trips are assigned
    - trip:updated - broadcasts trip updates to all connected clients
    - trip:cancelled - notifies when trips are cancelled
    - tripStatusUpdate - handles driver status updates (EN_ROUTE, ARRIVED, PICKED_UP, COMPLETED)
  - Flutter (trip_service.dart): Integrated Socket.IO client to receive real-time trip updates

  2. Signature Capture Widget (lib/widgets/signature_capture_widget.dart)

  - Custom canvas-based signature pad
  - Captures signatures as base64-encoded PNG images
  - Clear/reset functionality
  - Visual feedback showing signature status

  3. AHCCCS Daily Trip Report Completion Page (lib/pages/driver/trip_completion_page.dart)

  - Auto-fills known data (provider info, driver info, vehicle info, member info, locations)
  - Odometer reading capture at pickup and dropoff
  - Calculates trip miles automatically
  - Reason for visit field
  - Escort information (name and relationship)
  - Multiple members transport questions
  - Driver and member signature capture
  - "Member unable to sign" checkbox option
  - Submit triggers PDF generation and email on backend

  4. Azuga Integration (lib/services/location_service.dart)

  - AzugaVehicleLocation class for tracking vehicle data
  - Real-time vehicle location updates from Azuga webhook
  - Vehicle status tracking (moving, idle, offline)
  - Integration with trip tracking

  5. Push Notifications (lib/services/notification_service.dart)

  - Local notifications for new trip assignments
  - Trip cancellation notifications
  - Notification tap navigates to trip details
  - Channel configuration for different notification types

  6. Backend Trip Service Updates (trips.service.ts)

  - Broadcasts trip assignments to drivers via WebSocket
  - Auto-generates AHCCCS PDF report on trip completion
  - Emails report to NEMT provider
  - Handles all AHCCCS-required fields (odometer, reason for visit, escort info, signatures)

  7. Driver Login Integration (lib/pages/login_page.dart)

  - Initializes WebSocket connections on driver login
  - Fetches trips from backend API
  - Sets up location tracking

  Key Files Modified/Created:

  - backend/src/tracking/tracking.gateway.ts - WebSocket gateway
  - backend/src/trips/trips.service.ts - Trip management with PDF/email
  - lib/services/trip_service.dart - Real-time sync + backend API
  - lib/services/location_service.dart - Azuga integration
  - lib/services/notification_service.dart - Push notifications
  - lib/widgets/signature_capture_widget.dart - Signature capture
  - lib/pages/driver/trip_completion_page.dart - AHCCCS form
  - lib/nav.dart - Added trip completion route
  - lib/main.dart - Notification initialization
  - pubspec.yaml - Added flutter_local_notifications dependency

  Workflow:

  1. Dispatcher assigns trip in web portal → WebSocket broadcasts to driver
  2. Driver receives push notification and sees trip in schedule
  3. Driver confirms vehicle → views schedule → starts trip
  4. Swipe actions: Begin Pickup → Arrived → Pickup Done → Drop-off Done
  5. On completion: AHCCCS form with odometer, signatures → Submit
  6. Backend generates PDF report and emails to NEMT provider

  Sources for AHCCCS form fields:
  - https://www.azahcccs.gov/PlansProviders/Downloads/FFSProviderManual/AHCCCSDailyTripReportFinal.pdf
  - https://www.azahcccs.gov/Resources/Downloads/DFSMTraining/2024/NEMT_AHCCCSDailyTripReportReminders.pdf