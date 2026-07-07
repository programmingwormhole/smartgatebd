<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Building;
use App\Models\Block;
use App\Models\Floor;
use App\Models\Flat;

class SocietySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Create a Superadmin
        User::firstOrCreate(
            ['email' => 'superadmin@smartgate.com'],
            [
                'name' => 'Super Admin',
                'phone' => '01999999990',
                'password' => Hash::make('password'),
                'role' => 'superadmin',
            ]
        );

        // 2. Create a Building
        $building = Building::firstOrCreate(
            ['name' => 'Smart Plaza'],
            [
                'address' => '123 Smart City Avenue',
            ]
        );

        // 3. Create a Building Admin
        $admin = User::firstOrCreate(
            ['email' => 'admin@smartgate.com'],
            [
                'name' => 'Building Admin',
                'phone' => '01999999991',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'building_id' => $building->id,
            ]
        );

        // 4. Create Block, Floor, Flat
        $block = Block::firstOrCreate(['building_id' => $building->id, 'name' => 'Block A']);
        $floor = Floor::firstOrCreate(['block_id' => $block->id, 'floor_number' => '1']);
        $flat = Flat::firstOrCreate(['floor_id' => $floor->id, 'flat_number' => '101']);

        // 5. Create a Resident
        User::firstOrCreate(
            ['email' => 'resident@smartgate.com'],
            [
                'name' => 'John Resident',
                'phone' => '01999999992',
                'password' => Hash::make('password'),
                'role' => 'resident',
                'building_id' => $building->id,
            ]
        );

        // 6. Create a Guard
        User::firstOrCreate(
            ['email' => 'guard@smartgate.com'],
            [
                'name' => 'Security Guard',
                'phone' => '01999999993',
                'password' => Hash::make('password'),
                'role' => 'guard',
                'building_id' => $building->id,
            ]
        );
    }
}
