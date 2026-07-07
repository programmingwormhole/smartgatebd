<?php

namespace App\Http\Controllers;

use App\Models\Bill;
use App\Models\BillPayment;
use App\Services\PaymentService;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    protected $paymentService;

    public function __construct(PaymentService $paymentService)
    {
        $this->paymentService = $paymentService;
    }

    public function store(Request $request, Bill $bill)
    {
        $data = $request->validate([
            'amount' => 'required|numeric',
            'method' => 'required|in:cash,gateway',
            'payment_gateway_id' => 'nullable|required_if:method,gateway|exists:payment_gateways,id',
            'trx_id' => 'nullable|required_if:method,gateway|string',
            'notes' => 'nullable|string|max:1000',
            // 'screenshot' => 'required|file|image|max:5120' // 5MB limit
        ]);

        $isCashPayment = $data['method'] === 'cash';

        $paymentData = [
            'amount' => $data['amount'],
            'method' => $data['method'],
            'payment_gateway_id' => $isCashPayment ? null : $data['payment_gateway_id'],
            'trx_id' => $isCashPayment ? null : $data['trx_id'],
            'notes' => $isCashPayment ? ($data['notes'] ?? null) : null,
        ];

        $payment = $this->paymentService->recordPayment(
            $bill,
            $paymentData,
            // $request->file('screenshot')
        );

        // Get building ID
        $buildingId = $bill->flat->floor->block->building_id;

        // Notify User - payment submitted for review
        if ($bill->resident && $bill->resident->user) {
            \App\Http\Controllers\NotificationController::createNotification(
                $bill->resident->user->id,
                $isCashPayment ? 'Cash Payment Submitted' : 'Payment Submitted',
                $isCashPayment
                    ? 'Your cash payment of ৳' . number_format($payment->amount, 2) . ' for bill #' . $bill->id . ' has been submitted and is awaiting admin approval.'
                    : 'Your payment of ৳' . number_format($payment->amount, 2) . ' for bill #' . $bill->id . ' has been submitted and is awaiting admin approval.',
                'info',
                'payment',
                $payment->id
            );
        }

        // Notify Admins - new payment to review
        $adminUsers = \App\Helpers\NotificationHelper::getBuildingAdmins($buildingId);

        foreach ($adminUsers as $admin) {
            \App\Http\Controllers\NotificationController::createNotification(
                $admin->id,
                $isCashPayment ? 'New Cash Payment Submitted' : 'New Payment Submitted',
                $isCashPayment
                    ? "Cash payment for bill #{$bill->id} has been submitted for approval."
                    : "Payment for bill #{$bill->id} has been submitted for approval.",
                'info',
                'payment',
                $payment->id
            );
        }

        // Send push notification to admins
        $firebase = app(\App\Services\FirebaseService::class);
        $firebase->sendToTopic(
            "building_{$buildingId}_admins",
            $isCashPayment ? 'New Cash Payment Submitted' : 'New Payment Submitted',
            $isCashPayment
                ? "Cash payment for bill #{$bill->id} has been submitted for approval."
                : "Payment for bill #{$bill->id} has been submitted for approval.",
            ['type' => 'payment', 'id' => (string)$payment->id]
        );

        return response()->json($payment, 201);
    }

    public function show(BillPayment $payment)
    {
        return response()->json($payment->load('bill'));
    }
}
