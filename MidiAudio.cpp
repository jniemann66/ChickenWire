#include "MidiAudio.h"

#ifdef Q_OS_WIN
#  include "MidiAudioWin.h"
MidiAudio *MidiAudio::create() { return new MidiAudioWin; }
#else
#  include "MidiAudioProcess.h"
MidiAudio *MidiAudio::create() { return new MidiAudioProcess; }
#endif
