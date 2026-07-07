@extends('layouts.app')

@section('title', 'Building Details')
@section('header', 'Building Details: ' . $building->name)

@section('content')
<div class="mb-6 flex justify-between items-center">
    <a href="{{ route('admin.buildings.index') }}" class="text-gray-500 hover:text-gray-700 flex items-center gap-2 text-sm font-medium">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path></svg>
        Back to Buildings
    </a>
    <div class="flex items-center gap-2">
        <a href="{{ route('admin.residents.create', ['building_id' => $building->id]) }}" class="bg-primary hover:bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition">
            Create Resident
        </a>
        <a href="{{ route('admin.buildings.edit', $building->id) }}" class="bg-gray-100 hover:bg-gray-200 text-gray-800 px-4 py-2 rounded-lg text-sm font-medium transition">
            Edit Building Info
        </a>
    </div>
</div>

@if (session('success'))
    <div class="bg-green-50 text-green-700 p-4 rounded-xl mb-6 flex items-center gap-3">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
        {{ session('success') }}
    </div>
@endif

@if ($errors->any())
    <div class="bg-red-50 text-red-600 p-4 rounded-xl mb-6 text-sm">
        <ul class="list-disc pl-5">
            @foreach ($errors->all() as $error)
                <li>{{ $error }}</li>
            @endforeach
        </ul>
    </div>
@endif

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">

    <!-- Building Info Card -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
        <h3 class="text-lg font-semibold border-b pb-3 mb-4">Information</h3>
        <dl class="space-y-4 text-sm">
            <div>
                <dt class="font-medium text-gray-500">Name</dt>
                <dd class="mt-1 text-gray-900">{{ $building->name }}</dd>
            </div>
            <div>
                <dt class="font-medium text-gray-500">Address</dt>
                <dd class="mt-1 text-gray-900">{{ $building->address }}</dd>
            </div>
            <div>
                <dt class="font-medium text-gray-500">Registered On</dt>
                <dd class="mt-1 text-gray-900">{{ $building->created_at->format('M d, Y') }}</dd>
            </div>
        </dl>
    </div>

    <!-- Quick Stats -->
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 lg:col-span-2">
        <h3 class="text-lg font-semibold border-b pb-3 mb-4">Structure & Staff Statistics</h3>
        <div class="grid grid-cols-1 sm:grid-cols-4 gap-4">
            <div class="bg-blue-50 p-4 rounded-xl text-center">
                <span class="block text-2xl font-bold text-blue-700 mb-1">{{ $building->blocks->count() }}</span>
                <span class="text-sm font-medium text-blue-600">Blocks</span>
            </div>
            <div class="bg-green-50 p-4 rounded-xl text-center">
                <span class="block text-2xl font-bold text-green-700 mb-1">{{ $building->blocks->flatMap->floors->count() }}</span>
                <span class="text-sm font-medium text-green-600">Total Floors</span>
            </div>
            <div class="bg-purple-50 p-4 rounded-xl text-center">
                <span class="block text-2xl font-bold text-purple-700 mb-1">{{ $building->blocks->flatMap->floors->flatMap->flats->count() }}</span>
                <span class="text-sm font-medium text-purple-600">Total Flats</span>
            </div>
            <div class="bg-amber-50 p-4 rounded-xl text-center">
                <span class="block text-2xl font-bold text-amber-700 mb-1">{{ $residentCount ?? 0 }}</span>
                <span class="text-sm font-medium text-amber-600">Residents</span>
            </div>
        </div>
        <div class="border-t border-gray-200 mt-4 pt-4">
            <h4 class="text-sm font-semibold text-gray-700 mb-3">Security Guards</h4>
            <div class="grid grid-cols-1 sm:grid-cols-4 gap-3">
                <div class="bg-gradient-to-br from-green-50 to-emerald-50 p-3 rounded-lg border border-green-200">
                    <p class="text-2xl font-bold text-green-700">{{ $guardCount ?? 0 }}</p>
                    <p class="text-xs text-green-600 font-medium">Total Guards</p>
                </div>
                <div class="bg-gradient-to-br from-blue-50 to-cyan-50 p-3 rounded-lg border border-blue-200">
                    <p class="text-2xl font-bold text-blue-700">{{ $guardsOnDuty ?? 0 }}</p>
                    <p class="text-xs text-blue-600 font-medium">On Duty</p>
                </div>
                <div class="bg-gradient-to-br from-orange-50 to-amber-50 p-3 rounded-lg border border-orange-200">
                    <p class="text-2xl font-bold text-orange-700">{{ $guardsOffDuty ?? 0 }}</p>
                    <p class="text-xs text-orange-600 font-medium">Off Duty</p>
                </div>
                <div class="bg-gradient-to-br from-purple-50 to-pink-50 p-3 rounded-lg border border-purple-200">
                    <p class="text-2xl font-bold text-purple-700">{{ $guardsOnLeave ?? 0 }}</p>
                    <p class="text-xs text-purple-600 font-medium">On Leave</p>
                </div>
            </div>
        </div>
    </div>
