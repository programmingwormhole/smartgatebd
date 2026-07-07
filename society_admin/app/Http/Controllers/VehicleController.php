<?php

namespace App\Http\Controllers;

use App\Models\Vehicle;
use Illuminate\Http\Request;

class VehicleController extends Controller
{
    public function index($residentId = null)
    {
        $residentId = $residentId ?? auth()->user()->resident?->id;
        if (!$residentId) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }
        $vehicles = Vehicle::where('resident_id', $residentId)->latest()->get();
        return response()->json([
            'status' => 'success',
            'vehicles' => $vehicles
        ]);
    }

    public function store(Request $request, $residentId = null)
    {
        $residentId = $residentId ?? auth()->user()->resident?->id;
        if (!$residentId) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }

        $validated = $request->validate([
            'model' => 'required|string',
            'color' => 'nullable|string',
            'plate_number' => 'required|string',
            'type' => 'nullable|string'
        ]);

        $validated['resident_id'] = $residentId;

        $vehicle = Vehicle::create($validated);

        return response()->json([
            'status' => 'success',
            'message' => 'Vehicle added successfully',
            'vehicle' => $vehicle
        ], 201);
    }
}
