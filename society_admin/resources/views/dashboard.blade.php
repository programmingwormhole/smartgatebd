@extends('layouts.app')

@section('title', 'Dashboard')
@section('header', 'Dashboard')

@section('content')
<div class="mb-8 rounded-2xl bg-gradient-to-r from-slate-900 via-blue-900 to-slate-900 p-6 text-white shadow-xl">
    <div class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div>
            <p class="text-sm uppercase tracking-[0.18em] text-blue-200">Executive Overview</p>
            <h2 class="mt-2 text-3xl font-bold">
                {{ $isSuperadmin ? 'Superadmin Control Center' : 'Building Operations Command' }}
            </h2>
            <p class="mt-2 text-sm text-blue-100">
                Live operations, finance, occupancy and service performance in one view.
            </p>
        </div>
        <div class="grid grid-cols-2 gap-3 text-right">
            <div class="rounded-xl border border-blue-800/60 bg-blue-950/40 px-4 py-3">
                <p class="text-xs text-blue-200">Collection Rate</p>
                <p class="text-2xl font-bold">{{ number_format($kpis['collection_rate'], 1) }}%</p>
            </div>
            <div class="rounded-xl border border-blue-800/60 bg-blue-950/40 px-4 py-3">
                <p class="text-xs text-blue-200">Occupancy</p>
                <p class="text-2xl font-bold">{{ number_format($kpis['occupancy_rate'], 1) }}%</p>
            </div>
        </div>
    </div>
</div>

<div class="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4 mb-8">
    <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-gray-500">Buildings</p>
        <p class="mt-2 text-3xl font-bold text-gray-900">{{ number_format($kpis['total_buildings']) }}</p>
        <p class="mt-2 text-xs text-gray-500">{{ number_format($kpis['total_blocks']) }} blocks, {{ number_format($kpis['total_floors']) }} floors</p>
    </div>
    <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-gray-500">Flats Occupied</p>
        <p class="mt-2 text-3xl font-bold text-gray-900">{{ number_format($kpis['occupied_flats']) }} / {{ number_format($kpis['total_flats']) }}</p>
        <p class="mt-2 text-xs text-gray-500">Occupancy rate {{ number_format($kpis['occupancy_rate'], 1) }}%</p>
    </div>
    <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-gray-500">Residents</p>
        <p class="mt-2 text-3xl font-bold text-gray-900">{{ number_format($kpis['total_residents']) }}</p>
        <p class="mt-2 text-xs text-gray-500">Active community members</p>
    </div>
    <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-gray-500">Guards On Duty</p>
        <p class="mt-2 text-3xl font-bold text-gray-900">{{ number_format($kpis['on_duty_guards']) }}</p>
        <p class="mt-2 text-xs text-gray-500">{{ number_format($kpis['total_guards']) }} total guards</p>
    </div>
    <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-gray-500">Collected This Month</p>
        <p class="mt-2 text-3xl font-bold text-emerald-600">৳{{ number_format($kpis['monthly_collected'], 0) }}</p>
        <p class="mt-2 text-xs text-gray-500">Due ৳{{ number_format($kpis['monthly_due'], 0) }}</p>
    </div>
    <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-gray-500">Pending Bills</p>
        <p class="mt-2 text-3xl font-bold text-amber-600">{{ number_format($kpis['unpaid_bills']) }}</p>
        <p class="mt-2 text-xs text-gray-500">Requires collection follow-up</p>
    </div>
    <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-gray-500">Open Complaints</p>
        <p class="mt-2 text-3xl font-bold text-rose-600">{{ number_format($kpis['open_complaints']) }}</p>
        <p class="mt-2 text-xs text-gray-500">Resolved this month: {{ number_format($kpis['resolved_complaints_this_month']) }}</p>
    </div>
    <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-gray-500">Pending Requests</p>
        <p class="mt-2 text-3xl font-bold text-indigo-600">{{ number_format($kpis['pending_requests']) }}</p>
        <p class="mt-2 text-xs text-gray-500">Amenity {{ $kpis['pending_amenity_bookings'] }} | Service {{ $kpis['pending_service_bookings'] }}</p>
    </div>
</div>

