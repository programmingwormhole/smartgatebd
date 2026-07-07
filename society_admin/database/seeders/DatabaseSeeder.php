<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        User::firstOrCreate(
            ['email' => 'admin@smartgatebd.com'],
            [
                'name' => 'Superadmin',
                'phone' => '01700000000',
                'password' => bcrypt('password123'),
                'role' => 'superadmin',
            ]
        );

        $this->call([
            InitialDataSeeder::class,
        ]);
    }
}
