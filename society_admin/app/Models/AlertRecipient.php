<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AlertRecipient extends Model
{
    protected $fillable = ['alert_id', 'recipient_id', 'recipient_type', 'is_read'];

    public function alert(): BelongsTo
    {
        return $this->belongsTo(EmergencyAlert::class, 'alert_id');
    }
}
