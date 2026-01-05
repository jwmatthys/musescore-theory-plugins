// SATBErrorChecking.js - Error detection for SATB part-writing
// Checks voice ranges, spacing, crossing, parallels, direct perfects, and tendency resolution

.pragma library

.import "HarmonyAnalysis.js" as Harmony

var colorError = "#b30000";
var colorDiss = "#6a1b9a";

// Voice ranges (MIDI pitch values)
var voiceRanges = {
    S: { low: 60, high: 79, name: "Soprano" },   // C4-G5
    A: { low: 55, high: 74, name: "Alto" },      // G3-D5
    T: { low: 48, high: 67, name: "Tenor" },     // C3-G4
    B: { low: 40, high: 62, name: "Bass" }       // E2-D4
};

function tpcToName(tpc) {
    var names = {
        6:"Abb", 7:"Ebb", 8:"Gb", 9:"Db", 10:"Ab", 11:"Eb", 12:"Bb", 
        13:"F", 14:"C", 15:"G", 16:"D", 17:"A", 18:"E", 19:"B", 
        20:"F#", 21:"C#", 22:"G#", 23:"D#", 24:"A#", 25:"E#", 26:"B#", 
        27:"Fx", 28:"Cx", 29:"Gx", 30:"Dx", 31:"Ax"
    };
    return names[tpc] || ("TPC:" + tpc);
}

function getIntervalType(lower, upper) {
    if (!lower || !upper) return null;
    var tpcDist = upper.tpc - lower.tpc;
    var semitones = Math.abs(upper.pitch - lower.pitch) % 12;
    if (tpcDist === 0 && semitones === 0) return "P8";
    if (Math.abs(tpcDist) === 1 && semitones === 7) return "P5";
    return null;
}

function findNoteByVoiceLabel(notesObj, label) {
    if (!notesObj) return null;
    return notesObj[label] || null;
}

function checkVoiceRanges(notesObj) {
    var errors = [];
    var voiceLabels = ['S', 'A', 'T', 'B'];
    
    for (var i = 0; i < voiceLabels.length; i++) {
        var label = voiceLabels[i];
        var note = findNoteByVoiceLabel(notesObj, label);
        if (!note) continue;
        
        var range = voiceRanges[label];
        if (note.pitch < range.low) {
            errors.push(range.name + "\ntoo low");
            note.color = colorError;
        } else if (note.pitch > range.high) {
            errors.push(range.name + "\ntoo high");
            note.color = colorError;
        }
    }
    return errors;
}

function checkSpacing(notesObj) {
    var errors = [];
    
    var S = findNoteByVoiceLabel(notesObj, 'S');
    var A = findNoteByVoiceLabel(notesObj, 'A');
    var T = findNoteByVoiceLabel(notesObj, 'T');
    var B = findNoteByVoiceLabel(notesObj, 'B');
    
    // S-A: no more than octave (12 semitones)
    if (S && A && (S.pitch - A.pitch) > 12) {
        errors.push("S-A spacing\n> octave");
        S.color = colorError;
        A.color = colorError;
    }
    
    // A-T: no more than octave
    if (A && T && (A.pitch - T.pitch) > 12) {
        errors.push("A-T spacing\n> octave");
        A.color = colorError;
        T.color = colorError;
    }
    
    // T-B: no more than octave and fifth (19 semitones)
    if (T && B && (T.pitch - B.pitch) > 19) {
        errors.push("T-B spacing\n> 8ve + P5");
        T.color = colorError;
        B.color = colorError;
    }
    
    return errors;
}

function checkVoiceCrossing(notesObj, voiceLayout) {
    var errors = [];
    
    // Skip voice crossing check for keyboard style (voices determined by pitch)
    if (voiceLayout.isKeyboardStyle) return errors;
    
    var voiceOrder = ['B', 'T', 'A', 'S']; // low to high
    
    for (var i = 0; i < voiceOrder.length - 1; i++) {
        var lowerLabel = voiceOrder[i];
        var upperLabel = voiceOrder[i + 1];
        
        var lowerNote = findNoteByVoiceLabel(notesObj, lowerLabel);
        var upperNote = findNoteByVoiceLabel(notesObj, upperLabel);
        
        if (lowerNote && upperNote && lowerNote.pitch > upperNote.pitch) {
            errors.push(upperLabel + "-" + lowerLabel + "\ncrossing");
            lowerNote.color = colorError;
            upperNote.color = colorError;
        }
    }
    return errors;
}

function checkNonChordTones(notes, rn, hData) {
    var errors = [];
    if (rn === "") return errors;
    
    notes.forEach(function(note) {
        if (hData.tones.indexOf(note.tpc) === -1) {
            errors.push("Non-Chord\n(" + tpcToName(note.tpc) + ")");
            note.color = colorDiss;
        }
    });
    return errors;
}

