@extends('layouts.app')

@section('title', 'Guards')
@section('header', 'Security Guards')

@section('content')
<div class="mb-8">
    <div class="flex items-center justify-between">
        <div>
            <h2 class="text-2xl font-bold text-gray-900">Guard Management</h2>
            <p class="text-gray-600 mt-1">Manage security staff. Total guards: <span class="font-semibold text-primary">{{ $guards->total() }}</span></p>
        </div>
        <a href="{{ route('admin.guards.create') }}" class="bg-primary hover:bg-blue-600 text-white px-6 py-3 rounded-lg font-medium transition flex items-center gap-2 shadow-lg hover:shadow-xl">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
            </svg>
            Add Guard
        </a>
    </div>
</div>

<form method="GET" action="{{ route('admin.guards.index') }}" class="mb-6 bg-white rounded-2xl shadow-sm border border-gray-100 p-4">
    <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
        <div class="md:col-span-2">
            <input
                type="text"
                name="search"
                value="{{ request('search') }}"
                placeholder="Search guards by name, phone, email, building or status..."
                class="w-full rounded-lg border border-gray-200 px-4 py-3 focus:border-primary focus:ring-primary"
            >
        </div>
        <div>
            <button type="submit" class="w-full bg-primary hover:bg-blue-600 text-white px-6 py-3 rounded-lg font-medium transition">
                Search
            </button>
        </div>
        <div>
            <select
                name="building_id"
                class="w-full rounded-lg border border-gray-200 px-4 py-3 focus:border-primary focus:ring-primary"
            >
                @if(auth()->user()->role === 'superadmin')
                    <option value="">All Buildings</option>
                @endif
                @foreach($buildings as $building)
                    <option value="{{ $building->id }}" @selected((string) request('building_id') === (string) $building->id)>
                        {{ $building->name }}
                    </option>
                @endforeach
            </select>
        </div>
        <div class="md:col-span-3 flex justify-end">
            @if(request()->filled('search') || request()->filled('building_id'))
                <a href="{{ route('admin.guards.index') }}" class="inline-flex items-center px-6 py-3 rounded-lg border border-gray-200 text-gray-700 hover:bg-gray-50 font-medium transition">
                    Clear Filters
                </a>
            @endif
        </div>
    </div>
</form>

<div class="mb-6 rounded-2xl border border-blue-100 bg-blue-50 px-4 py-3 text-sm text-blue-900">
    Showing {{ $guards->count() }} of {{ $guards->total() }} guards
    @if(request()->filled('search'))
        for "{{ request('search') }}"
    @endif
    @if(request()->filled('building_id'))
        @php
            $selectedBuilding = $buildings->firstWhere('id', (int) request('building_id'));
        @endphp
        in {{ $selectedBuilding?->name ?? 'selected building' }}
    @endif
</div>

@if (session('success'))
    <div class="bg-green-50 border border-green-200 text-green-800 p-4 rounded-lg mb-6 flex items-start gap-3">
        <svg class="w-5 h-5 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
        </svg>
        <div>{{ session('success') }}</div>
    </div>
@endif

<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
    <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
            <thead>
                <tr class="bg-gradient-to-r from-gray-50 to-gray-100 border-b border-gray-200 text-xs text-gray-600 uppercase tracking-wider">
                    <th class="px-6 py-4 font-semibold">Guard</th>
                    <th class="px-6 py-4 font-semibold">Contact</th>
                    <th class="px-6 py-4 font-semibold">Building</th>
                    <th class="px-6 py-4 font-semibold">Status</th>
                    <th class="px-6 py-4 font-semibold">Joined</th>
                    <th class="px-6 py-4 font-semibold text-right">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse($guards as $guard)
                    <tr class="hover:bg-blue-50 transition-colors">
                        <td class="px-6 py-4">
                            <div class="flex items-center gap-3">
                                @php
                                    $guardPic = $guard->user?->profile_picture;
                                    $guardAvatarUrl = $guardPic
                                        ? (\Illuminate\Support\Str::startsWith($guardPic, ['http://', 'https://'])
                                            ? $guardPic
                                            : asset(ltrim($guardPic, '/')))
                                        : null;
                                @endphp
                                @if($guardAvatarUrl)
                                    <img src="{{ $guardAvatarUrl }}"
                                         alt="{{ $guard->user?->name }}"
                                         class="w-10 h-10 rounded-full object-cover">
                                @else
                                    <div class="w-10 h-10 rounded-full bg-gradient-to-br from-green-400 to-green-600 flex items-center justify-center text-white font-semibold">
                                        {{ substr($guard->user?->name ?? 'G', 0, 1) }}
                                    </div>
                                @endif
                                <div>
                                    <div class="font-semibold text-gray-900">{{ $guard->user?->name }}</div>
                                    <div class="text-xs text-gray-500">ID: #{{ $guard->id }}</div>
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4">
                            <div class="text-sm">
                                <div class="flex items-center gap-2 text-gray-700">
                                    <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 00.948-.684l1.498-4.493a1 1 0 011.502-.684l1.498 4.493a1 1 0 00.948.684H17a2 2 0 012 2v2a2 2 0 01-2 2H5a2 2 0 01-2-2V5z"/>
                                    </svg>
                                    {{ $guard->user?->phone ?: 'N/A' }}
                                </div>
                                <div class="flex items-center gap-2 text-gray-600 mt-1">
                                    <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                                    </svg>
                                    <span class="text-xs">{{ $guard->user?->email ?: 'N/A' }}</span>
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4">
                            <div class="text-sm font-medium text-gray-900">{{ $guard->building?->name ?? 'N/A' }}</div>
                        </td>
                        <td class="px-6 py-4">
                            @php
                                $statusColors = [
                                    'on_duty' => 'bg-green-100 text-green-800',
                                    'off_duty' => 'bg-orange-100 text-orange-800',
                                    'leave' => 'bg-blue-100 text-blue-800',
                                    'inactive' => 'bg-red-100 text-red-800',
                                ];
                                $color = $statusColors[$guard->status] ?? 'bg-gray-100 text-gray-800';
                            @endphp
                            <span class="px-3 py-1 rounded-full text-xs font-semibold {{ $color }}">
                                {{ str_replace('_', ' ', ucfirst($guard->status)) }}
                            </span>
                        </td>
                        <td class="px-6 py-4">
                            <div class="text-sm text-gray-700">{{ $guard->created_at->format('M d, Y') }}</div>
                        </td>
                        <td class="px-6 py-4 text-right">
                            <div class="flex items-center justify-end gap-2">
                                <a href="{{ route('admin.guards.show', $guard) }}" class="text-primary hover:text-blue-700 font-medium text-sm">
                                    View
                                </a>
                                <a href="{{ route('admin.guards.edit', $guard) }}" class="text-blue-500 hover:text-blue-700 font-medium text-sm">
                                    Edit
                                </a>
                                <form action="{{ route('admin.guards.destroy', $guard) }}" method="POST" class="inline" onsubmit="return confirm('Are you sure you want to delete this guard?');">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="text-red-500 hover:text-red-700 font-medium text-sm">Delete</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-6 py-12">
                            <div class="flex flex-col items-center justify-center">
                                <svg class="w-16 h-16 text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"/>
                                </svg>
                                <p class="text-gray-500 font-medium">No guards found</p>
                                <a href="{{ route('admin.guards.create') }}" class="mt-4 text-primary hover:text-blue-700 font-medium">
                                    Create the first guard
                                </a>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

<!-- Pagination -->
<div class="mt-6">
    {{ $guards->links() }}
</div>
@endsection
