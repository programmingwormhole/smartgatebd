<?php

namespace App\Filament\Guard\Resources\VisitorResource\Pages;

use App\Filament\Guard\Resources\VisitorResource;
use Filament\Actions;
use Filament\Resources\Pages\CreateRecord;

class CreateVisitor extends CreateRecord
{
    protected static string $resource = VisitorResource::class;
}
