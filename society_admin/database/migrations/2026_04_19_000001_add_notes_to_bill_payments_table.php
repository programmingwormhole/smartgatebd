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
        Schema::table('bill_payments', function (Blueprint $table) {
            if (!Schema::hasColumn('bill_payments', 'notes')) {
                $table->text('notes')->nullable()->after('trx_id');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bill_payments', function (Blueprint $table) {
            if (Schema::hasColumn('bill_payments', 'notes')) {
                $table->dropColumn('notes');
            }
        });
    }
};
