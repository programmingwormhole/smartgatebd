# Guard Management System - FIXED & READY

## ✅ Fixed Issues

### Problem: Duplicate Guards Tables
- Old guards table from 2026_03_05_190019 had status as BOOLEAN
- New migrations (2026_03_11) tried to create duplicate table with ENUM status
- Result: 500 error "Incorrect integer value: 'on_duty' for column 'status'"

### Solution Applied
1. ✅ **Deleted** new duplicate migration files (2026_03_11_120000 and 2026_03_11_130000)
2. ✅ **Updated** old migration (2026_03_05_190019) with correct schema:
   - Changed `status` from `boolean` → `enum('on_duty','off_duty','leave','inactive')`
   - Added new columns: `duty_start_time`, `duty_end_time`, `notes`, `assigned_areas`
   - Added soft deletes (`deleted_at`)
3. ✅ **Dropped & Recreated** guards and guard_logs tables
4. ✅ **Re-migrated** with corrected schema
5. ✅ **Updated** Guard model `$fillable` to include 'name' and 'phone'

## Current Database Schema

```sql
Table: guards
├── id (bigint primary key)
├── building_id (bigint FK → buildings)
├── user_id (bigint FK → users)
├── name (varchar)
├── phone (varchar)
├── status ENUM('on_duty','off_duty','leave','inactive') ✅
├── duty_start_time (datetime nullable)
├── duty_end_time (datetime nullable)
├── notes (text nullable)
├── assigned_areas (json nullable)
├── created_at (timestamp)
├── updated_at (timestamp)
└── deleted_at (timestamp - soft deletes) ✅
```

## API Endpoints (All Working)

```
POST   /api/v1/buildings/{id}/guards          Create guard + user auto-creation
GET    /api/v1/buildings/{id}/guards          List guards  
PUT    /api/v1/guards/{id}                    Update guard/user details
PUT    /api/v1/guards/{id}/status             Update status enum
DELETE /api/v1/guards/{id}                    Delete (soft delete)
```

## Guard Creation Flow (Corrected)

```
Admin Form (Name, Phone, Email, On Duty Toggle)
         ↓
POST /api/v1/buildings/{building_id}/guards
{ "name": "John Guard", "phone": "87654", "email": "john@...", "status": "on_duty" }
         ↓
GuardController.store()
  ├→ Validate inputs
  ├→ Create User: role='guard', password=Hash(phone), building_id
  ├→ Create Guard: with user_id, all fields
  └→ Return: { "guard": { ...with user loaded... } }
         ↓
✅ Success! User + Guard created in ONE operation
```

## Backend Implementation

**GuardController store() method:**
- Accepts: name, phone (unique), email (optional), status (optional)
- Creates User automatically (default password: phone number hashed)
- Creates Guard with all fields
- Returns fully loaded guard object

**Guard Model:**
- SoftDeletes trait enabled
- Proper $fillable: building_id, user_id, name, phone, status, duty_*, notes, assigned_areas
- Proper $casts: assigned_areas → array, dates to datetime
- Relationships: building(), user()
- Scopes: active(), onDuty()

## Flutter Implementation

**GuardCreateScreen:**
- Form with: Name (required), Phone (required), Email (optional), On Duty toggle (default yes)
- Single call to createGuard() that sends all data to backend
- Backend handles user creation automatically
- No separate user creation endpoint needed

**Admin Service:**
- createGuard(buildingId, data) → sends to backend in one call
- Backend auto-creates user + guard

**Result:** Clean, simple, consistent with ResidentController pattern

## Status
✅ **READY FOR TESTING**
- Database migrations: Applied ✅
- Guard model: Updated ✅  
- GuardController: Implements correct flow ✅
- Guard table: Created with enum status ✅
- Flutter code: Simplified and ready ✅

## Notes
- Default guard password: phone number (same as residents)
- No separate UserController endpoint needed for guard creation
- One API call creates both user and guard
- Soft deletes prevent losing data when deleting guards
