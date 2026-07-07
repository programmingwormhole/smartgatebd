# Quick Testing Guide - Notification System

## Devices/Emulators Setup

You'll need:
- **Admin App** (society_admin): Running on web/mobile to test admin receiving notifications
- **User App** (society_user): Running on emulator/device to test user receiving notifications

## Test Scenario 1: Bill Generation Notification

### Step 1: Start Apps
```bash
# Terminal 1: Admin Backend API
cd /Volumes/Project/Client\ Project/SmartGateBD/society_admin
php artisan serve  # Runs on localhost:8000 (or as configured)

# Terminal 2: User App
cd /Volumes/Project/Client\ Project/SmartGateBD/society_user
flutter run

# Terminal 3: Admin App (if web)
cd /Volumes/Project/Client\ Project/SmartGateBD/society_admin
# Open admin web/app
```

### Step 2: Generate Test Bills
```bash
# Terminal 4: Start bill generation
cd /Volumes/Project/Client\ Project/SmartGateBD/society_admin
php artisan bills:generate --demo
```

Expected output:
```
✓ Generated Maintenance bill for Test Resident fdgdfg (Flat A-101) - ৳1000.00
✓ Generated Maintenance bill for Admin John (Flat A-101) - ৳1000.00
...
✅ Successfully generated 7 bills for March 2026
```

### Step 3: Verify Notifications in User App

**Expected result:** User sees notification within 10 seconds

1. **User App (society_user):**
   - Look at **HomeScreen** (top right corner)
   - Should see **red badge with "1"** (unread count)
   - Tap the **bell icon**
   - You should see "New Bill Generated" notifications

2. **If no notification appears:**
   - Pull down on NotificationScreen to manually refresh
   - Wait max 10 seconds and check again
   - Verify network connection to backend API

## Test Scenario 2: Payment Submission Notification

### Step 1: User Submits Payment
In **society_user** app:
1. Go to Bills screen
2. Select a bill
3. Tap "Pay" button
4. Select payment gateway
5. Fill in transaction ID and screenshot
6. Tap "Submit"
7. See success message: "Payment submitted successfully. Waiting for admin approval."

### Step 2: Admin Receives Notification
In **society_admin** app:
1. Open NotificationScreen
2. Should see "New Payment Submitted" notification within 10 seconds
3. Unread count badge updates
4. Can pull-down to refresh immediately

Expected notification title: "New Payment Submitted"
Expected notification body: "Payment for bill #{bill_id} has been submitted for approval."

## Test Scenario 3: Persistent State Across Navigation

### Step 1: Setup
1. User app open with NotificationScreen showing 3 notifications
2. Unread count: 3

### Step 2: Navigate Away
1. Tap back to HomeScreen
2. Navigate to BillsScreen
3. Navigate to OtherScreen

### Step 3: Verify
1. Return to NotificationScreen
2. **Same 3 notifications should still be there** ✅
3. Unread count should be consistent across all screens

### Step 4: Generate Another Bill
1. In terminal, run `php artisan bills:generate --demo` again
2. Return to HomeScreen
3. Unread count should increment automatically
4. Pull down on NotificationScreen

## Test Scenario 4: Mark as Read

### Step 1: Open NotificationScreen
- Should see multiple "New Bill Generated" notifications
- Unread count in badge: e.g., "5"

### Step 2: Tap Notification
- Notification background color changes (read state)
- Unread count decreases: 5 → 4

### Step 3: Mark All as Read
1. Tap "Mark All as Read" button (top right)
2. All notifications should change appearance
3. Unread count → "0"
4. Badge disappears from bell icon

## Test Scenario 5: Manual Refresh

### Step 1: Enter NotificationScreen
- May take up to 10 seconds to see new notifications

### Step 2: Pull Down
- Gesture: Drag from top of list downward
- RefreshIndicator appears with spinning animation
- Notifications update immediately

### Step 3: Verify
- Should see latest notifications within 1 second
- No need to wait for 10-second poll

## Debugging Checklist

If notifications don't appear:

- [ ] Backend API running? Check: `curl http://localhost:8000/api/notifications`
- [ ] Logged in? NotificationController requires authenticated user
- [ ] Database notifications created? 
  ```bash
  php artisan tinker
  > DB::table('notifications')->latest()->first();
  ```
- [ ] API endpoint working?
  ```bash
  curl -H "Authorization: Bearer YOUR_TOKEN" \
       http://localhost:8000/api/notifications/unread-count
  ```
- [ ] Network tab showing requests? Check DevTools network tab
- [ ] Periodic refresh running? Check console for polling logs
- [ ] Singleton working? In Flutter console: 
  ```
  final c1 = NotificationController();
  final c2 = NotificationController();
  print(c1 == c2);  // Should be: true
  ```

## Database Queries for Verification

```bash
cd /Volumes/Project/Client\ Project/SmartGateBD/society_admin
php artisan tinker
```

### Check notifications created
```php
// Last 10 notifications
DB::table('notifications')->orderBy('created_at', 'desc')->limit(10)->get();

// Unread count for user (e.g., user_id = 2)
DB::table('notifications')->where('user_id', 2)->where('is_read', false)->count();

// Filter by type
DB::table('notifications')->where('type', 'info')->get();
```

## Expected API Responses

### Unread Count Endpoint
```
GET /api/notifications/unread-count

Response: {"unread_count": 5}
```

### List Notifications Endpoint
```
GET /api/notifications?page=1

Response: {
  "notifications": [
    {
      "id": 25,
      "user_id": 9,
      "title": "New Bill Generated",
      "message": "A new Maintenance bill of ৳1000.00...",
      "type": "info",
      "ref_type": "bill",
      "ref_id": "125",
      "is_read": false,
      "read_at": null,
      "created_at": "2024-03-15T10:30:00...",
      "updated_at": "2024-03-15T10:30:00..."
    },
    ...
  ]
}
```

## Performance Metrics

After implementing fixes:
- ✅ Notification appears within **10 seconds** (automatic) or **<1 second** (manual refresh)
- ✅ Unread count updates within **10 seconds** automatically
- ✅ Badge reflects true state across all screens simultaneously
- ✅ Pull-to-refresh completes in **<1 second**
- ✅ No data loss when navigating between screens

## Known Behavior

1. **First Load Delay:** May take up to 10 seconds on cold start
   - After app initializes and does first API call, periodic polling starts

2. **Background App:** Polling stops if app is minimized
   - Firebase push notifications still work (system level)
   - Polling resumes when app returns to foreground

3. **Offline Mode:** No automatic sync
   - Queue notification fetch when connection returns
   - (Future enhancement)

## Success Criteria

You've successfully fixed the notification system if:

✅ User generates bill → Resident sees notification within 10 seconds  
✅ Resident submits payment → Admin sees notification within 10 seconds  
✅ Pull-to-refresh triggers immediately                              
✅ Unread count badge updates in real-time                           
✅ Notifications persist across screen navigation                    
✅ Mark as read works correctly                                      
✅ No "fresh controller" behavior (notifications don't disappear)   

---

**Last Updated:** March 2024  
**Tested With:** Flutter 3.x, Laravel 10+, GetX state management
