<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Amenity extends Model
{
    protected $fillable = ['building_id', 'name', 'price_per_day', 'max_capacity', 'open_time', 'close_time', 'slot_duration_minutes'];

    public function building(): BelongsTo
    {
        return $this->belongsTo(Building::class);
    }

    public function bookings(): HasMany
    {
        return $this->hasMany(AmenityBooking::class);
    }
}
