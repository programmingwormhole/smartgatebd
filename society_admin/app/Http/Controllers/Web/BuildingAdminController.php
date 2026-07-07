<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Building;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class BuildingAdminController extends Controller
{
    public function store(Request $request, Building $building)
    {
        $request->validate([
            'admin_name' => 'required|string|max:255',
            'admin_email' => 'required|email|unique:users,email',
            'admin_phone' => 'nullable|string|unique:users,phone',
            'admin_password' => 'required|string|min:6',
        ]);

        $admin = User::create([
            'name' => $request->admin_name,
            'email' => $request->admin_email,
            'phone' => $request->admin_phone,
            'password' => Hash::make($request->admin_password),
            'role' => 'admin',
        ]);

        // Attach new admin to the building
        $building->admins()->attach($admin->id);

        return redirect()->route('admin.buildings.show', $building->id)->with('success', 'Admin added successfully to the building.');
    }

    public function destroy(Building $building, User $admin)
    {
        // Check if admin is attached to this building
        if ($building->admins()->where('user_id', $admin->id)->exists()) {
            
            // Detach admin from building
            $building->admins()->detach($admin->id);

            // Optional: If this admin doesn't manage any other buildings, we could delete the user entirely or keep them.
            // For now, we'll just detach them to remove access to this specific building.
            // if ($admin->managedBuildings()->count() === 0) {
            //      $admin->delete(); 
            // }

            return redirect()->route('admin.buildings.show', $building->id)->with('success', 'Admin removed from this building.');
        }

        return redirect()->route('admin.buildings.show', $building->id)->withErrors(['error' => 'Admin not found or not associated with this building.']);
    }
}
