import QtQuick
import FileIO

/**
 * DebugTools.qml
 * Translated and simplified for MuseScore 4 Interval ID Plugin
 */
Item {
    id: debugTools
    property string pluginName: "" 
    property string logContent: ""
    property alias logPath: fileHandler.source

    FileIO {
        id: fileHandler
        source: ""
        onError: console.log("FileIO Error: " + msg)
    }

    // Initialize the log file path if not manually set
    Component.onCompleted: {
        if (logPath === "" && pluginName !== "") {
            // Default: ~/Documents/MuseScore4/Plugins/PluginName/log.txt
            logPath = fileHandler.homePath() + "/Documents/MuseScore4/Plugins/" + pluginName + "/log.txt";
        }
    }

    // Automatically save and log shutdown when the plugin is closed
    Component.onDestruction: {
        if (logPath !== "") {
            appendLog("Shutdown at " + getSystemDate());
            saveLog();
        }
    }

    // Add a line to the internal log string
    function appendLog(text) {
        logContent = logContent + text + "\n";
    }

    // Write the current log string to the physical file
    function saveLog(clearAfterSaving = false) {
        fileHandler.write(logContent);
        if (clearAfterSaving) {
            logContent = "";
        }
    }

    // Returns a formatted timestamp
    function getSystemDate() {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd h:mm:ss AP");
    }

    /**
     * Inspects a MuseScore element and logs its properties.
     * Useful for seeing what 'notes' or 'chords' actually contain.
     */
    function inspectElement(element, showFunctions = false) {
        appendLog("===> Element Name: " + element.name + " | Type: " + element.type);
        
        for (var prop in element) {
            if (typeof element[prop] !== "function") {
                if (prop !== "objectName" && element[prop] !== undefined) {
                    appendLog("   Property " + prop + ": " + element[prop]);
                }
            }
        }

        if (!showFunctions) return;

        for (var func in element) {
            if (typeof element[func] === "function") {
                appendLog("   Function " + func);
            }
        }
    }
}