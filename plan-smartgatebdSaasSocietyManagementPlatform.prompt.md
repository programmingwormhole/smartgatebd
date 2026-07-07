# Plan: SmartGateBD SaaS Society Management Platform

## TL;DR
Build a complete multi-tenant apartment management platform with Laravel backend (server), Superadmin panel (web UI), Flutter resident app, and Flutter guard app. Foundation starts with authentication, progresses through core building/resident structures, then adds feature modules, UIs, and real-time notifications. Solo developer, sequential execution across 6 phases.

---

## Phase 1: BACKEND FOUNDATION (Society Admin / Laravel)

### Core Setup
1. **Initialize Laravel 12 project** in `society_admin/`
   - Install dependencies: Laravel 12, Laravel Sanctum, Firebase Admin SDK, BulkSMS PHP client, Dio HTTP client (if API mock server needed)
   - Database: Use existing MySQL `smartgatebd` (root / Justin@123#$)
   - Create `.env` file with all credentials
   
2. **Project Structure** (Service Layer Architecture)
   - Create directories: `app/Models`, `app/Services`, `app/Repositories`, `app/DTOs`, `app/Http/Controllers`, `app/Http/Resources`, `app/Policies`, `routes`, `database/migrations`
   - Create `config/app.php` adjustments for multi-tenancy if needed
   - Setup Laravel Sanctum for API tokens

3. **Database: Core Schema** (migrations)
   - Create migrations in order of dependency:
     - `users` (email, phone, role, password, otp_code, otp_expires_at, building_id for multi-tenant context)
     - `buildings` (name, address, admin_id, created_at)
     - `blocks` (building_id, name)
     - `floors` (block_id, floor_number)
     - `flats` (floor_id, flat_number)
     - `residents` (user_id, flat_id, role: resident|admin|committee)
     - `families` (resident_id, name, relation, gatepass_enabled)
     - `daily_helps` (resident_id, category: maid|cook|milkman|laundry, name, phone, gatepass_enabled)
     - `guards` (building_id, user_id, name, phone, status)
     - `visitors` (flat_id, type: guest|cab|delivery|service, name, phone, vehicle_no, company_name, purpose, from_date, to_date, status: pending|approved|rejected, created_by_resident_id)
     - `gatepasses` (visitor_id, gatepass_code, entry_code, qr_code, entry_time, exit_time)
     - `visitor_logs` (gatepass_id, guard_id, action: entry|exit, timestamp)
     - `bills` (flat_id, type: rent|maintenance|custom, amount, due_date, status, created_at)
     - `bill_payments` (bill_id, amount, method: upi|bank|cash, trx_id, screenshot_path)
     - `amenities` (building_id, name, price_per_day, max_capacity)
     - `amenity_bookings` (resident_id, amenity_id, booking_date, from_time, to_time, status: pending|approved|rejected)
     - `services` (building_id, category: ac_repair|cleaning|electrician etc, name)
     - `service_bookings` (resident_id, service_id, status: pending|approved|completed, description, booking_date, created_at)
     - `complaints` (resident_id, category, description, status: open|in_progress|resolved, created_at)
     - `chats` (id, sender_id, receiver_id, building_id)
     - `messages` (chat_id, sender_id, content, image_path, created_at)
     - `emergency_alerts` (building_id, type: fire|medical|security, message, status, created_by_admin_id, created_at)
     - `alert_recipients` (alert_id, recipient_id, recipient_type: admin|committee|guard, is_read)
     - `guard_logs` (guard_id, building_id, action: check_in|check_out|visitor_verified, metadata, timestamp)
     - `notices` (building_id, title, content, created_by_admin_id, created_at)
     - `fcm_tokens` (user_id, device_token, device_type, created_at)
     - `system_configurations` (key, value, created_at, updated_at) — For OTP settings, BulkSMSBD config

### MODULE 1: Authentication
4. **Models**
   - `User` model with relationships to `Building`, `resident` data
   - Create DTO: `LoginRequest`, `OtpVerificationRequest`, `RegisterRequest`

5. **Controllers**
   - `AuthController` with methods:
     - `register()` - Validate, create user, send OTP via BulkSMSBD
     - `verifyOtp()` - Check OTP, create Sanctum token
     - `login()` - Email+password → send OTP (for guard login)
     - `logout()` - Invalidate token
     - `resendOtp()` - Resend OTP if expired

6. **Services**
   - `AuthService` - Handle user creation, OTP generation logic
   - `OtpService` - Validate OTP, manage expiry (5 min), check if OTP enabled in config
   - `BulkSmsService` - Wrapper for BulkSMSBD API to send SMS
   - `SystemConfigurationService` - Get/set system configs (OTP enabled, API keys, etc)

7. **API Routes** (prefix: `/api/v1`)
   - POST `/auth/register` → `AuthController@register`
   - POST `/auth/verify-otp` → `AuthController@verifyOtp`
   - POST `/auth/login` → `AuthController@login`
   - POST `/auth/logout` → `AuthController@logout` (middleware: auth:sanctum)
   - POST `/auth/resend-otp` → `AuthController@resendOtp`

8. **Testing**
   - Test register → OTP sent to phone (mock BulkSMS API)
   - Test OTP verification → Token returned
   - Test login → OTP verification flow
   - Test logout → Token invalidated

---

### Modules 2-6: Core Data Structures (Buildings → Residents)

9. **MODULE 2: Buildings & Structure**
   - Models: `Building`, `Block`, `Floor`, `Flat`
   - Controllers: `BuildingController`, `BlockController`, `FloorController`, `FlatController`
   - Services: One service per model for business logic (e.g., `BuildingService@createBuilding`)
   - API Routes:
     - POST `/buildings` (admin only) → Create building
     - GET `/buildings` → Super admin sees all; building admin sees own
     - POST `/buildings/{id}/blocks` → Add block
     - POST `/blocks/{id}/floors` → Add floor
     - POST `/floors/{id}/flats` → Add flat
     - GET `/buildings/{id}/structure` → Get tree (building→blocks→floors→flats)
   - Resources: Transform to clean JSON (e.g., `BuildingResource`)
   - Middleware: Create `IsBuildingAdmin` policy to check access

10. **MODULE 3: Residents**
    - Model: `Resident` with belongs-to `User` and `Flat`
    - Controller: `ResidentController`
    - Service: `ResidentService`
    - API Routes:
      - POST `/buildings/{id}/residents` (admin only) → Assign user to flat + role
      - GET `/buildings/{id}/residents` → List all residents
      - PUT `/residents/{id}` → Update role
      - DELETE `/residents/{id}` → Remove resident
    - Policy: Check admin can only manage their own building
    - Resources: `ResidentResource`

11. **MODULE 4: Guards**
    - Model: `Guard` with belongs-to `User` and `Building`
    - Controller: `GuardController`
    - Service: `GuardService`
    - API Routes:
      - POST `/buildings/{id}/guards` (admin only) → Create guard account
      - GET `/buildings/{id}/guards` → List
      - PUT `/guards/{id}/status` → Toggle duty status
    - Resources: `GuardResource`

12. **MODULE 5: Family & Daily Help**
    - Models: `Family`, `DailyHelp`
    - Controller: `FamilyController`, `DailyHelpController`
    - API Routes:
      - POST `/residents/{id}/family` (resident) → Add family member
      - GET `/residents/{id}/family` → List family
      - POST `/residents/{id}/daily-help` (resident) → Add maid/cook/etc
      - PUT `/family/{id}` (resident) → Update
      - DELETE `/family/{id}` (resident) → Remove → Invalidate any active gatepass
    - Resources: `FamilyResource`, `DailyHelpResource`

---

### Modules 7-12: Feature Modules

13. **MODULE 6: Visitor Management (Core Feature)**
    - Models: `Visitor`, `Gatepass`, `VisitorLog`
    - Controllers: `VisitorController`, `GatepassController`
    - Services:
      - `VisitorService` - Create/approve/reject visitors
      - `GatepassService` - Generate QR code, entry code (6-digit random)
      - `QrCodeService` - Library wrapper to generate QR PNG (e.g., `Laravel QrCode`)
    - API Routes:
      - POST `/visitors` (resident) → Create visitor request
      - PUT `/visitors/{id}/approve` (admin) → Approve + auto-generate gatepass
      - PUT `/visitors/{id}/reject` → Reject
      - GET `/visitors/{id}/gatepass` → Fetch gatepass details (QR, code, dates)
      - GET `/buildings/{id}/visitors` (admin) → List all
      - GET `/residents/{id}/visitors` (resident) → Own visitors
    - Guard API (separate routes):
      - POST `/guard/verify` → Input QR or entry_code, returns visitor details + log entry
      - POST `/guard/logs` (guard) → Logs entry/exit
      - GET `/guard/logs` → View own logs
    - Resources: `VisitorResource`, `GatepassResource`

14. **MODULE 7: Bills & Payments**
    - Models: `Bill`, `BillPayment`
    - Controllers: `BillController`, `PaymentController`
    - Services:
      - `BillService` - Create, list, mark as paid
      - `PaymentService` - Record payment, validate screenshot upload
    - API Routes:
      - POST `/buildings/{id}/bills` (admin only) → Create bill
      - GET `/flats/{id}/bills` (resident) → Get own bills
      - GET `/buildings/{id}/bills` (admin) → All bills
      - POST `/bills/{id}/pay` (resident) → Record offline payment + upload screenshot
      - GET `/bill-payments/{id}` → View payment details
    - Resources: `BillResource`, `PaymentResource`
    - File Storage: Use Laravel Storage to save payment screenshots in `storage/app/payments/`

15. **MODULE 8: Amenities**
    - Models: `Amenity`, `AmenityBooking`
    - Controllers: `AmenityController`, `BookingController`
    - Services: `AmenityService`, `BookingService`
    - API Routes:
      - POST `/buildings/{id}/amenities` (admin) → Create amenity
      - GET `/buildings/{id}/amenities` → List amenities
      - POST `/amenities/{id}/book` (resident) → Request booking
      - GET `/amenities/{id}/bookings` (admin) → List bookings
      - PUT `/bookings/{id}/approve` (admin) → Approve
      - PUT `/bookings/{id}/reject` (admin) → Reject
    - Resources: `AmenityResource`, `BookingResource`

16. **MODULE 9: Services**
    - Models: `Service`, `ServiceBooking`
    - Controllers: `ServiceController`, `ServiceBookingController`
    - Services: `ServiceService`, `ServiceBookingService`
    - API Routes:
      - POST `/buildings/{id}/services` (admin) → Create service category
      - GET `/buildings/{id}/services` → List
      - POST `/service/{id}/book` (resident) → Request service
      - GET `/service-bookings` (resident) → Own bookings
      - GET `/service-bookings` (admin) → All in building
      - PUT `/service-bookings/{id}/status` (admin) → Update status
    - Resources: `ServiceResource`, `ServiceBookingResource`

17. **MODULE 10: Complaints**
    - Models: `Complaint`
    - Controller: `ComplaintController`
    - Service: `ComplaintService`
    - API Routes:
      - POST `/complaints` (resident) → File complaint
      - GET `/complaints` (resident) → Own complaints
      - GET `/complaints` (admin) → All in building
      - PUT `/complaints/{id}/status` (admin) → Update status
    - Resources: `ComplaintResource`

18. **MODULE 11: Chat & Notifications**
    - Models: `Chat`, `Message`
    - Controllers: `ChatController`, `MessageController`
    - Services: `ChatService`, `MessageService`
    - API Routes:
      - POST `/chats` (resident) → Initiate chat (one-on-one or with admin)
      - GET `/chats` → List user's chats
      - GET `/chats/{id}/messages` → Message history
      - POST `/messages` (resident) → Send message
    - WebSocket Note: For MVP, use polling; real-time via Firebase is Phase 5
    - Resources: `ChatResource`, `MessageResource`

19. **MODULE 12: Emergency Alerts**
    - Models: `EmergencyAlert`, `AlertRecipient`
    - Controllers: `EmergencyController`
    - Services: `EmergencyService`
    - API Routes:
      - POST `/emergency` (admin) → Create alert
      - GET `/emergency` (resident) → Alerts for resident's building
      - PUT `/emergency/{id}/read` (user) → Mark as read
    - Resources: `AlertResource`

20. **MODULE 13: Notices**
    - Models: `Notice`
    - Controller: `NoticeController`
    - Service: `NoticeService`
    - API Routes:
      - POST `/buildings/{id}/notices` (admin) → Create notice
      - GET `/buildings/{id}/notices` → List all
    - Resources: `NoticeResource`

---

### Additional Phase 1 Work

21. **API Authentication & Authorization**
    - Implement Sanctum middleware in routes
    - Create policies for each resource (e.g., `ResidentPolicy@view` checks ownership)
    - Add role-based access checks (Super Admin, Building Admin, Resident, Guard)

22. **Firebase Cloud Messaging Setup**
    - Create `FirebaseService` class to initialize Firebase SDK
    - Create `FcmTokenController` - Resident app sends device token on login
    - Store tokens in `fcm_tokens` table joined to users
    - (Actual sending deferred to Phase 5, but infrastructure ready)

23. **Scheduler for Monthly Bills**
    - Create `GenerateBills` scheduled job (runs monthly on 1st)
    - Create `ExpireVisitors` job (mark visitors as expired if to_date passed)
    - Register in `app/Console/Kernel.php` with `->monthly()` and custom cron

24. **Testing**
    - Set up PHPUnit or Pest
    - Test each controller's CRUD endpoints (basic integration tests)
    - Mock BulkSMS and Firebase API calls
    - Run tests: `php artisan test`

**Phase 1 Checkpoint:**
- All 13 modules have basic CRUD endpoints
- Database fully designed and migrated
- Authentication flow working (OTP → Token)
- Guards can verify visitors
- Residents can request amenities/services/visitor approval
- Admins can manage building structure/residents/approvals
- API documentation ready (Postman/OpenAPI)

---

## Phase 2: SUPERADMIN PANEL (Blade + TailwindCSS + Alpine.js)

25. **Setup Blade + TailwindCSS**
    - Create views folder structure: `resources/views/dashboard`, `/buildings`, `/users`, `/billing`, `/settings`
    - Install TailwindCSS into Laravel project
    - Create base layout: `resources/views/layouts/app.blade.php`
    - Setup Alpine.js for interactive components

26. **Superadmin Dashboard Pages**
    - Dashboard: System stats (buildings count, active residents, total revenue)
    - Buildings: List all buildings, create building, assign admin
    - Users: Manage all users (admins, residents, guards)
    - Billing: View SaaS subscription per building
    - System Settings: Configure system parameters (OTP, SMS service)

26.1 **OTP Verification & BulkSMSBD Configuration** (NEW)
    - Database: Create `system_configurations` table with key-value pairs:
      - `otp_enabled` (boolean, default: false)
      - `otp_expiry_minutes` (int, default: 5)
      - `bulksmsbd_api_key` (string, encrypted)
      - `bulksmsbd_sender_id` (string)
      - `bulksmsbd_enabled` (boolean)
    - Create `SystemConfigurationController` with:
      - GET `/admin/config/otp-settings` → Fetch current OTP config
      - PUT `/admin/config/otp-settings` → Update OTP settings (super admin only)
    - Superadmin Panel Page: **Settings → OTP & SMS Configuration**
      - Toggle: "Enable OTP Verification" (on/off) - Default: OFF
      - When enabled, show additional fields:
        - OTP Expiry (minutes) - default 5
        - BulkSMSBD API Key (password field)
        - BulkSMSBD Sender ID
        - Test SMS button (sends test OTP to admin phone)
      - Save button stores in `system_configurations` table
    - Backend: Modify `OtpService` to check `otp_enabled` config before sending
      - If OTP disabled, return error: "OTP verification not enabled"
      - If OTP enabled, fetch API key from `system_configurations` and send via BulkSMSBD
    - Flow: Initially platform has OTP OFF → Residents cannot register/login until superadmin enables it
      - Superadmin enables it and configures BulkSMSBD → Residents can now use OTP

27. **Building Admin Pages** (accessible by Building Admin after login)
    - Building Dashboard: Own building stats
    - Residents: Add/remove/manage residents
    - Blocks/Floors/Flats: Create structure
    - Bills: Create bills, view payments
    - Notices: Create & send notices
    - Services: Manage service categories
    - Amenities: Create amenities, approve bookings
    - Guards: Create guard accounts
    - Visitors: Approve/reject visitors
    - Reports: View logs, occupancy, revenue

28. **Authentication for Panel**
    - Login page: Email + password
    - Create separate admin middleware (distinct from API)
    - Session-based (Laravel default)

29. **File Upload UI**
    - Profile photos: Admin can upload building logo/photo
    - Screenshot verification: Display uploaded payment screenshots

**Phase 2 Checkpoint:**
- Super admin can log in and manage all buildings
- Building admins can manage their structure and residents
- Dashboard shows key metrics
- All CRUD operations have UI equivalents
- OTP settings configurable, defaults to OFF

---

## Phase 3: FLUTTER USER APP (society_user)

### Project Setup
30. **Initialize Flutter Project** in `society_user/`
    - `flutter create society_user`
    - Set minimum SDK to 21 (Android), 11 (iOS)
    - Add dependencies:
      - `get: ^4.6.6` (state management)
      - `dio: ^5.0.0` (HTTP client)
      - `firebase_core: ^2.x` + `firebase_messaging: ^14.x`
      - `qr_flutter: ^4.0.0` (display QR from gatepass)
      - `image_picker: ^1.0.0` (upload payment screenshot)
      - `intl: ^0.19.0` (date formatting)
      - `get_storage: ^2.1.1` (local storage for tokens)
      - `flutter_local_notifications: ^15.x` (handle FCM notifications)

31. **GetX Pattern/Modular Architecture Structure**
    ```
    lib/
    ├── app/
    │   ├── modules/
    │   │   ├── splash/
    │   │   │   ├── bindings/ (dependency injection for this module)
    │   │   │   ├── controllers/ (GetX state management)
    │   │   │   └── views/ (UI screens)
    │   │   ├── auth/
    │   │   │   ├── bindings/
    │   │   │   ├── controllers/
    │   │   │   └── views/
    │   │   ├── home/
    │   │   ├── visitors/
    │   │   │   ├── bindings/
    │   │   │   ├── controllers/
    │   │   │   ├── views/ (list, details, add forms)
    │   │   │   └── widgets/
    │   │   ├── bills/
    │   │   ├── amenities/
    │   │   ├── services/
    │   │   ├── chat/
    │   │   ├── notices/
    │   │   ├── complaints/
    │   │   ├── profile/
    │   │   └── ... other modules (each with bindings/, controllers/, views/)
    │   ├── routes/
    │   │   ├── app_pages.dart (named routes)
    │   │   └── app_routes.dart (route constants)
    │   └── widgets/ (global reusable widgets)
    ├── core/
    │   ├── services/ (Firebase, Dio, LocalStorage)
    │   ├── constants/ (API URLs, colors, strings)
    │   └── utils/ (helpers, validators)
    └── main.dart
    ```
    - Each module is self-contained with its own controllers, bindings, and views
    - Bindings auto-inject dependencies when module loads
    - Easier to maintain, scale, and modularize features

32. **Core Services**
    - `DioClient` - Configured Dio with base URL, interceptors for token injection, error handling
    - `LocalStorageService` - SaveToken, getToken, clearToken using GetStorage
    - `FirebaseService` - Initialize Firebase, listen to FCM, handle notification callbacks

33. **API Models & Repositories**
    - Create models (with `.fromJson`, `.toJson`):
      - `User`, `AuthToken`, `Resident`, `Building`, `Flat`
      - `Visitor`, `Gatepass`, `QrCodeData`
      - `Bill`, `Payment`
      - `Amenity`, `AmenityBooking`
      - `Service`, `ServiceBooking`
      - `Chat`, `Message`
      - `Notice`, `EmergencyAlert`
    - Create `AuthRepository` with methods: `register()`, `verifyOtp()`, `login()`, `logout()`
    - Create `VisitorRepository` with: `createVisitor()`, `listMyVisitors()`, `getGatepass()`
    - Create repositories for Bills, Amenities, Services, Chat, Notices

34. **Navigation & Routing (GetX)**
    - Define named routes in `routes.dart`
    - Create `GetPages` with bindings for each screen
    - Main routes: Splash → Onboarding → Login → OTP → Home (dashboard)

### Screens Development

35. **Authentication Flow**
    - `SplashScreen` - Check token, redirect to login or home
    - `OnboardingScreen` - Unauth users see features overview, "Get Started" button
    - `LoginScreen` - Phone number input, "Get OTP" button (calls `AuthRepository.login()`)
    - `OtpVerificationScreen` - 6-digit OTP input, timer (5 min), resend button (calls `AuthRepository.verifyOtp()`)
    - After success: Save token locally, navigate to Home

36. **Home Dashboard Screen**
    - GetX controller to fetch user/building/flat data on init
    - Display resident name, building, flat number, role
    - Show 5-6 quick action tiles:
      - Visitors (icon + count)
      - Bills (icon + count due)
      - Amenities
      - Services
      - Chat
      - Notices
    - Tap any tile to navigate to that module

37. **Visitor Management Module**
    - `VisitorsListScreen` - List current/past visitors with status badges
    - `PreApproveVisitorScreen` - Quick action screen with 4 buttons:
      - Add Guest (full form)
      - Add Cab (vehicle details)
      - Add Delivery (company + items)
      - Add Service (service type + description)
    - `AddVisitorFormScreen` - Dynamic form based on type, submit → calls repo
    - `GatepassDetailScreen` - After approval, show:
      - Visitor photo + details
      - QR code (generated from gatepass_code)
      - Entry code (numeric)
      - Valid dates/times
      - Share, Download, Delete buttons
    - Visitor approved → Push notification sent to guard app

38. **Bills Module**
    - `BillsListScreen` - Show pending and paid bills with status badges
    - `BillDetailScreen` - Show amount, due date, status, pay button
    - `PaymentScreen` - Amount pre-filled, payment method dropdown (UPI/Bank/Cash), transaction ID, screenshot upload
    - Submit → Save to backend, show confirmation

39. **Amenities Module**
    - `AmenitiesListScreen` - List available amenities with price/capacity
    - `BookAmenityScreen` - Select dates/times, show total cost, submit booking
    - `MyBookingsScreen` - List pending/approved/rejected bookings

40. **Services Module**
    - `ServicesListScreen` - List available services
    - `BookServiceScreen` - Select service, enter description, date, submit
    - `MyServicesScreen` - Track service requests

41. **Chat Module**
    - `ChatsListScreen` - List active chats (Residents tab, Admins tab)
    - `ChatDetailScreen` - Message history + input field + send button
    - Trigger push notification on message receive

42. **Notices & Alerts**
    - `NoticesScreen` - List building notices
    - `EmergencyAlertsScreen` - Float/banner alert when emergency received (via FCM)

43. **Complaints**
    - `ComplaintsListScreen` - List filed complaints
    - `FileComplaintScreen` - Category dropdown, description, submit

44. **Profile Screen**
    - User profile: Name, phone, family members, daily help staff
    - Family members: Display with option to add (→ auto-gatepass button), remove
    - Daily help: Display with add/remove options
    - Gate pass for each family/help member
    - Settings menu: Language, Support, Logout

### Firebase Integration
45. **Notification Handling**
    - On app startup, initialize Firebase, get FCM token
    - Send token to backend (`POST /fcm-tokens`)
    - Listen to FCM messages in foreground/background
    - Route notification to relevant screen based on type (visitor → gatepass detail, bill → bill detail, etc)
    - Show local notification with action buttons

**Phase 3 Checkpoint:**
- User app fully functional for: visitor management, bills, amenities, services, chat, notices, profile
- Login/OTP flow complete and stored
- API integration works for all modules
- FCM token registered with backend

---

## Phase 4: FLUTTER GUARD APP (society_guard)

### Project Setup
46. **Initialize Flutter Project** in `society_guard/`
    - Similar dependencies to user app: get, dio, firebase, plus:
      - `qr_code_scanner: ^2.3.0` (scan QR codes)
      - `qr_flutter: ^4.0.0` (display QR if guard enters code manually)

47. **GetX Pattern/Modular Architecture**
    ```
    lib/
    ├── app/
    │   ├── modules/
    │   │   ├── splash/
    │   │   ├── auth/
    │   │   ├── home/
    │   │   ├── visitor_verification/
    │   │   ├── in_out_list/
    │   │   ├── messages/
    │   │   ├── profile/
    │   │   └── ... modules
    │   ├── routes/
    │   └── widgets/
    ├── core/ (services, constants)
    └── main.dart
    ```

### Guard Screens

48. **Login Screen**
    - Email + password (guard credentials created by admin in panel)
    - Calls `AuthRepository.login()` (guard-specific endpoint)
    - Success → Navigate to Home

49. **Home Dashboard**
    - Large "Duty Status" toggle (check-in/check-out)
    - When toggled on: "On Duty" badge + green background
    - When toggled off: "Off Duty" badge + gray background
    - Status POST to `/guard/status` endpoint
    - Quick action buttons:
      - Scan Gatepass (QR code)
      - Enter Code (manual entry)
      - In/Out List
      - Messages

50. **Visitor Verification Screen**
    - Camera feed to scan QR code (or manual code entry field)
    - On scan/code entry:
      - Call `POST /guard/verify` with code
      - Display visitor details: Photo, Name, Type (Guest/Cab/Delivery/Service), Flat #, Valid dates
      - Show two buttons: "Check In" + "Check Out"
    - "Check In" → Log entry, show confirmation, return to camera
    - "Check Out" → Log exit, show confirmation with duration stayed, return to camera

51. **In/Out List Screen**
    - Tab view: Inside (current visitors) / Waiting (checked in but not out)
    - For each entry: Photo, name, type, flat, entry time, exit time (if out), duration
    - Swipe-to-logout gesture on waiting visitors
    - Pull-to-refresh to update list

52. **Messages Screen** (simplified chat)
    - `ChatsListScreen` - List messages from residents/admins
    - `ChatDetailScreen` - Read messages, reply functionality

53. **Profile / Settings**
    - Guard profile: Name, building, duty status history
    - Settings: Logout

### Guard API Integration
54. **Guard-Specific Endpoints** (already in Phase 1 backend, but guard app calls them)
    - POST `/guard/verify` - With QR/entry code, returns gatepass + visitor details
    - POST `/guard/logs` - With action (entry/exit), timestamp, gatepass_id
    - GET `/guard/logs` - Own duty logs
    - PUT `/guard/status` - Toggle on/off duty
    - GET `/guard/messages` - Incoming messages

**Phase 4 Checkpoint:**
- Guard app fully functional
- Can scan QR and verify visitors
- Logs entry/exit with timestamps
- Messages received and can reply
- Duty status tracking live

---

## Phase 5: REALTIME FEATURES & NOTIFICATIONS

### Push Notification Events
55. **Setup Notification Triggers in Backend**
    - Create notification helper methods in services:
      - `sendNotificationToResident()` - Uses FirebaseService to send FCM
      - `sendNotificationToGuards()` - Broadcast to all guards in building
      - `sendNotificationToAdmins()` - Broadcast to building admins

56. **Visitor Approval Event**
    - When admin approves visitor: Send push to guard ("New visitor to be verified at Flat X")
    - When resident's visitor approved: Send push to resident with gatepass details

57. **Bill Generation Event**
    - Scheduler runs monthly → generates bills → sends push "New bill generated, amount ₹X"

58. **Service/Amenity Approval Event**
    - Admin approves service booking → send push to resident "Your service request approved"

59. **Notice Posted Event**
    - Admin creates notice → broadcast to all residents in building

60. **Emergency Alert Event**
    - Admin sends emergency → broadcast to all residents, admins, guards in building
    - Guard app shows persistent notification with alert details

61. **Chat Message Event**
    - New message received → push notification to other party
    - If in background, show notification; if foreground, show in-app banner

62. **Firebase Rules** (if using Realtime DB for status)
    - Guard duty status: Write to `/buildings/{id}/guards/{id}/status` for real-time updates

**Phase 5 Checkpoint:**
- All major system events trigger relevant push notifications
- Guard app knows immediately when new visitor to verify
- Residents get bill alerts, service approvals, notices
- Emergency alerts are persistent and visible

---

## Phase 6: TESTING & REFINEMENT

### API Testing
63. **Endpoint Testing** (Postman or automated)
    - Create Postman collection for all `/api/v1/*` routes
    - Test flow: Register → OTP → Login → Create building → Add residents → Pre-approve visitor → Approve → Generate gatepass → Guard verifies
    - Test error cases: Invalid OTP, unauthorized access, nonexistent resources

64. **Database Consistency**
    - Test cascade deletes: Remove resident → gatepass invalidates
    - Test duplicate prevention: Can't create same flat twice
    - Test multi-tenancy: Admin A can't access Building B data

### Flutter App Testing
65. **Integration Tests**
    - Test login flow end-to-end
    - Test API calls return data correctly
    - Test navigation between screens
    - Test local storage (token persistence)

66. **Manual Testing Checklist**
    - User app: Can resident add visitor → approve → get gatepass → view QR/code
    - Guard app: Can scan QR → see visitor → log entry/exit
    - Admin panel: Can create building, add residents, approve visitors
    - Notifications: Do FCM messages trigger correct screens?

### Performance & Documentation
67. **API Documentation**
    - Generate OpenAPI spec (Swagger) from Laravel routes
    - Document all 50+ endpoints with request/response examples
    - Authentication header required

68. **Deployment Readiness**
    - Environment variables documented (.env.example created)
    - Database backup script in place
    - Frontend build: Flutter release build for both apps
    - Backend: Ready for server deployment (AWS/DigitalOcean, etc)

69. **Known Limitations & Future Work**
    - Phase 1-5 achieves: Full visitor management, billing, amenities, real-time alerts
    - Not included in MVP but documented for roadmap:
      - Advanced analytics/reports
      - SMS notifications (SMS-only as fallback if FCM fails)
      - Audio/video call integration
      - Advanced complaint resolution workflow
      - Multiple family member gatepass booking

**Phase 6 Checkpoint:**
- All endpoints tested and working
- Both Flutter apps tested on device
- Documentation complete
- System is production-ready

---

## Implementation Dependencies & Parallelization

### Critical Path (Sequential Dependencies)
1. **Auth** (Foundation - blocks everything)
   ↓
2. **Buildings & Residents** (Data structure - blocks feature modules)
   ↓
3. **Feature Modules** (Can work on 2-3 in parallel conceptually, but solo dev does sequentially)
   - Visitor → Guards → Bills → Amenities → Services → Chat → Notices
   ↓
4. **API Testing** (Can test as each module completes)
   ↓
5. **Flutter Apps** (Both can be built in parallel if resources allow, but solo dev does User first, Guard second)
   ↓
6. **Notifications** (Depends on API stable)
   ↓
7. **Final Testing & Refinement**

### For Solo Developer: Recommended Sequence
- **Weeks 1-2**: Phase 1 Part 1 (Auth + Buildings + Residents + Guards + Family/Help)
- **Weeks 3-4**: Phase 1 Part 2 (Visitors + Bills + Amenities + Services)
- **Weeks 5-6**: Phase 1 Part 3 (Chat + Complaints + Notices + Alerts) + API Testing
- **Weeks 7-8**: Phase 2 (Superadmin Panel)
- **Weeks 9-11**: Phase 3 (User App)
- **Weeks 12**: Phase 4 (Guard App)
- **Weeks 13**: Phase 5 (Notifications - integrate with existing)
- **Weeks 14**: Phase 6 (Testing & Refinement)

---

## Critical Files to Create/Modify

### Backend (society_admin/)
- `app/Models/*` — All 20+ models with relationships
- `app/Http/Controllers/*` — 30+ controllers (one per resource)
- `app/Services/*` — Business logic isolated
- `app/Http/Resources/*` — API serializers
- `database/migrations/*` — 20+ migrations
- `routes/api.php` — All 50+ API endpoints
- `app/Http/Middleware/*` — Custom auth middleware
- `config/filesystems.php` — Storage config for payments/profiles

### Admin Panel (resources/views/)
- `layouts/app.blade.php` — Base template
- `dashboard/index.blade.php` — Super admin dashboard
- `buildings/index.blade.php` — Building list & create
- `residents/index.blade.php` — Resident management
- `settings/otp-configuration.blade.php` — OTP & BulkSMSBD config
- `visitors/index.blade.php` — Visitor approvals
- `bills/index.blade.php` — Billing UI
- `amenities/index.blade.php` — Amenity management
- `analytics/reports.blade.php` — Reports

### User App (lib/)
- `main.dart` — App entry, routing, theming
- `app/modules/*/` — Each module with bindings, controllers, views
- `core/services/` — DioClient, Firebase, LocalStorage
- `pubspec.yaml` — All dependencies

### Guard App (lib/)
- `main.dart` — App entry
- `app/modules/*/` — Guard-specific modules
- `core/services/` — QR scanner, Firebase
- `pubspec.yaml` — Dependencies

---

## Success Criteria & Verification

✓ **Backend Complete**: All 13 modules have CRUD API endpoints, database is normalized, multi-tenancy works
✓ **Admin Panel Complete**: Super admin & building admin can manage buildings/residents/approvals, OTP settings configurable
✓ **User App Complete**: Residents can request visitors, pay bills, book amenities, chat, get notifications
✓ **Guard App Complete**: Guards can verify visitors via QR, log entry/exit, receive alerts
✓ **Notifications Complete**: FCM pushes notify users of all major events (visitor approval, bill, service, emergency, notice)
✓ **Testing Complete**: API tests pass, Flutter apps tested on device, no critical bugs
✓ **Documentation Complete**: API docs (Swagger), architecture overview, deployment guide ready

---

## Key Decisions Made

| Decision | Choice | Reason |
|----------|--------|--------|
| **Flutter Architecture** | GetX Pattern / Modular | Cleaner module separation, easier to maintain and scale |
| **Backend Architecture** | Service Layer (Controller → Service → Repository) | Testable, maintainable, isolated business logic |
| **State Management** | GetX | Simple, fast, suitable for MVP |
| **Database** | Single MySQL, app-level multi-tenancy | Cost-effective, simpler than separate DBs per tenant |
| **Notifications** | Firebase Cloud Messaging | Real-time push, cross-platform, free tier |
| **File Storage** | Laravel Storage (local) | Can upgrade to S3 later without code changes |
| **API Auth** | Sanctum | Stateless, mobile-friendly, scalable |
| **Admin Auth** | Sessions | Simple for web, standard Laravel |
| **Chat MVP** | Polling | Simple to implement; WebSocket in v2 |
| **QR Format** | PNG from server | Can scan with standard camera app + qr_code_scanner |
| **OTP MVP** | OFF by default, Superadmin configurable | Safe default, gives control to platform operator |
| **Visitor Types** | enum (Guest/Cab/Delivery/Service) | Simplifies approval workflow and gatepass |
| **Billing Payment** | Offline with screenshot | MVP simplicity; add payment gateway in v2 |

---

## Ready for Implementation!

This plan is comprehensive and ready for execution. Review the checkpoints and timeline, then proceed phase-by-phase. Each phase has clear deliverables and success criteria for validation.
