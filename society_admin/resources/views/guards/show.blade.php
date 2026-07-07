@extends('layouts.app')

@section('title', 'Guard Details')
@section('header', 'Guard Details')

@section('content')
<div class="mb-8">
    <a href="{{ route('admin.guards.index') }}" class="text-primary hover:text-blue-700 font-medium flex items-center gap-2">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
        </svg>
        Back to Guards
    </a>
</div>

@if (session('success'))
    <div class="bg-green-50 border border-green-200 text-green-800 p-4 rounded-lg mb-6 flex items-start gap-3">
        <svg class="w-5 h-5 mt-0.5 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
        </svg>
        <div>{{ session('success') }}</div>
    </div>
@endif

<div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
    <!-- Main Content -->
    <div class="lg:col-span-2">
        <!-- Profile Card -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8 mb-6">
            <div class="flex items-start justify-between mb-8">
                <div class="flex items-center gap-6">
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
                             class="w-20 h-20 rounded-full object-cover">
                    @else
                        <div class="w-20 h-20 rounded-full bg-gradient-to-br from-green-400 to-green-600 flex items-center justify-center text-white font-bold text-3xl">
                            {{ substr($guard->user->name ?? 'G', 0, 1) }}
                        </div>
                    @endif
                    <div>
                        <h2 class="text-3xl font-bold text-gray-900">{{ $guard->user->name }}</h2>
                        <p class="text-gray-600 mt-1">Guard ID: #{{ $guard->id }}</p>
                    </div>
                </div>
                <a href="{{ route('admin.guards.edit', $guard) }}" class="px-4 py-2 bg-primary hover:bg-blue-600 text-white rounded-lg font-medium transition">
                    Edit
                </a>
            </div>

            <!-- Contact Information -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 pb-8 border-b border-gray-200">
                <div>
                    <p class="text-xs text-gray-600 uppercase tracking-wide mb-2">Phone Number</p>
                    <div class="flex items-center gap-3">
                        <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 00.948-.684l1.498-4.493a1 1 0 011.502-.684l1.498 4.493a1 1 0 00.948.684H17a2 2 0 012 2v2a2 2 0 01-2 2H5a2 2 0 01-2-2V5z"/>
                        </svg>
                        <p class="text-lg font-semibold text-gray-900">{{ $guard->user->phone }}</p>
                    </div>
                </div>

                <div>
                    <p class="text-xs text-gray-600 uppercase tracking-wide mb-2">Email Address</p>
                    <div class="flex items-center gap-3">
                        <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
                        </svg>
                        <p class="text-lg font-semibold text-gray-900">{{ $guard->user->email ?? 'N/A' }}</p>
                    </div>
                </div>
            </div>

            <!-- Status and Building -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 pt-8">
                <div>
                    <p class="text-xs text-gray-600 uppercase tracking-wide mb-2">Building</p>
                    <p class="text-lg font-semibold text-gray-900">{{ $guard->building->name }}</p>
                </div>

                <div>
                    <p class="text-xs text-gray-600 uppercase tracking-wide mb-2">Current Status</p>
                    @php
                        $statusColors = [
                            'on_duty' => 'bg-green-100 text-green-800',
                            'off_duty' => 'bg-orange-100 text-orange-800',
                            'leave' => 'bg-blue-100 text-blue-800',
                            'inactive' => 'bg-red-100 text-red-800',
                        ];
                        $color = $statusColors[$guard->status] ?? 'bg-gray-100 text-gray-800';
                    @endphp
                    <span class="px-4 py-2 rounded-full text-sm font-semibold {{ $color }} inline-block">
                        {{ str_replace('_', ' ', ucfirst($guard->status)) }}
                    </span>
                </div>
            </div>
        </div>

        <!-- Notes Section -->
        @if($guard->notes)
            <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-8">
                <h3 class="text-lg font-bold text-gray-900 mb-4">Notes</h3>
                <p class="text-gray-700 whitespace-pre-wrap">{{ $guard->notes }}</p>
            </div>
        @endif
    </div>

    <!-- Sidebar -->
    <div class="lg:col-span-1">
        <!-- Details Card -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 mb-6">
            <h3 class="text-lg font-bold text-gray-900 mb-4">Details</h3>
            <dl class="space-y-6">
                <div>
                    <dt class="text-xs text-gray-600 uppercase tracking-wide">Guard ID</dt>
                    <dd class="text-sm font-semibold text-gray-900 mt-1">#{{ $guard->id }}</dd>
                </div>
                <div>
                    <dt class="text-xs text-gray-600 uppercase tracking-wide">Building</dt>
                    <dd class="text-sm font-semibold text-gray-900 mt-1">{{ $guard->building->name }}</dd>
                </div>
                <div>
                    <dt class="text-xs text-gray-600 uppercase tracking-wide">Role</dt>
                    <dd class="text-sm font-semibold text-gray-900 mt-1">Security Guard</dd>
                </div>
                <div>
                    <dt class="text-xs text-gray-600 uppercase tracking-wide">Date Joined</dt>
                    <dd class="text-sm font-semibold text-gray-900 mt-1">{{ $guard->created_at->format('M d, Y \a\t H:i A') }}</dd>
                </div>
                <div>
                    <dt class="text-xs text-gray-600 uppercase tracking-wide">Last Updated</dt>
                    <dd class="text-sm font-semibold text-gray-900 mt-1">{{ $guard->updated_at->format('M d, Y \a\t H:i A') }}</dd>
                </div>
            </dl>
        </div>

        <!-- Status Actions -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 mb-6">
            <h3 class="text-lg font-bold text-gray-900 mb-4">Quick Actions</h3>
            <div class="space-y-2">
                <a href="{{ route('admin.guards.edit', $guard) }}" class="block px-4 py-2 bg-primary hover:bg-blue-600 text-white rounded-lg font-medium text-center transition">
                    Edit Guard
                </a>
                <form action="{{ route('admin.guards.destroy', $guard) }}" method="POST" onsubmit="return confirm('Are you sure you want to delete this guard?');">
                    @csrf
                    @method('DELETE')
                    <button type="submit" class="block w-full px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium transition">
                        Delete Guard
                    </button>
                </form>
            </div>
        </div>

        <!-- User Account Info -->
        <div class="bg-blue-50 border border-blue-200 rounded-2xl p-6">
            <h3 class="text-sm font-bold text-blue-900 mb-3">Login Information</h3>
            <ul class="text-sm text-blue-800 space-y-2">
                <li><strong>Username:</strong> {{ $guard->user->phone }}</li>
                <li><strong>Default Password:</strong> Same as phone</li>
                <li>Guard can change password after first login</li>
            </ul>
        </div>
    </div>
</div>
@endsection
