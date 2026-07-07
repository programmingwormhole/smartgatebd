<?php

namespace App\Http\Controllers;

use App\Models\VisitorActivityLog;
use App\Models\Guard;
use App\Models\Resident;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ActivityLogController extends Controller
{
    /**
     * Get resident's visitor logs
     * Residents can only see logs for visitors to their flat
     */
    public function getResidentLogs(Request $request)
    {
        $data = $request->validate([
            'visitor_type' => 'nullable|in:temporary,family,daily_help,pre_approved',
            'action' => 'nullable|in:entry,exit,created,approved,rejected,verified',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date|after_or_equal:from_date',
            'per_page' => 'nullable|integer|min:10|max:100',
        ]);

        $user = Auth::user();
        $resident = Resident::where('user_id', $user->id)->firstOrFail();

        $query = VisitorActivityLog::with(['guardUser.user', 'resident.user', 'visitor', 'gatepass'])
            ->byResident($resident->id);

        // Filter by visitor type
        if (!empty($data['visitor_type'])) {
            $query->byVisitorType($data['visitor_type']);
        }

        // Filter by action
        if (!empty($data['action'])) {
            $query->byAction($data['action']);
        }

        // Filter by date range
        if (!empty($data['from_date']) && !empty($data['to_date'])) {
            $query->byDateRange(
                \Carbon\Carbon::parse($data['from_date'])->startOfDay(),
                \Carbon\Carbon::parse($data['to_date'])->endOfDay()
            );
        }

        $logs = $query->latest()->paginate($data['per_page'] ?? 20);

        return response()->json($logs);
    }

    /**
     * Get admin's visitor logs for their building
     * Admins can see all logs for their building with comprehensive filtering
     */
    public function getAdminLogs(Request $request)
    {
        $data = $request->validate([
            'visitor_type' => 'nullable|in:temporary,family,daily_help,pre_approved',
            'action' => 'nullable|in:entry,exit,created,approved,rejected,verified',
            'guard_id' => 'nullable|integer|exists:guards,id',
            'resident_id' => 'nullable|integer|exists:residents,id',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date|after_or_equal:from_date',
            'search' => 'nullable|string|max:100',
            'per_page' => 'nullable|integer|min:10|max:100',
        ]);

        $user = Auth::user();
        $buildingId = $user->building_id;

        if (!$buildingId) {
            return response()->json(['message' => 'No building assigned'], 403);
        }

        $query = VisitorActivityLog::with(['guardUser.user', 'resident.user', 'visitor', 'gatepass'])
            ->byBuilding($buildingId);

        // Filter by visitor type
        if (!empty($data['visitor_type'])) {
            $query->byVisitorType($data['visitor_type']);
        }

        // Filter by action
        if (!empty($data['action'])) {
            $query->byAction($data['action']);
        }

        // Filter by guard
        if (!empty($data['guard_id'])) {
            $query->byGuard($data['guard_id']);
        }

        // Filter by resident
        if (!empty($data['resident_id'])) {
            $query->byResident($data['resident_id']);
        }

        // Filter by date range
        if (!empty($data['from_date']) && !empty($data['to_date'])) {
            $query->byDateRange(
                \Carbon\Carbon::parse($data['from_date'])->startOfDay(),
                \Carbon\Carbon::parse($data['to_date'])->endOfDay()
            );
        }

        // Search by visitor name or phone
        if (!empty($data['search'])) {
            $search = $data['search'];
            $query->where(function ($q) use ($search) {
                $q->where('visitor_name', 'like', "%{$search}%")
                  ->orWhere('visitor_phone', 'like', "%{$search}%")
                  ->orWhere('entry_code', 'like', "%{$search}%");
            });
        }

        $logs = $query->latest()->paginate($data['per_page'] ?? 20);

        return response()->json($logs);
    }

    /**
     * Get guard's activity logs
     * Guards can see logs of their activities with filtering
     */
    public function getGuardLogs(Request $request)
    {
        $data = $request->validate([
            'visitor_type' => 'nullable|in:temporary,family,daily_help,pre_approved',
            'action' => 'nullable|in:entry,exit,created,approved,rejected,verified',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date|after_or_equal:from_date',
            'search' => 'nullable|string|max:100',
            'per_page' => 'nullable|integer|min:10|max:100',
        ]);

        $user = Auth::user();
        $guard = Guard::where('user_id', $user->id)->firstOrFail();

        $query = VisitorActivityLog::with(['guardUser.user', 'resident.user', 'visitor', 'gatepass'])
            ->byGuard($guard->id);

        // Filter by visitor type
        if (!empty($data['visitor_type'])) {
            $query->byVisitorType($data['visitor_type']);
        }

        // Filter by action
        if (!empty($data['action'])) {
            $query->byAction($data['action']);
        }

        // Filter by date range
        if (!empty($data['from_date']) && !empty($data['to_date'])) {
            $query->byDateRange(
                \Carbon\Carbon::parse($data['from_date'])->startOfDay(),
                \Carbon\Carbon::parse($data['to_date'])->endOfDay()
            );
        }

        // Search by visitor name or phone
        if (!empty($data['search'])) {
            $search = $data['search'];
            $query->where(function ($q) use ($search) {
                $q->where('visitor_name', 'like', "%{$search}%")
                  ->orWhere('visitor_phone', 'like', "%{$search}%")
                  ->orWhere('entry_code', 'like', "%{$search}%");
            });
        }

        $logs = $query->latest()->paginate($data['per_page'] ?? 20);

        return response()->json($logs);
    }

    /**
     * Get activity statistics for admin dashboard
     */
    public function getStatistics(Request $request)
    {
        $user = Auth::user();
        $buildingId = $user->building_id;

        if (!$buildingId) {
            return response()->json(['message' => 'No building assigned'], 403);
        }

        $today = \Carbon\Carbon::today();
        $thisWeek = \Carbon\Carbon::now()->startOfWeek();
        $thisMonth = \Carbon\Carbon::now()->startOfMonth();

        $stats = [
            'today' => [
                'entries' => VisitorActivityLog::byBuilding($buildingId)
                    ->where('action', 'entry')
                    ->whereDate('activity_date', $today)
                    ->count(),
                'exits' => VisitorActivityLog::byBuilding($buildingId)
                    ->where('action', 'exit')
                    ->whereDate('activity_date', $today)
                    ->count(),
            ],
            'this_week' => [
                'entries' => VisitorActivityLog::byBuilding($buildingId)
                    ->where('action', 'entry')
                    ->where('activity_date', '>=', $thisWeek)
                    ->count(),
                'exits' => VisitorActivityLog::byBuilding($buildingId)
                    ->where('action', 'exit')
                    ->where('activity_date', '>=', $thisWeek)
                    ->count(),
            ],
            'this_month' => [
                'entries' => VisitorActivityLog::byBuilding($buildingId)
                    ->where('action', 'entry')
                    ->where('activity_date', '>=', $thisMonth)
                    ->count(),
                'exits' => VisitorActivityLog::byBuilding($buildingId)
                    ->where('action', 'exit')
                    ->where('activity_date', '>=', $thisMonth)
                    ->count(),
            ],
            'by_type' => [
                'temporary' => VisitorActivityLog::byBuilding($buildingId)
                    ->byVisitorType('temporary')
                    ->count(),
                'family' => VisitorActivityLog::byBuilding($buildingId)
                    ->byVisitorType('family')
                    ->count(),
                'daily_help' => VisitorActivityLog::byBuilding($buildingId)
                    ->byVisitorType('daily_help')
                    ->count(),
                'pre_approved' => VisitorActivityLog::byBuilding($buildingId)
                    ->byVisitorType('pre_approved')
                    ->count(),
            ],
        ];

        return response()->json($stats);
    }

    /**
     * Export logs as CSV
     */
    public function exportLogs(Request $request)
    {
        $data = $request->validate([
            'visitor_type' => 'nullable|in:temporary,family,daily_help,pre_approved',
            'action' => 'nullable|in:entry,exit,created,approved,rejected,verified',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date|after_or_equal:from_date',
        ]);

        $user = Auth::user();
        $buildingId = $user->building_id;

        if (!$buildingId) {
            return response()->json(['message' => 'No building assigned'], 403);
        }

        $query = VisitorActivityLog::with(['guardUser.user', 'resident.user'])
            ->byBuilding($buildingId);

        if (!empty($data['visitor_type'])) {
            $query->byVisitorType($data['visitor_type']);
        }

        if (!empty($data['action'])) {
            $query->byAction($data['action']);
        }

        if (!empty($data['from_date']) && !empty($data['to_date'])) {
            $query->byDateRange(
                \Carbon\Carbon::parse($data['from_date'])->startOfDay(),
                \Carbon\Carbon::parse($data['to_date'])->endOfDay()
            );
        }

        $logs = $query->get();

        $csv = "Visitor Name,Phone,Type,Action,Entry Code,Purpose,Guard,Resident,Date\n";
        foreach ($logs as $log) {
            $guardName = $log->guard?->user?->name ?? 'N/A';
            $residentName = $log->resident?->user?->name ?? 'N/A';
            $csv .= "\"{$log->visitor_name}\",\"{$log->visitor_phone}\",\"{$log->getVisitorTypeLabel()}\",\"{$log->getActionLabel()}\",\"{$log->entry_code}\",\"{$log->purpose}\",\"{$guardName}\",\"{$residentName}\",\"{$log->activity_date->format('Y-m-d H:i:s')}\"\n";
        }

        return response()->streamDownload(function () use ($csv) {
            echo $csv;
        }, 'visitor_logs.csv', [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="visitor_logs.csv"',
        ]);
    }
}
