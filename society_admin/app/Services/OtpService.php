<?php

namespace App\Services;

use App\Models\User;
use Carbon\Carbon;

class OtpService
{
    protected $smsService;
    protected $configService;

    public function __construct(BulkSmsService $smsService, SystemConfigurationService $configService)
    {
        $this->smsService = $smsService;
        $this->configService = $configService;
    }

    public function generateAndSend(User $user)
    {
        $otpEnabled = $this->configService->get('otp_enabled', '0') === '1';
        
        $otpCode = rand(100000, 999999);
        $expiryMinutes = (int) $this->configService->get('otp_expiry_minutes', 5);

        $user->otp_code = (string)$otpCode;
        $user->otp_expires_at = Carbon::now()->addMinutes($expiryMinutes);
        $user->save();

        if ($otpEnabled) {
            $message = "Your SmartGateBD verification code is: {$otpCode}. It is valid for {$expiryMinutes} minutes.";
            $this->smsService->sendSms($user->phone, $message);
        }

        return $otpCode;
    }

    public function verify(User $user, string $code): bool
    {
        if ($user->otp_code !== $code) {
            return false;
        }
        if (Carbon::now()->gt($user->otp_expires_at)) {
            return false;
        }

        // Clear OTP upon successful validation
        $user->otp_code = null;
        $user->otp_expires_at = null;
        $user->save();

        return true;
    }
}
