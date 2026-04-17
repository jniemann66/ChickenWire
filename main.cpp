#include "midiPlayer.h"
#include "tonnetzController.h"
#include "transportWidget.h"
#include "visualizerSwitcher.h"

#include <QActionGroup>
#include <QApplication>
#include <QDebug>
#include <QDockWidget>
#include <QEvent>
#include <QFormLayout>
#include <QLabel>
#include <QMainWindow>
#include <QMenuBar>
#include <QPushButton>
#include <QQmlContext>
#include <QQuickWidget>
#include <QSettings>
#include <QShortcut>
#include <QSlider>

// Resets a slider to its default value on double-click.
class SliderResetter : public QObject
{
public:
    SliderResetter(QSlider *slider, int defaultValue)
        : QObject(slider), m_slider(slider), m_default(defaultValue)
    {
        slider->installEventFilter(this);
    }

protected:
    bool eventFilter(QObject *obj, QEvent *event) override
    {
        if (obj == m_slider && event->type() == QEvent::MouseButtonDblClick) {
            m_slider->setValue(m_default);
            return true;
        }
        return QObject::eventFilter(obj, event);
    }

private:
    QSlider *m_slider{nullptr};
    int m_default;
};


int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    QApplication::setOrganizationName(QStringLiteral("ChickenWire"));
    QApplication::setApplicationName(QStringLiteral("ChickenWire"));
    QSettings settings;

    TonnetzController controller;
    VisualizerSwitcher switcher;
    MidiPlayer midiPlayer;

    // Handler for sending MIDI note-on events to TonnetzController
    QObject::connect(&midiPlayer, &MidiPlayer::noteOn, [&controller](int semitone, int /*channel*/, int /*velocity*/) {
        controller.handleNoteOn(semitone);
    });

    // Handler for sending MIDI note-off events to TonnetzController
    QObject::connect(&midiPlayer, &MidiPlayer::noteOff, [&controller](int semitone, int /*channel*/) {
        controller.handleNoteOff(semitone);
    });

    // Handler for clearing all displayed notes from TonnetzController
    QObject::connect(&midiPlayer, &MidiPlayer::allNotesCleared, &controller, &TonnetzController::clearPlayingNotes);

    // QML view
    auto *view = new QQuickWidget;
    view->rootContext()->setContextProperty("tonnetzController", &controller);
    view->rootContext()->setContextProperty("visualizerSwitcher", &switcher);
    view->setSource(QUrl("qrc:/qt/qml/ChickenWire/main.qml"));
    view->setResizeMode(QQuickWidget::SizeRootObjectToView);

    if (view->status() == QQuickWidget::Error) {
        for (const auto &err : view->errors())
            qCritical() << "QML error:" << err;
    }

    // Main window
    QMainWindow mw;
    mw.setWindowTitle("ChickenWire");
    mw.setCentralWidget(view);
    mw.resize(1000, 700);

    // Transport dock
    auto *transport = new TransportWidget(&midiPlayer, &mw);
    mw.addDockWidget(Qt::BottomDockWidgetArea, transport);

    // View menu
    auto *viewMenu = mw.menuBar()->addMenu(QStringLiteral("&View"));
    auto *group = new QActionGroup(&mw);

    // convenience function for adding menu actions
    auto makeAction = [&](const QString &label, const QString &source) {
        auto *a = viewMenu->addAction(label);
        a->setCheckable(true);
        a->setChecked(switcher.source() == source);
        group->addAction(a);
        QObject::connect(a, &QAction::triggered, [&switcher, source]() {
            switcher.setSource(source);
        });
        return a;
    };

    // set-up View Menu
    auto *tonnetzAction = makeAction(QStringLiteral("&Tonnetz"),           QStringLiteral("tonnetz.qml"));
    auto *cwAction      = makeAction(QStringLiteral("&Chicken Wire"),      QStringLiteral("chickenWire.qml"));
    auto *cdAction      = makeAction(QStringLiteral("Cube &Dance"),        QStringLiteral("cubeDance.qml"));
    auto *s7Action      = makeAction(QStringLiteral("&Seventh Chords"),    QStringLiteral("seventhChords.qml"));
    viewMenu->addSeparator();
    auto *augAction = viewMenu->addAction(QStringLiteral("Show &Augmented Chords"));
    augAction->setCheckable(true);
    augAction->setChecked(switcher.showAugmented());

    QObject::connect(augAction, &QAction::toggled, [&switcher, &settings](bool on) {
        switcher.setShowAugmented(on);
        settings.setValue(QStringLiteral("display/showAugmented"), on);
    });

    QObject::connect(&switcher, &VisualizerSwitcher::showAugmentedChanged, [&]() {
        augAction->setChecked(switcher.showAugmented());
    });

    viewMenu->addSeparator();
    viewMenu->addAction(transport->toggleViewAction());

    // set up keyboard shortcut: F4 toggles between Tonnetz and ChickenWire
    auto *f4 = new QShortcut(QKeySequence(Qt::Key_F4), &mw);
    QObject::connect(f4, &QShortcut::activated, [&switcher]() {
        switcher.setSource(
            switcher.source() == QStringLiteral("tonnetz.qml")
                ? QStringLiteral("chickenWire.qml")
                : QStringLiteral("tonnetz.qml"));
    });

    QObject::connect(&switcher, &VisualizerSwitcher::sourceChanged, [&]() {
        const QString src = switcher.source();
        tonnetzAction->setChecked(src == QStringLiteral("tonnetz.qml"));
        cwAction->setChecked(src      == QStringLiteral("chickenWire.qml"));
        cdAction->setChecked(src      == QStringLiteral("cubeDance.qml"));
        s7Action->setChecked(src      == QStringLiteral("seventhChords.qml"));
    });

    // Color Scheme menu
    auto *colorMenu = mw.menuBar()->addMenu(QStringLiteral("&Color Scheme"));
    auto *negativeAction = colorMenu->addAction(QStringLiteral("&Negative"));
    negativeAction->setCheckable(true);
    negativeAction->setChecked(switcher.invertColors());
    QObject::connect(negativeAction, &QAction::toggled, [&switcher, &settings](bool on) {
        switcher.setInvertColors(on);
        settings.setValue(QStringLiteral("color/invertColors"), on);
    });

    QObject::connect(&switcher, &VisualizerSwitcher::invertColorsChanged, [&]() {
        negativeAction->setChecked(switcher.invertColors());
    });

    // Color controls dock
    auto *colorDock = new QDockWidget(QStringLiteral("Adjust Color"), &mw);
    colorDock->setAllowedAreas(Qt::AllDockWidgetAreas);
    colorDock->setFeatures(QDockWidget::DockWidgetMovable | QDockWidget::DockWidgetFloatable | QDockWidget::DockWidgetClosable);
    auto *colorWidget = new QWidget;
    auto *colorLayout = new QFormLayout(colorWidget);
    colorLayout->setContentsMargins(8, 4, 8, 4);

    auto makeSlider = [](int min, int max, int value, int tickInterval) {
        auto *s = new QSlider(Qt::Horizontal);
        s->setRange(min, max);
        s->setValue(value);
        s->setTickPosition(QSlider::TicksBelow);
        s->setTickInterval(tickInterval);
        return s;
    };

    // Saturation: slider 0-200, 100 = 1.0 (normal)
    auto *satSlider = makeSlider(0, 200, 100, 50);

    // Hue: slider 0-360, 180 = 0° rotation (maps to -180..+180 degrees)
    auto *hueSlider = makeSlider(0, 360, 180, 60);

    // Brightness: slider 0-200, 100 = 1.0 (normal)
    auto *briSlider = makeSlider(0, 200, 100, 50);

    // Contrast: slider 0-300, 100 = 1.0 (normal)
    auto *conSlider = makeSlider(0, 300, 100, 50);

    new SliderResetter(satSlider, 100);
    new SliderResetter(hueSlider, 180);
    new SliderResetter(briSlider, 100);
    new SliderResetter(conSlider, 100);

    colorLayout->addRow(QStringLiteral("Saturation"), satSlider);
    colorLayout->addRow(QStringLiteral("Hue"), hueSlider);
    colorLayout->addRow(QStringLiteral("Brightness"), briSlider);
    colorLayout->addRow(QStringLiteral("Contrast"), conSlider);

    auto *resetButton = new QPushButton(QStringLiteral("Reset to Defaults"));
    colorLayout->addRow(resetButton);
    QObject::connect(resetButton, &QPushButton::clicked, [&]() {
        satSlider->setValue(100);
        hueSlider->setValue(180);
        briSlider->setValue(100);
        conSlider->setValue(100);
    });

    colorDock->setWidget(colorWidget);
    mw.addDockWidget(Qt::BottomDockWidgetArea, colorDock);
    colorDock->hide();

    colorMenu->addSeparator();
    auto *adjustColorAction = colorDock->toggleViewAction();
    adjustColorAction->setText(QStringLiteral("Adjust Color..."));
    colorMenu->addAction(adjustColorAction);

    QObject::connect(satSlider, &QSlider::valueChanged, [&switcher, &settings](int v) {
        switcher.setSaturation(v / 100.0);
        settings.setValue(QStringLiteral("color/saturation"), v);
    });

    QObject::connect(hueSlider, &QSlider::valueChanged, [&switcher, &settings](int v) {
        switcher.setHue(v - 180.0);          // degrees; centre == 0
        settings.setValue(QStringLiteral("color/hue"), v);
    });

    QObject::connect(briSlider, &QSlider::valueChanged, [&switcher, &settings](int v) {
        switcher.setBrightness(v / 100.0);
        settings.setValue(QStringLiteral("color/brightness"), v);
    });

    QObject::connect(conSlider, &QSlider::valueChanged, [&switcher, &settings](int v) {
        switcher.setContrast(v / 100.0);
        settings.setValue(QStringLiteral("color/contrast"), v);
    });

    // Keep sliders in sync if switcher state is ever changed programmatically.
    QObject::connect(&switcher, &VisualizerSwitcher::saturationChanged, [&]() {
        satSlider->setValue(qRound(switcher.saturation() * 100));
    });

    QObject::connect(&switcher, &VisualizerSwitcher::hueChanged, [&]() {
        hueSlider->setValue(qRound(switcher.hue() + 180.0));
    });

    QObject::connect(&switcher, &VisualizerSwitcher::brightnessChanged, [&]() {
        briSlider->setValue(qRound(switcher.brightness() * 100));
    });

    QObject::connect(&switcher, &VisualizerSwitcher::contrastChanged, [&]() {
        conSlider->setValue(qRound(switcher.contrast() * 100));
    });

    // Restore saved settings — done last so all connections are live and the
    // switcher and sliders stay in sync from the first setValue/setChecked call.
    negativeAction->setChecked(settings.value(QStringLiteral("color/invertColors"), false).toBool());
    augAction->setChecked(settings.value(QStringLiteral("display/showAugmented"), false).toBool());
    satSlider->setValue(settings.value(QStringLiteral("color/saturation"), 100).toInt());
    hueSlider->setValue(settings.value(QStringLiteral("color/hue"),        180).toInt());
    briSlider->setValue(settings.value(QStringLiteral("color/brightness"), 100).toInt());
    conSlider->setValue(settings.value(QStringLiteral("color/contrast"),   100).toInt());

    mw.show();
    return app.exec();
}
