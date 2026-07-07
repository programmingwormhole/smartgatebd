# Notification System Integration Summary

## Overview
The notification system has been fully integrated across the SmartGateBD backend and frontend. Now every push notification sent to users is also stored in the database, ensuring no notifications are missed.

## ✅ Backend Integration Points

### 1. **Bill Notifications** 
**File:** `GenerateBills.php`  
**When:** Automated bill generation  
**Who:** Residents receive notifications about new bills  
**Status:** ✅ Integrated - DB + Push

```php
// Residents notified about new bills
NotificationController::createNotification(
    $resident->user->id,
    'New Bill Generated',
    'A new ' . $bill->type . ' bill of ৳' . $bill->amount . ' has been generated',
    'info',
    'bill',
    $bill->id
);
```

---

### 2. **Amenity/Booking Notifications**
**File:** `BookingController.php`  
**When:** Resident books an amenity  
**Who:** Building admins receive notification  
**Status:** ✅ Integrated - DB + Push

```php
// Admins notified about new booking requests
NotificationController::createNotification(
    $admin->id,
    'New Amenity Booking Request',
    "A new booking request for {$amenity->name}",
    'info',
    'amenity_booking',
    $booking->id
);
```

---

### 3. **Payment Notifications**
**File:** `PaymentController.php`  
**When:** Resident submits payment for approval  
**Who:** Building admins receive notification  
**Status:** ✅ Integrated - DB + Push

```php
// Admins notified about new payments
NotificationController::createNotification(
    $admin->id,
    'New Payment Submitted',
    "Payment for bill #{$bill->id} has been submitted for approval",
    'info',
    'payment',
    $payment->id
);
```

---

### 4. **Complaint Notifications**
**File:** `ComplaintController.php`  
**When:** 
- Resident submits a complaint
- Admin updates complaint status  

**Who:** 
- Admins receive notification of new complaints
- Residents receive notification of status updates  

**Status:** ✅ Integrated - DB + Push

```php
// Admins notified of new complaints
NotificationController::createNotification(
    $admin->id,
    'New Complaint Submitted',
    "Complaint: {$complaint->title}",
    'alert',
    'complaint',
    $complaint->id
);

// Residents notified of status updates
NotificationController::createNotification(
    $complaint->resident->user->id,
    'Complaint Status Updated',
    'Your complaint "' . $complaint->title . '" is now ' . $new_status,
    'success', // if resolved
    'complaint',
    $complaint->id
);
```

---

### 5. **Service Request Notifications**
**File:** `ServiceBookingController.php`  
**When:** Resident requests a service  
**Who:** Building admins receive notification  
**Status:** ✅ Integrated - DB + Push

```php
// Admins notified about new service requests
NotificationController::createNotification(
    $admin->id,
    'New Service Request',
    "New request for " . $booking->service->name,
    'info',
    'service_booking',
    $booking->id
);
```

---

### 6. **Emergency Alert Notifications**
**File:** `EmergencyController.php`  
**When:** Emergency alert is triggered  
**Who:** All building users (residents + admins) receive notification  
**Status:** ✅ Integrated - DB + Push

```php
// All building users notified of emergency
NotificationController::createNotification(
    $user->id,
    'Emergency: ' . $alert->type,
    $alert->message,
    'alert', // Red/Critical
    'emergency',
    $alert->id
);
```

---

## 🔧 Helper Class

**File:** `app/Helpers/NotificationHelper.php`

Contains utility methods used by controllers:

```php
// Get all admin users in a building
NotificationHelper::getBuildingAdmins($buildingId);

// Get all users in a building
NotificationHelper::getBuildingUsers($buildingId);
```

---

## 📱 Frontend Features

### Notification Screen
- View all notifications (paginated)
- Mark individual notifications as read
- Mark all as read
- Delete notifications
- Color-coded by type (info, success, warning, alert)
- Relative time display ("2h ago", "yesterday", etc)

