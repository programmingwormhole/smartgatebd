<?php

namespace App\Http\Controllers;

use App\Models\Building;
use App\Models\Complaint;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class ComplaintController extends Controller
{
    private function resolveAdminBuildingId(Request $request): ?int
    {
        $user = $request->user();
        if (!$user) {
            return null;
        }

        if ($user->role === 'superadmin') {
            $requestedBuildingId = $request->query('building_id');
            if ($requestedBuildingId !== null) {
                return (int) $requestedBuildingId;
            }

            if ($user->building_id) {
                return (int) $user->building_id;
            }

            return Building::query()->orderBy('id')->value('id');
        }

        return $user->building_id ? (int) $user->building_id : null;
    }

    public function store(Request $request)
    {
        $residentId = $request->resident_id ?? auth()->user()->resident?->id;
        if (!$residentId) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }

        $data = $request->validate([
            'title' => 'required|string',
            'category' => 'required|string',
            'description' => 'required|string',
        ]);

        $data['resident_id'] = $residentId;

        $complaint = Complaint::create($data);

        // Notify Admins
        $buildingId = $complaint->resident->flat->floor->block->building_id ?? null;
        if ($buildingId) {
            // Create notifications for all building admins
            $adminUsers = \App\Helpers\NotificationHelper::getBuildingAdmins($buildingId);

            foreach ($adminUsers as $admin) {
                \App\Http\Controllers\NotificationController::createNotification(
                    $admin->id,
                    'New Complaint Submitted',
                    "Complaint: {$complaint->title}",
                    'alert',
                    'complaint',
                    $complaint->id
                );
            }

            // Send push notification
            $firebase = app(\App\Services\FirebaseService::class);
            $firebase->sendToTopic(
                "building_{$buildingId}_admins",
                "New Complaint Submitted",
                "Complaint: {$complaint->title}",
                ['type' => 'complaint', 'id' => (string)$complaint->id]
            );
        }

        return response()->json($complaint, 201);
    }

    public function indexByResident(Request $request)
    {
        $residentId = $request->resident_id ?? auth()->user()->resident?->id;
        if (!$residentId) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }

        $request->validate([
            'status' => 'nullable|in:active,resolved,open,in_progress',
        ]);

        $statusFilter = $request->query('status');

        $query = Complaint::where('resident_id', $residentId);

        if ($statusFilter === 'resolved') {
            $query->where('status', 'resolved');
        } elseif (in_array($statusFilter, ['open', 'in_progress'], true)) {
            $query->where('status', $statusFilter);
        } elseif ($statusFilter === 'active') {
            $query->whereIn('status', ['open', 'in_progress']);
        }

        $complaints = $query->latest()->get();
        return response()->json(['complaints' => $complaints]);
    }

    public function indexByBuilding(Request $request)
    {
        $user = $request->user();
        if (!in_array($user->role, ['admin', 'committee', 'superadmin'], true)) {
            return response()->json(['message' => 'Only admins can manage complaints'], 403);
        }

        if ($user->role === 'superadmin' && $request->query('building_id') !== null) {
            $request->validate(['building_id' => 'required|exists:buildings,id']);
        }

        $buildingId = $this->resolveAdminBuildingId($request);
        if (!$buildingId) {
            return response()->json(['message' => 'Building context not found for this admin user'], 422);
        }

        $complaints = Complaint::whereHas('resident.flat.floor.block.building', function($q) use ($buildingId) {
            $q->where('id', $buildingId);
        })->with([
            'resident.user:id,name,phone',
            'resident.flat:id,flat_number,floor_id',
            'resident.flat.floor:id,floor_number,block_id',
            'resident.flat.floor.block:id,name,building_id',
        ])->latest()->get();

        return response()->json(['complaints' => $complaints]);
    }

    public function updateStatus(Request $request, Complaint $complaint)
    {
        $user = $request->user();
        if (!in_array($user->role, ['admin', 'committee', 'superadmin'], true)) {
            return response()->json(['message' => 'Only admins can update complaint status'], 403);
        }

        $data = $request->validate([
            'status' => 'required|in:open,in_progress,resolved'
        ]);

        $complaint->load('resident.flat.floor.block');
        $complaintBuildingId = $complaint->resident?->flat?->floor?->block?->building_id;

        if ($user->role !== 'superadmin' && (int) $user->building_id !== (int) $complaintBuildingId) {
            return response()->json(['message' => 'Unauthorized for this complaint'], 403);
        }

        $complaint->update($data);

        // Load resident user and fcm tokens
        $complaint->load('resident.user.fcmTokens');
        if ($complaint->resident && $complaint->resident->user) {
            // Create database notification
            \App\Http\Controllers\NotificationController::createNotification(
                $complaint->resident->user->id,
                'Complaint Status Updated',
                'Your complaint "' . $complaint->title . '" is now ' . str_replace('_', ' ', $data['status']) . '.',
                $data['status'] === 'resolved' ? 'success' : 'info',
                'complaint',
                $complaint->id
            );

            // Send push notification if tokens available
            $tokens = $complaint->resident->user->fcmTokens->pluck('device_token')->toArray();
            if (!empty($tokens)) {
                $firebase = app(\App\Services\FirebaseService::class);
                $firebase->sendNotification(
                    $tokens,
                    'Complaint Status Updated',
                    'Your complaint "' . $complaint->title . '" is now ' . str_replace('_', ' ', $data['status']) . '.',
                    ['type' => 'complaint', 'complaint_id' => (string)$complaint->id]
                );
            }

            Log::info('Complaint status updated and resident notified', [
                'complaint_id' => $complaint->id,
                'status' => $data['status'],
                'resident_user_id' => $complaint->resident->user->id,
                'updated_by' => $user->id,
            ]);
        }

        return response()->json($complaint);
    }
}
