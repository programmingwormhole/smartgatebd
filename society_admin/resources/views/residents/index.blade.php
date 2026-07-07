@extends('layouts.app')

@section('title', 'Residents')
@section('header', 'Residents')

@section('content')
<div class="mb-8">
    <div class="flex items-center justify-between">
        <div>
            <h2 class="text-2xl font-bold text-gray-900">Resident Directory</h2>
            <p class="text-gray-600 mt-1">Manage all residents in your building. Total residents: <span class="font-semibold text-primary">{{ $residents->total() }}</span></p>
        </div>
        <a href="{{ route('admin.residents.create') }}" class="bg-primary hover:bg-blue-600 text-white px-6 py-3 rounded-lg font-medium transition flex items-center gap-2 shadow-lg hover:shadow-xl">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
            </svg>
            Create Resident
        </a>
    </div>
</div>

<form method="GET" action="{{ route('admin.residents.index') }}" class="mb-6">
    <div class="flex gap-3">
        <div class="flex-1">
            <input
                type="text"
                name="search"
                value="{{ request('search') }}"
                placeholder="Search residents by name, phone, email, flat or block..."
                class="w-full rounded-lg border border-gray-200 px-4 py-3 focus:border-primary focus:ring-primary"
            >
        </div>
        <button type="submit" class="bg-primary hover:bg-blue-600 text-white px-6 py-3 rounded-lg font-medium transition">
            Search
        </button>
        @if(request()->filled('search'))
            <a href="{{ route('admin.residents.index') }}" class="inline-flex items-center px-6 py-3 rounded-lg border border-gray-200 text-gray-700 hover:bg-gray-50 font-medium transition">
                Clear
            </a>
        @endif
    </div>
</form>

<div class="mb-6 rounded-2xl border border-blue-100 bg-blue-50 px-4 py-3 text-sm text-blue-900">
    Showing {{ $residents->count() }} of {{ $residents->total() }} residents
    @if(request()->filled('search'))
        for "{{ request('search') }}"
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
                    <th class="px-6 py-4 font-semibold">Resident</th>
                    <th class="px-6 py-4 font-semibold">Contact</th>
                    <th class="px-6 py-4 font-semibold">Location</th>
                    <th class="px-6 py-4 font-semibold">Role</th>
                    <th class="px-6 py-4 font-semibold">Monthly Fees</th>
                    <th class="px-6 py-4 font-semibold text-right">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse($residents as $resident)
                    <tr class="hover:bg-blue-50 transition-colors">
                        <td class="px-6 py-4">
                            <div class="flex items-center gap-3">
                                @php
                                    $residentPic = $resident->user?->profile_picture;
                                    $residentAvatarUrl = $residentPic
                                        ? (\Illuminate\Support\Str::startsWith($residentPic, ['http://', 'https://'])
                                            ? $residentPic
                                            : asset(ltrim($residentPic, '/')))
                                        : null;
                                @endphp
                                @if($residentAvatarUrl)
                                    <img src="{{ $residentAvatarUrl }}"
                                         alt="{{ $resident->user?->name }}"
                                         class="w-10 h-10 rounded-full object-cover">
                                @else
                                    <div class="w-10 h-10 rounded-full bg-gradient-to-br from-blue-400 to-blue-600 flex items-center justify-center text-white font-semibold">
                                        {{ substr($resident->user?->name ?? 'U', 0, 1) }}
                                    </div>
                                @endif
                                <div>
                                    <div class="font-semibold text-gray-900">{{ $resident->user?->name }}</div>
                                    <div class="text-xs text-gray-500">ID: #{{ $resident->id }}</div>
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4">
                            <div class="text-sm">
                                <div class="flex items-center gap-2 text-gray-700">
                                    <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 00.948-.684l1.498-4.493a1 1 0 011.502-.684l1.498 4.493a1 1 0 00.948.684H17a2 2 0 012 2v2a2 2 0 01-2 2H5a2 2 0 01-2-2V5z"/>
                                    </svg>
                                    {{ $resident->user?->phone ?: 'N/A' }}
                                </div>
                                <div class="flex items-center gap-2 text-gray-600 mt-1">
                                    <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                                    </svg>
                                    <span class="text-xs">{{ $resident->user?->email ?: 'N/A' }}</span>
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4">
                            <div class="text-sm">
                                <div class="font-medium text-gray-900">{{ $resident->flat?->floor?->block?->name ?? 'N/A' }}</div>
                                <div class="text-gray-600 mt-1">
                                    Floor {{ $resident->flat?->floor?->floor_number ?? '-' }}
                                    <span class="text-gray-400">•</span>
                                    Flat {{ $resident->flat?->flat_number ?? '-' }}
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4">
                            @php
                                $roleColors = [
                                    'resident' => 'bg-blue-100 text-blue-800',
                                    'admin' => 'bg-red-100 text-red-800',
                                    'committee' => 'bg-purple-100 text-purple-800',
                                ];
                                $color = $roleColors[$resident->role] ?? 'bg-gray-100 text-gray-800';
                            @endphp
                            <span class="px-3 py-1 rounded-full text-xs font-semibold {{ $color }}">
                                {{ ucfirst($resident->role) }}
                            </span>
                        </td>
                        <td class="px-6 py-4">
                            <div class="text-sm">
                                <div class="text-gray-900">
                                    <span class="font-medium">৳</span> {{ number_format((float) ($resident->rent ?? 0), 2) }} + <span class="font-medium">৳</span> {{ number_format((float) ($resident->monthly_maintenance_fee ?? 0), 2) }} (Maintenance)
                                </div>
                                <div class="text-gray-600 mt-1 text-xs">
                                    Total: <span class="font-semibold">৳</span> {{ number_format((float) (($resident->rent ?? 0) + ($resident->monthly_maintenance_fee ?? 0)), 2) }}
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4 text-right">
                            <div class="flex items-center justify-end gap-2">
                                <a href="{{ route('admin.residents.show', $resident) }}" class="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition" title="View Details">
                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                                    </svg>
                                </a>
                                <a href="{{ route('admin.residents.edit', $resident) }}" class="p-2 text-green-600 hover:bg-green-50 rounded-lg transition" title="Edit">
                                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
                                    </svg>
                                </a>
                                <form method="POST" action="{{ route('admin.residents.destroy', $resident) }}" class="inline" onsubmit="return confirm('Are you sure you want to delete this resident?');">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="p-2 text-red-600 hover:bg-red-50 rounded-lg transition" title="Delete">
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
                                        </svg>
                                    </button>
                                </form>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="6" class="px-6 py-16 text-center">
                            <div class="flex flex-col items-center">
                                <svg class="w-16 h-16 text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4.354a4 4 0 110 8.646 4 4 0 010-8.646zm0 12a8 8 0 100-16 8 8 0 000 16z"/>
                                </svg>
                                <h3 class="text-lg font-medium text-gray-700 mb-1">No residents found</h3>
                                <p class="text-gray-500 mb-4">Start by creating your first resident to get started.</p>
                                <a href="{{ route('admin.residents.create') }}" class="text-primary hover:text-blue-600 font-medium text-sm">Create a resident →</a>
                            </div>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if($residents->hasPages())
        <div class="px-6 py-4 border-t border-gray-100">
            {{ $residents->links() }}
        </div>
    @endif
</div>
@endsection

