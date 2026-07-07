<?php

namespace App\Http\Controllers;

use App\Models\Building;
use App\Models\Flat;
use App\Services\BillService;
use Illuminate\Http\Request;

class BillController extends Controller
{
    protected $billService;

    public function __construct(BillService $billService)
    {
        $this->billService = $billService;
    }

    public function store(Request $request, Building $building)
    {
        $data = $request->validate([
            'flat_id' => 'required|exists:flats,id',
            'type' => 'required|in:rent,maintenance,custom',
            'amount' => 'required|numeric',
            'due_date' => 'required|date'
        ]);

        $bill = $this->billService->createBill($data);
        return response()->json($bill, 201);
    }

    public function indexByBuilding(Building $building)
    {
        return response()->json($this->billService->getBuildingBills($building));
    }

    public function indexByFlat(Flat $flat)
    {
        return response()->json($this->billService->getFlatBills($flat));
    }

    public function indexMy()
    {
        $resident = auth()->user()->resident;
        if (!$resident || !$resident->flat_id) {
            return response()->json(['message' => 'Resident flat mapping not found'], 404);
        }
        return response()->json([
            'bills' => $this->billService->getFlatBills($resident->flat)
        ]);
    }
}
