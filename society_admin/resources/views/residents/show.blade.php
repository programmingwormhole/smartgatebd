@extends('layouts.app')

@section('title', 'Resident Details - ' . $resident->user?->name)
@section('header', 'Resident Details')

@section('content')
<div class="mb-6 flex items-center justify-between">
    <a href="{{ route('admin.residents.index') }}" class="text-gray-600 hover:text-gray-900 font-medium flex items-center gap-2">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
        Back to Residents
    </a>
    <div class="flex gap-2">
        <a href="{{ route('admin.residents.edit', $resident) }}" class="bg-green-600 hover:bg-green-700 text-white px-6 py-2 rounded-lg font-medium transition flex items-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
            </svg>
            Edit Resident
        </a>
    </div>
</div>

@if (session('success'))
    <div class="bg-green-50 border border-green-200 text-green-800 p-4 rounded-lg mb-6">{{ session('success') }}</div>
@endif

<!-- Resident Header Card -->
<div class="bg-gradient-to-r from-blue-600 to-blue-700 rounded-2xl shadow-lg text-white p-8 mb-8">
    <div class="flex items-start justify-between">
        <div class="flex items-start gap-6">
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
                     class="w-24 h-24 rounded-full object-cover border border-white/30">
            @else
                <div class="w-24 h-24 rounded-full bg-white bg-opacity-20 flex items-center justify-center text-4xl font-bold">
                    {{ substr($resident->user?->name ?? 'U', 0, 1) }}
                </div>
            @endif
            <div>
                <h1 class="text-3xl font-bold">{{ $resident->user?->name }}</h1>
                <p class="text-blue-100 mt-2">Resident ID: #{{ $resident->id }}</p>
                <div class="flex gap-4 mt-4">
                    <div class="flex items-center gap-2">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 00.948-.684l1.498-4.493a1 1 0 011.502-.684l1.498 4.493a1 1 0 00.948.684H17a2 2 0 012 2v2a2 2 0 01-2 2H5a2 2 0 01-2-2V5z"/>
                        </svg>
                        {{ $resident->user?->phone }}
                    </div>
                    <div class="flex items-center gap-2">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                        </svg>
                        {{ $resident->user?->email ?? 'N/A' }}
                    </div>
                </div>
            </div>
        </div>
        <div class="text-right">
            @php
                $roleColors = [
                    'resident' => 'bg-blue-400',
                    'admin' => 'bg-red-400',
                    'committee' => 'bg-purple-400',
                ];
                $color = $roleColors[$resident->role] ?? 'bg-gray-400';
            @endphp
            <span class="inline-block px-6 py-2 rounded-full {{ $color }} font-bold text-sm uppercase">
                {{ ucfirst($resident->role) }}
            </span>
            <p class="text-blue-100 mt-4 text-sm">Building</p>
            <p class="text-lg font-semibold">{{ $resident->flat?->floor?->block?->building?->name }}</p>
        </div>
    </div>
</div>

<!-- Statistics Cards -->
<div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
        <div class="text-gray-600 text-sm font-medium mb-2">Total Bills</div>
        <div class="text-3xl font-bold text-gray-900">{{ $stats['total_bills'] }}</div>
        <p class="text-xs text-gray-500 mt-2">{{ $stats['pending_bills'] }} pending</p>
    </div>
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
        <div class="text-gray-600 text-sm font-medium mb-2">Paid Bills</div>
        <div class="text-3xl font-bold text-green-600">{{ $stats['paid_bills'] }}</div>
        <p class="text-xs text-gray-500 mt-2">Payment history</p>
    </div>
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
        <div class="text-gray-600 text-sm font-medium mb-2">Family Members</div>
        <div class="text-3xl font-bold text-blue-600">{{ $stats['total_families'] }}</div>
        <p class="text-xs text-gray-500 mt-2">Registered members</p>
    </div>
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
        <div class="text-gray-600 text-sm font-medium mb-2">Vehicles</div>
        <div class="text-3xl font-bold text-purple-600">{{ $stats['total_vehicles'] }}</div>
        <p class="text-xs text-gray-500 mt-2">Plus {{ $stats['total_pets'] }} pets</p>
    </div>
