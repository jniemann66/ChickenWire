#include "TonnetzController.h"
#include "VisualizerSwitcher.h"
#include "MidiPlayer.h"
#include "TransportWidget.h"

#include <QApplication>
#include <QMainWindow>
#include <QMenuBar>
#include <QActionGroup>
#include <QShortcut>
#include <QQuickWidget>
#include <QQmlContext>
#include <QDebug>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    TonnetzController controller;
    VisualizerSwitcher switcher;
    MidiPlayer midiPlayer;

    // Handler for sending MIDI note-on events to TonnetzController
    QObject::connect(&midiPlayer, &MidiPlayer::noteOn,
        [&controller](int semitone, int /*channel*/, int /*velocity*/) {
            controller.handleNoteOn(semitone);
        });

    // Handler for sending MIDI note-on events to TonnetzController
    QObject::connect(&midiPlayer, &MidiPlayer::noteOff,
        [&controller](int semitone, int /*channel*/) {
            controller.handleNoteOff(semitone);
        });

    // Handler for clearing all displayed notes from TonnetzController
    QObject::connect(&midiPlayer, &MidiPlayer::allNotesCleared, &controller, &TonnetzController::clearPlayingNotes);

    // QML view
    auto *view = new QQuickWidget;
    view->rootContext()->setContextProperty("tonnetzController", &controller);
    view->rootContext()->setContextProperty("visualizerSwitcher", &switcher);
    view->setSource(QUrl("qrc:/qt/qml/ChickenWire/Main.qml"));
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
    auto *tonnetzAction = makeAction(QStringLiteral("&Tonnetz"), QStringLiteral("Tonnetz.qml"));
    auto *cwAction = makeAction(QStringLiteral("&Chicken Wire"), QStringLiteral("ChickenWire.qml"));
    viewMenu->addSeparator();
    viewMenu->addAction(transport->toggleViewAction());

    // set up keyboard shortcut : F4 toggles between the two visualizers
    auto *f4 = new QShortcut(QKeySequence(Qt::Key_F4), &mw);
    QObject::connect(f4, &QShortcut::activated, [&switcher]() {
        switcher.setSource(
            switcher.source() == QStringLiteral("Tonnetz.qml")
                ? QStringLiteral("ChickenWire.qml")
                : QStringLiteral("Tonnetz.qml"));
    });

    QObject::connect(&switcher, &VisualizerSwitcher::sourceChanged, [&]() {
        tonnetzAction->setChecked(switcher.source() == QStringLiteral("Tonnetz.qml"));
        cwAction->setChecked(switcher.source() == QStringLiteral("ChickenWire.qml"));
    });

    mw.show();
    return app.exec();
}
