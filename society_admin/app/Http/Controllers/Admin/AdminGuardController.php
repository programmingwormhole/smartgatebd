<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Guard;
use App\Models\User;
use App\Models\Building;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminGuardController extends Controller
{
    /**
     * Get all guards with optional filtering by building
     */
    public function index(Request $request)
    {
        $query = Guard::with('user', 'building');

        // Filter by building if specified
        if ($request->has('building_id')) {
            $query->where('building_id', $request->input('building_id'));
        }

        // Filter by status if specified
        if ($request->has('status')) {
            $query->where('status', $request->input('status'));
        }

        // Search by name or phone
        if ($request->has('search')) {
            $search = $request->input('search');
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        $guards = $query->paginate($request->input('per_page', 15));
        return response()->json($guards);
    }

    /**
     * Get guards for a specific building
     */
    public function byBuilding(Building $building, Request $request)
    {
        $query = $building->guards()->with('user');

        // Filter by status if specified
        if ($request->has('status')) {
            $query->where('status', $request->input('status'));
        }

        $guards = $query->paginate($request->input('per_page', 15));
        return response()->json(['guards' => $guards]);
    }

    /**
     * Show a specific guard
     */
    public function show(Guard $guard)
    {
        return response()->json(['guard' => $guard->load('user', 'building')]);
    }

    /**
     * Create a new guard
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'building_id' => 'required|exists:buildings,id',
            'name' => 'required|string|max:255',
            'phone' => 'required|string|max:20|unique:users,phone',
            'email' => 'nullable|email|unique:users,email',
            'status' => 'nullable|in:on_duty,off_duty,leave,inactive',
        ]);

        // Create user first with guard role
        $user = User::create([
            'name' => $validated['name'],
            'phone' => $validated['phone'],
            'email' => $validated['email'] ?? $validated['phone'] . '@guard.local',
            'password' => Hash::make($validated['phone']),
            'role' => 'guard',
            'building_id' => $validated['building_id'],
        ]);

        // Then create guard record
        $guard = Guard::create([
            'building_id' => $validated['building_id'],
            'user_id' => $user->id,
            'status' => $validated['status'] ?? 'off_duty',
        ]);

        return response()->json([
            'message' => 'Guard created successfully',
            'guard' => $guard->load('user', 'building')
        ], 201);
    }

    /**
     * Update a guard
     */
    public function update(Request $request, Guard $guard)
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'phone' => 'sometimes|string|max:20|unique:users,phone,' . $guard->user_id,
            'email' => 'sometimes|email|unique:users,email,' . $guard->user_id,
            'status' => 'sometimes|in:on_duty,off_duty,leave,inactive',
            'duty_start_time' => 'nullable|date_format:H:i',
            'duty_end_time' => 'nullable|date_format:H:i',
            'notes' => 'nullable|string',
            'assigned_areas' => 'nullable|array',
        ]);

        // Update user fields if provided
        if (isset($validated['name']) || isset($validated['phone']) || isset($validated['email'])) {
            $userData = [];
            if (isset($validated['name'])) $userData['name'] = $validated['name'];
            if (isset($validated['phone'])) $userData['phone'] = $validated['phone'];
            if (isset($validated['email'])) $userData['email'] = $validated['email'];
            $guard->user->update($userData);
        }

        // Update guard-specific fields
        $guardData = [];
        if (isset($validated['status'])) $guardData['status'] = $validated['status'];
        if (isset($validated['duty_start_time'])) $guardData['duty_start_time'] = $validated['duty_start_time'];
        if (isset($validated['duty_end_time'])) $guardData['duty_end_time'] = $validated['duty_end_time'];
        if (isset($validated['notes'])) $guardData['notes'] = $validated['notes'];
        if (isset($validated['assigned_areas'])) $guardData['assigned_areas'] = $validated['assigned_areas'];

        if (!empty($guardData)) {
            $guard->update($guardData);
        }

        return response()->json([
            'message' => 'Guard updated successfully',
            'guard' => $guard->load('user', 'building')
        ]);
    }

    /**
     * Update guard status only
     */
    public function updateStatus(Request $request, Guard $guard)
    {
        $validated = $request->validate([
            'status' => 'required|in:on_duty,off_duty,leave,inactive',
        ]);

        $guard->update(['status' => $validated['status']]);

        return response()->json([
            'message' => 'Guard status updated',
            'guard' => $guard->load('user', 'building')
        ]);
    }

    /**
     * Delete a guard (soft delete)
     */
    public function destroy(Guard $guard)
    {
        $guard->delete();

        return response()->json([
            'message' => 'Guard deleted successfully'
        ]);
    }

    /**
     * Restore a deleted guard
     */
    public function restore($guardId)
    {
        $guard = Guard::onlyTrashed()->findOrFail($guardId);
        $guard->restore();

        return response()->json([
            'message' => 'Guard restored successfully',
            'guard' => $guard->load('user', 'building')
        ]);
    }

    /**
     * Get guards by status
     */
    public function byStatus(Request $request)
    {
        $validated = $request->validate([
            'status' => 'required|in:on_duty,off_duty,leave,inactive'
        ]);

        $guards = Guard::where('status', $validated['status'])
            ->with('user', 'building')
            ->paginate($request->input('per_page', 15));

        return response()->json(['guards' => $guards]);
    }

    /**
     * Get all guards across all buildings (superadmin view)
     */
    public function allGuards(Request $request)
    {
        $query = Guard::with('user', 'building');

        // Filter by status if needed
        if ($request->has('status')) {
            $query->where('status', $request->input('status'));
        }

        // Search functionality
        if ($request->has('search')) {
            $search = $request->input('search');
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            })->orWhereHas('building', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%");
            });
        }

        $guards = $query->orderByDesc('created_at')->paginate($request->input('per_page', 20));

        return response()->json([
            'message' => 'All guards',
            'guards' => $guards
        ]);
    }

    /**
     * Get guard statistics
     */
    public function statistics(Request $request)
    {
        $buildingId = $request->input('building_id');

        $query = Guard::query();
        if ($buildingId) {
            $query->where('building_id', $buildingId);
        }

        $stats = [
            'total_guards' => $query->count(),
            'on_duty' => (clone $query)->where('status', 'on_duty')->count(),
            'off_duty' => (clone $query)->where('status', 'off_duty')->count(),
            'on_leave' => (clone $query)->where('status', 'leave')->count(),
            'inactive' => (clone $query)->where('status', 'inactive')->count(),
        ];

        return response()->json(['statistics' => $stats]);
    }
}
