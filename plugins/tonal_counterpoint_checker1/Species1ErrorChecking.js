// Species1ErrorChecking.js - Error detection for Species 1
// First species: note-against-note, all notes must be chord tones

.pragma library

.import "HelperFunctions.js" as Helpers

var colorError = "#b30000";
var colorDiss = "#6a1b9a";

function checkVoiceCrossing(notes, voices) {
    var errors = [];
    for (var v = 0; v < voices.length - 1; v++) {
        var lowNote = notes.find(function(n) { 
            return n.staffIdx === voices[v].staffIdx && n.voice === voices[v].voice; 
        });
        var highNote = notes.find(function(n) { 
            return n.staffIdx === voices[v+1].staffIdx && n.voice === voices[v+1].voice; 
        });
        
        if (lowNote && highNote && lowNote.pitch > highNote.pitch) {
            errors.push("Voice Crossing");
            lowNote.color = colorError; 
            highNote.color = colorError;
        }
    }
    return errors;
}

function checkDoubledTendency(notes, hData, bassID, sopID) {
    var errors = [];
    
    var bassNote = notes.find(function(n) { 
        return n.staffIdx === bassID.staffIdx && n.voice === bassID.voice; 
    });
    var sopNote = notes.find(function(n) { 
        return n.staffIdx === sopID.staffIdx && n.voice === sopID.voice; 
    });
    
    if (bassNote && sopNote) {
        var isTendency0 = (hData.tendTones[0] !== null && bassNote.tpc === hData.tendTones[0]);
        var isTendency1 = (hData.tendTones[1] !== null && bassNote.tpc === hData.tendTones[1]);
        
        if ((isTendency0 || isTendency1) && bassNote.tpc === sopNote.tpc) {
            errors.push("Doubled\nTendency Tone");
            bassNote.color = colorError;
            sopNote.color = colorError;
        }
    }
    return errors;
}

function checkNonChordTones(notes, rn, hData) {
    var errors = [];
    if (rn === "") return errors;
    
    notes.forEach(function(note) {
        if (hData.tones.indexOf(note.tpc) === -1) {
            errors.push("Non-Chord (" + Helpers.tpcToName(note.tpc) + ")");
            note.color = colorDiss;
        }
    });
    return errors;
}

function checkTendencyResolution(notes, nextNotes, hData, bassID) {
    var errors = [];
    if (!nextNotes) return errors;
    
    notes.forEach(function(note) {
        var isBass = (note.staffIdx === bassID.staffIdx && note.voice === bassID.voice);
        if (isBass) return;
        
        var nextNote = Helpers.findNoteInSameVoice(note, nextNotes);
        if (!nextNote) return;
        
        var dist = nextNote.pitch - note.pitch;
        
        if (hData.tendTones[0] === note.tpc && (dist < 1 || dist > 2)) {
            errors.push(Helpers.tpcToName(note.tpc) + " should\nstep UP");
            note.color = colorError;
        }
        if (hData.tendTones[1] === note.tpc && (dist > -1 || dist < -2)) {
            errors.push(Helpers.tpcToName(note.tpc) + " should\nstep DOWN");
            note.color = colorError;
        }
    });
    return errors;
}

function checkMelodicIntervals(notes, nextNotes) {
    var errors = [];
    if (!nextNotes) return errors;
    
    notes.forEach(function(note) {
        var nextNote = Helpers.findNoteInSameVoice(note, nextNotes);
        if (!nextNote) return;
        
        var tpcDist = nextNote.tpc - note.tpc;
        if (Math.abs(tpcDist) >= 6) {
            var qual = (tpcDist >= 6) ? "Aug." : "Dim.";
            errors.push("Melodic " + qual);
            note.color = colorError;
            nextNote.color = colorError;
        }
    });
    return errors;
}

function checkParallelPerfects(notes, nextNotes) {
    var errors = [];
    if (!nextNotes) return errors;
    
    for (var x = 0; x < notes.length; x++) {
        for (var y = x + 1; y < notes.length; y++) {
            var n1 = notes[x], n2 = notes[y];
            var nN1 = Helpers.findNoteInSameVoice(n1, nextNotes);
            var nN2 = Helpers.findNoteInSameVoice(n2, nextNotes);
            
            if (!nN1 || !nN2) continue;
            
            var lC = (n1.pitch < n2.pitch) ? n1 : n2; 
            var hC = (n1.pitch < n2.pitch) ? n2 : n1;
            var lN = (nN1.pitch < nN2.pitch) ? nN1 : nN2; 
            var hN = (nN1.pitch < nN2.pitch) ? nN2 : nN1;
            
            var cT = Helpers.getIntervalType(lC, hC);
            var nT = Helpers.getIntervalType(lN, hN);
            
            if (cT && cT === nT && nN1.pitch !== n1.pitch) {
                errors.push("Parallel " + nT);
                lC.color = colorError; hC.color = colorError;
                lN.color = colorError; hN.color = colorError;
            }
        }
    }
    return errors;
}

function checkDirectPerfects(notes, nextNotes, bassID, sopID) {
    var errors = [];
    if (!nextNotes) return errors;
    
    for (var x = 0; x < notes.length; x++) {
        for (var y = x + 1; y < notes.length; y++) {
            var n1 = notes[x], n2 = notes[y];
            var nN1 = Helpers.findNoteInSameVoice(n1, nextNotes);
            var nN2 = Helpers.findNoteInSameVoice(n2, nextNotes);
            
            if (!nN1 || !nN2) continue;
            
            var lC = (n1.pitch < n2.pitch) ? n1 : n2; 
            var hC = (n1.pitch < n2.pitch) ? n2 : n1;
            var lN = (nN1.pitch < nN2.pitch) ? nN1 : nN2; 
            var hN = (nN1.pitch < nN2.pitch) ? nN2 : nN1;
            
            var isBass = (lC.staffIdx === bassID.staffIdx && lC.voice === bassID.voice);
            var isSop = (hC.staffIdx === sopID.staffIdx && hC.voice === sopID.voice);
            var cT = Helpers.getIntervalType(lC, hC);
            var nT = Helpers.getIntervalType(lN, hN);
            
            if (isBass && isSop && nT && !cT) {
                var bM = lN.pitch - lC.pitch;
                var sM = hN.pitch - hC.pitch;
                if ((bM * sM > 0) && Math.abs(sM) > 2) {
                    errors.push("Direct " + nT);
                    hN.color = colorError; 
                }
            }
        }
    }
    return errors;
}

function checkTickErrors(notes, nextNotes, rn, hData, voices, bassID, sopID) {
    var errors = [];
    
    errors = errors.concat(checkVoiceCrossing(notes, voices));
    errors = errors.concat(checkDoubledTendency(notes, hData, bassID, sopID));
    errors = errors.concat(checkNonChordTones(notes, rn, hData));
    errors = errors.concat(checkTendencyResolution(notes, nextNotes, hData, bassID));
    errors = errors.concat(checkMelodicIntervals(notes, nextNotes));
    errors = errors.concat(checkParallelPerfects(notes, nextNotes));
    errors = errors.concat(checkDirectPerfects(notes, nextNotes, bassID, sopID));
    
    return errors;
}