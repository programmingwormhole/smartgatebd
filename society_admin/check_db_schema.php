<?php
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;

echo "\n=== Database Table Check ===\n";

// Get all tables
$tables = DB::connection()->getDoctrineSchemaManager()->listTableNames();
echo "Tables in database:\n";
foreach ($tables as $table) {
    if (strpos($table, 'admin') !== false || strpos($table, 'notif') !== false) {
        echo "  • $table\n";
    }
}

echo "\n=== Sample Bills and Residents ===\n";

$bills = DB::table('bills')->select('id', 'resident_id', 'amount', 'type')->limit(3)->get();
echo "Sample bills:\n";
foreach ($bills as $bill) {
    echo "  • Bill {$bill->id}: Resident {$bill->resident_id}, {$bill->type} - ৳{$bill->amount}\n";
}

echo "\n=== Notification Fields Check ===\n";
$schema = DB::connection()->getDoctrineSchemaManager();
$notificationTable = $schema->listTableDetails('notifications');
$columns = $notificationTable->getColumns();

echo "Notification table columns:\n";
foreach ($columns as $column) {
    echo "  • {$column->getName()}\n";
}

echo "\n";
