<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Block;
use App\Models\Building;
use App\Models\Flat;
use App\Models\Floor;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class BuildingStructureController extends Controller
{
    public function storeBlock(Request $request, Building $building): RedirectResponse
    {
        $this->authorizeBuildingAccess($building);

        $validated = $request->validate([
            'name' => [
                'required',
                'string',
                'max:100',
                Rule::unique('blocks')->where(fn ($query) => $query->where('building_id', $building->id)),
            ],
        ]);

        $building->blocks()->create($validated);

        return back()->with('success', 'Block created successfully.');
    }

    public function storeFloor(Request $request, Block $block): RedirectResponse
    {
        $this->authorizeBuildingAccess($block->building);

        $validated = $request->validate([
            'floor_number' => [
                'required',
                'string',
                'max:50',
                Rule::unique('floors')->where(fn ($query) => $query->where('block_id', $block->id)),
            ],
        ]);

        $block->floors()->create($validated);

        return back()->with('success', 'Floor created successfully.');
    }

    public function storeFlat(Request $request, Floor $floor): RedirectResponse
    {
        $this->authorizeBuildingAccess($floor->block->building);

        $validated = $request->validate([
            'flat_number' => [
                'required',
                'string',
                'max:50',
                Rule::unique('flats')->where(fn ($query) => $query->where('floor_id', $floor->id)),
            ],
        ]);

        $floor->flats()->create($validated);

        return back()->with('success', 'Flat created successfully.');
    }

    public function destroyBlock(Block $block): RedirectResponse
    {
        $this->authorizeBuildingAccess($block->building);
        $block->delete();

        return back()->with('success', 'Block deleted successfully.');
    }

    public function destroyFloor(Floor $floor): RedirectResponse
    {
        $this->authorizeBuildingAccess($floor->block->building);
        $floor->delete();

        return back()->with('success', 'Floor deleted successfully.');
    }

    public function destroyFlat(Flat $flat): RedirectResponse
    {
        $this->authorizeBuildingAccess($flat->floor->block->building);
        $flat->delete();

        return back()->with('success', 'Flat deleted successfully.');
    }

    private function authorizeBuildingAccess(Building $building): void
    {
        $user = auth()->user();

        if (! $user) {
            abort(403);
        }

        if ($user->role === 'superadmin') {
            return;
        }

        $allowed = $user->managedBuildings()->where('buildings.id', $building->id)->exists();
        abort_unless($allowed, 403, 'You are not allowed to manage this building.');
    }
}
