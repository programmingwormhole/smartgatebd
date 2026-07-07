<?php

namespace App\Models;


use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;

class User extends Authenticatable implements FilamentUser
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable, \App\Models\Traits\ScopedByBuilding;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'phone',
        'role',
        'password',
        'otp_code',
        'otp_expires_at',
        'building_id',
        'profile_picture',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'otp_code',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'otp_expires_at' => 'datetime',
        ];
    }

    public function managedBuildings()
    {
        return $this->belongsToMany(Building::class, 'building_user', 'user_id', 'building_id');
    }

    public function resident()
    {
        return $this->hasOne(Resident::class);
    }

    public function guardProfile()
    {
        return $this->hasOne(Guard::class);
    }

    public function fcmTokens(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(FcmToken::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    public function building()
    {
        return $this->belongsTo(Building::class);
    }

    public function canAccessPanel(Panel $panel): bool
    {
        return match($panel->getId()) {
            'admin' => $this->role === 'admin',
            'resident' => $this->role === 'resident',
            'guard' => $this->role === 'guard',
            default => false,
        };
    }
}
