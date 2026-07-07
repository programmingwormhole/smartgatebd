<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('visitor_logs', function (Blueprint $table) {
            // Change action from ENUM('entry', 'exit') to VARCHAR(255) for flexibility
            $table->string('action', 255)->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('visitor_logs', function (Blueprint $table) {
            // Revert back to ENUM if needed
            $table->enum('action', ['entry', 'exit'])->change();
        });
    }
};
