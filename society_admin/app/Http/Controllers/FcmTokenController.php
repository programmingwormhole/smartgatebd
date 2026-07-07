<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class FcmTokenController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'device_token' => 'required|string',
            'device_type' => 'nullable|string'
        ]);

        $token = $request->user()->fcmTokens()->updateOrCreate(
            ['device_token' => $data['device_token']],
            ['device_type' => $data['device_type'] ?? 'android']
        );

        $user = $request->user()->loadMissing('resident', 'guardProfile');

        Log::info('FCM token synced', [
            'user_id' => $user->id,
            'user_role' => $user->role,
            'resident_role' => optional($user->resident)->role,
            'building_id' => $user->building_id,
            'device_type' => $token->device_type,
        ]);

        return response()->json([
            'message' => 'Token saved successfully',
            'token' => $token,
            'user' => $user,
        ]);
    }

    public function destroy(Request $request)
    {
        $request->validate(['device_token' => 'required|string']);
        $request->user()->fcmTokens()->where('device_token', $request->device_token)->delete();

        return response()->json(null, 204);
    }
}
