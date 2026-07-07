# Quick Implementation Guide - Offline Payment Gateway Management

## What Was Added

New admin dashboard option to manage offline payment gateways (bKash, Nagad, Bank Transfers, etc.).

---

## Quick Start

### 1. Deploy Backend Changes
```bash
cd /Volumes/Project/Client Project/SmartGateBD/society_admin
php artisan optimize:clear
```

**Files Changed**:
- `app/Http/Controllers/PaymentGatewayController.php` - Added CRUD methods
- `routes/api.php` - Added 4 API routes for payment gateways

### 2. Test Backend API
```bash
# Get all gateways (admin)
curl -X GET http://localhost:8000/api/v1/payment-gateways \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create gateway
curl -X POST http://localhost:8000/api/v1/payment-gateways \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "bKash",
    "account_type": "bkash",
    "account_number": "+8801700000000",
    "is_active": true,
    "required_fields": ["trx_id", "screenshot"]
  }'
```

### 3. Update Flutter App
No additional dependencies needed. New files created:
- `lib/services/payment_gateway_service.dart`
- `lib/controllers/payment_gateway_controller.dart`
- `lib/screens/admin/management/payment_gateway_management_screen.dart`

Modified:
- `lib/screens/admin/management/society_management_screen.dart`

### 4. Access in Flutter App

**Navigation Path**:
```
Admin Dashboard 
  → Admin icon (right corner)
    → Admin Panel
      → Society Management
        → Payment Gateways (NEW)
```

---

## API Endpoints

All endpoints require authentication (`auth:sanctum`)

### List All Gateways
```
GET /api/v1/payment-gateways
```

**Response**:
```json
{
  "gateways": [...],
  "total": 5
}
```

### Create Gateway
```
POST /api/v1/payment-gateways
```

**Body**:
```json
{
  "name": "gateway_name",
  "account_type": "bkash|nagad|bank|...",
  "account_number": "phone_or_account",
  "is_active": true,
  "required_fields": ["trx_id", "screenshot"]
}
```

### Update Gateway
```
PUT /api/v1/payment-gateways/{id}
```

**Body**: Same as create

### Delete Gateway
```
DELETE /api/v1/payment-gateways/{id}
```

---

## UI Components

### Payment Gateway Management Screen
- **Location**: `Tab → Admin → Society Management → Payment Gateways`
- **FloatingActionButton**: Add new gateway
- **List of Gateways**: Shows name, type, account number, status
- **Edit Button**: Modify gateway details
- **Delete Button**: Remove gateway with confirmation
- **Toggle**: Active/Inactive status
- **Pull-to-Refresh**: Reload list

### Form Dialog
- Gateway name (text field)
- Account type (dropdown with 8 options)
- Account number (text field)
- Active status (checkbox)
- Save/Update button

---

## Account Types Available

```
• bank      - Traditional bank transfer
• bkash     - bKash mobile banking
• nagad     - Nagad mobile banking
• rocket    - Rocket mobile banking
• upi       - UPI payment
• cash      - Cash payment
• check     - Check payment
• other     - Other methods
```

---

## Testing Steps

### 1. Add Payment Gateway
1. Login as admin
2. Go to Society Management
3. Tap "Payment Gateways"
4. Tap FAB (+)
5. Fill form:
   - Name: "bKash Mobile"
   - Type: "bkash"
   - Number: "+8801700000000"
   - Active: ✓ Checked
6. Tap "Create"
7. Verify snackbar "Gateway created successfully"

### 2. Edit Payment Gateway
1. On Payment Gateways list
2. Find gateway card
3. Tap "Edit" button
4. Modify details
5. Tap "Update"
6. Verify snackbar

### 3. Delete Payment Gateway
1. On Payment Gateways list
2. Find gateway card
3. Tap "Delete" button
4. Confirm deletion
5. Verify snackbar and list updates

### 4. Toggle Active Status
1. Add gateway as "Active"
2. Edit gateway
3. Uncheck "Active"
4. Save
5. Verify badge changes to "Inactive"

---

## Database Verification

Check if gateways are saved:
```sql
SELECT * FROM payment_gateways WHERE building_id = 1;
```

Expected columns:
- id
- building_id
- name
- account_type
- account_number
- required_fields (JSON)
- is_active
- created_at
- updated_at

---

## Troubleshooting

### Issue: "No Payment Gateways" message appears
**Solution**: 
- Check internet connection
- Verify API endpoint is accessible
- Check Laravel server is running

### Issue: Create button doesn't work
**Solution**:
- Verify all fields are filled
- Check that account type dropdown has a selection
- Look for validation error snackbar

### Issue: API returns 403 Unauthorized
**Solution**:
- Verify auth token is valid
- Check user is building admin
- Confirm building_id matches user's building

### Issue: Gateway list doesn't refresh
**Solution**:
- Check console for errors
- Verify API response format
- Pull down to refresh manually
- Restart app

---

## Code Examples

### Using Payment Gateways in Your Own Screen
```dart
// Import controller
import 'package:your_app/controllers/payment_gateway_controller.dart';

// In your widget
final controller = Get.put(PaymentGatewayController());

// Access gateways
Obx(() {
  return ListView.builder(
    itemCount: controller.gateways.length,
    itemBuilder: (context, index) {
      final gateway = controller.gateways[index];
      return Text(gateway['name']);
    },
  );
});
```

### Creating Gateway Programmatically
```dart
final controller = Get.find<PaymentGatewayController>();
bool success = await controller.createPaymentGateway({
  'name': 'My Gateway',
  'account_type': 'bank',
  'account_number': '1234567890',
  'is_active': true,
  'required_fields': ['trx_id'],
});
```

---

## Files Changed

### Backend
```
✓ app/Http/Controllers/PaymentGatewayController.php
✓ routes/api.php
```

### Frontend  
```
✓ lib/services/payment_gateway_service.dart (NEW)
✓ lib/controllers/payment_gateway_controller.dart (NEW)
✓ lib/screens/admin/management/payment_gateway_management_screen.dart (NEW)
✓ lib/screens/admin/management/society_management_screen.dart (MODIFIED)
```

---

## Support

For issues or questions:
1. Check the detailed implementation doc: `PAYMENT_GATEWAY_MANAGEMENT_IMPLEMENTATION.md`
2. Review API responses in console
3. Check database records
4. Verify authentication tokens

---

**Date**: March 11, 2026
**Version**: 1.0
**Status**: Ready for Testing
