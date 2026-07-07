<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n=== Database Tables ===\n";
$tables = DB::select("SHOW TABLES");
echo "Tables with 'admin', 'notif', or 'build':\n";
foreach ($tables as $table) {
    $tableName = (array)$table;
    $tableName = array_values($tableName)[0];
    if (strpos(strtolower($tableName), 'admin') !== false ||
        strpos(strtolower($tableName), 'notif') !== false ||
        strpos(strtolower($tableName), 'build') !== false) {
        echo "  • $tableName\n";
    }
}

echo "\n=== Sample Notification Records ===\n";
$notifications = DB::table('notifications')
    ->select('id', 'user_id', 'title', 'message', 'ref_type', 'ref_id', 'is_read')
    ->orderBy('id', 'desc')
    ->limit(5)
    ->get();

foreach ($notifications as $notif) {
    echo "ID {$notif->id}: User {$notif->user_id}\n";
    echo "  Title: {$notif->title}\n";
    echo "  Type: {$notif->ref_type}({$notif->ref_id}) | Read: {$notif->is_read}\n\n";
}

echo "=== API Endpoint Test ===\n";
echo "To verify notifications are accessible via API:\n";
echo "1. Test endpoint: GET /api/notifications\n";
echo "2. Expected: Should return list of unread notifications for authenticated user\n";
echo "3. Check PaymentController creates notifications with:\n";
echo "   - NotificationController::createNotification() for amount validation\n\n";
