<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use App\Models\Traits\ScopedByBuilding;

class Visitor extends Model
{
    use ScopedByBuilding;

    protected $fillable = [
        'flat_id', 'type', 'name', 'phone', 'vehicle_no',
        'company_name', 'purpose', 'from_date', 'to_date',
        'status', 'created_by_resident_id', 'reject_reason'
    ];

    protected $casts = [
        'from_date' => 'datetime',
        'to_date' => 'datetime',
    ];

    public function flat(): BelongsTo
    {
        return $this->belongsTo(Flat::class);
    }

    public function resident(): BelongsTo
    {
        return $this->belongsTo(Resident::class, 'created_by_resident_id');
    }

    public function gatepass(): HasOne
    {
        return $this->hasOne(Gatepass::class);
    }
}
