<?php

namespace App\Services;

use App\Models\BillPayment;
use App\Models\Bill;
use Illuminate\Http\UploadedFile;

class PaymentService
{
    public function recordPayment(Bill $bill, array $data)
    {
        $payment = $bill->payments()->create($data);

        // Manual payment: status changes to pending_for_approval
        $bill->update(['status' => 'pending_for_approval']);

        return $payment;
    }
}
