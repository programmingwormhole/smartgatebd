<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

Route::prefix('v1/auth')->group(function () {
    Route::get('/config', [AuthController::class, 'config']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);
    Route::post('/resend-otp', [AuthController::class, 'resendOtp']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
        // User Management
        Route::post('/users', [\App\Http\Controllers\UserController::class, 'store']);
        Route::get('/users/me', [\App\Http\Controllers\UserController::class, 'show']);
        Route::put('/users/me', [\App\Http\Controllers\UserController::class, 'update']);

        // Module 2: Buildings & Structure
        Route::post('/buildings', [\App\Http\Controllers\BuildingController::class, 'store']);
        Route::get('/buildings', [\App\Http\Controllers\BuildingController::class, 'index']);
        Route::put('/buildings/{building}', [\App\Http\Controllers\BuildingController::class, 'update']);
        Route::get('/buildings/{building}/structure', [\App\Http\Controllers\BuildingController::class, 'structure']);
        Route::post('/buildings/{building}/blocks', [\App\Http\Controllers\BlockController::class, 'store']);
        Route::put('/blocks/{block}', [\App\Http\Controllers\BlockController::class, 'update']);
        Route::delete('/blocks/{block}', [\App\Http\Controllers\BlockController::class, 'destroy']);
        Route::post('/blocks/{block}/floors', [\App\Http\Controllers\FloorController::class, 'store']);
        Route::put('/floors/{floor}', [\App\Http\Controllers\FloorController::class, 'update']);
        Route::delete('/floors/{floor}', [\App\Http\Controllers\FloorController::class, 'destroy']);
        Route::post('/floors/{floor}/flats', [\App\Http\Controllers\FlatController::class, 'store']);
        Route::put('/flats/{flat}', [\App\Http\Controllers\FlatController::class, 'update']);
        Route::delete('/flats/{flat}', [\App\Http\Controllers\FlatController::class, 'destroy']);

        // Module 3: Residents
        Route::post('/buildings/{building}/residents', [\App\Http\Controllers\ResidentController::class, 'store']);
        Route::get('/buildings/{building}/residents', [\App\Http\Controllers\ResidentController::class, 'index']);
        Route::put('/residents/{resident}', [\App\Http\Controllers\ResidentController::class, 'update']);
        Route::delete('/residents/{resident}', [\App\Http\Controllers\ResidentController::class, 'destroy']);

        // Module 4: Guards
        Route::post('/buildings/{building}/guards', [\App\Http\Controllers\GuardController::class, 'store']);
        Route::get('/buildings/{building}/guards', [\App\Http\Controllers\GuardController::class, 'index']);
        Route::put('/guards/{guard}', [\App\Http\Controllers\GuardController::class, 'update']);
        Route::delete('/guards/{guard}', [\App\Http\Controllers\GuardController::class, 'destroy']);
        Route::put('/guards/{guard}/status', [\App\Http\Controllers\GuardController::class, 'updateStatus']);

        // Module 5: Family & Daily Help
        Route::post('/residents/{resident}/family', [\App\Http\Controllers\FamilyController::class, 'store']);
        Route::get('/residents/{resident}/family', [\App\Http\Controllers\FamilyController::class, 'index']);
        Route::get('/my-family', [\App\Http\Controllers\FamilyController::class, 'index']); // Use auth resident if not passing id
        Route::post('/my-family', [\App\Http\Controllers\FamilyController::class, 'store']);
        Route::put('/family/{family}', [\App\Http\Controllers\FamilyController::class, 'update']);
        Route::delete('/family/{family}', [\App\Http\Controllers\FamilyController::class, 'destroy']);
        Route::post('/residents/{resident}/daily-help', [\App\Http\Controllers\DailyHelpController::class, 'store']);
        Route::get('/residents/{resident}/daily-help', [\App\Http\Controllers\DailyHelpController::class, 'index']);
        Route::get('/my-daily-help', [\App\Http\Controllers\DailyHelpController::class, 'index']);
        Route::post('/my-daily-help', [\App\Http\Controllers\DailyHelpController::class, 'store']);
        Route::put('/daily-help/{dailyHelp}', [\App\Http\Controllers\DailyHelpController::class, 'update']);

        // Pets
        Route::post('/residents/{resident}/pets', [\App\Http\Controllers\PetController::class, 'store']);
        Route::get('/residents/{resident}/pets', [\App\Http\Controllers\PetController::class, 'index']);
        Route::get('/my-pets', [\App\Http\Controllers\PetController::class, 'index']);
        Route::post('/my-pets', [\App\Http\Controllers\PetController::class, 'store']);

        // Vehicles
        Route::post('/residents/{resident}/vehicles', [\App\Http\Controllers\VehicleController::class, 'store']);
        Route::get('/residents/{resident}/vehicles', [\App\Http\Controllers\VehicleController::class, 'index']);
        Route::get('/my-vehicles', [\App\Http\Controllers\VehicleController::class, 'index']);
        Route::post('/my-vehicles', [\App\Http\Controllers\VehicleController::class, 'store']);

        // Module 6: Visitor Management
        Route::post('/visitors', [\App\Http\Controllers\VisitorController::class, 'store']);
        Route::delete('/visitors/{visitor}', [\App\Http\Controllers\VisitorController::class, 'destroy']);
        Route::get('/my-visitors', [\App\Http\Controllers\VisitorController::class, 'indexByResident']); // Fallback to auth resident
        Route::put('/visitors/{visitor}/approve', [\App\Http\Controllers\VisitorController::class, 'approve']);
        Route::put('/visitors/{visitor}/reject', [\App\Http\Controllers\VisitorController::class, 'reject']);
        Route::get('/visitors/{visitor}/gatepass', [\App\Http\Controllers\VisitorController::class, 'gatepass']);
        Route::get('/buildings/{building}/visitors', [\App\Http\Controllers\VisitorController::class, 'indexByBuilding']);
        Route::get('/residents/{resident}/visitors', [\App\Http\Controllers\VisitorController::class, 'indexByResident']);

        // Guard API for Gatepass
        // Route::post('/guard/verify', [\App\Http\Controllers\GatepassController::class, 'verify']); // Replaced by GuardController
        Route::post('/guard/logs', [\App\Http\Controllers\GatepassController::class, 'logsStore']);
        Route::get('/guard/logs', [\App\Http\Controllers\GatepassController::class, 'logsIndex']);

        // Guard Visitor Management Routes
        Route::get('/guard/verify', [\App\Http\Controllers\GuardController::class, 'verifyEntryCode']);
        Route::post('/guard/walk-in-visitors', [\App\Http\Controllers\GuardController::class, 'createWalkInVisitor']);
        Route::post('/guard/visitors/{visitor}/confirm-entry', [\App\Http\Controllers\GuardController::class, 'confirmVisitorEntry']);
        Route::post('/guard/visitors/{visitor}/mark-exit', [\App\Http\Controllers\GuardController::class, 'markVisitorExit']);
        Route::post('/guard/visitors/{visitor}/reject', [\App\Http\Controllers\GuardController::class, 'rejectVisitorEntry']);
        Route::post('/guard/permanent/mark-entry', [\App\Http\Controllers\GuardController::class, 'markPermanentEntry']);
        Route::post('/guard/permanent/mark-exit', [\App\Http\Controllers\GuardController::class, 'markPermanentExit']);
        Route::get('/guard/visitors/inside', [\App\Http\Controllers\GuardController::class, 'getInsideVisitors']);
        Route::get('/guard/visitors/pending', [\App\Http\Controllers\GuardController::class, 'getPendingVisitors']);
        Route::get('/guard/visitors/history', [\App\Http\Controllers\GuardController::class, 'getVisitorHistory']);

        // Module 7: Bills & Payments
        Route::post('/buildings/{building}/bills', [\App\Http\Controllers\BillController::class, 'store']);
        Route::get('/buildings/{building}/bills', [\App\Http\Controllers\BillController::class, 'indexByBuilding']);
        Route::get('/flats/{flat}/bills', [\App\Http\Controllers\BillController::class, 'indexByFlat']);
        Route::get('/my-bills', [\App\Http\Controllers\BillController::class, 'indexMy']);
        Route::post('/bills/{bill}/pay', [\App\Http\Controllers\PaymentController::class, 'store']);
        Route::get('/bill-payments/{payment}', [\App\Http\Controllers\PaymentController::class, 'show']);
        Route::get('/buildings/{building}/payment-gateways', [\App\Http\Controllers\PaymentGatewayController::class, 'indexByBuilding']);

        // Payment Gateway Management (Admin)
        Route::get('/payment-gateways', [\App\Http\Controllers\PaymentGatewayController::class, 'index']);
        Route::post('/payment-gateways', [\App\Http\Controllers\PaymentGatewayController::class, 'store']);
        Route::put('/payment-gateways/{paymentGateway}', [\App\Http\Controllers\PaymentGatewayController::class, 'update']);
        Route::delete('/payment-gateways/{paymentGateway}', [\App\Http\Controllers\PaymentGatewayController::class, 'destroy']);

        // Module 8: Amenities
        Route::post('/buildings/{building}/amenities', [\App\Http\Controllers\AmenityController::class, 'store']);
        Route::get('/buildings/{building}/amenities', [\App\Http\Controllers\AmenityController::class, 'index']);
        Route::put('/amenities/{amenity}', [\App\Http\Controllers\AmenityController::class, 'update']);
        Route::delete('/amenities/{amenity}', [\App\Http\Controllers\AmenityController::class, 'destroy']);
        Route::get('/amenities/bookings', [\App\Http\Controllers\BookingController::class, 'indexByResident']);
        Route::post('/amenities/{amenity}/book', [\App\Http\Controllers\BookingController::class, 'store']);
        Route::get('/amenities/{amenity}/slots', [\App\Http\Controllers\AmenityController::class, 'slots']);
        Route::get('/amenities/{amenity}/bookings', [\App\Http\Controllers\BookingController::class, 'indexByAmenity']);
        Route::put('/bookings/{booking}/approve', [\App\Http\Controllers\BookingController::class, 'approve']);
        Route::put('/bookings/{booking}/reject', [\App\Http\Controllers\BookingController::class, 'reject']);

        // Module 9: Services
        Route::post('/buildings/{building}/services', [\App\Http\Controllers\ServiceController::class, 'store']);
        Route::get('/buildings/{building}/services', [\App\Http\Controllers\ServiceController::class, 'index']);
        Route::put('/services/{service}', [\App\Http\Controllers\ServiceController::class, 'update']);
        Route::delete('/services/{service}', [\App\Http\Controllers\ServiceController::class, 'destroy']);
        Route::post('/service-bookings', [\App\Http\Controllers\ServiceBookingController::class, 'store']);
        Route::get('/service-bookings', [\App\Http\Controllers\ServiceBookingController::class, 'indexByResident']);
        Route::get('/admin/service-bookings', [\App\Http\Controllers\ServiceBookingController::class, 'indexByBuilding']);
        // Module 10: Complaints
        Route::post('/complaints', [\App\Http\Controllers\ComplaintController::class, 'store']);
        Route::get('/complaints', [\App\Http\Controllers\ComplaintController::class, 'indexByResident']); // Resident scope
        Route::get('/admin/complaints', [\App\Http\Controllers\ComplaintController::class, 'indexByBuilding']); // Admin scope
        Route::put('/complaints/{complaint}/status', [\App\Http\Controllers\ComplaintController::class, 'updateStatus']);

        // Module 11: Chat & Notifications
        Route::post('/chats', [\App\Http\Controllers\ChatController::class, 'store']);
        Route::get('/chats', [\App\Http\Controllers\ChatController::class, 'index']);
        Route::get('/chats/{chat}/messages', [\App\Http\Controllers\MessageController::class, 'index']);
        Route::post('/chats/{chat}/messages', [\App\Http\Controllers\MessageController::class, 'store']);

        // Module 12: Emergency Alerts
        Route::post('/emergency', [\App\Http\Controllers\EmergencyController::class, 'store']);
        Route::post('/emergency/sos', [\App\Http\Controllers\EmergencyController::class, 'store']);
        Route::get('/emergency', [\App\Http\Controllers\EmergencyController::class, 'index']);
        Route::put('/emergency/{alert}/read', [\App\Http\Controllers\EmergencyController::class, 'markAsRead']);

        // Module 13: Notices
        Route::post('/buildings/{building}/notices', [\App\Http\Controllers\NoticeController::class, 'store']);
        Route::get('/buildings/{building}/notices', [\App\Http\Controllers\NoticeController::class, 'index']);
        Route::put('/notices/{notice}', [\App\Http\Controllers\NoticeController::class, 'update']);
        Route::delete('/notices/{notice}', [\App\Http\Controllers\NoticeController::class, 'destroy']);

        // FCM Tokens
        Route::post('/fcm-tokens', [\App\Http\Controllers\FcmTokenController::class, 'store']);
        Route::delete('/fcm-tokens', [\App\Http\Controllers\FcmTokenController::class, 'destroy']);

        Route::get('/profile', [\App\Http\Controllers\AuthController::class, 'profile']);
        Route::post('/profile/update', [\App\Http\Controllers\AuthController::class, 'updateProfile']);
        Route::post('/profile/upload-picture', [\App\Http\Controllers\AuthController::class, 'uploadProfilePicture']);
        Route::delete('/profile/picture', [\App\Http\Controllers\AuthController::class, 'deleteProfilePicture']);
        Route::post('/profile/change-password', [\App\Http\Controllers\AuthController::class, 'changePassword']);

        // Notifications
        Route::get('/notifications', [\App\Http\Controllers\NotificationController::class, 'index']);
        Route::get('/notifications/unread-count', [\App\Http\Controllers\NotificationController::class, 'unreadCount']);
        Route::post('/notifications/{notification}/read', [\App\Http\Controllers\NotificationController::class, 'markAsRead']);
        Route::post('/notifications/read-all', [\App\Http\Controllers\NotificationController::class, 'markAllAsRead']);
        Route::delete('/notifications/{notification}', [\App\Http\Controllers\NotificationController::class, 'destroy']);

        Route::get('/members', [\App\Http\Controllers\ResidentController::class, 'members']);
        Route::get('/committee-members', [\App\Http\Controllers\ResidentController::class, 'committee']);

        // Admin Routes
        Route::prefix('admin')->group(function () {
            Route::get('/dashboard/stats', [\App\Http\Controllers\Admin\AdminDashboardController::class, 'stats']);
            Route::get('/payments/pending', [\App\Http\Controllers\Admin\AdminDashboardController::class, 'pendingManualPayments']);
            Route::post('/payments/{payment}/approve', [\App\Http\Controllers\Admin\AdminDashboardController::class, 'approvePayment']);
            Route::post('/payments/{payment}/reject', [\App\Http\Controllers\Admin\AdminDashboardController::class, 'rejectPayment']);

            // Admin Bill Management
            Route::get('/bills', [\App\Http\Controllers\Admin\AdminBillController::class, 'index']);
            Route::get('/bills/{bill}', [\App\Http\Controllers\Admin\AdminBillController::class, 'show']);
            Route::post('/bills/{bill}/mark-paid', [\App\Http\Controllers\Admin\AdminBillController::class, 'markAsPaid']);
            Route::post('/flats/{flat}/bills', [\App\Http\Controllers\Admin\AdminBillController::class, 'generateForFlat']);
            Route::post('/bills/bulk-generate', [\App\Http\Controllers\Admin\AdminBillController::class, 'generateBulk']);

            // Admin Guard Management
            Route::get('/guards', [\App\Http\Controllers\Admin\AdminGuardController::class, 'index']);
            Route::get('/guards/all', [\App\Http\Controllers\Admin\AdminGuardController::class, 'allGuards']);
            Route::get('/guards/building/{building}', [\App\Http\Controllers\Admin\AdminGuardController::class, 'byBuilding']);
            Route::get('/guards/status/{status}', [\App\Http\Controllers\Admin\AdminGuardController::class, 'byStatus']);
            Route::get('/guards/statistics', [\App\Http\Controllers\Admin\AdminGuardController::class, 'statistics']);
            Route::get('/guards/{guard}', [\App\Http\Controllers\Admin\AdminGuardController::class, 'show']);
            Route::post('/guards', [\App\Http\Controllers\Admin\AdminGuardController::class, 'store']);
            Route::put('/guards/{guard}', [\App\Http\Controllers\Admin\AdminGuardController::class, 'update']);
            Route::put('/guards/{guard}/status', [\App\Http\Controllers\Admin\AdminGuardController::class, 'updateStatus']);
            Route::delete('/guards/{guard}', [\App\Http\Controllers\Admin\AdminGuardController::class, 'destroy']);
            Route::post('/guards/{guard}/restore', [\App\Http\Controllers\Admin\AdminGuardController::class, 'restore']);

            // Admin Request Management
            Route::get('/requests/amenities', [\App\Http\Controllers\Admin\AdminRequestController::class, 'amenityRequests']);
            Route::get('/requests/services', [\App\Http\Controllers\Admin\AdminRequestController::class, 'serviceRequests']);
            Route::post('/requests/amenities/{booking}/status', [\App\Http\Controllers\Admin\AdminRequestController::class, 'updateAmenityStatus']);
            Route::post('/requests/services/{booking}/status', [\App\Http\Controllers\Admin\AdminRequestController::class, 'updateServiceStatus']);

            // Activity Logs
            Route::get('/logs/activity', [\App\Http\Controllers\ActivityLogController::class, 'getAdminLogs']);
            Route::get('/logs/statistics', [\App\Http\Controllers\ActivityLogController::class, 'getStatistics']);
            Route::get('/logs/export', [\App\Http\Controllers\ActivityLogController::class, 'exportLogs']);
        });

        // Resident Activity Logs
        Route::get('/resident/logs', [\App\Http\Controllers\ActivityLogController::class, 'getResidentLogs']);

        // Guard Activity Logs
        Route::get('/guard/activity-logs', [\App\Http\Controllers\ActivityLogController::class, 'getGuardLogs']);
    });
