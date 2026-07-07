<?php

namespace App\Http\Controllers;

use App\Models\Pet;
use App\Models\Resident;
use Illuminate\Http\Request;

class PetController extends Controller
{
    public function index(Resident $resident = null)
    {
        $resident = $resident ?? auth()->user()->resident;
        if (!$resident) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }
        return response()->json([
            'pets' => $resident->pets()->orderBy('created_at', 'desc')->get()
        ]);
    }

    public function store(Request $request, Resident $resident = null)
    {
        $resident = $resident ?? auth()->user()->resident;
        if (!$resident) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|string|max:255',
            'breed' => 'nullable|string|max:255',
            'is_vaccinated' => 'nullable|boolean',
        ]);

        $data['is_vaccinated'] = $data['is_vaccinated'] ?? false;

        $pet = $resident->pets()->create($data);

        return response()->json(['pet' => $pet], 201);
    }
}
