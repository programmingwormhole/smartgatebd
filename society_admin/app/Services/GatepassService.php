<?php

namespace App\Services;

use App\Models\Gatepass;
use Illuminate\Support\Str;

class GatepassService
{
    public function generateForVisitor($visitorId)
    {
        $code = strtoupper(Str::random(10));
        $entryCode = rand(100000, 999999);
        
        // Mock QR path for now
        $qrPath = "qrcodes/" . $code . ".png";

        return Gatepass::create([
            'visitor_id' => $visitorId,
            'gatepass_code' => $code,
            'entry_code' => $entryCode,
            'qr_code' => $qrPath
        ]);
    }
}
