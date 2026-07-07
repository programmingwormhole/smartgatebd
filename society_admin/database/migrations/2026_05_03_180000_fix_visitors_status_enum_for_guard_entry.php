<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Ensure guard lifecycle statuses are valid in visitors.status.
        DB::statement("ALTER TABLE visitors MODIFY COLUMN status ENUM('pending', 'approved', 'resident_rejected', 'rejected', 'inside', 'exited') NOT NULL DEFAULT 'pending'");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE visitors MODIFY COLUMN status ENUM('pending', 'approved', 'resident_rejected', 'rejected') NOT NULL DEFAULT 'pending'");
    }
};
