#pragma once
#include <QObject>
#include <QString>

// Exposed to QML as "visualizerSwitcher".
// Holds the active visualizer filename and the shared viewport state.
//
// Both tonnetz.qml and chickenWire.qml use the same underlying lattice
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

    Q_PROPERTY(bool  invertColors READ invertColors WRITE setInvertColors NOTIFY invertColorsChanged)
    Q_PROPERTY(qreal saturation   READ saturation   WRITE setSaturation   NOTIFY saturationChanged)
    Q_PROPERTY(qreal hue          READ hue          WRITE setHue          NOTIFY hueChanged)
    Q_PROPERTY(qreal brightness   READ brightness   WRITE setBrightness   NOTIFY brightnessChanged)
    Q_PROPERTY(qreal contrast     READ contrast     WRITE setContrast     NOTIFY contrastChanged)

    // Shared selection state.  selType: 0=none  1=note  2=triad
    Q_PROPERTY(int  selType    READ selType    NOTIFY selectionChanged)
    Q_PROPERTY(int  selI       READ selI       NOTIFY selectionChanged)
    Q_PROPERTY(int  selJ       READ selJ       NOTIFY selectionChanged)
    Q_PROPERTY(bool selIsMajor READ selIsMajor NOTIFY selectionChanged)

public:
    explicit VisualizerSwitcher(QObject *parent = nullptr)
        : QObject(parent), m_source(u"tonnetz.qml"), m_vpScale(0)
    {

    }

    bool invertColors() const { return m_invertColors; }
    void setInvertColors(bool v) {
        if (m_invertColors != v) { m_invertColors = v; emit invertColorsChanged(); }
    }

    qreal saturation() const { return m_saturation; }
    void setSaturation(qreal v) {
        if (m_saturation != v) { m_saturation = v; emit saturationChanged(); }
    }

    qreal hue() const { return m_hue; }
    void setHue(qreal v) {
        if (m_hue != v) { m_hue = v; emit hueChanged(); }
    }

    qreal brightness() const { return m_brightness; }
    void setBrightness(qreal v) {
        if (m_brightness != v) { m_brightness = v; emit brightnessChanged(); }
    }

    qreal contrast() const { return m_contrast; }
    void setContrast(qreal v) {
        if (m_contrast != v) { m_contrast = v; emit contrastChanged(); }
    }

    QString source() const { return m_source; }
    qreal vpOriginX() const { return m_vpOriginX; }
    qreal vpOriginY() const { return m_vpOriginY; }
    qreal vpScale() const { return m_vpScale; }
    int selType() const { return m_selType; }
    int selI() const { return m_selI; }
    int selJ() const { return m_selJ; }
    bool selIsMajor() const { return m_selIsMajor; }

    Q_INVOKABLE void setNoteSelection(int i, int j) {
        m_selType = 1; m_selI = i; m_selJ = j; m_selIsMajor = false;
        emit selectionChanged();
    }

    Q_INVOKABLE void setTriadSelection(int i, int j, bool isMajor) {
        m_selType = 2; m_selI = i; m_selJ = j; m_selIsMajor = isMajor;
        emit selectionChanged();
    }

    Q_INVOKABLE void clearSelection() {
        if (m_selType == 0) return;
        m_selType = 0; emit selectionChanged();
    }

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
    void selectionChanged();
    void invertColorsChanged();
    void saturationChanged();
    void hueChanged();
    void brightnessChanged();
    void contrastChanged();

private:
    bool  m_invertColors = false;
    qreal m_saturation   = 1.0;
    qreal m_hue          = 0.0;   // degrees
    qreal m_brightness   = 1.0;
    qreal m_contrast     = 1.0;
    QString m_source;
    qreal m_vpOriginX = 0;
    qreal m_vpOriginY = 0;
    qreal m_vpScale = 0; // 0 = sentinel "not yet set"
    int m_selType = 0; // 0=none 1=note 2=triad
    int m_selI = 0;
    int m_selJ = 0;
    bool m_selIsMajor = false;
};