</div>

<!-- Resident Information -->
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
    <!-- Location & Contact -->
    <div class="lg:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
        <h2 class="text-xl font-bold text-gray-900 mb-6 flex items-center gap-2">
            <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/>
            </svg>
            Location & Address
        </h2>
        <div class="grid grid-cols-2 gap-6">
            <div>
                <label class="text-sm font-medium text-gray-600 block mb-2">Building</label>
                <p class="text-lg font-semibold text-gray-900">{{ $resident->flat?->floor?->block?->building?->name }}</p>
            </div>
            <div>
                <label class="text-sm font-medium text-gray-600 block mb-2">Block</label>
                <p class="text-lg font-semibold text-gray-900">{{ $resident->flat?->floor?->block?->name }}</p>
            </div>
            <div>
                <label class="text-sm font-medium text-gray-600 block mb-2">Floor</label>
                <p class="text-lg font-semibold text-gray-900">{{ $resident->flat?->floor?->floor_number }}</p>
            </div>
            <div>
                <label class="text-sm font-medium text-gray-600 block mb-2">Flat</label>
                <p class="text-lg font-semibold text-gray-900">{{ $resident->flat?->flat_number }}</p>
            </div>
        </div>
    </div>

    <!-- Financial Information -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
        <h2 class="text-xl font-bold text-gray-900 mb-6 flex items-center gap-2">
            <span class="inline-flex h-6 w-6 items-center justify-center rounded-full border border-green-600 text-sm font-extrabold leading-none text-green-600">৳</span>
            Financial Info
        </h2>
        <div class="space-y-4">
            <div>
                <label class="text-sm font-medium text-gray-600 block mb-1">Monthly Maintenance</label>
                <p class="text-2xl font-bold text-gray-900">৳ {{ number_format((float) ($resident->monthly_maintenance_fee ?? 0), 2) }}</p>
            </div>
            <div>
                <label class="text-sm font-medium text-gray-600 block mb-1">Monthly Rent</label>
                <p class="text-2xl font-bold text-gray-900">৳ {{ number_format((float) ($resident->rent ?? 0), 2) }}</p>
            </div>
            <div class="pt-4 border-t border-gray-200">
                <label class="text-sm font-medium text-gray-600 block mb-1">Billing Date</label>
                <p class="text-gray-900">{{ $resident->bill_generate_day }} of each month</p>
            </div>
        </div>
    </div>
</div>

<div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
    <!-- Recent Bills -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
        <h2 class="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
            <svg class="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            Recent Bills
        </h2>
        @if($resident->flat->bills->count() > 0)
            <div class="space-y-3 max-h-96 overflow-y-auto">
                @foreach($resident->flat->bills as $bill)
                    <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                        <div>
                            <p class="font-medium text-gray-900">{{ $bill->title ?? $bill->type ?? 'Bill' }}</p>
                            <p class="text-sm text-gray-600">{{ $bill->created_at->format('M d, Y') }}</p>
                        </div>
                        <div class="text-right">
                            <p class="font-semibold text-gray-900">৳ {{ number_format((float) $bill->amount, 2) }}</p>
                            <span class="text-xs px-2 py-1 rounded-full {{ $bill->status === 'paid' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800' }}">
                                {{ ucfirst($bill->status) }}
                            </span>
                        </div>
                    </div>
                @endforeach
            </div>
        @else
            <p class="text-gray-500 text-center py-8">No bills found</p>
        @endif
    </div>

    <!-- Family Members -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
        <h2 class="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
            <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 8.646 4 4 0 010-8.646M12 14a7 7 0 100-14 7 7 0 000 14z"/>
            </svg>
            Family Members ({{ $stats['total_families'] }})
        </h2>
        @if($resident->families->count() > 0)
            <div class="space-y-3 max-h-96 overflow-y-auto">
                @foreach($resident->families as $family)
                    <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                        <div class="flex items-center gap-3">
                            <div class="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-blue-600 font-semibold">
                                {{ substr($family->name ?? 'M', 0, 1) }}
                            </div>
                            <div>
                                <p class="font-medium text-gray-900">{{ $family->name }}</p>
                                <p class="text-sm text-gray-600">{{ $family->relationship ?? 'Family Member' }}</p>
                            </div>
                        </div>
                    </div>
                @endforeach
            </div>
        @else
            <p class="text-gray-500 text-center py-8">No family members registered</p>
        @endif
    </div>
