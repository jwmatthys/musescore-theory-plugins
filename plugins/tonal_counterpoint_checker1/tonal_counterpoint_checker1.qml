import QtQuick
import MuseScore
import "HarmonyAnalysis.js" as Harmony
import "HelperFunctions.js" as Helpers
import "Species1ErrorChecking.js" as Errors

MuseScore {
    title: "Tonal Counterpoint Species 1 Checker"
    description: "Checks two-part species 1 counterpoint (note-against-note, all chord tones)"
    version: "2.0"
    thumbnailName: "thumbnail_tonal1.png"
    categoryCode: "Proofreading"
    requiresScore: true

    readonly property string colorError: "#b30000" 
    readonly property string colorStats: "#004a99"

    function addErrorLabels(tick, errors) {
        if (errors.length === 0) return;
        var outCursor = curScore.newCursor(); 
        outCursor.rewindToTick(tick);
        var text = newElement(Element.STAFF_TEXT);
        text.text = [...new Set(errors)].join("\n");
        text.color = colorError;
        outCursor.add(text);
    }

    function calculateStatistics(sortedTicks, tickGroups) {
        var totalIntervals = 0, perfectCount = 0;
        
        for (var i = 0; i < sortedTicks.length; i++) {
            var notes = tickGroups[sortedTicks[i]];
            if (notes && notes.length > 1) {
                for (var x = 0; x < notes.length; x++) {
                    for (var y = x + 1; y < notes.length; y++) {
                        totalIntervals++;
                        var low = (notes[x].pitch < notes[y].pitch) ? notes[x] : notes[y];
                        var high = (notes[x].pitch < notes[y].pitch) ? notes[y] : notes[x];
                        if (Helpers.getIntervalType(low, high)) perfectCount++;
                    }
                }
            }
        }
        return { total: totalIntervals, perfect: perfectCount };
    }

    function addStatisticsFooter(sortedTicks, tickGroups, lastStaff) {
        var stats = calculateStatistics(sortedTicks, tickGroups);
        var perfRatio = (stats.total > 0) ? Math.round((stats.perfect / stats.total) * 100) : 0;
        
        var cursor = curScore.newCursor();
        cursor.rewind(1); 
        cursor.staffIdx = lastStaff; 
        
        var footer = newElement(Element.STAFF_TEXT);
        footer.text = "--- SPECIES 1 ANALYSIS ---\nIntervals: " + stats.total + " | Perfect: " + perfRatio + "%";
        footer.color = colorStats; 
        footer.placement = Placement.BELOW;
        cursor.add(footer);
    }

    onRun: {
        if (!curScore) { quit(); return; }
        curScore.startCmd("Species 1 Counterpoint Analysis");
        if (curScore.selection.elements.length === 0) { cmd("select-all"); }

        // Collect notes by tick
        var tickGroups = {};
        curScore.selection.elements.forEach(function(el) {
            if (el && el.type === Element.NOTE && el.parent && el.parent.parent) {
                var tick = el.parent.parent.tick;
                if (!tickGroups[tick]) tickGroups[tick] = [];
                tickGroups[tick].push(el);
            }
        });

        var lastStaff = curScore.selection.endStaff > curScore.selection.startStaff ? 
                       curScore.selection.endStaff - 1 : curScore.selection.startStaff;
        var sortedTicks = Object.keys(tickGroups).map(Number).sort(function(a,b) { return a - b; });
        if (sortedTicks.length === 0) { quit(); return; }

        // Find voices
        var firstChord = tickGroups[sortedTicks[0]].sort(function(a,b) { return a.pitch - b.pitch; });
        var voices = firstChord.map(function(n) { return { staffIdx: n.staffIdx, voice: n.voice }; });
        var bassID = voices[0];
        var sopID = voices[voices.length - 1];
        
        // Determine tonic and mode
        var keyResult = Harmony.determineKeyAndMode(sortedTicks, tickGroups, curScore, Element, newElement);
        var tonicTPC = keyResult.tonic;
        var mode = keyResult.mode;

        // Main check loop - simple tick-by-tick analysis
        for (var j = 0; j < sortedTicks.length; j++) {
            var tick = sortedTicks[j];
            var notes = tickGroups[tick];
            var nextNotes = (j + 1 < sortedTicks.length) ? tickGroups[sortedTicks[j + 1]] : null;

            // Get roman numeral at this tick
            var rn = "";
            var cursor = curScore.newCursor(); 
            cursor.rewindToTick(tick);
            if (cursor.segment) {
                cursor.segment.annotations.forEach(function(ann) {
                    if (ann.type === Element.HARMONY) rn = ann.text;
                });
            }

            var hData = Harmony.getChordData(rn, tonicTPC, mode);
            var errors = Errors.checkTickErrors(notes, nextNotes, rn, hData, voices, bassID, sopID);
            addErrorLabels(tick, errors);
        }

        // Add statistics
        addStatisticsFooter(sortedTicks, tickGroups, lastStaff);
        
        curScore.endCmd(); 
        quit();
    }
}
