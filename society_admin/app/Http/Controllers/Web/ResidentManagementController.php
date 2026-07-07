<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Block;
use App\Models\Building;
use App\Models\Flat;
use App\Models\Floor;
use App\Models\Resident;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class ResidentManagementController extends Controller
{
    public function index(Request $request): View
    {
        $user = $request->user();
        $search = trim((string) $request->query('search', ''));

        $residents = Resident::query()
            ->with(['user', 'flat.floor.block.building'])
            ->when($user->role !== 'superadmin', function ($query) use ($user) {
                $query->whereHas('flat.floor.block.building.admins', function ($sub) use ($user) {
                    $sub->where('users.id', $user->id);
                });
            })
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($inner) use ($search) {
                    $inner->whereHas('user', function ($userQuery) use ($search) {
                        $userQuery->where('name', 'like', '%' . $search . '%')
                            ->orWhere('phone', 'like', '%' . $search . '%')
                            ->orWhere('email', 'like', '%' . $search . '%');
                    })->orWhereHas('flat', function ($flatQuery) use ($search) {
                        $flatQuery->where('flat_number', 'like', '%' . $search . '%')
                            ->orWhereHas('floor', function ($floorQuery) use ($search) {
                                $floorQuery->where('floor_number', 'like', '%' . $search . '%')
                                    ->orWhereHas('block', function ($blockQuery) use ($search) {
                                        $blockQuery->where('name', 'like', '%' . $search . '%');
                                    });
                            });
                    })->orWhere('role', 'like', '%' . $search . '%');
                });
            })
            ->latest()
            ->paginate(20)
            ->withQueryString();

        return view('residents.index', compact('residents', 'search'));
    }

    public function create(Request $request): View
    {
        $user = $request->user();

        $building = $this->resolveAuthorizedBuilding($request, $user);

        $blocks = $building->blocks()->orderBy('name')->get(['id', 'name']);

        // For superadmin, pass all buildings
        $isSuperadmin = $user->role === 'superadmin';
        $allBuildings = $isSuperadmin ? Building::orderBy('name')->get(['id', 'name']) : null;

        return view('residents.create', [
            'building' => $building,
            'blocks' => $blocks,
            'isSuperadmin' => $isSuperadmin,
            'allBuildings' => $allBuildings,
        ]);
    }

    public function store(Request $request): RedirectResponse
    {
        $user = $request->user();
        $building = $this->resolveAuthorizedBuilding($request, $user);

        $validated = $request->validate([
            'building_id' => $user->role === 'superadmin' ? ['required', 'integer', Rule::exists('buildings', 'id')] : [],
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:20', Rule::unique('users', 'phone')],
            'email' => ['nullable', 'email', 'max:255', Rule::unique('users', 'email')],
            'role' => ['required', Rule::in(['resident', 'admin', 'committee'])],
            'block_id' => ['required', 'integer', Rule::exists('blocks', 'id')],
            'floor_id' => ['required', 'integer', Rule::exists('floors', 'id')],
            'flat_id' => ['required', 'integer', Rule::exists('flats', 'id')],
            'monthly_maintenance_fee' => ['nullable', 'numeric', 'min:0'],
            'rent' => ['nullable', 'numeric', 'min:0'],
            'bill_generate_day' => ['nullable', 'integer', 'between:1,28'],
        ]);

        // If superadmin selected a building, use that instead
        if ($user->role === 'superadmin' && ! empty($validated['building_id'])) {
            $building = Building::findOrFail($validated['building_id']);
        }

        $flat = Flat::with('floor.block')->findOrFail((int) $validated['flat_id']);

        if ((int) $validated['block_id'] !== (int) $flat->floor->block_id || (int) $validated['floor_id'] !== (int) $flat->floor_id) {
            return back()->withInput()->withErrors(['flat_id' => 'Selected flat does not match the selected block/floor.']);
        }

        if ((int) $flat->floor->block->building_id !== (int) $building->id) {
            abort(403, 'Selected flat does not belong to your building.');
        }

        $newUser = User::create([
            'name' => $validated['name'],
            'phone' => $validated['phone'],
            'email' => $validated['email'] ?? null,
            'role' => 'resident',
            'building_id' => $building->id,
            // Default password can be changed by resident later.
            'password' => Hash::make($validated['phone']),
        ]);

        Resident::create([
            'user_id' => $newUser->id,
            'flat_id' => $flat->id,
            'role' => $validated['role'],
            'monthly_maintenance_fee' => $validated['monthly_maintenance_fee'] ?? 0,
            'rent' => $validated['rent'] ?? 0,
            'bill_generate_day' => $validated['bill_generate_day'] ?? 1,
        ]);

        return redirect()->route('admin.residents.index')->with('success', 'Resident created successfully.');
    }

    public function blocks(Request $request, Building $building): JsonResponse
    {
        $this->authorizeBuildingAccess($request->user(), $building);

        return response()->json(
            $building->blocks()->orderBy('name')->get(['id', 'name'])
        );
    }

    public function floors(Request $request, Block $block): JsonResponse
    {
        $this->authorizeBuildingAccess($request->user(), $block->building);

        return response()->json(
            $block->floors()->orderBy('floor_number')->get(['id', 'floor_number'])
        );
    }

    public function flats(Request $request, Floor $floor): JsonResponse
    {
        $this->authorizeBuildingAccess($request->user(), $floor->block->building);

        return response()->json(
            $floor->flats()->orderBy('flat_number')->get(['id', 'flat_number'])
        );
    }

    public function show(Request $request, Resident $resident): View
    {
        $this->authorizeBuildingAccess($request->user(), $resident->flat->floor->block->building);

        $resident->load([
            'user',
            'flat.floor.block.building',
            'flat.bills' => fn($q) => $q->latest()->limit(10),
            'families',
            'visitors' => fn($q) => $q->latest()->limit(10),
            'vehicles',
            'pets',
            'dailyHelps' => fn($q) => $q->latest()->limit(10),
        ]);

        // Get statistics
        $stats = [
            'total_bills' => $resident->flat->bills()->count(),
            'pending_bills' => $resident->flat->bills()->where('status', 'pending')->count(),
            'paid_bills' => $resident->flat->bills()->where('status', 'paid')->count(),
            'total_families' => $resident->families()->count(),
            'total_vehicles' => $resident->vehicles()->count(),
            'total_pets' => $resident->pets()->count(),
            'total_visitors' => $resident->visitors()->count(),
            'pending_visitors' => $resident->visitors()->where('status', 'pending')->count(),
        ];

        return view('residents.show', compact('resident', 'stats'));
    }

    public function edit(Request $request, Resident $resident): View
    {
        $user = $request->user();
        $building = $resident->flat->floor->block->building;
        $this->authorizeBuildingAccess($user, $building);

        $resident->load(['user', 'flat.floor.block']);
        $blocks = $building->blocks()->orderBy('name')->get(['id', 'name']);

        // For superadmin, pass all buildings
        $isSuperadmin = $user->role === 'superadmin';
        $allBuildings = $isSuperadmin ? Building::orderBy('name')->get(['id', 'name']) : null;

        return view('residents.edit', [
            'resident' => $resident,
            'building' => $building,
            'blocks' => $blocks,
            'isSuperadmin' => $isSuperadmin,
            'allBuildings' => $allBuildings,
        ]);
    }

    public function update(Request $request, Resident $resident): RedirectResponse
    {
        $user = $request->user();
        $building = $resident->flat->floor->block->building;
        $this->authorizeBuildingAccess($user, $building);

        $validated = $request->validate([
            'building_id' => $user->role === 'superadmin' ? ['required', 'integer', Rule::exists('buildings', 'id')] : [],
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:20', Rule::unique('users', 'phone')->ignore($resident->user_id)],
            'email' => ['nullable', 'email', 'max:255', Rule::unique('users', 'email')->ignore($resident->user_id)],
            'role' => ['required', Rule::in(['resident', 'admin', 'committee'])],
            'block_id' => ['required', 'integer', Rule::exists('blocks', 'id')],
            'floor_id' => ['required', 'integer', Rule::exists('floors', 'id')],
            'flat_id' => ['required', 'integer', Rule::exists('flats', 'id')],
            'monthly_maintenance_fee' => ['nullable', 'numeric', 'min:0'],
            'rent' => ['nullable', 'numeric', 'min:0'],
            'bill_generate_day' => ['nullable', 'integer', 'between:1,28'],
        ]);

        // If superadmin selected a building, use that
        if ($user->role === 'superadmin' && ! empty($validated['building_id'])) {
            $building = Building::findOrFail($validated['building_id']);
        }

        $flat = Flat::with('floor.block')->findOrFail((int) $validated['flat_id']);

        if ((int) $validated['block_id'] !== (int) $flat->floor->block_id || (int) $validated['floor_id'] !== (int) $flat->floor_id) {
            return back()->withInput()->withErrors(['flat_id' => 'Selected flat does not match the selected block/floor.']);
        }

        if ((int) $flat->floor->block->building_id !== (int) $building->id) {
            abort(403, 'Selected flat does not belong to your building.');
        }

        // Update user info
        $resident->user->update([
            'name' => $validated['name'],
            'phone' => $validated['phone'],
            'email' => $validated['email'] ?? null,
        ]);

        // Update resident info
        $resident->update([
            'flat_id' => $flat->id,
            'role' => $validated['role'],
            'monthly_maintenance_fee' => $validated['monthly_maintenance_fee'] ?? 0,
            'rent' => $validated['rent'] ?? 0,
            'bill_generate_day' => $validated['bill_generate_day'] ?? 1,
        ]);

        return redirect()->route('admin.residents.show', $resident)->with('success', 'Resident updated successfully.');
    }

    public function destroy(Request $request, Resident $resident): RedirectResponse
    {
        $this->authorizeBuildingAccess($request->user(), $resident->flat->floor->block->building);

        $resident->delete();

        return redirect()->route('admin.residents.index')->with('success', 'Resident deleted successfully.');
    }

    private function resolveAuthorizedBuilding(Request $request, User $user): Building
    {
        if ($user->role === 'superadmin') {
            $buildingId = (int) $request->query('building_id', $request->input('building_id', 0));
            $building = $buildingId > 0
                ? Building::find($buildingId)
                : Building::orderBy('name')->first();

            abort_if(! $building, 422, 'No building found. Please create a building first.');
            return $building;
        }

        $building = $user->managedBuildings()->orderBy('buildings.name')->first();
        abort_if(! $building, 403, 'No building assigned to this admin account.');

        return $building;
    }

    private function authorizeBuildingAccess(User $user, Building $building): void
    {
        if ($user->role === 'superadmin') {
            return;
        }

        $allowed = $user->managedBuildings()->where('buildings.id', $building->id)->exists();
        abort_unless($allowed, 403, 'You are not allowed to access this building.');
    }
}
