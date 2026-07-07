# Notification System Documentation

## Overview
A professional notification system that stores notifications in the database and displays them in both user and admin apps with unread badge counts.

## Backend (Laravel) - How to Trigger Notifications

### Basic Usage
```php
use App\Http\Controllers\NotificationController;

// Create a notification
NotificationController::createNotification(
    userId: $userId,
    title: 'New Visitor',
    message: 'John Doe has arrived at the gate',
    type: 'info', // info, warning, success, alert
    refType: 'visitor', // optional: visitor, complaint, payment, booking, guard, etc
    refId: $visitorId // optional: ID of the referenced entity
);
```

### Example - When a Visitor Arrives
In your `VisitorController@store()`:
```php
// After creating visitor...
NotificationController::createNotification(
    userId: $flat->resident->user_id,
    title: 'New Visitor Arrival',
    message: $visitor->name . ' has arrived. Flat: ' . $flat->flat_number,
    type: 'info',
    refType: 'visitor',
    refId: $visitor->id
);
```

### Example - When a Complaint is Resolved
In your `ComplaintController@update()`:
```php
if ($complaint->status === 'resolved') {
    NotificationController::createNotification(
        userId: $complaint->resident->user_id,
        title: 'Complaint Resolved',
        message: 'Your complaint: "' . $complaint->title . '" has been resolved',
        type: 'success',
        refType: 'complaint',
        refId: $complaint->id
    );
}
```

### Example - Admin Notifications
For admin notifications, use the user's building admin:
```php
// Notify all building admins of something
$adminUsers = User::where('role', 'admin')
    ->whereHas('resident', function($q) use ($buildingId) {
        $q->where('building_id', $buildingId);
    })->get();

foreach ($adminUsers as $admin) {
    NotificationController::createNotification(
        userId: $admin->id,
        title: 'New Complaint',
        message: 'A new complaint has been filed: ' . $complaint->title,
        type: 'alert',
        refType: 'complaint',
        refId: $complaint->id
    );
}
```

## Notification Types
- **info**: General information (blue)
- **success**: Positive outcomes (green)
- **warning**: Important notices (orange)
- **alert**: Urgent/critical issues (red)

## API Endpoints

### Get All Notifications
```
GET /api/v1/notifications?page=1
Response: {
  "notifications": [...],
  "total": 100,
  "unread_count": 5
}
```

### Get Unread Count
```
GET /api/v1/notifications/unread-count
Response: {
  "unread_count": 5
}
```

### Mark as Read
```
POST /api/v1/notifications/{id}/read
Response: { "message": "Notification marked as read" }
```

### Mark All as Read
```
POST /api/v1/notifications/read-all
Response: { "message": "All notifications marked as read" }
```

### Delete Notification
```
DELETE /api/v1/notifications/{id}
Response: { "message": "Notification deleted" }
```

## Frontend (Flutter) - Usage

### Notification Screen
- Automatically shows all notifications with unread badge
- Pull-to-refresh to fetch latest
- Tap to mark as read
- Swipe to delete
- "Mark All as Read" button in appbar

### Notification Badge
- Appears in appbar notification icon
- Shows count of unread notifications
- Shows "99+" if more than 99 unread

### Getting Notification Controller
```dart
final notificationController = Get.find<NotificationController>();

// Get unread count
int unread = notificationController.unreadCount;

// Get all notifications
List notifications = notificationController.notifications;
```

### Manual Notification Trigger
Use the helper to show in-app notifications and refresh the notification list:
```dart
import 'package:your_app/helpers/notification_helper.dart';

NotificationHelper.notifyUser(
  title: 'Payment Received',
  message: 'Monthly maintenance payment received',
  type: 'success',
  refType: 'payment',
  refId: paymentId,
);
```

## Migration
Run the migration to create the notifications table:
```bash
php artisan migrate
```

## Database Schema
```
notifications
- id (PK)
- user_id (FK)
- title (string)
- message (text)
- type (enum: info, warning, success, alert)
- ref_type (nullable: visitor, complaint, payment, booking, guard, etc)
- ref_id (nullable)
- is_read (boolean)
- read_at (timestamp, nullable)
- created_at (timestamp)
- updated_at (timestamp)

Indexes:
- (user_id, is_read)
- created_at
```

## Best Practices
1. **Always provide meaningful titles and messages** - Users need to understand what the notification is about
2. **Use appropriate types** - Helps users prioritize their attention
3. **Include ref_type and ref_id** - Allows future functionality like clicking to view the referenced item
4. **Limit high-frequency notifications** - Avoid notification fatigue
5. **Test with real users** - Ensure notifications are helpful, not annoying
