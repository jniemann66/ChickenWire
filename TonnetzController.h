#pragma once
#include <QObject>
#include <QStringList>
#include <QVariantList>

class TonnetzController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QStringList noteNames          READ noteNames          NOTIFY noteNamesChanged)
    Q_PROPERTY(QStringList majorRootNoteNames READ majorRootNoteNames NOTIFY majorRootNoteNamesChanged)
    Q_PROPERTY(QStringList minorRootNoteNames READ minorRootNoteNames NOTIFY minorRootNoteNamesChanged)

    // 12-bit bitmask: bit N is set when semitone N is in the highlighted set.
    Q_PROPERTY(int  highlightedNotes      READ highlightedNotes      NOTIFY highlightedNotesChanged)
    Q_PROPERTY(int  playingNotes          READ playingNotes          NOTIFY playingNotesChanged)

    // When false, computeTriadDistances() returns an empty list and the views show no distance colours.
    Q_PROPERTY(bool nrDistancesEnabled    READ nrDistancesEnabled    WRITE setNrDistancesEnabled
                                                                     NOTIFY nrDistancesEnabledChanged)
public:
    explicit TonnetzController(QObject *parent = nullptr);

    QStringList noteNames() const { return m_noteNames;          }
    QStringList majorRootNoteNames() const { return m_majorRootNoteNames; }
    QStringList minorRootNoteNames() const { return m_minorRootNoteNames; }
    int highlightedNotes() const { return m_highlightedNotes;   }
    int playingNotes() const { return m_playingNotes;       }
    bool nrDistancesEnabled() const { return m_nrDistancesEnabled; }
    void setNrDistancesEnabled(bool enabled);

    // Called by QML after hit-testing
    Q_INVOKABLE void selectNote (int semitone, int i, int j);
    Q_INVOKABLE void selectTriad(int root, int third, int fifth, bool isMajor);

    // Replace a note-name set.  Each list must contain exactly 12 entries
    // (one per semitone, starting at C).  Returns false without changing
    // anything if the list is invalid.
    Q_INVOKABLE bool setNoteNames          (const QStringList &names);
    Q_INVOKABLE bool setMajorRootNoteNames (const QStringList &names);
    Q_INVOKABLE bool setMinorRootNoteNames (const QStringList &names);

    // Set the highlighted note set from a list of semitone values (0–11).
    // Pass an empty list (or call clearHighlightedNotes) to clear.
    Q_INVOKABLE void setHighlightedNotes (const QVariantList &semitones);
    Q_INVOKABLE void clearHighlightedNotes();

    // BFS over the 24-triad neo-Riemannian graph (P/R/L transformations).
    // Returns a list of 24 ints: indices 0–11 are distances to major triads
    // (root 0–11), indices 12–23 are distances to minor triads (root 0–11).
    // The starting triad has distance 0; all others are 1–5.
    Q_INVOKABLE QVariantList computeTriadDistances(int root, bool isMajor) const;

public slots:
    void handleNoteOn (int semitone);
    void handleNoteOff(int semitone);
    void clearPlayingNotes();

signals:
    // Connect these from C++ to drive application logic
    void noteSelected (int semitone, int i, int j);
    void triadSelected(int root, int third, int fifth, bool isMajor);
    void noteNamesChanged();
    void majorRootNoteNamesChanged();
    void minorRootNoteNamesChanged();
    void highlightedNotesChanged();
    void playingNotesChanged();
    void nrDistancesEnabledChanged();

private:
    static bool validateNames(const QStringList &names, const char *which);

    QStringList m_noteNames;
    QStringList m_majorRootNoteNames;
    QStringList m_minorRootNoteNames;
    int m_highlightedNotes = 0;     // 12-bit bitmask
    bool m_nrDistancesEnabled = false;
    int m_playingNotes = 0;
    int m_playingNoteCounts[12] = {};
};