</div>

<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Vehicles & Pets -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
        <h2 class="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
            <svg class="w-6 h-6 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
            </svg>
            Vehicles & Pets
        </h2>
        <div class="space-y-4">
            @if($resident->vehicles->count() > 0)
                <div>
                    <h3 class="font-semibold text-gray-900 mb-2">Vehicles ({{ $stats['total_vehicles'] }})</h3>
                    <div class="space-y-2 max-h-48 overflow-y-auto">
                        @foreach($resident->vehicles as $vehicle)
                            <div class="text-sm p-2 bg-gray-50 rounded">
                                <p class="font-medium text-gray-900">{{ $vehicle->vehicle_type ?? 'N/A' }}</p>
                                <p class="text-gray-600">{{ $vehicle->registration_number ?? 'No registration' }}</p>
                            </div>
                        @endforeach
                    </div>
                </div>
            @endif
            @if($resident->pets->count() > 0)
                <div>
                    <h3 class="font-semibold text-gray-900 mb-2">Pets ({{ $stats['total_pets'] }})</h3>
                    <div class="space-y-2 max-h-48 overflow-y-auto">
                        @foreach($resident->pets as $pet)
                            <div class="text-sm p-2 bg-gray-50 rounded">
                                <p class="font-medium text-gray-900">{{ $pet->name ?? 'Pet' }}</p>
                                <p class="text-gray-600">{{ $pet->type ?? 'Unknown' }}</p>
                            </div>
                        @endforeach
                    </div>
                </div>
            @endif
            @if($resident->vehicles->count() === 0 && $resident->pets->count() === 0)
                <p class="text-gray-500 text-center py-8">No vehicles or pets registered</p>
            @endif
        </div>
    </div>

    <!-- Visitors & Activity -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
        <h2 class="text-xl font-bold text-gray-900 mb-4 flex items-center gap-2">
            <svg class="w-6 h-6 text-orange-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.856-1.487M15 10a3 3 0 11-6 0 3 3 0 016 0zM6 20h12a6 6 0 00-6-6 6 6 0 00-6 6z"/>
            </svg>
            Recent Visitors ({{ $stats['total_visitors'] }})
        </h2>
        @if($resident->visitors->count() > 0)
            <div class="space-y-3 max-h-96 overflow-y-auto">
                @foreach($resident->visitors as $visitor)
                    <div class="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                        <div>
                            <p class="font-medium text-gray-900">{{ $visitor->name }}</p>
                            <p class="text-sm text-gray-600">{{ $visitor->phone ?? 'No contact' }}</p>
                        </div>
                        <span class="text-xs px-2 py-1 rounded-full {{ $visitor->status === 'approved' ? 'bg-green-100 text-green-800' : ($visitor->status === 'rejected' ? 'bg-red-100 text-red-800' : 'bg-yellow-100 text-yellow-800') }}">
                            {{ ucfirst($visitor->status) }}
                        </span>
                    </div>
                @endforeach
            </div>
        @else
            <p class="text-gray-500 text-center py-8">No visitor records</p>
        @endif
    </div>
</div>
@endsection