</div>

<div x-data="{ showAdminModal: false }" class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-8">
    <div class="p-6 border-b bg-gray-50">
        <h2 class="text-lg font-semibold">Building Structure</h2>
        <p class="text-sm text-gray-500">Manage blocks, floors and flats from one place.</p>
    </div>

    <div class="p-6 border-b">
        <form action="{{ route('admin.buildings.blocks.store', $building->id) }}" method="POST" class="flex flex-col md:flex-row gap-3 items-start md:items-end">
            @csrf
            <div class="w-full md:w-80">
                <label for="block_name" class="block text-sm font-medium mb-1">New Block Name</label>
                <input id="block_name" type="text" name="name" required placeholder="e.g. Block A" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
            </div>
            <button type="submit" class="bg-primary hover:bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition">Add Block</button>
        </form>
    </div>

    <div class="divide-y divide-gray-100">
        @forelse($building->blocks as $block)
            <div class="p-6">
                <div class="flex flex-wrap items-center justify-between gap-3 mb-4">
                    <div>
                        <h3 class="font-semibold text-gray-900">{{ $block->name }}</h3>
                        <p class="text-xs text-gray-500">{{ $block->floors->count() }} floors</p>
                    </div>
                    <div class="flex gap-2">
                        <form action="{{ route('admin.blocks.destroy', $block->id) }}" method="POST" onsubmit="return confirm('Delete this block and all child floors/flats?');">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="text-red-600 hover:text-red-800 text-sm font-medium">Delete Block</button>
                        </form>
                    </div>
                </div>

                <form action="{{ route('admin.blocks.floors.store', $block->id) }}" method="POST" class="flex flex-col md:flex-row gap-3 items-start md:items-end mb-4">
                    @csrf
                    <div class="w-full md:w-80">
                        <label class="block text-sm font-medium mb-1">Add Floor</label>
                        <input type="text" name="floor_number" required placeholder="e.g. 1st Floor / 1" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                    </div>
                    <button type="submit" class="bg-gray-900 hover:bg-gray-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition">Add Floor</button>
                </form>

                <div class="space-y-3">
                    @forelse($block->floors as $floor)
                        <div class="border border-gray-200 rounded-xl p-4">
                            <div class="flex flex-wrap items-center justify-between gap-3 mb-3">
                                <div class="font-medium text-gray-800">Floor {{ $floor->floor_number }}</div>
                                <form action="{{ route('admin.floors.destroy', $floor->id) }}" method="POST" onsubmit="return confirm('Delete this floor and all flats under it?');">
                                    @csrf
                                    @method('DELETE')
                                    <button type="submit" class="text-red-600 hover:text-red-800 text-sm font-medium">Delete Floor</button>
                                </form>
                            </div>

                            <form action="{{ route('admin.floors.flats.store', $floor->id) }}" method="POST" class="flex flex-col md:flex-row gap-3 items-start md:items-end mb-3">
                                @csrf
                                <div class="w-full md:w-80">
                                    <label class="block text-sm font-medium mb-1">Add Flat</label>
                                    <input type="text" name="flat_number" required placeholder="e.g. A-101" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                                </div>
                                <button type="submit" class="bg-blue-100 hover:bg-blue-200 text-blue-800 px-4 py-2 rounded-lg text-sm font-medium transition">Add Flat</button>
                            </form>

                            <div class="flex flex-wrap gap-2">
                                @forelse($floor->flats as $flat)
                                    <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-gray-100 text-gray-800 text-sm">
                                        <span>{{ $flat->flat_number }}</span>
                                        <form action="{{ route('admin.flats.destroy', $flat->id) }}" method="POST" onsubmit="return confirm('Delete this flat?');">
                                            @csrf
                                            @method('DELETE')
                                            <button type="submit" class="text-red-600 hover:text-red-800">&times;</button>
                                        </form>
                                    </div>
                                @empty
                                    <span class="text-sm text-gray-500">No flats yet.</span>
                                @endforelse
                            </div>
                        </div>
                    @empty
                        <p class="text-sm text-gray-500">No floors yet.</p>
                    @endforelse
                </div>
            </div>
        @empty
            <div class="p-6 text-sm text-gray-500">No blocks yet. Add your first block above.</div>
        @endforelse
    </div>
