<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use App\Models\Building;
use App\Models\Block;
use App\Models\Floor;
use App\Models\Flat;
use App\Models\Resident;

class ResidentTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $admin;
    protected $token;
    protected $building;
    protected $flat;
    protected $residentUser;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->token = $this->admin->createToken('test-token')->plainTextToken;

        $this->building = Building::create([
            'name' => 'Sunset Towers',
            'address' => '123 Sunset Blvd',
            'admin_id' => $this->admin->id
        ]);

        $block = Block::create([
            'name' => 'Block A',
            'building_id' => $this->building->id
        ]);

        $floor = Floor::create([
            'floor_number' => '1',
            'block_id' => $block->id
        ]);

        $this->flat = Flat::create([
            'flat_number' => '101',
            'floor_id' => $floor->id
        ]);

        $this->residentUser = User::factory()->create();
    }

    public function test_can_create_resident()
    {
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson("/api/v1/buildings/{$this->building->id}/residents", [
            'user_id' => $this->residentUser->id,
            'flat_id' => $this->flat->id,
            'role' => 'resident'
        ]);

        $response->assertStatus(201)
                 ->assertJsonStructure([
                     'id', 'user_id', 'flat_id', 'role'
                 ]);

        $this->assertDatabaseHas('residents', [
            'user_id' => $this->residentUser->id,
            'flat_id' => $this->flat->id,
            'role' => 'resident'
        ]);
    }

    public function test_can_list_residents_for_building()
    {
        Resident::create([
            'user_id' => $this->residentUser->id,
            'flat_id' => $this->flat->id,
            'role' => 'resident'
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->getJson("/api/v1/buildings/{$this->building->id}/residents");

        $response->assertStatus(200)
                 ->assertJsonCount(1);
    }
}
