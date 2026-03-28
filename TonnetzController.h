#pragma once
#include <QObject>
#include <QStringList>

class TonnetzController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QStringList noteNames      READ noteNames      NOTIFY noteNamesChanged)
    Q_PROPERTY(QStringList majorRootNoteNames READ majorRootNoteNames NOTIFY majorRootNoteNamesChanged)
    Q_PROPERTY(QStringList minorRootNoteNames READ minorRootNoteNames NOTIFY minorRootNoteNamesChanged)

public:
    explicit TonnetzController(QObject *parent = nullptr);

    QStringList noteNames()      const { return m_noteNames;      }
    QStringList majorRootNoteNames() const { return m_majorRootNoteNames; }
    QStringList minorRootNoteNames() const { return m_minorRootNoteNames; }

    // Called by QML after hit-testing
    Q_INVOKABLE void selectNote (int semitone, int i, int j);
    Q_INVOKABLE void selectTriad(int root, int third, int fifth, bool isMajor);

    // Replace a note-name set.  Each list must contain exactly 12 entries
    // (one per semitone, starting at C).  Returns false without changing
    // anything if the list is invalid.
    Q_INVOKABLE bool setNoteNames     (const QStringList &names);
    Q_INVOKABLE bool setMajorNoteNames(const QStringList &names);
    Q_INVOKABLE bool setMinorNoteNames(const QStringList &names);

signals:
    // Connect these from C++ to drive application logic
    void noteSelected (int semitone, int i, int j);
    void triadSelected(int root, int third, int fifth, bool isMajor);
    void noteNamesChanged();
    void majorRootNoteNamesChanged();
    void minorRootNoteNamesChanged();

private:
    static bool validateNames(const QStringList &names, const char *which);

    QStringList m_noteNames;
    QStringList m_majorRootNoteNames;
    QStringList m_minorRootNoteNames;
};
