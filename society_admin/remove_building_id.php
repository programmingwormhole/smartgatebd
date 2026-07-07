<?php

$dir = __DIR__ . '/app/Filament/Resources';
$files = glob($dir . '/*.php');

foreach ($files as $file) {
    $content = file_get_contents($file);
    // Remove Select::make('building_id')->...
    $content = preg_replace('/Forms\\\\Components\\\\Select::make\(\'building_id\'\)[^;]+;/s', '', $content);
    // Remove TextInput::make('building_id')->...
    $content = preg_replace('/Forms\\\\Components\\\\TextInput::make\(\'building_id\'\)[^;]+;/s', '', $content);
    // Remove TextColumn::make('building_id')->...
    $content = preg_replace('/Tables\\\\Columns\\\\TextColumn::make\(\'building_id\'\)[^,]+,/s', '', $content);
    
    file_put_contents($file, $content);
}

echo "Done.";
