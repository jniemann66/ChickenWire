#include "midiPlayer.h"
#include "midiAudio.h"

#include <QSet>
#include <QTimer>
#include <algorithm>

MidiPlayer::MidiPlayer(QObject *parent)
    : QObject(parent)
    , m_audio(MidiAudio::create())
    , m_timer(new QTimer(this))
{
    m_timer->setInterval(8);  // ~8 ms — fine for note-visualization latency
    connect(m_timer, &QTimer::timeout, this, &MidiPlayer::tick);
}

MidiPlayer::~MidiPlayer()
{
    // Stop timer and audio before destruction
    m_timer->stop();
    m_audio->stop();
    delete m_audio;
}

bool MidiPlayer::load(const QString &path)
{
    stop();

    QString errMsg;
    qint64 dur = 0;
    m_events = parseMidiFile(path, &dur, &errMsg);

    if (m_events.isEmpty() && !errMsg.isEmpty()) {
        emit loadError(tr("Could not load: %1").arg(errMsg));
        return false;
    }

    m_durationMs = int(dur);
    m_nextEvent = 0;
    m_filePath = path;

    QSet<int> seen;
    for (const MidiNoteEvent &e : m_events)
        seen.insert(e.channel);
    m_presentChannels = seen.values();
    std::sort(m_presentChannels.begin(), m_presentChannels.end());

    emit filePathChanged();
    emit durationMsChanged();
    emit positionChanged();
    emit presentChannelsChanged();
    return true;
}

// Playback control

void MidiPlayer::play()
{
    if (m_events.isEmpty() || m_state == Playing) return;

    if (m_state == Stopped) {
        m_resumeOffsetMs = 0;
        m_nextEvent = 0;
        m_audio->start(m_filePath);
    } else {
        // Paused — audio resumes from where it paused
        m_audio->resume();
    }

    m_clock.restart();
    m_state = Playing;
    emit stateChanged();
    m_timer->start();
}

void MidiPlayer::pause()
{
    if (m_state != Playing) return;

    m_timer->stop();
    m_resumeOffsetMs = currentMs();
    m_audio->pause();
    silenceAll();
    m_state = Paused;
    emit stateChanged();
}

void MidiPlayer::stop()
{
    if (m_state == Stopped) return;

    m_timer->stop();
    m_audio->stop();
    silenceAll();
    m_resumeOffsetMs = 0;
    m_nextEvent = 0;
    m_state = Stopped;
    emit stateChanged();
    emit positionChanged();
}

void MidiPlayer::seek(qreal fraction)
{
    if (m_events.isEmpty()) return;
    fraction = qBound(0.0, fraction, 1.0);

    const bool wasPlaying = (m_state == Playing);
    if (wasPlaying) m_timer->stop();

    silenceAll();
    m_resumeOffsetMs = qRound64(fraction * m_durationMs);

    m_nextEvent = int(std::lower_bound(
        m_events.cbegin(), m_events.cend(), m_resumeOffsetMs,
        [](const MidiNoteEvent &e, qint64 t) { return e.timeMs < t; }
    ) - m_events.cbegin());

    emit positionChanged();

    if (wasPlaying) {
        m_clock.restart();
        m_timer->start();
        // Audio cannot seek in external players — it continues from its current position.
    }
}

// Internal helpers

qint64 MidiPlayer::currentMs() const
{
    return (m_state == Playing) ? m_resumeOffsetMs + m_clock.elapsed()
                                : m_resumeOffsetMs;
}

qreal MidiPlayer::position() const
{
    if (m_durationMs == 0) return 0.0;
    return qBound(0.0, double(currentMs()) / m_durationMs, 1.0);
}

void MidiPlayer::silenceAll()
{
    emit allNotesCleared();
}

// Timer tick — dispatch visualization events

void MidiPlayer::tick()
{
    const qint64 now = currentMs();

    while (m_nextEvent < m_events.size() && m_events.at(m_nextEvent).timeMs <= now) {
        const MidiNoteEvent &e = m_events.at(m_nextEvent++);

        if (e.velocity > 0)
            emit noteOn(e.semitone, e.channel, e.velocity);
        else
            emit noteOff(e.semitone, e.channel);
    }

    emit positionChanged();

    if (m_nextEvent >= m_events.size()) {
        m_timer->stop();
        m_audio->stop();
        silenceAll();
        m_resumeOffsetMs = 0;
        m_nextEvent = 0;
        m_state = Stopped;
        emit stateChanged();
        emit positionChanged();
    }
}
