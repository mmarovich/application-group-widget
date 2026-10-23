import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import "../lib/Translations.js" as Tr
import "../lib/UiStyle.js" as UiStyle

KCM.SimpleKCM {
    id: page

    property string cfg_viewMode: "grid"
    property string cfg_viewModeDefault: "grid"
    property string cfg_columnsMode: "auto"
    property string cfg_columnsModeDefault: "auto"
    property int cfg_gridColumns: 4
    property int cfg_gridColumnsDefault: 4
    property string cfg_iconSize: "medium"
    property string cfg_iconSizeDefault: "medium"
    property string cfg_backgroundStyle: "card"
    property string cfg_backgroundStyleDefault: "card"
    property real cfg_backgroundOpacity: 0.85
    property real cfg_backgroundOpacityDefault: 0.85
    property real cfg_backgroundHue: -1
    property real cfg_backgroundHueDefault: -1
    property int cfg_borderRadius: 16
    property int cfg_borderRadiusDefault: 16
    property alias cfg_showLabels: showLabelsCheck.checked
    property bool cfg_showLabelsDefault: true
    property int cfg_fontSizeDelta: 0
    property int cfg_fontSizeDeltaDefault: 0
    property string cfg_language: "auto"

    readonly property string lang: {
        if (cfg_language === "fa" || cfg_language === "en")
            return cfg_language;
        return Qt.locale().name.indexOf("fa") === 0 ? "fa" : "en";
    }

    function tr(key, args) { return Tr.t(lang, key, args); }

    LayoutMirroring.enabled: page.lang === "fa"
    LayoutMirroring.childrenInherit: true

    LivePreview {
        page: page
        tag: "appearance"
    }

    Kirigami.FormLayout {

        QQC2.ComboBox {
            Kirigami.FormData.label: page.tr("cfgViewMode")
            textRole: "label"
            valueRole: "value"
            model: [
                { value: "grid", label: page.tr("cfgGrid") },
                { value: "list", label: page.tr("cfgList") }
            ]
            Component.onCompleted: currentIndex = indexOfValue(page.cfg_viewMode)
            onActivated: page.cfg_viewMode = currentValue
        }

        QQC2.ComboBox {
            visible: page.cfg_viewMode === "grid"
            Kirigami.FormData.label: page.tr("cfgColumnsMode")
            textRole: "label"
            valueRole: "value"
            model: [
                { value: "auto",  label: page.tr("cfgColumnsAuto") },
                { value: "fixed", label: page.tr("cfgColumnsFixed") }
            ]
            Component.onCompleted: currentIndex = indexOfValue(page.cfg_columnsMode)
            onActivated: page.cfg_columnsMode = currentValue
        }

        QQC2.ComboBox {
            visible: page.cfg_viewMode === "grid" && page.cfg_columnsMode === "fixed"
            Kirigami.FormData.label: page.tr("cfgGridColumns")
            textRole: "label"
            valueRole: "value"
            model: [
                { value: 2, label: "2" },
                { value: 3, label: "3" },
                { value: 4, label: "4" },
                { value: 5, label: "5" },
                { value: 6, label: "6" },
                { value: 7, label: "7" },
                { value: 8, label: "8" }
            ]
            Component.onCompleted: currentIndex = indexOfValue(page.cfg_gridColumns)
            onActivated: page.cfg_gridColumns = currentValue
        }

        QQC2.ComboBox {
            Kirigami.FormData.label: page.tr("cfgIconSize")
            textRole: "label"
            valueRole: "value"
            model: [
                { value: "small",  label: page.tr("cfgSizeSmall") },
                { value: "medium", label: page.tr("cfgSizeMedium") },
                { value: "large",  label: page.tr("cfgSizeLarge") },
                { value: "huge",   label: page.tr("cfgSizeHuge") }
            ]
            Component.onCompleted: currentIndex = indexOfValue(page.cfg_iconSize)
            onActivated: page.cfg_iconSize = currentValue
        }

        QQC2.CheckBox {
            id: showLabelsCheck
            Kirigami.FormData.label: page.tr("cfgShowLabels")
            checked: true
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.ComboBox {
            Kirigami.FormData.label: page.tr("cfgBackgroundStyle")
            textRole: "label"
            valueRole: "value"
            model: [
                { value: "card",    label: page.tr("cfgStyleCard") },
                { value: "flat",    label: page.tr("cfgStyleFlat") },
                { value: "outline", label: page.tr("cfgStyleOutline") }
            ]
            Component.onCompleted: currentIndex = Math.max(0, indexOfValue(page.cfg_backgroundStyle === "glass" ? "card" : page.cfg_backgroundStyle))
            onActivated: page.cfg_backgroundStyle = currentValue
        }

        RowLayout {
            Kirigami.FormData.label: page.tr("cfgBackgroundOpacity")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                from: 0.1
                to: 1.0
                stepSize: 0.05
                value: page.cfg_backgroundOpacity
                onMoved: page.cfg_backgroundOpacity = Math.round(value * 100) / 100
            }

            QQC2.Label {
                text: Math.round(page.cfg_backgroundOpacity * 100) + "%"
            }
        }

        RowLayout {
            Kirigami.FormData.label: page.tr("cfgBackgroundColor")
            spacing: Kirigami.Units.smallSpacing

            // Far left = theme default, then the hues 0..1 (stored as backgroundHue).
            // Slider runs from -0.08 so the theme-default notch is easy to hit.
            QQC2.Slider {
                id: hueSlider
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                from: -0.08
                to: 1.0
                stepSize: 0.01
                value: page.cfg_backgroundHue < 0 ? -0.08 : page.cfg_backgroundHue
                onMoved: page.cfg_backgroundHue = value < 0 ? -1 : Math.round(value * 100) / 100

                // The desktop style draws its handle inside its own background,
                // so a custom track needs its own handle.
                handle: Rectangle {
                    x: hueSlider.leftPadding + hueSlider.visualPosition * (hueSlider.availableWidth - width)
                    y: hueSlider.topPadding + hueSlider.availableHeight / 2 - height / 2
                    implicitWidth: Kirigami.Units.gridUnit * 1.1
                    implicitHeight: Kirigami.Units.gridUnit * 1.1
                    radius: width / 2
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    Kirigami.Theme.inherit: false
                    color: hueSlider.pressed ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
                    border.width: 1
                    border.color: hueSlider.hovered || hueSlider.pressed ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.35)
                }

                background: Item {
                    x: hueSlider.leftPadding
                    y: hueSlider.topPadding + hueSlider.availableHeight / 2 - height / 2
                    width: hueSlider.availableWidth
                    height: Math.round(Kirigami.Units.gridUnit * 0.45)

                    // Theme-default segment, then the rainbow.
                    Rectangle {
                        id: themeSeg
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * 0.08 / 1.08
                        height: parent.height
                        radius: height / 2
                        color: Kirigami.Theme.backgroundColor
                        border.width: 1
                        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
                    }
                    Rectangle {
                        anchors.left: themeSeg.right
                        anchors.right: parent.right
                        anchors.leftMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        height: parent.height
                        radius: height / 2
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0;   color: Qt.hsla(0.0,   0.45, 0.45, 1) }
                            GradientStop { position: 0.167; color: Qt.hsla(0.167, 0.45, 0.45, 1) }
                            GradientStop { position: 0.333; color: Qt.hsla(0.333, 0.45, 0.45, 1) }
                            GradientStop { position: 0.5;   color: Qt.hsla(0.5,   0.45, 0.45, 1) }
                            GradientStop { position: 0.667; color: Qt.hsla(0.667, 0.45, 0.45, 1) }
                            GradientStop { position: 0.833; color: Qt.hsla(0.833, 0.45, 0.45, 1) }
                            GradientStop { position: 1.0;   color: Qt.hsla(1.0,   0.45, 0.45, 1) }
                        }
                    }
                }
            }

            Rectangle {
                visible: page.cfg_backgroundHue >= 0
                implicitWidth: Kirigami.Units.gridUnit * 1.2
                implicitHeight: Kirigami.Units.gridUnit * 1.2
                radius: Kirigami.Units.smallSpacing
                color: Qt.hsla(Math.max(0, page.cfg_backgroundHue), 0.45, Kirigami.Theme.textColor.hslLightness > 0.5 ? 0.30 : 0.82, 1)
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.4)
            }

            QQC2.Label {
                visible: page.cfg_backgroundHue < 0
                text: page.tr("cfgThemeDefault")
            }
        }

        RowLayout {
            Kirigami.FormData.label: page.tr("cfgBorderRadius")
            spacing: Kirigami.Units.smallSpacing

            QQC2.Slider {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 10
                from: 0
                to: 32
                stepSize: 2
                value: page.cfg_borderRadius
                onMoved: page.cfg_borderRadius = Math.round(value)
            }

            QQC2.Label {
                text: page.cfg_borderRadius + "px"
            }
        }

        QQC2.SpinBox {
            Kirigami.FormData.label: page.tr("cfgFontSizeDelta")
            from: -2
            to: 6
            value: page.cfg_fontSizeDelta
            onValueModified: page.cfg_fontSizeDelta = value
        }
    }
}
