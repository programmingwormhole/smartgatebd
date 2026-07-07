<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\SystemConfiguration;
use App\Services\SystemConfigurationService;
use Illuminate\Support\Facades\Artisan;

class SettingController extends Controller
{
    protected $configService;

    public function __construct(SystemConfigurationService $configService)
    {
        $this->configService = $configService;
    }

    public function index()
    {
        $settings = SystemConfiguration::all()->pluck('config_value', 'config_key')->toArray();
        return view('settings.index', compact('settings'));
    }

    public function update(Request $request)
    {
        // $rules = [
        //     'app_name' => 'nullable|string|max:255',
        //     'maintenance_mode' => 'nullable|boolean',
        //     'otp_enabled' => 'nullable|boolean',
        //     'bulksms_enabled' => 'nullable|boolean',
        //     'bulksms_api_key' => 'nullable|string',
        //     'bulksms_sender_id' => 'nullable|string',
        //     'mail_host' => 'nullable|string',
        //     'mail_port' => 'nullable|string',
        //     'mail_username' => 'nullable|string',
        //     'mail_password' => 'nullable|string',
        //     'mail_encryption' => 'nullable|string',
        //     'mail_from_address' => 'nullable|email',
        //     'mail_from_name' => 'nullable|string',
        // ];

        // $request->validate($rules);
        

        // Booleans
        $this->configService->set('maintenance_mode', $request->has('maintenance_mode') ? '1' : '0');
        $this->configService->set('otp_enabled', $request->has('otp_enabled') ? '1' : '0');
        $this->configService->set('bulksms_enabled', $request->has('bulksms_enabled') ? '1' : '0');
        
        // Strings
        $stringKeys = [
            'app_name', 'bulksms_api_key', 'bulksms_sender_id',
            'mail_host', 'mail_port', 'mail_username', 'mail_password', 
            'mail_encryption', 'mail_from_address', 'mail_from_name'
        ];

        foreach ($stringKeys as $key) {
            if ($request->has($key)) {
                $this->configService->set($key, $request->get($key));
            }
        }

        Artisan::call('config:clear');

        return redirect()->back()->with('success', 'Settings updated successfully.');
    }
}
