<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Building;
use App\Models\Block;
use App\Models\Floor;
use App\Models\Flat;
use App\Models\User;
use App\Models\Resident;
use App\Models\Guard;
use App\Models\Visitor;
use App\Models\Gatepass;
use App\Models\VisitorActivityLog;
use Illuminate\Support\Facades\Hash;

class InitialDataSeeder extends Seeder
{
    public function run(): void
    {
        // 0. Get or create Admin User
        $adminUser = User::firstOrCreate(
            ['phone' => '01758195324'],
            [
                'name' => 'Admin One',
                'email' => 'admin1@example.com',
                'password' => Hash::make('password123'),
                'role' => 'admin',
            ]
        );

        // 1. Create Building
        $building = Building::first();
        if (!$building) {
            $building = Building::create([
                'name' => 'Rose Valley',
                'address' => 'House 12, Road 5, Block A, Dhanmondi'
            ]);
        }

        if ($adminUser) {
            $adminUser->update(['building_id' => $building->id]);
        }

        // 2. Create Block
        $block = Block::firstOrCreate(
            ['building_id' => $building->id, 'name' => 'Block A']
        );

        // 3. Create Floor
        $floor = Floor::firstOrCreate(
            ['block_id' => $block->id, 'floor_number' => '1st Floor']
        );

        // 4. Create Flat
        $flat = Flat::firstOrCreate(
            ['floor_id' => $floor->id, 'flat_number' => 'A-101']
        );

        // 5. Assign Test Resident User to this flat
        $residentUser = User::where('phone', '01711111111')->first();
        if ($residentUser) {
            $residentUser->update(['building_id' => $building->id]);

            $resident = Resident::updateOrCreate(
                ['user_id' => $residentUser->id],
                ['flat_id' => $flatId ?? $flat->id, 'role' => 'resident']
            );

            // 6. Create Family Members
            $resident->families()->firstOrCreate(
                ['name' => 'Sara Doe'],
                [
                    'relation' => 'Spouse',
                    'entry_code' => '123456',
                    'qr_code' => 'qrcodes/family_1.png',
                    'gatepass_enabled' => true
                ]
            );

            // 7. Create Daily Help
            $resident->dailyHelps()->firstOrCreate(
                ['name' => 'Rahim'],
                [
                    'category' => 'maid',
                    'phone' => '01700000000',
                    'entry_code' => '654321',
                    'qr_code' => 'qrcodes/staff_1.png',
                    'gatepass_enabled' => true
                ]
            );

            // 8. Create Bills
            $resident->flat->bills()->updateOrCreate(
                ['type' => 'maintenance', 'amount' => 1500],
                ['due_date' => '2026-03-31', 'status' => 'unpaid']
            );

            // 9. Create Pets
            $resident->pets()->updateOrCreate(
                ['name' => 'Buddy'],
                ['type' => 'Dog', 'breed' => 'Golden Retriever', 'is_vaccinated' => true]
            );

            // 10. Create Vehicles
            \App\Models\Vehicle::updateOrCreate(
                ['resident_id' => $resident->id, 'plate_number' => 'DHK-12345'],
                ['type' => 'car', 'model' => 'Toyota Premio']
            );

            // 11. Create a sample guard and activity logs for UI testing
            $guardUser = User::firstOrCreate(
                ['phone' => '01790000000'],
                [
                    'name' => 'Guard Karim',
                    'email' => 'guard.karim@example.com',
                    'password' => Hash::make('password123'),
                    'role' => 'guard',
                    'building_id' => $building->id,
                ]
            );

            $guard = Guard::updateOrCreate(
                ['user_id' => $guardUser->id],
                [
                    'building_id' => $building->id,
                    'status' => 'on_duty',
                    'duty_start_time' => now()->subHours(2),
                    'notes' => 'Seeded guard for activity log testing',
                    'assigned_areas' => ['Main Gate'],
                ]
            );

            $familyMember = $resident->families()->firstOrCreate(
                ['name' => 'Sara Doe'],
                [
                    'relation' => 'Spouse',
                    'entry_code' => '123456',
                    'qr_code' => 'qrcodes/family_1.png',
                    'gatepass_enabled' => true,
                ]
            );

            $dailyHelp = $resident->dailyHelps()->firstOrCreate(
                ['name' => 'Rahim'],
                [
                    'category' => 'maid',
                    'phone' => '01700000000',
                    'entry_code' => '654321',
                    'qr_code' => 'qrcodes/staff_1.png',
                    'gatepass_enabled' => true,
                ]
            );

            $temporaryVisitor = Visitor::updateOrCreate(
                [
                    'flat_id' => $flat->id,
                    'name' => 'Courier Rahim',
                    'phone' => '01770000001',
                ],
                [
                    'type' => 'delivery',
                    'vehicle_no' => 'DHK-COUR-001',
                    'company_name' => 'Fast Express',
                    'purpose' => 'Parcel delivery',
                    'from_date' => now()->subHours(5),
                    'to_date' => now()->addHour(),
                    'status' => 'inside',
                    'created_by_resident_id' => $resident->id,
                ]
            );

            $temporaryGatepass = Gatepass::updateOrCreate(
                ['visitor_id' => $temporaryVisitor->id],
                [
                    'gatepass_code' => 'GP-1001',
                    'entry_code' => '100111',
                    'qr_code' => 'qrcodes/temp_1.png',
                    'entry_time' => now()->subHours(5),
                    'exit_time' => null,
                ]
            );

            VisitorActivityLog::updateOrCreate(
                [
                    'building_id' => $building->id,
                    'guard_id' => $guard->id,
                    'resident_id' => $resident->id,
                    'visitor_name' => 'Courier Rahim',
                    'action' => 'entry',
                    'entry_code' => '100111',
                    'activity_date' => now()->subHours(5),
                ],
                [
                    'visitor_type' => 'temporary',
                    'visitor_phone' => '01770000001',
                    'purpose' => 'Parcel delivery',
                    'gatepass_category' => 'temporary',
                    'visitor_id' => $temporaryVisitor->id,
                    'gatepass_id' => $temporaryGatepass->id,
                    'subject_type' => 'visitor',
                    'subject_id' => $temporaryVisitor->id,
                    'notes' => 'Seeded temporary visitor entry',
                    'metadata' => ['source' => 'seed', 'status' => 'inside'],
                ]
            );

            VisitorActivityLog::updateOrCreate(
                [
                    'building_id' => $building->id,
                    'guard_id' => $guard->id,
                    'resident_id' => $resident->id,
                    'visitor_name' => 'Sara Doe',
                    'action' => 'entry',
                    'entry_code' => '123456',
                    'activity_date' => now()->subHours(3),
                ],
                [
                    'visitor_type' => 'family',
                    'visitor_phone' => '01811111111',
                    'purpose' => 'Family visit',
                    'gatepass_category' => 'permanent',
                    'subject_type' => 'family',
                    'subject_id' => $familyMember->id,
                    'notes' => 'Seeded permanent family entry',
                    'metadata' => ['source' => 'seed', 'status' => 'inside'],
                ]
            );

            VisitorActivityLog::updateOrCreate(
                [
                    'building_id' => $building->id,
                    'guard_id' => $guard->id,
                    'resident_id' => $resident->id,
                    'visitor_name' => 'Rahim',
                    'action' => 'entry',
                    'entry_code' => '654321',
                    'activity_date' => now()->subHours(2),
                ],
                [
                    'visitor_type' => 'daily_help',
                    'visitor_phone' => '01700000000',
                    'purpose' => 'Daily help shift',
                    'gatepass_category' => 'permanent',
                    'subject_type' => 'daily_help',
                    'subject_id' => $dailyHelp->id,
                    'notes' => 'Seeded permanent daily help entry',
                    'metadata' => ['source' => 'seed', 'status' => 'inside'],
                ]
            );

            VisitorActivityLog::updateOrCreate(
                [
                    'building_id' => $building->id,
                    'guard_id' => $guard->id,
                    'resident_id' => $resident->id,
                    'visitor_name' => 'Courier Rahim',
                    'action' => 'exit',
                    'entry_code' => '100111',
                    'activity_date' => now()->subHour(),
                ],
                [
                    'visitor_type' => 'temporary',
                    'visitor_phone' => '01770000001',
                    'purpose' => 'Parcel delivery completed',
                    'gatepass_category' => 'temporary',
                    'visitor_id' => $temporaryVisitor->id,
                    'gatepass_id' => $temporaryGatepass->id,
                    'subject_type' => 'visitor',
                    'subject_id' => $temporaryVisitor->id,
                    'notes' => 'Seeded temporary visitor exit',
                    'metadata' => ['source' => 'seed', 'status' => 'exited'],
                ]
            );

            // 12. Create Building Data (Amenities & Notices)
            $building->amenities()->updateOrCreate(
                ['name' => 'Swimming Pool'],
                [
                    'price_per_day' => 500,
                    'max_capacity' => 10,
                    'open_time' => '06:00',
                    'close_time' => '22:00',
                    'slot_duration_minutes' => 60
                ]
            );
            $building->amenities()->updateOrCreate(
                ['name' => 'Community Hall'],
                [
                    'price_per_day' => 2000,
                    'max_capacity' => 2,
                    'open_time' => '08:00',
                    'close_time' => '23:00',
                    'slot_duration_minutes' => 240 // 4 hours
                ]
            );

            $building->notices()->updateOrCreate(
                ['title' => 'Water Tank Cleaning'],
                [
                    'content' => 'The water tank will be cleaned on Sunday. Please save water.',
                    'created_by_admin_id' => $adminUser->id ?? null
                ]
            );

            // 13. Create Services
            $building->services()->updateOrCreate(
                ['name' => 'Laundry Service'],
                ['category' => 'Laundry']
            );

            // 14. Create Complaints
            $resident->complaints()->updateOrCreate(
                ['title' => 'AC Pipe Leakage'],
                ['category' => 'Maintenance', 'description' => 'Water is leaking from the AC pipe in the balcony.', 'status' => 'open']
            );

            // 15. Create some dummy admin and committee members
            $adminUser2 = User::firstOrCreate(
                ['phone' => '01800000001'],
                [
                    'name' => 'Admin John',
                    'email' => 'admin2@example.com',
                    'password' => \Illuminate\Support\Facades\Hash::make('password123'),
                    'role' => 'resident',
                    'building_id' => $building->id
                ]
            );
            Resident::updateOrCreate(
                ['user_id' => $adminUser2->id],
                ['flat_id' => $flat->id, 'role' => 'admin']
            );

            $committeeUser = User::firstOrCreate(
                ['phone' => '01900000001'],
                [
                    'name' => 'Committee Member Lee',
                    'email' => 'committee@example.com',
                    'password' => \Illuminate\Support\Facades\Hash::make('password123'),
                    'role' => 'resident',
                    'building_id' => $building->id
                ]
            );
            Resident::updateOrCreate(
                ['user_id' => $committeeUser->id],
                ['flat_id' => $flat->id, 'role' => 'committee']
            );

            // 16. Create Payment Gateways
            \App\Models\PaymentGateway::updateOrCreate(
                ['building_id' => $building->id, 'name' => 'bKash'],
                [
                    'account_type' => 'Merchant',
                    'account_number' => '01712345678',
                    'required_fields' => ['trx_id', 'screenshot'],
                    'is_active' => true
                ]
            );
            \App\Models\PaymentGateway::updateOrCreate(
                ['building_id' => $building->id, 'name' => 'Nagad'],
                [
                    'account_type' => 'Personal',
                    'account_number' => '01812345678',
                    'required_fields' => ['trx_id', 'screenshot'],
                    'is_active' => true
                ]
            );
        }
    }
}
