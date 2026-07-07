<?php

namespace App\Http\Controllers;

use App\Models\Building;
use App\Models\Guard;
use App\Models\User;
use App\Models\Gatepass;
use App\Models\Visitor;
use App\Models\VisitorLog;
use App\Models\VisitorActivityLog;
use App\Models\Resident;
use App\Models\Family;
use App\Models\DailyHelp;
use App\Models\PermanentGatepassLog;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class GuardController extends Controller
{
    public function createWalkInVisitor(Request $request)
    {
        $data = $request->validate([
            'resident_id' => 'required|integer|exists:residents,id',
            'type' => 'required|in:guest,cab,delivery,service',
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:30',
            'vehicle_no' => 'nullable|string|max:100',
            'company_name' => 'nullable|string|max:255',
            'purpose' => 'nullable|string|max:500',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date|after_or_equal:from_date',
        ]);

        [$guard, $guardBuildingId] = $this->resolveGuardContext();
        $resident = Resident::with('flat.floor.block.building')->findOrFail($data['resident_id']);

        $residentBuildingId = (int) ($resident->flat?->floor?->block?->building?->id ?? 0);
        if ($residentBuildingId <= 0 || $residentBuildingId !== $guardBuildingId) {
            return response()->json(['message' => 'Resident is not in guard building'], 403);
        }

        $visitor = Visitor::create([
            'flat_id' => $resident->flat_id,
            'type' => $data['type'],
            'name' => $data['name'],
            'phone' => $data['phone'] ?? null,
            'vehicle_no' => $data['vehicle_no'] ?? null,
            'company_name' => $data['company_name'] ?? null,
            'purpose' => $data['purpose'] ?? 'Walk-in visitor added by guard',
            'from_date' => $data['from_date'] ?? now(),
            'to_date' => $data['to_date'] ?? now()->addHours(3),
            'status' => 'pending',
            'created_by_resident_id' => $resident->id,
        ]);

        $gatepass = $visitor->gatepass;
        if ($gatepass) {
            VisitorLog::create([
                'gatepass_id' => $gatepass->id,
                'guard_id' => $guard->id,
                'action' => 'created_pending',
                'timestamp' => now(),
            ]);
        }

        // Also log to VisitorActivityLog
        VisitorActivityLog::create([
            'building_id' => $guardBuildingId,
            'guard_id' => $guard->id,
            'resident_id' => $resident->id,
            'visitor_type' => 'temporary',
            'visitor_name' => $visitor->name,
            'visitor_phone' => $visitor->phone,
            'action' => 'created',
            'purpose' => $visitor->purpose,
            'gatepass_category' => 'walk-in',
            'visitor_id' => $visitor->id,
            'gatepass_id' => $gatepass?->id,
            'activity_date' => now(),
        ]);

        // Notify the resident that a walk-in visitor needs approval.
        $resident->loadMissing('user.fcmTokens');
        if ($resident->user) {
            NotificationController::createNotification(
                $resident->user->id,
                'Visitor Approval Needed',
                ($visitor->name ?? 'A visitor') . ' was added by guard and is waiting for your approval.',
                'info',
                'visitor',
                $visitor->id
            );

            $tokens = $resident->user->fcmTokens->pluck('device_token')->toArray();
            if (!empty($tokens)) {
                app(\App\Services\FirebaseService::class)->sendNotification(
                    $tokens,
                    'Visitor Approval Needed',
                    ($visitor->name ?? 'A visitor') . ' is waiting for your approval.',
                    [
                        'type' => 'visitor',
                        'id' => (string) $visitor->id,
                        'event' => 'walk_in_pending_approval',
                    ]
                );
            }
        }

        return response()->json([
            'message' => 'Walk-in visitor created and sent for approval',
            'visitor' => $visitor->fresh(['resident.user', 'gatepass']),
        ], 201);
    }

    public function index(Building $building)
    {
        return response()->json(['guards' => $building->guards()->with('user')->get()]);
    }

    public function store(Request $request, Building $building)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20|unique:users',
            'email' => 'nullable|email|unique:users',
            'status' => 'nullable|in:on_duty,off_duty,leave,inactive',
        ]);

        // Create the user automatically with phone as default password (like residents)
        $user = User::create([
            'name' => $data['name'],
            'phone' => $data['phone'],
            'email' => $data['email'],
            'password' => Hash::make($data['phone']), // Default password is their phone number
            'role' => 'guard', // System role for guards
            'building_id' => $building->id
        ]);

        $guard = Guard::create([
            'building_id' => $building->id,
            'user_id' => $user->id,
            'status' => $request->status ?? 'off_duty',
        ]);

        return response()->json(['guard' => $guard->load('user')], 201);
    }

    public function updateStatus(Request $request, Guard $guard)
    {
        $data = $request->validate([
            'status' => 'required|string|in:on_duty,off_duty,leave,inactive'
        ]);

        $guard->update($data);
        return response()->json($guard);
    }

    public function update(Request $request, Guard $guard)
    {
        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:20',
            'email' => 'nullable|email',
            'status' => 'sometimes|in:on_duty,off_duty,leave,inactive',
        ]);

        // Update user fields if provided
        if (isset($data['name']) || isset($data['phone']) || isset($data['email'])) {
            $userData = [];
            if (isset($data['name'])) $userData['name'] = $data['name'];
            if (isset($data['phone'])) $userData['phone'] = $data['phone'];
            if (isset($data['email'])) $userData['email'] = $data['email'];
            $guard->user->update($userData);
        }

        // Update guard-specific fields
        if (isset($data['status'])) {
            $guard->update(['status' => $data['status']]);
        }

        return response()->json($guard->load('user'));
    }

    public function destroy(Guard $guard)
    {
        $guard->delete();
        return response()->json(['message' => 'Guard deleted successfully']);
    }

    // ================================
    // Guard Visitor Management Methods
    // ================================

    /**
     * Verify visitor entry code and return visitor details
     */
    public function verifyEntryCode(Request $request)
    {
        $request->validate([
            'entry_code' => 'required|string'
        ]);

        [$guard, $guardBuildingId] = $this->resolveGuardContext();
        $entryCode = $request->query('entry_code');

        $gatepass = Gatepass::where('entry_code', $entryCode)
            ->orWhere('gatepass_code', $entryCode)
            ->with('visitor.resident.user')
            ->first();

        if ($gatepass) {
            $visitor = $gatepass->visitor;
            if ($visitor->status === 'rejected') {
                return response()->json(['message' => 'This visitor entry has been rejected'], 403);
            }

            $effectiveStatus = $visitor->status;
            if (
                $visitor->status === 'pending'
                && !empty($visitor->created_by_resident_id)
                && !empty($gatepass->id)
            ) {
                // Legacy compatibility for pre-approved resident visitors.
                $effectiveStatus = 'approved';
            }

            return response()->json([
                'visitor' => [
                    'id' => $visitor->id,
                    'gatepass_id' => $gatepass->id,
                    'pass_category' => 'visitor',
                    'guest_name' => $visitor->name,
                    'resident_name' => $visitor->resident?->user?->name ?? 'Unknown',
                    'resident_phone' => $visitor->resident?->user?->phone ?? '-',
                    'purpose' => $visitor->purpose,
                    'expected_checkout_time' => $visitor->to_date,
                    'entry_code' => $gatepass->entry_code,
                    'status' => $effectiveStatus,
                    'reject_reason' => $visitor->reject_reason,
                    'phone' => $visitor->phone,
                    'vehicle_no' => $visitor->vehicle_no,
                    'company_name' => $visitor->company_name,
                    'type' => $visitor->type,
                    'created_at' => $visitor->created_at,
                    'entry_time' => $gatepass->entry_time,
                    'exit_time' => $gatepass->exit_time,
                ]
            ], 200);
        }

        $family = Family::with('resident.user', 'resident.flat.floor.block.building')
            ->where('entry_code', $entryCode)
            ->first();

        if ($family) {
            $familyBuildingId = (int) ($family->resident?->flat?->floor?->block?->building?->id ?? 0);
            if (!$family->resident || $familyBuildingId !== $guardBuildingId) {
                return response()->json(['message' => 'Entry code not valid for this building'], 403);
            }
            $latestLog = PermanentGatepassLog::where('subject_type', 'family')
                ->latest('logged_at')
                ->first();
            $isInside = $latestLog?->action === 'entry';

            return response()->json([
                'visitor' => [
                    'id' => $family->id,
                    'pass_category' => 'permanent',
                    'permanent_type' => 'family',
                    'guest_name' => $family->name,
                    'resident_name' => $family->resident?->user?->name ?? 'Unknown',
                    'resident_phone' => $family->resident?->user?->phone ?? '-',
                    'purpose' => 'Family access',
                    'expected_checkout_time' => 'Permanent gatepass',
                    'entry_code' => $family->entry_code,
                    'status' => $isInside ? 'inside' : 'approved',
                    'phone' => $family->phone,
                    'type' => 'family',
                    'gatepass_enabled' => (bool) $family->gatepass_enabled,
                    'is_inside' => $isInside,
                    'entry_time' => $isInside ? $latestLog?->logged_at : null,
                    'exit_time' => !$isInside ? $latestLog?->logged_at : null,
                    'last_action_time' => $latestLog?->logged_at,
                ]
            ], 200);
        }

        $dailyHelp = DailyHelp::with('resident.user', 'resident.flat.floor.block.building')
            ->where('entry_code', $entryCode)
            ->first();

        if ($dailyHelp) {
            $dailyHelpBuildingId = (int) ($dailyHelp->resident?->flat?->floor?->block?->building?->id ?? 0);
            if (!$dailyHelp->resident || $dailyHelpBuildingId !== $guardBuildingId) {
                return response()->json(['message' => 'Entry code not valid for this building'], 403);
            }
            if (!$dailyHelp->gatepass_enabled) {
                return response()->json(['message' => 'Gatepass is disabled for this daily help member'], 403);
            }

            $latestLog = PermanentGatepassLog::where('subject_type', 'daily_help')
                ->where('subject_id', $dailyHelp->id)
                ->latest('logged_at')
                ->first();
            $isInside = $latestLog?->action === 'entry';

            return response()->json([
                'visitor' => [
                    'id' => $dailyHelp->id,
                    'pass_category' => 'permanent',
                    'permanent_type' => 'daily_help',
                    'guest_name' => $dailyHelp->name,
                    'resident_name' => $dailyHelp->resident?->user?->name ?? 'Unknown',
                    'resident_phone' => $dailyHelp->resident?->user?->phone ?? '-',
                    'purpose' => 'Daily help access',
                    'expected_checkout_time' => 'Permanent gatepass',
                    'entry_code' => $dailyHelp->entry_code,
                    'status' => $isInside ? 'inside' : 'approved',
                    'phone' => $dailyHelp->phone,
                    'type' => $dailyHelp->category,
                    'gatepass_enabled' => (bool) $dailyHelp->gatepass_enabled,
                    'is_inside' => $isInside,
                    'entry_time' => $isInside ? $latestLog?->logged_at : null,
                    'exit_time' => !$isInside ? $latestLog?->logged_at : null,
                    'last_action_time' => $latestLog?->logged_at,
                ]
            ], 200);
        }

        return response()->json(['message' => 'Invalid entry code'], 404);
    }

    public function markPermanentEntry(Request $request)
    {
        $data = $request->validate([
            'subject_type' => 'required|in:family,daily_help',
            'subject_id' => 'required|integer',
            'entry_code' => 'required|string',
        ]);

        [$guard, $guardBuildingId] = $this->resolveGuardContext();

        if ($data['subject_type'] === 'family') {
            $subject = Family::with('resident.flat.floor.block.building')->findOrFail($data['subject_id']);
        } else {
            $subject = DailyHelp::with('resident.flat.floor.block.building')->findOrFail($data['subject_id']);
        }

        $subjectBuildingId = (int) ($subject->resident?->flat?->floor?->block?->building?->id ?? 0);
        if (!$subject->resident || $subjectBuildingId !== $guardBuildingId) {
            return response()->json(['message' => 'Member is not assigned to guard building'], 403);
        }

        if (!$subject->gatepass_enabled || $subject->entry_code !== $data['entry_code']) {
            return response()->json(['message' => 'Gatepass is disabled or invalid'], 403);
        }

        $latestLog = PermanentGatepassLog::where('subject_type', $data['subject_type'])
            ->where('subject_id', $subject->id)
            ->latest('logged_at')
            ->first();

        if ($latestLog?->action === 'entry') {
            return response()->json(['message' => 'Member is already inside'], 422);
        }

        PermanentGatepassLog::create([
            'guard_id' => $guard->id,
            'resident_id' => $subject->resident_id,
            'subject_type' => $data['subject_type'],
            'subject_id' => $subject->id,
            'entry_code' => $subject->entry_code,
            'action' => 'entry',
            'logged_at' => now(),
        ]);

        // Log to VisitorActivityLog
        VisitorActivityLog::create([
            'building_id' => $guardBuildingId,
            'guard_id' => $guard->id,
            'resident_id' => $subject->resident_id,
            'visitor_type' => $data['subject_type'] === 'family' ? 'family' : 'daily_help',
            'visitor_name' => $subject->name,
            'visitor_phone' => $subject->phone,
            'entry_code' => $subject->entry_code,
            'action' => 'entry',
            'purpose' => $data['subject_type'] === 'family' ? 'Family access' : 'Daily help access',
            'gatepass_category' => 'permanent',
            'subject_type' => $data['subject_type'],
            'subject_id' => $subject->id,
            'activity_date' => now(),
        ]);

        return response()->json(['message' => 'Entry logged successfully'], 200);
    }

    public function markPermanentExit(Request $request)
    {
        $data = $request->validate([
            'subject_type' => 'required|in:family,daily_help',
            'subject_id' => 'required|integer',
            'entry_code' => 'required|string',
        ]);

        [$guard, $guardBuildingId] = $this->resolveGuardContext();

        if ($data['subject_type'] === 'family') {
            $subject = Family::with('resident.flat.floor.block.building')->findOrFail($data['subject_id']);
        } else {
            $subject = DailyHelp::with('resident.flat.floor.block.building')->findOrFail($data['subject_id']);
        }

        $subjectBuildingId = (int) ($subject->resident?->flat?->floor?->block?->building?->id ?? 0);
        if (!$subject->resident || $subjectBuildingId !== $guardBuildingId) {
            return response()->json(['message' => 'Member is not assigned to guard building'], 403);
        }

        if (!$subject->gatepass_enabled || $subject->entry_code !== $data['entry_code']) {
            return response()->json(['message' => 'Gatepass is disabled or invalid'], 403);
        }

        $latestLog = PermanentGatepassLog::where('subject_type', $data['subject_type'])
            ->where('subject_id', $subject->id)
            ->latest('logged_at')
            ->first();

        if (!$latestLog || $latestLog->action !== 'entry') {
            return response()->json(['message' => 'Member is not currently inside'], 422);
        }

        PermanentGatepassLog::create([
            'guard_id' => $guard->id,
            'resident_id' => $subject->resident_id,
            'subject_type' => $data['subject_type'],
            'subject_id' => $subject->id,
            'entry_code' => $subject->entry_code,
            'action' => 'exit',
            'logged_at' => now(),
        ]);

        // Log to VisitorActivityLog
        VisitorActivityLog::create([
            'building_id' => $guardBuildingId,
            'guard_id' => $guard->id,
            'resident_id' => $subject->resident_id,
            'visitor_type' => $data['subject_type'] === 'family' ? 'family' : 'daily_help',
            'visitor_name' => $subject->name,
            'visitor_phone' => $subject->phone,
            'entry_code' => $subject->entry_code,
            'action' => 'exit',
            'purpose' => $data['subject_type'] === 'family' ? 'Family access' : 'Daily help access',
            'gatepass_category' => 'permanent',
            'subject_type' => $data['subject_type'],
            'subject_id' => $subject->id,
            'activity_date' => now(),
        ]);

        return response()->json(['message' => 'Exit logged successfully'], 200);
    }

    /**
     * Confirm visitor entry (mark as 'inside')
     */
    public function confirmVisitorEntry(Request $request, Visitor $visitor)
    {
        $user = Auth::user();
        $guard = Guard::where('user_id', $user->id)->firstOrFail();

        $guardBuildingId = (int) ($guard->building_id ?? $user->building_id ?? 0);
        $visitorBuildingId = (int) ($visitor->flat?->floor?->block?->building_id ?? 0);
        if ($guardBuildingId > 0 && $visitorBuildingId > 0 && $guardBuildingId !== $visitorBuildingId) {
            return response()->json(['message' => 'Visitor does not belong to your building'], 403);
        }

        if (
            $visitor->status === 'pending'
            && !empty($visitor->created_by_resident_id)
            && !empty($visitor->gatepass)
        ) {
            // Self-heal older inconsistent records that were resident pre-approved
            // but persisted with pending status.
            $visitor->update(['status' => 'approved']);
            $visitor->refresh();
        }

        if ($visitor->status !== 'approved') {
            return response()->json(['message' => 'Visitor must be approved before entry can be confirmed'], 422);
        }

        // Update visitor status to 'inside'
        $visitor->update(['status' => 'inside']);

        // Log the action
        $gatepass = $visitor->gatepass;
        if ($gatepass && !$gatepass->entry_time) {
            $gatepass->update(['entry_time' => now()]);
            VisitorLog::create([
                'gatepass_id' => $gatepass->id,
                'guard_id' => $guard->id,
                'action' => 'confirmed_entry',
                'timestamp' => now(),
            ]);

            // Also log to VisitorActivityLog; never fail entry confirmation if this insert fails.
            $activityResidentId = $visitor->created_by_resident_id
                ?? $visitor->resident?->id
                ?? $visitor->flat?->residents?->first()?->id;

            try {
                VisitorActivityLog::create([
                    'building_id' => $guardBuildingId > 0 ? $guardBuildingId : $guard->building_id,
                    'guard_id' => $guard->id,
                    'resident_id' => $activityResidentId,
                    'visitor_type' => 'temporary',
                    'visitor_name' => $visitor->name,
                    'visitor_phone' => $visitor->phone,
                    'action' => 'entry',
                    'purpose' => $visitor->purpose,
                    'gatepass_category' => 'temporary',
                    'visitor_id' => $visitor->id,
                    'gatepass_id' => $gatepass->id,
                    'activity_date' => now(),
                ]);
            } catch (\Throwable $e) {
                Log::warning('Failed to write visitor entry activity log', [
                    'visitor_id' => $visitor->id,
                    'gatepass_id' => $gatepass->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        // Notify resident that the visitor was allowed entry.
        $visitor->loadMissing('resident.user.fcmTokens');
        if ($visitor->resident?->user) {
            NotificationController::createNotification(
                $visitor->resident->user->id,
                'Visitor Entry Allowed',
                ($visitor->name ?? 'Your visitor') . ' was allowed entry by the guard.',
                'success',
                'visitor',
                $visitor->id
            );

            $tokens = $visitor->resident->user->fcmTokens->pluck('device_token')->toArray();
            if (!empty($tokens)) {
                app(\App\Services\FirebaseService::class)->sendNotification(
                    $tokens,
                    'Visitor Entry Allowed',
                    ($visitor->name ?? 'Your visitor') . ' was allowed entry by the guard.',
                    [
                        'type' => 'visitor',
                        'id' => (string) $visitor->id,
                        'event' => 'entry_allowed',
                    ]
                );
            }
        }

        return response()->json([
            'message' => 'Visitor entry confirmed',
            'visitor' => $visitor
        ], 200);
    }

    /**
     * Mark visitor exit
     */
    public function markVisitorExit(Request $request, Visitor $visitor)
    {
        $user = Auth::user();
        $guard = Guard::where('user_id', $user->id)->firstOrFail();

        $guardBuildingId = (int) ($guard->building_id ?? $user->building_id ?? 0);
        $visitorBuildingId = (int) ($visitor->flat?->floor?->block?->building_id ?? 0);
        if ($guardBuildingId > 0 && $visitorBuildingId > 0 && $guardBuildingId !== $visitorBuildingId) {
            return response()->json(['message' => 'Visitor does not belong to your building'], 403);
        }

        if ($visitor->status === 'exited') {
            return response()->json([
                'message' => 'Visitor is already exited',
                'visitor' => $visitor,
            ], 200);
        }

        if ($visitor->status !== 'inside') {
            return response()->json(['message' => 'Visitor is not currently inside'], 422);
        }

        // Update visitor status to 'exited'
        $visitor->update(['status' => 'exited']);

        // Log the action
        $gatepass = $visitor->gatepass;
        if ($gatepass && !$gatepass->exit_time) {
            $gatepass->update(['exit_time' => now()]);
            VisitorLog::create([
                'gatepass_id' => $gatepass->id,
                'guard_id' => $guard->id,
                'action' => 'mark_exit',
                'timestamp' => now(),
            ]);

            // Also log to VisitorActivityLog; never fail exit if this insert fails.
            $activityResidentId = $visitor->created_by_resident_id
                ?? $visitor->resident?->id
                ?? $visitor->flat?->residents?->first()?->id;

            try {
                VisitorActivityLog::create([
                    'building_id' => $guardBuildingId > 0 ? $guardBuildingId : $guard->building_id,
                    'guard_id' => $guard->id,
                    'resident_id' => $activityResidentId,
                    'visitor_type' => 'temporary',
                    'visitor_name' => $visitor->name,
                    'visitor_phone' => $visitor->phone,
                    'action' => 'exit',
                    'purpose' => $visitor->purpose,
                    'gatepass_category' => 'temporary',
                    'visitor_id' => $visitor->id,
                    'gatepass_id' => $gatepass->id,
                    'activity_date' => now(),
                ]);
            } catch (\Throwable $e) {
                Log::warning('Failed to write visitor exit activity log', [
                    'visitor_id' => $visitor->id,
                    'gatepass_id' => $gatepass->id,
                    'error' => $e->getMessage(),
                ]);
            }
        }

        return response()->json([
            'message' => 'Visitor marked as exited',
            'visitor' => $visitor
        ], 200);
    }

    /**
     * Reject visitor entry with reason
     */
    public function rejectVisitorEntry(Request $request, Visitor $visitor)
    {
        $request->validate([
            'reason' => 'required|string|max:500'
        ]);

        $user = Auth::user();
        $guard = Guard::where('user_id', $user->id)->firstOrFail();

        // Allow guard to reject when visitor was resident_rejected or when
        // the visitor is a resident-created pre-approved record (approved).
        if (in_array($visitor->status, ['resident_rejected', 'approved'], true)) {
            $visitor->update([
                'status' => 'rejected',
                'reject_reason' => $request->reason,
            ]);
        } else {
            return response()->json(['message' => 'Visitor cannot be rejected in the current state'], 422);
        }

        // Log the action with reason
        $gatepass = $visitor->gatepass;
        if ($gatepass) {
            VisitorLog::create([
                'gatepass_id' => $gatepass->id,
                'guard_id' => $guard->id,
                'action' => 'rejected',
                'timestamp' => now(),
            ]);
        }

        // Also write to activity log (best-effort)
        try {
            VisitorActivityLog::create([
                'building_id' => $guard->building_id ?? null,
                'guard_id' => $guard->id,
                'resident_id' => $visitor->created_by_resident_id ?? $visitor->resident?->id,
                'visitor_type' => 'temporary',
                'visitor_name' => $visitor->name,
                'visitor_phone' => $visitor->phone,
                'action' => 'rejected',
                'purpose' => $request->reason,
                'gatepass_category' => $gatepass ? 'temporary' : 'unknown',
                'visitor_id' => $visitor->id,
                'gatepass_id' => $gatepass?->id,
                'activity_date' => now(),
            ]);
        } catch (\Throwable $e) {
            Log::warning('Failed to write visitor reject activity log', [
                'visitor_id' => $visitor->id,
                'error' => $e->getMessage(),
            ]);
        }

        // Notify resident that visitor entry was rejected.
        $visitor->loadMissing('resident.user.fcmTokens');
        if ($visitor->resident?->user) {
            NotificationController::createNotification(
                $visitor->resident->user->id,
                'Visitor Entry Rejected',
                ($visitor->name ?? 'Your visitor') . ' entry was rejected by the guard.',
                'warning',
                'visitor',
                $visitor->id
            );

            $tokens = $visitor->resident->user->fcmTokens->pluck('device_token')->toArray();
            if (!empty($tokens)) {
                app(\App\Services\FirebaseService::class)->sendNotification(
                    $tokens,
                    'Visitor Entry Rejected',
                    ($visitor->name ?? 'Your visitor') . ' entry was rejected by the guard.',
                    [
                        'type' => 'visitor',
                        'id' => (string) $visitor->id,
                        'event' => 'entry_rejected',
                    ]
                );
            }
        }

        return response()->json([
            'message' => 'Visitor entry rejected',
            'reason' => $request->reason,
            'visitor' => $visitor
        ], 200);
    }

    /**
     * Get inside visitors (currently inside the society)
     */
    public function getInsideVisitors(Request $request)
    {
        [, $guardBuildingId] = $this->resolveGuardContext();

        $visitors = Visitor::where('status', 'inside')
            ->whereHas('flat.floor.block.building', function ($query) use ($guardBuildingId) {
                $query->where('buildings.id', $guardBuildingId);
            })
            ->with('resident.user')
            ->get()
            ->map(function ($visitor) {
                return [
                    'id' => $visitor->id,
                    'guest_name' => $visitor->name,
                    'resident_name' => $visitor->resident?->user?->name ?? 'Unknown',
                    'purpose' => $visitor->purpose,
                    'entry_time' => $visitor->gatepass?->entry_time,
                    'phone' => $visitor->phone,
                    'status' => $visitor->status,
                ];
            });

        return response()->json(['visitors' => $visitors], 200);
    }

    /**
     * Get pending/approved visitors (waiting for entry)
     */
    public function getPendingVisitors(Request $request)
    {
        [, $guardBuildingId] = $this->resolveGuardContext();

        $visitors = Visitor::whereIn('status', ['pending', 'approved', 'resident_rejected'])
            ->whereHas('flat.floor.block.building', function ($query) use ($guardBuildingId) {
                $query->where('buildings.id', $guardBuildingId);
            })
            ->with('resident.user')
            ->get()
            ->map(function ($visitor) {
                return [
                    'id' => $visitor->id,
                    'guest_name' => $visitor->name,
                    'resident_name' => $visitor->resident?->user?->name ?? 'Unknown',
                    'purpose' => $visitor->purpose,
                    'phone' => $visitor->phone,
                    'status' => $visitor->status,
                    'reject_reason' => $visitor->reject_reason,
                ];
            });

        return response()->json(['visitors' => $visitors], 200);
    }

    /**
     * Get visitor history with pagination
     */
    public function getVisitorHistory(Request $request)
    {
        $request->validate([
            'limit' => 'sometimes|integer|min:1|max:100'
        ]);

        [, $guardBuildingId] = $this->resolveGuardContext();

        $limit = $request->limit ?? 50;

        $history = Visitor::whereHas('flat.floor.block.building', function ($query) use ($guardBuildingId) {
            $query->where('buildings.id', $guardBuildingId);
        })
            ->with('resident.user', 'gatepass')
            ->latest('updated_at')
            ->limit($limit)
            ->get()
            ->map(function ($visitor) {
                return [
                    'id' => $visitor->id,
                    'guest_name' => $visitor->name,
                    'resident_name' => $visitor->resident?->user?->name ?? 'Unknown',
                    'purpose' => $visitor->purpose,
                    'status' => $visitor->status,
                    'phone' => $visitor->phone,
                    'entry_time' => $visitor->gatepass?->entry_time,
                    'exit_time' => $visitor->gatepass?->exit_time,
                    'created_at' => $visitor->created_at,
                    'updated_at' => $visitor->updated_at,
                ];
            });

        return response()->json(['history' => $history], 200);
    }

    private function resolveGuardContext(): array
    {
        $user = Auth::user();
        $guard = Guard::where('user_id', $user->id)->firstOrFail();

        $guardBuildingId = (int) ($guard->building_id ?? 0);
        $userBuildingId = (int) ($user?->building_id ?? 0);
        $effectiveBuildingId = $guardBuildingId > 0 ? $guardBuildingId : $userBuildingId;

        if ($effectiveBuildingId <= 0) {
            abort(422, 'Guard building context not found');
        }

        // Self-heal legacy guard rows that missed building_id assignment.
        if ($guardBuildingId <= 0 && $userBuildingId > 0) {
            $guard->update(['building_id' => $userBuildingId]);
        }

        return [$guard, $effectiveBuildingId];
    }
}
