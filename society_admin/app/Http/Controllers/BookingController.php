<?php

namespace App\Http\Controllers;

use App\Models\Amenity;
use App\Models\AmenityBooking;
use Illuminate\Http\Request;

class BookingController extends Controller
{
    public function store(Request $request, Amenity $amenity)
    {
        $residentId = $request->resident_id ?? auth()->user()->resident?->id;
        if (!$residentId) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }

        $data = $request->validate([
            'booking_date' => 'required|date',
            'from_time' => 'required|date_format:H:i',
            'to_time' => 'required|date_format:H:i|after:from_time',
        ]);

        $data['resident_id'] = $residentId;

        // Check if THIS resident already has a booking for this slot
        $myBookingCount = $amenity->bookings()
            ->where('resident_id', $residentId)
            ->whereDate('booking_date', $data['booking_date'])
            ->whereIn('status', ['approved', 'pending'])
            ->where('from_time', '<', $data['to_time'])
            ->where('to_time', '>', $data['from_time'])
            ->count();

        if ($myBookingCount > 0) {
            return response()->json(['message' => 'You already have a booking for this slot'], 422);
        }

        // Capacity validation for others
        $existingBookingsCount = $amenity->bookings()
            ->whereDate('booking_date', $data['booking_date'])
            ->whereIn('status', ['approved', 'pending'])
            ->where('from_time', '<', $data['to_time'])
            ->where('to_time', '>', $data['from_time'])
            ->count();

        if ($existingBookingsCount >= ($amenity->max_capacity ?? 1)) {
            return response()->json(['message' => 'This slot is already fully booked'], 422);
        }

        $booking = $amenity->bookings()->create($data);

        // Notify Admins
        $buildingId = $amenity->building_id;

        // Create notifications for all building admins
        $adminUsers = \App\Helpers\NotificationHelper::getBuildingAdmins($buildingId);

        foreach ($adminUsers as $admin) {
            \App\Http\Controllers\NotificationController::createNotification(
                $admin->id,
                'New Amenity Booking Request',
                "A new booking request for {$amenity->name} from flat " . ($booking->resident->flat->flat_number ?? 'N/A'),
                'info',
                'amenity_booking',
                $booking->id
            );
        }

        // Send push notification
        $firebase = app(\App\Services\FirebaseService::class);
        $firebase->sendToTopic(
            "building_{$buildingId}_admins",
            "New Amenity Booking Request",
            "A new booking request for {$amenity->name} from flat " . ($booking->resident->flat->flat_number ?? 'N/A'),
            ['type' => 'amenity_booking', 'id' => (string)$booking->id]
        );

        return response()->json($booking, 201);
    }

    public function indexByAmenity(Amenity $amenity)
    {
        return response()->json($amenity->bookings()->with('resident.user')->get());
    }

    public function indexByResident(Request $request)
    {
        $residentId = $request->query('resident_id') ?? auth()->user()->resident?->id;
        if (!$residentId) {
            return response()->json(['bookings' => []]);
        }
        $bookings = AmenityBooking::where('resident_id', $residentId)
            ->with('amenity')
            ->orderBy('created_at', 'desc')
            ->get();
        // format output
        $formatted = $bookings->map(function ($booking) {
            return [
                'id' => $booking->id,
                'amenity_name' => $booking->amenity->name ?? 'Unknown Amenity',
                'booking_date' => $booking->booking_date,
                'booking_time' => $booking->from_time . ' - ' . $booking->to_time,
                'status' => $booking->status,
                'rejection_reason' => $booking->rejection_reason,
                'admin_comment' => $booking->admin_comment,
                'created_at' => $booking->created_at,
            ];
        });
        return response()->json(['bookings' => $formatted]);
    }

    public function approve(AmenityBooking $booking)
    {
        $booking->load(['resident.user.fcmTokens', 'amenity']);
        $booking->update(['status' => 'approved']);

        if ($booking->resident && $booking->resident->user) {
            \App\Http\Controllers\NotificationController::createNotification(
                $booking->resident->user->id,
                'Amenity Request Updated',
                'Your request for ' . ($booking->amenity->name ?? 'Amenity') . ' has been approved.',
                'success',
                'amenity_booking',
                $booking->id
            );

            $tokens = $booking->resident->user->fcmTokens->pluck('device_token')->toArray();
            if (!empty($tokens)) {
                $firebase = app(\App\Services\FirebaseService::class);
                $firebase->sendNotification(
                    $tokens,
                    'Amenity Request Updated',
                    'Your request for ' . ($booking->amenity->name ?? 'Amenity') . ' has been approved.',
                    ['type' => 'amenity', 'id' => (string)$booking->id]
                );
            }
        }

        return response()->json($booking);
    }

    public function reject(AmenityBooking $booking)
    {
        $booking->load(['resident.user.fcmTokens', 'amenity']);
        $booking->update(['status' => 'rejected']);

        if ($booking->resident && $booking->resident->user) {
            \App\Http\Controllers\NotificationController::createNotification(
                $booking->resident->user->id,
                'Amenity Request Updated',
                'Your request for ' . ($booking->amenity->name ?? 'Amenity') . ' has been rejected.',
                'alert',
                'amenity_booking',
                $booking->id
            );

            $tokens = $booking->resident->user->fcmTokens->pluck('device_token')->toArray();
            if (!empty($tokens)) {
                $firebase = app(\App\Services\FirebaseService::class);
                $firebase->sendNotification(
                    $tokens,
                    'Amenity Request Updated',
                    'Your request for ' . ($booking->amenity->name ?? 'Amenity') . ' has been rejected.',
                    ['type' => 'amenity', 'id' => (string)$booking->id]
                );
            }
        }

        return response()->json($booking);
    }
}
