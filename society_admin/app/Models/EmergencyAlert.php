<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class EmergencyAlert extends Model
{
    protected $fillable = ['building_id', 'type', 'message', 'status', 'created_by_admin_id'];

    public function building(): BelongsTo
    {
        return $this->belongsTo(Building::class);
    }

    public function recipients(): HasMany
    {
        return $this->hasMany(AlertRecipient::class, 'alert_id');
    }
}
