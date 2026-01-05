import QtQuick
import MuseScore

MuseScore {
    title: "Tonal Counterpoint Species 2 Checker"
    description: "Checks two-part species 2 counterpoint with passing tones only"
    version: "1.0"
    categoryCode: "Proofreading"
    requiresScore: true

    readonly property string colorError: "#b30000" 
    readonly property string colorDiss: "#6a1b9a"  
    readonly property string colorStats: "#004a99"
    readonly property string colorPattern: "#2e7d32"

    readonly property var chordMap: {
        "I":      [0, 1, 4],      "III":   [4, 5, 8], 
        "IV":     [-1, 0, 3],     "V":     [1, 2, 5],  "VI":  [-4, -3, 0], "VII": [-2, -1, 1],
        "i":      [0, 1, -3],     "ii":    [2, 3, -1], "iii": [4, 5, 1], 
        "iv":     [-1, 0, -4],    "v":     [1, 2, -2], "vi":  [3, 4, 0],
        "iio":    [2, -4, -1],    "viio":  [-1, 2, 5],
        "I7":     [0, 1, 4, 5],   "III7":  [-3, -2, 1, 2],  "IV7":   [-1, 0, 3, 4], "VI7":   [-4, -3, 0, 1], "VII7": [-2, -1, 2, 3],
        "i7":     [0, 1, -3, -2], "ii7":   [2, 3, -1, 0], "iii7":  [4, 5, 1, 2],  "iv7":   [-1, 0, -4, -3], "vi7":   [3, 4, 0, 1],
        "V7":     [1, 2, 5, -1],  "viio7": [2, -1, 5, -4], "vii07": [2, -1, 5, 3],  "ii07":  [2, -4, -1, 0],
        "It6":    [0, 0, 6, -4],  "Fr65":    [0, 2, 6, -4],   "Ger65":   [0, -3, 6, -4], "N6":     [-5, -4, -1],
        "It":     [0, 0, 6, -4],  "Fr":    [0, 2, 6, -4],   "Ger":   [0, -3, 6, -4], "N":     [-5, -4, -1], "Cad": [1, 0, 4]
    }

    // --- HELPER FUNCTIONS ---

    function tpcToName(tpc) {
        var names = {6:"Abb", 7:"Ebb", 8:"Gb", 9:"Db", 10:"Ab", 11:"Eb", 12:"Bb", 13:"F", 14:"C", 15:"G", 16:"D", 17:"A", 18:"E", 19:"B", 20:"F#", 21:"C#", 22:"G#", 23:"D#", 24:"A#", 25:"E#", 26:"B#", 27:"Fx", 28:"Cx", 29:"Gx", 30:"Dx", 31:"Ax"};
        return names[tpc] || ("TPC:" + tpc);
    }

    function getIntervalType(bass, sop) {
        if (!bass || !sop) return null;
        var tpcDist = sop.tpc - bass.tpc;
        var semitones = Math.abs(sop.pitch - bass.pitch) % 12;
        if (tpcDist === 0 && semitones === 0) return "P8";
        if (tpcDist === 1 && semitones === 7) return "P5";
        return null;
    }

    function findNoteInSameVoice(sourceNote, nextTickNotes) {
        if (!sourceNote || !nextTickNotes) return null;
        for (var i = 0; i < nextTickNotes.length; i++) {
            if (nextTickNotes[i].staffIdx === sourceNote.staffIdx && nextTickNotes[i].voice === sourceNote.voice) 
                return nextTickNotes[i];
        }
        return null;
    }

    function isStep(tpcDist) {
        var abs = Math.abs(tpcDist);
        return abs === 2 || abs === 5;
    }

    function getChordData(rn, tonicTPC) {
        if (!rn || rn === "") return { tones: [], tendTones: [null, null] };

        var parts = rn.split('/');
        var primaryPart = parts[0].replace("ø", "0");
        var targetPart = parts.length > 1 ? parts[1].replace("ø", "0") : null;

        var localTonic = tonicTPC; 
        if (targetPart) {
            var targetData = getChordData(targetPart, tonicTPC);
            if (targetData.tones.length > 0) {
                if (targetPart.toLowerCase().indexOf("viio") !== -1 || targetPart.toLowerCase().indexOf("vii0") !== -1) {
                    localTonic = targetData.tones[2];
                } else if (targetPart.match(/^(It|Fr|Ger)/i)) {
                    localTonic = targetData.tones[3];
                } else {
                    localTonic = targetData.tones[0];
                }
            }
        }

        var lookup = primaryPart;
        var isSeventh = lookup.match(/7|65|43|42/) !== null;
        var baseRN = lookup.replace(/[765432]/g, ''); 
        var searchKey = lookup;

        if (!chordMap[searchKey]) {
            if (isSeventh && chordMap[baseRN + "7"]) {
                searchKey = baseRN + "7";
            } else if (chordMap[baseRN]) {
                searchKey = baseRN;
            } else {
                var capitalized = baseRN.charAt(0).toUpperCase() + baseRN.slice(1);
                searchKey = chordMap[capitalized] ? capitalized : null;
            }
        }

        var offsets = chordMap[searchKey];
        if (!offsets) return { tones: [], tendTones: [null, null] };
        
        var tones = offsets.map(o => localTonic + o);
        var tendTones = [null, null];
        var upperBase = baseRN.toUpperCase();

        if (upperBase === "V" || upperBase === "VIIO" || upperBase === "VII0") {
            tendTones[0] = tones[2]; 
            if (tones.length === 4) tendTones[1] = tones[3]; 
        } 
        return { tones: tones, tendTones: tendTones };
    }

    // --- ANALYSIS FUNCTIONS ---

    function identifyBassOnsets(sortedTicks, tickGroups, bassID) {
        var bassOnsets = [];
        var lastBassNote = null;
        
        for (var i = 0; i < sortedTicks.length; i++) {
            var bassNote = tickGroups[sortedTicks[i]].find(n => n.staffIdx === bassID.staffIdx && n.voice === bassID.voice);
            if (bassNote && (!lastBassNote || bassNote.pitch !== lastBassNote.pitch || bassNote.tpc !== lastBassNote.tpc)) {
                bassOnsets.push(sortedTicks[i]);
                lastBassNote = bassNote;
            }
        }
        return bassOnsets;
    }

    function getCurrentHarmonyContext(tick, bassOnsets, tickGroups, tonicTPC) {
        var contextTick = null;
        for (var i = bassOnsets.length - 1; i >= 0; i--) {
            if (bassOnsets[i] <= tick) {
                contextTick = bassOnsets[i];
                break;
            }
        }
        if (contextTick === null) return { rn: "", hData: getChordData("", tonicTPC) };
        
        var cursor = curScore.newCursor(); 
        cursor.rewindToTick(contextTick);
        var rn = "";
        if (cursor.segment) {
            cursor.segment.annotations.forEach(ann => {
                if (ann.type === Element.HARMONY) rn = ann.text;
            });
        }
        return { rn: rn, hData: getChordData(rn, tonicTPC) };
    }

    function determineTonic(sortedTicks, tickGroups) {
        var tpc = 14; // Default to C
        sortedTicks.forEach(t => {
            var cursor = curScore.newCursor(); 
            cursor.rewindToTick(t);
            if (cursor.segment && cursor.segment.annotations) {
                cursor.segment.annotations.forEach(ann => {
                    if (ann.type === Element.HARMONY && ann.text.match(/^V7?$/)) {
                        var chordNotes = tickGroups[t].sort((a,b) => a.pitch - b.pitch);
                        if (chordNotes.length > 0) tpc = chordNotes[0].tpc - 1; 
                    }
                });
            }
        });
        return tpc;
    }

    // --- TICK ANALYSIS OBJECT CREATION ---

    function analyzeNoteAtTick(note, tickIdx, analysis, bassID, sopID) {
        var ana = analysis[tickIdx];
        var isBass = (note.staffIdx === bassID.staffIdx && note.voice === bassID.voice);
        
        return {
            note: note,
            isBass: isBass,
            isChordTone: ana.hData.tones.indexOf(note.tpc) !== -1,
            isTendency0: ana.hData.tendTones[0] === note.tpc,
            isTendency1: ana.hData.tendTones[1] === note.tpc,
            prevNote: (tickIdx > 0) ? findNoteInSameVoice(note, analysis[tickIdx - 1].notes) : null,
            nextNote: (tickIdx < analysis.length - 1) ? findNoteInSameVoice(note, analysis[tickIdx + 1].notes) : null,
            nextBassOnsetNote: null // Will be filled in second pass
        };
    }

    function createTickAnalysis(sortedTicks, tickGroups, bassOnsets, tonicTPC, bassID, sopID) {
        var analysis = [];
        
        // First pass: basic analysis
        for (var i = 0; i < sortedTicks.length; i++) {
            var tick = sortedTicks[i];
            var notes = tickGroups[tick];
            var isBassOnset = (bassOnsets.indexOf(tick) !== -1);
            var context = getCurrentHarmonyContext(tick, bassOnsets, tickGroups, tonicTPC);
            
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
        
        // Second pass: analyze each note and find next bass onset
        for (var i = 0; i < analysis.length; i++) {
            var ana = analysis[i];
            
            // Analyze each note
            ana.notes.forEach(function(note) {
                ana.noteAnalysis.push(analyzeNoteAtTick(note, i, analysis, bassID, sopID));
            });
            
            // Find next bass onset for each note
            var nextBassOnsetIdx = i + 1;
            while (nextBassOnsetIdx < analysis.length && !analysis[nextBassOnsetIdx].isBassOnset) {
                nextBassOnsetIdx++;
            }
            if (nextBassOnsetIdx < analysis.length) {
                ana.noteAnalysis.forEach(function(noteAna) {
                    noteAna.nextBassOnsetNote = findNoteInSameVoice(noteAna.note, analysis[nextBassOnsetIdx].notes);
                });
            }
        }
        
        return analysis;
    }

    // --- ERROR CHECKING FUNCTIONS ---

    function checkVoiceCrossing(ana, voices) {
        var errors = [];
        for (var v = 0; v < voices.length - 1; v++) {
            var lowNote = ana.notes.find(n => n.staffIdx === voices[v].staffIdx && n.voice === voices[v].voice);
            var highNote = ana.notes.find(n => n.staffIdx === voices[v+1].staffIdx && n.voice === voices[v+1].voice);
            
            if (lowNote && highNote && lowNote.pitch > highNote.pitch) {
                errors.push("Voice Crossing");
                lowNote.color = colorError; 
                highNote.color = colorError;
            }
        }
        return errors;
    }

    function checkDoubledTendency(ana, bassID) {
        var errors = [];
        if (!ana.isBassOnset) return errors;
        
        var bassNoteAna = ana.noteAnalysis.find(n => n.isBass);
        if (!bassNoteAna) return errors;
        
        var otherWithSameTPC = ana.noteAnalysis.filter(n => !n.isBass && n.note.tpc === bassNoteAna.note.tpc);
        if (otherWithSameTPC.length > 0 && (bassNoteAna.isTendency0 || bassNoteAna.isTendency1)) {
            errors.push("Doubled\nTendency Tone");
            otherWithSameTPC.forEach(n => n.note.color = colorError);
        }
        return errors;
    }

    function checkRepeatedNote(noteAna) {
        if (noteAna.nextNote && noteAna.nextNote.pitch === noteAna.note.pitch && 
            noteAna.nextNote.tpc === noteAna.note.tpc) {
            noteAna.note.color = colorError;
            noteAna.nextNote.color = colorError;
            return ["Repeated\nMelody Note"];
        }
        return [];
    }

    function checkTendencyResolution(noteAna) {
        if (!noteAna.nextBassOnsetNote) return [];
        var dist = noteAna.nextBassOnsetNote.pitch - noteAna.note.pitch;
        
        if (noteAna.isTendency0 && (dist < 1 || dist > 2)) {
            noteAna.note.color = colorError;
            return [tpcToName(noteAna.note.tpc) + " should\nstep UP"];
        }
        if (noteAna.isTendency1 && (dist > -1 || dist < -2)) {
            noteAna.note.color = colorError;
            return [tpcToName(noteAna.note.tpc) + " should\nstep DOWN"];
        }
        return [];
    }

    function checkInvalidNCT(noteAna, ana) {
        if (noteAna.isBass || !ana.isBassOnset || ana.rn === "") return [];
        if (noteAna.isChordTone) return [];
        
        noteAna.note.color = colorError;
        return ["Invalid\nNCT"];
    }

    function isPassingTone(noteAna, hData) {
        if (!noteAna.prevNote || !noteAna.nextNote) return false;
        if (hData.tones.indexOf(noteAna.note.tpc) !== -1) return true;
        
        var stepToPrev = Math.abs(noteAna.note.pitch - noteAna.prevNote.pitch);
        var stepToNext = Math.abs(noteAna.note.pitch - noteAna.nextNote.pitch);
        if (stepToPrev > 2 || stepToNext > 2) return false;
        
        var dirToPrev = noteAna.note.pitch - noteAna.prevNote.pitch;
        var dirToNext = noteAna.nextNote.pitch - noteAna.note.pitch;
        
        // SPECIES 2: Only passing tones (same direction), NO neighbor tones
        return dirToPrev * dirToNext > 0;
    }

    function checkNonChordTone(noteAna, ana) {
        if (noteAna.isBass || noteAna.isChordTone) return [];
        
        var isPassingNCT = isPassingTone(noteAna, ana.hData);
        
        if (!isPassingNCT) {
            noteAna.note.color = colorError;
            return ["Invalid\nNCT"];
        }
        
        return [];
    }

    function checkMelodicInterval(noteAna) {
        if (!noteAna.nextBassOnsetNote) return null;
        var tpcDist = noteAna.nextBassOnsetNote.tpc - noteAna.note.tpc;
        if (Math.abs(tpcDist) >= 6) {
            var qual = (tpcDist >= 6) ? "Aug." : "Dim.";
            noteAna.note.color = colorError;
            noteAna.nextBassOnsetNote.color = colorError;
            return qual;
        }
        return null;
    }

    function checkParallelPerfects(noteAna1, noteAna2) {
        if (!noteAna1.nextBassOnsetNote || !noteAna2.nextBassOnsetNote) return null;
        
        var n1 = noteAna1.note, n2 = noteAna2.note;
        var nN1 = noteAna1.nextBassOnsetNote, nN2 = noteAna2.nextBassOnsetNote;
        
        var lC = (n1.pitch < n2.pitch) ? n1 : n2; 
        var hC = (n1.pitch < n2.pitch) ? n2 : n1;
        var lN = (nN1.pitch < nN2.pitch) ? nN1 : nN2; 
        var hN = (nN1.pitch < nN2.pitch) ? nN2 : nN1;
        
        var cT = getIntervalType(lC, hC);
        var nT = getIntervalType(lN, hN);
        
        if (cT && cT === nT && nN1.pitch !== n1.pitch) {
            lC.color = colorError; hC.color = colorError;
            lN.color = colorError; hN.color = colorError;
            return "Parallel " + nT;
        }
        return null;
    }

    function checkDirectPerfect(noteAna1, noteAna2, bassID, sopID) {
        if (!noteAna1.nextBassOnsetNote || !noteAna2.nextBassOnsetNote) return null;
        
        var n1 = noteAna1.note, n2 = noteAna2.note;
        var nN1 = noteAna1.nextBassOnsetNote, nN2 = noteAna2.nextBassOnsetNote;
        
        var lC = (n1.pitch < n2.pitch) ? n1 : n2; 
        var hC = (n1.pitch < n2.pitch) ? n2 : n1;
        var lN = (nN1.pitch < nN2.pitch) ? nN1 : nN2; 
        var hN = (nN1.pitch < nN2.pitch) ? nN2 : nN1;
        
        var isBass = (lC.staffIdx === bassID.staffIdx && lC.voice === bassID.voice);
        var isSop = (hC.staffIdx === sopID.staffIdx && hC.voice === sopID.voice);
        var cT = getIntervalType(lC, hC);
        var nT = getIntervalType(lN, hN);
        
        if (isBass && isSop && nT && !cT) {
            var bM = lN.pitch - lC.pitch;
            var sM = hN.pitch - hC.pitch;
            if ((bM * sM > 0) && Math.abs(sM) > 2) {
                hN.color = colorError; 
                return "Direct " + nT;
            }
        }
        return null;
    }

    function checkFirstMelodyNote(ana, bassID) {
        var errors = [];
        var melodyNotes = ana.noteAnalysis.filter(function(n) { return !n.isBass; });
        
        if (melodyNotes.length > 0) {
            var firstMelodyNote = melodyNotes[0];
            if (!firstMelodyNote.isChordTone) {
                errors.push("First melody\nnote must be CT");
                firstMelodyNote.note.color = colorError;
            }
        }
        return errors;
    }

    function checkLastNote(ana, bassID) {
        var errors = [];
        
        if (!ana.isBassOnset) {
            errors.push("Last note must\nbe bass onset");
            ana.notes.forEach(function(n) { n.color = colorError; });
            return errors;
        }
        
        ana.noteAnalysis.forEach(function(noteAna) {
            if (!noteAna.isBass && !noteAna.isChordTone) {
                errors.push("Last note must\nbe chord tone");
                noteAna.note.color = colorError;
            }
        });
        
        return errors;
    }

    function checkTickErrors(ana, voices, bassID, sopID, isFirst, isLast) {
        var errors = [];
        
        // First melody note check
        if (isFirst) {
            errors = errors.concat(checkFirstMelodyNote(ana, bassID));
        }
        
        // Last note check
        if (isLast) {
            errors = errors.concat(checkLastNote(ana, bassID));
        }
        
        // Voice crossing
        errors = errors.concat(checkVoiceCrossing(ana, voices));
        
        // Doubled tendency tones
        errors = errors.concat(checkDoubledTendency(ana, bassID));
        
        // Check each note
        ana.noteAnalysis.forEach(function(noteAna) {
            if (noteAna.isBass) return;
            
            // Invalid NCT on bass onset
            errors = errors.concat(checkInvalidNCT(noteAna, ana));
            
            // Repeated notes
            errors = errors.concat(checkRepeatedNote(noteAna));
            
            // Tendency resolution
            errors = errors.concat(checkTendencyResolution(noteAna));
            
            // NCT validation (passing tones only)
            errors = errors.concat(checkNonChordTone(noteAna, ana));
        });
        
        // Voice leading checks between note pairs
        for (var x = 0; x < ana.noteAnalysis.length; x++) {
            for (var y = x + 1; y < ana.noteAnalysis.length; y++) {
                var noteAna1 = ana.noteAnalysis[x];
                var noteAna2 = ana.noteAnalysis[y];
                
                // Melodic intervals
                var mel1 = checkMelodicInterval(noteAna1);
                var mel2 = checkMelodicInterval(noteAna2);
                if (mel1) errors.push("Melodic " + mel1);
                if (mel2) errors.push("Melodic " + mel2);
                
                // Parallel perfects
                var parallel = checkParallelPerfects(noteAna1, noteAna2);
                if (parallel) errors.push(parallel);
                
                // Direct perfects
                var direct = checkDirectPerfect(noteAna1, noteAna2, bassID, sopID);
                if (direct) errors.push(direct);
            }
        }
        
        return errors;
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
                        if (getIntervalType(low, high)) perfectCount++;
                    }
                }
            }
        });
        return { total: totalIntervals, perfect: perfectCount };
    }

    function addStatisticsFooter(analysis, lastStaff, bassOnsets) {
        var stats = calculateStatistics(analysis);
        var perfRatio = (stats.total > 0) ? Math.round((stats.perfect / stats.total) * 100) : 0;
        
        var cursor = curScore.newCursor();
        cursor.rewind(1); 
        cursor.staffIdx = lastStaff; 
        var footer = newElement(Element.STAFF_TEXT);
        footer.text = "--- SPECIES 2 ANALYSIS ---\nBass Onsets: " + bassOnsets.length + 
                     " | Perfect: " + perfRatio + "%";
        footer.color = colorStats; 
        footer.placement = Placement.BELOW;
        cursor.add(footer);
    }

    // --- MAIN RUN ---

    onRun: {
        if (!curScore) { quit(); return; }
        curScore.startCmd("Species 2 Counterpoint Analysis");
        if (curScore.selection.elements.length === 0) { cmd("select-all"); }

        // Collect notes by tick
        var tickGroups = {};
        curScore.selection.elements.forEach(el => {
            if (el && el.type === Element.NOTE && el.parent && el.parent.parent) {
                var tick = el.parent.parent.tick;
                if (!tickGroups[tick]) tickGroups[tick] = [];
                tickGroups[tick].push(el);
            }
        });

        // Setup
        var lastStaff = curScore.selection.endStaff > curScore.selection.startStaff ? 
                       curScore.selection.endStaff - 1 : curScore.selection.startStaff;
        var sortedTicks = Object.keys(tickGroups).map(Number).sort((a,b) => a - b);
        if (sortedTicks.length === 0) { quit(); return; }

        var tonicTPC = determineTonic(sortedTicks, tickGroups);
        var firstChord = tickGroups[sortedTicks[0]].sort((a,b) => a.pitch - b.pitch);
        var voices = firstChord.map(n => ({ staffIdx: n.staffIdx, voice: n.voice }));
        var bassID = voices[0];
        var sopID = voices[voices.length - 1];
        var bassOnsets = identifyBassOnsets(sortedTicks, tickGroups, bassID);

        // PHASE 1: Analyze all ticks and create analysis objects
        var analysis = createTickAnalysis(sortedTicks, tickGroups, bassOnsets, tonicTPC, bassID, sopID);

        // PHASE 2: Check for errors using the analysis
        for (var i = 0; i < analysis.length; i++) {
            var isFirst = (i === 0);
            var isLast = (i === analysis.length - 1);
            var errors = checkTickErrors(analysis[i], voices, bassID, sopID, isFirst, isLast);
            addErrorLabels(analysis[i].tick, errors);
        }

        // PHASE 3: Add statistics footer
        addStatisticsFooter(analysis, lastStaff, bassOnsets);
        
        curScore.endCmd(); 
        quit();
    }
}