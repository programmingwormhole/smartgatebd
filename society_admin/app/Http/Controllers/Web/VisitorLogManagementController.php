<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Building;
use App\Models\Guard;
use App\Models\Resident;
use App\Models\VisitorActivityLog;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\Request;

class VisitorLogManagementController extends Controller
{
    public function index(Request $request)
    {
        abort_unless($request->user()?->role === 'superadmin', 403);

        [$query, $filters] = $this->buildFilteredQuery($request);

        $logs = (clone $query)
            ->with([
                'building:id,name',
                'guardUser.user:id,name',
                'resident.user:id,name',
                'gatepass:id,entry_code',
            ])
            ->orderByDesc('activity_date')
            ->paginate($filters['per_page'])
            ->withQueryString();

        $stats = [
            'total_logs' => (clone $query)->count(),
            'entries' => (clone $query)->where('action', 'entry')->count(),
            'exits' => (clone $query)->where('action', 'exit')->count(),
            'unique_visitors' => (clone $query)->distinct('visitor_phone')->count('visitor_phone'),
        ];

        $buildings = Building::query()->orderBy('name')->get(['id', 'name']);

        $guards = Guard::query()
            ->with('user:id,name')
            ->when($filters['building_id'], fn ($q) => $q->where('building_id', $filters['building_id']))
            ->orderByDesc('id')
            ->limit(300)
            ->get(['id', 'building_id', 'user_id']);

        $residents = Resident::query()
            ->with(['user:id,name', 'flat:id,flat_number,floor_id', 'flat.floor:id,floor_number,block_id', 'flat.floor.block:id,name'])
            ->when($filters['building_id'], function ($q) use ($filters) {
                $q->whereHas('flat.floor.block', fn ($sub) => $sub->where('building_id', $filters['building_id']));
            })
            ->orderByDesc('id')
            ->limit(400)
            ->get(['id', 'user_id', 'flat_id']);

        return view('visitor_logs.index', [
            'logs' => $logs,
            'stats' => $stats,
            'filters' => $filters,
            'buildings' => $buildings,
            'guards' => $guards,
            'residents' => $residents,
            'visitorTypes' => $this->visitorTypes(),
            'actions' => $this->actions(),
            'rangeOptions' => $this->rangeOptions(),
        ]);
    }

    public function exportPdf(Request $request)
    {
        abort_unless($request->user()?->role === 'superadmin', 403);

        [$query, $filters] = $this->buildFilteredQuery($request);

        $logs = (clone $query)
            ->with([
                'building:id,name',
                'guardUser.user:id,name',
                'resident.user:id,name',
                'gatepass:id,entry_code',
            ])
            ->orderByDesc('activity_date')
            ->limit(5000)
            ->get();

        $stats = [
            'total_logs' => $logs->count(),
            'entries' => $logs->where('action', 'entry')->count(),
            'exits' => $logs->where('action', 'exit')->count(),
            'unique_visitors' => $logs->pluck('visitor_phone')->filter()->unique()->count(),
        ];

        $pdf = Pdf::loadView('visitor_logs.report_pdf', [
            'logs' => $logs,
            'stats' => $stats,
            'filters' => $filters,
            'generatedAt' => now(),
        ])->setPaper('a4', 'landscape');

        return $pdf->download('visitor-log-report-' . now()->format('Ymd-His') . '.pdf');
    }

