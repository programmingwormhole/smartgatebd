# Quick Reference: Toggle Database Notifications

## Current Status: ❌ DISABLED

Database notifications are currently **disabled** in the Flutter apps.

---

## To Enable Database Notifications

Edit this ONE file:

**File**: `/Volumes/Project/Client Project/SmartGateBD/society_user/lib/core/constants/app_config.dart`

**Change this line**:
```dart
static const bool showDBNotification = false;  // ← CHANGE THIS
```

**To this**:
```dart
static const bool showDBNotification = true;   // ← TO THIS
```

Then rebuild and run the app.

---

## Affected When Enabled

✅ Notification icons appear in:
- Home screen (top right)
- Admin dashboard (app bar)

✅ Notification screen shows:
- List of all notifications
- Unread count badge
- Mark as read buttons
- Delete notification buttons

✅ API calls resume:
- Periodic fetch every 10 seconds
- Manual refresh on page updates

---

## What's Always Working (Regardless of Setting)

✅ **Push Notifications** (Firebase FCM)
- Still active at all times
- Independent of this setting
- Users still receive notifications via Firebase

✅ **Backend Database**
- Notifications still created in database
- Still available via API endpoints
- Still being stored for future retrieval

---

## When to Enable

- Development/Testing notifications feature
- When you want notification badges visible
- When you want periodic polling
- To test the complete notification system

## When to Keep Disabled

- Production (current setting)
- To reduce API calls
- To simplify UI
- When push notifications are sufficient
- To test push-notifications-only flow

---

## Files That Auto-Adapt

These files automatically check the config and adapt:

1. **NotificationController** - Skips all API calls
2. **home_screen.dart** - Hides notification icon
3. **admin_dashboard_screen.dart** - Hides notification icon  
4. **notification_screen.dart** - Shows "Disabled" message
5. **pay_bill_screen.dart** - Already has no refresh call
6. **admin_bills_screen.dart** - Already has no refresh call

No other changes needed - it's all feature flag based!

---

## Testing Checklist for Disabled State

- [ ] App launches without errors
- [ ] No notification icons visible
- [ ] No notification badge count shown
- [ ] Notification screen shows "Disabled" message when navigated to
- [ ] Bill payment works normally
- [ ] Bulk bill generation works normally
- [ ] Push notifications still arrive from Firebase
- [ ] No console errors or API call errors
- [ ] Settings screen is unaffected
- [ ] All other features work normally

---

**Last Updated**: March 11, 2026
