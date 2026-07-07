<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use App\Services\SystemConfigurationService;

class CheckMaintenanceMode
{
    protected $configService;

    public function __construct(SystemConfigurationService $configService)
    {
        $this->configService = $configService;
    }

    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $isMaintenanceEnabled = $this->configService->get('maintenance_mode', false);

        // If maintenance is enabled, and the URL does not start with 'admin'
        if ($isMaintenanceEnabled) {
            
            // Allow admin panel access to continue managing the system
            if ($request->is('login') || $request->is('logout') || $request->is('admin*') || $request->is('settings*') || $request->is('buildings*') || $request->is('uploads*') || $request->is('dashboard*') || $request->is('/')) {
                return $next($request);
            }

            if ($request->expectsJson() || $request->is('api/*')) {
                return response()->json([
                    'success' => false,
                    'message' => 'System is currently under maintenance. Please try again later.'
                ], 503);
            }

            // For web non-admin requests
            abort(503, 'System is currently under maintenance.');
        }

        return $next($request);
    }
}
