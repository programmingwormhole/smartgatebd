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
        Schema::create('daily_helps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('resident_id')->constrained()->cascadeOnDelete();
            $table->enum('category', ['maid', 'cook', 'milkman', 'laundry', 'other']);
            $table->string('name');
            $table->string('phone')->nullable();
            $table->string('entry_code')->nullable();
            $table->string('qr_code')->nullable();
            $table->boolean('gatepass_enabled')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('daily_helps');
    }
};
