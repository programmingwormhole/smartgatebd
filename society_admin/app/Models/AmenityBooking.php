<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AmenityBooking extends Model
{
    protected $fillable = [
        'resident_id',
        'amenity_id',
        'booking_date',
        'from_time',
        'to_time',
        'status',
        'rejection_reason',
        'admin_comment',
    ];

    protected $casts = [
        'booking_date' => 'date',
    ];

    public function resident(): BelongsTo
    {
        return $this->belongsTo(Resident::class);
    }

    public function amenity(): BelongsTo
    {
        return $this->belongsTo(Amenity::class);
    }
}