<div class="grid grid-cols-1 gap-6 xl:grid-cols-3 mb-8">
    <div class="xl:col-span-2 rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
        <div class="mb-4 flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900">Growth & Revenue Trend (Last 6 Months)</h3>
            <span class="text-xs text-gray-500">Residents, Guards, Revenue</span>
        </div>
        <div class="h-[320px]">
            <canvas id="trendChart"></canvas>
        </div>
    </div>

    <div class="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
        <h3 class="mb-4 text-lg font-semibold text-gray-900">Complaint Status Mix</h3>
        <div class="h-[220px]">
            <canvas id="complaintChart"></canvas>
        </div>
        <div class="mt-5 grid grid-cols-3 gap-3 text-center text-xs">
            <div class="rounded-lg bg-red-50 p-2 text-red-700">Open<br><span class="text-sm font-bold">{{ $chartData['complaint_status']['open'] }}</span></div>
            <div class="rounded-lg bg-amber-50 p-2 text-amber-700">Progress<br><span class="text-sm font-bold">{{ $chartData['complaint_status']['in_progress'] }}</span></div>
            <div class="rounded-lg bg-emerald-50 p-2 text-emerald-700">Resolved<br><span class="text-sm font-bold">{{ $chartData['complaint_status']['resolved'] }}</span></div>
        </div>
    </div>
</div>

<div class="grid grid-cols-1 gap-6 xl:grid-cols-3 mb-8">
    <div class="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm xl:col-span-2">
        <div class="mb-4 flex items-center justify-between">
            <h3 class="text-lg font-semibold text-gray-900">Top Buildings by Resident Count</h3>
            <span class="text-xs text-gray-500">Population vs flat capacity</span>
        </div>
        <div class="h-[320px]">
            <canvas id="topBuildingsChart"></canvas>
        </div>
    </div>

    <div class="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
        <h3 class="mb-4 text-lg font-semibold text-gray-900">Guard Status</h3>
        <div class="h-[220px]">
            <canvas id="guardStatusChart"></canvas>
        </div>
        <div class="mt-5 grid grid-cols-2 gap-2 text-xs">
            <div class="rounded-lg bg-emerald-50 p-2 text-emerald-700">On Duty: <span class="font-bold">{{ $chartData['guard_status']['on_duty'] }}</span></div>
            <div class="rounded-lg bg-slate-50 p-2 text-slate-700">Off Duty: <span class="font-bold">{{ $chartData['guard_status']['off_duty'] }}</span></div>
            <div class="rounded-lg bg-amber-50 p-2 text-amber-700">On Leave: <span class="font-bold">{{ $chartData['guard_status']['leave'] }}</span></div>
            <div class="rounded-lg bg-red-50 p-2 text-red-700">Inactive: <span class="font-bold">{{ $chartData['guard_status']['inactive'] }}</span></div>
        </div>
    </div>
</div>

