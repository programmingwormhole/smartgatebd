<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Pet extends Model
{
    protected $fillable = ['resident_id', 'name', 'type', 'breed'];

    public function resident(): BelongsTo
    {
        return $this->belongsTo(Resident::class);
    }
}
