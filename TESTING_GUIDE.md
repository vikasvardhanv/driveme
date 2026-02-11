# YazTrans NEMT - Testing & Deployment Guide

## Overview
This guide covers testing the complete flow: Driver Signup → Azuga Webhook Integration → Trip Completion → AHCCCS PDF Generation → Email Delivery.

---

## 1. Testing on iPhone Simulator

### Prerequisites
```bash
# Ensure Flutter and Xcode are installed
flutter doctor

# Should show:
# ✓ Flutter
# ✓ Xcode
# ✓ iOS toolchain
```

### Start iPhone Simulator

**Option A: Default Simulator**
```bash
open -a Simulator
```

**Option B: Specific iPhone Model**
```bash
# List available simulators
xcrun simctl list devices | grep iPhone

# Boot specific simulator (e.g., iPhone 15 Pro)
xcrun simctl boot "iPhone 15 Pro"
open -a Simulator
```

**For Production Backend (Default):**
```bash
cd /Users/vikashvardhan/Downloads/driveme

# Run with production backend (https://backend.yaztrans.com)
flutter run -d ios
```

*Note: The app is now set to production by default in `ApiService.dart`.*

### Hot Reload During Development
- Press `r` in terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

---

## 2. Test Driver Signup Flow

### Step 1: Access Signup Page
1. Open browser and go to: **https://yaztrans.com/driver/signup**
2. Or locally: **http://localhost:3000/driver/signup** (if running admin-web locally)

### Step 2: Fill Signup Form
```
First Name: John
Last Name: Doe
Email: john.doe@example.com
Phone: (555) 123-4567
License Number: DL123456789
License Expiry: 2026-12-31
```

### Step 3: Verify Backend Response
Check that:
- ✅ Driver account created in database
- ✅ Temporary password generated and displayed
- ✅ Welcome email sent to driver's email
- ✅ Redirect to mobile app attempted

### Step 4: Test Mobile App Login
1. On iPhone simulator, open the app
2. Navigate to Login screen
3. Enter email and temporary password
4. Verify successful login

### API Endpoint
```bash
# Test signup endpoint directly
curl -X POST https://backend.yaztrans.com/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test.driver@example.com",
    "firstName": "Test",
    "lastName": "Driver",
    "phone": "5551234567",
    "licenseNumber": "DL123456",
    "licenseExpiry": "2026-12-31"
  }'

# Expected Response:
{
  "message": "Driver account created successfully. Welcome email sent.",
  "user": { ... },
  "tempPassword": "Abc123!@#XYZ"
}
```

---

## 3. Test Azuga Webhook Integration

### Step 1: Unpause Webhook in Azuga Dashboard
1. Go to: https://fleet.azuga.com/admin/webhooks
2. Find webhook: `Coolify_connect` (or your specific webhook name)
3. **Unpause** the webhook if it's currently paused

### Step 2: Test Webhook Manually

**Using cURL:**
```bash
curl -X POST https://backend.yaztrans.com/azuga/webhook \
  -H "Content-Type: application/json" \
  -u "your-username:your-password" \
  -d '{
    "serialNumber": "YOUR_VEHICLE_VIN",
    "latitude": 33.4484,
    "longitude": -112.0740,
    "speed": 45.5,
    "timestamp": "2026-01-13T10:30:00Z"
  }'

# Expected Response:
{
  "status": "received"
}
```

**Replace:**
- `YOUR_VEHICLE_VIN` with an actual VIN from your database
- Username/password with your Azuga webhook credentials

### Step 3: Check Backend Logs
```bash
# Check logs on your deployment server (e.g., Coolify or VPS)
# For example, if using Docker:
docker logs backend
```

Look for:
"Received Azuga Webhook: ..."
"Found Vehicle: <vehicle-id> (Driver: <driver-id>)"
"Updated Vehicle <vehicle-id> coordinates to ..."
"Broadcasting update for Driver <driver-id>"
```

### Step 4: Verify in Mobile App
- GPS location should update in real-time on the map
- Vehicle marker should move to new coordinates

---

## 4. Test AHCCCS PDF Generation & Email

### Prerequisites
1. **Download AHCCCS PDF Template:**
   ```bash
   # Download from:
   # https://www.azahcccs.gov/PlansProviders/Downloads/FFSProviderManual/AHCCCSDailyTripReportFinal.pdf

   # Save to:
   /Users/vikashvardhan/Downloads/driveme/backend/templates/ahcccs-daily-trip-report.pdf
   ```

2. **Set up Email SMTP (in backend/.env):**
   ```env
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USER=your-email@gmail.com
   SMTP_PASS=your-app-password
   SMTP_FROM="YazTrans NEMT <noreply@yaztrans.com>"
   ```

### Test Flow 1: Automatic PDF Generation on Trip Completion

**Step 1: Create a Test Trip**
```bash
curl -X POST https://backend.yaztrans.com/trips \
  -H "Content-Type: application/json" \
  -d '{
    "pickupAddress": "123 Main St, Phoenix, AZ 85001",
    "dropoffAddress": "456 Oak Ave, Phoenix, AZ 85002",
    "customerName": "Jane Smith",
    "customerPhone": "5559876543",
    "scheduledDate": "2026-01-15",
    "scheduledTime": "10:00",
    "companyId": "<your-company-id>",
    "memberId": "<member-id>",
    "driverId": "<driver-id>",
    "vehicleId": "<vehicle-id>",
    "tripType": "one-way",
    "pickupOdometer": 12345,
    "reasonForVisit": "Medical Appointment",
    "escortName": "John Doe",
    "escortRelationship": "Son"
  }'
