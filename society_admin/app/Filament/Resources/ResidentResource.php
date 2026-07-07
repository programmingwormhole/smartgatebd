<?php

namespace App\Filament\Resources;

use App\Filament\Resources\ResidentResource\Pages;
use App\Filament\Resources\ResidentResource\RelationManagers;
use App\Models\Resident;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class ResidentResource extends Resource
{
    protected static ?string $model = Resident::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('user_id')
                    ->relationship('user', 'name')
                    ->required(),
                Forms\Components\Select::make('flat_id')
                    ->relationship('flat', 'id')
                    ->required(),
                Forms\Components\TextInput::make('monthly_rent')
                    ->required()
                    ->numeric()
                    ->default(0.00),
                Forms\Components\TextInput::make('role')
                    ->required(),
                Forms\Components\TextInput::make('monthly_maintenance_fee')
                    ->required()
                    ->numeric()
                    ->default(0.00),
                Forms\Components\TextInput::make('bill_generate_date')
                    ->required()
                    ->numeric()
                    ->default(1),
                Forms\Components\TextInput::make('rent')
                    ->required()
                    ->numeric()
                    ->default(0.00),
                Forms\Components\TextInput::make('bill_generate_day')
                    ->required()
                    ->numeric()
                    ->default(1),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('flat.id')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('monthly_rent')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('role'),
                Tables\Columns\TextColumn::make('monthly_maintenance_fee')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('bill_generate_date')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('rent')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('bill_generate_day')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
                Tables\Columns\TextColumn::make('updated_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListResidents::route('/'),
            'create' => Pages\CreateResident::route('/create'),
            'edit' => Pages\EditResident::route('/{record}/edit'),
        ];
    }
}
