<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use App\Models\Building;
use App\Models\Block;
use App\Models\Floor;

class BuildingStructureTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    protected $admin;
    protected $token;

    protected function setUp(): void
    {
        parent::setUp();
        
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->token = $this->admin->createToken('test-token')->plainTextToken;
    }

    public function test_can_create_building()
    {
        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson('/api/v1/buildings', [
            'name' => 'Sunset Towers',
            'address' => '123 Sunset Blvd',
            'admin_id' => $this->admin->id
        ]);

        $response->assertStatus(201)
                 ->assertJsonStructure([
                     'id', 'name', 'address', 'admin_id'
                 ]);

        $this->assertDatabaseHas('buildings', [
            'name' => 'Sunset Towers',
            'admin_id' => $this->admin->id
        ]);
    }

    public function test_can_list_buildings()
    {
        Building::create([
            'name' => 'Sunset Towers',
            'address' => '123 Sunset Blvd',
            'admin_id' => $this->admin->id
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->getJson('/api/v1/buildings');

        $response->assertStatus(200)
                 ->assertJsonCount(1);
    }

    public function test_can_create_block_in_building()
    {
        $building = Building::create([
            'name' => 'Sunset Towers',
            'address' => '123 Sunset Blvd',
            'admin_id' => $this->admin->id
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson("/api/v1/buildings/{$building->id}/blocks", [
            'name' => 'Block A',
        ]);

        $response->assertStatus(201)
                 ->assertJsonStructure([
                     'id', 'name', 'building_id'
                 ]);

        $this->assertDatabaseHas('blocks', [
            'name' => 'Block A',
            'building_id' => $building->id
        ]);
    }

    public function test_can_create_floor_in_block()
    {
        $building = Building::create([
            'name' => 'Sunset Towers',
            'address' => '123 Sunset Blvd',
            'admin_id' => $this->admin->id
        ]);

        $block = Block::create([
            'name' => 'Block A',
            'building_id' => $building->id
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson("/api/v1/blocks/{$block->id}/floors", [
            'floor_number' => '1',
        ]);

        $response->assertStatus(201)
                 ->assertJsonStructure([
                     'id', 'floor_number', 'block_id'
                 ]);

        $this->assertDatabaseHas('floors', [
            'floor_number' => '1',
            'block_id' => $block->id
        ]);
    }

    public function test_can_create_flat_in_floor()
    {
        $building = Building::create([
            'name' => 'Sunset Towers',
            'address' => '123 Sunset Blvd',
            'admin_id' => $this->admin->id
        ]);

        $block = Block::create([
            'name' => 'Block A',
            'building_id' => $building->id
        ]);

        $floor = Floor::create([
            'floor_number' => '1',
            'block_id' => $block->id
        ]);

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $this->token,
        ])->postJson("/api/v1/floors/{$floor->id}/flats", [
            'flat_number' => '101',
        ]);

        $response->assertStatus(201)
                 ->assertJsonStructure([
                     'id', 'flat_number', 'floor_id'
                 ]);

        $this->assertDatabaseHas('flats', [
            'flat_number' => '101',
            'floor_id' => $floor->id
        ]);
    }
}
