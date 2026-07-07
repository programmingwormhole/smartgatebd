<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Add 'resident_rejected' to the action enum
        DB::statement("ALTER TABLE visitor_activity_logs MODIFY COLUMN action ENUM('entry', 'exit', 'created', 'approved', 'rejected', 'verified', 'resident_rejected')");
    }

    public function down(): void
    {
        // Remove 'resident_rejected' from the action enum
        DB::statement("ALTER TABLE visitor_activity_logs MODIFY COLUMN action ENUM('entry', 'exit', 'created', 'approved', 'rejected', 'verified')");
    }
};
