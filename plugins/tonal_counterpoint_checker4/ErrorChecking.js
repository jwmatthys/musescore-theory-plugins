// ErrorChecking.js - Error detection functions for Species 4

.pragma library

.import "HelperFunctions.js" as Helpers

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
        if (noteAna.note.tieBack || noteAna.note.tieForward) {
            return [];
        }
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
        return [Helpers.tpcToName(noteAna.note.tpc) + " should\nstep UP"];
    }
    if (noteAna.isTendency1 && (dist > -1 || dist < -2)) {
        noteAna.note.color = colorError;
        return [Helpers.tpcToName(noteAna.note.tpc) + " should\nstep DOWN"];
    }
    return [];
}

function checkBassOnsetNCT(noteAna, ana) {
    if (noteAna.isBass || !ana.isBassOnset) return [];
    
    if (noteAna.nctType === "invalid") {
        noteAna.note.color = colorError;
        return ["Invalid\nNCT"];
    } else if (noteAna.nctType !== "none") {
        noteAna.note.color = colorPattern;
    }
    
    return [];
}

function checkNonBassOnsetNote(noteAna, ana) {
    if (noteAna.isBass || ana.isBassOnset) return [];
    
    if (!noteAna.isChordTone) {
        if (noteAna.note.tieForward) {
            noteAna.note.color = colorError;
            return ["Invalid\nNCT"];
        }
        
        if (!noteAna.prevNote || !noteAna.nextNote) {
            noteAna.note.color = colorError;
            return ["Invalid\nNCT"];
        }
        
        var prevTpcDist = noteAna.note.tpc - noteAna.prevNote.tpc;
        var nextTpcDist = noteAna.nextNote.tpc - noteAna.note.tpc;
        var prevPitchDist = noteAna.note.pitch - noteAna.prevNote.pitch;
        var nextPitchDist = noteAna.nextNote.pitch - noteAna.note.pitch;
        
        var stepToPrev = Math.abs(prevPitchDist);
        var stepToNext = Math.abs(nextPitchDist);
        
        var leapFrom = !Helpers.isStep(prevTpcDist) || stepToPrev > 2;
        var leapTo = !Helpers.isStep(nextTpcDist) || stepToNext > 2;
        
        if (leapFrom || leapTo) {
            noteAna.note.color = colorError;
            return ["Leap to/from\ndissonance"];
        }
        
        var dirToPrev = noteAna.note.pitch - noteAna.prevNote.pitch;
        var dirToNext = noteAna.nextNote.pitch - noteAna.note.pitch;
        
        var isPassing = dirToPrev * dirToNext > 0;
        var isNeighbor = dirToPrev * dirToNext < 0 && 
                       noteAna.prevNote.pitch === noteAna.nextNote.pitch && 
                       noteAna.prevNote.tpc === noteAna.nextNote.tpc;
        
        if (!isPassing && !isNeighbor) {
            noteAna.note.color = colorError;
            return ["Invalid\nNCT"];
        }
        
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

function checkFirstMelodyNote(ana, bassID) {
    var errors = [];
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

function checkMelodyNotesPerBassOnset(ana, analysis, bassID, nextBassOnsetIdx) {
    var errors = [];
    if (!ana.isBassOnset || nextBassOnsetIdx === -1) return errors;
    
    var melodyNoteCount = 0;
    for (var i = ana.tickIdx; i < nextBassOnsetIdx; i++) {
        var melodyNotes = analysis[i].noteAnalysis.filter(function(n) { return !n.isBass; });
        melodyNoteCount += melodyNotes.length;
    }
    
    if (melodyNoteCount > 2) {
        errors.push("Too many melody notes\nper bass note");
        for (var i = ana.tickIdx; i < nextBassOnsetIdx; i++) {
            analysis[i].noteAnalysis.forEach(function(n) {
                if (!n.isBass) n.note.color = colorError;
            });
        }
    }
    
    return errors;
}

function checkTickErrors(ana, analysis, voices, bassID, sopID, isFirst, isLast, nextBassOnsetIdx) {
    var errors = [];
    
    if (isFirst) {
        errors = errors.concat(checkFirstMelodyNote(ana, bassID));
    }
    
    if (isLast) {
        errors = errors.concat(checkLastNote(ana, bassID));
    }
    
    errors = errors.concat(checkMelodyNotesPerBassOnset(ana, analysis, bassID, nextBassOnsetIdx));
    errors = errors.concat(checkVoiceCrossing(ana, voices));
    errors = errors.concat(checkDoubledTendency(ana, bassID));
    
    ana.noteAnalysis.forEach(function(noteAna) {
        if (noteAna.isBass) return;
        
        errors = errors.concat(checkBassOnsetNCT(noteAna, ana));
        errors = errors.concat(checkNonBassOnsetNote(noteAna, ana));
        errors = errors.concat(checkRepeatedNote(noteAna));
        errors = errors.concat(checkTendencyResolution(noteAna));
    });
    
    // Voice leading checks between note pairs
    for (var x = 0; x < ana.noteAnalysis.length; x++) {
        for (var y = x + 1; y < ana.noteAnalysis.length; y++) {
            var noteAna1 = ana.noteAnalysis[x];
            var noteAna2 = ana.noteAnalysis[y];
            
            // Check from bass onset to next bass onset
            if (noteAna1.nextBassOnsetNote && noteAna2.nextBassOnsetNote) {
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
    }
    
    // Check from offbeat to next offbeat (2 ticks ahead) - OUTSIDE the note pair loop
    if (!ana.isBassOnset && ana.tickIdx + 2 < analysis.length) {
        var nextOffbeatIdx = ana.tickIdx + 2;
        var nextOffbeatAna = analysis[nextOffbeatIdx];
        
        if (!nextOffbeatAna.isBassOnset) {
            var currentInterval = ana.intervalType;
            var nextInterval = nextOffbeatAna.intervalType;
            
            // Parallel perfects
            if (currentInterval && currentInterval === nextInterval) {
                // Find the notes at both offbeats
                var bassNow = ana.bassNote;
                var sopNow = ana.sopNote;
                var bassNext = nextOffbeatAna.bassNote;
                var sopNext = nextOffbeatAna.sopNote;
                
                if (bassNow && sopNow && bassNext && sopNext && sopNow.pitch !== sopNext.pitch) {
                    bassNow.color = colorError; sopNow.color = colorError;
                    bassNext.color = colorError; sopNext.color = colorError;
                    errors.push("Parallel " + currentInterval);
                }
            }
            
            // Direct perfects
            if (!currentInterval && nextInterval) {
                var bassNow = ana.bassNote;
                var sopNow = ana.sopNote;
                var bassNext = nextOffbeatAna.bassNote;
                var sopNext = nextOffbeatAna.sopNote;
                
                if (bassNow && sopNow && bassNext && sopNext) {
                    var bM = bassNext.pitch - bassNow.pitch;
                    var sM = sopNext.pitch - sopNow.pitch;
                    if ((bM * sM > 0) && Math.abs(sM) > 2) {
                        sopNext.color = colorError;
                        errors.push("Direct " + nextInterval);
                    }
                }
            }
        }
    }
    
    return errors;
}