#pragma once
#include <QObject>
#include <QString>

// Exposed to QML as "visualizerSwitcher".
// Holds the active visualizer filename and the shared viewport state.
//
// Both Tonnetz.qml and ChickenWire.qml use the same underlying lattice
// coordinate system, so a single (originX, originY, scale) triple keeps
// them visually aligned — which is also the foundation for future compositing.
//
// vpScale == 0 means "not yet set": visualizers keep their default origin
// (canvas centre) until the user first pans or zooms.
class VisualizerSwitcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString source    READ source    WRITE setSource    NOTIFY sourceChanged)
    Q_PROPERTY(qreal vpOriginX   READ vpOriginX WRITE setVpOriginX NOTIFY vpOriginXChanged)
    Q_PROPERTY(qreal vpOriginY   READ vpOriginY WRITE setVpOriginY NOTIFY vpOriginYChanged)
    Q_PROPERTY(qreal vpScale     READ vpScale   WRITE setVpScale   NOTIFY vpScaleChanged)

public:
    explicit VisualizerSwitcher(QObject *parent = nullptr)
        : QObject(parent), m_source(u"Tonnetz.qml"), m_vpScale(0) {}

    QString source()  const { return m_source;    }
    qreal vpOriginX() const { return m_vpOriginX; }
    qreal vpOriginY() const { return m_vpOriginY; }
    qreal vpScale()   const { return m_vpScale;   }

    void setSource(const QString &s) {
        if (m_source != s) { m_source = s; emit sourceChanged(); }
    }
    void setVpOriginX(qreal v) {
        if (m_vpOriginX != v) { m_vpOriginX = v; emit vpOriginXChanged(); }
    }
    void setVpOriginY(qreal v) {
        if (m_vpOriginY != v) { m_vpOriginY = v; emit vpOriginYChanged(); }
    }
    void setVpScale(qreal v) {
        if (m_vpScale != v) { m_vpScale = v; emit vpScaleChanged(); }
    }

signals:
    void sourceChanged();
    void vpOriginXChanged();
    void vpOriginYChanged();
    void vpScaleChanged();

private:
    QString m_source;
    qreal   m_vpOriginX = 0;
    qreal   m_vpOriginY = 0;
    qreal   m_vpScale   = 0;   // 0 = sentinel "not yet set"
};