function checkDoubledTendency(notes, hData) {
    var errors = [];
    
    // Check tendency tone 0 (leading tone)
    if (hData.tendTones[0] !== null) {
        var doubled0 = notes.filter(function(n) { return n.tpc === hData.tendTones[0]; });
        if (doubled0.length > 1) {
            errors.push("Doubled\nLead Tone");
            doubled0.forEach(function(n) { n.color = colorError; });
        }
    }
    
    // Check tendency tone 1 (seventh)
    if (hData.tendTones[1] !== null) {
        var doubled1 = notes.filter(function(n) { return n.tpc === hData.tendTones[1]; });
        if (doubled1.length > 1) {
            errors.push("Doubled\n7th");
            doubled1.forEach(function(n) { n.color = colorError; });
        }
    }
    
    return errors;
}

function checkTendencyResolution(notesObj, nextNotesObj, hData) {
    // Only check soprano for tendency resolution (bass typically doesn't have tendency tones)
    var errors = [];
    if (!nextNotesObj) return errors;
    
    var sopNote = findNoteByVoiceLabel(notesObj, 'S');
    var nextSopNote = findNoteByVoiceLabel(nextNotesObj, 'S');
    
    if (sopNote && nextSopNote) {
        var dist = nextSopNote.pitch - sopNote.pitch;
        
        // Leading tone must resolve up by step
        if (hData.tendTones[0] === sopNote.tpc && (dist < 1 || dist > 2)) {
            errors.push(tpcToName(sopNote.tpc) + " should\nstep UP");
            sopNote.color = colorError;
        }
        // Seventh must resolve down by step
        if (hData.tendTones[1] === sopNote.tpc && (dist > -1 || dist < -2)) {
            errors.push(tpcToName(sopNote.tpc) + " should\nstep DOWN");
            sopNote.color = colorError;
        }
    }
    
    return errors;
}

function checkMelodicIntervals(notesObj, nextNotesObj) {
    var errors = [];
    if (!nextNotesObj) return errors;
    var voiceLabels = ['S', 'A', 'T', 'B'];
    
    voiceLabels.forEach(function(label) {
        var note = findNoteByVoiceLabel(notesObj, label);
        var nextNote = findNoteByVoiceLabel(nextNotesObj, label);
        if (!note || !nextNote) return;
        
        var tpcDist = nextNote.tpc - note.tpc;
        if (Math.abs(tpcDist) >= 6) {
            var qual = (tpcDist >= 6) ? "Aug." : "Dim.";
            errors.push(label + ": Melodic\n" + qual);
            note.color = colorError;
            nextNote.color = colorError;
        }
    });
    return errors;
}

function checkParallelPerfects(notesObj, nextNotesObj) {
    var errors = [];
    if (!nextNotesObj) return errors;
    var voiceLabels = ['S', 'A', 'T', 'B'];
    
    // Check all pairs of voices
    for (var i = 0; i < voiceLabels.length; i++) {
        for (var j = i + 1; j < voiceLabels.length; j++) {
            var label1 = voiceLabels[i]; // higher voice (S, A, or T)
            var label2 = voiceLabels[j]; // lower voice
            
            var upper = findNoteByVoiceLabel(notesObj, label1);
            var lower = findNoteByVoiceLabel(notesObj, label2);
            var nextUpper = findNoteByVoiceLabel(nextNotesObj, label1);
            var nextLower = findNoteByVoiceLabel(nextNotesObj, label2);
            
            if (!upper || !lower || !nextUpper || !nextLower) continue;
            
            // Ensure proper ordering (lower pitch is actually lower)
            var currLow = (lower.pitch < upper.pitch) ? lower : upper;
            var currHigh = (lower.pitch < upper.pitch) ? upper : lower;
            var nextLow = (nextLower.pitch < nextUpper.pitch) ? nextLower : nextUpper;
            var nextHigh = (nextLower.pitch < nextUpper.pitch) ? nextUpper : nextLower;
            
            var currInterval = getIntervalType(currLow, currHigh);
            var nextInterval = getIntervalType(nextLow, nextHigh);
            
            // Parallel: same perfect interval, with motion
            if (currInterval && currInterval === nextInterval && upper.pitch !== nextUpper.pitch) {
                errors.push(label1 + "-" + label2 + ":\nParallel " + nextInterval);
                currLow.color = colorError; currHigh.color = colorError;
                nextLow.color = colorError; nextHigh.color = colorError;
            }
        }
    }
    return errors;
}

