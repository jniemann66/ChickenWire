#include "TonnetzController.h"
#include "VisualizerSwitcher.h"

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

    TonnetzController  controller;
    VisualizerSwitcher switcher;

    // Wire up C++ signal handlers here — add real logic as the app grows
    QObject::connect(&controller, &TonnetzController::noteSelected,
        [](int semitone, int i, int j) {
            Q_UNUSED(semitone) Q_UNUSED(i) Q_UNUSED(j)
            // TODO: drive application logic
        });

    QObject::connect(&controller, &TonnetzController::triadSelected,
        [](int root, int third, int fifth, bool isMajor) {
            Q_UNUSED(root) Q_UNUSED(third) Q_UNUSED(fifth) Q_UNUSED(isMajor)
            // TODO: drive application logic
        });

    auto *view = new QQuickWidget;
    view->rootContext()->setContextProperty("tonnetzController", &controller);
    view->rootContext()->setContextProperty("visualizerSwitcher", &switcher);
    view->setSource(QUrl("qrc:/qt/qml/ChickenWire/Main.qml"));
    view->setResizeMode(QQuickWidget::SizeRootObjectToView);

    if (view->status() == QQuickWidget::Error) {
        for (const auto &err : view->errors())
            qCritical() << "QML error:" << err;
    }

    QMainWindow win;
    win.setWindowTitle("ChickenWire");

    // Set up "View" menu
    auto *viewMenu = win.menuBar()->addMenu(QStringLiteral("&View"));
    auto *group    = new QActionGroup(&win);

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

    auto *tonnetzAction = makeAction(QStringLiteral("&Tonnetz"),      QStringLiteral("Tonnetz.qml"));
    auto *cwAction      = makeAction(QStringLiteral("&Chicken Wire"), QStringLiteral("ChickenWire.qml"));

    // F4 toggles between the two visualizers
    auto *f4 = new QShortcut(QKeySequence(Qt::Key_F4), &win);
    QObject::connect(f4, &QShortcut::activated, [&switcher]() {
        switcher.setSource(
            switcher.source() == QStringLiteral("Tonnetz.qml")
                ? QStringLiteral("ChickenWire.qml")
                : QStringLiteral("Tonnetz.qml")
        );
    });

    // Keep menu checkmarks in sync when the source changes via F4 (not via menu click)
    QObject::connect(&switcher, &VisualizerSwitcher::sourceChanged, [&]() {
        tonnetzAction->setChecked(switcher.source() == QStringLiteral("Tonnetz.qml"));
        cwAction->setChecked(switcher.source() == QStringLiteral("ChickenWire.qml"));
    });
    // ---

    win.setCentralWidget(view);
    win.resize(1000, 640);
    win.show();

    return app.exec();
}
