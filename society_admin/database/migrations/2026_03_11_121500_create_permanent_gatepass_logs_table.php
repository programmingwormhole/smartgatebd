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
        Schema::create('permanent_gatepass_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('guard_id')->constrained()->cascadeOnDelete();
            $table->foreignId('resident_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('subject_type', ['family', 'daily_help']);
            $table->unsignedBigInteger('subject_id');
            $table->string('entry_code')->index();
            $table->enum('action', ['entry', 'exit']);
            $table->timestamp('logged_at');
            $table->timestamps();

            $table->index(['subject_type', 'subject_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('permanent_gatepass_logs');
    }
};
