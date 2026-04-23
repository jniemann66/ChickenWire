#pragma once
#include <QDialog>
#include <QStringList>

class QComboBox;

class NoteNameDialog : public QDialog
{
    Q_OBJECT
public:
    explicit NoteNameDialog(
        const QStringList &noteNames,
        const QStringList &majorRootNames,
        const QStringList &minorRootNames,
        QWidget *parent = nullptr);

    QStringList noteNames() const;
    QStringList majorRootNoteNames() const;
    QStringList minorRootNoteNames() const;

private:
    void resetToDefaults();

    QComboBox *m_noteEdits[12]{};
    QComboBox *m_majorEdits[12]{};
    QComboBox *m_minorEdits[12]{};
};
