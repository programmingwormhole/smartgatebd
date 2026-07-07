<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ config('app.name', 'SmartGateBD') }} - @yield('title', 'Admin Panel')</title>

    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.bunny.net">
    <link href="https://fonts.bunny.net/css?family=manrope:400,500,600,700,800&display=swap" rel="stylesheet" />

    <!-- Scripts -->
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="admin-body antialiased" x-data="{ sidebarOpen: false }">
    @php
        $navItems = [
            ['route' => 'admin.dashboard', 'active' => 'admin.dashboard', 'label' => 'Dashboard', 'icon' => 'M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z'],
            ['route' => 'admin.buildings.index', 'active' => 'admin.buildings.*', 'label' => 'Buildings', 'icon' => 'M3 21h18M5 21V7l7-4 7 4v14M9 9h6M9 13h6M9 17h6'],
            ['route' => 'admin.visitor-logs.index', 'active' => 'admin.visitor-logs.*', 'label' => 'Visitor Logs', 'icon' => 'M9 17v-2a4 4 0 0 1 4-4h4m0 0-2-2m2 2-2 2M5 21h6a2 2 0 0 0 2-2v-2a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v2a2 2 0 0 0 2 2zm3-11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z'],
            ['route' => 'admin.residents.index', 'active' => 'admin.residents.*', 'label' => 'Residents', 'icon' => 'M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5s-3 1.34-3 3 1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5C15 14.17 10.33 13 8 13zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.98 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z'],
            ['route' => 'admin.guards.index', 'active' => 'admin.guards.*', 'label' => 'Guards', 'icon' => 'M12 2 4 5v6c0 5.55 3.84 10.74 8 12 4.16-1.26 8-6.45 8-12V5l-8-3zm-1 14-4-4 1.41-1.41L11 13.17l5.59-5.58L18 9l-7 7z'],
            ['route' => 'admin.uploads.index', 'active' => 'admin.uploads.*', 'label' => 'File Uploads', 'icon' => 'M20 17v3H4v-3M12 3v12m0 0-4-4m4 4 4-4'],
            ['route' => 'admin.settings', 'active' => 'admin.settings', 'label' => 'Settings', 'icon' => 'M19.14 12.94a7.49 7.49 0 0 0 .05-.94 7.49 7.49 0 0 0-.05-.94l2.03-1.58a.5.5 0 0 0 .12-.64l-1.92-3.32a.5.5 0 0 0-.6-.22l-2.39.96a7.28 7.28 0 0 0-1.63-.94L14.5 2.5a.5.5 0 0 0-.5-.5h-4a.5.5 0 0 0-.5.5l-.36 2.82c-.58.23-1.13.54-1.63.94l-2.39-.96a.5.5 0 0 0-.6.22L2.6 8.84a.5.5 0 0 0 .12.64l2.03 1.58c-.03.31-.05.63-.05.94 0 .31.02.63.05.94L2.72 14.52a.5.5 0 0 0-.12.64l1.92 3.32c.13.22.39.31.6.22l2.39-.96c.5.4 1.05.71 1.63.94l.36 2.82c.04.25.25.44.5.44h4c.25 0 .46-.19.5-.44l.36-2.82c.58-.23 1.13-.54 1.63-.94l2.39.96c.23.09.48 0 .6-.22l1.92-3.32a.5.5 0 0 0-.12-.64l-2.03-1.58zM12 15.5A3.5 3.5 0 1 1 12 8a3.5 3.5 0 0 1 0 7.5z'],
        ];

        if ((auth()->user()?->role ?? null) !== 'superadmin') {
            $navItems = array_values(array_filter($navItems, fn ($item) => $item['route'] !== 'admin.visitor-logs.index'));
        }
    @endphp

    <div class="min-h-screen lg:grid lg:grid-cols-12">
        <div
            x-cloak
            x-show="sidebarOpen"
            class="fixed inset-0 z-30 bg-slate-900/50 backdrop-blur-[1px] lg:hidden"
            @click="sidebarOpen = false"
        ></div>

        <aside
            class="admin-sidebar fixed inset-y-0 left-0 z-40 w-72 -translate-x-full lg:static lg:col-span-3 xl:col-span-2 lg:w-auto lg:translate-x-0"
            :class="{ 'translate-x-0': sidebarOpen }"
        >
            <div class="admin-brand">
                <span class="admin-brand-mark">SG</span>
                <div>
                    <p class="admin-brand-title">SmartGateBD</p>
                    <p class="admin-brand-subtitle">Superadmin Workspace</p>
                </div>
            </div>

            <nav class="admin-nav">
                @foreach($navItems as $item)
                    <a
                        href="{{ route($item['route']) }}"
                        class="admin-nav-link {{ request()->routeIs($item['active']) ? 'is-active' : '' }}"
                    >
                        <svg class="h-5 w-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.8" d="{{ $item['icon'] }}"></path>
                        </svg>
                        <span>{{ $item['label'] }}</span>
                    </a>
                @endforeach
            </nav>

            <div class="admin-sidebar-footer">
                <div class="text-xs text-slate-500">Platform Health</div>
                <div class="mt-1 flex items-center gap-2 text-sm font-semibold text-emerald-600">
                    <span class="h-2.5 w-2.5 rounded-full bg-emerald-500"></span>
                    Operational
                </div>
            </div>
        </aside>

        <div class="flex min-h-screen flex-col lg:col-span-9 xl:col-span-10">
            <header class="admin-topbar">
                <div class="flex items-center gap-3">
                    <button
                        @click="sidebarOpen = !sidebarOpen"
                        class="inline-flex h-10 w-10 items-center justify-center rounded-xl border border-slate-200 text-slate-500 lg:hidden"
                    >
                        <svg class="h-5 w-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path>
                        </svg>
                    </button>
                    <div>
                        <h1 class="admin-page-title">@yield('header')</h1>
                        <p class="admin-page-subtitle">Operations overview and management tools</p>
                    </div>
                </div>

                <div class="relative" x-data="{ open: false }">
                    <button @click="open = !open" class="admin-user-menu-button">
                        <img src="https://ui-avatars.com/api/?name=Admin&background=0f172a&color=ffffff" alt="Admin" class="h-9 w-9 rounded-full border border-slate-200">
                        <div class="hidden text-left sm:block">
                            <p class="text-sm font-semibold text-slate-800">Admin</p>
                            <p class="text-xs text-slate-500">Superadmin</p>
                        </div>
                    </button>
                    <div
                        x-cloak
                        x-show="open"
                        @click.away="open = false"
                        class="absolute right-0 z-50 mt-2 w-52 rounded-xl border border-slate-200 bg-white p-2 shadow-xl"
                    >
                        <a href="{{ route('admin.settings') }}" class="admin-dropdown-link">Settings</a>
                        <form method="POST" action="{{ route('admin.logout') }}">
                            @csrf
                            <button type="submit" class="admin-dropdown-link w-full text-left text-red-600">Log Out</button>
                        </form>
                    </div>
                </div>
            </header>

            <main class="admin-content flex-1 p-4 sm:p-6 lg:p-8">
                @yield('content')
            </main>

            <footer class="admin-footer">
                <span>SmartGateBD Superadmin Dashboard</span>
                <span>{{ now()->format('Y') }} • Built for secure society operations</span>
            </footer>
        </div>
    </div>
</body>
</html>
