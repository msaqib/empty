<?php

namespace App\Http\Controllers;

use App\Models\Note;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Validation\ValidationException;

class NotesController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(): JsonResponse
    {
        $notes = Note::all();
        return response()->json($notes);
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'nullable|string',
        ]);

        $note = Note::create($validated);
        return response()->json($note, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id): JsonResponse
    {
        $note = Note::findOrFail($id);
        return response()->json($note);
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $note = Note::findOrFail($id);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'content' => 'nullable|string',
        ]);

        $note->update($validated);
        return response()->json($note);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id): JsonResponse
    {
        $note = Note::findOrFail($id);
        $note->delete();
        return response()->json(['message' => 'Note deleted successfully']);
    }
}

