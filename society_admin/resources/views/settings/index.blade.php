@extends('layouts.app')

@section('title', 'System Settings')
@section('header', 'System Settings')

@section('content')
<div class="max-w-4xl">

    @if (session('success'))
        <div class="bg-green-50 text-green-700 p-4 rounded-xl mb-6 flex items-center gap-3">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
            {{ session('success') }}
        </div>
    @endif

    <form method="POST" action="{{ route('admin.settings.update') }}">
        @csrf
        
        <!-- General Configuration -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 md:p-8 mb-6">
            <h2 class="text-xl font-semibold mb-6 flex items-center gap-2">
                <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                General Settings
            </h2>
            
            <div class="space-y-6">
                <div>
                    <label class="block text-sm font-medium mb-1" for="app_name">Application Name</label>
                    <input type="text" id="app_name" name="app_name" value="{{ $settings['app_name'] ?? 'SmartGateBD' }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                </div>

                <div class="flex items-center gap-3 bg-red-50 p-4 rounded-xl border border-red-100">
                    <input type="checkbox" id="maintenance_mode" name="maintenance_mode" value="true" class="w-5 h-5 text-red-600 rounded focus:ring-red-500" {{ isset($settings['maintenance_mode']) && $settings['maintenance_mode'] === '1' ? 'checked' : '' }}>
                    <div>
                        <label for="maintenance_mode" class="font-medium text-red-800">Enable Maintenance Mode</label>
                        <p class="text-sm text-red-600">When enabled, the application will display a maintenance view for all users except Superadmins.</p>
                    </div>
                </div>
            </div>
        </div>

        <!-- SMTP Configuration -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 md:p-8 mb-6">
            <h2 class="text-xl font-semibold mb-6 flex items-center gap-2">
                <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                SMTP Email Configuration
            </h2>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                    <label class="block text-sm font-medium mb-1" for="mail_host">Mail Host</label>
                    <input type="text" id="mail_host" name="mail_host" value="{{ $settings['mail_host'] ?? '' }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition" placeholder="smtp.mailtrap.io">
                </div>
                <div>
                    <label class="block text-sm font-medium mb-1" for="mail_port">Mail Port</label>
                    <input type="text" id="mail_port" name="mail_port" value="{{ $settings['mail_port'] ?? '587' }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                </div>
                <div>
                    <label class="block text-sm font-medium mb-1" for="mail_username">Mail Username</label>
                    <input type="text" id="mail_username" name="mail_username" value="{{ $settings['mail_username'] ?? '' }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                </div>
                <div>
                    <label class="block text-sm font-medium mb-1" for="mail_password">Mail Password</label>
                    <input type="password" id="mail_password" name="mail_password" value="{{ $settings['mail_password'] ?? '' }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                </div>
                <div>
                    <label class="block text-sm font-medium mb-1" for="mail_encryption">Encryption (tls/ssl)</label>
                    <input type="text" id="mail_encryption" name="mail_encryption" value="{{ $settings['mail_encryption'] ?? 'tls' }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                </div>
                <!-- Empty div for alignment on large screens if desired -->
                <div class="hidden md:block"></div> 

                <div>
                    <label class="block text-sm font-medium mb-1" for="mail_from_address">From Address</label>
                    <input type="email" id="mail_from_address" name="mail_from_address" value="{{ $settings['mail_from_address'] ?? 'noreply@smartgatebd.com' }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                </div>
                <div>
                    <label class="block text-sm font-medium mb-1" for="mail_from_name">From Name</label>
                    <input type="text" id="mail_from_name" name="mail_from_name" value="{{ $settings['mail_from_name'] ?? 'SmartGateBD' }}" class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition">
                </div>
            </div>
        </div>

        <!-- SMS & OTP Configuration -->
        <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 md:p-8 mb-6">
            <h2 class="text-xl font-semibold mb-6 flex items-center gap-2">
                <svg class="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>
                OTP & SMS Configuration
            </h2>
            
            <div class="space-y-6">
                <div class="flex items-center gap-3 bg-gray-50 p-4 rounded-xl border border-gray-100">
                    <input type="checkbox" id="otp_enabled" name="otp_enabled" value="true" class="w-5 h-5 text-primary rounded focus:ring-primary" {{ isset($settings['otp_enabled']) && $settings['otp_enabled'] === '1' ? 'checked' : '' }}>
                    <div>
                        <label for="otp_enabled" class="font-medium">Enable OTP Verification</label>
                        <p class="text-sm text-gray-500">Require users to verify their phone numbers during registration.</p>
                    </div>
                </div>

                <div class="flex items-center gap-3 bg-gray-50 p-4 rounded-xl border border-gray-100">
                    <input type="checkbox" id="bulksms_enabled" name="bulksms_enabled" value="true" class="w-5 h-5 text-primary rounded focus:ring-primary" {{ isset($settings['bulksms_enabled']) && $settings['bulksms_enabled'] === '1' ? 'checked' : '' }}>
                    <div>
                        <label for="bulksms_enabled" class="font-medium">Enable BulkSMSBD Gateway</label>
                        <p class="text-sm text-gray-500">Use BulkSMSBD for sending OTP codes instead of appending to laravel.log.</p>
                    </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-6 bg-gray-50 p-6 rounded-xl border border-gray-100">
                    <div>
                        <label class="block text-sm font-medium mb-1" for="bulksms_api_key">BulkSMSBD API Key</label>
                        <input type="text" id="bulksms_api_key" name="bulksms_api_key" value="{{ $settings['bulksms_api_key'] ?? '' }}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition bg-white">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1" for="bulksms_sender_id">Sender ID</label>
                        <input type="text" id="bulksms_sender_id" name="bulksms_sender_id" value="{{ $settings['bulksms_sender_id'] ?? '' }}" class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition bg-white">
                    </div>
                </div>
            </div>
        </div>

        <div class="flex justify-end sticky bottom-6 z-10">
            <button type="submit" class="bg-primary hover:bg-blue-600 text-white font-medium py-3 px-8 rounded-xl shadow-lg transition duration-200 flex items-center gap-2">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"></path></svg>
                Save All Configurations
            </button>
        </div>
    </form>
</div>
@endsection
