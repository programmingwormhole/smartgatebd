<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        DB::statement("ALTER TABLE bills MODIFY COLUMN type ENUM('rent', 'maintenance', 'custom', 'utility', 'security', 'water', 'electricity', 'other') NOT NULL");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        DB::statement("ALTER TABLE bills MODIFY COLUMN type ENUM('rent', 'maintenance', 'custom') NOT NULL");
    }
};
