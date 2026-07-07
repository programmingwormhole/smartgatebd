<?php

namespace App\Services;

use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class FirebaseService
{
    /**
     * Send notification to specific device tokens.
     */
    public function sendNotification(array $tokens, string $title, string $body, array $data = [])
    {
        if (empty($tokens)) {
            Log::info('FCM multicast skipped: no tokens', [
                'title' => $title,
                'type' => $data['type'] ?? null,
                'ref_id' => $data['id'] ?? $data['bill_id'] ?? $data['complaint_id'] ?? $data['alert_id'] ?? null,
            ]);
            return false;
        }

        try {
            $messaging = app('firebase.messaging');

            Log::info('FCM multicast sending', [
                'token_count' => count($tokens),
                'title' => $title,
                'type' => $data['type'] ?? null,
                'ref_id' => $data['id'] ?? $data['bill_id'] ?? $data['complaint_id'] ?? $data['alert_id'] ?? null,
            ]);

            $notification = Notification::create($title, $body);

            $message = CloudMessage::new()
                ->withNotification($notification)
                ->withData($data)
                ->withAndroidConfig([
                    'priority' => 'high',
                    'notification' => [
                        'channel_id' => $data['type'] === 'emergency' ? 'emergency_alerts' : 'general_notifications',
                        'sound' => 'default',
                    ],
                ])
                ->withApnsConfig([
                    'payload' => [
                        'aps' => [
                            'sound' => 'default',
                            'badge' => 1,
                        ],
                    ],
                ]);

            // Send to multiple devices
            $report = $messaging->sendMulticast($message, $tokens);

            Log::info("FCM Multicast Report", [
                'success_count' => $report->successes()->count(),
                'failure_count' => $report->failures()->count(),
            ]);

            if ($report->hasFailures()) {
                foreach ($report->failures()->getItems() as $failure) {
                    Log::error("FCM Send Failure: " . $failure->error()->getMessage());
                }
            }

            return true;
        } catch (\Exception $e) {
            Log::error("❌ Firebase Send Exception: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Send notification to a specific topic.
     */
    public function sendToTopic(string $topic, string $title, string $body, array $data = [])
    {
        try {
            $messaging = app('firebase.messaging');

            Log::info('FCM topic sending', [
                'topic' => $topic,
                'title' => $title,
                'type' => $data['type'] ?? null,
                'ref_id' => $data['id'] ?? $data['bill_id'] ?? $data['complaint_id'] ?? $data['alert_id'] ?? null,
            ]);

            $notification = Notification::create($title, $body);

            $message = CloudMessage::withTarget('topic', $topic)
                ->withNotification($notification)
                ->withData($data)
                ->withAndroidConfig([
                    'priority' => 'high',
                    'notification' => [
                        'channel_id' => $data['type'] === 'emergency' ? 'emergency_alerts' : 'general_notifications',
                        'sound' => 'default',
                        'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
                    ],
                ])
                ->withApnsConfig([
                    'payload' => [
                        'aps' => [
                            'sound' => 'default',
                            'badge' => 1,
                        ],
                    ],
                ]);

            $messaging->send($message);

            Log::info('FCM topic message sent', [
                'topic' => $topic,
                'type' => $data['type'] ?? null,
                'ref_id' => $data['id'] ?? $data['bill_id'] ?? $data['complaint_id'] ?? $data['alert_id'] ?? null,
            ]);

            return true;
        } catch (\Exception $e) {
            Log::error("❌ Firebase Topic Send Exception: " . $e->getMessage());
            return false;
        }
    }
}
