<?php

namespace App\Services;

use App\Models\SystemConfiguration;

class SystemConfigurationService
{
    public function get(string $key, $default = null)
    {
        $config = SystemConfiguration::where('key', $key)->first();
        return $config ? $config->value : $default;
    }

    public function set(string $key, $value)
    {
        return SystemConfiguration::updateOrCreate(
            ['key' => $key],
            ['value' => $value]
        );
    }
}
