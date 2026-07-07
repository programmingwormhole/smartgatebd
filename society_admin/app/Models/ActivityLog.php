<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ActivityLog extends Model
{
    protected $fillable = [
        'user_id',
        'building_id',
        'activity_type',
        'action',
        'description',
        'related_model',
        'related_id',
        'metadata',
        'ip_address',
        'user_agent',
        'created_at',
    ];

    protected $casts = [
        'metadata' => 'array',
        'created_at' => 'datetime',
    ];

    /**
     * Get the user who performed the activity
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Get the building context
     */
    public function building(): BelongsTo
    {
        return $this->belongsTo(Building::class);
    }

    /**
     * Scope to filter by activity type
     */
    public function scopeByType($query, string $type)
    {
        return $query->where('activity_type', $type);
    }

    /**
     * Scope to filter by date range
     */
    public function scopeByDateRange($query, $startDate, $endDate)
    {
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }

    /**
     * Scope to filter by user
     */
    public function scopeByUser($query, int $userId)
    {
        return $query->where('user_id', $userId);
    }

    /**
     * Scope to filter by building
     */
    public function scopeByBuilding($query, int $buildingId)
    {
        return $query->where('building_id', $buildingId);
    }

    /**
     * Scope to order by latest first
     */
    public function scopeLatest($query)
    {
        return $query->orderBy('created_at', 'desc');
    }

    /**
     * Log an activity
     */
    public static function log(array $data)
    {
        return static::create(array_merge($data, [
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
        ]));
    }

    /**
     * Get human-readable activity type
     */
    public function getActivityTypeLabel(): string
    {
        $labels = [
            'visitor' => 'Visitor Management',
            'complaint' => 'Complaint',
            'gatepass' => 'Gatepass',
            'resident' => 'Resident',
            'admin' => 'Admin Action',
            'guard' => 'Guard Activity',
            'bill' => 'Billing',
            'booking' => 'Booking',
            'notice' => 'Notice',
            'emergency' => 'Emergency Alert',
        ];
        return $labels[$this->activity_type] ?? ucfirst($this->activity_type);
    }

    /**
     * Get human-readable action
     */
    public function getActionLabel(): string
    {
        $labels = [
            'created' => 'Created',
            'updated' => 'Updated',
            'deleted' => 'Deleted',
            'viewed' => 'Viewed',
            'entry' => 'Entry Logged',
            'exit' => 'Exit Logged',
            'approved' => 'Approved',
            'rejected' => 'Rejected',
            'verified' => 'Verified',
            'submitted' => 'Submitted',
            'completed' => 'Completed',
            'cancelled' => 'Cancelled',
        ];
        return $labels[$this->action] ?? ucfirst($this->action);
    }
}
