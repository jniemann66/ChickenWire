#include "midiAudio.h"

#ifdef Q_OS_WIN
	#include "MidiAudioWin.h"
MidiAudio *MidiAudio::create() { return new MidiAudioWin; }
#else
	#include "midiAudioProcess.h"
MidiAudio *MidiAudio::create() { return new MidiAudioProcess; }
#endif
