<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Auth\AuthenticationException;

class AuthService
{
    protected $otpService;

    public function __construct(OtpService $otpService)
    {
        $this->otpService = $otpService;
    }

    public function register(array $data): User
    {
        $data['password'] = Hash::make($data['password']);
        $user = User::create($data);

        $this->otpService->generateAndSend($user);

        return $user;
    }

    public function attemptLogin(string $login, string $password): User
    {
        $user = User::where('email', $login)->orWhere('phone', $login)->first();

        if (!$user || !Hash::check($password, $user->password)) {
            throw new AuthenticationException('Invalid credentials.');
        }

        $this->otpService->generateAndSend($user);

        return $user;
    }
    
    public function verifyOtpAndCreateToken(string $phone, string $otp_code): string
    {
        $user = User::where('phone', $phone)->firstOrFail();
        
        if (!$this->otpService->verify($user, $otp_code)) {
            throw new \Exception("Invalid or expired OTP");
        }
        
        // Return Sanctum token
        return $user->createToken('auth_token')->plainTextToken;
    }
}
