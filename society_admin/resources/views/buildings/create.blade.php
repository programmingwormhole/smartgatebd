@extends('layouts.app')

@section('title', 'Add Building')
@section('header', 'Add Building')

@section('content')
<div class="max-w-4xl">
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 md:p-8">
        
        @if ($errors->any())
            <div class="bg-red-50 text-red-600 p-4 rounded-xl mb-6 text-sm">
                <ul class="list-disc pl-5">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form method="POST" action="{{ route('admin.buildings.store') }}">
            @csrf
            
            <h3 class="text-lg font-semibold text-gray-700 mb-4 border-b pb-2">Building Details</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                <div class="md:col-span-2">
                    <label class="block text-sm font-medium mb-1" for="building_name">Building Name</label>
                    <input type="text" id="building_name" name="building_name" value="{{ old('building_name') }}" required class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                </div>
                <div class="md:col-span-2">
                    <label class="block text-sm font-medium mb-1" for="address">Address</label>
                    <textarea id="address" name="address" rows="3" required class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">{{ old('address') }}</textarea>
                </div>
            </div>

            <h3 class="text-lg font-semibold text-gray-700 mb-4 border-b pb-2">Building Admin Credentials</h3>
            <p class="text-sm text-gray-500 mb-4">A new user account will be created with Admin privileges for this building.</p>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                <div class="md:col-span-2">
                    <label class="block text-sm font-medium mb-1" for="admin_name">Admin Full Name</label>
                    <input type="text" id="admin_name" name="admin_name" value="{{ old('admin_name') }}" required class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                </div>
                
                <div>
                    <label class="block text-sm font-medium mb-1" for="admin_email">Admin Email (Login)</label>
                    <input type="email" id="admin_email" name="admin_email" value="{{ old('admin_email') }}" required class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                </div>
                
                <div>
                    <label class="block text-sm font-medium mb-1" for="admin_phone">Admin Phone</label>
                    <input type="text" id="admin_phone" name="admin_phone" value="{{ old('admin_phone') }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition" placeholder="Optional">
                </div>
                
                <div class="md:col-span-2">
                    <label class="block text-sm font-medium mb-1" for="admin_password">Admin Password</label>
                    <input type="password" id="admin_password" name="admin_password" required class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                </div>
            </div>

            <div class="flex justify-end gap-3">
                <a href="{{ route('admin.buildings.index') }}" class="px-6 py-2 border rounded-lg text-gray-600 hover:bg-gray-50 transition font-medium">Cancel</a>
                <button type="submit" class="bg-primary hover:bg-blue-600 text-white font-medium py-2 px-6 rounded-lg transition duration-200">
                    Create Building & Admin
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
