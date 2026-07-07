<?php

namespace App\Http\Controllers;

use App\Models\Building;
use App\Models\Notice;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class NoticeController extends Controller
{
    private function mapNotice(Notice $notice): array
    {
        return [
            'id' => $notice->id,
            'title' => $notice->title,
            'content' => $notice->content,
            'description' => $notice->content, // Backward compatibility for existing Flutter UI.
            'created_by_admin_id' => $notice->created_by_admin_id,
            'created_at' => optional($notice->created_at)->toDateTimeString(),
            'created_at_human' => optional($notice->created_at)->diffForHumans(),
            'updated_at' => optional($notice->updated_at)->toDateTimeString(),
        ];
    }

    public function index(Building $building)
    {
        $notices = $building->notices()
            ->latest()
            ->get()
            ->map(fn ($notice) => $this->mapNotice($notice));

        return response()->json([
            'notices' => $notices,
        ]);
    }

    public function store(Request $request, Building $building)
    {
        $data = $request->validate([
            'title' => 'required|string',
            'content' => 'required|string',
            'created_by_admin_id' => 'nullable|exists:users,id'
        ]);

        $creatorId = $data['created_by_admin_id'] ?? $request->user()->id;

        $notice = $building->notices()->create($data);
        $notice->update(['created_by_admin_id' => $creatorId]);

        // Create DB notifications for all users in this building except creator.
        $buildingUsers = \App\Helpers\NotificationHelper::getBuildingUsers($building->id)
            ->where('id', '!=', $creatorId)
            ->values();

        foreach ($buildingUsers as $user) {
            \App\Http\Controllers\NotificationController::createNotification(
                $user->id,
                'New Notice',
                $notice->title,
                'info',
                'notice',
                $notice->id
            );
        }

        // Push specifically for residents and guards.
        $firebase = app(\App\Services\FirebaseService::class);
        $firebase->sendToTopic(
            "building_{$building->id}_residents",
            'New Notice',
            $notice->title,
            ['type' => 'notice', 'id' => (string)$notice->id]
        );
        $firebase->sendToTopic(
            "building_{$building->id}_guards",
            'New Notice',
            $notice->title,
            ['type' => 'notice', 'id' => (string)$notice->id]
        );

        Log::info('Notice created and notifications dispatched', [
            'notice_id' => $notice->id,
            'building_id' => $building->id,
            'creator_id' => $creatorId,
            'db_recipient_count' => $buildingUsers->count(),
        ]);

        return response()->json($this->mapNotice($notice), 201);
    }

    public function update(Request $request, Notice $notice)
    {
        $data = $request->validate([
            'title' => 'required|string',
            'content' => 'required|string',
        ]);

        if ($request->user()->role !== 'superadmin' && (int) $request->user()->building_id !== (int) $notice->building_id) {
            return response()->json(['message' => 'Unauthorized for this building notice'], 403);
        }

        $notice->update($data);

        return response()->json($this->mapNotice($notice));
    }

    public function destroy(Request $request, Notice $notice)
    {
        if ($request->user()->role !== 'superadmin' && (int) $request->user()->building_id !== (int) $notice->building_id) {
            return response()->json(['message' => 'Unauthorized for this building notice'], 403);
        }

        $notice->delete();

        return response()->json(['message' => 'Notice deleted successfully']);
    }
}