function checkDirectPerfects(notesObj, nextNotesObj) {
    var errors = [];
    if (!nextNotesObj) return errors;
    var voiceLabels = ['S', 'A', 'T', 'B'];
    
    // Check all pairs of voices
    for (var i = 0; i < voiceLabels.length; i++) {
        for (var j = i + 1; j < voiceLabels.length; j++) {
            var label1 = voiceLabels[i]; // higher voice
            var label2 = voiceLabels[j]; // lower voice
            
            var upper = findNoteByVoiceLabel(notesObj, label1);
            var lower = findNoteByVoiceLabel(notesObj, label2);
            var nextUpper = findNoteByVoiceLabel(nextNotesObj, label1);
            var nextLower = findNoteByVoiceLabel(nextNotesObj, label2);
            
            if (!upper || !lower || !nextUpper || !nextLower) continue;
            
            // Ensure proper ordering
            var currLow = (lower.pitch < upper.pitch) ? lower : upper;
            var currHigh = (lower.pitch < upper.pitch) ? upper : lower;
            var nextLow = (nextLower.pitch < nextUpper.pitch) ? nextLower : nextUpper;
            var nextHigh = (nextLower.pitch < nextUpper.pitch) ? nextUpper : nextLower;
            
            var currInterval = getIntervalType(currLow, currHigh);
            var nextInterval = getIntervalType(nextLow, nextHigh);
            
            // Direct: moving into perfect interval (not from one), similar motion, upper voice leaps
            if (nextInterval && !currInterval) {
                var lowerMotion = nextLow.pitch - currLow.pitch;
                var upperMotion = nextHigh.pitch - currHigh.pitch;
                
                // Similar motion (same direction) and upper voice leaps (> step)
                if ((lowerMotion * upperMotion > 0) && Math.abs(upperMotion) > 2) {
                    errors.push(label1 + "-" + label2 + ":\nDirect " + nextInterval);
                    nextHigh.color = colorError;
                }
            }
        }
    }
    return errors;
}

function isDominantFunction(rn) {
    // Check if the roman numeral is a dominant-function chord (V or viio, including 7ths and secondary)
    if (!rn || rn === "") return false;
    
    // Get the primary part (before any slash for secondary dominants)
    var parts = rn.split('/');
    var primary = parts[0].replace(/ø/g, "0").replace(/Ã¸/g, "0");
    
    // Remove inversion figures to get base
    var base = primary.replace(/[765432]/g, '');
    
    // Check for V or viio variants
    return (base === "V" || base === "viio" || base === "vii0" || 
            base === "viiø" || base === "vii°");
}

function getLocalTonicForChord(rn, tonicTPC, mode) {
    // For secondary dominants (V/x, viio/x), get the local tonic
    if (!rn || rn === "") return tonicTPC;
    
    var parts = rn.split('/');
    if (parts.length === 1) return tonicTPC;
    
    // Get the target chord and find its root
    var targetPart = parts[1].replace(/ø/g, "0").replace(/Ã¸/g, "0");
    var targetData = Harmony.getChordData(targetPart, tonicTPC, mode);
    
    if (targetData.tones.length > 0) {
        // For viio targets, use index 2; for aug6, use index 3; otherwise root at index 0
        if (targetPart.toLowerCase().indexOf("viio") !== -1 || targetPart.toLowerCase().indexOf("vii0") !== -1) {
            return targetData.tones[2];
        } else if (targetPart.match(/^(It|Fr|Ger)/i)) {
            return targetData.tones[3];
        } else {
            return targetData.tones[0];
        }
    }
    return tonicTPC;
}

function checkUnraisedLeadingTone(notes, rn, hData, mode, tonicTPC) {
    var errors = [];
    
    // Only check in minor mode and on dominant-function chords
    if (mode !== "minor" || !isDominantFunction(rn)) return errors;
    
    // Get the local tonic for this chord (handles secondary dominants)
    var localTonic = getLocalTonicForChord(rn, tonicTPC, mode);
    
    // The natural (unraised) 7th scale degree is 2 TPCs below the local tonic
    // The raised leading tone is 5 TPCs above the local tonic
    // Example in A minor (tonic TPC 17): G natural = 15, G# = 22
    var unraisedLT = localTonic - 2;
    
    notes.forEach(function(note) {
        if (note.tpc === unraisedLT) {
            // Check that this note is indeed not a chord tone (it shouldn't be on V or viio)
            if (hData.tones.indexOf(note.tpc) === -1) {
                errors.push("Need to\nraise LT");
                note.color = colorError;
            }
        }
    });
    
    return errors;
}

function checkTickErrors(notes, notesObj, nextNotesObj, rn, hData, voiceLayout, mode, tonicTPC) {
    var errors = [];
    
    errors = errors.concat(checkVoiceRanges(notesObj));
    errors = errors.concat(checkSpacing(notesObj));
    errors = errors.concat(checkVoiceCrossing(notesObj, voiceLayout));
    errors = errors.concat(checkUnraisedLeadingTone(notes, rn, hData, mode, tonicTPC));
    errors = errors.concat(checkNonChordTones(notes, rn, hData));
    errors = errors.concat(checkDoubledTendency(notes, hData));
    errors = errors.concat(checkTendencyResolution(notesObj, nextNotesObj, hData));
    errors = errors.concat(checkMelodicIntervals(notesObj, nextNotesObj));
    errors = errors.concat(checkParallelPerfects(notesObj, nextNotesObj));
    errors = errors.concat(checkDirectPerfects(notesObj, nextNotesObj));
    
    return errors;
}
