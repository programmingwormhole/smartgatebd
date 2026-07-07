<?php

namespace App\Filament\Pages\Auth;

use Filament\Pages\Auth\Login as BaseLogin;
use Filament\Forms\Form;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Component;
use Filament\Facades\Filament;

class Login extends BaseLogin
{
    public function mount(): void
    {
        parent::mount();

        $panelId = Filament::getCurrentPanel()->getId();
        
        $loginData = match($panelId) {
            'admin' => 'admin@smartgate.com',
            'resident' => 'resident@smartgate.com',
            'guard' => 'guard@smartgate.com',
            default => '',
        };

        if ($loginData && app()->environment() !== 'production') {
            $this->form->fill([
                'login' => $loginData,
                'password' => 'password',
                'remember' => true,
            ]);
        }
    }
    public function form(Form $form): Form
    {
        return $form
            ->schema([
                $this->getLoginFormComponent(),
                $this->getPasswordFormComponent(),
                $this->getRememberFormComponent(),
            ])
            ->statePath('data');
    }

    protected function getLoginFormComponent(): Component
    {
        return TextInput::make('login')
            ->label('Email or Phone')
            ->required()
            ->autocomplete()
            ->autofocus()
            ->extraInputAttributes(['tabindex' => 1]);
    }

    protected function getCredentialsFromFormData(array $data): array
    {
        $login_type = filter_var($data['login'], FILTER_VALIDATE_EMAIL) ? 'email' : 'phone';

        return [
            $login_type => $data['login'],
            'password' => $data['password'],
        ];
    }
}
