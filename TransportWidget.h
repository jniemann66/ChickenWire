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

    MidiPlayer *m_player{nullptr};
    QPushButton *m_openBtn{nullptr};
    QPushButton *m_playPauseBtn{nullptr};
    QPushButton *m_stopBtn{nullptr};
    QSlider *m_slider{nullptr};
    QLabel *m_fileLabel{nullptr};
    QLabel *m_timeLabel{nullptr};

    bool m_dragging = false;
};
