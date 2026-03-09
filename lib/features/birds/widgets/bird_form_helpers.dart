import 'package:budgie_breeding_tracker/core/enums/bird_enums.dart';

/// Internal prefix used to embed custom color name inside notes field.
const birdFormColorPrefix = 'color:';

/// Extracts the custom color note embedded at the start of the notes field.
String? extractColorNote(String? notes) {
  if (notes == null || !notes.startsWith(birdFormColorPrefix)) return null;
  final eol = notes.indexOf('\n');
  return eol == -1
      ? notes.substring(birdFormColorPrefix.length)
      : notes.substring(birdFormColorPrefix.length, eol);
}

/// Returns the notes body without the color-note prefix line.
String? notesBody(String? notes) {
  if (notes == null || !notes.startsWith(birdFormColorPrefix)) return notes;
  final eol = notes.indexOf('\n');
  if (eol == -1) return null;
  final body = notes.substring(eol + 1);
  return body.isEmpty ? null : body;
}

/// Builds the combined notes string from color note and user notes.
String? buildNotes({
  required BirdColor? colorMutation,
  required String colorNoteText,
  required String notesText,
}) {
  final colorNote = colorNoteText.trim();
  final notes = notesText.trim();
  if (colorMutation == BirdColor.other && colorNote.isNotEmpty) {
    return notes.isEmpty
        ? '$birdFormColorPrefix$colorNote'
        : '$birdFormColorPrefix$colorNote\n$notes';
  }
  return notes.isEmpty ? null : notes;
}
