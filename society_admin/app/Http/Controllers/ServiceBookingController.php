<?php

namespace App\Http\Controllers;

use App\Models\Service;
use App\Models\ServiceBooking;
use Illuminate\Http\Request;

class ServiceBookingController extends Controller
{
    public function store(Request $request)
    {
        $residentId = $request->resident_id ?? auth()->user()->resident?->id;
        if (!$residentId) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }

        if (!$request->has('service_id') && $request->has('category')) {
            $service = Service::where('name', $request->category)
                ->where('building_id', auth()->user()->building_id)
                ->first();
            if ($service) {
                $request->merge(['service_id' => $service->id]);
            }
        }

        $data = $request->validate([
            'service_id' => 'required|exists:services,id',
            'description' => 'nullable|string',
            'booking_date' => 'required|date'
        ]);

        $data['resident_id'] = $residentId;

        $booking = ServiceBooking::create($data);

        // Notify Admins
        $buildingId = $booking->service->building_id;

        // Create notifications for all building admins
        $adminUsers = \App\Helpers\NotificationHelper::getBuildingAdmins($buildingId);

        foreach ($adminUsers as $admin) {
            \App\Http\Controllers\NotificationController::createNotification(
                $admin->id,
                'New Service Request',
                "New request for " . ($booking->service->name ?? 'Service') . " from flat " . ($booking->resident->flat->flat_number ?? 'N/A'),
                'info',
                'service_booking',
                $booking->id
            );
        }

        // Send push notification
        $firebase = app(\App\Services\FirebaseService::class);
        $firebase->sendToTopic(
            "building_{$buildingId}_admins",
            "New Service Request",
            "New request for " . ($booking->service->name ?? 'Service') . " from flat " . ($booking->resident->flat->flat_number ?? 'N/A'),
            ['type' => 'service_booking', 'id' => (string)$booking->id]
        );

        return response()->json($booking, 201);
    }

    public function indexByResident(Request $request)
    {
        $residentId = $request->resident_id ?? auth()->user()->resident?->id;
        if (!$residentId) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }

        $bookings = ServiceBooking::where('resident_id', $residentId)
            ->with('service')
            ->get();
        return response()->json(['bookings' => $bookings]);
    }

    public function indexByBuilding(Request $request)
    {
        $request->validate(['building_id' => 'required|exists:buildings,id']);
        $bookings = ServiceBooking::whereHas('service', function($q) use ($request) {
            $q->where('building_id', $request->building_id);
        })->with(['service', 'resident.user'])->get();
        return response()->json(['bookings' => $bookings]);
    }

    public function updateStatus(Request $request, ServiceBooking $booking)
    {
        $data = $request->validate([
            'status' => 'required|in:pending,approved,completed,rejected'
        ]);

        $booking->update($data);

        // Notify resident
        $booking->load('resident.user.fcmTokens');
        if ($booking->resident && $booking->resident->user) {
            $tokens = $booking->resident->user->fcmTokens->pluck('device_token')->toArray();
            if (!empty($tokens)) {
                $firebase = app(\App\Services\FirebaseService::class);
                $firebase->sendNotification(
                    $tokens,
                    'Service Request Updated',
                    'Your service request for ' . ($booking->service->name ?? 'Service') . ' has been ' . $data['status'] . '.',
                    ['type' => 'service', 'id' => (string)$booking->id]
                );
            }
        }

        return response()->json($booking);
    }
}
