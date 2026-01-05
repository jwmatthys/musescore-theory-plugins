import QtQuick 2.0
import MuseScore 3.0
import "HarmonyAnalysis.js" as Harmony
import "HelperFunctions.js" as Helpers
import "NCTAnalysis.js" as NCT
import "ErrorChecking.js" as Errors

MuseScore {
    title: "Tonal Counterpoint Species 4 Checker"
    description: "Checks two-part species 4 counterpoint with syncopation and suspensions"
    version: "2.0"
    categoryCode: "Proofreading"
    requiresScore: true

    readonly property string colorError: "#b30000" 
    readonly property string colorPattern: "#2e7d32"
    readonly property string colorStats: "#004a99"

    function createTickAnalysis(sortedTicks, tickGroups, bassOnsets, tonicTPC, bassID, sopID) {
        var analysis = [];
        
        // Pass 1: Create basic tick analysis
        for (var i = 0; i < sortedTicks.length; i++) {
            var tick = sortedTicks[i];
            var notes = tickGroups[tick];
            var isBassOnset = (bassOnsets.indexOf(tick) !== -1);
            var context = Harmony.getCurrentHarmonyContext(tick, bassOnsets, tickGroups, tonicTPC, curScore, Element);
            
            analysis.push({
                tick: tick,
                tickIdx: i,
                notes: notes,
                isBassOnset: isBassOnset,
                rn: context.rn,
                hData: context.hData,
                noteAnalysis: [],
                intervalType: null,
                bassNote: null,
                sopNote: null
            });
        }
        
        // Pass 2: Analyze each note
        for (var i = 0; i < analysis.length; i++) {
            analysis[i].notes.forEach(function(note) {
                analysis[i].noteAnalysis.push(NCT.analyzeNoteAtTick(note, i, analysis, bassID, sopID));
            });
        }
        
        // Pass 3: Track sounding notes and calculate intervals
        var lastBassNote = null;
        var lastSopNote = null;
        
        for (var i = 0; i < analysis.length; i++) {
            var bassAtThisTick = analysis[i].notes.find(function(n) {
                return n.staffIdx === bassID.staffIdx && n.voice === bassID.voice;
            });
            var sopAtThisTick = analysis[i].notes.find(function(n) {
                return n.staffIdx === sopID.staffIdx && n.voice === sopID.voice;
            });
            
            if (bassAtThisTick) lastBassNote = bassAtThisTick;
            if (sopAtThisTick) lastSopNote = sopAtThisTick;
            
            analysis[i].bassNote = bassAtThisTick ? bassAtThisTick : lastBassNote;
            analysis[i].sopNote = sopAtThisTick ? sopAtThisTick : lastSopNote;
            analysis[i].intervalType = Helpers.getIntervalType(analysis[i].bassNote, analysis[i].sopNote);
        }
        
        // Pass 4: Link note relationships
        for (var i = 0; i < analysis.length; i++) {
            // Find next bass onset
            var nextBassOnsetIdx = i + 1;
            while (nextBassOnsetIdx < analysis.length && !analysis[nextBassOnsetIdx].isBassOnset) {
                nextBassOnsetIdx++;
            }
            if (nextBassOnsetIdx < analysis.length) {
                analysis[i].noteAnalysis.forEach(function(noteAna) {
                    noteAna.nextBassOnsetNote = Helpers.findNoteInSameVoice(noteAna.note, analysis[nextBassOnsetIdx].notes);
                });
            }
            
            // Find previous non-bass onset
            var prevNonBassOnsetIdx = i - 1;
            while (prevNonBassOnsetIdx >= 0 && analysis[prevNonBassOnsetIdx].isBassOnset) {
                prevNonBassOnsetIdx--;
            }
            if (prevNonBassOnsetIdx >= 0) {
                analysis[i].noteAnalysis.forEach(function(noteAna) {
                    var prevNote = Helpers.findNoteInSameVoice(noteAna.note, analysis[prevNonBassOnsetIdx].notes);
                    if (prevNote) {
                        var prevAna = analysis[prevNonBassOnsetIdx].noteAnalysis.find(function(n) {
                            return n.note === prevNote;
                        });
                        noteAna.prevNonBassOnsetNote = prevAna;
                    }
                });
            }
            
            // Link next note analysis
            analysis[i].noteAnalysis.forEach(function(noteAna) {
                if (noteAna.nextNote && i + 1 < analysis.length) {
                    var nextAna = analysis[i + 1].noteAnalysis.find(function(n) {
                        return n.note === noteAna.nextNote;
                    });
                    noteAna.nextNoteAnalysis = nextAna;
                }
            });
        }
        
        // Pass 5: Identify NCT types
        for (var i = 0; i < analysis.length; i++) {
            analysis[i].noteAnalysis.forEach(function(noteAna) {
                if (!noteAna.isBass) {
                    noteAna.nctType = NCT.identifyNCTType(noteAna, analysis[i]);
                }
            });
        }
        
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
        var nctCounts = {
            "accented-passing": 0,
            "accented-neighbor": 0,
            "suspension": 0,
            "retardation": 0,
            "appoggiatura": 0
        };
        
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
            
            ana.noteAnalysis.forEach(function(noteAna) {
                if (nctCounts[noteAna.nctType] !== undefined) {
                    nctCounts[noteAna.nctType]++;
                }
            });
        });
        
        return { total: totalIntervals, perfect: perfectCount, nctCounts: nctCounts };
    }

    function addStatisticsFooter(analysis, lastStaff, bassOnsets) {
        var stats = calculateStatistics(analysis);
        var perfRatio = (stats.total > 0) ? Math.round((stats.perfect / stats.total) * 100) : 0;
        
        var cursor = curScore.newCursor();
        cursor.rewind(1); 
        cursor.staffIdx = lastStaff; 
        var footer = newElement(Element.STAFF_TEXT);
        footer.text = "--- SPECIES 4 ANALYSIS ---\n" +
                     "Bass Onsets: " + bassOnsets.length + " | Perfect: " + perfRatio + "%\n" +
                     "Suspensions: " + stats.nctCounts["suspension"] + 
                     " | Retardations: " + stats.nctCounts["retardation"] + "\n" +
                     "Acc. Passing: " + stats.nctCounts["accented-passing"] + 
                     " | Acc. Neighbor: " + stats.nctCounts["accented-neighbor"] + "\n" +
                     "Appoggiaturas: " + stats.nctCounts["appoggiatura"];
        footer.color = colorStats; 
        footer.placement = Placement.BELOW;
        cursor.add(footer);
    }

    onRun: {
        if (!curScore) { quit(); return; }
        curScore.startCmd("Species 4 Counterpoint Analysis");
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
        var firstChord = null;
        for (var i = 0; i < sortedTicks.length; i++) {
            var notesAtTick = tickGroups[sortedTicks[i]].sort(function(a,b) { return a.pitch - b.pitch; });
            if (notesAtTick.length >= 2) {
                firstChord = notesAtTick;
                break;
            }
        }
        if (!firstChord || firstChord.length < 2) { quit(); return; }
        
        var voices = firstChord.map(function(n) { return { staffIdx: n.staffIdx, voice: n.voice }; });
        var bassID = voices[0];
        var sopID = voices[voices.length - 1];
        
        // Determine tonic and bass onsets
        var tonicTPC = Harmony.determineTonic(sortedTicks, tickGroups, curScore, Element);
        var bassOnsets = Helpers.identifyBassOnsets(sortedTicks, tickGroups, bassID);

        // Analyze all ticks
        var analysis = createTickAnalysis(sortedTicks, tickGroups, bassOnsets, tonicTPC, bassID, sopID);

        // Check for errors
        for (var i = 0; i < analysis.length; i++) {
            var isFirst = (i === 0);
            var isLast = (i === analysis.length - 1);
            
            var nextBassOnsetIdx = -1;
            for (var j = i + 1; j < analysis.length; j++) {
                if (analysis[j].isBassOnset) {
                    nextBassOnsetIdx = j;
                    break;
                }
            }
            
            var errors = Errors.checkTickErrors(analysis[i], analysis, voices, bassID, sopID, isFirst, isLast, nextBassOnsetIdx);
            addErrorLabels(analysis[i].tick, errors);
        }

        // Add statistics
        addStatisticsFooter(analysis, lastStaff, bassOnsets);
        
        curScore.endCmd(); 
        quit();
    }
}