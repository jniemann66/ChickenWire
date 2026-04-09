// enumNotes.cpp — standalone utility
//
// Enumerates all 2048 12-bit values in which bit 0 (C) is always set,
// sorted by ascending popcount, then ascending value (= LSB-first within
// each popcount tier).  Each value is printed as a comma-separated list
// of note names.
//
// Build:  g++ -std=c++17 -O2 -o enumNotes enumNotes.cpp
// Run:    ./enumNotes

#include <algorithm>
#include <array>
#include <bitset>
#include <iostream>
#include <string>
#include <vector>

static constexpr std::array<const char*, 12> kNoteNames = {
    "C", "D\u266d", "D", "E\u266d", "E", "F",
    "F\u266f", "G", "A\u266d", "A", "B\u266d", "B"
};

static std::string formatMask(int mask)
{
    std::string result;
    for (int bit = 0; bit < 12; ++bit) {
        if (mask & (1 << bit)) {
            if (!result.empty())
                result += ",";
            result += kNoteNames[bit];
        }
    }
    return result;
}

int main()
{
    // Collect the 2048 12-bit values that have bit 0 set.
    std::vector<int> values;
    values.reserve(2048);
    for (int v = 1; v < 4096; v += 2) {   // odd numbers only — bit 0 always set
        values.push_back(v);
    }

    // Sort: primary = popcount ascending, secondary = value ascending.
    std::stable_sort(values.begin(), values.end(), [](int a, int b) {
        return std::bitset<12>(a).count() < std::bitset<12>(b).count();
    });

    // header
    std::cout << "upper 11 bits,12-bits,Note0,Note1,Note2,Note3,Note4,Note5,Note6,Note7,Note8,Note9,Note10,Note11" << '\n';

    // rows
    for (int v : values) {
        std::cout << ((v >> 1) & 2047) << "," << v << "," << formatMask(v) << '\n';
    }
}
