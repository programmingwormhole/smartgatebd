<?php

namespace App\Http\Controllers;

use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class NotificationController extends Controller
{
    /**
     * Get all notifications for the authenticated user
     */
    public function index(Request $request)
    {
        $query = Notification::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc');

        $notifications = $query->paginate(20);

        return response()->json([
            'notifications' => $notifications->items(),
            'total' => $notifications->total(),
            'unread_count' => Notification::where('user_id', $request->user()->id)
                ->where('is_read', false)
                ->count(),
        ]);
    }

    /**
     * Get unread notification count
     */
    public function unreadCount(Request $request)
    {
        $count = Notification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->count();

        return response()->json(['unread_count' => $count]);
    }

    /**
     * Mark a notification as read
     */
    public function markAsRead(Request $request, Notification $notification)
    {
        // Check if notification belongs to the user
        if ($notification->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $notification->markAsRead();

        return response()->json([
            'message' => 'Notification marked as read',
            'notification' => $notification,
        ]);
    }

    /**
     * Mark all notifications as read
     */
    public function markAllAsRead(Request $request)
    {
        Notification::where('user_id', $request->user()->id)
            ->where('is_read', false)
            ->update([
                'is_read' => true,
                'read_at' => now(),
            ]);

        return response()->json(['message' => 'All notifications marked as read']);
    }

    /**
     * Delete a notification
     */
    public function destroy(Request $request, Notification $notification)
    {
        // Check if notification belongs to the user
        if ($notification->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $notification->delete();

        return response()->json(['message' => 'Notification deleted']);
    }

    /**
     * Create a notification (internal use)
     */
    public static function createNotification(
        int $userId,
        string $title,
        string $message,
        string $type = 'info',
        ?string $refType = null,
        ?int $refId = null
    ) {
        $notification = Notification::create([
            'user_id' => $userId,
            'title' => $title,
            'message' => $message,
            'type' => $type,
            'ref_type' => $refType,
            'ref_id' => $refId,
        ]);

        Log::info('Database notification created', [
            'notification_id' => $notification->id,
            'user_id' => $userId,
            'type' => $type,
            'ref_type' => $refType,
            'ref_id' => $refId,
        ]);

        return $notification;
    }
}
