#pragma once
#include <QString>

// MIDI Audio playback interface

class MidiAudio
{
public:
    virtual ~MidiAudio() = default;

    // Begin playing filePath from the beginning.
    // Returns false if no player is available.
    virtual bool start(const QString &filePath) = 0;

    // Suspend playback mid-stream.
    virtual void pause() = 0;

    // Resume after pause() — continues from where it paused.
    virtual void resume() = 0;

    // Stop and reset; safe to call when already stopped.
    virtual void stop() = 0;

    // Returns a platform-appropriate concrete instance.
    static MidiAudio *create();
};
