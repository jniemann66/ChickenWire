#ifndef CHORDSYMBOL_H
#define CHORDSYMBOL_H

#include <cstdint>

#include <memory>
#include <string>

// These Flags need to be sufficient to capture print any chord without
// actually using any music theory; just instructions for what to print

enum class ChordQualityFlags : int64_t
{
	NC       = 0x0, // No chord

	// base chord type
	Omit3    = 0x1,
	Sus2     = 0x2,
	Sus2Post = 0x4, // C7sus2 etc
	Dim      = 0x8,
	HalfDim  = 0x10,
	Min      = 0x20,
	Maj      = 0x40,
	Aug      = 0x80,
	Sus      = 0x100,
	SusPost  = 0x200,
	Sus4     = 0x400,
	Sus4Post = 0x800, // C7sus4, C13sus4 etc

	Sharp4   = 0x1000,

	// types of 5th (always post-)
	Omit5    = 0x2000,
	Flat5    = 0x4000,
	Sharp5   = 0x8000,

	// types of 6th
	Min6Post = 0x10000, // add "min6" eg Cm (min6) - aeolian sound
	Flat6Post = 0x20000, // add flat-6 eg C (b6) ;  or CDim(b6) etc
	Six      = 0x40000, // add a "6" : "C6, Cm6"
	Aug6     = 0x80000, // may be required for French/Italian/German 6ths ?

	// types of 7ths
	Seven    = 0x100000, // Just add "7" to whatever is already there
	Maj7     = 0x200000, // for Major chords
	Maj7Post = 0x400000, // Cm(maj7), Cdim(maj7)

	// types of 9ths
	Flat9    = 0x800000,
	Nine     = 0x1000000,
	SixNine  = 0x2000000,
	Sharp9   = 0x4000000,

	// types of 11ths
	Eleven   = 0x8000000,
	Sharp11  = 0x10000000,

	// types of 13ths
	Flat13   = 0x20000000,
	Thirteen = 0x40000000,

	// sharp15
	Sharp15  = 0x80000000
};


struct ChordSymbol
{
	std::string root;
	int64_t quality{0ll};
	std::string bass;

	std::unique_ptr<ChordSymbol> denominator; // optional for building polychords (possibly recursively ...)
};

#endif // CHORDSYMBOL_H
