#include <QApplication>
#include <QMainWindow>
#include <QQuickWidget>
#include <QQmlContext>
#include <QDebug>

#include "TonnetzController.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    TonnetzController controller;

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
    view->setSource(QUrl("qrc:/qt/qml/ChickenWire/Main.qml"));
    view->setResizeMode(QQuickWidget::SizeRootObjectToView);

    if (view->status() == QQuickWidget::Error) {
        for (const auto &err : view->errors())
            qCritical() << "QML error:" << err;
    }

    QMainWindow win;
    win.setWindowTitle("Tonnetz");
    win.setCentralWidget(view);
    win.resize(1000, 620);
    win.show();

    return app.exec();
}
