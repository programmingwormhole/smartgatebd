<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('visitor_activity_logs')) {
            return;
        }

        Schema::create('visitor_activity_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('building_id')->constrained()->cascadeOnDelete();
            $table->foreignId('guard_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('resident_id')->nullable()->constrained()->nullOnDelete();

            // Visitor/Member details
            $table->enum('visitor_type', ['temporary', 'family', 'daily_help', 'pre_approved']);
            $table->string('visitor_name');
            $table->string('visitor_phone')->nullable();
            $table->string('entry_code')->nullable()->index();

            // Activity tracking
            $table->enum('action', ['entry', 'exit', 'created', 'approved', 'rejected', 'verified']);
            $table->string('purpose')->nullable();
            $table->string('gatepass_category')->nullable(); // permanent, temporary, walk-in

            // Related data
            $table->foreignId('visitor_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('gatepass_id')->nullable()->constrained()->nullOnDelete();
            $table->string('subject_type')->nullable(); // family, daily_help (for permanent)
            $table->unsignedBigInteger('subject_id')->nullable(); // For family or daily_help

            // Metadata
            $table->text('notes')->nullable();
            $table->json('metadata')->nullable(); // store additional info
            $table->string('ip_address')->nullable();

            $table->timestamp('activity_date')->useCurrent();
            $table->timestamps();

            // Indexes for filtering
            $table->index(['building_id', 'activity_date']);
            $table->index(['resident_id', 'activity_date']);
            $table->index(['guard_id', 'activity_date']);
            $table->index(['visitor_type', 'action']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('visitor_activity_logs');
    }
};
