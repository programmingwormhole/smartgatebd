<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Models\Traits\ScopedByBuilding;

class Complaint extends Model
{
    use ScopedByBuilding;

    protected $fillable = ['resident_id', 'title', 'category', 'description', 'status'];

    public function resident(): BelongsTo
    {
        return $this->belongsTo(Resident::class);
    }
}
