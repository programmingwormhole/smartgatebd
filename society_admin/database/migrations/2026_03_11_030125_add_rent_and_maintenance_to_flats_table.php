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
        Schema::table('flats', function (Blueprint $table) {
            $table->decimal('monthly_rent', 12, 2)->default(5000)->after('flat_number');
            $table->decimal('monthly_maintenance_fee', 12, 2)->default(1000)->after('monthly_rent');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('flats', function (Blueprint $table) {
            $table->dropColumn(['monthly_rent', 'monthly_maintenance_fee']);
        });
    }
};
