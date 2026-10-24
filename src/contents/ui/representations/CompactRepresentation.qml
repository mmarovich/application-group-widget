import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import QtQuick.Effects
import QtQuick.Shapes
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.draganddrop as DragDrop
import org.kde.kirigami as Kirigami
import "../lib/Translations.js" as Tr

DragDrop.DropArea {
    id: compactRoot

    property int itemsCount: 0
    property string panelIcon: "folder-apps"
    property string panelIconMode: "grid"
    property var items: []
    property bool showBadge: true
    property string lang: "en"
    // True while this group's drawer is open; drives the selection glow.
    property bool expanded: false
    property bool glowEnabled: true
    property int glowIntensity: 60

    signal toggleRequested()
    signal dropReceived(var event)

    Layout.minimumWidth: Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? height : Kirigami.Units.iconSizes.small
    Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? width : Kirigami.Units.iconSizes.small
    Layout.preferredWidth: Plasmoid.formFactor === PlasmaCore.Types.Horizontal ? height : Kirigami.Units.iconSizes.medium
    Layout.preferredHeight: Plasmoid.formFactor === PlasmaCore.Types.Vertical ? width : Kirigami.Units.iconSizes.medium

    preventStealing: true

    onContainsDragChanged: contained => {
        if (containsDrag) {
            hoverExpandTimer.restart();
        } else {
            hoverExpandTimer.stop();
        }
    }

    onDrop: event => {
        compactRoot.dropReceived(event);
    }

    Timer {
        id: hoverExpandTimer
        interval: 350
        onTriggered: {
            compactRoot.toggleRequested();
        }
    }

    Rectangle {
        id: hoverBg
        anchors.fill: parent
        anchors.margins: 2
        radius: width / 2
        color: mouseArea.containsMouse || compactRoot.containsDrag
            ? Kirigami.Theme.hoverColor
            : "transparent"
        opacity: compactRoot.containsDrag ? 0.8 : 0.5
        border.color: compactRoot.containsDrag ? Kirigami.Theme.highlightColor : "transparent"
        border.width: compactRoot.containsDrag ? 2 : 0

        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
    }

    // Selection glow: a soft accent-color bloom that radiates out from the button while
    // the drawer is open, and breathes with a deep pulse. glowIntensity (0-100) sets both brightness
    // and reach. Nothing is drawn or animated when the drawer is closed or glow is off.
    Item {
        id: selectionGlow
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        z: -1
        visible: active
        readonly property bool active: compactRoot.expanded && compactRoot.glowEnabled && level > 0
        readonly property real level: Math.max(0, Math.min(1, compactRoot.glowIntensity / 100))
        readonly property color accent: Kirigami.Theme.highlightColor
        readonly property color hot: Qt.lighter(accent, 1.35)
        readonly property real cornerRadius: Math.round(width * 0.28)
        // Breathing phase: 1 = peak (bright), 0 = dim point. 1.8s full cycle with
        // InOutSine easing, only while active. The intensity slider sets the peak; the
        // pulse dips from there:
        //   bloom brightness 20% -> 100% of peak, bloom reach 85% -> 100% (horizontal),
        //   inner halo 35% -> 100%, crisp ring 55% -> 100% (always identifiable).
        property real phase: 1.0
        readonly property real pulse: 0.20 + 0.80 * phase
        readonly property real reachPulse: 0.85 + 0.15 * phase
        readonly property real haloPulse: 0.35 + 0.65 * phase
        readonly property real ringPulse: 0.55 + 0.45 * phase

        SequentialAnimation on phase {
            running: selectionGlow.active
            loops: Animation.Infinite
            alwaysRunToEnd: false
            NumberAnimation { from: 1.0; to: 0.0; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.0; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
        }
        onActiveChanged: if (!active) phase = 1.0

        // Radial bloom: an accent gradient that fades smoothly with distance. Drawn as a
        // circle and squashed vertically, since a horizontal panel has more room to the
        // sides than above and below.
        component Bloom: Shape {
            id: bloomShape
            property real reach: 0
            property real strength: 1
            property color tint: selectionGlow.accent
            readonly property real r: selectionGlow.width / 2 + reach
            readonly property real core: (selectionGlow.width / 2) / r
            readonly property real a: Math.min(1, strength) * selectionGlow.pulse
            function c(f) { return Qt.rgba(tint.r, tint.g, tint.b, Math.min(1, a * f)); }
            function at(f) { return core + (1 - core) * f; }
            width: r * 2
            height: r * 2
            anchors.centerIn: parent
            visible: selectionGlow.active
            transform: Scale {
                origin.x: bloomShape.width / 2
                origin.y: bloomShape.height / 2
                // Reach breathes along the panel (GPU transform, no re-tessellation).
                xScale: selectionGlow.reachPulse
                // Vertically the panel window only extends a few pixels past the button, so
                // fade out within ~12px to avoid a hard edge at the window border.
                yScale: Math.min(1, (selectionGlow.height / 2 + Math.min(12, bloomShape.reach * 0.6)) / bloomShape.r)
            }
            ShapePath {
                strokeWidth: -1
                strokeColor: "transparent"
                fillGradient: RadialGradient {
                    centerX: bloomShape.r; centerY: bloomShape.r; centerRadius: bloomShape.r
                    focalX: bloomShape.r; focalY: bloomShape.r
                    GradientStop { position: 0.0; color: bloomShape.c(1.0) }
                    GradientStop { position: bloomShape.core; color: bloomShape.c(1.0) }
                    GradientStop { position: bloomShape.at(0.12); color: bloomShape.c(0.90) }
                    GradientStop { position: bloomShape.at(0.30); color: bloomShape.c(0.62) }
                    GradientStop { position: bloomShape.at(0.55); color: bloomShape.c(0.32) }
                    GradientStop { position: bloomShape.at(0.80); color: bloomShape.c(0.10) }
                    GradientStop { position: 1.0; color: bloomShape.c(0.0) }
                }
                startX: 0; startY: bloomShape.r
                PathArc { x: bloomShape.r * 2; y: bloomShape.r; radiusX: bloomShape.r; radiusY: bloomShape.r }
                PathArc { x: 0; y: bloomShape.r; radiusX: bloomShape.r; radiusY: bloomShape.r }
            }
        }

        // Wide outer bloom: reach and brightness both grow with intensity.
        Bloom {
            reach: selectionGlow.width * (0.3 + 2.7 * selectionGlow.level)
            strength: 0.4 + 0.8 * selectionGlow.level
        }
        // Brighter, tighter core so the light reads as coming from the button.
        Bloom {
            reach: selectionGlow.width * (0.15 + 0.85 * selectionGlow.level)
            strength: 0.25 + 0.65 * selectionGlow.level
            tint: selectionGlow.hot
        }

        // Tight inner halo hugging the button, so the glow reads as coming from it.
        Rectangle {
            id: innerShape
            anchors.centerIn: parent
            width: parent.width + 2
            height: parent.height + 2
            radius: selectionGlow.cornerRadius + 1
            color: selectionGlow.hot
            visible: false
        }
        MultiEffect {
            source: innerShape
            anchors.fill: innerShape
            visible: selectionGlow.active
            autoPaddingEnabled: true
            blurEnabled: true
            blur: 1.0
            blurMax: 12 + Math.round(20 * selectionGlow.level)
            opacity: Math.min(1, 0.45 + 0.75 * selectionGlow.level) * selectionGlow.haloPulse
        }

        // Crisp accent ring on the button edge.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, selectionGlow.cornerRadius - 1)
            color: Qt.rgba(selectionGlow.accent.r, selectionGlow.accent.g, selectionGlow.accent.b, (0.18 + 0.2 * selectionGlow.level) * selectionGlow.ringPulse)
            border.width: 1.5
            border.color: Qt.rgba(selectionGlow.hot.r, selectionGlow.hot.g, selectionGlow.hot.b, (0.6 + 0.4 * selectionGlow.level) * selectionGlow.ringPulse)
        }
    }

    Kirigami.Icon {
        id: iconItem
        visible: !appGrid.visible
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        source: {
            if (compactRoot.panelIcon && compactRoot.panelIcon !== "com.keyaruga.applicationgroup" && compactRoot.panelIcon !== "folder-apps") {
                return compactRoot.panelIcon;
            }
            return Qt.resolvedUrl("../../icons/logo.png");
        }
        active: mouseArea.containsMouse || compactRoot.containsDrag
    }

    // Phone-folder style icon: the first up to 4 item icons in a rounded square.
    AppGridIcon {
        id: appGrid
        visible: compactRoot.panelIconMode !== "custom" && compactRoot.items && compactRoot.items.length > 0
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) - Kirigami.Units.smallSpacing
        height: width
        items: compactRoot.items
        active: mouseArea.containsMouse || compactRoot.containsDrag
    }

    Rectangle {
        id: badge
        visible: compactRoot.showBadge && compactRoot.itemsCount > 0
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 1
        width: Math.max(badgeText.implicitWidth + 6, height)
        height: Kirigami.Units.iconSizes.small * 0.75
        radius: height / 2
        color: Kirigami.Theme.highlightColor

        QQC2.Label {
            id: badgeText
            anchors.centerIn: parent
            text: compactRoot.itemsCount > 99 ? "99+" : compactRoot.itemsCount
            font.pointSize: Math.max(6, Kirigami.Theme.smallFont.pointSize - 3)
            font.bold: true
            color: Kirigami.Theme.highlightedTextColor
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: compactRoot.toggleRequested()
    }
}
