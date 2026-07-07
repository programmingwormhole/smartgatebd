<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentGateway extends Model
{
    protected $fillable = [
        'building_id', 'name', 'account_type', 'account_number', 'notes', 'required_fields', 'is_active'
    ];

    protected $casts = [
        'required_fields' => 'array',
        'is_active' => 'boolean'
    ];

    public function building(): BelongsTo
    {
        return $this->belongsTo(Building::class);
    }
}
