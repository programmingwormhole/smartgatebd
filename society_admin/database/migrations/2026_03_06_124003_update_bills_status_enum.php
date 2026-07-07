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
        // First, add 'unpaid' and 'pending_for_approval' to allow conversion
        // Using a raw statement is often safer for enum changes in MySQL
        DB::statement("ALTER TABLE bills MODIFY COLUMN status ENUM('pending', 'paid', 'overdue', 'unpaid', 'pending_for_approval') DEFAULT 'pending'");

        // Update existing data
        DB::table('bills')->whereIn('status', ['pending', 'overdue'])->update(['status' => 'unpaid']);

        // Set final enum and default
        DB::statement("ALTER TABLE bills MODIFY COLUMN status ENUM('paid', 'unpaid', 'pending_for_approval') DEFAULT 'unpaid'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bills', function (Blueprint $table) {
            //
        });
    }
};
