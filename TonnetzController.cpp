#include "TonnetzController.h"
#include <QDebug>

static const char *NOTE_NAMES[] = {
    "C","C#","D","D#","E","F","F#","G","G#","A","A#","B"
};

TonnetzController::TonnetzController(QObject *parent) : QObject(parent) {}

void TonnetzController::selectNote(int semitone, int i, int j)
{
    qDebug() << "Note:"  << NOTE_NAMES[semitone & 0xF]
             << "  lattice (" << i << "," << j << ")";
    emit noteSelected(semitone, i, j);
}

void TonnetzController::selectTriad(int root, int third, int fifth, bool isMajor)
{
    qDebug() << "Triad:" << NOTE_NAMES[root & 0xF]
             << (isMajor ? "major" : "minor")
             << " [" << NOTE_NAMES[root  & 0xF]
             << NOTE_NAMES[third & 0xF]
             << NOTE_NAMES[fifth & 0xF] << "]";
    emit triadSelected(root, third, fifth, isMajor);
}
