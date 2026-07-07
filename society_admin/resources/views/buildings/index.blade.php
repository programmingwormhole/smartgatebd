@extends('layouts.app')

@section('title', 'Manage Buildings')
@section('header', 'Manage Buildings')

@section('content')

<form method="GET" action="{{ route('admin.buildings.index') }}" class="mb-6">
    <div class="flex gap-3">
        <div class="flex-1">
            <input
                type="text"
                name="search"
                value="{{ request('search') }}"
                placeholder="Search buildings by name, address, admin name, email or phone..."
                class="w-full rounded-lg border border-gray-200 px-4 py-3 focus:border-primary focus:ring-primary"
            >
        </div>
        <button type="submit" class="bg-primary hover:bg-blue-600 text-white px-6 py-3 rounded-lg font-medium transition">
            Search
        </button>
        @if(request()->filled('search'))
            <a href="{{ route('admin.buildings.index') }}" class="inline-flex items-center px-6 py-3 rounded-lg border border-gray-200 text-gray-700 hover:bg-gray-50 font-medium transition">
                Clear
            </a>
        @endif
    </div>
</form>

@if (session('success'))
    <div class="bg-green-50 text-green-700 p-4 rounded-xl mb-6 flex items-center gap-3">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
        {{ session('success') }}
    </div>
@endif

<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
    <div class="p-6 border-b flex justify-between items-center">
        <h2 class="text-lg font-semibold">Registered Buildings</h2>
        <a href="{{ route('admin.buildings.create') }}" class="bg-primary hover:bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition flex items-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
            Add Building
        </a>
    </div>

    <div class="overflow-x-auto">
        <table class="w-full text-left border-collapse">
            <thead>
                <tr class="bg-gray-50 border-b border-gray-100 text-sm text-gray-500 uppercase">
                    <th class="px-6 py-4 font-medium">Building Name</th>
                    <th class="px-6 py-4 font-medium">Address</th>
                    <th class="px-6 py-4 font-medium">Admins</th>
                    <th class="px-6 py-4 font-medium text-right">Actions</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @forelse($buildings as $building)
                <tr class="hover:bg-gray-50 transition">
                    <td class="px-6 py-4 font-medium text-gray-900">{{ $building->name }}</td>
                    <td class="px-6 py-4 text-gray-600 truncate max-w-xs">{{ $building->address }}</td>
                    <td class="px-6 py-4 text-gray-600">
                        @if($building->admins->count() > 0)
                            <div class="flex flex-col gap-1">
                                @foreach($building->admins as $admin)
                                    <span class="text-xs font-medium">{{ $admin->name }} <span class="text-gray-400">({{ $admin->email }})</span></span>
                                @endforeach
                            </div>
                        @else
                            <span class="text-gray-400 italic">No admins</span>
                        @endif
                    </td>
                    <td class="px-6 py-4 flex justify-end gap-3 text-sm">
                        <a href="{{ route('admin.buildings.show', $building->id) }}" class="text-blue-600 hover:text-blue-800">View / Admins</a>
                        <a href="{{ route('admin.buildings.edit', $building->id) }}" class="text-indigo-600 hover:text-indigo-800">Edit</a>
                        <form action="{{ route('admin.buildings.destroy', $building->id) }}" method="POST" onsubmit="return confirm('Are you sure you want to delete this building?');">
                            @csrf
                            @method('DELETE')
                            <button type="submit" class="text-red-600 hover:text-red-800">Delete</button>
                        </form>
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="4" class="px-6 py-8 text-center text-gray-500">
                        No buildings registered yet. <a href="{{ route('admin.buildings.create') }}" class="text-primary hover:underline">Add one now</a>.
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    @if($buildings->hasPages())
    <div class="p-4 border-t">
        {{ $buildings->links() }}
    </div>
    @endif
</div>
@endsection