```

**Step 2: Complete the Trip**
```bash
curl -X PATCH https://backend.yaztrans.com/trips/<trip-id> \
  -H "Content-Type: application/json" \
  -d '{
    "status": "COMPLETED",
    "dropoffOdometer": 12367,
    "actualPickupTime": "2026-01-15T10:05:00Z",
    "actualDropoffTime": "2026-01-15T10:45:00Z"
  }'
```

**Step 3: Verify Automatic PDF Generation**
- Check backend logs for: `"Trip <id> marked as COMPLETED - triggering PDF generation"`
- PDF should be generated automatically
- Email should be sent to company email

**Step 4: Check Email**
- Check the company's email inbox
- Email subject: "AHCCCS Daily Trip Report - <date>"
- Should have PDF attachment: `AHCCCS_Daily_Trip_Report_<trip-id>_<timestamp>.pdf`

### Test Flow 2: Manual On-Demand PDF Generation

```bash
# Generate PDF manually for any trip
curl -X POST https://backend.yaztrans.com/trips/<trip-id>/generate-report \
  -o trip-report.pdf

# This downloads the PDF directly
# Check that the file opens correctly
open trip-report.pdf
```

### Verify PDF Contents
The auto-filled PDF should contain:
- ✅ NEMT Provider ID, Name, Address, Phone
- ✅ Driver Name
- ✅ Date
- ✅ Vehicle License/Fleet ID
- ✅ Vehicle Make & Color
- ✅ Vehicle Type (checkbox)
- ✅ AHCCCS Number
- ✅ Member Name
- ✅ Member Date of Birth
- ✅ Mailing Address
- ✅ Pickup Location, Time, Odometer
- ✅ Dropoff Location, Time, Odometer
- ✅ Trip Miles (calculated)
- ✅ Trip Type (checkbox)
- ✅ Reason for Visit
- ✅ Escort Name & Relationship

---

## 5. Test Complete End-to-End Flow

### Scenario: New Driver Completes First Trip

**Step 1: Driver Signs Up**
1. Go to https://yaztrans.com/driver/signup
2. Fill form and submit
3. Note temporary password
4. Check email for welcome message

**Step 2: Driver Logs into Mobile App**
1. Open app on iPhone simulator
2. Enter email and temp password
3. Verify successful login

**Step 3: Driver Gets Assigned to Trip**
1. Dispatcher creates trip in admin portal
2. Assigns driver to trip
3. Driver sees trip in mobile app

**Step 4: Driver Starts Trip**
1. Driver taps "Start Trip"
2. App records pickup odometer
3. App records pickup time
4. GPS tracking starts (Azuga webhook updates location)

**Step 5: Driver Completes Trip**
1. Driver arrives at destination
2. Driver taps "Complete Trip"
3. App records dropoff odometer
4. App records dropoff time
5. Trip marked as COMPLETED

**Step 6: Automatic PDF Generation**
1. Backend detects COMPLETED status
2. Generates AHCCCS PDF with all trip data
3. Saves PDF to `/uploads/reports/`
4. Sends email to company with PDF attachment

**Step 7: Verification**
1. Company receives email with PDF
2. PDF contains all required AHCCCS fields
3. Company can submit PDF to AHCCCS

---

## 6. Common Issues & Troubleshooting

### Issue 1: "Connection Refused" on iOS Simulator
**Solution:**
```bash
# Use localhost for iOS simulator, not 10.0.2.2
# The app already handles this in user_service.dart

# If still issues, check backend is running:
cd /Users/vikashvardhan/Downloads/driveme/backend
npm run start:dev

