<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Building;
use App\Models\Resident;
use App\Models\Guard;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class BuildingController extends Controller
{
    public function index()
    {
        $search = trim((string) request()->query('search', ''));
        $query = Building::with('admins');

        if (auth()->user()?->role !== 'superadmin') {
            $query->whereHas('admins', function ($sub) {
                $sub->where('users.id', auth()->id());
            });
        }

        if ($search !== '') {
            $query->where(function ($buildingQuery) use ($search) {
                $buildingQuery->where('name', 'like', '%' . $search . '%')
                    ->orWhere('address', 'like', '%' . $search . '%')
                    ->orWhereHas('admins', function ($adminQuery) use ($search) {
                        $adminQuery->where('users.name', 'like', '%' . $search . '%')
                            ->orWhere('users.email', 'like', '%' . $search . '%')
                            ->orWhere('users.phone', 'like', '%' . $search . '%');
                    });
            });
        }

        $buildings = $query->paginate(10)->withQueryString();
        return view('buildings.index', compact('buildings'));
    }

    public function create()
    {
        return view('buildings.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'building_name' => 'required|string|max:255',
            'address' => 'required|string',
            'admin_name' => 'required|string|max:255',
            'admin_email' => 'required|email|unique:users,email',
            'admin_phone' => 'nullable|string|unique:users,phone',
            'admin_password' => 'required|string|min:6',
        ]);

        // Create the admin user
        $admin = User::create([
            'name' => $request->admin_name,
            'email' => $request->admin_email,
            'phone' => $request->admin_phone,
            'password' => Hash::make($request->admin_password),
            'role' => 'admin',
        ]);

        // Create the building
        $building = Building::create([
            'name' => $request->building_name,
            'address' => $request->address,
            'admin_id' => $admin->id,
        ]);

        // Link admin to building
        $building->admins()->attach($admin->id);

        // Keep user's primary building in sync for role-based access checks.
        $admin->update(['building_id' => $building->id]);

        return redirect()->route('admin.buildings.index')->with('success', 'Building and initial Admin successfully created.');
    }

    public function show(string $id)
    {
        $building = Building::with('admins', 'blocks.floors.flats')->findOrFail($id);
        $this->authorizeBuildingAccess($building);

        $residentCount = Resident::whereHas('flat.floor.block', function ($query) use ($building) {
            $query->where('building_id', $building->id);
        })->count();

        $recentResidents = Resident::with(['user', 'flat.floor.block'])
            ->whereHas('flat.floor.block', function ($query) use ($building) {
                $query->where('building_id', $building->id);
            })
            ->latest()
            ->limit(8)
            ->get();

        // Guard statistics
        $guardCount = Guard::where('building_id', $building->id)->count();
        $guardsOnDuty = Guard::where('building_id', $building->id)->where('status', 'on_duty')->count();
        $guardsOffDuty = Guard::where('building_id', $building->id)->where('status', 'off_duty')->count();
        $guardsOnLeave = Guard::where('building_id', $building->id)->where('status', 'leave')->count();

        $recentGuards = Guard::with('user')
            ->where('building_id', $building->id)
            ->latest()
            ->limit(8)
            ->get();

        return view('buildings.show', compact('building', 'residentCount', 'recentResidents', 'guardCount', 'guardsOnDuty', 'guardsOffDuty', 'guardsOnLeave', 'recentGuards'));
    }

    public function edit(string $id)
    {
        $building = Building::with('admins')->findOrFail($id);
        $this->authorizeBuildingAccess($building);

        $primaryAdmin = $building->admins->first();
        return view('buildings.edit', compact('building', 'primaryAdmin'));
    }

    public function update(Request $request, string $id)
    {
        $building = Building::findOrFail($id);
        $this->authorizeBuildingAccess($building);

        $request->validate([
            'building_name' => 'required|string|max:255',
            'address' => 'required|string',
            'admin_name' => 'nullable|string|max:255',
            'admin_email' => 'nullable|email',
            'admin_phone' => 'nullable|string|max:30',
            'admin_password' => 'nullable|string|min:6',
        ]);

        // Update building
        $building->update([
            'name' => $request->building_name,
            'address' => $request->address,
        ]);

        $primaryAdmin = $building->admins()->first();
        if ($primaryAdmin && $request->filled('admin_name')) {
            $primaryAdmin->name = $request->admin_name;
            $primaryAdmin->email = $request->admin_email ?: $primaryAdmin->email;
            $primaryAdmin->phone = $request->admin_phone;

            if ($request->filled('admin_password')) {
                $primaryAdmin->password = Hash::make($request->admin_password);
            }

            $primaryAdmin->save();
        }

        return redirect()->route('admin.buildings.index')->with('success', 'Building updated successfully.');
    }

    public function destroy(string $id)
    {
        $building = Building::findOrFail($id);
        $this->authorizeBuildingAccess($building);
        $building->delete();

        return redirect()->route('admin.buildings.index')->with('success', 'Building deleted successfully.');
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
        abort_unless($allowed, 403, 'You are not allowed to access this building.');
    }
}
