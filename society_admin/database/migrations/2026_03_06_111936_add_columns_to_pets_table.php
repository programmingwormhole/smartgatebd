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
        Schema::table('pets', function (Blueprint $table) {
            $table->foreignId('resident_id')->after('id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('type');
            $table->string('breed')->nullable();
            $table->boolean('is_vaccinated')->default(false);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('pets', function (Blueprint $table) {
            $table->dropForeign(['resident_id']);
            $table->dropColumn(['resident_id', 'name', 'type', 'breed', 'is_vaccinated']);
        });
    }
};
