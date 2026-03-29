#pragma once
#include <QDockWidget>

class MidiPlayer;
class QPushButton;
class QSlider;
class QLabel;

class TransportWidget : public QDockWidget
{
    Q_OBJECT

public:
    explicit TransportWidget(MidiPlayer *player, QWidget *parent = nullptr);

private slots:
    void openFile();
    void onStateChanged();
    void onPositionChanged();
    void onSliderReleased();

private:
    static QString formatMs(int ms);

    MidiPlayer *m_player;
    QPushButton *m_openBtn;
    QPushButton *m_playPauseBtn;
    QPushButton *m_stopBtn;
    QSlider *m_slider;
    QLabel *m_fileLabel;
    QLabel *m_timeLabel;
    bool m_dragging = false;
};
