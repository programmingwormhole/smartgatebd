<?php

namespace App\Http\Controllers;

use App\Models\Resident;
use App\Models\Family;
use Illuminate\Http\Request;

class FamilyController extends Controller
{
    public function index(Resident $resident = null)
    {
        $resident = $resident ?? auth()->user()->resident;
        if (!$resident) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }
        return response()->json($resident->families);
    }

    public function store(Request $request, Resident $resident = null)
    {
        $resident = $resident ?? auth()->user()->resident;
        if (!$resident) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }

        $data = $request->validate([
            'name' => 'required|string',
            'relation' => 'required|string',
            'phone' => 'nullable|string',
            'gatepass_enabled' => 'boolean'
        ]);

        if ($data['gatepass_enabled'] ?? true) {
            $data['entry_code'] = rand(100000, 999999);
            $data['qr_code'] = "qrcodes/family_" . rand(1000, 9999) . ".png";
        }

        $family = $resident->families()->create($data);
        return response()->json($family, 201);
    }

    public function update(Request $request, Family $family)
    {
        $authResidentId = auth()->user()?->resident?->id;
        if ($authResidentId && $family->resident_id !== $authResidentId) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $data = $request->validate([
            'name' => 'string',
            'relation' => 'string',
            'phone' => 'nullable|string',
            'gatepass_enabled' => 'boolean'
        ]);

        if (array_key_exists('gatepass_enabled', $data)) {
            if ($data['gatepass_enabled']) {
                if (empty($family->entry_code)) {
                    $data['entry_code'] = (string) rand(100000, 999999);
                    $data['qr_code'] = 'qrcodes/family_' . rand(1000, 9999) . '.png';
                }
            } else {
                $data['entry_code'] = null;
                $data['qr_code'] = null;
            }
        }

        $family->update($data);
        return response()->json($family);
    }

    public function destroy(Family $family)
    {
        $authResidentId = auth()->user()?->resident?->id;
        if ($authResidentId && $family->resident_id !== $authResidentId) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $family->delete();
        return response()->json(null, 204);
    }
}
