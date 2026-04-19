#pragma once
#include "midiFile.h"
#include <QElapsedTimer>
#include <QList>
#include <QObject>
#include <QString>

class MidiAudio;
class QTimer;

// Loads and schedules a Standard MIDI File for visualization.
// Audio playback is delegated to the platform MidiAudio backend.

class MidiPlayer : public QObject
{
    Q_OBJECT

    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(qreal position READ position NOTIFY positionChanged)  // 0.0–1.0
    Q_PROPERTY(int durationMs READ durationMs NOTIFY durationMsChanged)
    Q_PROPERTY(QString filePath READ filePath NOTIFY filePathChanged)
    Q_PROPERTY(QList<int> presentChannels READ presentChannels NOTIFY presentChannelsChanged)

public:
    enum State {
        Stopped,
        Playing,
        Paused
    };
    Q_ENUM(State)

    explicit MidiPlayer(QObject *parent = nullptr);
    ~MidiPlayer() override;

    State state() const { return m_state; }
    qreal position() const;
    int durationMs() const { return m_durationMs; }
    QString filePath() const { return m_filePath; }
    QList<int> presentChannels() const { return m_presentChannels; }

    Q_INVOKABLE bool load(const QString &path);
    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void seek(qreal fraction);  // 0.0–1.0; visualization only

signals:
    void noteOn (int semitone, int channel, int velocity);
    void noteOff(int semitone, int channel);
    void allNotesCleared();
    void stateChanged();
    void positionChanged();
    void durationMsChanged();
    void filePathChanged();
    void presentChannelsChanged();
    void loadError(const QString &message);

private slots:
    void tick();

private:
    void silenceAll();
    qint64 currentMs() const;

    QString m_filePath;
    QList<int> m_presentChannels;
    MidiAudio *m_audio = nullptr;

    QList<MidiNoteEvent> m_events;
    int m_nextEvent = 0;
    int m_durationMs = 0;

    State m_state = Stopped;
    QElapsedTimer m_clock;
    qint64 m_resumeOffsetMs = 0;

    QTimer *m_timer = nullptr;
};
