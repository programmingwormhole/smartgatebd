<?php

namespace App\Helpers;

use App\Models\User;

class NotificationHelper
{
    /**
     * Get all admin users for a specific building
     */
    public static function getBuildingAdmins($buildingId)
    {
        return User::query()
            ->where(function ($query) use ($buildingId) {
                $query
                    ->where(function ($q) use ($buildingId) {
                        $q->where('role', 'admin')
                            ->where('building_id', $buildingId);
                    })
                    ->orWhere(function ($q) use ($buildingId) {
                        $q->whereHas('resident', function ($residentQuery) {
                            $residentQuery->where('role', 'admin');
                        })->whereHas('resident.flat.floor.block', function ($blockQuery) use ($buildingId) {
                            $blockQuery->where('building_id', $buildingId);
                        });
                    });
            })
            ->select('users.*')
            ->distinct()
            ->get();
    }

    /**
     * Get all users in a building (residents and admins)
     */
    public static function getBuildingUsers($buildingId)
    {
        return User::query()
            ->where(function ($query) use ($buildingId) {
                $query
                    ->where('building_id', $buildingId)
                    ->orWhereHas('guardProfile', function ($guardQuery) use ($buildingId) {
                        $guardQuery->where('building_id', $buildingId);
                    })
                    ->orWhereHas('resident.flat.floor.block', function ($blockQuery) use ($buildingId) {
                        $blockQuery->where('building_id', $buildingId);
                    });
            })
            ->select('users.*')
            ->distinct()
            ->get();
    }
}
