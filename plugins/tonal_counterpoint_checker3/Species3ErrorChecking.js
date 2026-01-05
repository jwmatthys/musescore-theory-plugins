// Species3ErrorChecking.js - Error detection for Species 3

.pragma library

.import "HelperFunctions.js" as Helpers
.import "Species3NCTAnalysis.js" as NCT

var colorError = "#b30000";
var colorPattern = "#2e7d32";

function checkVoiceCrossing(ana, voices) {
    var errors = [];
    for (var v = 0; v < voices.length - 1; v++) {
        var lowNote = ana.notes.find(function(n) { 
            return n.staffIdx === voices[v].staffIdx && n.voice === voices[v].voice; 
        });
        var highNote = ana.notes.find(function(n) { 
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

function checkDoubledTendency(ana, bassID) {
    var errors = [];
    if (!ana.isBassOnset) return errors;
    
    var bassNoteAna = ana.noteAnalysis.find(function(n) { return n.isBass; });
    if (!bassNoteAna) return errors;
    
    var otherWithSameTPC = ana.noteAnalysis.filter(function(n) { 
        return !n.isBass && n.note.tpc === bassNoteAna.note.tpc; 
    });
    if (otherWithSameTPC.length > 0 && (bassNoteAna.isTendency0 || bassNoteAna.isTendency1)) {
        errors.push("Doubled\nTendency Tone");
        otherWithSameTPC.forEach(function(n) { n.note.color = colorError; });
    }
    return errors;
}

function checkRepeatedNote(noteAna) {
    if (noteAna.nextNote && 
        noteAna.nextNote.pitch === noteAna.note.pitch && 
        noteAna.nextNote.tpc === noteAna.note.tpc) {
        noteAna.note.color = colorError;
        noteAna.nextNote.color = colorError;
        return ["Repeated\nMelody Note"];
    }
    return [];
}

function checkTendencyResolution(noteAna, ana, nextTickAnalysis) {
    // Only check tendency resolution on the last note before a bass onset
    if (!noteAna.nextBassOnsetNote) return [];
    if (!nextTickAnalysis || !nextTickAnalysis.isBassOnset) return [];
    
    var dist = noteAna.nextBassOnsetNote.pitch - noteAna.note.pitch;
    
    if (noteAna.isTendency0 && (dist < 1 || dist > 2)) {
        noteAna.note.color = colorError;
        return [Helpers.tpcToName(noteAna.note.tpc) + " should\nstep UP"];
    }
    if (noteAna.isTendency1 && (dist > -1 || dist < -2)) {
        noteAna.note.color = colorError;
        return [Helpers.tpcToName(noteAna.note.tpc) + " should\nstep DOWN"];
    }
    return [];
}

function checkInvalidNCT(noteAna, ana) {
    if (noteAna.isBass || !ana.isBassOnset || ana.rn === "") return [];
    if (noteAna.isChordTone) return [];
    
    noteAna.note.color = colorError;
    return ["Invalid\nNCT"];
}

function checkNonChordTone(noteAna, ana) {
    if (noteAna.isBass || noteAna.isChordTone) return [];
    
    var isStandardNCT = NCT.isPassingOrNeighborTone(noteAna, ana.hData);
    
    if (!isStandardNCT && !ana.isPartOfPattern) {
        noteAna.note.color = colorError;
        return ["Invalid\nNCT"];
    } else if (ana.isPartOfPattern) {
        noteAna.note.color = colorPattern;
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
    
    var cT = Helpers.getIntervalType(lC, hC);
    var nT = Helpers.getIntervalType(lN, hN);
    
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
    var cT = Helpers.getIntervalType(lC, hC);
    var nT = Helpers.getIntervalType(lN, hN);
    
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

function checkFirstMelodyNote(ana, bassID, isFirstTick) {
    var errors = [];
    if (!isFirstTick) return errors;
    
    var melodyNotes = ana.noteAnalysis.filter(function(n) { return !n.isBass; });
    
    if (melodyNotes.length > 0) {
        var firstMelodyNote = melodyNotes[0];
        if (!firstMelodyNote.isChordTone) {
            errors.push("First note must\nbe chord tone");
            firstMelodyNote.note.color = colorError;
        }
    }
    return errors;
}

function checkLastNote(ana, bassID) {
    var errors = [];
    
    if (!ana.isBassOnset) {
        errors.push("Last note must align\nwith bass note");
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

function checkTickErrors(ana, analysis, voices, bassID, sopID, isFirst, isLast) {
    var errors = [];
    
    if (isFirst) {
        errors = errors.concat(checkFirstMelodyNote(ana, bassID));
    }
    
    if (isLast) {
        errors = errors.concat(checkLastNote(ana, bassID));
    }
    
    errors = errors.concat(checkVoiceCrossing(ana, voices));
    errors = errors.concat(checkDoubledTendency(ana, bassID));
    
    // Get next tick analysis for tendency resolution check
    var nextTickAnalysis = (ana.tickIdx + 1 < analysis.length) ? analysis[ana.tickIdx + 1] : null;
    
    ana.noteAnalysis.forEach(function(noteAna) {
        if (noteAna.isBass) return;
        
        errors = errors.concat(checkInvalidNCT(noteAna, ana));
        errors = errors.concat(checkRepeatedNote(noteAna));
        errors = errors.concat(checkTendencyResolution(noteAna, ana, nextTickAnalysis));
        errors = errors.concat(checkNonChordTone(noteAna, ana));
    });
    
    for (var x = 0; x < ana.noteAnalysis.length; x++) {
        for (var y = x + 1; y < ana.noteAnalysis.length; y++) {
            var noteAna1 = ana.noteAnalysis[x];
            var noteAna2 = ana.noteAnalysis[y];
            
            var mel1 = checkMelodicInterval(noteAna1);
            var mel2 = checkMelodicInterval(noteAna2);
            if (mel1) errors.push("Melodic " + mel1);
            if (mel2) errors.push("Melodic " + mel2);
            
            var parallel = checkParallelPerfects(noteAna1, noteAna2);
            if (parallel) errors.push(parallel);
            
            var direct = checkDirectPerfect(noteAna1, noteAna2, bassID, sopID);
            if (direct) errors.push(direct);
        }
    }
    
    return errors;
}