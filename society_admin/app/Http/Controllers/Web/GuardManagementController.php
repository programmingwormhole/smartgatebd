<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Building;
use App\Models\Guard;
use App\Models\User;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;
use Illuminate\View\View;

class GuardManagementController extends Controller
{
    /**
     * Display a listing of guards
     */
    public function index(Request $request): View
    {
        $user = $request->user();
        $search = trim((string) $request->query('search', ''));
        $buildingId = $request->query('building_id');

        $buildings = $user->role === 'superadmin'
            ? Building::orderBy('name')->get(['id', 'name'])
            : Building::where('id', $user->building_id)->orderBy('name')->get(['id', 'name']);

        $guards = Guard::query()
            ->with(['user', 'building'])
            ->when($user->role !== 'superadmin', function ($query) use ($user) {
                $query->where('building_id', $user->building_id);
            })
            ->when($user->role === 'superadmin' && filled($buildingId), function ($query) use ($buildingId) {
                $query->where('building_id', $buildingId);
            })
            ->when($search !== '', function ($query) use ($search) {
                $query->where(function ($inner) use ($search) {
                    $inner->whereHas('user', function ($userQuery) use ($search) {
                        $userQuery->where('name', 'like', '%' . $search . '%')
                            ->orWhere('phone', 'like', '%' . $search . '%')
                            ->orWhere('email', 'like', '%' . $search . '%');
                    })->orWhereHas('building', function ($buildingQuery) use ($search) {
                        $buildingQuery->where('name', 'like', '%' . $search . '%');
                    })->orWhere('status', 'like', '%' . $search . '%');
                });
            })
            ->latest()
            ->paginate(20)
            ->withQueryString();

        return view('guards.index', compact('guards', 'search', 'buildings', 'buildingId'));
    }

    /**
     * Show the form for creating a new guard
     */
    public function create(Request $request): View
    {
        $user = $request->user();

        if ($user->role === 'superadmin') {
            $buildings = Building::orderBy('name')->get(['id', 'name']);
        } else {
            $buildings = Building::where('id', $user->building_id)->get(['id', 'name']);
        }

        return view('guards.create', compact('buildings'));
    }

    /**
     * Store a newly created guard
     */
    public function store(Request $request): RedirectResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'building_id' => ['required', 'integer', Rule::exists('buildings', 'id')],
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:20', Rule::unique('users', 'phone')],
            'email' => ['nullable', 'email', 'max:255', Rule::unique('users', 'email')],
            'status' => ['nullable', Rule::in(['on_duty', 'off_duty', 'leave', 'inactive'])],
        ]);

        // Check authorization
        if ($user->role !== 'superadmin' && $user->building_id !== (int) $validated['building_id']) {
            abort(403, 'You are not authorized to create guards for this building.');
        }

        // Create the user
        $newUser = User::create([
            'name' => $validated['name'],
            'phone' => $validated['phone'],
            'email' => $validated['email'] ?? $validated['phone'] . '@guard.local',
            'password' => Hash::make($validated['phone']),
            'role' => 'guard',
            'building_id' => $validated['building_id'],
        ]);

        // Create the guard record
        Guard::create([
            'building_id' => $validated['building_id'],
            'user_id' => $newUser->id,
            'status' => $validated['status'] ?? 'off_duty',
        ]);

        return redirect()->route('admin.guards.index')
            ->with('success', 'Guard created successfully. Password is their phone number.');
    }

    /**
     * Display the specified guard
     */
    public function show(Guard $guard, Request $request): View
    {
        $user = $request->user();

        // Check authorization
        if ($user->role !== 'superadmin' && $user->building_id !== $guard->building_id) {
            abort(403, 'You are not authorized to view this guard.');
        }

        $guard->load(['user', 'building']);

        return view('guards.show', compact('guard'));
    }

    /**
     * Show the form for editing the specified guard
     */
    public function edit(Guard $guard, Request $request): View
    {
        $user = $request->user();

        // Check authorization
        if ($user->role !== 'superadmin' && $user->building_id !== $guard->building_id) {
            abort(403, 'You are not authorized to edit this guard.');
        }

        $guard->load(['user', 'building']);

        if ($user->role === 'superadmin') {
            $buildings = Building::orderBy('name')->get(['id', 'name']);
        } else {
            $buildings = Building::where('id', $user->building_id)->get(['id', 'name']);
        }

        return view('guards.edit', compact('guard', 'buildings'));
    }

    /**
     * Update the specified guard
     */
    public function update(Guard $guard, Request $request): RedirectResponse
    {
        $user = $request->user();

        // Check authorization
        if ($user->role !== 'superadmin' && $user->building_id !== $guard->building_id) {
            abort(403, 'You are not authorized to update this guard.');
        }

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'phone' => ['required', 'string', 'max:20', Rule::unique('users', 'phone')->ignore($guard->user_id)],
            'email' => ['nullable', 'email', 'max:255', Rule::unique('users', 'email')->ignore($guard->user_id)],
            'status' => ['required', Rule::in(['on_duty', 'off_duty', 'leave', 'inactive'])],
            'notes' => ['nullable', 'string'],
        ]);

        // Update user information
        $guard->user->update([
            'name' => $validated['name'],
            'phone' => $validated['phone'],
            'email' => $validated['email'],
        ]);

        // Update guard information
        $guard->update([
            'status' => $validated['status'],
            'notes' => $validated['notes'],
        ]);

        return redirect()->route('admin.guards.show', $guard)
            ->with('success', 'Guard updated successfully.');
    }

    /**
     * Remove the specified guard
     */
    public function destroy(Guard $guard, Request $request): RedirectResponse
    {
        $user = $request->user();

        // Check authorization
        if ($user->role !== 'superadmin' && $user->building_id !== $guard->building_id) {
            abort(403, 'You are not authorized to delete this guard.');
        }

        $guardName = $guard->user->name;

        // Soft delete the guard
        $guard->delete();

        // Optionally delete or disable the user account
        // $guard->user->delete();

        return redirect()->route('admin.guards.index')
            ->with('success', "Guard '{$guardName}' has been deleted.");
    }
}
