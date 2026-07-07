<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class FileUploadController extends Controller
{
    public function index()
    {
        return view('uploads.index');
    }

    public function store(Request $request)
    {
        $request->validate([
            'document' => 'required|file|mimes:pdf,doc,docx,jpg,jpeg,png|max:10240', // 10MB max
            'title' => 'required|string|max:255',
        ]);

        if ($request->hasFile('document')) {
            $file = $request->file('document');
            $filename = time() . '_' . $file->getClientOriginalName();
            
            // Store locally in public storage for now
            $path = $file->storeAs('uploads/documents', $filename, 'public');

            return back()->with('success', 'File "' . $request->title . '" uploaded successfully. Path: ' . $path);
        }

        return back()->withErrors(['message' => 'Failed to upload file']);
    }
}
