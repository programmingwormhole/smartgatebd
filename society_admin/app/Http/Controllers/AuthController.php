<?php

namespace App\Http\Controllers;

use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\OtpVerificationRequest;
use App\Services\AuthService;
use App\Services\OtpService;
use App\Models\User;
use App\Models\Resident;
use Illuminate\Http\Request;
use App\Services\SystemConfigurationService;

class AuthController extends Controller
{
    protected $authService;
    protected $configService;

    public function __construct(AuthService $authService, SystemConfigurationService $configService)
    {
        $this->authService = $authService;
        $this->configService = $configService;
    }

    public function login(LoginRequest $request)
    {
        try {
            $user = $this->authService->attemptLogin($request->login, $request->password);
            $user->load('resident.flat.floor.block.building', 'building');
            $otpEnabled = $this->configService->get('otp_enabled', '0') === '1';

            if (!$otpEnabled) {
                return response()->json([
                    'message' => 'Logged in successfully.',
                    'access_token' => $user->createToken('auth_token')->plainTextToken,
                    'token_type' => 'Bearer',
                    'user' => $user
                ]);
            }

            return response()->json([
                'message' => 'Credentials verified. OTP sent to phone.',
                'user' => $user
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }
    }

    public function verifyOtp(OtpVerificationRequest $request)
    {
        try {
            $token = $this->authService->verifyOtpAndCreateToken($request->phone, $request->otp_code);

            $user = User::with('resident.flat.floor.block.building', 'building')->where('phone', $request->phone)->first();

            return response()->json([
                'message' => 'OTP verified successfully.',
                'access_token' => $token,
                'token_type' => 'Bearer',
                'user' => $user
            ]);
        } catch (\Exception $e) {
            return response()->json(['message' => $e->getMessage()], 400);
        }
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out successfully.']);
    }

    public function profile(Request $request)
    {
        $user = $request->user()->load('resident.flat.floor.block.building', 'building');
        return response()->json(['user' => $user]);
    }

    public function resendOtp(Request $request)
    {
        $request->validate(['phone' => 'required|string|exists:users,phone']);
        $user = User::where('phone', $request->phone)->first();

        $otpService = app(OtpService::class);
        $otpService->generateAndSend($user);

        return response()->json(['message' => 'New OTP sent to phone.']);
    }

    public function updateProfile(Request $request)
    {
        $user = auth()->user();
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'nullable|email|unique:users,email,' . $user->id,
            'phone' => 'nullable|string|unique:users,phone,' . $user->id,
        ]);

        $user->update($data);

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => $user
        ]);
    }

    public function uploadProfilePicture(Request $request)
    {
        $user = auth()->user();

        $request->validate([
            'profile_picture' => 'required|image|mimes:jpeg,png,jpg,gif|max:5120' // max 5MB
        ]);

        // Delete old profile picture if exists
        if ($user->profile_picture && file_exists(public_path($user->profile_picture))) {
            unlink(public_path($user->profile_picture));
        }

        // Store new profile picture
        $file = $request->file('profile_picture');
        $path = $file->store('profile_pictures', 'public');
        $profilePictureUrl = '/storage/' . $path;

        // Update user
        $user->update(['profile_picture' => $profilePictureUrl]);

        return response()->json([
            'message' => 'Profile picture updated successfully',
            'profile_picture' => $profilePictureUrl,
            'user' => $user
        ], 200);
    }

    public function deleteProfilePicture(Request $request)
    {
        $user = auth()->user();

        if ($user->profile_picture) {
            if (file_exists(public_path($user->profile_picture))) {
                unlink(public_path($user->profile_picture));
            }
            $user->update(['profile_picture' => null]);
        }

        return response()->json([
            'message' => 'Profile picture deleted successfully',
            'user' => $user
        ], 200);
    }

    public function changePassword(Request $request)
    {
        $user = auth()->user();

        $request->validate([
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:8|confirmed',
        ]);

        // Verify current password
        if (!\Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'message' => 'Current password is incorrect'
            ], 422);
        }

        // Update password
        $user->update([
            'password' => \Hash::make($request->new_password)
        ]);

        return response()->json([
            'message' => 'Password changed successfully'
        ]);
    }

    public function config()
    {
        return response()->json([
            'otp_enabled' => $this->configService->get('otp_enabled', '0') === '1'
        ]);
    }
}
