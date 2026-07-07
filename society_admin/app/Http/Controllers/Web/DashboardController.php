<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\AmenityBooking;
use App\Models\Bill;
use App\Models\BillPayment;
use App\Models\Block;
use App\Models\Building;
use App\Models\Complaint;
use App\Models\Flat;
use App\Models\Floor;
use App\Models\Guard;
use App\Models\Notice;
use App\Models\Resident;
use App\Models\ServiceBooking;
use App\Models\Visitor;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $isSuperadmin = $user?->role === 'superadmin';

        $managedBuildingIds = $isSuperadmin
            ? collect()
            : $user->managedBuildings()->pluck('buildings.id');

        if (! $isSuperadmin && $managedBuildingIds->isEmpty() && ! empty($user?->building_id)) {
            $managedBuildingIds = collect([(int) $user->building_id]);
        }

        $filterByBuildingId = function ($query, string $column = 'building_id') use ($isSuperadmin, $managedBuildingIds) {
            if ($isSuperadmin) {
                return;
            }

            if ($managedBuildingIds->isEmpty()) {
                $query->whereRaw('1 = 0');

                return;
            }

            $query->whereIn($column, $managedBuildingIds->all());
        };

        $buildingsQuery = Building::query();
        $filterByBuildingId($buildingsQuery, 'id');

        $totalBuildings = (clone $buildingsQuery)->count();
        $totalBlocks = Block::query()
            ->when(! $isSuperadmin, function ($query) use ($managedBuildingIds) {
                if ($managedBuildingIds->isEmpty()) {
                    return $query->whereRaw('1 = 0');
                }

                return $query->whereIn('building_id', $managedBuildingIds->all());
            })
            ->count();
        $totalFloors = Floor::query()
            ->whereHas('block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->count();
        $totalFlats = Flat::query()
            ->whereHas('floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->count();
        $occupiedFlats = Flat::query()
            ->whereHas('residents')
            ->whereHas('floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->count();

        $totalResidents = Resident::query()
            ->whereHas('flat.floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->count();

        $guardsQuery = Guard::query();
        $filterByBuildingId($guardsQuery);
        $totalGuards = (clone $guardsQuery)->count();
        $onDutyGuards = (clone $guardsQuery)->where('status', 'on_duty')->count();
        $offDutyGuards = (clone $guardsQuery)->where('status', 'off_duty')->count();
        $leaveGuards = (clone $guardsQuery)->where('status', 'leave')->count();
        $inactiveGuards = (clone $guardsQuery)->where('status', 'inactive')->count();

        $openComplaints = Complaint::query()
            ->whereIn('status', ['open', 'in_progress'])
            ->whereHas('resident.flat.floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->count();

        $resolvedComplaintsThisMonth = Complaint::query()
            ->where('status', 'resolved')
            ->whereBetween('updated_at', [now()->startOfMonth(), now()->endOfMonth()])
            ->whereHas('resident.flat.floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->count();

        $pendingAmenityBookings = AmenityBooking::query()
            ->where('status', 'pending')
            ->whereHas('amenity', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->count();

        $pendingServiceBookings = ServiceBooking::query()
            ->where('status', 'pending')
            ->whereHas('service', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->count();

        $pendingRequests = $pendingAmenityBookings + $pendingServiceBookings;

        $monthlyCollected = BillPayment::query()
            ->where('status', 'approved')
            ->whereBetween('created_at', [now()->startOfMonth(), now()->endOfMonth()])
            ->whereHas('bill.flat.floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->sum('amount');

        $monthlyDue = Bill::query()
            ->whereBetween('due_date', [now()->startOfMonth(), now()->endOfMonth()])
            ->whereHas('flat.floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->sum('amount');

        $unpaidBills = Bill::query()
            ->whereIn('status', ['pending', 'unpaid', 'pending_for_approval'])
            ->whereHas('flat.floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->count();

        $collectionRate = $monthlyDue > 0
            ? round(($monthlyCollected / $monthlyDue) * 100, 1)
            : 0.0;

        $visitorsToday = Visitor::query()
            ->whereDate('created_at', today())
            ->whereHas('flat.floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->count();

        $visitorsInside = Visitor::query()
            ->where('status', 'inside')
            ->whereHas('flat.floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->count();

        $noticesThisMonth = Notice::query()
            ->whereBetween('created_at', [now()->startOfMonth(), now()->endOfMonth()])
            ->when(! $isSuperadmin, function ($query) use ($managedBuildingIds) {
                if ($managedBuildingIds->isEmpty()) {
                    return $query->whereRaw('1 = 0');
                }

                return $query->whereIn('building_id', $managedBuildingIds->all());
            })
            ->count();

        $occupancyRate = $totalFlats > 0
            ? round(($occupiedFlats / $totalFlats) * 100, 1)
            : 0.0;

        $trendMonths = collect(range(5, 0))
            ->map(fn (int $offset) => now()->copy()->startOfMonth()->subMonths($offset));

        $trendLabels = $trendMonths->map(fn (Carbon $month) => $month->format('M Y'))->values();

        $residentTrend = $trendMonths->map(function (Carbon $month) use ($filterByBuildingId) {
            return Resident::query()
                ->whereBetween('created_at', [$month->copy()->startOfMonth(), $month->copy()->endOfMonth()])
                ->whereHas('flat.floor.block', function ($query) use ($filterByBuildingId) {
                    $filterByBuildingId($query, 'building_id');
                })
                ->count();
        })->values();

        $guardTrend = $trendMonths->map(function (Carbon $month) use ($filterByBuildingId) {
            $query = Guard::query()->whereBetween('created_at', [$month->copy()->startOfMonth(), $month->copy()->endOfMonth()]);
            $filterByBuildingId($query);

            return $query->count();
        })->values();

        $revenueTrend = $trendMonths->map(function (Carbon $month) use ($filterByBuildingId) {
            return (float) BillPayment::query()
                ->where('status', 'approved')
                ->whereBetween('created_at', [$month->copy()->startOfMonth(), $month->copy()->endOfMonth()])
                ->whereHas('bill.flat.floor.block', function ($query) use ($filterByBuildingId) {
                    $filterByBuildingId($query, 'building_id');
                })
                ->sum('amount');
        })->values();

        $complaintStatusChart = [
            'open' => Complaint::query()
                ->where('status', 'open')
                ->whereHas('resident.flat.floor.block', function ($query) use ($filterByBuildingId) {
                    $filterByBuildingId($query, 'building_id');
                })->count(),
            'in_progress' => Complaint::query()
                ->where('status', 'in_progress')
                ->whereHas('resident.flat.floor.block', function ($query) use ($filterByBuildingId) {
                    $filterByBuildingId($query, 'building_id');
                })->count(),
            'resolved' => Complaint::query()
                ->where('status', 'resolved')
                ->whereHas('resident.flat.floor.block', function ($query) use ($filterByBuildingId) {
                    $filterByBuildingId($query, 'building_id');
                })->count(),
        ];

        $guardStatusChart = [
            'on_duty' => $onDutyGuards,
            'off_duty' => $offDutyGuards,
            'leave' => $leaveGuards,
            'inactive' => $inactiveGuards,
        ];

        $topBuildings = Building::query()
            ->select('buildings.id', 'buildings.name')
            ->selectRaw('COUNT(DISTINCT flats.id) as flats_count')
            ->selectRaw('COUNT(DISTINCT residents.id) as residents_count')
            ->leftJoin('blocks', 'blocks.building_id', '=', 'buildings.id')
            ->leftJoin('floors', 'floors.block_id', '=', 'blocks.id')
            ->leftJoin('flats', 'flats.floor_id', '=', 'floors.id')
            ->leftJoin('residents', 'residents.flat_id', '=', 'flats.id')
            ->when(! $isSuperadmin, function ($query) use ($managedBuildingIds) {
                if ($managedBuildingIds->isEmpty()) {
                    return $query->whereRaw('1 = 0');
                }

                return $query->whereIn('buildings.id', $managedBuildingIds->all());
            })
            ->groupBy('buildings.id', 'buildings.name')
            ->orderByDesc('residents_count')
            ->limit(6)
            ->get();

        $recentComplaints = Complaint::query()
            ->with(['resident.user:id,name'])
            ->whereHas('resident.flat.floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->latest()
            ->limit(5)
            ->get(['id', 'resident_id', 'title', 'status', 'created_at']);

        $recentPayments = BillPayment::query()
            ->with(['bill.flat.floor.block.building:id,name'])
            ->whereHas('bill.flat.floor.block', function ($query) use ($filterByBuildingId) {
                $filterByBuildingId($query, 'building_id');
            })
            ->where('status', 'approved')
            ->latest()
            ->limit(5)
            ->get(['id', 'bill_id', 'amount', 'method', 'created_at']);

        $kpis = [
            'total_buildings' => $totalBuildings,
            'total_blocks' => $totalBlocks,
            'total_floors' => $totalFloors,
            'total_flats' => $totalFlats,
            'occupied_flats' => $occupiedFlats,
            'occupancy_rate' => $occupancyRate,
            'total_residents' => $totalResidents,
            'total_guards' => $totalGuards,
            'on_duty_guards' => $onDutyGuards,
            'open_complaints' => $openComplaints,
            'resolved_complaints_this_month' => $resolvedComplaintsThisMonth,
            'pending_requests' => $pendingRequests,
            'pending_amenity_bookings' => $pendingAmenityBookings,
            'pending_service_bookings' => $pendingServiceBookings,
            'monthly_collected' => (float) $monthlyCollected,
            'monthly_due' => (float) $monthlyDue,
            'collection_rate' => $collectionRate,
            'unpaid_bills' => $unpaidBills,
            'visitors_today' => $visitorsToday,
            'visitors_inside' => $visitorsInside,
            'notices_this_month' => $noticesThisMonth,
        ];

        $chartData = [
            'trend_labels' => $trendLabels,
            'resident_trend' => $residentTrend,
            'guard_trend' => $guardTrend,
            'revenue_trend' => $revenueTrend,
            'complaint_status' => $complaintStatusChart,
            'guard_status' => $guardStatusChart,
            'top_buildings_labels' => $topBuildings->pluck('name')->values(),
            'top_buildings_residents' => $topBuildings->pluck('residents_count')->map(fn ($value) => (int) $value)->values(),
            'top_buildings_flats' => $topBuildings->pluck('flats_count')->map(fn ($value) => (int) $value)->values(),
        ];

        return view('dashboard', [
            'isSuperadmin' => $isSuperadmin,
            'kpis' => $kpis,
            'chartData' => $chartData,
            'topBuildings' => $topBuildings,
            'recentComplaints' => $recentComplaints,
            'recentPayments' => $recentPayments,
        ]);
    }
}
