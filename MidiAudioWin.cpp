#include "MidiAudioWin.h"

#include <QDir>

#include <windows.h>
#include <mmsystem.h>

// MCI device alias used for all commands
static const wchar_t *ALIAS     = L"cw_midi";
static const wchar_t *PLAY_CMD  = L"play cw_midi";
static const wchar_t *PAUSE_CMD = L"pause cw_midi";
static const wchar_t *RESUME_CMD= L"resume cw_midi";
static const wchar_t *STOP_CMD  = L"stop cw_midi";
static const wchar_t *CLOSE_CMD = L"close cw_midi";

MidiAudioWin::~MidiAudioWin()
{
    stop();
}

bool MidiAudioWin::start(const QString &filePath)
{
    stop();

    // MCI requires native path separators; quote in case of spaces
    const QString native = QDir::toNativeSeparators(filePath);
    const QString openCmd = QStringLiteral("open \"%1\" type sequencer alias cw_midi")
                            .arg(native);

    MCIERROR err = mciSendString(openCmd.toStdWString().c_str(), nullptr, 0, nullptr);
    if (err != 0) return false;

    err = mciSendString(PLAY_CMD, nullptr, 0, nullptr);
    if (err != 0) {
        mciSendString(CLOSE_CMD, nullptr, 0, nullptr);
        return false;
    }

    m_open = true;
    return true;
}

void MidiAudioWin::pause()
{
    if (m_open)
        mciSendString(PAUSE_CMD, nullptr, 0, nullptr);
}

void MidiAudioWin::resume()
{
    if (m_open)
        mciSendString(RESUME_CMD, nullptr, 0, nullptr);
}

void MidiAudioWin::stop()
{
    if (!m_open) return;
    mciSendString(STOP_CMD,  nullptr, 0, nullptr);
    mciSendString(CLOSE_CMD, nullptr, 0, nullptr);
    m_open = false;
}
