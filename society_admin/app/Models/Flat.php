<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Models\Traits\ScopedByBuilding;

class Flat extends Model
{
    use ScopedByBuilding;

    protected $fillable = ['floor_id', 'flat_number'];

    public function floor(): BelongsTo
    {
        return $this->belongsTo(Floor::class);
    }

    public function residents(): HasMany
    {
        return $this->hasMany(Resident::class);
    }

    public function bills(): HasMany
    {
        return $this->hasMany(Bill::class);
    }
}
