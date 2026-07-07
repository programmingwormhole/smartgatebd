<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$user = \App\Models\User::where('role', 'admin')->first();
$buildingId = $user->building_id;

echo "Admin ID: " . $user->id . "\n";
echo "Building ID: " . $buildingId . "\n";

try {
    $totalResidents = \App\Models\Resident::whereHas('flat.floor.block.building', function ($q) use ($buildingId) {
        $q->where('id', $buildingId);
    })->count();
    $pendingBillsCount = \App\Models\Bill::whereHas('flat.floor.block.building', function ($q) use ($buildingId) {
        $q->where('id', $buildingId);
    })->where('status', 'pending_for_approval')->count();
    
    echo "Total Residents: " . $totalResidents . "\n";
    echo "Pending Bills: " . $pendingBillsCount . "\n";
} catch (\Exception $e) {
    echo "Exception: " . $e->getMessage() . "\n";
}
