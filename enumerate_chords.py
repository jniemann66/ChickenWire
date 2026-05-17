#!/usr/bin/env python3
"""Enumerate all 2048 note combinations rooted on C (bit 0 always set)."""

import csv

NOTE_NAMES = ['C', 'D♭', 'D', 'E♭', 'E', 'F', 'F♯', 'G', 'A♭', 'A', 'B♭', 'B']

OUTPUT = 'chord_combinations.csv'


def main():
    with open(OUTPUT, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['bits_1_11', 'note_count', 'notes'])
        for upper in range(2048):
            full = (upper << 1) | 1
            notes = [NOTE_NAMES[b] for b in range(12) if full & (1 << b)]
            writer.writerow([upper, full.bit_count(), ' '.join(notes)])


if __name__ == '__main__':
    main()
