<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    /**
     * Create a new user (primarily for guard creation)
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string',
            'password' => 'required|string|min:6',
            'role' => 'required|string|in:resident,admin,guard',
        ]);

        $data['password'] = Hash::make($data['password']);

        $user = User::create($data);

        return response()->json(['user' => $user], 201);
    }

    /**
     * Get current authenticated user
     */
    public function show(Request $request)
    {
        return response()->json(['user' => $request->user()]);
    }

    /**
     * Update current user
     */
    public function update(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|email|unique:users,email,' . $user->id,
            'phone' => 'nullable|string',
        ]);

        $user->update($data);

        return response()->json(['user' => $user]);
    }
}
