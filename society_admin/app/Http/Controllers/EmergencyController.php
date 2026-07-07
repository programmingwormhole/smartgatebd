<?php

namespace App\Http\Controllers;

use App\Models\EmergencyAlert;
use App\Models\AlertRecipient;
use Illuminate\Http\Request;

class EmergencyController extends Controller
{
    public function store(Request $request)
    {
        $resident = auth()->user()->resident;
        $buildingId = $request->building_id ?? $resident?->flat?->floor?->block?->building_id;

        if (!$buildingId) {
            return response()->json(['message' => 'Building ID is required'], 422);
        }

        $data = $request->validate([
            'type' => 'required|string',
            'message' => 'required|string',
            'latitude' => 'nullable|string',
            'longitude' => 'nullable|string'
        ]);

        $data['building_id'] = $buildingId;
        $data['created_by_admin_id'] = null; // Default to null if from resident

        $alert = EmergencyAlert::create($data);

        // Create notifications for all building users
        $buildingUsers = \App\Helpers\NotificationHelper::getBuildingUsers($buildingId);

        foreach ($buildingUsers as $user) {
            \App\Http\Controllers\NotificationController::createNotification(
                $user->id,
                'Emergency: ' . $data['type'],
                $data['message'],
                'alert',
                'emergency',
                $alert->id
            );
        }

        // Trigger topic-based push notification for the building
        $firebase = app(\App\Services\FirebaseService::class);
        $firebase->sendToTopic(
            "building_$buildingId",
            "Emergency: " . $data['type'],
            $data['message'],
            [
                'type' => 'emergency',
                'alert_id' => (string)$alert->id,
                'building_id' => (string)$buildingId,
                'priority' => 'high'
            ]
        );

        return response()->json(['alert' => $alert], 201);
    }

    public function index(Request $request)
    {
        $request->validate(['building_id' => 'required|exists:buildings,id']);
        $alerts = EmergencyAlert::where('building_id', $request->building_id)->latest()->get();
        return response()->json(['alerts' => $alerts]);
    }

    public function markAsRead(Request $request, EmergencyAlert $alert)
    {
        // Simple mock for mark as read endpoint
        return response()->json(['message' => 'Marked as read', 'alert' => $alert]);
    }
}
