<?php

return [
    'default' => env('FIREBASE_PROJECT', 'app'),

    'projects' => [
        'app' => [
            'credentials' => env('FIREBASE_CREDENTIALS', storage_path('app/firebase-auth.json')),
            'project_id' => env('FIREBASE_PROJECT_ID'),
        ],
    ],
];
