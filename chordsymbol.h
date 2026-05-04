#ifndef CHORDSYMBOL_H
#define CHORDSYMBOL_H

#include <cstdint>

#include <memory>
#include <string>

// These Flags need to be sufficient to capture print any chord without
// actually using any music theory; just instructions for what to print

enum class ChordQualityFlags : int64_t
{
	NC, // No chord

	// base chord type
	Omit3,
	Sus2,
	Sus2Post, // C7sus2 etc
	Dim,
	HalfDim,
	Min,
	Maj,
	Aug,
	Sus,
	SusPost,
	Sus4,
	Sus4Post, // C7sus4, C13sus4 etc

	Sharp4,

	// types of 5th (always post-)
	Omit5,
	Flat5,
	Sharp5,

	// types of 6th
	Min6Post, // add "min6" eg Cm (min6) - aeolian sound
	Flat6Post, // add flat-6 eg C (b6) ;  or CDim(b6) etc
	Six, // add a "6" : "C6, Cm6"
	Aug6, // may be required for French/Italian/German 6ths ?

	// types of 7ths
	Seven, // Just add "7" to whatever is already there
	Maj7, // for Major chords
	Maj7Post, // Cm(maj7), Cdim(maj7)

	// types of 9ths
	Flat9,
	Nine,
	SixNine,
	Sharp9,

	// types of 11ths
	Eleven,
	Sharp11,

	// types of 13ths
	Flat13,
	Thirteen,

	// sharp15
	Sharp15
};


struct ChordSymbol
{
	std::string root;
	int64_t quality{0ll};
	std::string bass;

	std::unique_ptr<ChordSymbol> denominator; // optional for building polychords (possibly recursively ...)
};

#endif // CHORDSYMBOL_H
