#include "chordsymbol.h"

#include <string_view>
#include <vector>

static void replaceAll(std::string &s, std::string_view from, std::string_view to)
{
	for (size_t pos = 0; (pos = s.find(from, pos)) != std::string::npos; pos += to.size())
		s.replace(pos, from.size(), to);
}

std::string ChordSymbol::toText(ChordSymbolFormat fmt)
{
	std::vector<std::string> mainParts;
	std::vector<std::string> alterations;

	if (quality == ChordQualityFlags::Empty)
		return {};

	if (quality == ChordQualityFlags::NC)
		return "N.C.";

	// root note
	mainParts.push_back(root);

	// base chord type \u2014 mutually exclusive, first match wins
	if (auto s = [&]() -> std::string {
		if (quality & ChordQualityFlags::Sus2)    return "sus2";
		if (quality & ChordQualityFlags::Dim)     return u8"\u00B0";
		if (quality & ChordQualityFlags::HalfDim) return u8"\u00F8";
		if (quality & ChordQualityFlags::Min)     return "m";
		if (quality & ChordQualityFlags::Maj)     return {};  // major is silent
		if (quality & ChordQualityFlags::Aug)     return "+";
		if (quality & ChordQualityFlags::Sus)     return "sus";
		if (quality & ChordQualityFlags::Sus4)    return "sus4";
		return {};
	}(); !s.empty())
		mainParts.push_back(std::move(s));

	// extensions \u2014 mutually exclusive, first match wins
	if (auto s = [&]() -> std::string {
		if (quality & ChordQualityFlags::Six)      return "6";
		if (quality & ChordQualityFlags::Seven)    return "7";
		if (quality & ChordQualityFlags::Maj7)     return u8"\u03947";
		if (quality & ChordQualityFlags::Nine)     return "9";
		if (quality & ChordQualityFlags::Maj9)     return u8"\u03949";
		if (quality & ChordQualityFlags::SixNine)  return "6/9";
		if (quality & ChordQualityFlags::Eleven)   return "11";
		if (quality & ChordQualityFlags::Maj11)    return u8"\u039411";
		if (quality & ChordQualityFlags::Thirteen) return "13";
		if (quality & ChordQualityFlags::Maj13)    return u8"\u039413";
		return {};
	}(); !s.empty())
		mainParts.push_back(std::move(s));

	// alterations — not mutually exclusive, all that apply
	if (quality & ChordQualityFlags::Omit3)    alterations.emplace_back("omit3");
	if (quality & ChordQualityFlags::Add2)     alterations.emplace_back("add2");
	if (quality & ChordQualityFlags::Sus2Post) alterations.emplace_back("sus2");
	if (quality & ChordQualityFlags::SusPost)  alterations.emplace_back("sus");
	if (quality & ChordQualityFlags::Sus4Post) alterations.emplace_back("sus4");
	if (quality & ChordQualityFlags::Sharp4)   alterations.emplace_back(u8"♯4");
	if (quality & ChordQualityFlags::Omit5)    alterations.emplace_back("omit5");
	if (quality & ChordQualityFlags::Flat5)    alterations.emplace_back(u8"♭5");
	if (quality & ChordQualityFlags::Sharp5)   alterations.emplace_back(u8"♯5");
	if (quality & ChordQualityFlags::Min6Post) alterations.emplace_back("min6");
	if (quality & ChordQualityFlags::Flat6Post) alterations.emplace_back(u8"♭6");
	if (quality & ChordQualityFlags::Aug6)     alterations.emplace_back("+6");
	if (quality & ChordQualityFlags::Maj7Post) alterations.emplace_back("maj7");
	if (quality & ChordQualityFlags::Flat9)    alterations.emplace_back(u8"♭9");
	if (quality & ChordQualityFlags::Add9)     alterations.emplace_back("add9");
	if (quality & ChordQualityFlags::Sharp9)   alterations.emplace_back(u8"♯9");
	if (quality & ChordQualityFlags::Add11)    alterations.emplace_back("add11");
	if (quality & ChordQualityFlags::Sharp11)  alterations.emplace_back(u8"♯11");
	if (quality & ChordQualityFlags::Flat13)   alterations.emplace_back(u8"♭13");
	if (quality & ChordQualityFlags::Alt)      alterations.emplace_back("alt");
	if (quality & ChordQualityFlags::Sharp15)  alterations.emplace_back(u8"♯15");

	// push alterations onto mainParts
	if (!alterations.empty()) {
		std::string alt;
		for (const auto &a : alterations)
			alt += a;
		if (parensAroundAlterations)
			alt = "(" + alt + ")";
		if (fmt == ChordSymbolFormat::Html)
			alt = "<sup>" + alt + "</sup>";
		mainParts.push_back(std::move(alt));
	}

	if (!bass.empty())
		mainParts.push_back("/" + bass);

	// assemble
	std::string result;
	for (const auto &p : mainParts)
		result += p;

	// symbol substitution
	switch (fmt) {
	case ChordSymbolFormat::Utf8:
		break;
	case ChordSymbolFormat::Ascii:
		replaceAll(result, u8"ø7",  "m7b5");  // must precede ø → m7b5
		replaceAll(result, u8"♭",   "b");
		replaceAll(result, u8"♯",   "#");
		replaceAll(result, u8"°",   "dim");
		replaceAll(result, u8"ø",   "m7b5");
		replaceAll(result, u8"Δ",   "maj");
		break;
	case ChordSymbolFormat::Html:
		replaceAll(result, u8"♭",   "&#9837;");
		replaceAll(result, u8"♯",   "&#9839;");
		replaceAll(result, u8"°",   "&deg;");
		replaceAll(result, u8"ø",   "&oslash;");
		replaceAll(result, u8"Δ",   "&Delta;");
		break;
	}

	return result;
}
