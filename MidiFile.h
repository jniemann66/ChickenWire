#pragma once
#include <QList>
#include <QString>

// MidiNoteEvent : A single NoteOn or NoteOff event extracted from a Standard MIDI File.

struct MidiNoteEvent {
    qint64 timeMs;    // milliseconds from the start of the file
    int note;      // MIDI note number 0–127
    int semitone;  // note % 12  (pitch class: 0=C … 11=B)
    int channel;   // MIDI channel 0–15
    int velocity;  // > 0 → NoteOn,  0 → NoteOff
};

// parseMidiFile() : Parses SMF format 0 or 1, returns all note events sorted by timeMs.
// Returns an empty list on failure; sets *errorMsg if non-null.
// *durationMs (if non-null) receives the timestamp of the last event.

QList<MidiNoteEvent> parseMidiFile(const QString &path, qint64  *durationMs = nullptr, QString *errorMsg   = nullptr);