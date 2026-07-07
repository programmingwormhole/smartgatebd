<?php

namespace App\Http\Controllers;

use App\Models\Resident;
use Illuminate\Http\Request;

class DailyHelpController extends Controller
{
    public function index(Resident $resident = null)
    {
        $resident = $resident ?? auth()->user()->resident;
        if (!$resident) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }
        return response()->json([
            'daily_helps' => $resident->dailyHelps()->latest()->get()
        ]);
    }

    public function store(Request $request, Resident $resident = null)
    {
        $resident = $resident ?? auth()->user()->resident;
        if (!$resident) {
            return response()->json(['message' => 'Resident profile not found'], 404);
        }

        if (!$request->has('category') && $request->has('role')) {
            $request->merge(['category' => strtolower($request->role)]);
        }

        $allowedCategories = ['maid', 'cook', 'driver', 'gardener', 'nanny', 'security', 'milkman', 'laundry', 'tutor', 'cleaner', 'other'];
        if (!in_array($request->category, $allowedCategories)) {
            $request->merge(['category' => 'other']);
        }

        $data = $request->validate([
            'category' => 'required|string', // make it more flexible
            'name' => 'required|string',
            'phone' => 'nullable|string',
            'gatepass_enabled' => 'boolean'
        ]);

        if ($data['gatepass_enabled'] ?? true) {
            $data['entry_code'] = rand(100000, 999999);
            $data['qr_code'] = "qrcodes/staff_" . rand(1000, 9999) . ".png";
        }

        $help = $resident->dailyHelps()->create($data);
        return response()->json($help, 201);
    }

    public function update(Request $request, \App\Models\DailyHelp $dailyHelp)
    {
        $authResidentId = auth()->user()?->resident?->id;
        if ($authResidentId && $dailyHelp->resident_id !== $authResidentId) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $data = $request->validate([
            'category' => 'sometimes|string',
            'name' => 'sometimes|string',
            'phone' => 'nullable|string',
            'gatepass_enabled' => 'sometimes|boolean',
        ]);

        if (array_key_exists('gatepass_enabled', $data)) {
            if ($data['gatepass_enabled']) {
                if (empty($dailyHelp->entry_code)) {
                    $data['entry_code'] = (string) rand(100000, 999999);
                    $data['qr_code'] = 'qrcodes/staff_' . rand(1000, 9999) . '.png';
                }
            } else {
                $data['entry_code'] = null;
                $data['qr_code'] = null;
            }
        }

        $dailyHelp->update($data);

        return response()->json($dailyHelp);
    }
}
