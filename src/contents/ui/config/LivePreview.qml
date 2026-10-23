import QtQuick
import org.kde.plasma.plasmoid

// Pushes the page's unsaved cfg_* values into Plasmoid.configuration.livePreview.
// Do not declare cfg_livePreview on the page: Apply/OK copies every cfg_<key> that exists.
QtObject {
    id: bridge

    required property var page
    property string tag

    function isCfgProperty(name) {
        if (!name || name.indexOf("cfg_") !== 0) {
            return false;
        }
        if (name === "cfg_livePreview") {
            return false;
        }
        // for-in also lists the "...Changed" signal and the "...Default" reset value.
        if (name.length > 7 && name.indexOf("Default") === name.length - 7) {
            return false;
        }
        if (name.length > 7 && name.indexOf("Changed") === name.length - 7) {
            return false;
        }
        return true;
    }

    function schedule() {
        bridge.publishTimer.restart();
    }

    function publish() {
        try {
            if (!bridge.page) {
                return;
            }
            var allowed = {};
            var keys = Plasmoid.configuration.keys();
            if (keys && keys.forEach) {
                keys.forEach(function(key) {
                    allowed[String(key)] = true;
                });
            }
            var values = {};
            var seen = {};
            for (var name in bridge.page) {
                if (seen[name] || !bridge.isCfgProperty(name)) {
                    continue;
                }
                seen[name] = true;
                var key = name.substring(4);
                if (!allowed[key]) {
                    continue;
                }
                values[key] = bridge.page[name];
            }
            var payload = JSON.stringify({
                tag: bridge.tag,
                values: values
            });
            if (String(Plasmoid.configuration.livePreview || "") !== payload) {
                Plasmoid.configuration.livePreview = payload;
            }
        } catch (e) {
        }
    }

    function clearIfMine() {
        try {
            var raw = Plasmoid.configuration.livePreview;
            if (!raw) {
                return;
            }
            var parsed = JSON.parse(String(raw));
            if (parsed && parsed.tag === bridge.tag) {
                Plasmoid.configuration.livePreview = "";
            }
        } catch (e) {
        }
    }

    function connectAll() {
        try {
            if (!bridge.page) {
                return;
            }
            var seen = {};
            for (var name in bridge.page) {
                if (seen[name] || !bridge.isCfgProperty(name)) {
                    continue;
                }
                seen[name] = true;
                var sig = bridge.page[name + "Changed"];
                if (sig && typeof sig.connect === "function") {
                    sig.connect(bridge.schedule);
                }
            }
        } catch (e) {
        }
    }

    // QtObject has no default property, so the Timer is held in a property.
    property Timer publishTimer: Timer {
        interval: 60
        repeat: false
        onTriggered: bridge.publish()
    }

    Component.onCompleted: {
        bridge.connectAll();
        bridge.schedule();
    }

    Component.onDestruction: bridge.clearIfMine()
}
