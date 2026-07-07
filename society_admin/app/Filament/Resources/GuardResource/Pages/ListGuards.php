<?php

namespace App\Filament\Resources\GuardResource\Pages;

use App\Filament\Resources\GuardResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListGuards extends ListRecords
{
    protected static string $resource = GuardResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
