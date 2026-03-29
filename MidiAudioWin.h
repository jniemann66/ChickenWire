#pragma once
#include "MidiAudio.h"

// Audio backend for Windows.
// Uses the built-in MCI sequencer (winmm.dll) — no external tools required.
// Native pause/resume via MCI "pause" / "resume" commands.
class MidiAudioWin : public MidiAudio
{
public:
    ~MidiAudioWin() override;

    bool start(const QString &filePath) override;
    void pause()  override;
    void resume() override;
    void stop()   override;

private:
    bool m_open = false;
};
