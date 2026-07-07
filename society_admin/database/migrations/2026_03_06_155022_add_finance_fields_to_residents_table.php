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
        Schema::table('residents', function (Blueprint $table) {
            $table->decimal('monthly_maintenance_fee', 10, 2)->default(0)->after('role');
            $table->decimal('rent', 10, 2)->default(0)->after('monthly_maintenance_fee');
            $table->unsignedTinyInteger('bill_generate_day')->default(1)->after('rent'); // Day of month (1-31)
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('residents', function (Blueprint $table) {
            $table->dropColumn(['monthly_maintenance_fee', 'rent', 'bill_generate_day']);
        });
    }
};
