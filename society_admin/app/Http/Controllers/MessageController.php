<?php

namespace App\Http\Controllers;

use App\Models\Chat;
use App\Models\Message;
use Illuminate\Http\Request;

class MessageController extends Controller
{
    public function index(Chat $chat)
    {
        return response()->json($chat->messages()->with('sender')->latest()->get());
    }

    public function store(Request $request, Chat $chat)
    {
        $data = $request->validate([
            'sender_id' => 'required|exists:users,id',
            'content' => 'required_without:image|string|nullable',
            'image' => 'required_without:content|file|mimes:jpeg,png,jpg|max:2048'
        ]);

        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('chat_images', 'local');
        }

        $message = $chat->messages()->create($data);
        return response()->json($message, 201);
    }
}
