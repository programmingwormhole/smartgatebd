<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

echo "\n=== Recent Notifications (Last 30 minutes) ===\n";
$recentNotifications = DB::table('notifications')
    ->where('created_at', '>=', Carbon::now()->subMinutes(30))
    ->orderBy('created_at', 'desc')
    ->limit(15)
    ->get();

if ($recentNotifications->count() > 0) {
    foreach ($recentNotifications as $notif) {
        echo "• User {$notif->user_id}: {$notif->title}\n";
        echo "  Type: {$notif->type} | Ref: {$notif->ref_type}({$notif->ref_id})\n";
        echo "  Created: {$notif->created_at}\n\n";
    }
} else {
    echo "No notifications in last 30 minutes\n\n";
}

echo "=== Notification Counts by Type ===\n";
$byType = DB::table('notifications')
    ->groupBy('ref_type')
    ->selectRaw('ref_type, COUNT(*) as count')
    ->orderByDesc('count')
    ->get();

foreach ($byType as $row) {
    echo "• {$row->ref_type}: {$row->count} notifications\n";
}

echo "\n=== Total Notifications in DB ===\n";
$total = DB::table('notifications')->count();
echo "Total: {$total}\n\n";
