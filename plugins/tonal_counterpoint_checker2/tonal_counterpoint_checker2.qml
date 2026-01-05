import QtQuick 2.0
import MuseScore 3.0
import "HarmonyAnalysis.js" as Harmony
import "HelperFunctions.js" as Helpers
import "Species2NCTAnalysis.js" as NCT
import "Species2ErrorChecking.js" as Errors

MuseScore {
    title: "Tonal Counterpoint Species 2 Checker"
    description: "Checks two-part species 2 counterpoint (only passing tones allowed)"
    version: "1.0"
    categoryCode: "Proofreading"
    requiresScore: true

    readonly property string colorError: "#b30000" 
    readonly property string colorStats: "#004a99"

    function createTickAnalysis(sortedTicks, tickGroups, bassOnsets, tonicTPC, mode, bassID, sopID) {
        var analysis = [];
        
        // Pass 1: Create basic tick analysis
        for (var i = 0; i < sortedTicks.length; i++) {
            var tick = sortedTicks[i];
            var notes = tickGroups[tick];
            var isBassOnset = (bassOnsets.indexOf(tick) !== -1);
            var context = Harmony.getCurrentHarmonyContext(tick, bassOnsets, tickGroups, tonicTPC, mode, curScore, Element);
            
            analysis.push({
                tick: tick,
                tickIdx: i,
                notes: notes,
                isBassOnset: isBassOnset,
                rn: context.rn,
                hData: context.hData,
                noteAnalysis: []
            });
        }
        
        // Pass 2: Analyze each note and find next bass onset
        for (var i = 0; i < analysis.length; i++) {
            analysis[i].notes.forEach(function(note) {
                analysis[i].noteAnalysis.push(NCT.analyzeNoteAtTick(note, i, analysis, bassID, sopID));
            });
            
            var nextBassOnsetIdx = i + 1;
            while (nextBassOnsetIdx < analysis.length && !analysis[nextBassOnsetIdx].isBassOnset) {
                nextBassOnsetIdx++;
            }
            if (nextBassOnsetIdx < analysis.length) {
                analysis[i].noteAnalysis.forEach(function(noteAna) {
                    noteAna.nextBassOnsetNote = Helpers.findNoteInSameVoice(noteAna.note, analysis[nextBassOnsetIdx].notes);
                });
            }
        }
        
        // No Pass 3 needed - species 2 doesn't have patterns to detect
        
        return analysis;
    }

    function addErrorLabels(tick, errors) {
        if (errors.length === 0) return;
        var outCursor = curScore.newCursor(); 
        outCursor.rewindToTick(tick);
        var text = newElement(Element.STAFF_TEXT);
        text.text = [...new Set(errors)].join("\n");
        text.color = colorError;
        outCursor.add(text);
    }

    function calculateStatistics(analysis) {
        var totalIntervals = 0, perfectCount = 0;
        analysis.forEach(function(ana) {
            if (ana.notes && ana.notes.length > 1) {
                for (var x = 0; x < ana.notes.length; x++) {
                    for (var y = x + 1; y < ana.notes.length; y++) {
                        totalIntervals++;
                        var low = (ana.notes[x].pitch < ana.notes[y].pitch) ? ana.notes[x] : ana.notes[y];
                        var high = (ana.notes[x].pitch < ana.notes[y].pitch) ? ana.notes[y] : ana.notes[x];
                        if (Helpers.getIntervalType(low, high)) perfectCount++;
                    }
                }
            }
        });
        return { total: totalIntervals, perfect: perfectCount };
    }

    function countPassingTones(analysis) {
        var count = 0;
        analysis.forEach(function(ana) {
            ana.noteAnalysis.forEach(function(noteAna) {
                if (!noteAna.isBass && !noteAna.isChordTone) {
                    if (NCT.isPassingTone(noteAna, ana.hData)) {
                        count++;
                    }
                }
            });
        });
        return count;
    }

    function addStatisticsFooter(analysis, lastStaff, bassOnsets) {
        var stats = calculateStatistics(analysis);
        var perfRatio = (stats.total > 0) ? Math.round((stats.perfect / stats.total) * 100) : 0;
        var ptCount = countPassingTones(analysis);
        
        var cursor = curScore.newCursor();
        cursor.rewind(1); 
        cursor.staffIdx = lastStaff; 
        var footer = newElement(Element.STAFF_TEXT);
        footer.text = "--- SPECIES 2 ANALYSIS ---\nBass Onsets: " + bassOnsets.length + 
                     " | Perfect: " + perfRatio + "%\nPassing Tones: " + ptCount;
        footer.color = colorStats; 
        footer.placement = Placement.BELOW;
        cursor.add(footer);
    }

    onRun: {
        if (!curScore) { quit(); return; }
        curScore.startCmd("Species 2 Counterpoint Analysis");
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
        
        // Determine tonic, mode, and bass onsets
        var tonicTPC = Harmony.determineTonic(sortedTicks, tickGroups, curScore, Element);
        var mode = Harmony.determineMode(sortedTicks, curScore, Element);
        var bassOnsets = Helpers.identifyBassOnsets(sortedTicks, tickGroups, bassID);

        // Analyze all ticks
        var analysis = createTickAnalysis(sortedTicks, tickGroups, bassOnsets, tonicTPC, mode, bassID, sopID);

        // Check for errors
        for (var i = 0; i < analysis.length; i++) {
            var isFirst = (i === 0);
            var isLast = (i === analysis.length - 1);
            var errors = Errors.checkTickErrors(analysis[i], analysis, voices, bassID, sopID, isFirst, isLast);
            addErrorLabels(analysis[i].tick, errors);
        }

        // Add statistics
        addStatisticsFooter(analysis, lastStaff, bassOnsets);
        
        curScore.endCmd(); 
        quit();
    }
}
