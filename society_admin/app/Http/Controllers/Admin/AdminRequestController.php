<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\AmenityBooking;
use App\Models\ServiceBooking;

class AdminRequestController extends Controller
{
    /**
     * Get all amenity requests for the admin's building.
     */
    public function amenityRequests(Request $request)
    {
        $buildingId = $request->user()->building_id;

        $bookings = AmenityBooking::with(['resident.user', 'amenity', 'resident.flat.floor.block.building'])
            ->whereHas('resident.flat.floor.block.building', function ($q) use ($buildingId) {
                $q->where('id', $buildingId);
            })
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['bookings' => $bookings]);
    }

    /**
     * Get all service requests for the admin's building.
     */
    public function serviceRequests(Request $request)
    {
        $buildingId = $request->user()->building_id;

        $bookings = ServiceBooking::with(['resident.user', 'service', 'resident.flat.floor.block.building'])
            ->whereHas('resident.flat.floor.block.building', function ($q) use ($buildingId) {
                $q->where('id', $buildingId);
            })
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['bookings' => $bookings]);
    }

    /**
     * Update status of an amenity booking.
     */
    public function updateAmenityStatus(AmenityBooking $booking, Request $request)
    {
        $data = $request->validate([
            'status' => 'required|in:pending,approved,rejected',
            'rejection_reason' => 'nullable|string|max:1000',
            'admin_comment' => 'nullable|string|max:1000',
        ]);

        $booking->update([
            'status' => $data['status'],
            'rejection_reason' => $data['status'] === 'rejected' ? ($data['rejection_reason'] ?? null) : null,
            'admin_comment' => $data['status'] === 'approved' ? ($data['admin_comment'] ?? null) : null,
        ]);

        // Trigger Notification to Resident
        $this->notifyResidentAboutBooking($booking, 'amenity');

        return response()->json(['message' => 'Status updated successfully', 'booking' => $booking]);
    }

    /**
     * Update status of a service booking.
     */
    public function updateServiceStatus(ServiceBooking $booking, Request $request)
    {
        $data = $request->validate([
            'status' => 'required|in:pending,approved,rejected,completed',
            'rejection_reason' => 'nullable|string|max:1000',
            'admin_comment' => 'nullable|string|max:1000',
        ]);

        $booking->update([
            'status' => $data['status'],
            'rejection_reason' => $data['status'] === 'rejected' ? ($data['rejection_reason'] ?? null) : null,
            'admin_comment' => $data['status'] === 'approved' ? ($data['admin_comment'] ?? null) : null,
        ]);

        // Trigger Notification
        $this->notifyResidentAboutBooking($booking, 'service');

        return response()->json(['message' => 'Status updated successfully', 'booking' => $booking]);
    }

    /**
     * Helper to notify residents about request status updates.
     */
    private function notifyResidentAboutBooking($booking, $type)
    {
        $booking->load(['resident.user.fcmTokens']);
        $user = $booking->resident->user;
        $label = $type === 'amenity' ? ($booking->amenity->name ?? 'Amenity') : ($booking->service->name ?? 'Service');

        $message = "Your request for $label has been " . $booking->status . ".";

        if ($booking->status === 'rejected' && !empty($booking->rejection_reason)) {
            $message .= ' Reason: ' . $booking->rejection_reason;
        }

        if ($booking->status === 'approved' && !empty($booking->admin_comment)) {
            $message .= ' Note: ' . $booking->admin_comment;
        }

        if ($user) {
            \App\Http\Controllers\NotificationController::createNotification(
                $user->id,
                ucfirst($type) . ' Request Updated',
                $message,
                $booking->status === 'approved' || $booking->status === 'completed' ? 'success' : 'info',
                $type . '_booking',
                $booking->id
            );
        }

        if ($user && $user->fcmTokens->isNotEmpty()) {
            $tokens = $user->fcmTokens->pluck('device_token')->toArray();

            $firebase = app(\App\Services\FirebaseService::class);
            $firebase->sendNotification(
                $tokens,
                ucfirst($type) . ' Request Updated',
                $message,
                ['type' => $type, 'id' => (string)$booking->id]
            );
        }
    }
}
