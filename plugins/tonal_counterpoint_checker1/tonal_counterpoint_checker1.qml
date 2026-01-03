import QtQuick
import MuseScore

MuseScore {
    title: "Tonal Counterpoint Species 1 Checker"
    description: "Checks two-part species counterpoint"
    version: "2.0"
    categoryCode: "Proofreading"
    requiresScore: true

    readonly property string colorError: "#b30000" 
    readonly property string colorDiss: "#6a1b9a"  
    readonly property string colorStats: "#004a99"   // Deep Blue (Professional and highly legible)

    readonly property var chordMap: {
        "I":     [0, 1, 4],      "III":   [4, 5, 8], 
        "IV":    [-1, 0, 3],     "V":     [1, 2, 5],  "VI":  [-4, -3, 0], "VII": [-2, -1, 1],
        "i":     [0, 1, -3],     "ii":    [2, 3, -1], "iii": [4, 5, 1], 
        "iv":    [-1, 0, -4],    "v":     [1, 2, -2], "vi":  [3, 4, 0],
        "iio":   [2, -4, -1],    "viio":  [-1, 2, 5],
        "I7":    [0, 1, 4, 5],   "III7":  [-3, -2, 1, 2],  "IV7":   [-1, 0, 3, 4], "VI7":   [-4, -3, 0, 1], "VII7": [-2, -1, 2, 3],
        "i7":    [0, 1, -3, -2], "ii7":   [2, 3, -1, 0], "iii7":  [4, 5, 1, 2],  "iv7":   [-1, 0, -4, -3], "vi7":   [3, 4, 0, 1],
        "V7":    [1, 2, 5, -1],  "viio7": [2, -1, 5, -4], "vii07": [2, -1, 5, 3],  "ii07":  [2, -4, -1, 0],
        "It6":    [0, 0, 6, -4],  "Fr65":    [0, 2, 6, -4],   "Ger65":   [0, -3, 6, -4], "N6":     [-5, -4, -1],
        "It":    [0, 0, 6, -4],  "Fr":    [0, 2, 6, -4],   "Ger":   [0, -3, 6, -4], "N":     [-5, -4, -1],   "CAD":   [0, 1, 4]
    }

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
        if (!sourceNote) return null;
        for (var i = 0; i < nextTickNotes.length; i++) {
            if (nextTickNotes[i].staffIdx === sourceNote.staffIdx && nextTickNotes[i].voice === sourceNote.voice) return nextTickNotes[i];
        }
        return null;
    }

    function getChordData(rn, tonicTPC) {
        if (!rn || rn === "") return { tones: [], tendTones: [null, null] };

        // 1. Clean the input and separate the base from the figures
        var lookup = rn.split('/')[0].replace("ø", "0");
        var isSeventh = lookup.match(/7|65|43|42/) !== null;
        var baseRN = lookup.replace(/[765432]/g, ''); // e.g., "V65" becomes "V"
        
        // 2. Determine the search key for chordMap
        var searchKey = lookup;
        if (!chordMap[searchKey]) {
            searchKey = isSeventh ? baseRN + "7" : baseRN;
        }

        var offsets = chordMap[searchKey];
        if (!offsets) return { tones: [], tendTones: [null, null] };
        
        var tones = offsets.map(o => tonicTPC + o);
        var tendTones = [null, null];

        // 3. CORRECT TENDENCY TONE LOGIC
        // We only care about the base identity of the chord
        if (baseRN === "V" || baseRN === "viio" || baseRN === "vii0") {
            // Leading tone is the 3rd of the chord (index 2 in your chordMap)
            tendTones[0] = tones[2]; 
            
            // Chordal 7th (index 3) only exists if it's a 4-note chord
            if (tones.length === 4) {
                tendTones[1] = tones[3]; 
            }
        } 
        // Augmented 6th chords (It, Fr, Ger)
        else if (baseRN.match(/^(It|Fr|Ger)$/i)) {
            tendTones[0] = tones[2]; // #4
            tendTones[1] = tones[3]; // b6
        }

        return { tones: tones, tendTones: tendTones };
    }

    onRun: {
        if (!curScore) { quit(); return; }
        curScore.startCmd("Expert Tonal Analysis");
        if (curScore.selection.elements.length === 0) { cmd("select-all"); }

        var tickGroups = {};
        curScore.selection.elements.forEach(el => {
            if (el && el.type === Element.NOTE && el.parent && el.parent.parent) {
                var tick = el.parent.parent.tick;
                if (!tickGroups[tick]) tickGroups[tick] = [];
                tickGroups[tick].push(el);
            }
        });

        // NEW: Find the lowest staff in the selection
        var lastStaff = curScore.selection.startStaff;
        if (curScore.selection.endStaff > lastStaff) {
            lastStaff = curScore.selection.endStaff - 1; 
        }

        var sortedTicks = Object.keys(tickGroups).map(Number).sort((a,b)=>a-b);
        if (sortedTicks.length === 0) { quit(); return; }

        var tonicTPC = 14; // fall back to C Major
        sortedTicks.forEach(t => {
            var cursor = curScore.newCursor(); cursor.rewindToTick(t);
            if (cursor.segment && cursor.segment.annotations) {
                cursor.segment.annotations.forEach(ann => {
                    if (ann.type === Element.HARMONY && ann.text.match(/^V7?$/)) {
                        var chordNotes = tickGroups[t].sort((a,b)=>a.pitch-b.pitch);
                        if (chordNotes.length > 0) tonicTPC = chordNotes[0].tpc - 1; // Find a root position V or V7 to determine tonic
                    }
                });
            }
        });

        var firstChord = tickGroups[sortedTicks[0]].sort((a,b)=>a.pitch-b.pitch);
        var voices = firstChord.map(n => ({ staffIdx: n.staffIdx, voice: n.voice }));
        var bassID = voices[0];
        var sopID = voices[voices.length - 1];
        var consecutive3rds = 0;
        var consecutive6ths = 0;

        for (var j = 0; j < sortedTicks.length; j++) {
            var tick = sortedTicks[j];
            var notes = tickGroups[tick];
            var nextNotes = (j + 1 < sortedTicks.length) ? tickGroups[sortedTicks[j+1]] : null;

            var rn = "";
            var cursor = curScore.newCursor(); cursor.rewindToTick(tick);
            if (cursor.segment) {
                cursor.segment.annotations.forEach(ann => {
                    if (ann.type === Element.HARMONY) rn = ann.text;
                });
            }

            var hData = getChordData(rn, tonicTPC);
            var errors = [];

            // 1. VOICE CROSSING
            if (voices.length > 1) {
                for (var v = 0; v < voices.length - 1; v++) {
                    var lowV = voices[v], highV = voices[v+1];
                    var ln = null, hn = null;
                    notes.forEach(n => {
                        if (n.staffIdx === lowV.staffIdx && n.voice === lowV.voice) ln = n;
                        if (n.staffIdx === highV.staffIdx && n.voice === highV.voice) hn = n;
                    });
                    if (ln && hn && ln.pitch > hn.pitch) {
                        errors.push("Voice Crossing");
                        ln.color = colorError; hn.color = colorError;
                    }
                }
            }

            // 2. TENDENCY & CHORD TONES
            notes.forEach(note => {
                if (rn !== "" && hData.tones.indexOf(note.tpc) === -1) {
                    errors.push("Non-Chord (" + tpcToName(note.tpc) + ")");
                    note.color = colorDiss;
                }
                var isB = (note.staffIdx === bassID.staffIdx && note.voice === bassID.voice);
                if (!isB && nextNotes) {
                    var nN = findNoteInSameVoice(note, nextNotes);
                    if (nN) {
                        var dist = nN.pitch - note.pitch;
                        if (hData.tendTones[0] === note.tpc && (dist < 1 || dist > 2)) {
                            errors.push(tpcToName(note.tpc) + " should\nresolve UP");
                            note.color = colorError; // Highlight the tendency tone itself
                        }
                        if (hData.tendTones[1] === note.tpc && (dist > -1 || dist < -2)) {
                            errors.push(tpcToName(note.tpc) + " should\nresolve DOWN");
                            note.color = colorError; // Highlight the tendency tone itself
                        }
                    }
                }
            });

            // 3. PARALLELS & DIRECTS
            if (nextNotes) {
                for (var x = 0; x < notes.length; x++) {
                    for (var y = x + 1; y < notes.length; y++) {
                        var n1 = notes[x], n2 = notes[y];
                        var nN1 = findNoteInSameVoice(n1, nextNotes), nN2 = findNoteInSameVoice(n2, nextNotes);
                        if (nN1 && nN2) {
                            var lC = (n1.pitch < n2.pitch) ? n1 : n2, hC = (n1.pitch < n2.pitch) ? n2 : n1;
                            var lN = (nN1.pitch < nN2.pitch) ? nN1 : nN2, hN = (nN1.pitch < nN2.pitch) ? nN2 : nN1;
                            var cT = getIntervalType(lC, hC), nT = getIntervalType(lN, hN);
                            
                            // Parallels: Highlight ALL FOUR notes
                            if (cT && cT === nT && (nN1.pitch !== n1.pitch)) {
                                errors.push("Parallel " + nT);
                                lC.color = colorError; hC.color = colorError;
                                lN.color = colorError; hN.color = colorError;
                            }
                            
                            // Directs: Highlight only the leaping Soprano arrival
                            var isBass = (lC.staffIdx === bassID.staffIdx && lC.voice === bassID.voice);
                            var isSop = (hC.staffIdx === sopID.staffIdx && hC.voice === sopID.voice);
                            if (isBass && isSop && nT && !cT) {
                                var bM = lN.pitch - lC.pitch, sM = hN.pitch - hC.pitch;
                                if ((bM * sM > 0) && Math.abs(sM) > 2) {
                                    errors.push("Direct " + nT);
                                    hN.color = colorError; 
                                }
                            }
                        }
                    }
                }
            }

            if (errors.length > 0) {
                var outCursor = curScore.newCursor(); outCursor.rewindToTick(tick);
                var text = newElement(Element.STAFF_TEXT);
                text.text = [...new Set(errors)].join("\n");
                text.color = colorError;
                outCursor.add(text);
            }
        }

        cursor.rewind(1); 
        cursor.staffIdx = lastStaff; 

        // 2. Precisely align with the first tick of the analysis
        if (sortedTicks.length > 0) {
            while (cursor.segment && cursor.tick < sortedTicks[0]) {
                cursor.next();
            }
        }
        
        // --- FINAL STATISTICS CALCULATIONS ---
        var totalIntervalsChecked = 0;
        var totalPerfectCount = 0;
        for (var i = 0; i < sortedTicks.length; i++) {
            var tick = sortedTicks[i];
            var notesAtTick = tickGroups[tick];

            // We need at least two notes to form an interval
            if (notesAtTick && notesAtTick.length > 1) {
                // Compare every note against every other note in the vertical slice
                for (var x = 0; x < notesAtTick.length; x++) {
                    for (var y = x + 1; y < notesAtTick.length; y++) {
                        var n1 = notesAtTick[x];
                        var n2 = notesAtTick[y];

                        // Sort by pitch to ensure we always pass (bass, soprano) to getIntervalType
                        var lowNote = (n1.pitch < n2.pitch) ? n1 : n2;
                        var highNote = (n1.pitch < n2.pitch) ? n2 : n1;

                        // 1. Increment total interval count
                        totalIntervalsChecked++;

                        // 2. Check for perfect intervals (P5/P8)
                        if (getIntervalType(lowNote, highNote)) {
                            totalPerfectCount++;
                        }
                    }
                }
            }
        }

        var footer = newElement(Element.STAFF_TEXT);
        var perfRatio = Math.round((totalPerfectCount / totalIntervalsChecked) * 100);
        footer.text = "--- ANALYSIS ---\nIntervals: " + totalIntervalsChecked + " | Perfect: " + perfRatio + "%";
        footer.color = colorStats;
        footer.placement = Placement.BELOW;
        footer.offsetX = -5;
        cursor.add(footer);

        curScore.endCmd(); quit();
    }
}