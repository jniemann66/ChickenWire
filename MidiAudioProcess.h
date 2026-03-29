#pragma once
#include "MidiAudio.h"

class QProcess;

// Audio backend for Linux and macOS
// Launches an external player (timidity) as a child process
// Pause/resume use SIGSTOP/SIGCONT on Unix

class MidiAudioProcess : public MidiAudio
{
public:
    MidiAudioProcess();
    ~MidiAudioProcess() override;

    bool start(const QString &filePath) override;
    void pause()  override;
    void resume() override;
    void stop()   override;

private:
    void killProcess();

    QString   m_playerExe;
    QProcess *m_process = nullptr;
};
