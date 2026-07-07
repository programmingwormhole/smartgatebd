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
        Schema::table('bills', function (Blueprint $table) {
            if (!Schema::hasColumn('bills', 'resident_id')) {
                $table->unsignedBigInteger('resident_id')->nullable()->after('flat_id');
                $table->foreign('resident_id')->references('id')->on('residents')->onDelete('cascade');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bills', function (Blueprint $table) {
            if (Schema::hasColumn('bills', 'resident_id')) {
                $table->dropForeign(['resident_id']);
                $table->dropColumn('resident_id');
            }
        });
    }
};
