#include "noteNameDialog.h"

#include <QComboBox>
#include <QDialogButtonBox>
#include <QGridLayout>
#include <QLabel>
#include <QPushButton>
#include <QVBoxLayout>

static const QStringList kDefaultNoteNames = {
    "C","C♯","D","E♭","E","F","F♯","G","A♭","A","B♭","B"
};
static const QStringList kDefaultMajorRootNames = {
    "C","D♭","D","E♭","E","F","F♯","G","A♭","A","B♭","B"
};
static const QStringList kDefaultMinorRootNames = {
    "C","C♯","D","E♭","E","F","F♯","G","G♯","A","B♭","B"
};

// Enharmonic choices offered in each combo. Naturals have one entry; black-key
// slots offer both spellings so the user can just click rather than type.
static const QStringList kEnharmonics[12] = {
    {"C"},
    {"C♯", "D♭"},
    {"D"},
    {"D♯", "E♭"},
    {"E"},
    {"F"},
    {"F♯", "G♭"},
    {"G"},
    {"G♯", "A♭"},
    {"A"},
    {"A♯", "B♭"},
    {"B"},
};

// Fixed chromatic reference labels for column headers.
static const QStringList kColHeaders = {
    "0","1","2","3","4","5","6","7","8","9","10","11"
};

static QComboBox *makeCombo(int semitone, const QString &value)
{
    auto *c = new QComboBox;
    c->setEditable(true);
    c->addItems(kEnharmonics[semitone]);
    c->setCurrentText(value);
    c->setSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding);
    return c;
}

NoteNameDialog::NoteNameDialog(
    const QStringList &noteNames,
    const QStringList &majorRootNames,
    const QStringList &minorRootNames,
    QWidget *parent)
    : QDialog(parent)
{
    setWindowTitle(tr("Note Names"));

    auto *outer = new QVBoxLayout(this);

    auto *grid = new QGridLayout;
    grid->setHorizontalSpacing(4);
    grid->setVerticalSpacing(6);

    // Row 0: column headers
    for (int i = 0; i < 12; ++i) {
        auto *lbl = new QLabel(kColHeaders[i]);
        lbl->setAlignment(Qt::AlignHCenter | Qt::AlignBottom);
        QFont f = lbl->font();
        f.setBold(true);
        lbl->setFont(f);
        grid->addWidget(lbl, 0, i + 1);
    }

    // Rows 1–3: row label + 12 combos
    const struct { const char *label; const QStringList &vals; QComboBox **combos; } rows[3] = {
        { QT_TR_NOOP("Note Names"), noteNames, m_noteEdits  },
        { QT_TR_NOOP("Major Root Names"), majorRootNames, m_majorEdits },
        { QT_TR_NOOP("Minor Root Names"), minorRootNames, m_minorEdits },
    };

    for (int r = 0; r < 3; ++r) {
        auto *rowLabel = new QLabel(tr(rows[r].label));
        rowLabel->setAlignment(Qt::AlignRight | Qt::AlignVCenter);
        grid->addWidget(rowLabel, r * 2 + 1, 0);

        for (int i = 0; i < 12; ++i) {
            auto *combo = makeCombo(i, rows[r].vals.value(i));
            rows[r].combos[i] = combo;
            grid->addWidget(combo, r * 2 + 1, i + 1);
        }
    }

    for (int i = 0; i < 12; ++i)
        grid->setColumnStretch(i + 1, 1);
    // Rows 2 and 4 are empty spacer rows between the three data rows.
    grid->setRowStretch(2, 1);
    grid->setRowStretch(4, 1);

    outer->addLayout(grid, 1);

    auto *resetBtn = new QPushButton(tr("Reset to Defaults"));
    QObject::connect(resetBtn, &QPushButton::clicked, this, &NoteNameDialog::resetToDefaults);
    outer->addWidget(resetBtn);

    auto *buttons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
    QObject::connect(buttons, &QDialogButtonBox::accepted, this, &QDialog::accept);
    QObject::connect(buttons, &QDialogButtonBox::rejected, this, &QDialog::reject);
    outer->addWidget(buttons);
}

QStringList NoteNameDialog::noteNames() const
{
    QStringList result;
    for (int i = 0; i < 12; ++i) {
        result << m_noteEdits[i]->currentText();
    }
    return result;
}

QStringList NoteNameDialog::majorRootNoteNames() const
{
    QStringList result;
    for (int i = 0; i < 12; ++i) {
        result << m_majorEdits[i]->currentText();
    }
    return result;
}

QStringList NoteNameDialog::minorRootNoteNames() const
{
    QStringList result;
    for (int i = 0; i < 12; ++i)
        result << m_minorEdits[i]->currentText();
    return result;
}

void NoteNameDialog::resetToDefaults()
{
    for (int i = 0; i < 12; ++i) {
        m_noteEdits[i]->setCurrentText(kDefaultNoteNames[i]);
        m_majorEdits[i]->setCurrentText(kDefaultMajorRootNames[i]);
        m_minorEdits[i]->setCurrentText(kDefaultMinorRootNames[i]);
    }
}
