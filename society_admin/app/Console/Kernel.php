<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // Generate monthly bills daily at 2 AM
        // The command checks each resident's bill_generate_date
        // If today matches their billing date, bills are generated
        // If no specific date is set, defaults to 1st of month
        $schedule->command('bills:generate')
            ->dailyAt('02:00')
            ->onOneServer()
            ->withoutOverlapping();

        // Run queued jobs
        // $schedule->command('queue:work --stop-when-empty')
        //     ->everyMinute()
        //     ->withoutOverlapping();
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
