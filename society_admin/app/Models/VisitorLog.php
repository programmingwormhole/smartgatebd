<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class VisitorLog extends Model
{
    protected $fillable = ['gatepass_id', 'guard_id', 'action', 'timestamp'];

    public function gatepass(): BelongsTo
    {
        return $this->belongsTo(Gatepass::class);
    }

    public function guardUser(): BelongsTo
    {
        return $this->belongsTo(Guard::class, 'guard_id');
    }
}
