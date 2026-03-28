#pragma once
#include <QObject>
#include <QStringList>

class TonnetzController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList noteNames          READ noteNames          NOTIFY noteNamesChanged)
    Q_PROPERTY(QStringList majorRootNoteNames READ majorRootNoteNames NOTIFY majorRootNoteNamesChanged)
    Q_PROPERTY(QStringList minorRootNoteNames READ minorRootNoteNames NOTIFY minorRootNoteNamesChanged)
    // 12-bit bitmask: bit N is set when semitone N is in the highlighted set.
    Q_PROPERTY(int highlightedNotes READ highlightedNotes NOTIFY highlightedNotesChanged)

public:
    explicit TonnetzController(QObject *parent = nullptr);

    QStringList noteNames()          const { return m_noteNames;          }
    QStringList majorRootNoteNames() const { return m_majorRootNoteNames; }
    QStringList minorRootNoteNames() const { return m_minorRootNoteNames; }
    int         highlightedNotes()   const { return m_highlightedNotes;   }

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

signals:
    // Connect these from C++ to drive application logic
    void noteSelected (int semitone, int i, int j);
    void triadSelected(int root, int third, int fifth, bool isMajor);
    void noteNamesChanged();
    void majorRootNoteNamesChanged();
    void minorRootNoteNamesChanged();
    void highlightedNotesChanged();

private:
    static bool validateNames(const QStringList &names, const char *which);

    QStringList m_noteNames;
    QStringList m_majorRootNoteNames;
    QStringList m_minorRootNoteNames;
    int         m_highlightedNotes = 0;  // 12-bit bitmask
};
