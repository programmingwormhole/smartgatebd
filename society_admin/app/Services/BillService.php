<?php

namespace App\Services;

use App\Models\Bill;
use App\Models\Building;
use App\Models\Flat;

class BillService
{
    public function createBill(array $data)
    {
        return Bill::create($data);
    }

    public function getBuildingBills(Building $building)
    {
        return Bill::whereHas('flat.floor.block.building', function($q) use ($building) {
            $q->where('id', $building->id);
        })->with('flat')->get();
    }
    
    public function getFlatBills(Flat $flat)
    {
        return $flat->bills()->with(['payments.gateway'])->orderBy('created_at', 'desc')->get();
    }
}
