<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Bill;
use App\Models\Flat;
use App\Models\BillPayment;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class AdminBillController extends Controller
{
    /**
     * Get all bills for the admin's building
     */
    public function index(Request $request)
    {
        $buildingId = $request->user()->building_id;

        $bills = Bill::whereHas('flat.floor.block', function ($q) use ($buildingId) {
            $q->where('building_id', $buildingId);
        })
        ->with('flat.residents.user', 'payments')
        ->orderBy('created_at', 'desc')
        ->paginate(20);

        return response()->json([
            'bills' => $bills->items(),
            'total' => $bills->total(),
            'current_page' => $bills->currentPage(),
            'last_page' => $bills->lastPage()
        ]);
    }

    /**
     * Get detailed statistics for a specific bill
     */
    public function show(Request $request, Bill $bill)
    {
        $buildingId = $request->user()->building_id;

        // Verify bill belongs to admin's building
        if ($bill->flat->floor->block->building_id !== $buildingId) {
            return response()->json(['message' => 'Unauthorized access'], 403);
        }

        // Load relationships
        $bill->load('flat.residents.user', 'payments.gateway');

        // Calculate statistics
        $totalAmount = $bill->amount;
        $totalCollected = $bill->payments->where('status', 'approved')->sum('amount');
        $totalPending = $bill->payments->where('status', 'pending_approval')->sum('amount');
        $totalUnpaid = $totalAmount - $totalCollected - $totalPending;

        $statistics = [
            'total_amount' => $totalAmount,
            'total_collected' => $totalCollected,
            'total_pending' => $totalPending,
            'total_unpaid' => max(0, $totalUnpaid),
            'collection_percentage' => $totalAmount > 0 ? round(($totalCollected / $totalAmount) * 100, 2) : 0,
            'total_payments' => $bill->payments->count(),
            'approved_payments' => $bill->payments->where('status', 'approved')->count(),
            'pending_payments' => $bill->payments->where('status', 'pending_approval')->count(),
        ];

        // Get resident details who owe
        $residentDetails = [];
        foreach ($bill->flat->residents as $resident) {
            $residentPayment = $bill->payments
                ->where('bill_id', $bill->id)
                ->first();

            $status = 'unpaid';
            $amountPaid = 0;

            if ($residentPayment) {
                if ($residentPayment->status === 'approved') {
                    $status = 'paid';
                    $amountPaid = $residentPayment->amount;
                } elseif ($residentPayment->status === 'pending_approval') {
                    $status = 'pending';
                    $amountPaid = $residentPayment->amount;
                }
            }

            $residentDetails[] = [
                'resident_id' => $resident->id,
                'resident_name' => $resident->user?->name,
                'flat_number' => $bill->flat->flat_number,
                'status' => $status,
                'amount_due' => $totalAmount,
                'amount_paid' => $amountPaid,
                'amount_remaining' => max(0, $totalAmount - $amountPaid),
            ];
        }

        return response()->json([
            'bill' => $bill,
            'statistics' => $statistics,
            'resident_details' => $residentDetails,
            'payments' => $bill->payments,
        ]);
    }

    /**
     * Mark a bill as paid manually by admin with an optional note.
     */
    public function markAsPaid(Request $request, Bill $bill)
    {
        $request->validate([
            'note' => 'nullable|string|max:1000',
        ]);

        $buildingId = $request->user()->building_id;

        if ($bill->flat->floor->block->building_id !== $buildingId) {
            return response()->json(['message' => 'Unauthorized access'], 403);
        }

        if ($bill->status === 'paid') {
            return response()->json(['message' => 'Bill is already marked as paid']);
        }

        $note = trim((string) $request->input('note', ''));

        $payment = DB::transaction(function () use ($bill, $note) {
            $pendingPayment = $bill->payments()
                ->where('status', 'pending')
                ->latest('id')
                ->first();

            if ($pendingPayment) {
                $updatedNote = $pendingPayment->notes;
                if ($note !== '') {
                    $updatedNote = trim(($pendingPayment->notes ? $pendingPayment->notes . "\n" : '') . 'Admin note: ' . $note);
                }

                $pendingPayment->update([
                    'status' => 'approved',
                    'notes' => $updatedNote,
                ]);

                $payment = $pendingPayment;
            } else {
                $payment = BillPayment::create([
                    'bill_id' => $bill->id,
                    'payment_gateway_id' => null,
                    'amount' => $bill->amount,
                    'method' => 'cash',
                    'trx_id' => null,
                    'notes' => $note !== '' ? 'Admin marked paid. ' . $note : 'Admin marked paid.',
                    'status' => 'approved',
                ]);
            }

            $bill->update(['status' => 'paid']);

            return $payment;
        });

        $bill->load('flat.residents.user.fcmTokens');

        if ($bill->flat && $bill->flat->residents->isNotEmpty()) {
            $resident = $bill->flat->residents->first();
            if ($resident->user) {
                $message = 'Your bill for ' . $bill->month_year . ' has been marked as paid by admin.';
                if ($note !== '') {
                    $message .= ' Note: ' . $note;
                }

                \App\Http\Controllers\NotificationController::createNotification(
                    $resident->user->id,
                    'Bill Marked Paid',
                    $message,
                    'success',
                    'bill',
                    $bill->id
                );

                $tokens = $resident->user->fcmTokens->pluck('device_token')->toArray();
                if (!empty($tokens)) {
                    $firebase = app(\App\Services\FirebaseService::class);
                    $firebase->sendNotification(
                        $tokens,
                        'Bill Marked Paid',
                        $message,
                        ['type' => 'bill', 'bill_id' => (string) $bill->id]
                    );
                }
            }
        }

        return response()->json([
            'message' => 'Bill marked as paid successfully',
            'bill' => $bill,
            'payment' => $payment,
        ]);
    }

    /**
     * Generate a bill for a specific flat.
     */
    public function generateForFlat(Request $request, Flat $flat)
    {
        $request->validate([
            'type' => 'required|string|in:maintenance,utility,security,other',
            'amount' => 'required|numeric|min:0',
            'month_year' => 'required|string', // e.g., "March 2026"
            'due_date' => 'required|date',
            'description' => 'nullable|string'
        ]);

        // Check if building matches admin's building
        if ($flat->floor->block->building_id !== $request->user()->building_id) {
            return response()->json(['message' => 'Unauthorized flat access'], 403);
        }

        $bill = $flat->bills()->create([
            'type' => $request->type,
            'amount' => $request->amount,
            'month_year' => $request->month_year,
            'due_date' => $request->due_date,
            'status' => 'unpaid',
            'description' => $request->description,
        ]);

        // Trigger Notification to Resident if any
        $this->notifyResidentAboutBill($flat, $bill);

        return response()->json(['message' => 'Bill generated successfully', 'bill' => $bill], 201);
    }

    /**
     * Mass generate bills for all occupied flats in the admin's building.
     */
    public function generateBulk(Request $request)
    {
        $request->validate([
            'type' => 'required|string|in:maintenance,utility,security,other',
            'amount' => 'required|numeric|min:0',
            'month_year' => 'required|string',
            'due_date' => 'required|date',
            'description' => 'nullable|string'
        ]);

        $buildingId = $request->user()->building_id;

        // Get all flats that have at least one resident
        $flats = Flat::whereHas('floor.block.building', function ($q) use ($buildingId) {
            $q->where('id', $buildingId);
        })->whereHas('residents')->get();

        $generatedCount = 0;

        foreach ($flats as $flat) {
            // Check if a bill of this type for this month already exists to avoid duplicates
            $exists = Bill::where('flat_id', $flat->id)
                ->where('type', $request->type)
                ->where('month_year', $request->month_year)
                ->exists();

            if (!$exists) {
                $bill = $flat->bills()->create([
                    'type' => $request->type,
                    'amount' => $request->amount,
                    'month_year' => $request->month_year,
                    'due_date' => $request->due_date,
                    'status' => 'unpaid',
                    'description' => $request->description,
                ]);

                // Notify residents about the new bill (both database + push notifications)
                $this->notifyResidentAboutBill($flat, $bill);
                $generatedCount++;
            }
        }

        return response()->json([
            'message' => "Successfully generated $generatedCount bills.",
            'generated_count' => $generatedCount
        ], 201);
    }

    /**
     * Helper to notify residents about new bills (database + push notifications).
     */
    private function notifyResidentAboutBill(Flat $flat, Bill $bill)
    {
        if ($flat->residents->isNotEmpty()) {
            foreach ($flat->residents as $resident) {
                if ($resident->user) {
                    // Create database notification
                    \App\Http\Controllers\NotificationController::createNotification(
                        $resident->user->id,
                        'New Bill Generated',
                        'A new ' . ucfirst($bill->type) . ' bill of ৳' . number_format($bill->amount, 2) . ' has been generated for ' . $bill->month_year . '. Due: ' . \Carbon\Carbon::parse($bill->due_date)->format('d M, Y'),
                        'info',
                        'bill',
                        $bill->id
                    );

                    // Send push notification if tokens available
                    if ($resident->user->fcmTokens && $resident->user->fcmTokens->isNotEmpty()) {
                        $tokens = $resident->user->fcmTokens->pluck('device_token')->toArray();
                        try {
                            $firebase = app(\App\Services\FirebaseService::class);
                            $firebase->sendNotification(
                                $tokens,
                                'New Bill Generated',
                                'A new ' . $bill->type . ' bill of ৳' . $bill->amount . ' has been generated for ' . $bill->month_year . '. Due: ' . \Carbon\Carbon::parse($bill->due_date)->format('d M, Y'),
                                ['type' => 'bill', 'bill_id' => (string)$bill->id]
                            );
                        } catch (\Exception $e) {
                            \Log::warning("Failed to send push notification for bill {$bill->id}: {$e->getMessage()}");
                        }
                    }
                }
            }
        }
    }
}
