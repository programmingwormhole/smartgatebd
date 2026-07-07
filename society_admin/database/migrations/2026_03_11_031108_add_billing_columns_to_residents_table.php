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
            if (!Schema::hasColumn('residents', 'monthly_rent')) {
                $table->decimal('monthly_rent', 12, 2)->default(0)->after('flat_id');
            }
            if (!Schema::hasColumn('residents', 'bill_generate_date')) {
                $table->integer('bill_generate_date')->default(1)->comment('1-31, day of month when bill is generated')->after('monthly_maintenance_fee');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('residents', function (Blueprint $table) {
            if (Schema::hasColumn('residents', 'monthly_rent')) {
                $table->dropColumn('monthly_rent');
            }
            if (Schema::hasColumn('residents', 'bill_generate_date')) {
                $table->dropColumn('bill_generate_date');
            }
        });
    }
};
