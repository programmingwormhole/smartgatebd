<?php

namespace App\Http\Controllers;

use App\Models\Visitor;
use App\Models\Building;
use App\Models\Resident;
use App\Models\User;
use App\Models\VisitorActivityLog;
use App\Services\VisitorService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class VisitorController extends Controller
{
    protected $visitorService;

    public function __construct(VisitorService $visitorService)
    {
        $this->visitorService = $visitorService;
    }

    public function store(Request $request)
    {
        $resident = Auth::user()?->resident;
        $residentId = $request->created_by_resident_id ?? $resident?->id;
        $flatId = $request->flat_id ?? $resident?->flat_id;

        if (!$residentId || !$flatId) {
            return response()->json(['message' => 'Resident profile or flat mapping missing'], 422);
        }

        $data = $request->validate([
            'type' => 'required|in:guest,cab,delivery,service',
            'name' => 'required|string',
            'phone' => 'nullable|string',
            'vehicle_no' => 'nullable|string',
            'company_name' => 'nullable|string',
            'purpose' => 'nullable|string',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date',
        ]);

        $data['created_by_resident_id'] = $residentId;
        $data['flat_id'] = $flatId;

        // Auto-approve if created by resident.
        // Keep visitor + gatepass creation atomic to avoid inconsistent statuses.
        $visitor = DB::transaction(function () use ($data) {
            $data['status'] = 'approved';
            $visitor = Visitor::create($data);
            $this->visitorService->approve($visitor);
            return $visitor;
        });

        // Notify Guards
        $buildingId = $visitor->flat->floor->block->building_id;

        // Create DB notifications for all guards in this building.
        $guardUsers = User::query()
            ->where('role', 'guard')
            ->where(function ($query) use ($buildingId) {
                $query->where('building_id', $buildingId)
                    ->orWhereHas('guardProfile', function ($guardQuery) use ($buildingId) {
                        $guardQuery->where('building_id', $buildingId);
                    });
            })
            ->select('users.*')
            ->distinct()
            ->get();

        foreach ($guardUsers as $guardUser) {
            NotificationController::createNotification(
                $guardUser->id,
                'New Pre-approved Visitor',
                ($visitor->name ?? 'A visitor') . ' is expected for flat ' . ($visitor->flat->flat_number ?? '-'),
                'info',
                'visitor',
                $visitor->id
            );
        }

        $firebase = app(\App\Services\FirebaseService::class);
        $firebase->sendToTopic(
            "building_{$buildingId}_guards",
            "New Pre-approved Visitor",
            "{$visitor->name} is expected for flat " . $visitor->flat->flat_number,
            ['type' => 'visitor', 'id' => (string)$visitor->id]
        );

        return response()->json($visitor->load('gatepass'), 201);
    }

    public function approve(Visitor $visitor)
    {
        if (in_array($visitor->status, ['approved', 'inside', 'exited', 'rejected'], true)) {
            return response()->json(['message' => 'Visitor cannot be approved in the current state'], 422);
        }

        $gatepass = $this->visitorService->approve($visitor);

        $visitor->loadMissing('flat.floor.block.building', 'resident.user.fcmTokens');

        VisitorActivityLog::create([
            'building_id' => $visitor->flat?->floor?->block?->building_id,
            'resident_id' => $visitor->created_by_resident_id,
            'visitor_type' => 'pre_approved',
            'visitor_name' => $visitor->name,
            'visitor_phone' => $visitor->phone,
            'entry_code' => $gatepass?->entry_code,
            'action' => 'approved',
            'purpose' => $visitor->purpose,
            'gatepass_category' => 'walk-in',
            'visitor_id' => $visitor->id,
            'gatepass_id' => $gatepass?->id,
            'activity_date' => now(),
        ]);

        $buildingId = (int) ($visitor->flat?->floor?->block?->building_id ?? 0);
        if ($buildingId > 0) {
            $guardUsers = User::query()
                ->where('role', 'guard')
                ->where(function ($query) use ($buildingId) {
                    $query->where('building_id', $buildingId)
                        ->orWhereHas('guardProfile', function ($guardQuery) use ($buildingId) {
                            $guardQuery->where('building_id', $buildingId);
                        });
                })
                ->select('users.*')
                ->distinct()
                ->get();

            foreach ($guardUsers as $guardUser) {
                NotificationController::createNotification(
                    $guardUser->id,
                    'Visitor Approved',
                    ($visitor->name ?? 'Visitor') . ' was approved and is ready for entry.',
                    'success',
                    'visitor',
                    $visitor->id
                );
            }

            app(\App\Services\FirebaseService::class)->sendToTopic(
                "building_{$buildingId}_guards",
                'Visitor Approved',
                ($visitor->name ?? 'Visitor') . ' was approved and is ready for entry.',
                [
                    'type' => 'visitor',
                    'id' => (string) $visitor->id,
                    'event' => 'visitor_approved',
                ]
            );
        }

        return response()->json(['message' => 'Approved', 'gatepass' => $gatepass]);
    }

    public function reject(Request $request, Visitor $visitor)
    {
        $data = $request->validate([
            'reason' => 'required|string|max:500',
        ]);

        if (in_array($visitor->status, ['rejected', 'inside', 'exited', 'resident_rejected'], true)) {
            return response()->json(['message' => 'Visitor cannot be rejected in the current state'], 422);
        }

        // Set status to resident_rejected instead of rejected
        $visitor->update(['status' => 'resident_rejected', 'reject_reason' => $data['reason']]);

        $visitor->loadMissing('flat.floor.block.building');

        VisitorActivityLog::create([
            'building_id' => $visitor->flat?->floor?->block?->building_id,
            'resident_id' => $visitor->created_by_resident_id,
            'visitor_type' => 'pre_approved',
            'visitor_name' => $visitor->name,
            'visitor_phone' => $visitor->phone,
            'action' => 'resident_rejected',
            'purpose' => $visitor->purpose,
            'gatepass_category' => 'walk-in',
            'visitor_id' => $visitor->id,
            'notes' => $data['reason'],
            'activity_date' => now(),
        ]);

        // Notify Guards about resident rejection
        $buildingId = (int) ($visitor->flat?->floor?->block?->building_id ?? 0);
        if ($buildingId > 0) {
            $guardUsers = User::query()
                ->where('role', 'guard')
                ->where(function ($query) use ($buildingId) {
                    $query->where('building_id', $buildingId)
                        ->orWhereHas('guardProfile', function ($guardQuery) use ($buildingId) {
                            $guardQuery->where('building_id', $buildingId);
                        });
                })
                ->select('users.*')
                ->distinct()
                ->get();

            foreach ($guardUsers as $guardUser) {
                NotificationController::createNotification(
                    $guardUser->id,
                    'Visitor Rejected by Resident',
                    ($visitor->name ?? 'Visitor') . ' was rejected by the resident for flat ' . ($visitor->flat->flat_number ?? '-'),
                    'warning',
                    'visitor',
                    $visitor->id
                );
            }

            app(\App\Services\FirebaseService::class)->sendToTopic(
                "building_{$buildingId}_guards",
                'Visitor Rejected by Resident',
                ($visitor->name ?? 'Visitor') . ' was rejected by the resident.',
                [
                    'type' => 'visitor',
                    'id' => (string) $visitor->id,
                    'event' => 'visitor_rejected_by_resident',
                    'reject_reason' => $data['reason'],
                ]
            );
        }

        return response()->json(['message' => 'Rejected', 'visitor' => $visitor]);
    }

    public function gatepass(Visitor $visitor)
    {
        return response()->json($visitor->gatepass);
    }

    public function indexByBuilding(Building $building)
    {
        $visitors = Visitor::whereHas('flat.floor.block.building', function ($q) use ($building) {
            $q->where('id', $building->id);
        })->get();
        return response()->json(['visitors' => $visitors]);
    }

    public function indexByResident(Resident $resident = null)
    {
        $resident = $resident ?? Auth::user()?->resident;
        if (!$resident) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }
        return response()->json(['visitors' => $resident->visitors()->with('gatepass')->latest()->get()]);
    }

    public function destroy(Visitor $visitor)
    {
        if ($visitor->status === 'inside') {
            return response()->json(['message' => 'Cannot delete visitor who is currently inside'], 422);
        }
        $visitor->delete();
        return response()->json(['message' => 'Visitor deleted successfully']);
    }
}
