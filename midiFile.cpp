#include "midiFile.h"

#include <QFile>
#include <algorithm>

// Low-level helpers

namespace {

static quint32 be32(const uchar *d, int p)
{
    return (quint32(d[p])<<24)|(quint32(d[p+1])<<16)|(quint32(d[p+2])<<8)|d[p+3];
}

static quint16 be16(const uchar *d, int p)
{
    return quint16((quint16(d[p])<<8)|d[p+1]);
}

// Read a variable-length quantity; advances pos.
static quint32 vlq(const uchar *d, int size, int &pos)
{
    quint32 v = 0;
    for (int i = 0; i < 4 && pos < size; ++i) {
        uchar b = d[pos++];
        v = (v << 7) | (b & 0x7Fu);
        if (!(b & 0x80u)) break;
    }
    return v;
}

// Raw tick-level events from one track

struct RawEv {
    qint64 tick;
    int type;     // 0x80=NoteOff  0x90=NoteOn  0xFF51=Tempo
    int channel;
    int note;
    int velocity;
    quint32 tempoUs;  // only for type==0xFF51
};

static QList<RawEv> parseTrack(const uchar *d, int size)
{
    QList<RawEv> out;
    int pos = 0;
    qint64 tick = 0;
    uchar running = 0;

    while (pos < size) {
        tick += qint64(vlq(d, size, pos));
        if (pos >= size) break;
        uchar b = d[pos];

        // Meta event
        if (b == 0xFF) {
            ++pos;
            if (pos >= size) break;
            uchar mtype = d[pos++];
            quint32 len = vlq(d, size, pos);
            if (mtype == 0x51 && len == 3 && pos + 3 <= size) {
                quint32 t = (quint32(d[pos])<<16)|(quint32(d[pos+1])<<8)|d[pos+2];
                out.append({tick, 0xFF51, 0, 0, 0, t});
            }
            pos += int(len);
            continue;
        }

        // SysEx
        if (b == 0xF0 || b == 0xF7) {
            ++pos;
            pos += int(vlq(d, size, pos));
            continue;
        }

        // MIDI event (with running status)
        uchar status;
        if (b & 0x80u) {
            status = running = b; ++pos;
        } else {
            status = running;
        }

        uchar type = status & 0xF0u;
        uchar ch   = status & 0x0Fu;

        if (type == 0x80u || type == 0x90u) {
            if (pos + 2 > size) break;
            uchar note = d[pos++], vel = d[pos++];
            bool on = (type == 0x90u && vel > 0);
            out.append({tick, on ? 0x90 : 0x80, ch, note, vel, 0u});
        } else if (type == 0xA0u || type == 0xB0u || type == 0xE0u) {
            pos += 2;
        } else if (type == 0xC0u || type == 0xD0u) {
            pos += 1;
        } else {
            break; // unknown byte — bail on this track
        }
    }
    return out;
}

// Tempo-aware tick → millisecond conversion
struct TempoPt {
    qint64 tick;
    qint64 baseMs;
    quint32 tempoUs;
};

static qint64 tickToMs(qint64 tick, const QList<TempoPt> &map, int ppq)
{
    for (int i = map.size() - 1; i >= 0; --i) {
        if (tick >= map[i].tick)
            return map[i].baseMs + (tick - map[i].tick) * qint64(map[i].tempoUs) / (ppq * 1000LL);
    }
    return 0;
}

} // namespace

// Public entry point

QList<MidiNoteEvent> parseMidiFile(const QString &path, qint64 *durationMs, QString *errorMsg)
{
    auto fail = [&](const QString &msg) -> QList<MidiNoteEvent> {
        if (errorMsg) *errorMsg = msg;
        return {};
    };

    QFile f(path);
    if (!f.open(QIODevice::ReadOnly))
        return fail(QStringLiteral("Cannot open: %1").arg(path));

    const QByteArray raw = f.readAll();
    const auto *d = reinterpret_cast<const uchar *>(raw.constData());
    const int   sz = raw.size();

    if (sz < 14 || raw[0]!='M'||raw[1]!='T'||raw[2]!='h'||raw[3]!='d')
        return fail(QStringLiteral("Not a MIDI file: %1").arg(path));

    const quint16 ntrks = be16(d, 10);
    const quint16 div   = be16(d, 12);

    if (div & 0x8000u)
        return fail(QStringLiteral("SMPTE timing not supported: %1").arg(path));

    const int ppq = div; // ticks per quarter note

    // Collect raw events from all tracks
    QList<RawEv> allRaw;
    int fp = 8 + int(be32(d, 4)); // skip MThd (header length is usually 6)

    for (int t = 0; t < ntrks && fp + 8 <= sz; ++t) {
        if (raw[fp]!='M'||raw[fp+1]!='T'||raw[fp+2]!='r'||raw[fp+3]!='k') break;
        quint32 trkLen = be32(d, fp + 4);
        fp += 8;
        if (fp + int(trkLen) > sz) break;
        allRaw.append(parseTrack(d + fp, int(trkLen)));
        fp += int(trkLen);
    }

    std::stable_sort(allRaw.begin(), allRaw.end(),
        [](const RawEv &a, const RawEv &b){ return a.tick < b.tick; });

    // Build tempo map
    QList<TempoPt> tempoMap;
    tempoMap.append({0, 0, 500000u}); // default 120 BPM

    for (const RawEv &e : allRaw) {
        if (e.type == 0xFF51) {
            qint64 base = tickToMs(e.tick, tempoMap, ppq);
            tempoMap.append({e.tick, base, e.tempoUs});
        }
    }

    // Convert note events to milliseconds
    QList<MidiNoteEvent> result;
    qint64 maxMs = 0;

    for (const RawEv &e : allRaw) {
        if (e.type != 0x80 && e.type != 0x90) continue;
        MidiNoteEvent ev;
        ev.timeMs   = tickToMs(e.tick, tempoMap, ppq);
        ev.note     = e.note;
        ev.semitone = e.note % 12;
        ev.channel  = e.channel;
        ev.velocity = (e.type == 0x90) ? e.velocity : 0;
        result.append(ev);
        if (ev.timeMs > maxMs) maxMs = ev.timeMs;
    }

    // result is already sorted by tick (and tick order = time order after tempo conversion)
    if (durationMs) *durationMs = maxMs;
    return result;
}
