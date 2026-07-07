<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Visitor;
use Carbon\Carbon;

class ExpireVisitors extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'visitors:expire';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Mark visitors as expired if to_date has passed';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $count = Visitor::where('to_date', '<', Carbon::now())
            ->where('status', 'approved')
            ->update(['status' => 'rejected']); // assuming rejected means invalid/expired

        $this->info("Expired {$count} visitors.");
    }
}
