<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

class Building extends Model
{
    protected $fillable = ['name', 'address', 'admin_id'];

    public function admins(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'building_user', 'building_id', 'user_id');
    }

    public function blocks(): HasMany
    {
        return $this->hasMany(Block::class);
    }

    public function amenities(): HasMany
    {
        return $this->hasMany(Amenity::class);
    }

    public function guards(): HasMany
    {
        return $this->hasMany(Guard::class);
    }

    public function notices(): HasMany
    {
        return $this->hasMany(Notice::class);
    }

    public function services(): HasMany
    {
        return $this->hasMany(Service::class);
    }
}
