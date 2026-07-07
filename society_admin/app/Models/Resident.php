<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Models\Traits\ScopedByBuilding;

class Resident extends Model
{
    use ScopedByBuilding;

    protected $fillable = ['user_id', 'flat_id', 'role', 'monthly_maintenance_fee', 'rent', 'bill_generate_day'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function flat(): BelongsTo
    {
        return $this->belongsTo(Flat::class);
    }

    public function visitors(): HasMany
    {
        return $this->hasMany(Visitor::class, 'created_by_resident_id');
    }

    public function pets(): HasMany
    {
        return $this->hasMany(Pet::class);
    }

    public function families(): HasMany
    {
        return $this->hasMany(Family::class);
    }

    public function dailyHelps(): HasMany
    {
        return $this->hasMany(DailyHelp::class);
    }

    public function vehicles(): HasMany
    {
        return $this->hasMany(Vehicle::class);
    }

    public function complaints(): HasMany
    {
        return $this->hasMany(Complaint::class);
    }
}
