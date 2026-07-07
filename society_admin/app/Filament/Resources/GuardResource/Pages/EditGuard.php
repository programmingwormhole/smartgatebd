<?php

namespace App\Filament\Resources\GuardResource\Pages;

use App\Filament\Resources\GuardResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditGuard extends EditRecord
{
    protected static string $resource = GuardResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
