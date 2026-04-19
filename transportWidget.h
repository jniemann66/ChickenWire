#pragma once
#include <QDockWidget>
#include <QList>

class MidiPlayer;
class QComboBox;
class QPushButton;
class QSlider;
class QLabel;

class TransportWidget : public QDockWidget
{
    Q_OBJECT

public:
    explicit TransportWidget(MidiPlayer *player, QWidget *parent = nullptr);

public slots:
    void setPresentChannels(const QList<int> &channels);

signals:
    void channelFilterChanged(int channel);  // -1 = all, 0–15 = specific

private slots:
    void openFile();
    void onStateChanged();
    void onPositionChanged();
    void onSliderReleased();

private:
    static QString formatMs(int ms);

    MidiPlayer *m_player{nullptr};
    QPushButton *m_openBtn{nullptr};
    QPushButton *m_playPauseBtn{nullptr};
    QPushButton *m_stopBtn{nullptr};
    QSlider *m_slider{nullptr};
    QLabel *m_fileLabel{nullptr};
    QLabel *m_timeLabel{nullptr};
    QComboBox *m_channelCombo{nullptr};

    bool m_dragging = false;
};
