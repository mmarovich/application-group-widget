.pragma library

// Drawer chrome shared by every Application Group. Glow, layout, titles,
// items, and the panel icon stay on the applet that owns them.
var SHARED_KEYS = ["backgroundStyle", "backgroundOpacity", "borderRadius"];

function isSharedKey(key) {
    return key === "backgroundStyle" || key === "backgroundOpacity" || key === "borderRadius";
}

function canonical(key, value) {
    if (key === "backgroundStyle") {
        return String(value === undefined || value === null ? "" : value);
    }
    if (key === "backgroundOpacity") {
        var opacity = Number(value);
        if (isNaN(opacity)) {
            opacity = 0.85;
        }
        return Math.round(opacity * 100) / 100;
    }
    var radius = Math.round(Number(value));
    if (isNaN(radius)) {
        radius = 16;
    }
    return radius;
}

function equal(key, a, b) {
    if (key === "backgroundOpacity") {
        if (a === undefined || b === undefined || a === null || b === null) {
            return false;
        }
        return Math.abs(Number(a) - Number(b)) < 0.001;
    }
    if (key === "borderRadius") {
        return Number(a) === Number(b);
    }
    return String(a) === String(b);
}

function displayedValue(key, previewValues, override, saved) {
    if (previewValues && previewValues[key] !== undefined) {
        return previewValues[key];
    }
    if (isSharedKey(key) && override && override[key] !== undefined) {
        return override[key];
    }
    return saved;
}

// What the other drawers should show while the Appearance page is open.
// Null when style, opacity, and radius still match the saved cluster, so a
// glow or layout edit does not repaint every drawer.
function previewCluster(saved, values) {
    if (!saved || !values) {
        return null;
    }
    var cluster = {
        backgroundStyle: values.backgroundStyle !== undefined
            ? canonical("backgroundStyle", values.backgroundStyle)
            : saved.backgroundStyle,
        backgroundOpacity: values.backgroundOpacity !== undefined
            ? canonical("backgroundOpacity", values.backgroundOpacity)
            : saved.backgroundOpacity,
        borderRadius: values.borderRadius !== undefined
            ? canonical("borderRadius", values.borderRadius)
            : saved.borderRadius
    };
    var same = true;
    for (var i = 0; i < SHARED_KEYS.length; i++) {
        var key = SHARED_KEYS[i];
        if (!equal(key, saved[key], cluster[key])) {
            same = false;
            break;
        }
    }
    return same ? null : cluster;
}

function savedCluster(configuration) {
    return {
        backgroundStyle: canonical("backgroundStyle", configuration.backgroundStyle),
        backgroundOpacity: canonical("backgroundOpacity", configuration.backgroundOpacity),
        borderRadius: canonical("borderRadius", configuration.borderRadius)
    };
}

function withSavedKey(saved, key, value) {
    var next = {
        backgroundStyle: saved.backgroundStyle,
        backgroundOpacity: saved.backgroundOpacity,
        borderRadius: saved.borderRadius
    };
    next[key] = canonical(key, value);
    return next;
}

function appletId(applet) {
    try {
        return String(applet.id);
    } catch (e) {
        return "";
    }
}

function samePlugin(applet, pluginName) {
    try {
        return String(applet.pluginName || "") === pluginName;
    } catch (e) {
        return false;
    }
}

function considerContainment(list, seen, containment) {
    if (!containment) {
        return;
    }
    var id = "";
    try {
        id = String(containment.id);
    } catch (eId) {
        id = "";
    }
    var mark = id || ("idx-" + list.length);
    if (seen[mark]) {
        return;
    }
    seen[mark] = true;
    list.push(containment);
}

// Plasma 6.3 exposes Containment.applets to QML. Corona.containments() is not
// invokable; probe it so a shell that does expose the list also shares style
// across panels and the desktop.
function containmentsOf(plasmoid) {
    var list = [];
    var seen = {};
    var own = null;
    try {
        own = plasmoid.containment;
    } catch (eOwn) {
        own = null;
    }
    considerContainment(list, seen, own);
    try {
        var corona = own ? own.corona : null;
        var more = null;
        if (corona) {
            more = corona.containments;
            if (typeof more === "function") {
                more = more();
            }
        }
        if (more && more.length) {
            for (var i = 0; i < more.length; i++) {
                considerContainment(list, seen, more[i]);
            }
        }
    } catch (eCorona) {
    }
    return list;
}

function forEachSibling(plasmoid, callback) {
    if (!plasmoid || typeof callback !== "function") {
        return;
    }
    var pluginName = "";
    var myId = "";
    try {
        pluginName = String(plasmoid.pluginName || "");
        myId = String(plasmoid.id);
    } catch (eSelf) {
        return;
    }
    var containments = containmentsOf(plasmoid);
    var seenApplet = {};
    for (var c = 0; c < containments.length; c++) {
        var applets = null;
        try {
            applets = containments[c].applets;
        } catch (eApplets) {
            applets = null;
        }
        if (!applets || !applets.length) {
            continue;
        }
        for (var i = 0; i < applets.length; i++) {
            var applet = applets[i];
            if (!applet || !samePlugin(applet, pluginName)) {
                continue;
            }
            var id = appletId(applet);
            if (!id || id === myId || seenApplet[id]) {
                continue;
            }
            seenApplet[id] = true;
            var config = null;
            try {
                config = applet.configuration;
            } catch (eConfig) {
                config = null;
            }
            if (!config) {
                continue;
            }
            try {
                callback(applet, config);
            } catch (eCallback) {
            }
        }
    }
}

function writeKeys(config, updates, persist) {
    var wrote = 0;
    for (var i = 0; i < SHARED_KEYS.length; i++) {
        var key = SHARED_KEYS[i];
        if (updates[key] === undefined) {
            continue;
        }
        var value = canonical(key, updates[key]);
        if (equal(key, config[key], value)) {
            continue;
        }
        config[key] = value;
        wrote++;
    }
    if (wrote && persist && config.writeConfig) {
        try {
            config.writeConfig();
        } catch (eWrite) {
        }
    }
    return wrote;
}

// persist=false updates the running applets. persist=true also calls
// KConfigPropertyMap.writeConfig() so a plasmashell restart keeps the match.
function writeToSiblings(plasmoid, updates, persist) {
    if (!updates) {
        return 0;
    }
    var wrote = 0;
    forEachSibling(plasmoid, function(applet, config) {
        wrote += writeKeys(config, updates, persist);
    });
    return wrote;
}

function persistSiblings(plasmoid) {
    forEachSibling(plasmoid, function(applet, config) {
        if (!config.writeConfig) {
            return;
        }
        try {
            config.writeConfig();
        } catch (ePersist) {
        }
    });
}
