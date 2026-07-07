<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n=== Testing Payment Notification Creation ===\n\n";

// Simulate a payment submission
echo "Simulating payment submission for Bill ID 1...\n";

// Get a bill with a resident
$bill = DB::table('bills')->find(1);

if (!$bill) {
    echo "❌ Bill not found\n";
} else {
    echo "✓ Bill found - Resident ID: {$bill->resident_id}\n";

    // Get resident user ID
    $resident = DB::table('residents')->find($bill->resident_id);
    if ($resident) {
        echo "✓ Resident found - User ID: {$resident->user_id}\n";

        // Count notifications before
        $countBefore = DB::table('notifications')
            ->where('user_id', $resident->user_id)
            ->where('title', 'like', 'Payment%')
            ->count();

        echo "\nNotifications before: {$countBefore}\n";

        // Get the PaymentController class
        $paymentController = new \App\Http\Controllers\PaymentController();

        echo "\n(Note: This is a database-level check.\n";
        echo " In real app, payments create notifications via PaymentController::store() method)\n";
    }
}

echo "\n=== Checking Admin Notification Retrieval ===\n";

// Test if admin can retrieve notifications
$builder = DB::table('building_admins');
$buildingAdmins = $builder->get();

echo "Building admins count: " . $buildingAdmins->count() . "\n";

if ($buildingAdmins->count() > 0) {
    foreach ($buildingAdmins->take(3) as $admin) {
        $adminNotifications = DB::table('notifications')
            ->where('user_id', $admin->user_id)
            ->count();
        echo "  - User {$admin->user_id}: {$adminNotifications} notifications\n";
    }
}

echo "\n";
