import QtQuick
import MuseScore

MuseScore {
    title: "Tonal Counterpoint Species 2 Checker"
    description: "Checks Species 2 (Passing Tones & Chord Skips)"
    version: "3.0"
    categoryCode: "Proofreading"
    requiresScore: true

    readonly property string colorError: "#b30000" 
    readonly property string colorDiss: "#6a1b9a"  
    readonly property string colorStats: "#004a99"

    readonly property var chordMap: {
        "I":     [0, 1, 4],      "III":   [4, 5, 8], 
        "IV":    [-1, 0, 3],     "V":     [1, 2, 5],  "VI":  [-4, -3, 0], "VII": [-2, -1, 1],
        "i":     [0, 1, -3],     "ii":    [2, 3, -1], "iii": [4, 5, 1], 
        "iv":    [-1, 0, -4],    "v":     [1, 2, -2], "vi":  [3, 4, 0],
        "iio":   [2, -4, -1],    "viio":  [-1, 2, 5],
        "I7":    [0, 1, 4, 5],   "III7":  [-3, -2, 1, 2],  "IV7":   [-1, 0, 3, 4], "VI7":   [-4, -3, 0, 1], "VII7": [-2, -1, 2, 3],
        "i7":    [0, 1, -3, -2], "ii7":   [2, 3, -1, 0], "iii7":  [4, 5, 1, 2],  "iv7":   [-1, 0, -4, -3], "vi7":   [3, 4, 0, 1],
        "V7":    [1, 2, 5, -1],  "viio7": [2, -1, 5, -4], "vii07": [2, -1, 5, 3],  "ii07":  [2, -4, -1, 0],
        "It6":   [0, 0, 6, -4],  "Fr65":    [0, 2, 6, -4],   "Ger65":   [0, -3, 6, -4], "N6":     [-5, -4, -1],
        "It":    [0, 0, 6, -4],  "Fr":    [0, 2, 6, -4],   "Ger":   [0, -3, 6, -4], "N":     [-5, -4, -1],   "CAD":   [0, 1, 4]
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
            if (nextTickNotes[i].staffIdx === sourceNote.staffIdx && nextTickNotes[i].voice === sourceNote.voice) return nextTickNotes[i];
        }
        return null;
    }

    function getChordData(rn, tonicTPC) {
        if (!rn || rn === "") return { tones: [], tendTones: [null, null] };
        var lookup = rn.split('/')[0].replace("ø", "0");
        var isSeventh = lookup.match(/7|65|43|42/) !== null;
        var baseRN = lookup.replace(/[765432]/g, '');
        var searchKey = lookup;
        if (!chordMap[searchKey]) searchKey = isSeventh ? baseRN + "7" : baseRN;
        var offsets = chordMap[searchKey];
        if (!offsets) return { tones: [], tendTones: [null, null] };
        var tones = offsets.map(o => tonicTPC + o);
        var tendTones = [null, null];
        if (baseRN === "V" || baseRN === "viio" || baseRN === "vii0") {
            tendTones[0] = tones[2]; 
            if (tones.length === 4) tendTones[1] = tones[3]; 
        } 
        else if (baseRN.match(/^(It|Fr|Ger)$/i)) {
            tendTones[0] = tones[2]; tendTones[1] = tones[3];
        }
        return { tones: tones, tendTones: tendTones };
    }

    function determineTonic(sortedTicks, tickGroups) {
        var tpc = 14; 
        sortedTicks.forEach(t => {
            var cursor = curScore.newCursor(); cursor.rewindToTick(t);
            if (cursor.segment && cursor.segment.annotations) {
                cursor.segment.annotations.forEach(ann => {
                    if (ann.type === Element.HARMONY && ann.text.match(/^V7?$/)) {
                        var chordNotes = tickGroups[t].sort((a,b)=>a.pitch-b.pitch);
                        if (chordNotes.length > 0) tpc = chordNotes[0].tpc - 1; 
                    }
                });
            }
        });
        return tpc;
    }

    // --- CHECK LOGIC METHODS ---

    // TYPE 1: Bass Onset Checks (Strict Consonance / Chord Tones)
    function checkBassOnset(notes, hData) {
        var errors = [];
        notes.forEach(note => {
            // In Species 1/Downbeats, we expect Chord Tones
            if (hData.tones.length > 0 && hData.tones.indexOf(note.tpc) === -1) {
                errors.push("Non-Chord (" + tpcToName(note.tpc) + ")");
                note.color = colorDiss;
            }
        });
        return errors;
    }

    // TYPE 2 & 3: Interior Note Checks (Interval vs Bass, Motion Type)
    function checkMelodicFunction(prevNote, currNote, nextNote, hData, activeBass) {
        var errors = [];
        
        // A. Identify Interval against Sustained Bass
        // (You can expand this to log the interval or flag dissonances if desired)
        // var intervalType = getIntervalType(activeBass, currNote);

        // B. Analyze Motion (Chord Tone vs Passing Tone)
        var isChordTone = hData.tones.indexOf(currNote.tpc) !== -1;

        if (isChordTone) {
            // Valid Chord Skip / Arpeggiation -> OK
            return errors; 
        }

        // If not a Chord Tone, it MUST be a Passing Tone
        var isPassing = false;
        if (prevNote && nextNote) {
            var approachInterval = currNote.pitch - prevNote.pitch;
            var departureInterval = nextNote.pitch - currNote.pitch;
            
            // Check for Steps (semitone dist 1 or 2)
            var approachIsStep = Math.abs(approachInterval) >= 1 && Math.abs(approachInterval) <= 2;
            var departureIsStep = Math.abs(departureInterval) >= 1 && Math.abs(departureInterval) <= 2;
            
            // Check Direction (must continue same way)
            var sameDirection = (approachInterval * departureInterval) > 0;

            if (approachIsStep && departureIsStep && sameDirection) {
                isPassing = true;
            }
        }

        if (!isPassing) {
            // Note is neither a Chord Tone nor a Valid Passing Tone
            errors.push("Invalid Motion\n(Must be PT or CT)");
            currNote.color = colorError;
        } else {
            // Optional: Mark passing tones visually for debug?
            // currNote.color = "#2e7d32"; // green
        }
        
        return errors;
    }

    function checkVoiceCrossing(bass, sop) {
        var errors = [];
        if (bass && sop && bass.pitch > sop.pitch) {
            errors.push("Voice Crossing");
            bass.color = colorError; sop.color = colorError;
        }
        return errors;
    }

    function addErrorLabels(tick, errors) {
        if (errors.length > 0) {
            var outCursor = curScore.newCursor(); outCursor.rewindToTick(tick);
            var text = newElement(Element.STAFF_TEXT);
            text.text = [...new Set(errors)].join("\n");
            text.color = colorError;
            outCursor.add(text);
        }
    }

    // --- MAIN RUN ---

    onRun: {
        if (!curScore) { quit(); return; }
        curScore.startCmd("Tonal Species 2 Analysis");
        if (curScore.selection.elements.length === 0) { cmd("select-all"); }

        var tickGroups = {};
        curScore.selection.elements.forEach(el => {
            if (el && el.type === Element.NOTE && el.parent && el.parent.parent) {
                var tick = el.parent.parent.tick;
                if (!tickGroups[tick]) tickGroups[tick] = [];
                tickGroups[tick].push(el);
            }
        });

        var sortedTicks = Object.keys(tickGroups).map(Number).sort((a,b)=>a-b);
        if (sortedTicks.length === 0) { quit(); return; }

        var tonicTPC = determineTonic(sortedTicks, tickGroups);
        var lastStaff = curScore.selection.endStaff - 1; 

        // State Variables for Linear Analysis
        // 3. Determine Context: Bass Onset vs Interior
        // If a bass note exists at this tick, it's an "Onset"
        var isBassOnset = (bassNode !== undefined);

        if (isBassOnset) {
            activeBass = bassNode; // Update the "current" bass
            
            // Strict Downbeat Checks
            errors = errors.concat(checkBassOnset(notes, hData));
            
            // CORRECTED VOICE CROSSING:
            // Error if Bass (Lower Staff) Pitch > Soprano (Upper Staff) Pitch
            if (sopNode && activeBass && activeBass.pitch > sopNode.pitch) {
                errors.push("Voice Crossing");
                activeBass.color = colorError; 
                sopNode.color = colorError;
            }
        } else {
            // === INTERIOR NOTE (Bass is sustaining) ===
            if (sopNode && activeBass) {
                // Voice crossing check even on interior notes
                if (activeBass.pitch > sopNode.pitch) {
                    errors.push("Voice Crossing");
                    sopNode.color = colorError;
                }

                // Melodic Function (Passing Tone vs Chord Tone)
                var nextSop = findNoteInSameVoice(sopNode, nextTickNotes);
                errors = errors.concat(checkMelodicFunction(prevSop, sopNode, nextSop, hData, activeBass));
            }

            addErrorLabels(tick, errors);

            // Update Soprano History
            if (sopNode) prevSop = sopNode;
        }

        // Add footer stats if desired (omitted for brevity, can copy from previous version)
        
        curScore.endCmd(); 
        quit();
    }
}