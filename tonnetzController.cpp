#include "tonnetzController.h"

#include <QDebug>
#include <QVariantList>

#include <algorithm>

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
{
    // setHighlightedNotes({0, 4, 7, 11}); // Cmaj7
}

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
    if (!validateNames(names, "setNoteNames"))
        return false;

    if (m_noteNames == names)
        return true;

    m_noteNames = names;
    emit noteNamesChanged();
    return true;
}

bool TonnetzController::setMajorRootNoteNames(const QStringList &names)
{
    if (!validateNames(names, "setMajorNoteNames"))
        return false;

    if (m_majorRootNoteNames == names)
        return true;

    m_majorRootNoteNames = names;
    emit majorRootNoteNamesChanged();
    return true;
}

bool TonnetzController::setMinorRootNoteNames(const QStringList &names)
{
    if (!validateNames(names, "setMinorNoteNames"))
        return false;

    if (m_minorRootNoteNames == names)
        return true;

    m_minorRootNoteNames = names;
    emit minorRootNoteNamesChanged();
    return true;
}

void TonnetzController::setHighlightedNotes(const QVariantList &semitones)
{
    int mask = 0;
    for (const QVariant &v : semitones) {
        int s = v.toInt();
        if (s >= 0 && s < 12)
            mask |= (1 << s);
    }

    if (m_highlightedNotes == mask)
        return;

    m_highlightedNotes = mask;
    emit highlightedNotesChanged();
}

void TonnetzController::clearHighlightedNotes()
{
    if (m_highlightedNotes == 0)
        return;

    m_highlightedNotes = 0;
    emit highlightedNotesChanged();
}

void TonnetzController::setNrDistancesEnabled(bool enabled)
{
    if (m_nrDistancesEnabled == enabled)
        return;

    m_nrDistancesEnabled = enabled;
    emit nrDistancesEnabledChanged();
}

QVariantList TonnetzController::computeTriadDistances(int root, bool isMajor) const
{
    // Indices 0–11: distance to major triad with that root semitone.
    // Indices 12–23: distance to minor triad with that root semitone.
    QList<int> dist(24, -1);
    const int startIdx = isMajor ? root : root + 12;
    dist[startIdx] = 0;

    // Simple BFS — 24 nodes, use QList as a queue iterated by index.
    QList<int> queue;
    queue.reserve(24);
    queue.append(startIdx);

    for (int qi = 0; qi < queue.size(); ++qi) {
        const int cur = queue[qi];
        const bool maj = (cur < 12);
        const int  r   = cur % 12;
        const int  d   = dist[cur];

        if (maj) {
            // major(r) → minor(r), minor((r+9)%12), minor((r+4)%12)  [P, R, L]
            for (int nr : { r, (r + 9) % 12, (r + 4) % 12 }) {
                const int ni = nr + 12;
                if (dist[ni] < 0) { dist[ni] = d + 1; queue.append(ni); }
            }
        } else {
            // minor(r) → major(r), major((r+3)%12), major((r+8)%12)  [L, R, P]
            for (int nr : { r, (r + 3) % 12, (r + 8) % 12 }) {
                if (dist[nr] < 0) { dist[nr] = d + 1; queue.append(nr); }
            }
        }
    }

    QVariantList result;
    result.reserve(24);
    for (const int v : dist) result.append(v);
    return result;
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

void TonnetzController::handleNoteOn(int semitone)
{
    if (semitone < 0 || semitone >= 12)
        return;

    ++m_playingNoteCounts[semitone];
    const int newMask = m_playingNotes | (1 << semitone);
    if (newMask != m_playingNotes) {
        m_playingNotes = newMask;
        emit playingNotesChanged();
    }
}

void TonnetzController::handleNoteOff(int semitone)
{
    if (semitone < 0 || semitone >= 12)
        return;

    if (--m_playingNoteCounts[semitone] <= 0) {
        m_playingNoteCounts[semitone] = 0;
        const int newMask = m_playingNotes & ~(1 << semitone);
        if (newMask != m_playingNotes) {
            m_playingNotes = newMask;
            emit playingNotesChanged();
        }
    }
}

void TonnetzController::clearPlayingNotes()
{
    std::fill(std::begin(m_playingNoteCounts), std::end(m_playingNoteCounts), 0);
    if (m_playingNotes != 0) {
        m_playingNotes = 0;
        emit playingNotesChanged();
    }
}
