#include "TonnetzController.h"

#include <QDebug>

// default names
static const QStringList DEFAULT_NOTE_NAMES = {
    "C","C♯","D","E♭","E","F","F♯","G","A♭","A","B♭","B"
};

// default root note names for Major Triads
static const QStringList DEFAULT_MAJOR_ROOT_NOTE_NAMES = {
    "C","D♭","D","E♭","E","F","F♯","G","A♭","A","B♭","B"
};

// default root note names for Minor Triads
static const QStringList DEFAULT_MINOR_ROOT_NOTE_NAMES = {
    "C","C♯","D","E♭","E","F","F♯","G","G♯","A","B♭","B"
};

TonnetzController::TonnetzController(QObject *parent)
    : QObject(parent)
    , m_noteNames(DEFAULT_NOTE_NAMES)
    , m_majorRootNoteNames(DEFAULT_MAJOR_ROOT_NOTE_NAMES)
    , m_minorRootNoteNames(DEFAULT_MINOR_ROOT_NOTE_NAMES)
{}

bool TonnetzController::validateNames(const QStringList &names, const char *which)
{
    if (names.size() != 12) {
        qWarning() << which << ": expected 12 entries, got" << names.size();
        return false;
    }
    return true;
}

bool TonnetzController::setNoteNames(const QStringList &names)
{
    if (!validateNames(names, "setNoteNames")) return false;
    if (m_noteNames == names) return true;
    m_noteNames = names;
    emit noteNamesChanged();
    return true;
}

bool TonnetzController::setMajorNoteNames(const QStringList &names)
{
    if (!validateNames(names, "setMajorNoteNames")) return false;
    if (m_majorRootNoteNames == names) return true;
    m_majorRootNoteNames = names;
    emit majorRootNoteNamesChanged();
    return true;
}

bool TonnetzController::setMinorNoteNames(const QStringList &names)
{
    if (!validateNames(names, "setMinorNoteNames")) return false;
    if (m_minorRootNoteNames == names) return true;
    m_minorRootNoteNames = names;
    emit minorRootNoteNamesChanged();
    return true;
}

void TonnetzController::selectNote(int semitone, int i, int j)
{
    qDebug() << "Note:"  << m_noteNames.value(semitone & 0xF)
             << "  lattice (" << i << "," << j << ")";
    emit noteSelected(semitone, i, j);
}

void TonnetzController::selectTriad(int root, int third, int fifth, bool isMajor)
{
    const QStringList &names = isMajor ? m_majorRootNoteNames : m_minorRootNoteNames;
    qDebug() << "Triad:" << names.value(root & 0xF)
             << (isMajor ? "major" : "minor")
             << " [" << names.value(root  & 0xF)
             << m_noteNames.value(third & 0xF)
             << m_noteNames.value(fifth & 0xF) << "]";
    emit triadSelected(root, third, fifth, isMajor);
}
