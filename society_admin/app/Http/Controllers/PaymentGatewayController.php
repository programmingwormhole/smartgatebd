<?php

namespace App\Http\Controllers;

use App\Models\Building;
use App\Models\PaymentGateway;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PaymentGatewayController extends Controller
{
    /**
     * Get the building for the authenticated user.
     * Tries direct building_id first, then checks managedBuildings pivot table.
     */
    private function getAuthenticatedUserBuilding()
    {
        $user = Auth::user();

        if (!$user) {
            return null;
        }

        $building = $user->building;
        if ($building) {
            return $building;
        }

        $managedBuildings = $user->managedBuildings;
        if ($managedBuildings && $managedBuildings->count() > 0) {
            return $managedBuildings->first();
        }

        return null;
    }

    // For users - get only active gateways
    public function indexByBuilding(Building $building)
    {
        $gateways = PaymentGateway::where('building_id', $building->id)
            ->where('is_active', true)
            ->get();

        return response()->json(['gateways' => $gateways]);
    }

    // For admins - get all gateways (active and inactive)
    public function index(Request $request)
    {
        $building = $this->getAuthenticatedUserBuilding();

        if (!$building) {
            return response()->json(['message' => 'No building found'], 404);
        }

        $gateways = PaymentGateway::where('building_id', $building->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'gateways' => $gateways,
            'total' => $gateways->count(),
        ]);
    }

    // Create payment gateway
    public function store(Request $request)
    {
        $building = $this->getAuthenticatedUserBuilding();

        if (!$building) {
            return response()->json(['message' => 'No building found'], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'account_type' => ['required'],
            'account_number' => 'required|string|max:255',
            'notes' => 'nullable|string|max:2000',
            'required_fields' => 'array|nullable',
            'required_fields.*' => 'string',
            'is_active' => 'boolean',
        ]);

        $gateway = PaymentGateway::create(array_merge(
            $validated,
            ['building_id' => $building->id]
        ));

        return response()->json([
            'message' => 'Payment gateway created successfully',
            'gateway' => $gateway,
        ], 201);
    }

    // Update payment gateway
    public function update(Request $request, $gateway)
    {

        $building = $this->getAuthenticatedUserBuilding();

        if (!$building) {
            return response()->json(['message' => 'No building found'], 404);
        }

        $gateway = PaymentGateway::find($gateway);


        if ($gateway->building_id !== $building->id) {
            return response()->json([
                'message' => 'Unauthorized',
                'details' => "Gateway belongs to building {$gateway->building_id}, you belong to building {$building->id}"
            ], 403);
        }

        $validated = $request->validate([
            'name' => 'string|max:255',
            'account_type' => ['required'],
            'account_number' => 'string|max:255',
            'notes' => 'nullable|string|max:2000',
            'required_fields' => 'array|nullable',
            'required_fields.*' => 'string',
            'is_active' => 'boolean',
        ]);

        $gateway->update($validated);

        return response()->json([
            'message' => 'Payment gateway updated successfully',
            'gateway' => $gateway,
        ]);
    }

    // Delete payment gateway
    public function destroy(PaymentGateway $gateway)
    {
        $building = $this->getAuthenticatedUserBuilding();

        if (!$building) {
            return response()->json(['message' => 'No building found'], 404);
        }

        if ($gateway->building_id !== $building->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $gateway->delete();

        return response()->json(['message' => 'Payment gateway deleted successfully']);
    }
}
