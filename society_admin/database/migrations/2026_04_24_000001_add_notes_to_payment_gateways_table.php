<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('payment_gateways', function (Blueprint $table) {
            if (!Schema::hasColumn('payment_gateways', 'notes')) {
                $table->text('notes')->nullable()->after('account_number');
            }
        });
    }

    public function down(): void
    {
        Schema::table('payment_gateways', function (Blueprint $table) {
            if (Schema::hasColumn('payment_gateways', 'notes')) {
                $table->dropColumn('notes');
            }
        });
    }
};