### Notification Badge
- Red badge on notification icon
- Shows unread count (99+ max)
- Auto-updates when notifications are marked as read
- Available in both:
  - User app (HomeScreen)
  - Admin app (AdminDashboardScreen)

### Notification Types & Colors

| Type | Color | Use Case |
|------|-------|----------|
| info | Blue | Bills, bookings, general updates |
| success | Green | Complaint resolved, payment approved |
| warning | Orange | Alerts, important notices |
| alert | Red | Complaints, emergencies |

---

## 🔄 Data Flow

```
1. Event Occurs (Bill Generated, Complaint Filed, etc)
   ↓
2. Backend Creates Notification Record in DB
   ↓
3. Firebase Push Notification Sent (if user has FCM token)
   ↓
4. User Sees:
   a) Push notification (if app is in background)
   b) In-app notification badge (if app is open)
   ↓
5. User Opens App → Sees Notification Screen
   ↓
6. User Taps Notification → Marked as Read
   ↓
7. Badge Count Updated in Real-Time
```

---

## 📊 Database Schema

```sql
notifications table:
- id (Primary Key)
- user_id (Foreign Key → users)
- title (String)
- message (Text)
- type (String: info, warning, success, alert)
- ref_type (String: null or specific type)
- ref_id (BigInt: ID of referenced entity)
- is_read (Boolean)
- read_at (Timestamp: null until read)
- created_at (Timestamp)
- updated_at (Timestamp)

Indexes:
- (user_id, is_read) - For fetching unread count
- created_at - For sorting
```

---

## 🚀 How to Add New Notification Triggers

### Example: Notify About a New Visitor

```php
// In VisitorController.php

$visitor = Visitor::create($data);

// Create database notification
NotificationController::createNotification(
    $resident->user->id,
    'New Visitor',
    $visitor->name . ' has arrived at the gate',
    'info',
    'visitor',
    $visitor->id
);

// Send push notification (existing code)
$firebase = app(\App\Services\FirebaseService::class);
$firebase->sendNotification(
    $tokens,
    'New Visitor',
    $visitor->name . ' has arrived at the gate',
    ['type' => 'visitor', 'id' => (string)$visitor->id]
);
```

---

## ✨ Benefits

✅ **No Missed Notifications** - All notifications stored in DB, not just pushed  
✅ **Persistent History** - Users can view past notifications anytime  
✅ **Better UX** - Badge shows unread count, encouraging users to check  
✅ **Flexible Reference** - Can extend to view full content of referenced entity  
✅ **Professional** - Enterprise-grade notification system  
✅ **Scalable** - Works for any type of notification  

---

## 🧪 Testing

### Test Notification Creation
```bash
php artisan tinker

# Create a test notification
App\Http\Controllers\NotificationController::createNotification(
    1, // user_id
    'Test Notification',
    'This is a test',
    'info',
    'test',
    1
);

# Verify in database
App\Models\Notification::latest()->first();
```

### Test API Endpoints
```bash
# Get all notifications
curl -H "Authorization: Bearer TOKEN" http://localhost:8000/api/v1/notifications

# Get unread count
curl -H "Authorization: Bearer TOKEN" http://localhost:8000/api/v1/notifications/unread-count

# Mark as read
curl -X POST -H "Authorization: Bearer TOKEN" http://localhost:8000/api/v1/notifications/{id}/read
```

---

## 📝 Future Enhancements

- [ ] Notification preferences (user can disable certain types)
- [ ] Email summaries of unread notifications
- [ ] Deep linking to view referenced entity
- [ ] Notification grouping/threading
- [ ] Scheduled notifications
- [ ] Notification templates with custom placeholders

---

## 🔗 Related Files

- Backend: `/society_admin/app/Http/Controllers/NotificationController.php`
- Models: `/society_admin/app/Models/Notification.php`
- Helper: `/society_admin/app/Helpers/NotificationHelper.php`
- Frontend: `/society_user/lib/controllers/notification_controller.dart`
- UI: `/society_user/lib/screens/notifications/notification_screen.dart`
- Services: `/society_user/lib/services/notification_api_service.dart`
