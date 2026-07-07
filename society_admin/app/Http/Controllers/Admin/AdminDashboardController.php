<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Resident;
use App\Models\Bill;
use App\Models\BillPayment;
use App\Models\Complaint;
use App\Models\Visitor;
use Carbon\Carbon;

class AdminDashboardController extends Controller
{
    public function stats(Request $request)
    {
        $buildingId = $request->user()->building_id;

        $totalResidents = Resident::whereHas('flat.floor.block.building', function ($q) use ($buildingId) {
            $q->where('id', $buildingId);
        })->count();

        $pendingBillsCount = Bill::whereHas('flat.floor.block.building', function ($q) use ($buildingId) {
            $q->where('id', $buildingId);
        })->where('status', 'pending_for_approval')->count();

        $openComplaints = Complaint::whereHas('resident.flat.floor.block.building', function ($q) use ($buildingId) {
            $q->where('id', $buildingId);
        })->where('status', 'open')->count();

        $recentVisitors = Visitor::whereHas('resident.flat.floor.block.building', function ($q) use ($buildingId) {
            $q->where('id', $buildingId);
        })->whereDate('from_date', Carbon::today())->count();

        return response()->json([
            'stats' => [
                'total_residents' => $totalResidents,
                'pending_payments' => $pendingBillsCount,
                'open_complaints' => $openComplaints,
                'visitors_today' => $recentVisitors,
            ]
        ]);
    }

    public function pendingManualPayments(Request $request)
    {
        $buildingId = $request->user()->building_id;

        // Fetch pending bill payments that belong to this building
        $payments = BillPayment::with(['bill.flat.floor.block.building', 'bill.flat.residents.user', 'gateway'])
            ->whereHas('bill.flat.floor.block.building', function ($q) use ($buildingId) {
                $q->where('id', $buildingId);
            })
            ->where('status', 'pending')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['payments' => $payments]);
    }

    public function approvePayment(BillPayment $payment, Request $request)
    {
        $payment->load('bill.flat.residents.user.fcmTokens');

        $payment->update(['status' => 'approved']);
        $payment->bill->update(['status' => 'paid']);

        // Trigger Notification
        if ($payment->bill->flat && $payment->bill->flat->residents->isNotEmpty()) {
            $resident = $payment->bill->flat->residents->first();
            if ($resident->user) {
                \App\Http\Controllers\NotificationController::createNotification(
                    $resident->user->id,
                    'Payment Approved',
                    'Your payment of ৳' . $payment->amount . ' for ' . $payment->bill->month_year . ' has been approved.',
                    'success',
                    'bill',
                    $payment->bill->id
                );

                $tokens = $resident->user->fcmTokens->pluck('device_token')->toArray();
                if (!empty($tokens)) {
                    $firebase = app(\App\Services\FirebaseService::class);
                    $firebase->sendNotification(
                        $tokens,
                        'Payment Approved',
                        'Your payment of ৳' . $payment->amount . ' for ' . $payment->bill->month_year . ' has been approved.',
                        ['type' => 'bill', 'bill_id' => (string)$payment->bill->id]
                    );
                }
            }
        }

        return response()->json(['message' => 'Payment approved successfully']);
    }

    public function rejectPayment(BillPayment $payment, Request $request)
    {
        $request->validate(['rejection_reason' => 'required|string']);

        $payment->load('bill.flat.residents.user.fcmTokens');

        $payment->update([
            'status' => 'rejected',
            'rejection_reason' => $request->rejection_reason,
        ]);
        $payment->bill->update(['status' => 'unpaid']);

        // Trigger Notification
        if ($payment->bill->flat && $payment->bill->flat->residents->isNotEmpty()) {
            $resident = $payment->bill->flat->residents->first();
            if ($resident->user) {
                \App\Http\Controllers\NotificationController::createNotification(
                    $resident->user->id,
                    'Payment Rejected',
                    'Your payment of ৳' . $payment->amount . ' for ' . $payment->bill->month_year . ' was rejected: ' . $request->rejection_reason,
                    'alert',
                    'bill',
                    $payment->bill->id
                );

                $tokens = $resident->user->fcmTokens->pluck('device_token')->toArray();
                if (!empty($tokens)) {
                    $firebase = app(\App\Services\FirebaseService::class);
                    $firebase->sendNotification(
                        $tokens,
                        'Payment Rejected',
                        'Your payment of ৳' . $payment->amount . ' for ' . $payment->bill->month_year . ' was rejected: ' . $request->rejection_reason,
                        ['type' => 'bill', 'bill_id' => (string)$payment->bill->id]
                    );
                }
            }
        }

        return response()->json(['message' => 'Payment rejected successfully']);
    }
}
