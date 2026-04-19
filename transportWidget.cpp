#include "transportWidget.h"
#include "midiPlayer.h"

#include <QComboBox>
#include <QFileDialog>
#include <QFileInfo>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QSlider>
#include <QVBoxLayout>
#include <QWidget>

TransportWidget::TransportWidget(MidiPlayer *player, QWidget *parent)
    : QDockWidget(tr("MIDI Transport"), parent)
    , m_player(player)
{
    setFeatures(QDockWidget::DockWidgetMovable | QDockWidget::DockWidgetFloatable);

    auto *container = new QWidget(this);
    m_openBtn = new QPushButton(tr("Open…"), container);
    m_playPauseBtn = new QPushButton(tr("Play"), container);
    m_stopBtn = new QPushButton(tr("Stop"), container);
    m_slider = new QSlider(Qt::Horizontal, container);
    m_fileLabel = new QLabel(tr("No file loaded"), container);
    m_timeLabel = new QLabel(tr("0:00 / 0:00"), container);
    m_channelCombo = new QComboBox(container);
    m_channelCombo->addItem(tr("All Channels"), -1);
    m_channelCombo->setEnabled(false);
    m_channelCombo->setToolTip(tr("Filter display to a single MIDI channel"));

    m_slider->setRange(0, 1000);
    m_slider->setEnabled(false);
    m_playPauseBtn->setEnabled(false);
    m_stopBtn->setEnabled(false);
    m_timeLabel->setMinimumWidth(90);
    m_timeLabel->setAlignment(Qt::AlignRight | Qt::AlignVCenter);

    auto *row = new QHBoxLayout;
    row->addWidget(m_openBtn);
    row->addWidget(m_playPauseBtn);
    row->addWidget(m_stopBtn);
    row->addWidget(m_slider, 1);
    row->addWidget(m_timeLabel);
    row->addWidget(m_channelCombo);

    auto *layout = new QVBoxLayout(container);
    layout->setContentsMargins(4, 2, 4, 2);
    layout->addLayout(row);
    layout->addWidget(m_fileLabel);
    setWidget(container);

    // Button connections
    connect(m_openBtn, &QPushButton::clicked, this, &TransportWidget::openFile);

    connect(m_playPauseBtn, &QPushButton::clicked, this, [this]() {
        if (m_player->state() == MidiPlayer::Playing)
            m_player->pause();
        else
            m_player->play();
    });

    connect(m_stopBtn, &QPushButton::clicked, m_player, &MidiPlayer::stop);

    // Slider drag tracking
    connect(m_slider, &QSlider::sliderPressed, this, [this]() { m_dragging = true; });
    connect(m_slider, &QSlider::sliderReleased, this, &TransportWidget::onSliderReleased);

    // Channel combo → emit filter signal
    connect(m_channelCombo, &QComboBox::currentIndexChanged, this, [this](int idx) {
        emit channelFilterChanged(m_channelCombo->itemData(idx).toInt());
    });

    // Player → widget updates
    connect(m_player, &MidiPlayer::stateChanged, this, &TransportWidget::onStateChanged);
    connect(m_player, &MidiPlayer::positionChanged, this, &TransportWidget::onPositionChanged);

    connect(m_player, &MidiPlayer::filePathChanged, this, [this]() {
        m_fileLabel->setText(QFileInfo(m_player->filePath()).fileName());
        m_slider->setEnabled(true);
        m_playPauseBtn->setEnabled(true);
        m_stopBtn->setEnabled(true);
    });

    connect(m_player, &MidiPlayer::loadError, this, [this](const QString &msg) {
        m_fileLabel->setText(tr("Error: %1").arg(msg));
    });
}

void TransportWidget::setPresentChannels(const QList<int> &channels)
{
    // Block signals to avoid emitting channelFilterChanged while rebuilding.
    const QSignalBlocker blocker(m_channelCombo);
    m_channelCombo->clear();
    m_channelCombo->addItem(tr("All Channels"), -1);
    for (int ch : channels)
        m_channelCombo->addItem(tr("Channel %1").arg(ch + 1), ch);
    m_channelCombo->setCurrentIndex(0);
    m_channelCombo->setEnabled(channels.size() > 1);
    // Restore filter to "all" when a new file is loaded.
    emit channelFilterChanged(-1);
}

void TransportWidget::openFile()
{
    const QString path = QFileDialog::getOpenFileName(
        this, tr("Open MIDI File"), {},
        tr("MIDI Files (*.mid *.midi);;All Files (*)"));

    if (!path.isEmpty()) {
        m_player->load(path);
    }
}

void TransportWidget::onStateChanged()
{
    const bool playing = (m_player->state() == MidiPlayer::Playing);
    m_playPauseBtn->setText(playing ? tr("Pause") : tr("Play"));
    m_stopBtn->setEnabled(m_player->state() != MidiPlayer::Stopped);
}

void TransportWidget::onPositionChanged()
{
    if (!m_dragging) {
        m_slider->setValue(int(m_player->position() * 1000));
    }

    const int dur = m_player->durationMs();
    const int pos = int(m_player->position() * dur);
    m_timeLabel->setText(QStringLiteral("%1 / %2").arg(formatMs(pos), formatMs(dur)));
}

void TransportWidget::onSliderReleased()
{
    m_dragging = false;
    m_player->seek(m_slider->value() / 1000.0);
}

QString TransportWidget::formatMs(int ms)
{
    const int s = ms / 1000;
    return QStringLiteral("%1:%2").arg(s / 60).arg(s % 60, 2, 10, QChar('0'));
}
