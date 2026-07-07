<?php

namespace App\Services;

use App\Models\Visitor;
use App\Models\Gatepass;

class VisitorService
{
    protected $gatepassService;

    public function __construct(GatepassService $gatepassService)
    {
        $this->gatepassService = $gatepassService;
    }

    public function approve(Visitor $visitor)
    {
        // TODO:: On approve push notification trigger to resident.
        $visitor->update(['status' => 'approved']);
        return $this->gatepassService->generateForVisitor($visitor->id);
    }

    public function reject(Visitor $visitor, ?string $reason = null)
    {
        // TODO:: On reject also.
        $visitor->update(['status' => 'rejected']);
        return $visitor;
    }
}
