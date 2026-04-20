#include "midiPlayer.h"
#include "tonnetzController.h"
#include "transportWidget.h"
#include "visualizerSwitcher.h"

#include <QActionGroup>
#include <QApplication>
#include <QClipboard>
#include <QIcon>
#include <QFileDialog>
#include <QDebug>
#include <QDockWidget>
#include <QEvent>
#include <QFormLayout>
#include <QLabel>
#include <QMainWindow>
#include <QMenuBar>
#include <QMimeData>
#include <QPushButton>
#include <QQmlContext>
#include <QQuickWidget>
#include <QSettings>
#include <QShortcut>
#include <QSlider>
#include <QStatusBar>

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

    QApplication::setWindowIcon(QIcon(QStringLiteral(":/icon.svg")));

    TonnetzController controller;
    VisualizerSwitcher switcher;
    MidiPlayer midiPlayer;

    QObject::connect(&midiPlayer, &MidiPlayer::noteOn, [&controller](int semitone, int channel, int /*velocity*/) {
        controller.handleNoteOn(semitone, channel);
    });

    QObject::connect(&midiPlayer, &MidiPlayer::noteOff, [&controller](int semitone, int channel) {
        controller.handleNoteOff(semitone, channel);
    });

    // Handler for clearing all displayed notes from TonnetzController
    QObject::connect(&midiPlayer, &MidiPlayer::allNotesCleared, &controller, &TonnetzController::clearPlayingNotes);

    // Clear all node/triad selections in every visualizer when playback starts.
    QObject::connect(&midiPlayer, &MidiPlayer::stateChanged, [&]() {
        if (midiPlayer.state() == MidiPlayer::Playing) {
            controller.clearHighlightedNotes();
            switcher.notifyPlaybackStarted();
        }
    });

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

    // Channel filter: populate combo when a new file is loaded, wire filter → controller.
    QObject::connect(&midiPlayer, &MidiPlayer::presentChannelsChanged, transport,
                     [&midiPlayer, transport]() {
                         transport->setPresentChannels(midiPlayer.presentChannels());
                     });
    QObject::connect(transport, &TransportWidget::channelFilterChanged,
                     &controller, &TonnetzController::setMidiChannelFilter);

    // File menu
    auto grabVisualizer = [view]() { return view->grabFramebuffer(); };

    auto *fileMenu = mw.menuBar()->addMenu(QStringLiteral("&File"));

    auto *copyAction = fileMenu->addAction(QStringLiteral("&Copy Visualizer to Clipboard"));
    copyAction->setShortcut(QKeySequence(Qt::ALT | Qt::Key_Print));
    QObject::connect(copyAction, &QAction::triggered, [grabVisualizer, &mw]() {
        QMimeData *mimeData = new QMimeData();
        mimeData->setImageData(grabVisualizer());
        QApplication::clipboard()->setMimeData(mimeData);
        mw.statusBar()->showMessage(QStringLiteral("Copied to Clipboard"), 3000);
    });

    auto *saveAction = fileMenu->addAction(QStringLiteral("&Save Visualizer Image…"));
    saveAction->setShortcut(QKeySequence(Qt::CTRL | Qt::Key_Print));
    QObject::connect(saveAction, &QAction::triggered, [grabVisualizer, &mw]() {
        const QString path = QFileDialog::getSaveFileName(
            &mw, QStringLiteral("Save Visualizer Image"), {},
            QStringLiteral("PNG Image (*.png)"));
        if (!path.isEmpty())
            grabVisualizer().save(path, "PNG");
    });

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
    auto *tonnetzAction = makeAction(QStringLiteral("&Tonnetz"), QStringLiteral("tonnetz.qml"));
    auto *cwAction = makeAction(QStringLiteral("&Chicken Wire"), QStringLiteral("chickenWire.qml"));
    auto *cdAction = makeAction(QStringLiteral("Cube &Dance"), QStringLiteral("cubeDance.qml"));
    auto *s7Action = makeAction(QStringLiteral("&Seventh Chords"), QStringLiteral("seventhChords.qml"));
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

    // F4 / Shift+F4 cycle through the visualizers in display order.
    static const QStringList visualizerOrder{
        QStringLiteral("tonnetz.qml"),
        QStringLiteral("chickenWire.qml"),
        QStringLiteral("cubeDance.qml"),
        QStringLiteral("seventhChords.qml"),
    };
    auto cycle = [&switcher](int step) {
        int idx = visualizerOrder.indexOf(switcher.source());
        if (idx < 0) idx = 0;
        int n = visualizerOrder.size();
        switcher.setSource(visualizerOrder.at(((idx + step) % n + n) % n));
    };
    auto *f4 = new QShortcut(QKeySequence(Qt::Key_F4), &mw);
    QObject::connect(f4, &QShortcut::activated, [cycle]() { cycle(+1); });
    auto *shiftF4 = new QShortcut(QKeySequence(Qt::SHIFT | Qt::Key_F4), &mw);
    QObject::connect(shiftF4, &QShortcut::activated, [cycle]() { cycle(-1); });

    auto *escKey = new QShortcut(QKeySequence(Qt::Key_Escape), &mw);
    QObject::connect(escKey, &QShortcut::activated, [&]() {
        controller.clearHighlightedNotes();
        switcher.clearAllSelections();
    });

    QObject::connect(&switcher, &VisualizerSwitcher::sourceChanged, [&]() {
        const QString src = switcher.source();
        tonnetzAction->setChecked(src == QStringLiteral("tonnetz.qml"));
        cwAction->setChecked(src == QStringLiteral("chickenWire.qml"));
        cdAction->setChecked(src == QStringLiteral("cubeDance.qml"));
        s7Action->setChecked(src == QStringLiteral("seventhChords.qml"));
        settings.setValue(QStringLiteral("view/source"), src);
    });

    // Persist per-visualizer toggle state.
    QObject::connect(&switcher, &VisualizerSwitcher::cubeModeChanged, [&]() {
        settings.setValue(QStringLiteral("display/cubeMode"), switcher.cubeMode());
    });
    QObject::connect(&switcher, &VisualizerSwitcher::fifthsOrderChanged, [&]() {
        settings.setValue(QStringLiteral("display/fifthsOrder"), switcher.fifthsOrder());
    });
    QObject::connect(&switcher, &VisualizerSwitcher::hiddenClassesChanged, [&]() {
        settings.setValue(QStringLiteral("display/hiddenClasses"), switcher.hiddenClasses());
    });

    // Color Scheme menu
    auto *colorMenu = mw.menuBar()->addMenu(QStringLiteral("&Color Scheme"));

    // Theme submenu (radio-button style, exclusive)
    auto *themeMenu = colorMenu->addMenu(QStringLiteral("&Theme"));
    auto *themeGroup = new QActionGroup(&mw);
    themeGroup->setExclusive(true);
    const QList<QPair<QString,QString>> themeItems = {
        { QStringLiteral("Dark"), QStringLiteral("dark") },
        { QStringLiteral("Light"), QStringLiteral("light") },
        { QStringLiteral("High Contrast"), QStringLiteral("contrast") },
    };
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


    for (const auto &[label, id] : themeItems) {
        auto *a = themeMenu->addAction(label);
        a->setCheckable(true);
        a->setData(id);
        a->setChecked(switcher.themeName() == id);
        themeGroup->addAction(a);
        QObject::connect(a, &QAction::triggered, [&switcher, &settings, id]() {
            switcher.setThemeName(id);
            settings.setValue(QStringLiteral("color/theme"), id);
        });
    }

    QObject::connect(&switcher, &VisualizerSwitcher::themeNameChanged, [&]() {
        const QString name = switcher.themeName();
        for (QAction *a : themeGroup->actions())
            a->setChecked(a->data().toString() == name);
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
    hueSlider->setValue(settings.value(QStringLiteral("color/hue"), 180).toInt());
    briSlider->setValue(settings.value(QStringLiteral("color/brightness"), 100).toInt());
    conSlider->setValue(settings.value(QStringLiteral("color/contrast"), 100).toInt());

    switcher.setCubeMode(settings.value(QStringLiteral("display/cubeMode"), true).toBool());
    switcher.setFifthsOrder(settings.value(QStringLiteral("display/fifthsOrder"), true).toBool());
    switcher.setHiddenClasses(settings.value(QStringLiteral("display/hiddenClasses"), QStringList{}).toStringList());
    switcher.setThemeName(settings.value(QStringLiteral("color/theme"), QStringLiteral("dark")).toString());

    // Restore active visualizer.  Menu checkmarks were initialized to the
    // default ("tonnetz.qml") in makeAction; setSource() will fix them up
    // via the sourceChanged connection if the restored value differs.
    switcher.setSource(settings.value(QStringLiteral("view/source"), QStringLiteral("tonnetz.qml")).toString());

    // Restore window geometry & dock layout, save on quit.
    const QByteArray geom = settings.value(QStringLiteral("window/geometry")).toByteArray();
    if (!geom.isEmpty())
        mw.restoreGeometry(geom);
    const QByteArray state = settings.value(QStringLiteral("window/state")).toByteArray();
    if (!state.isEmpty())
        mw.restoreState(state);

    QObject::connect(&app, &QApplication::aboutToQuit, [&]() {
        settings.setValue(QStringLiteral("window/geometry"), mw.saveGeometry());
        settings.setValue(QStringLiteral("window/state"), mw.saveState());
    });

    mw.show();
    return app.exec();
}
