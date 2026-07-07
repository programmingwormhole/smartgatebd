<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use App\Models\Traits\ScopedByBuilding;

class Guard extends Model
{
    use HasFactory, SoftDeletes, ScopedByBuilding;

    protected $fillable = [
        'building_id',
        'user_id',
        'status',
        'duty_start_time',
        'duty_end_time',
        'notes',
        'assigned_areas',
    ];

    protected $casts = [
        'assigned_areas' => 'array',
        'duty_start_time' => 'datetime',
        'duty_end_time' => 'datetime',
    ];

    protected $with = ['user', 'building'];

    public function building(): BelongsTo
    {
        return $this->belongsTo(Building::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function scopeActive($query)
    {
        return $query->whereIn('status', ['on_duty', 'off_duty']);
    }

    public function scopeOnDuty($query)
    {
        return $query->where('status', 'on_duty');
    }

    protected function getStatusLabelAttribute(): string
    {
        return match($this->status) {
            'on_duty' => 'On Duty',
            'off_duty' => 'Off Duty',
            'leave' => 'On Leave',
            'inactive' => 'Inactive',
            default => 'Unknown',
        };
    }
}