<div class="grid grid-cols-1 gap-6 xl:grid-cols-3">
    <div class="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm xl:col-span-2">
        <h3 class="mb-4 text-lg font-semibold text-gray-900">Building Performance Snapshot</h3>
        <div class="overflow-x-auto">
            <table class="w-full text-left text-sm">
                <thead>
                    <tr class="border-b text-xs uppercase tracking-wide text-gray-500">
                        <th class="py-3 pr-4">Building</th>
                        <th class="py-3 pr-4">Residents</th>
                        <th class="py-3 pr-4">Flats</th>
                        <th class="py-3 pr-4">Occupancy</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($topBuildings as $building)
                        @php
                            $buildingFlats = max(1, (int) $building->flats_count);
                            $buildingResidents = (int) $building->residents_count;
                            $buildingOccupancy = min(100, round(($buildingResidents / $buildingFlats) * 100, 1));
                        @endphp
                        <tr class="border-b border-gray-100">
                            <td class="py-3 pr-4 font-medium text-gray-900">{{ $building->name }}</td>
                            <td class="py-3 pr-4 text-gray-700">{{ number_format($buildingResidents) }}</td>
                            <td class="py-3 pr-4 text-gray-700">{{ number_format((int) $building->flats_count) }}</td>
                            <td class="py-3 pr-4">
                                <div class="flex items-center gap-2">
                                    <div class="h-2 w-24 rounded-full bg-gray-100">
                                        <div class="h-2 rounded-full bg-blue-600" style="width: {{ $buildingOccupancy }}%"></div>
                                    </div>
                                    <span class="text-xs text-gray-600">{{ number_format($buildingOccupancy, 1) }}%</span>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="py-6 text-center text-gray-500">No building data available yet.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <div class="space-y-6">
        <div class="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
            <h3 class="mb-4 text-lg font-semibold text-gray-900">Recent Complaints</h3>
            <div class="space-y-3">
                @forelse($recentComplaints as $complaint)
                    <div class="rounded-xl border border-gray-100 p-3">
                        <p class="text-sm font-medium text-gray-900">{{ $complaint->title }}</p>
                        <p class="mt-1 text-xs text-gray-500">{{ $complaint->resident?->user?->name ?? 'Unknown Resident' }} • {{ $complaint->created_at?->diffForHumans() }}</p>
                        <span class="mt-2 inline-flex rounded-full px-2.5 py-1 text-[11px] font-medium
                            {{ $complaint->status === 'resolved' ? 'bg-emerald-100 text-emerald-700' : ($complaint->status === 'in_progress' ? 'bg-amber-100 text-amber-700' : 'bg-red-100 text-red-700') }}">
                            {{ str_replace('_', ' ', ucfirst($complaint->status)) }}
                        </span>
                    </div>
                @empty
                    <p class="text-sm text-gray-500">No complaints recorded.</p>
                @endforelse
            </div>
        </div>

        <div class="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
            <h3 class="mb-4 text-lg font-semibold text-gray-900">Recent Approved Payments</h3>
            <div class="space-y-3">
                @forelse($recentPayments as $payment)
                    <div class="rounded-xl border border-gray-100 p-3">
                        <p class="text-sm font-semibold text-emerald-700">৳{{ number_format((float) $payment->amount, 0) }}</p>
                        <p class="mt-1 text-xs text-gray-500">
                            {{ strtoupper($payment->method ?? 'manual') }} • {{ $payment->bill?->flat?->floor?->block?->building?->name ?? 'Unknown Building' }}
                        </p>
                        <p class="mt-1 text-xs text-gray-400">{{ $payment->created_at?->diffForHumans() }}</p>
                    </div>
                @empty
                    <p class="text-sm text-gray-500">No approved payments yet.</p>
                @endforelse
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
<script>
    const chartData = @json($chartData);

    const trendCtx = document.getElementById('trendChart');
    if (trendCtx) {
        new Chart(trendCtx, {
            type: 'line',
            data: {
                labels: chartData.trend_labels,
                datasets: [
                    {
                        label: 'Residents Added',
                        data: chartData.resident_trend,
                        borderColor: '#2563eb',
                        backgroundColor: 'rgba(37, 99, 235, 0.12)',
                        yAxisID: 'y',
                        tension: 0.35,
                        fill: true,
                    },
                    {
                        label: 'Guards Added',
                        data: chartData.guard_trend,
                        borderColor: '#0f766e',
                        backgroundColor: 'rgba(15, 118, 110, 0.1)',
                        yAxisID: 'y',
                        tension: 0.35,
                        fill: true,
                    },
                    {
                        label: 'Revenue Collected (BDT)',
                        data: chartData.revenue_trend,
                        borderColor: '#f59e0b',
                        backgroundColor: 'rgba(245, 158, 11, 0.15)',
                        yAxisID: 'y1',
                        tension: 0.35,
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                interaction: { mode: 'index', intersect: false },
                scales: {
                    y: { beginAtZero: true, position: 'left', grid: { color: '#f1f5f9' } },
                    y1: { beginAtZero: true, position: 'right', grid: { drawOnChartArea: false } }
                },
                plugins: { legend: { position: 'bottom' } }
            }
        });
    }

    const complaintCtx = document.getElementById('complaintChart');
    if (complaintCtx) {
        new Chart(complaintCtx, {
            type: 'doughnut',
            data: {
                labels: ['Open', 'In Progress', 'Resolved'],
                datasets: [{
                    data: [
                        chartData.complaint_status.open,
                        chartData.complaint_status.in_progress,
                        chartData.complaint_status.resolved,
                    ],
                    backgroundColor: ['#ef4444', '#f59e0b', '#10b981'],
                    borderWidth: 0,
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { position: 'bottom' } }
            }
        });
    }

    const topBuildingsCtx = document.getElementById('topBuildingsChart');
    if (topBuildingsCtx) {
        new Chart(topBuildingsCtx, {
            type: 'bar',
            data: {
                labels: chartData.top_buildings_labels,
                datasets: [
                    {
                        label: 'Residents',
                        data: chartData.top_buildings_residents,
                        backgroundColor: '#2563eb',
                        borderRadius: 8,
                    },
                    {
                        label: 'Flats',
                        data: chartData.top_buildings_flats,
                        backgroundColor: '#93c5fd',
                        borderRadius: 8,
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { position: 'bottom' } },
                scales: {
                    y: { beginAtZero: true, grid: { color: '#f1f5f9' } }
                }
            }
        });
    }

    const guardStatusCtx = document.getElementById('guardStatusChart');
    if (guardStatusCtx) {
        new Chart(guardStatusCtx, {
            type: 'polarArea',
            data: {
                labels: ['On Duty', 'Off Duty', 'On Leave', 'Inactive'],
                datasets: [{
                    data: [
                        chartData.guard_status.on_duty,
                        chartData.guard_status.off_duty,
                        chartData.guard_status.leave,
                        chartData.guard_status.inactive,
                    ],
                    backgroundColor: ['#10b981', '#64748b', '#f59e0b', '#ef4444'],
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { position: 'bottom' } }
            }
        });
    }
</script>
@endsection