    /**
     * @return array{0: Builder, 1: array<string,mixed>}
     */
    private function buildFilteredQuery(Request $request): array
    {
        $validated = $request->validate([
            'building_id' => 'nullable|integer|exists:buildings,id',
            'guard_id' => 'nullable|integer|exists:guards,id',
            'resident_id' => 'nullable|integer|exists:residents,id',
            'visitor_type' => 'nullable|in:temporary,family,daily_help,pre_approved',
            'action' => 'nullable|in:entry,exit,created,approved,rejected,verified',
            'entry_code' => 'nullable|string|max:50',
            'search' => 'nullable|string|max:120',
            'from_date' => 'nullable|date',
            'to_date' => 'nullable|date|after_or_equal:from_date',
            'date_range' => 'nullable|in:today,last_7_days,last_30_days,this_month,last_month,custom',
            'per_page' => 'nullable|integer|min:10|max:100',
        ]);

        $filters = [
            'building_id' => $validated['building_id'] ?? null,
            'guard_id' => $validated['guard_id'] ?? null,
            'resident_id' => $validated['resident_id'] ?? null,
            'visitor_type' => $validated['visitor_type'] ?? null,
            'action' => $validated['action'] ?? null,
            'entry_code' => trim((string) ($validated['entry_code'] ?? '')),
            'search' => trim((string) ($validated['search'] ?? '')),
            'from_date' => $validated['from_date'] ?? null,
            'to_date' => $validated['to_date'] ?? null,
            'date_range' => $validated['date_range'] ?? 'last_30_days',
            'per_page' => (int) ($validated['per_page'] ?? 25),
        ];

        if ((! $filters['from_date'] || ! $filters['to_date']) && $filters['date_range'] !== 'custom') {
            [$fromDate, $toDate] = $this->resolveRange($filters['date_range']);
            $filters['from_date'] = $fromDate->toDateString();
            $filters['to_date'] = $toDate->toDateString();
        }

        $query = VisitorActivityLog::query();

        if ($filters['building_id']) {
            $query->where('building_id', $filters['building_id']);
        }

        if ($filters['guard_id']) {
            $query->where('guard_id', $filters['guard_id']);
        }

        if ($filters['resident_id']) {
            $query->where('resident_id', $filters['resident_id']);
        }

        if ($filters['visitor_type']) {
            $query->where('visitor_type', $filters['visitor_type']);
        }

        if ($filters['action']) {
            $query->where('action', $filters['action']);
        }

        if ($filters['entry_code'] !== '') {
            $query->where(function ($q) use ($filters) {
                $q->where('entry_code', 'like', '%' . $filters['entry_code'] . '%')
                    ->orWhereHas('gatepass', function ($sub) use ($filters) {
                        $sub->where('entry_code', 'like', '%' . $filters['entry_code'] . '%');
                    });
            });
        }

        if ($filters['search'] !== '') {
            $search = $filters['search'];
            $query->where(function ($q) use ($search) {
                $q->where('visitor_name', 'like', '%' . $search . '%')
                    ->orWhere('visitor_phone', 'like', '%' . $search . '%')
                    ->orWhere('entry_code', 'like', '%' . $search . '%')
                    ->orWhere('purpose', 'like', '%' . $search . '%')
                      ->orWhere('notes', 'like', '%' . $search . '%')
                      ->orWhereHas('gatepass', function ($sub) use ($search) {
                          $sub->where('entry_code', 'like', '%' . $search . '%');
                      });
            });
        }

        if ($filters['from_date'] && $filters['to_date']) {
            $query->whereBetween('activity_date', [
                Carbon::parse($filters['from_date'])->startOfDay(),
                Carbon::parse($filters['to_date'])->endOfDay(),
            ]);
        }

        return [$query, $filters];
    }

    private function resolveRange(string $range): array
    {
        return match ($range) {
            'today' => [now()->startOfDay(), now()->endOfDay()],
            'last_7_days' => [now()->subDays(6)->startOfDay(), now()->endOfDay()],
            'last_30_days' => [now()->subDays(29)->startOfDay(), now()->endOfDay()],
            'this_month' => [now()->startOfMonth(), now()->endOfMonth()],
            'last_month' => [now()->subMonthNoOverflow()->startOfMonth(), now()->subMonthNoOverflow()->endOfMonth()],
            default => [now()->subDays(29)->startOfDay(), now()->endOfDay()],
        };
    }

    private function visitorTypes(): array
    {
        return [
            'temporary' => 'Temporary Visitor',
            'family' => 'Family Member',
            'daily_help' => 'Daily Help',
            'pre_approved' => 'Pre-approved Visitor',
        ];
    }

    private function actions(): array
    {
        return [
            'entry' => 'Entry',
            'exit' => 'Exit',
            'created' => 'Created',
            'approved' => 'Approved',
            'rejected' => 'Rejected',
            'verified' => 'Verified',
        ];
    }

    private function rangeOptions(): array
    {
        return [
            'today' => 'Today',
            'last_7_days' => 'Last 7 Days',
            'last_30_days' => 'Last 30 Days',
            'this_month' => 'This Month',
            'last_month' => 'Last Month',
            'custom' => 'Custom Range',
        ];
    }
}
