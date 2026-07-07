<?php

namespace App\Http\Controllers;

use App\Models\Building;
use App\Models\Guard;
use App\Models\Resident;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Http\Request;

class ResidentController extends Controller
{
    public function index(Building $building)
    {
        // Get all residents through flats in this building
        $residents = Resident::whereHas('flat.floor.block.building', function ($q) use ($building) {
            $q->where('id', $building->id);
        })->with(['user', 'flat'])->get();

        return response()->json($residents);
    }

    public function store(Request $request, Building $building)
    {
        $user = $request->user();
        if (!in_array($user->role, ['admin', 'committee', 'superadmin'], true)) {
            return response()->json(['message' => 'Only admins can create residents'], 403);
        }

        if ($user->role !== 'superadmin' && (int) $user->building_id !== (int) $building->id) {
            return response()->json(['message' => 'Unauthorized for this building'], 403);
        }

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20|unique:users',
            'email' => 'nullable|email|unique:users',
            'flat_id' => 'required|exists:flats,id',
            'role' => 'nullable|in:resident,admin,committee',
            // Allow setting bill defaults on resident
            'monthly_maintenance_fee' => 'nullable|numeric|min:0',
            'rent' => 'nullable|numeric|min:0',
            'bill_generate_day' => 'nullable|integer|between:1,28',
        ]);

        $flat = \App\Models\Flat::with('floor.block')->findOrFail((int) $data['flat_id']);
        if ((int) $flat->floor->block->building_id !== (int) $building->id) {
            return response()->json(['message' => 'Selected flat does not belong to this building'], 422);
        }

        // Create the user automatically with a default password
        $user = User::create([
            'name' => $data['name'],
            'phone' => $data['phone'],
            'email' => $data['email'],
            'password' => Hash::make($data['phone']), // Default password is their phone number
            'role' => 'resident', // Default system role for residents
            'building_id' => $building->id
        ]);

        $resident = Resident::create([
            'user_id' => $user->id,
            'flat_id' => $data['flat_id'],
            'role' => $data['role'] ?? 'resident',
            'monthly_maintenance_fee' => $data['monthly_maintenance_fee'] ?? 0,
            'rent' => $data['rent'] ?? 0,
            'bill_generate_day' => $data['bill_generate_day'] ?? 1,
        ]);

        // If maintenance fee is provided, we can optionally store it in the flat or resident model
        // depending on structural decision, but often it's kept on Flat or handled during bill generation.
        // For mass generation, we'll use a fixed value or flat-specific value.

        return response()->json($resident->load('user', 'flat'), 201);
    }

    public function update(Request $request, Resident $resident)
    {
        $user = $request->user();
        if (!in_array($user->role, ['admin', 'committee', 'superadmin'], true)) {
            return response()->json(['message' => 'Only admins can update residents'], 403);
        }

        $residentBuildingId = $resident->flat->floor->block->building_id;
        if ($user->role !== 'superadmin' && (int) $user->building_id !== (int) $residentBuildingId) {
            return response()->json(['message' => 'Unauthorized for this resident'], 403);
        }

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20|unique:users,phone,' . $resident->user_id,
            'email' => 'nullable|email|unique:users,email,' . $resident->user_id,
            'flat_id' => 'required|exists:flats,id',
            'role' => 'required|in:resident,admin,committee',
            'monthly_maintenance_fee' => 'nullable|numeric|min:0',
            'rent' => 'nullable|numeric|min:0',
            'bill_generate_day' => 'nullable|integer|between:1,28',
        ]);

        $flat = \App\Models\Flat::with('floor.block')->findOrFail((int) $data['flat_id']);
        if ((int) $flat->floor->block->building_id !== (int) $residentBuildingId) {
            return response()->json(['message' => 'Selected flat does not belong to this building'], 422);
        }

        $resident->user->update([
            'name' => $data['name'],
            'phone' => $data['phone'],
            'email' => $data['email'] ?? null,
        ]);

        $resident->update([
            'flat_id' => $data['flat_id'],
            'role' => $data['role'],
            'monthly_maintenance_fee' => $data['monthly_maintenance_fee'] ?? 0,
            'rent' => $data['rent'] ?? 0,
            'bill_generate_day' => $data['bill_generate_day'] ?? 1,
        ]);

        return response()->json($resident->load('user', 'flat'));
    }

    public function destroy(Resident $resident)
    {
        $resident->delete();
        return response()->json(null, 204);
    }

    public function members(Request $request)
    {
        $user = $request->user();
        $buildingId = $request->query('building_id');

        if (!$buildingId && $user->role === 'guard') {
            $buildingId = Guard::where('user_id', $user->id)->value('building_id') ?? $user->building_id;
        }

        if (!$buildingId) {
            $buildingId = $user->building_id;
        }

        if (!$buildingId && $user->resident) {
            $buildingId = $user->resident->flat->floor->block->building_id;
        }

        if (!$buildingId) {
            return response()->json(['message' => 'Building context not found'], 404);
        }

        $residentMembers = Resident::whereHas('flat.floor.block.building', function ($q) use ($buildingId) {
            $q->where('id', $buildingId);
        })->with(['user', 'flat.floor.block.building'])->get();

        $members = collect($residentMembers);

        // Include default building admins who may not have a resident profile yet.
        if (in_array($user->role, ['resident', 'committee', 'admin', 'superadmin'], true)) {
            $residentUserIds = $residentMembers->pluck('user_id')->filter()->values();

            $adminUsers = User::query()
                ->where('role', 'admin')
                ->where('building_id', $buildingId)
                ->whereNotIn('id', $residentUserIds)
                ->with('building')
                ->get();

            $adminMembers = $adminUsers->map(function (User $admin) {
                return [
                    'id' => $admin->id,
                    'user_id' => $admin->id,
                    'flat_id' => null,
                    'role' => 'admin',
                    'user' => [
                        'id' => $admin->id,
                        'name' => $admin->name,
                        'phone' => $admin->phone,
                        'email' => $admin->email,
                        'profile_picture' => $admin->profile_picture,
                    ],
                    'flat' => [
                        'flat_number' => null,
                        'floor' => [
                            'block' => [
                                'name' => null,
                                'building' => [
                                    'name' => optional($admin->building)->name,
                                ],
                            ],
                        ],
                    ],
                ];
            });

            $members = $members->concat($adminMembers);
        }

        return response()->json(['members' => $members->values()]);
    }

    public function committee(Request $request)
    {
        $user = $request->user();
        $buildingId = $request->query('building_id') ?? $user->building_id;

        if (!$buildingId && $user->resident) {
            $buildingId = $user->resident->flat->floor->block->building_id;
        }

        $members = Resident::where('role', 'committee')
            ->whereHas('flat.floor.block.building', function ($q) use ($buildingId) {
                $q->where('id', $buildingId);
            })->with(['user', 'flat'])->get();

        return response()->json(['members' => $members]);
    }
}
