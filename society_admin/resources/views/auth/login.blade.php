<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ config('app.name', 'SmartGateBD') }} - Admin Login</title>
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="bg-gray-50 flex items-center justify-center min-h-screen text-gray-800 antialiased font-sans">
    
    <div class="w-full max-w-sm">
        <div class="text-center mb-8">
            <h1 class="text-3xl font-bold text-primary">SmartGateBD</h1>
            <p class="text-gray-500 mt-2">Superadmin Dashboard</p>
        </div>

        <div class="bg-white p-8 rounded-2xl shadow-sm border border-gray-100">
            <h2 class="text-xl font-semibold mb-6">Sign In</h2>
            
            @if ($errors->any())
                <div class="bg-red-50 text-red-600 p-3 rounded-lg mb-4 text-sm">
                    <ul>
                        @foreach ($errors->all() as $error)
                            <li>{{ $error }}</li>
                        @endforeach
                    </ul>
                </div>
            @endif

            <form method="POST" action="{{ route('admin.login.submit') }}">
                @csrf
                <div class="mb-4">
                    <label class="block text-sm font-medium mb-1" for="login">Email or Phone</label>
                    <input class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition" 
                           type="text" 
                           id="login" 
                           name="login"
                           value="{{ old('login', 'superadmin@smartgate.com') }}" 
                           required autofocus>
                </div>
                
                <div class="mb-6">
                    <label class="block text-sm font-medium mb-1" for="password">Password</label>
                    <input class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition" 
                           type="password" 
                           id="password" 
                           name="password" 
                           value="password"
                           required>
                </div>

                <button type="submit" class="w-full bg-primary hover:bg-blue-600 text-white font-medium py-2 px-4 rounded-lg transition duration-200">
                    Sign In
                </button>
            </form>
        </div>
    </div>

</body>
</html>
