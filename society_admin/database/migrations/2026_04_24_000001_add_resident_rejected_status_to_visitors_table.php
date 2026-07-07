<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        $hasRejectReason = Schema::hasColumn('visitors', 'reject_reason');

        Schema::table('visitors', function (Blueprint $table) {
            // Keep existing lifecycle statuses and add resident_rejected for two-stage rejection.
            $table->enum('status', ['pending', 'approved', 'resident_rejected', 'rejected', 'inside', 'exited'])->default('pending')->change();
        });

        if (!$hasRejectReason) {
            Schema::table('visitors', function (Blueprint $table) {
                $table->string('reject_reason', 500)->nullable();
            });
        }
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE visitors MODIFY COLUMN status ENUM('pending', 'approved', 'rejected', 'inside', 'exited') NOT NULL DEFAULT 'pending'");

        if (Schema::hasColumn('visitors', 'reject_reason')) {
            Schema::table('visitors', function (Blueprint $table) {
                $table->dropColumn('reject_reason');
            });
        }
    }
};
