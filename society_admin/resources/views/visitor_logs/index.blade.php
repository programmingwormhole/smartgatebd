@extends('layouts.app')

@section('title', 'Visitor Logs')
@section('header', 'Visitor Logs')

@section('content')
<div class="space-y-6">
    <div class="rounded-2xl border border-gray-100 bg-white p-6">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
            <div>
                <h2 class="text-xl font-bold text-gray-900">Visitor Activity Intelligence</h2>
                <p class="mt-1 text-sm text-gray-500">Advanced visitor access monitoring with audit-friendly filtering and reporting.</p>
            </div>
            <a
                href="{{ route('admin.visitor-logs.report.pdf', request()->query()) }}"
                class="inline-flex items-center gap-2 rounded-xl bg-primary px-4 py-2.5 text-sm font-semibold text-white hover:bg-blue-700"
            >
                <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 10v6m0 0-3-3m3 3 3-3M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2M7 9V4a1 1 0 0 1 1-1h5l4 4v2" />
                </svg>
                Export PDF Report
            </a>
        </div>
    </div>

    <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
        <div class="rounded-2xl border border-gray-100 bg-white p-5">
            <p class="text-xs uppercase tracking-wide text-gray-500">Total Logs</p>
            <p class="mt-2 text-3xl font-bold text-gray-900">{{ number_format($stats['total_logs']) }}</p>
        </div>
        <div class="rounded-2xl border border-gray-100 bg-white p-5">
            <p class="text-xs uppercase tracking-wide text-gray-500">Entries</p>
            <p class="mt-2 text-3xl font-bold text-emerald-600">{{ number_format($stats['entries']) }}</p>
        </div>
        <div class="rounded-2xl border border-gray-100 bg-white p-5">
            <p class="text-xs uppercase tracking-wide text-gray-500">Exits</p>
            <p class="mt-2 text-3xl font-bold text-orange-600">{{ number_format($stats['exits']) }}</p>
        </div>
        <div class="rounded-2xl border border-gray-100 bg-white p-5">
            <p class="text-xs uppercase tracking-wide text-gray-500">Unique Visitors</p>
            <p class="mt-2 text-3xl font-bold text-indigo-600">{{ number_format($stats['unique_visitors']) }}</p>
        </div>
    </div>

    <div class="rounded-2xl border border-gray-100 bg-white p-6">
        <form method="GET" action="{{ route('admin.visitor-logs.index') }}" class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-5">
            <div>
                <label for="date_range" class="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-600">Date Range</label>
                <select name="date_range" id="date_range">
                    @foreach($rangeOptions as $value => $label)
                        <option value="{{ $value }}" @selected($filters['date_range'] === $value)>{{ $label }}</option>
                    @endforeach
                </select>
            </div>

            <div>
                <label for="from_date" class="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-600">From Date</label>
                <input type="date" name="from_date" id="from_date" value="{{ $filters['from_date'] }}">
            </div>

            <div>
                <label for="to_date" class="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-600">To Date</label>
                <input type="date" name="to_date" id="to_date" value="{{ $filters['to_date'] }}">
            </div>

            <div>
                <label for="building_id" class="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-600">Building</label>
                <select name="building_id" id="building_id">
                    <option value="">All Buildings</option>
                    @foreach($buildings as $building)
                        <option value="{{ $building->id }}" @selected((string) $filters['building_id'] === (string) $building->id)>{{ $building->name }}</option>
                    @endforeach
                </select>
            </div>

            <div>
                <label for="visitor_type" class="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-600">Visitor Type</label>
                <select name="visitor_type" id="visitor_type">
                    <option value="">All Types</option>
                    @foreach($visitorTypes as $value => $label)
                        <option value="{{ $value }}" @selected($filters['visitor_type'] === $value)>{{ $label }}</option>
                    @endforeach
                </select>
            </div>

            <div>
                <label for="action" class="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-600">Action</label>
                <select name="action" id="action">
                    <option value="">All Actions</option>
                    @foreach($actions as $value => $label)
                        <option value="{{ $value }}" @selected($filters['action'] === $value)>{{ $label }}</option>
                    @endforeach
                </select>
            </div>

            <div>
                <label for="guard_id" class="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-600">Guard</label>
                <select name="guard_id" id="guard_id">
                    <option value="">All Guards</option>
                    @foreach($guards as $guard)
                        <option value="{{ $guard->id }}" @selected((string) $filters['guard_id'] === (string) $guard->id)>
                            {{ $guard->user?->name ?? ('Guard #' . $guard->id) }}
                        </option>
                    @endforeach
                </select>
            </div>

            <div>
                <label for="resident_id" class="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-600">Resident</label>
                <select name="resident_id" id="resident_id">
                    <option value="">All Residents</option>
                    @foreach($residents as $resident)
                        <option value="{{ $resident->id }}" @selected((string) $filters['resident_id'] === (string) $resident->id)>
                            {{ $resident->user?->name ?? ('Resident #' . $resident->id) }}
                        </option>
                    @endforeach
                </select>
            </div>

            <div>
                <label for="entry_code" class="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-600">Entry Code</label>
                <input type="text" name="entry_code" id="entry_code" value="{{ $filters['entry_code'] }}" placeholder="e.g. 123456">
            </div>

            <div class="xl:col-span-2">
                <label for="search" class="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-600">Search</label>
                <input type="text" name="search" id="search" value="{{ $filters['search'] }}" placeholder="Visitor name, phone, purpose, notes">
            </div>

            <div>
                <label for="per_page" class="mb-1 block text-xs font-semibold uppercase tracking-wide text-gray-600">Rows Per Page</label>
                <select name="per_page" id="per_page">
                    @foreach([10, 25, 50, 100] as $size)
                        <option value="{{ $size }}" @selected((int) $filters['per_page'] === $size)>{{ $size }}</option>
                    @endforeach
                </select>
            </div>

            <div class="xl:col-span-5 flex flex-wrap items-center gap-3 pt-1">
                <button type="submit" class="rounded-xl bg-primary px-5 py-2.5 text-sm font-semibold text-white hover:bg-blue-700">
                    Apply Filters
                </button>
                <a href="{{ route('admin.visitor-logs.index') }}" class="rounded-xl border border-gray-200 px-5 py-2.5 text-sm font-semibold text-gray-700 hover:bg-gray-50">
                    Reset
                </a>
            </div>
        </form>
    </div>

    <div class="rounded-2xl border border-gray-100 bg-white p-0 overflow-hidden">
        <div class="overflow-x-auto">
            <table class="min-w-full text-sm">
                <thead>
                    <tr class="text-xs uppercase tracking-wide text-gray-600">
                        <th class="px-4 py-3 text-left">Date & Time</th>
                        <th class="px-4 py-3 text-left">Building</th>
                        <th class="px-4 py-3 text-left">Visitor</th>
                        <th class="px-4 py-3 text-left">Type</th>
                        <th class="px-4 py-3 text-left">Action</th>
                        <th class="px-4 py-3 text-left">Entry Code</th>
                        <th class="px-4 py-3 text-left">Guard</th>
                        <th class="px-4 py-3 text-left">Resident</th>
                        <th class="px-4 py-3 text-left">Purpose / Notes</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($logs as $log)
                        <tr class="border-t border-gray-100 align-top">
                            <td class="px-4 py-3 whitespace-nowrap">
                                <div class="font-semibold text-gray-900">{{ $log->activity_date?->format('d M Y') }}</div>
                                <div class="text-xs text-gray-500">{{ $log->activity_date?->format('h:i A') }}</div>
                            </td>
                            <td class="px-4 py-3 text-gray-700">{{ $log->building?->name ?? 'N/A' }}</td>
                            <td class="px-4 py-3">
                                <div class="font-semibold text-gray-900">{{ $log->visitor_name ?: 'N/A' }}</div>
                                <div class="text-xs text-gray-500">{{ $log->visitor_phone ?: 'No phone' }}</div>
                            </td>
                            <td class="px-4 py-3 text-gray-700">{{ $log->getVisitorTypeLabel() }}</td>
                            <td class="px-4 py-3">
                                <span class="inline-flex rounded-full px-2.5 py-1 text-xs font-semibold {{ $log->action === 'entry' ? 'bg-emerald-100 text-emerald-700' : ($log->action === 'exit' ? 'bg-orange-100 text-orange-700' : 'bg-blue-100 text-blue-700') }}">
                                    {{ $log->getActionLabel() }}
                                </span>
                            </td>
                            <td class="px-4 py-3 font-mono text-gray-700">{{ $log->entry_code ?: ($log->gatepass?->entry_code ?: 'N/A') }}</td>
                            <td class="px-4 py-3 text-gray-700">{{ $log->guardUser?->user?->name ?? 'N/A' }}</td>
                            <td class="px-4 py-3 text-gray-700">{{ $log->resident?->user?->name ?? 'N/A' }}</td>
                            <td class="px-4 py-3 text-gray-600">
                                <div>{{ $log->purpose ?: 'No purpose' }}</div>
                                @if(!empty($log->notes))
                                    <div class="mt-1 text-xs text-gray-500">{{ $log->notes }}</div>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="9" class="px-4 py-8 text-center text-gray-500">No visitor logs found for the selected filters.</td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>

        @if($logs->hasPages())
            <div class="border-t border-gray-100 p-4">
                {{ $logs->links() }}
            </div>
        @endif
    </div>
</div>
@endsection
