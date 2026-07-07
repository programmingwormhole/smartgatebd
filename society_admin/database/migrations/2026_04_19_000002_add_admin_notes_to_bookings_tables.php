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
        Schema::table('amenity_bookings', function (Blueprint $table) {
            if (!Schema::hasColumn('amenity_bookings', 'rejection_reason')) {
                $table->text('rejection_reason')->nullable()->after('status');
            }
            if (!Schema::hasColumn('amenity_bookings', 'admin_comment')) {
                $table->text('admin_comment')->nullable()->after('rejection_reason');
            }
        });

        Schema::table('service_bookings', function (Blueprint $table) {
            if (!Schema::hasColumn('service_bookings', 'rejection_reason')) {
                $table->text('rejection_reason')->nullable()->after('status');
            }
            if (!Schema::hasColumn('service_bookings', 'admin_comment')) {
                $table->text('admin_comment')->nullable()->after('rejection_reason');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('amenity_bookings', function (Blueprint $table) {
            if (Schema::hasColumn('amenity_bookings', 'admin_comment')) {
                $table->dropColumn('admin_comment');
            }
            if (Schema::hasColumn('amenity_bookings', 'rejection_reason')) {
                $table->dropColumn('rejection_reason');
            }
        });

        Schema::table('service_bookings', function (Blueprint $table) {
            if (Schema::hasColumn('service_bookings', 'admin_comment')) {
                $table->dropColumn('admin_comment');
            }
            if (Schema::hasColumn('service_bookings', 'rejection_reason')) {
                $table->dropColumn('rejection_reason');
            }
        });
    }
};
