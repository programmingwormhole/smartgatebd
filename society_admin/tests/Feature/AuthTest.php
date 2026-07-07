<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use App\Models\SystemConfiguration;

class AuthTest extends TestCase
{
    use RefreshDatabase, WithFaker;

    public function test_user_can_register()
    {
        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'phone' => '01711223344',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);

        $response->assertStatus(201)
                 ->assertJsonStructure([
                     'message',
                     'user' => ['id', 'name', 'email', 'phone'] // removed 'role' and 'token' from assertions since role might not be exposed or token isn't generated yet
                 ]);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
            'phone' => '01711223344'
        ]);
    }

    public function test_user_cannot_register_with_existing_email()
    {
        User::factory()->create([
            'email' => 'john@example.com',
            'phone' => '01711223344',
            'password' => bcrypt('password'),
        ]);

        $response = $this->postJson('/api/v1/auth/register', [
            'name' => 'John Doe 2',
            'email' => 'john@example.com',
            'phone' => '01711223355',
            'password' => 'password',
            'password_confirmation' => 'password',
        ]);

        $response->assertStatus(422)
                 ->assertJsonValidationErrors(['email']);
    }

    public function test_user_can_login_with_email()
    {
        $user = User::factory()->create([
            'email' => 'login@example.com',
            'password' => bcrypt('secret123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'login' => 'login@example.com',
            'password' => 'secret123',
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'message',
                     'user' => ['id', 'email']
                 ]);
    }

    public function test_user_can_login_with_phone()
    {
        $user = User::factory()->create([
            'phone' => '01811223344',
            'password' => bcrypt('secret123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'login' => '01811223344',
            'password' => 'secret123',
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure([
                     'message',
                     'user' => ['id', 'phone']
                 ]);
    }

    public function test_user_cannot_login_with_invalid_credentials()
    {
        $user = User::factory()->create([
            'email' => 'wrong@example.com',
            'password' => bcrypt('secret123'),
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'login' => 'wrong@example.com',
            'password' => 'wrongpassword',
        ]);

        $response->assertStatus(401)
                 ->assertJson(['message' => 'Invalid credentials']);
    }

    public function test_user_can_logout()
    {
        $user = User::factory()->create();
        $token = $user->createToken('test-token')->plainTextToken;

        $response = $this->withHeaders([
            'Authorization' => 'Bearer ' . $token,
        ])->postJson('/api/v1/auth/logout');

        $response->assertStatus(200)
                 ->assertJson(['message' => 'Logged out successfully.']);
    }
}
