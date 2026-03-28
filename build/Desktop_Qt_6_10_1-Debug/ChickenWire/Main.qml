import QtQuick

Item {
    anchors.fill: parent

    // Shared background — lives here so neither canvas bleeds its own fill
    // through at partial opacity during the cross-fade.
    Rectangle {
        anchors.fill: parent
        color: "#1a1a2e"
    }

    // Both visualizers are always loaded; opacity drives the cross-fade.
    // layer.enabled renders each to its own GPU texture before alpha-blending,
    // giving correct compositing over the background above.

    Loader {
        id: tonnetzLoader
        anchors.fill: parent
        source: "Tonnetz.qml"
        opacity: visualizerSwitcher.source === "Tonnetz.qml" ? 1.0 : 0.0
        enabled: visualizerSwitcher.source === "Tonnetz.qml"
        layer.enabled: true
        Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }
        onLoaded: if (visualizerSwitcher.source === "Tonnetz.qml") item.forceActiveFocus()
    }

    Loader {
        id: cwLoader
        anchors.fill: parent
        source: "ChickenWire.qml"
        opacity: visualizerSwitcher.source === "ChickenWire.qml" ? 1.0 : 0.0
        enabled: visualizerSwitcher.source === "ChickenWire.qml"
        layer.enabled: true
        Behavior on opacity { NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad } }
        onLoaded: if (visualizerSwitcher.source === "ChickenWire.qml") item.forceActiveFocus()
    }

    // Transfer keyboard focus to whichever view is becoming active.
    Connections {
        target: visualizerSwitcher
        function onSourceChanged() {
            var loader = visualizerSwitcher.source === "Tonnetz.qml" ? tonnetzLoader : cwLoader
            if (loader.item) loader.item.forceActiveFocus()
        }
    }
}
