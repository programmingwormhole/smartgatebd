<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Models\Traits\ScopedByBuilding;

class Floor extends Model
{
    use ScopedByBuilding;

    protected $fillable = ['block_id', 'floor_number'];

    public function block(): BelongsTo
    {
        return $this->belongsTo(Block::class);
    }

    public function flats(): HasMany
    {
        return $this->hasMany(Flat::class);
    }
}
