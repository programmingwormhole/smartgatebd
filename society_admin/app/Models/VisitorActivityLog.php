<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VisitorActivityLog extends Model
{
    protected $appends = ['guard'];

    protected $hidden = ['guardUser'];

    protected $fillable = [
        'building_id',
        'guard_id',
        'resident_id',
        'visitor_type',
        'visitor_name',
        'visitor_phone',
        'entry_code',
        'action',
        'purpose',
        'gatepass_category',
        'visitor_id',
        'gatepass_id',
        'subject_type',
        'subject_id',
        'notes',
        'metadata',
        'ip_address',
        'activity_date',
    ];

    protected $casts = [
        'metadata' => 'array',
        'activity_date' => 'datetime',
    ];

    public function building(): BelongsTo
    {
        return $this->belongsTo(Building::class);
    }

    public function guardUser(): BelongsTo
    {
        return $this->belongsTo(Guard::class, 'guard_id');
    }

    public function getGuardAttribute()
    {
        return $this->guardUser;
    }

    public function resident(): BelongsTo
    {
        return $this->belongsTo(Resident::class);
    }

    public function visitor(): BelongsTo
    {
        return $this->belongsTo(Visitor::class);
    }

    public function gatepass(): BelongsTo
    {
        return $this->belongsTo(Gatepass::class);
    }

    /**
     * Scope to filter by building
     */
    public function scopeByBuilding($query, int $buildingId)
    {
        return $query->where('building_id', $buildingId);
    }

    /**
     * Scope to filter by resident
     */
    public function scopeByResident($query, int $residentId)
    {
        return $query->where('resident_id', $residentId);
    }

    /**
     * Scope to filter by guard
     */
    public function scopeByGuard($query, int $guardId)
    {
        return $query->where('guard_id', $guardId);
    }

    /**
     * Scope to filter by visitor type
     */
    public function scopeByVisitorType($query, string $type)
    {
        return $query->where('visitor_type', $type);
    }

    /**
     * Scope to filter by action
     */
    public function scopeByAction($query, string $action)
    {
        return $query->where('action', $action);
    }

    /**
     * Scope to filter by date range
     */
    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('activity_date', [$startDate, $endDate]);
    }

    /**
     * Scope to filter by entry code
     */
    public function scopeByEntryCode($query, string $code)
    {
        return $query->where('entry_code', $code);
    }

    /**
     * Latest first
     */
    public function scopeLatest($query)
    {
        return $query->orderBy('activity_date', 'desc');
    }

    /**
     * Log a visitor activity
     */
    public static function logActivity(array $data)
    {
        return static::create(array_merge($data, [
            'ip_address' => request()?->ip(),
        ]));
    }

    /**
     * Get human-readable visitor type
     */
    public function getVisitorTypeLabel(): string
    {
        $labels = [
            'temporary' => 'Temporary Visitor',
            'family' => 'Family Member',
            'daily_help' => 'Daily Help',
            'pre_approved' => 'Pre-Approved Visitor',
        ];
        return $labels[$this->visitor_type] ?? ucfirst(str_replace('_', ' ', $this->visitor_type));
    }

    /**
     * Get human-readable action
     */
    public function getActionLabel(): string
    {
        $labels = [
            'entry' => 'Entry',
            'exit' => 'Exit',
            'created' => 'Created',
            'approved' => 'Approved',
            'rejected' => 'Rejected',
            'verified' => 'Verified',
        ];
        return $labels[$this->action] ?? ucfirst($this->action);
    }
}
