#include "chordsymbol.h"

#include <vector>

std::string ChordSymbol::toHtml()
{
	std::vector<std::string> parts;

	// root note
	parts.push_back(root);

	// base chord type
	if (quality & ChordQualityFlags::Sus2)
		parts.emplace_back(u8"sus2");

	if (quality & ChordQualityFlags::Dim)
		parts.emplace_back(u8"\u00B0");

	if (quality & ChordQualityFlags::HalfDim)
		parts.emplace_back(u8"\u00F8");

	if (quality & ChordQualityFlags::Min)
		parts.emplace_back(u8"m");

	// if (quality & ChordQualityFlags::Maj)
	// 	parts.emplace_back(u8"\u0394");

	if (quality & ChordQualityFlags::Aug)
		parts.emplace_back(u8"+");

	if (quality & ChordQualityFlags::Sus)
		parts.emplace_back(u8"sus");

	if (quality & ChordQualityFlags::Sus4)
		parts.emplace_back(u8"sus4");

	// number
	if (quality & ChordQualityFlags::Six)
		parts.emplace_back(u8"6");

	if (quality & ChordQualityFlags::Seven)
		parts.emplace_back(u8"7");

	if (quality & ChordQualityFlags::Maj7)
		parts.emplace_back(u8"\u0394" "7");

	if (quality & ChordQualityFlags::Nine)
		parts.emplace_back(u8"9");

	if (quality & ChordQualityFlags::Maj9)
		parts.emplace_back(u8"\u0394" "9");

	if (quality & ChordQualityFlags::Eleven)
		parts.emplace_back(u8"11");

	if (quality & ChordQualityFlags::Maj11)
		parts.emplace_back(u8"\u0394" "11");

	if (quality & ChordQualityFlags::Thirteen)
		parts.emplace_back(u8"13");

	if (quality & ChordQualityFlags::Maj13)
		parts.emplace_back(u8"\u0394" "13");

	// todo: all the extensions

	// todo: put the parts together
	return {};

}
