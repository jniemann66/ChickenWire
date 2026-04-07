import QtQuick
import ChickenWire

Item {
    anchors.fill: parent

    layer.enabled: visualizerSwitcher.invertColors
                || visualizerSwitcher.saturation  !== 1.0
                || visualizerSwitcher.hue         !== 0.0
                || visualizerSwitcher.brightness  !== 1.0
                || visualizerSwitcher.contrast    !== 1.0
    layer.effect: ShaderEffect {
        property real saturation:   visualizerSwitcher.saturation
        property real invertColors: visualizerSwitcher.invertColors ? 1.0 : 0.0
        property real hue:          visualizerSwitcher.hue
        property real brightness:   visualizerSwitcher.brightness
        property real contrast:     visualizerSwitcher.contrast
        fragmentShader: "qrc:/shaders/coloreffect.frag.qsb"
    }

    // Shared background — lives here so neither canvas bleeds its own fill
    // through at partial opacity during the cross-fade.
    Rectangle {
        anchors.fill: parent
        color: Theme.background
    }

    // Both visualizers are always loaded; opacity drives the cross-fade.
    // layer.enabled renders each to its own GPU texture before alpha-blending,
    // giving correct compositing over the background above.

    Loader {
        id: tonnetzLoader
        anchors.fill: parent
        source: "tonnetz.qml"
        opacity: visualizerSwitcher.source === "tonnetz.qml" ? 1.0 : 0.0
        enabled: visualizerSwitcher.source === "tonnetz.qml"
        layer.enabled: true
        Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }
        onLoaded: if (visualizerSwitcher.source === "tonnetz.qml") item.forceActiveFocus()
    }

    Loader {
        id: cwLoader
        anchors.fill: parent
        source: "chickenWire.qml"
        opacity: visualizerSwitcher.source === "chickenWire.qml" ? 1.0 : 0.0
        enabled: visualizerSwitcher.source === "chickenWire.qml"
        layer.enabled: true
        Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }
        onLoaded: if (visualizerSwitcher.source === "chickenWire.qml") item.forceActiveFocus()
    }

    // Transfer keyboard focus to whichever view is becoming active.
    Connections {
        target: visualizerSwitcher
        function onSourceChanged() {
            var loader = visualizerSwitcher.source === "tonnetz.qml" ? tonnetzLoader : cwLoader
            if (loader.item) loader.item.forceActiveFocus()
        }
    }
}
