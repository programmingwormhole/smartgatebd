@extends('layouts.app')

@section('title', 'File Uploads')
@section('header', 'File Uploads')

@section('content')
<div class="max-w-3xl">
    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-6 md:p-8">
        
        <h2 class="text-xl font-semibold mb-6">Upload Document</h2>
        <p class="text-sm text-gray-500 mb-6">Upload building guidelines, rules, forms or bulk data. Supported formats: PDF, DOC, JPG, PNG.</p>

        @if (session('success'))
            <div class="bg-green-50 text-green-700 p-4 rounded-xl mb-6 flex items-center gap-3 text-sm">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                {{ session('success') }}
            </div>
        @endif
        
        @if ($errors->any())
            <div class="bg-red-50 text-red-600 p-4 rounded-xl mb-6 text-sm">
                <ul class="list-disc pl-5">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form method="POST" action="{{ route('admin.uploads.store') }}" enctype="multipart/form-data">
            @csrf
            
            <div class="space-y-6">
                <div>
                    <label class="block text-sm font-medium mb-1" for="title">Document Title</label>
                    <input type="text" id="title" name="title" value="{{ old('title') }}" required class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition" placeholder="e.g. Society Rules 2026">
                </div>
                
                <div>
                    <label class="block text-sm font-medium mb-1" for="document">Select File</label>
                    <input type="file" id="document" name="document" required class="w-full px-4 py-2 border border-dashed border-gray-300 rounded-lg focus:ring-2 focus:ring-primary focus:border-primary outline-none transition file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100 cursor-pointer">
                    <p class="text-xs text-gray-400 mt-2">Maximum file size: 10MB.</p>
                </div>
            </div>

            <div class="mt-8 flex justify-end">
                <button type="submit" class="bg-primary hover:bg-blue-600 text-white font-medium py-2 px-6 rounded-lg transition duration-200">
                    Upload File
                </button>
            </div>
        </form>

    </div>
</div>
@endsection
