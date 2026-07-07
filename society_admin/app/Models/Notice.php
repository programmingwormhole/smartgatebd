<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Notice extends Model
{
    protected $fillable = ['building_id', 'title', 'content', 'created_by_admin_id'];

    public function building(): BelongsTo
    {
        return $this->belongsTo(Building::class);
    }
}
