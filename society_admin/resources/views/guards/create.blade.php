@extends('layouts.app')

@section('title', 'Create Guard')
@section('header', 'Create Guard')

@section('content')
<div class="mb-8">
    <a href="{{ route('admin.guards.index') }}" class="text-primary hover:text-blue-700 font-medium flex items-center gap-2">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
        Back to Guards
    </a>
</div>

<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
    <h2 class="text-2xl font-bold text-gray-900 mb-8">Add New Guard</h2>

    @if ($errors->any())
        <div class="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <h3 class="text-red-900 font-semibold mb-2">Errors:</h3>
            <ul class="text-red-800 text-sm space-y-1">
                @foreach ($errors->all() as $error)
                    <li>• {{ $error }}</li>
                @endforeach
            </ul>
        </div>
    @endif

    <form action="{{ route('admin.guards.store') }}" method="POST" class="space-y-6">
        @csrf

        <!-- Building Selection (for superadmin) -->
        @if (auth()->user()->role === 'superadmin')
            <div>
                <label for="building_id" class="block text-sm font-semibold text-gray-700 mb-2">
                    Building <span class="text-red-500">*</span>
                </label>
                <select name="building_id" id="building_id" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent @error('building_id') border-red-500 @enderror">
                    <option value="">Select a building</option>
                    @foreach($buildings as $building)
                        <option value="{{ $building->id }}" {{ old('building_id') == $building->id ? 'selected' : '' }}>
                            {{ $building->name }}
                        </option>
                    @endforeach
                </select>
                @error('building_id')
                    <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
                @enderror
            </div>
        @else
            <input type="hidden" name="building_id" value="{{ auth()->user()->building_id }}">
        @endif

        <!-- Name -->
        <div>
            <label for="name" class="block text-sm font-semibold text-gray-700 mb-2">
                Full Name <span class="text-red-500">*</span>
            </label>
            <input type="text" name="name" id="name" value="{{ old('name') }}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent @error('name') border-red-500 @enderror" placeholder="Guard's full name" required>
            @error('name')
                <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
            @enderror
        </div>

        <!-- Phone -->
        <div>
            <label for="phone" class="block text-sm font-semibold text-gray-700 mb-2">
                Phone Number <span class="text-red-500">*</span>
            </label>
            <input type="tel" name="phone" id="phone" value="{{ old('phone') }}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent @error('phone') border-red-500 @enderror" placeholder="01XXXXXXXXX" required>
            <p class="text-xs text-gray-500 mt-1">Phone will be used as default password</p>
            @error('phone')
                <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
            @enderror
        </div>

        <!-- Email -->
        <div>
            <label for="email" class="block text-sm font-semibold text-gray-700 mb-2">
                Email Address <span class="text-gray-500 text-sm">(Optional)</span>
            </label>
            <input type="email" name="email" id="email" value="{{ old('email') }}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent @error('email') border-red-500 @enderror" placeholder="guard@example.com">
            @error('email')
                <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
            @enderror
        </div>

        <!-- Status -->
        <div>
            <label for="status" class="block text-sm font-semibold text-gray-700 mb-2">
                Initial Status <span class="text-red-500">*</span>
            </label>
            <select name="status" id="status" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent @error('status') border-red-500 @enderror">
                <option value="off_duty" {{ old('status') === 'off_duty' ? 'selected' : '' }}>Off Duty</option>
                <option value="on_duty" {{ old('status') === 'on_duty' ? 'selected' : '' }}>On Duty</option>
                <option value="leave" {{ old('status') === 'leave' ? 'selected' : '' }}>On Leave</option>
                <option value="inactive" {{ old('status') === 'inactive' ? 'selected' : '' }}>Inactive</option>
            </select>
            @error('status')
                <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
            @enderror
        </div>

        <!-- Info Box -->
        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <p class="text-sm text-blue-800">
                <strong>Note:</strong> A user account will be created automatically. The default password will be the phone number. The guard can change it after first login.
            </p>
        </div>

        <!-- Buttons -->
        <div class="flex gap-4 pt-6 border-t border-gray-200">
            <a href="{{ route('admin.guards.index') }}" class="px-6 py-2 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition">
                Cancel
            </a>
            <button type="submit" class="px-6 py-2 bg-primary hover:bg-blue-600 text-white rounded-lg font-medium transition">
                Create Guard
            </button>
        </div>
    </form>
</div>
@endsection
