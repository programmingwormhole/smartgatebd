<?php

namespace App\Filament\Resources\EmergencyAlertResource\Pages;

use App\Filament\Resources\EmergencyAlertResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditEmergencyAlert extends EditRecord
{
    protected static string $resource = EmergencyAlertResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
