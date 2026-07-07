<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Models\Traits\ScopedByBuilding;

class Block extends Model
{
    use ScopedByBuilding;

    protected $fillable = ['building_id', 'name'];

    public function building(): BelongsTo
    {
        return $this->belongsTo(Building::class);
    }

    public function floors(): HasMany
    {
        return $this->hasMany(Floor::class);
    }
}
