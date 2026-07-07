<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PermanentGatepassLog extends Model
{
    protected $fillable = [
        'guard_id',
        'resident_id',
        'subject_type',
        'subject_id',
        'entry_code',
        'action',
        'logged_at',
    ];

    protected $casts = [
        'logged_at' => 'datetime',
    ];

    public function guardUser(): BelongsTo
    {
        return $this->belongsTo(Guard::class);
    }

    public function resident(): BelongsTo
    {
        return $this->belongsTo(Resident::class);
    }
}
