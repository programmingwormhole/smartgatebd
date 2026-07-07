<?php

namespace App\Models;

use App\Models\Traits\ScopedByBuilding;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Bill extends Model
{
    use HasFactory, ScopedByBuilding;

    protected $fillable = ['flat_id', 'type', 'amount', 'due_date', 'status', 'month_year', 'description'];
    
    protected $casts = [
        'due_date' => 'date',
    ];

    public function flat()
    {
        return $this->belongsTo(Flat::class);
    }

    public function payments()
    {
        return $this->hasMany(BillPayment::class);
    }
}
