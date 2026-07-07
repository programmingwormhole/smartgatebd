<?php

namespace App\Models\Scopes;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Scope;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;

class BuildingScope implements Scope
{
    public function apply(Builder $builder, Model $model)
    {
        if (Auth::check() && Auth::user()->role !== 'superadmin' && Auth::user()->building_id) {
            $buildingId = Auth::user()->building_id;
            
            $table = $model->getTable();

            // Models with direct building_id
            if (Schema::hasColumn($table, 'building_id')) {
                $builder->where($table . '.building_id', $buildingId);
            } 
            // Models associated via flats
            elseif (in_array($table, ['visitors', 'bills'])) {
                $builder->whereHas('flat.floor.block', function ($q) use ($buildingId) {
                    $q->where('building_id', $buildingId);
                });
            }
            // Models associated via residents
            elseif (in_array($table, ['complaints'])) {
                $builder->whereHas('resident.user', function ($q) use ($buildingId) {
                    $q->where('building_id', $buildingId);
                });
            }
            // Flats
            elseif ($table === 'flats') {
                $builder->whereHas('floor.block', function ($q) use ($buildingId) {
                    $q->where('building_id', $buildingId);
                });
            }
            // Floors
            elseif ($table === 'floors') {
                $builder->whereHas('block', function ($q) use ($buildingId) {
                    $q->where('building_id', $buildingId);
                });
            }
        }
    }
}
