<?php

namespace App\Http\Controllers;

use App\Models\Chat;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    public function index(Request $request)
    {
        $userId = $request->user()->id;
        
        $chats = Chat::where('sender_id', $userId)
            ->orWhere('receiver_id', $userId)
            ->with(['sender', 'receiver', 'messages' => function($q) {
                // Fetch latest message
                $q->latest()->limit(1);
            }])
            ->get();
            
        return response()->json($chats);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'building_id' => 'required|exists:buildings,id',
            'sender_id' => 'required|exists:users,id',
            'receiver_id' => 'required|exists:users,id'
        ]);

        $chat = Chat::firstOrCreate([
            'sender_id' => $data['sender_id'],
            'receiver_id' => $data['receiver_id'],
            'building_id' => $data['building_id']
        ]);

        return response()->json($chat, 201);
    }
}
