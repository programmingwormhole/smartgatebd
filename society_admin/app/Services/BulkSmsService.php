<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class BulkSmsService
{
    protected $configService;

    public function __construct(SystemConfigurationService $configService)
    {
        $this->configService = $configService;
    }

    public function sendSms(string $phone, string $message): bool
    {
        $enabled = $this->configService->get('bulksmsbd_enabled', 'false') === 'true';
        if (!$enabled) {
            Log::info("BulkSMS disabled. Would have sent to {$phone}: {$message}");
            return true; // Simulate success if disabled
        }

        $apiKey = $this->configService->get('bulksmsbd_api_key');
        $senderId = $this->configService->get('bulksmsbd_sender_id');

        if (!$apiKey || !$senderId) {
            Log::error("BulkSMSBD configuration missing.");
            return false;
        }

        try {
            $response = Http::get('http://bulksmsbd.net/api/smsapi', [
                'api_key' => $apiKey,
                'type' => 'text',
                'number' => $phone,
                'senderid' => $senderId,
                'message' => $message,
            ]);

            return $response->successful();
        } catch (\Exception $e) {
            Log::error("BulkSMSBD API Error: " . $e->getMessage());
            return false;
        }
    }
}
