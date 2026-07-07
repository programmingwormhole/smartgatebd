<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Web\AuthController;
use App\Http\Controllers\Web\BuildingStructureController;
use App\Http\Controllers\Web\DashboardController;
use App\Http\Controllers\Web\ResidentManagementController;
use App\Http\Controllers\Web\GuardManagementController;
use App\Http\Controllers\Web\SettingController;
use App\Http\Controllers\Web\VisitorLogManagementController;

Route::get('/', function () {
    return view('welcome');
});

Route::prefix('superadmin')->group(function () {
    Route::middleware('guest')->group(function () {
        Route::get('/login', [AuthController::class, 'showLoginForm'])->name('admin.login');
        Route::post('/login', [AuthController::class, 'login'])->name('admin.login.submit');
    });

    Route::middleware('auth')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout'])->name('admin.logout');
        Route::get('/dashboard', [DashboardController::class, 'index'])->name('admin.dashboard');
        Route::get('/visitor-logs', [VisitorLogManagementController::class, 'index'])->name('admin.visitor-logs.index');
        Route::get('/visitor-logs/report/pdf', [VisitorLogManagementController::class, 'exportPdf'])->name('admin.visitor-logs.report.pdf');

        Route::get('/settings', [SettingController::class, 'index'])->name('admin.settings');
        Route::post('/settings', [SettingController::class, 'update'])->name('admin.settings.update');

        // Building Management
        Route::resource('buildings', \App\Http\Controllers\Web\BuildingController::class)->names('admin.buildings');
        Route::post('/buildings/{building}/admins', [\App\Http\Controllers\Web\BuildingAdminController::class, 'store'])->name('admin.buildings.admins.store');
        Route::delete('/buildings/{building}/admins/{admin}', [\App\Http\Controllers\Web\BuildingAdminController::class, 'destroy'])->name('admin.buildings.admins.destroy');

        // Building Structure Management (Web)
        Route::post('/buildings/{building}/blocks', [BuildingStructureController::class, 'storeBlock'])->name('admin.buildings.blocks.store');
        Route::post('/blocks/{block}/floors', [BuildingStructureController::class, 'storeFloor'])->name('admin.blocks.floors.store');
        Route::post('/floors/{floor}/flats', [BuildingStructureController::class, 'storeFlat'])->name('admin.floors.flats.store');
        Route::delete('/blocks/{block}', [BuildingStructureController::class, 'destroyBlock'])->name('admin.blocks.destroy');
        Route::delete('/floors/{floor}', [BuildingStructureController::class, 'destroyFloor'])->name('admin.floors.destroy');
        Route::delete('/flats/{flat}', [BuildingStructureController::class, 'destroyFlat'])->name('admin.flats.destroy');

        // Resident Management (Web)
        Route::get('/residents', [ResidentManagementController::class, 'index'])->name('admin.residents.index');
        Route::get('/residents/create', [ResidentManagementController::class, 'create'])->name('admin.residents.create');
        Route::post('/residents', [ResidentManagementController::class, 'store'])->name('admin.residents.store');
        Route::get('/residents/{resident}', [ResidentManagementController::class, 'show'])->name('admin.residents.show');
        Route::get('/residents/{resident}/edit', [ResidentManagementController::class, 'edit'])->name('admin.residents.edit');
        Route::put('/residents/{resident}', [ResidentManagementController::class, 'update'])->name('admin.residents.update');
        Route::delete('/residents/{resident}', [ResidentManagementController::class, 'destroy'])->name('admin.residents.destroy');

        // Guard Management (Web)
        Route::get('/guards', [GuardManagementController::class, 'index'])->name('admin.guards.index');
        Route::get('/guards/create', [GuardManagementController::class, 'create'])->name('admin.guards.create');
        Route::post('/guards', [GuardManagementController::class, 'store'])->name('admin.guards.store');
        Route::get('/guards/{guard}', [GuardManagementController::class, 'show'])->name('admin.guards.show');
        Route::get('/guards/{guard}/edit', [GuardManagementController::class, 'edit'])->name('admin.guards.edit');
        Route::put('/guards/{guard}', [GuardManagementController::class, 'update'])->name('admin.guards.update');
        Route::delete('/guards/{guard}', [GuardManagementController::class, 'destroy'])->name('admin.guards.destroy');

        // Resident form helpers
        Route::get('/buildings/{building}/blocks', [ResidentManagementController::class, 'blocks'])->name('admin.buildings.blocks.index');
        Route::get('/blocks/{block}/floors', [ResidentManagementController::class, 'floors'])->name('admin.blocks.floors.index');
        Route::get('/floors/{floor}/flats', [ResidentManagementController::class, 'flats'])->name('admin.floors.flats.index');

        // File Uploads
        Route::get('/uploads', [\App\Http\Controllers\Web\FileUploadController::class, 'index'])->name('admin.uploads.index');
        Route::post('/uploads', [\App\Http\Controllers\Web\FileUploadController::class, 'store'])->name('admin.uploads.store');
    });
});
