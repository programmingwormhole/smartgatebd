<?php

namespace App\Http\Controllers;

use App\Models\Amenity;
use App\Models\Building;
use Illuminate\Http\Request;

class AmenityController extends Controller
{
    public function index(Building $building)
    {
        return response()->json([
            'amenities' => $building->amenities
        ]);
    }

    public function slots(Request $request, Amenity $amenity)
    {
        $date = $request->query('date', date('Y-m-d'));
        $openTime = $amenity->open_time;
        $closeTime = $amenity->close_time;
        $duration = $amenity->slot_duration_minutes;

        $slots = [];
        $current = strtotime($date . ' ' . $openTime);
        $end = strtotime($date . ' ' . $closeTime);

        $existingBookings = $amenity->bookings()
            ->whereDate('booking_date', $date)
            ->whereIn('status', ['approved', 'pending']) // Both approved and pending bookings block slots
            ->get();

        $residentId = auth()->user()->resident?->id;
        
        while ($current < $end) {
            $slotFrom = date('H:i', $current);
            $current = $current + ($duration * 60);
            $slotTo = date('H:i', $current);
            
            if ($current > $end) break;

            $isBookedByMe = false;
            $bookedCount = $existingBookings->filter(function($booking) use ($slotFrom, $slotTo, $residentId, &$isBookedByMe) {
                // Ensure HH:mm:ss format for reliable string comparison
                $bFrom = date('H:i:s', strtotime($booking->from_time));
                $bTo = date('H:i:s', strtotime($booking->to_time));
                $sFrom = date('H:i:s', strtotime($slotFrom));
                $sTo = date('H:i:s', strtotime($slotTo));

                $match = $bFrom < $sTo && $bTo > $sFrom;
                
                if ($match && $residentId && $booking->resident_id == $residentId) {
                    $isBookedByMe = true;
                }

                return $match;
            })->count();
            
            // Available if: not booked by me AND count < capacity
            $isAvailable = !$isBookedByMe && ($bookedCount < ($amenity->max_capacity ?? 1));

            $slots[] = [
                'from' => $slotFrom,
                'to' => $slotTo,
                'is_available' => $isAvailable,
                'is_booked_by_me' => $isBookedByMe
            ];
        }

        return response()->json(['slots' => $slots]);
    }

    public function store(Request $request, Building $building)
    {
        $data = $request->validate([
            'name' => 'required|string',
            'price_per_day' => 'nullable|numeric|min:0',
            'max_capacity' => 'nullable|integer|min:1',
            'open_time' => 'nullable|date_format:H:i',
            'close_time' => 'nullable|date_format:H:i',
            'slot_duration_minutes' => 'nullable|integer|min:1'
        ]);

        $amenity = $building->amenities()->create($data);
        return response()->json($amenity, 201);
    }

    public function update(Request $request, Amenity $amenity)
    {
        $data = $request->validate([
            'name' => 'required|string',
            'price_per_day' => 'nullable|numeric|min:0',
            'max_capacity' => 'nullable|integer|min:1',
            'open_time' => 'nullable|date_format:H:i',
            'close_time' => 'nullable|date_format:H:i',
            'slot_duration_minutes' => 'nullable|integer|min:1'
        ]);

        $amenity->update($data);
        return response()->json($amenity);
    }

    public function destroy(Amenity $amenity)
    {
        $amenity->delete();
        return response()->json(['message' => 'Amenity deleted successfully']);
    }
}
