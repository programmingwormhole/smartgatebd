<?php

namespace App\Http\Controllers;

use App\Models\Building;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class BuildingController extends Controller
{
    public function index()
    {
        // Simple return all for now. Policy can refine later.
        return response()->json(
            Building::with(['blocks.floors.flats.residents.user:id,name,profile_picture'])->get()
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string',
            'address' => 'nullable|string',
            'admin_id' => [
                'nullable',
                Rule::exists('users', 'id')->where(fn ($query) => $query->where('role', 'admin')),
            ],
        ]);

        $building = DB::transaction(function () use ($data) {
            $building = Building::create($data);

            if (! empty($data['admin_id'])) {
                $admin = User::find($data['admin_id']);

                if ($admin) {
                    $admin->update(['building_id' => $building->id]);
                    $building->admins()->syncWithoutDetaching([$admin->id]);
                }
            }

            return $building;
        });

        return response()->json($building, 201);
    }

    public function update(Request $request, Building $building)
    {
        $data = $request->validate([
            'name' => 'required|string',
            'address' => 'nullable|string'
        ]);

        $building->update($data);
        return response()->json($building);
    }

    public function show(Building $building)
    {
        return response()->json(
            $building->load(['blocks.floors.flats.residents.user:id,name,profile_picture'])
        );
    }

    public function structure(Building $building)
    {
        return response()->json(
            $building->load(['blocks.floors.flats.residents.user:id,name,profile_picture'])
        );
    }
}
