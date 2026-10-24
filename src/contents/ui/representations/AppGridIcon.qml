import QtQuick
import org.kde.kirigami as Kirigami

// Folder-style panel icon: up to 4 item icons in a 2x2 grid on a rounded square.
// 1 item = one centered tile, 2 = side by side, 3 = two on top + one centered below, 4 = full grid.
Item {
    id: gridIcon

    property var items: []
    property bool active: false

    readonly property var shown: {
        var list = gridIcon.items || [];
        return list.slice(0, 4);
    }
    readonly property int count: shown.length

    // Inner layout geometry (whole pixels keep the small icons crisp).
    readonly property int pad: Math.max(2, Math.round(width * 0.10))
    readonly property int gap: Math.max(1, Math.round(width * 0.05))
    readonly property int cell: Math.floor((width - pad * 2 - gap) / 2)

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Math.round(width * 0.26)
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b,
                       gridIcon.active ? 0.22 : 0.14)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)

        Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }
    }

    Repeater {
        model: gridIcon.count

        Kirigami.Icon {
            required property int index
            readonly property var entry: gridIcon.shown[index]
            readonly property int row: index < 2 ? 0 : 1
            readonly property int itemsInRow: row === 0 ? Math.min(2, gridIcon.count) : gridIcon.count - 2
            readonly property int col: index % 2
            readonly property int rows: gridIcon.count > 2 ? 2 : 1

            width: gridIcon.cell
            height: gridIcon.cell
            x: {
                var rowWidth = itemsInRow * gridIcon.cell + (itemsInRow - 1) * gridIcon.gap;
                var start = Math.round((gridIcon.width - rowWidth) / 2);
                return start + col * (gridIcon.cell + gridIcon.gap);
            }
            y: {
                var blockHeight = rows * gridIcon.cell + (rows - 1) * gridIcon.gap;
                var start = Math.round((gridIcon.height - blockHeight) / 2);
                return start + row * (gridIcon.cell + gridIcon.gap);
            }
            source: (entry && entry.icon) ? entry.icon : "application-x-executable"
            fallback: "application-x-executable"
            active: gridIcon.active
        }
    }
}
