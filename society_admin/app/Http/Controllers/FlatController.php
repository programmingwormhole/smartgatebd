<?php

namespace App\Http\Controllers;

use App\Models\Floor;
use App\Models\Flat;
use Illuminate\Http\Request;

class FlatController extends Controller
{
    public function store(Request $request, Floor $floor)
    {
        $data = $request->validate([
            'flat_number' => 'required|string'
        ]);

        $flat = $floor->flats()->create($data);
        return response()->json($flat, 201);
    }

    public function update(Request $request, Flat $flat)
    {
        $data = $request->validate([
            'flat_number' => 'required|string'
        ]);

        $flat->update($data);
        return response()->json($flat);
    }

    public function destroy(Flat $flat)
    {
        $flat->delete();
        return response()->json(['message' => 'Flat deleted successfully']);
    }
}
