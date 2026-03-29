#include "MidiAudioProcess.h"

#include <QProcess>
#include <QStandardPaths>

#ifdef Q_OS_UNIX
#  include <signal.h>
#endif

static QString findPlayerExe()
{
    for (const char *name : {"timidity", "timidity++", "timidity-gtk"}) {
        const QString p = QStandardPaths::findExecutable(QLatin1String(name));
        if (!p.isEmpty()) return p;
    }
    return {};
}

MidiAudioProcess::MidiAudioProcess()
    : m_playerExe(findPlayerExe())
{}

MidiAudioProcess::~MidiAudioProcess()
{
    stop();
}

bool MidiAudioProcess::start(const QString &filePath)
{
    stop(); // clean up any previous run
    if (m_playerExe.isEmpty()) return false;

    m_process = new QProcess;
    m_process->start(m_playerExe, {filePath});
    return m_process->waitForStarted(3000);
}

void MidiAudioProcess::pause()
{
#ifdef Q_OS_UNIX
    if (m_process && m_process->state() == QProcess::Running)
        ::kill(pid_t(m_process->processId()), SIGSTOP);
#endif
}

void MidiAudioProcess::resume()
{
#ifdef Q_OS_UNIX
    if (m_process)
        ::kill(pid_t(m_process->processId()), SIGCONT);
#endif
}

void MidiAudioProcess::stop()
{
    if (!m_process) return;
#ifdef Q_OS_UNIX
    // Unblock the process first so it can respond to terminate
    ::kill(pid_t(m_process->processId()), SIGCONT);
#endif
    m_process->terminate();
    m_process->waitForFinished(500);
    delete m_process;
    m_process = nullptr;
}
