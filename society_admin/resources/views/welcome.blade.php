<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>SmartGateBD - Welcome</title>
        <!-- Fonts -->
        <link rel="preconnect" href="https://fonts.bunny.net">
        <link href="https://fonts.bunny.net/css?family=figtree:400,600&display=swap" rel="stylesheet" />
        <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body class="antialiased bg-gray-100 flex items-center justify-center min-h-screen">
        <div class="max-w-4xl w-full mx-auto p-6 lg:p-8">
            <div class="bg-white overflow-hidden shadow-sm sm:rounded-lg p-8 text-center">
                <h1 class="text-4xl font-bold text-gray-900 mb-4">Welcome to SmartGateBD</h1>
                <p class="text-lg text-gray-600 mb-10">Select your portal to log in to the system.</p>

                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                    <!-- Superadmin -->
                    <a href="/superadmin/dashboard" class="group flex flex-col items-center justify-center p-6 bg-blue-50 rounded-xl hover:bg-blue-100 transition-colors border border-blue-200">
                        <div class="w-16 h-16 bg-blue-500 rounded-full flex items-center justify-center mb-4 text-white">
                            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 002-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path></svg>
                        </div>
                        <h2 class="text-xl font-semibold text-blue-900">SaaS Admin</h2>
                        <span class="text-sm text-blue-700 mt-2">Manage System</span>
                    </a>

                    <!-- Building Admin -->
                    <a href="/admin" class="group flex flex-col items-center justify-center p-6 bg-indigo-50 rounded-xl hover:bg-indigo-100 transition-colors border border-indigo-200">
                        <div class="w-16 h-16 bg-indigo-500 rounded-full flex items-center justify-center mb-4 text-white">
                            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path></svg>
                        </div>
                        <h2 class="text-xl font-semibold text-indigo-900">Building Admin</h2>
                        <span class="text-sm text-indigo-700 mt-2">Manage Society</span>
                    </a>

                    <!-- Resident -->
                    <a href="/resident" class="group flex flex-col items-center justify-center p-6 bg-green-50 rounded-xl hover:bg-green-100 transition-colors border border-green-200">
                        <div class="w-16 h-16 bg-green-500 rounded-full flex items-center justify-center mb-4 text-white">
                            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path></svg>
                        </div>
                        <h2 class="text-xl font-semibold text-green-900">Resident</h2>
                        <span class="text-sm text-green-700 mt-2">Manage Home</span>
                    </a>

                    <!-- Guard -->
                    <a href="/guard" class="group flex flex-col items-center justify-center p-6 bg-orange-50 rounded-xl hover:bg-orange-100 transition-colors border border-orange-200">
                        <div class="w-16 h-16 bg-orange-500 rounded-full flex items-center justify-center mb-4 text-white">
                            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
                        </div>
                        <h2 class="text-xl font-semibold text-orange-900">Guard</h2>
                        <span class="text-sm text-orange-700 mt-2">Manage Gates</span>
                    </a>
                </div>
            </div>
        </div>
    </body>
</html>