# Should see: "Application is running on: http://localhost:3001"
```

### Issue 2: Azuga Webhook Not Updating Location
**Checklist:**
- ✅ Webhook is unpaused in Azuga dashboard
- ✅ Vehicle VIN exists in database
- ✅ Vehicle has assigned driver
- ✅ Basic Auth credentials are correct
- ✅ Backend is accessible from internet (Coolify URL)

### Issue 3: PDF Generation Fails
**Common Causes:**
- ❌ PDF template not found at `/backend/templates/ahcccs-daily-trip-report.pdf`
- ❌ Trip missing required company data
- ❌ pdf-lib can't read the template

**Solution:**
```bash
# Verify template exists
ls -l /Users/vikashvardhan/Downloads/driveme/backend/templates/

# Check backend logs for specific error
# (e.g., docker logs backend | grep "PDF")
```

### Issue 4: Email Not Sending
**Common Causes:**
- ❌ SMTP credentials not configured
- ❌ Gmail blocking "less secure apps"
- ❌ Wrong SMTP port

**Solution:**
```bash
# For Gmail, use App Password:
# 1. Go to Google Account > Security
# 2. Enable 2-Step Verification
# 3. Generate App Password
# 4. Use app password in SMTP_PASS

# Update .env:
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-16-char-app-password
```

### Issue 5: Database Schema Mismatch
**Solution:**
```bash
cd /Users/vikashvardhan/Downloads/driveme/backend

# Push schema to database
npx prisma db push --url="$DATABASE_URL"

# Regenerate Prisma Client
npx prisma generate
```

---

## 7. Environment Variables Checklist

### Backend (.env)
```env
NODE_ENV=production
PORT=3001

# Database
DATABASE_URL=postgresql://postgres.[project-ref]:[your-password]@aws-0-[region].pooler.supabase.com:5432/postgres

# CORS
CORS_ORIGINS=https://yaztrans.com,http://localhost:3000

# SMTP Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM="YazTrans NEMT <noreply@yaztrans.com>"

# Azuga
AZUGA_CLIENT_ID=<your-client-id>
AZUGA_CLIENT_SECRET=<your-client-secret>
```

### Admin Web (.env.local)
```env
NEXT_PUBLIC_API_URL=https://backend.yaztrans.com
NEXT_PUBLIC_SUPABASE_URL=https://hrlnevacotasdxxmhgxe.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_DEFAULT_KEY=sb_publishable_7HkgTyG2UhWO_UZYXJeZFA_y_0GHpDS
```

---

## 8. Deployment Checklist

### Pre-Deployment
- [ ] Download AHCCCS PDF template
- [ ] Configure SMTP credentials
- [ ] Test all endpoints locally
- [ ] Test PDF generation with real data
- [ ] Verify email delivery

### Backend Deployment (Coolify/VPS)
- [ ] Push latest code to GitHub
- [ ] Server auto-deploys from main branch
- [ ] Set environment variables in Server dashboard
- [ ] Run database migration: `npx prisma db push`
- [ ] Verify deployment: Check server logs

### Admin Web Deployment (Vercel/Netlify)
- [ ] Push to GitHub
- [ ] Connect repo to Vercel/Netlify
- [ ] Set environment variables
- [ ] Deploy to production
- [ ] Verify at https://yaztrans.com

### Mobile App Deployment
- [ ] Update API URLs to production
- [ ] Build iOS app: `flutter build ios`
- [ ] Submit to App Store via Xcode
- [ ] Build Android app: `flutter build apk`
- [ ] Submit to Google Play Console

---

## 9. API Endpoints Reference

### Authentication
```
POST /auth/login
POST /auth/signup
```

### Trips
```
GET    /trips
POST   /trips
GET    /trips/:id
PATCH  /trips/:id
DELETE /trips/:id
POST   /trips/:id/generate-report  # Manual PDF generation
```

### Azuga Webhook
```
POST /azuga/webhook
```

---

## 10. Next Steps

1. **Download AHCCCS PDF Template** (CRITICAL)
   - Get PDF from: https://www.azahcccs.gov/PlansProviders/Downloads/FFSProviderManual/AHCCCSDailyTripReportFinal.pdf
   - Save to: `/backend/templates/ahcccs-daily-trip-report.pdf`

2. **Configure Email Settings**
   - Set up Gmail App Password
   - Update backend/.env with SMTP credentials

3. **Test on iPhone Simulator**
   ```bash
   flutter run -d ios
   ```

4. **Test Driver Signup**
   - Visit https://yaztrans.com/driver/signup
   - Create test driver account
   - Login via mobile app

5. **Test Complete Trip Flow**
   - Create trip
   - Assign driver
   - Start & complete trip
   - Verify PDF generation and email delivery

6. **Production Deployment**
   - Deploy backend to Coolify
   - Deploy admin-web to Vercel/Netlify
   - Submit mobile app to App Store

---

## Support

For issues or questions:
- Email: support@yaztrans.com
- GitHub Issues: https://github.com/your-repo/issues
