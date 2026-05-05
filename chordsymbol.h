#ifndef CHORDSYMBOL_H
#define CHORDSYMBOL_H

#include <cstdint>

#include <memory>
#include <string>

// These Flags need to be sufficient to print any chord without
// actually using any music theory; just instructions for what to print

enum class ChordQualityFlags : uint64_t
{
	Empty    = 0x0, // Don't display a chord symbol

	// base chord/triad type
	Sus2     = 0x1,
	Dim      = 0x2,
	HalfDim  = 0x4,
	Min      = 0x8,
	Maj      = 0x10,
	Aug      = 0x20,
	Sus      = 0x40,
	Sus4     = 0x80,

	// extensions
	Six      = 0x100,   // add a "6" : "C6, Cm6"
	Seven    = 0x200,   // Just add "7" to whatever is already there
	Maj7     = 0x400,   // for Maj7th chords only
	Nine     = 0x800,
	Maj9     = 0x1000,
	SixNine  = 0x2000,
	Eleven   = 0x4000,
	Maj11    = 0x8000,
	Thirteen = 0x10000,
	Maj13    = 0x20000,

	// alterations
	Omit3    = 0x40000,
	Add2     = 0x80000,
	Sus2Post = 0x100000,  // C7sus2 etc
	SusPost  = 0x200000,
	Sus4Post = 0x400000,  // C7sus4, C13sus4 etc
	Sharp4   = 0x800000,
	Omit5    = 0x1000000,
	Flat5    = 0x2000000,
	Sharp5   = 0x4000000,
	Min6Post  = 0x8000000,   // add "min6" eg Cm (min6) - aeolian sound
	Flat6Post = 0x10000000,  // add flat-6 eg C (b6) ;  or CDim(b6) etc
	Aug6      = 0x20000000,  // may be required for French/Italian/German 6ths ?
	Maj7Post  = 0x40000000,  // Cm(maj7), Cdim(maj7)
	Flat9     = 0x80000000,
	Add9      = 0x100000000,
	Sharp9    = 0x200000000,
	Add11     = 0x400000000,
	Sharp11   = 0x800000000,
	Flat13    = 0x1000000000,
	Alt       = 0x2000000000, // altered chord
	Sharp15   = 0x4000000000,

	// NC (sentinel)
	NC = 0x8000000000000000 // No Chord (Symbol to explicitly say "N.C.")
};

inline constexpr ChordQualityFlags operator|(ChordQualityFlags lhs, ChordQualityFlags rhs) {
	return static_cast<ChordQualityFlags>(
		static_cast<uint64_t>(lhs) | static_cast<uint64_t>(rhs)
	);
}

inline constexpr uint64_t operator&(ChordQualityFlags lhs, ChordQualityFlags rhs) {
	return static_cast<uint64_t>(lhs) & static_cast<uint64_t>(rhs);
}

struct ChordSymbol
{
	std::string root;
	ChordQualityFlags quality{0ll};
	std::string bass;

	std::unique_ptr<ChordSymbol> denominator; // optional for building polychords (possibly recursively ...)

	std::string toHtml();
};

#endif // CHORDSYMBOL_H
