<?php

namespace App\Http\Controllers;

use App\Models\Building;
use App\Models\Service;
use Illuminate\Http\Request;

class ServiceController extends Controller
{
    public function index(Building $building)
    {
        return response()->json([
            'services' => $building->services
        ]);
    }

    public function store(Request $request, Building $building)
    {
        $data = $request->validate([
            'category' => 'required|string',
            'name' => 'required|string',
        ]);

        $service = $building->services()->create($data);
        return response()->json(['service' => $service], 201);
    }

    public function update(Request $request, Service $service)
    {
        $data = $request->validate([
            'category' => 'required|string',
            'name' => 'required|string',
        ]);

        $service->update($data);
        return response()->json(['service' => $service]);
    }

    public function destroy(Service $service)
    {
        $service->delete();
        return response()->json(['message' => 'Service deleted successfully'], 204);
    }
}
