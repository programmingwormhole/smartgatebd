<?php

namespace App\Http\Controllers;

use App\Models\Block;
use App\Models\Floor;
use Illuminate\Http\Request;

class FloorController extends Controller
{
    public function store(Request $request, Block $block)
    {
        $data = $request->validate([
            'floor_number' => 'required|string'
        ]);

        $floor = $block->floors()->create($data);
        return response()->json($floor, 201);
    }

    public function update(Request $request, Floor $floor)
    {
        $data = $request->validate([
            'floor_number' => 'required|string'
        ]);

        $floor->update($data);
        return response()->json($floor);
    }

    public function destroy(Floor $floor)
    {
        $floor->delete();
        return response()->json(['message' => 'Floor deleted successfully']);
    }
}
