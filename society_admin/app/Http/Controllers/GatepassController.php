<?php

namespace App\Http\Controllers;

use App\Models\Gatepass;
use App\Models\VisitorLog;
use Illuminate\Http\Request;

class GatepassController extends Controller
{
    public function verify(Request $request)
    {
        $request->validate([
            'code' => 'required|string'
        ]);

        $gatepass = Gatepass::where('gatepass_code', $request->code)
            ->orWhere('entry_code', $request->code)
            ->with('visitor.flat')
            ->first();

        if (!$gatepass) {
            return response()->json(['message' => 'Invalid Gatepass'], 404);
        }

        return response()->json($gatepass);
    }

    public function logsStore(Request $request)
    {
        $data = $request->validate([
            'gatepass_id' => 'required|exists:gatepasses,id',
            'guard_id' => 'required|exists:guards,id',
            'action' => 'required|in:entry,exit'
        ]);

        $log = VisitorLog::create($data);

        // Update gatepass entry/exit time and visitor status
        $gatepass = Gatepass::find($data['gatepass_id']);
        if ($data['action'] === 'entry' && !$gatepass->entry_time) {
            if (($gatepass->visitor?->status ?? null) !== 'approved') {
                return response()->json(['message' => 'Visitor must be approved before entry can be confirmed'], 422);
            }
            $gatepass->update(['entry_time' => now()]);
            $gatepass->visitor?->update(['status' => 'inside']);
        } elseif ($data['action'] === 'exit' && !$gatepass->exit_time) {
            $gatepass->update(['exit_time' => now()]);
            $gatepass->visitor?->update(['status' => 'exited']);
        }

        return response()->json($log, 201);
    }

    public function logsIndex(Request $request)
    {
        $request->validate([
            'guard_id' => 'required|exists:guards,id'
        ]);

        $logs = VisitorLog::where('guard_id', $request->guard_id)->with('gatepass.visitor')->get();
        return response()->json($logs);
    }
}
