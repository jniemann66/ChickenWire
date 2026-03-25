#pragma once
#include <QObject>

class TonnetzController : public QObject
{
    Q_OBJECT

public:
    explicit TonnetzController(QObject *parent = nullptr);

    // Called by QML after hit-testing
    Q_INVOKABLE void selectNote (int semitone, int i, int j);
    Q_INVOKABLE void selectTriad(int root, int third, int fifth, bool isMajor);

signals:
    // Connect these from C++ to drive application logic
    void noteSelected (int semitone, int i, int j);
    void triadSelected(int root, int third, int fifth, bool isMajor);
};
