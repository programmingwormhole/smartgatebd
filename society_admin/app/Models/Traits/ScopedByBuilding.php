<?php

namespace App\Models\Traits;

use App\Models\Scopes\BuildingScope;
use Illuminate\Support\Facades\Auth;

trait ScopedByBuilding
{
    protected static function bootScopedByBuilding()
    {
        static::addGlobalScope(new BuildingScope);
        
        static::creating(function ($model) {
            if (Auth::check() && Auth::user()->role !== 'superadmin' && Auth::user()->building_id) {
                // Only auto-assign if the table actually has building_id
                $fillable = $model->getFillable();
                if (in_array('building_id', $fillable) && empty($model->building_id)) {
                    $model->building_id = Auth::user()->building_id;
                }
            }
        });
    }
}