</div>

<div x-data="{ showAdminModal: false }" class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-8">
    <div class="p-6 border-b bg-gray-50 flex justify-between items-center">
        <div>
            <h2 class="text-lg font-semibold">Recent Residents</h2>
            <p class="text-sm text-gray-500">Latest residents for this building.</p>
        </div>
        <a href="{{ route('admin.residents.index') }}" class="text-primary hover:underline text-sm font-medium">View All</a>
    </div>

    <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
            <thead>
                <tr class="bg-gray-50 border-b border-gray-100 text-sm text-gray-500 uppercase">
                    <th class="px-6 py-4 font-medium">Name</th>
                    <th class="px-6 py-4 font-medium">Phone</th>
                    <th class="px-6 py-4 font-medium">Block / Floor / Flat</th>
                    <th class="px-6 py-4 font-medium">Role</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse(($recentResidents ?? collect()) as $resident)
                    <tr>
                        <td class="px-6 py-4 font-medium text-gray-900">{{ $resident->user?->name }}</td>
                        <td class="px-6 py-4 text-gray-600">{{ $resident->user?->phone ?: 'N/A' }}</td>
                        <td class="px-6 py-4 text-gray-600">
                            {{ $resident->flat?->floor?->block?->name }} / {{ $resident->flat?->floor?->floor_number }} / {{ $resident->flat?->flat_number }}
                        </td>
                        <td class="px-6 py-4 text-gray-600 uppercase">{{ $resident->role }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="4" class="px-6 py-8 text-center text-gray-500">No residents found for this building.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-8">
    <div class="p-6 border-b flex justify-between items-center bg-gray-50">
        <div>
            <h2 class="text-lg font-semibold">Recent Guards</h2>
            <p class="text-sm text-gray-500">Latest guards assigned to this building.</p>
        </div>
    </div>

    <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
            <thead>
                <tr class="bg-gray-50 border-b border-gray-100 text-sm text-gray-500 uppercase">
                    <th class="px-6 py-4 font-medium">Name</th>
                    <th class="px-6 py-4 font-medium">Phone</th>
                    <th class="px-6 py-4 font-medium">Status</th>
                    <th class="px-6 py-4 font-medium">Joined Date</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 text-sm">
                @forelse ($recentGuards as $guard)
                    <tr class="hover:bg-gray-50 transition">
                        <td class="px-6 py-4 font-medium text-gray-900">{{ $guard->user->name ?? 'N/A' }}</td>
                        <td class="px-6 py-4 text-gray-600">{{ $guard->user->phone ?? 'N/A' }}</td>
                        <td class="px-6 py-4">
                            @if ($guard->status === 'on_duty')
                                <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-700">
                                    <span class="w-2 h-2 bg-green-600 rounded-full"></span>
                                    On Duty
                                </span>
                            @elseif ($guard->status === 'off_duty')
                                <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700">
                                    <span class="w-2 h-2 bg-gray-600 rounded-full"></span>
                                    Off Duty
                                </span>
                            @elseif ($guard->status === 'leave')
                                <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-700">
                                    <span class="w-2 h-2 bg-yellow-600 rounded-full"></span>
                                    On Leave
                                </span>
                            @else
                                <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium bg-red-100 text-red-700">
                                    <span class="w-2 h-2 bg-red-600 rounded-full"></span>
                                    Inactive
                                </span>
                            @endif
                        </td>
                        <td class="px-6 py-4 text-gray-600">{{ $guard->created_at->format('M d, Y') ?? 'N/A' }}</td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="4" class="px-6 py-8 text-center text-gray-500">No guards found for this building.</td>
                    </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden mb-8">
    <div class="p-6 border-b flex justify-between items-center bg-gray-50">
        <div>
            <h2 class="text-lg font-semibold">Building Admins</h2>
            <p class="text-sm text-gray-500">Users authorized to manage this building's society panel.</p>
        </div>
        <button type="button" @click="$dispatch('open-admin-modal')" class="bg-primary hover:bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition flex items-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
            Add Admin
        </button>
    </div>

    <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
            <thead>
                <tr class="bg-gray-50 border-b border-gray-100 text-sm text-gray-500 uppercase">
                    <th class="px-6 py-4 font-medium">Name</th>
                    <th class="px-6 py-4 font-medium">Email</th>
                    <th class="px-6 py-4 font-medium">Phone</th>
                    <th class="px-6 py-4 font-medium text-right">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse($building->admins as $admin)
                <tr class="hover:bg-gray-50 transition">
                    <td class="px-6 py-4 font-medium text-gray-900 border-l-4 {{ $loop->first ? 'border-primary' : 'border-transparent' }}">
                        {{ $admin->name }}
                        @if($loop->first)<span class="ml-2 text-[10px] bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full uppercase font-bold tracking-wider">Primary</span>@endif
                    </td>
                    <td class="px-6 py-4 text-gray-600">{{ $admin->email }}</td>
                    <td class="px-6 py-4 text-gray-600">{{ text_or_fallback($admin->phone) }}</td>
                    <td class="px-6 py-4 flex justify-end gap-3 text-sm">
                        <form action="{{ route('admin.buildings.admins.destroy', [$building->id, $admin->id]) }}" method="POST" onsubmit="return confirm('Are you sure you want to remove this admin from the building?');">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="text-red-500 hover:text-red-700 font-medium">Remove Access</button>
                        </form>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="4" class="px-6 py-8 text-center text-gray-500">
                        No admins assigned to this building.
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

<!-- Add Admin Modal -->
<div x-data="{ showAdminModal: false }"
    @open-admin-modal.window="showAdminModal = true"
    @keydown.escape.window="showAdminModal = false"
    x-cloak
    x-show="showAdminModal"
     style="display: none;"
     class="fixed inset-0 z-50 overflow-y-auto"
     aria-labelledby="modal-title"
     role="dialog"
     aria-modal="true">

    <div class="flex items-end justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
        <div x-show="showAdminModal"
             x-transition:enter="ease-out duration-300"
             x-transition:enter-start="opacity-0"
             x-transition:enter-end="opacity-100"
             x-transition:leave="ease-in duration-200"
             x-transition:leave-start="opacity-100"
             x-transition:leave-end="opacity-0"
             class="fixed inset-0 transition-opacity bg-gray-500 bg-opacity-75"
             aria-hidden="true"></div>

        <span class="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">&#8203;</span>

           <div x-show="showAdminModal"
               @click.away="showAdminModal = false"
             x-transition:enter="ease-out duration-300"
             x-transition:enter-start="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
             x-transition:enter-end="opacity-100 translate-y-0 sm:scale-100"
             x-transition:leave="ease-in duration-200"
             x-transition:leave-start="opacity-100 translate-y-0 sm:scale-100"
             x-transition:leave-end="opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"
             class="inline-block px-4 pt-5 pb-4 overflow-hidden text-left align-bottom transition-all transform bg-white rounded-2xl shadow-xl sm:my-8 sm:align-middle sm:max-w-lg w-full sm:p-6 text-gray-800">

            <div class="flex justify-between items-center mb-5 border-b pb-3">
                <h3 class="text-lg font-medium leading-6 text-gray-900" id="modal-title">Grant Admin Access</h3>
                <button type="button" @click="showAdminModal = false" class="text-gray-400 hover:text-gray-500 focus:outline-none">
                    <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
                </button>
            </div>

            <form method="POST" action="{{ route('admin.buildings.admins.store', $building->id) }}">
                @csrf
                <p class="text-sm text-gray-500 mb-4">Create a new building admin account and assign them to <strong>{{ $building->name }}</strong>.</p>

                <div class="space-y-4 mb-6">
                    <div>
                        <label class="block text-sm font-medium mb-1" for="admin_name">Full Name</label>
                        <input type="text" id="admin_name" name="admin_name" required class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                    </div>

                    <div>
                        <label class="block text-sm font-medium mb-1" for="admin_email">Email (Login)</label>
                        <input type="email" id="admin_email" name="admin_email" required class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                    </div>

                    <div>
                        <label class="block text-sm font-medium mb-1" for="admin_phone">Phone Number (Optional)</label>
                        <input type="text" id="admin_phone" name="admin_phone" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                    </div>

                    <div>
                        <label class="block text-sm font-medium mb-1" for="admin_password">Initial Password</label>
                        <input type="text" id="admin_password" name="admin_password" required class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                    </div>
                </div>

                <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse border-t pt-4">
                    <button type="submit" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-primary text-base font-medium text-white hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary sm:ml-3 sm:w-auto sm:text-sm">
                        Create & Assign
                    </button>
                    <button type="button" @click="showAdminModal = false" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary sm:mt-0 sm:w-auto sm:text-sm">
                        Cancel
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection

@php
function text_or_fallback($value, $fallback = 'N/A') {
    return $value ? $value : $fallback;
}
@endphp
