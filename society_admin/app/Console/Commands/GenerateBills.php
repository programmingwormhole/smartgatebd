<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Resident;
use App\Models\Bill;
use App\Http\Controllers\NotificationController;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class GenerateBills extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'bills:generate {--demo}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Generate monthly rent and maintenance bills for residents based on their bill_generate_date';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $isDemo = $this->option('demo');
        $today = Carbon::now()->day;

        $monthYear = Carbon::now()->format('F Y');
        $count = 0;
        $skipped = 0;

        // Get all residents
        $residents = Resident::with('user', 'flat.floor.block.building')->get();

        foreach ($residents as $resident) {
            // Check if today is the bill generation day (or generate all if demo mode)
            if (!$isDemo && $resident->bill_generate_date != $today) {
                $skipped++;
                continue;
            }

            // Only generate bills if resident has rent or maintenance fee set
            if ($resident->monthly_rent <= 0 && $resident->monthly_maintenance_fee <= 0) {
                continue;
            }

            // Generate Rent Bill
            if ($resident->monthly_rent > 0) {
                $rentBillExists = Bill::where('flat_id', $resident->flat_id)
                    ->where('resident_id', $resident->id)
                    ->where('type', 'rent')
                    ->where('month_year', $monthYear)
                    ->exists();

                if (!$rentBillExists) {
                    $rentBill = Bill::create([
                        'flat_id' => $resident->flat_id,
                        'resident_id' => $resident->id,
                        'type' => 'rent',
                        'amount' => $resident->monthly_rent,
                        'month_year' => $monthYear,
                        'due_date' => Carbon::now()->endOfMonth(),
                        'status' => 'unpaid',
                        'description' => "Monthly Rent for {$monthYear}"
                    ]);

                    $this->notifyResidentAboutBill($resident, $rentBill);
                    $count++;
                    $this->info("✓ Generated Rent bill for {$resident->user->name} (Flat {$resident->flat->flat_number}) - ৳{$resident->monthly_rent}");
                }
            }

            // Generate Maintenance Bill
            if ($resident->monthly_maintenance_fee > 0) {
                $maintenanceBillExists = Bill::where('flat_id', $resident->flat_id)
                    ->where('resident_id', $resident->id)
                    ->where('type', 'maintenance')
                    ->where('month_year', $monthYear)
                    ->exists();

                if (!$maintenanceBillExists) {
                    $maintenanceBill = Bill::create([
                        'flat_id' => $resident->flat_id,
                        'resident_id' => $resident->id,
                        'type' => 'maintenance',
                        'amount' => $resident->monthly_maintenance_fee,
                        'month_year' => $monthYear,
                        'due_date' => Carbon::now()->endOfMonth(),
                        'status' => 'unpaid',
                        'description' => "Monthly Maintenance for {$monthYear}"
                    ]);

                    $this->notifyResidentAboutBill($resident, $maintenanceBill);
                    $count++;
                    $this->info("✓ Generated Maintenance bill for {$resident->user->name} (Flat {$resident->flat->flat_number}) - ৳{$resident->monthly_maintenance_fee}");
                }
            }
        }

        Log::info("Bills generated: {$count}, Skipped (not billing date): {$skipped} for {$monthYear}");
        $this->info("\n✅ Successfully generated {$count} bills for {$monthYear}");
        if (!$isDemo && $skipped > 0) {
            $this->info("⏭️  Skipped {$skipped} residents (not their billing date)");
        }
    }

    private function notifyResidentAboutBill($resident, $bill)
    {
        if (!$resident->user) {
            return;
        }

        try {
            // Create database notification
            NotificationController::createNotification(
                $resident->user->id,
                'New Bill Generated',
                'A new ' . ucfirst($bill->type) . ' bill of ৳' . number_format($bill->amount, 2) . ' has been generated for ' . $bill->month_year,
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
                        'A new ' . ucfirst($bill->type) . ' bill of ৳' . number_format($bill->amount, 2) . ' has been generated for ' . $bill->month_year,
                        ['type' => 'bill', 'bill_id' => (string)$bill->id]
                    );
                } catch (\Exception $e) {
                    Log::warning("Failed to send push notification for bill {$bill->id}: {$e->getMessage()}");
                }
            }
        } catch (\Exception $e) {
            Log::error("Failed to notify resident {$resident->user->id} about bill {$bill->id}: {$e->getMessage()}");
        }
    }
}
