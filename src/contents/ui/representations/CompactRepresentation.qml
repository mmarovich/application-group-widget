import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
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

    // Selection glow: accent-colored soft halo that gently pulses while the drawer is open.
    // Hidden and not animating when closed, so it costs nothing at idle.
    Item {
        id: selectionGlow
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        visible: compactRoot.expanded
        opacity: 1

        readonly property color accent: Kirigami.Theme.highlightColor
        readonly property real cornerRadius: Math.round(width * 0.28)

        // Inner tint behind the icon.
        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: Math.max(0, selectionGlow.cornerRadius - 3)
            color: Qt.rgba(selectionGlow.accent.r, selectionGlow.accent.g, selectionGlow.accent.b, 0.30)
        }

        // Three rings fading outward give a soft edge without a shader.
        Repeater {
            model: [0.35, 0.70, 1.0]
            Rectangle {
                required property int index
                required property var modelData
                anchors.fill: parent
                anchors.margins: index
                radius: Math.max(0, selectionGlow.cornerRadius - index)
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(selectionGlow.accent.r, selectionGlow.accent.g, selectionGlow.accent.b, modelData)
            }
        }

        SequentialAnimation on opacity {
            running: compactRoot.expanded
            loops: Animation.Infinite
            alwaysRunToEnd: false
            NumberAnimation { from: 1.0; to: 0.5; duration: 850; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.5; to: 1.0; duration: 850; easing.type: Easing.InOutSine }
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

    QQC2.ToolTip {
        visible: false // Max: duplicate of the panel tooltip
        delay: Kirigami.Units.toolTipDelay
        text: Tr.t(compactRoot.lang, "appName") + " (" + Tr.t(compactRoot.lang, "itemsCount", compactRoot.itemsCount) + ")"
    }
}
