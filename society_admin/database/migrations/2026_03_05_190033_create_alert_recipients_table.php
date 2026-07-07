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
        Schema::create('alert_recipients', function (Blueprint $table) {
            $table->id();
            $table->foreignId('alert_id')->constrained('emergency_alerts')->cascadeOnDelete();
            $table->unsignedBigInteger('recipient_id');
            $table->enum('recipient_type', ['admin', 'committee', 'guard', 'resident']);
            $table->boolean('is_read')->default(false);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('alert_recipients');
    }
};
