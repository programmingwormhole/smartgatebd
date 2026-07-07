<?php

namespace App\Http\Controllers;

use App\Models\Building;
use App\Models\Block;
use Illuminate\Http\Request;

class BlockController extends Controller
{
    public function store(Request $request, Building $building)
    {
        $data = $request->validate([
            'name' => 'required|string'
        ]);

        $block = $building->blocks()->create($data);
        return response()->json($block, 201);
    }

    public function update(Request $request, Block $block)
    {
        $data = $request->validate([
            'name' => 'required|string'
        ]);

        $block->update($data);
        return response()->json($block);
    }

    public function destroy(Block $block)
    {
        $block->delete();
        return response()->json(['message' => 'Block deleted successfully']);
    }
}
