@extends('layouts.app')

@section('title', 'Edit Guard')
@section('header', 'Edit Guard')

@section('content')
<div class="mb-8">
    <a href="{{ route('admin.guards.index') }}" class="text-primary hover:text-blue-700 font-medium flex items-center gap-2">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
        Back to Guards
    </a>
</div>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
    <!-- Main Form -->
    <div class="lg:col-span-2">
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
            <h2 class="text-2xl font-bold text-gray-900 mb-8">Edit Guard</h2>

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

            <form action="{{ route('admin.guards.update', $guard) }}" method="POST" class="space-y-6">
                @csrf
                @method('PUT')

                <!-- Name -->
                <div>
                    <label for="name" class="block text-sm font-semibold text-gray-700 mb-2">
                        Full Name <span class="text-red-500">*</span>
                    </label>
                    <input type="text" name="name" id="name" value="{{ old('name', $guard->user->name) }}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent @error('name') border-red-500 @enderror" placeholder="Guard's full name" required>
                    @error('name')
                        <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
                    @enderror
                </div>

                <!-- Phone -->
                <div>
                    <label for="phone" class="block text-sm font-semibold text-gray-700 mb-2">
                        Phone Number <span class="text-red-500">*</span>
                    </label>
                    <input type="tel" name="phone" id="phone" value="{{ old('phone', $guard->user->phone) }}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent @error('phone') border-red-500 @enderror" placeholder="01XXXXXXXXX" required>
                    @error('phone')
                        <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
                    @enderror
                </div>

                <!-- Email -->
                <div>
                    <label for="email" class="block text-sm font-semibold text-gray-700 mb-2">
                        Email Address <span class="text-gray-500 text-sm">(Optional)</span>
                    </label>
                    <input type="email" name="email" id="email" value="{{ old('email', $guard->user->email) }}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent @error('email') border-red-500 @enderror" placeholder="guard@example.com">
                    @error('email')
                        <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
                    @enderror
                </div>

                <!-- Status -->
                <div>
                    <label for="status" class="block text-sm font-semibold text-gray-700 mb-2">
                        Status <span class="text-red-500">*</span>
                    </label>
                    <select name="status" id="status" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent @error('status') border-red-500 @enderror">
                        <option value="off_duty" {{ old('status', $guard->status) === 'off_duty' ? 'selected' : '' }}>Off Duty</option>
                        <option value="on_duty" {{ old('status', $guard->status) === 'on_duty' ? 'selected' : '' }}>On Duty</option>
                        <option value="leave" {{ old('status', $guard->status) === 'leave' ? 'selected' : '' }}>On Leave</option>
                        <option value="inactive" {{ old('status', $guard->status) === 'inactive' ? 'selected' : '' }}>Inactive</option>
                    </select>
                    @error('status')
                        <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
                    @enderror
                </div>

                <!-- Notes -->
                <div>
                    <label for="notes" class="block text-sm font-semibold text-gray-700 mb-2">
                        Notes <span class="text-gray-500 text-sm">(Optional)</span>
                    </label>
                    <textarea name="notes" id="notes" rows="4" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-transparent @error('notes') border-red-500 @enderror" placeholder="Add any additional notes about this guard...">{{ old('notes', $guard->notes) }}</textarea>
                    @error('notes')
                        <p class="text-red-500 text-sm mt-1">{{ $message }}</p>
                    @enderror
                </div>

                <!-- Buttons -->
                <div class="flex gap-4 pt-6 border-t border-gray-200">
                    <a href="{{ route('admin.guards.show', $guard) }}" class="px-6 py-2 border border-gray-300 rounded-lg font-medium text-gray-700 hover:bg-gray-50 transition">
                        Cancel
                    </a>
                    <button type="submit" class="px-6 py-2 bg-primary hover:bg-blue-600 text-white rounded-lg font-medium transition">
                        Save Changes
                    </button>
                </div>
            </form>
        </div>
    </div>

    <!-- Sidebar -->
    <div class="lg:col-span-1">
        <!-- Guard Info Card -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 mb-6">
            <h3 class="text-lg font-bold text-gray-900 mb-4">Guard Info</h3>
            <div class="space-y-4">
                <div>
                    <p class="text-xs text-gray-600 uppercase tracking-wide">Building</p>
                    <p class="text-sm font-semibold text-gray-900">{{ $guard->building->name }}</p>
                </div>
                <div>
                    <p class="text-xs text-gray-600 uppercase tracking-wide">Guard ID</p>
                    <p class="text-sm font-semibold text-gray-900">#{{ $guard->id }}</p>
                </div>
                <div>
                    <p class="text-xs text-gray-600 uppercase tracking-wide">Current Status</p>
                    @php
                        $statusColors = [
                            'on_duty' => 'bg-green-100 text-green-800',
                            'off_duty' => 'bg-orange-100 text-orange-800',
                            'leave' => 'bg-blue-100 text-blue-800',
                            'inactive' => 'bg-red-100 text-red-800',
                        ];
                        $color = $statusColors[$guard->status] ?? 'bg-gray-100 text-gray-800';
                    @endphp
                    <span class="px-3 py-1 rounded-full text-xs font-semibold {{ $color }} inline-block mt-1">
                        {{ str_replace('_', ' ', ucfirst($guard->status)) }}
                    </span>
                </div>
                <div>
                    <p class="text-xs text-gray-600 uppercase tracking-wide">Joined</p>
                    <p class="text-sm font-semibold text-gray-900">{{ $guard->created_at->format('M d, Y') }}</p>
                </div>
            </div>
        </div>

        <!-- Danger Zone -->
        <div class="bg-red-50 border border-red-200 rounded-2xl p-6">
            <h3 class="text-lg font-bold text-red-900 mb-4">Danger Zone</h3>
            <p class="text-sm text-red-700 mb-4">Once you delete a guard, there is no going back.</p>
            <form action="{{ route('admin.guards.destroy', $guard) }}" method="POST" onsubmit="return confirm('Are you sure you want to delete {{ $guard->user->name }}? This action cannot be undone.');">
                @csrf
                @method('DELETE')
                <button type="submit" class="w-full px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium transition">
                    Delete Guard
                </button>
            </form>
        </div>
    </div>
</div>
@endsection
