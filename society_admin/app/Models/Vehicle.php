<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;

class Vehicle extends Model
{
    protected $fillable = [
        'resident_id',
        'model',
        'color',
        'plate_number',
        'type',
    ];

    public function resident()
    {
        return $this->belongsTo(Resident::class);
    }
}
