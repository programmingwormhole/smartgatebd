<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Gatepass extends Model
{
    protected $fillable = [
        'visitor_id', 'gatepass_code', 'entry_code', 
        'qr_code', 'entry_time', 'exit_time'
    ];

    protected $casts = [
        'entry_time' => 'datetime',
        'exit_time' => 'datetime',
    ];

    public function visitor(): BelongsTo
    {
        return $this->belongsTo(Visitor::class);
    }

    public function logs(): HasMany
    {
        return $this->hasMany(VisitorLog::class);
    }
}
