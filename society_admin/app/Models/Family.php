<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Family extends Model
{
    protected $fillable = ['resident_id', 'name', 'relation', 'phone', 'gatepass_enabled', 'entry_code', 'qr_code'];

    protected $casts = [
        'gatepass_enabled' => 'boolean',
    ];

    public function resident(): BelongsTo
    {
        return $this->belongsTo(Resident::class);
    }
}
