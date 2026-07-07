<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;
use App\Http\Controllers\NotificationController;

echo "=== Testing Notification System ===\n\n";

// Check if notification table exists
$notificationsCount = DB::table('notifications')->count();
echo "Total notifications in DB: $notificationsCount\n";

// Test creating a notification
echo "\nTesting notification creation...\n";
NotificationController::createNotification(
    1,
    'Test Bulk Bill Notification',
    'Testing bulk bill notification system',
    'info',
    'bill',
    100
);

// Verify it was created
$newCount = DB::table('notifications')->count();
echo "✓ Notification created\n";
echo "Total notifications now: $newCount\n";

// Show the notification
$lastNotification = DB::table('notifications')->latest('id')->first();
echo "\nLast notification created:\n";
echo "  - Title: {$lastNotification->title}\n";
echo "  - User ID: {$lastNotification->user_id}\n";
echo "  - Type: {$lastNotification->type}\n";
echo "  - Ref Type: {$lastNotification->ref_type}\n";
echo "  - Is Read: {$lastNotification->is_read}\n";
