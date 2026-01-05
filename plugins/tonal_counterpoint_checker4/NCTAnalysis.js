// NCTAnalysis.js - Non-chord tone identification for Species 4

.pragma library

.import "HelperFunctions.js" as Helpers

function identifyNCTType(noteAna, ana) {
    if (noteAna.isChordTone || !noteAna.prevNote || !noteAna.nextNote) return "none";
    
    var prevTpcDist = noteAna.note.tpc - noteAna.prevNote.tpc;
    var nextTpcDist = noteAna.nextNote.tpc - noteAna.note.tpc;
    var prevPitchDist = noteAna.note.pitch - noteAna.prevNote.pitch;
    var nextPitchDist = noteAna.nextNote.pitch - noteAna.note.pitch;
    
    if (ana.isBassOnset) {
        // 3. Suspension - tied from previous chord tone, resolves down by step
        if (noteAna.note.tieBack && 
            noteAna.prevNonBassOnsetNote && 
            noteAna.prevNonBassOnsetNote.isChordTone &&
            Helpers.isStep(nextTpcDist) && nextPitchDist < 0 &&
            noteAna.nextNoteAnalysis && noteAna.nextNoteAnalysis.isChordTone) {
            return "suspension";
        }
        
        // 4. Retardation - tied from previous chord tone, resolves up by half-step
        if (noteAna.note.tieBack && 
            noteAna.prevNonBassOnsetNote && 
            noteAna.prevNonBassOnsetNote.isChordTone &&
            Helpers.isHalfStep(nextTpcDist, nextPitchDist) && nextPitchDist > 0 &&
            noteAna.nextNoteAnalysis && noteAna.nextNoteAnalysis.isChordTone) {
            return "retardation";
        }
        
        // 1. Accented Passing Tone - stepwise same direction
        if (Helpers.isStep(prevTpcDist) && Helpers.isStep(nextTpcDist) && 
            prevPitchDist * nextPitchDist > 0) {
            return "accented-passing";
        }
        
        // 2. Accented Neighbor Tone - stepwise opposite direction, returns home
        if (Helpers.isStep(prevTpcDist) && Helpers.isStep(nextTpcDist) && 
            prevPitchDist * nextPitchDist < 0 &&
            noteAna.prevNote.pitch === noteAna.nextNote.pitch &&
            noteAna.prevNote.tpc === noteAna.nextNote.tpc) {
            return "accented-neighbor";
        }
        
        // 5. Appoggiatura - approached by leap, resolves by step
        if (Helpers.isLeap(prevTpcDist)) {
            // Upward leap, resolve down by step
            if (prevPitchDist > 0 && Helpers.isStep(nextTpcDist) && nextPitchDist < 0) {
                return "appoggiatura";
            }
            // Downward leap, resolve up by half-step
            if (prevPitchDist < 0 && Helpers.isHalfStep(nextTpcDist, nextPitchDist) && nextPitchDist > 0) {
                return "appoggiatura";
            }
        }
    }
    
    return "invalid";
}

function analyzeNoteAtTick(note, tickIdx, analysis, bassID, sopID) {
    var ana = analysis[tickIdx];
    var isBass = (note.staffIdx === bassID.staffIdx && note.voice === bassID.voice);
    
    return {
        note: note,
        isBass: isBass,
        isChordTone: ana.hData.tones.indexOf(note.tpc) !== -1,
        isTendency0: ana.hData.tendTones[0] === note.tpc,
        isTendency1: ana.hData.tendTones[1] === note.tpc,
        prevNote: (tickIdx > 0) ? Helpers.findNoteInSameVoice(note, analysis[tickIdx - 1].notes) : null,
        nextNote: (tickIdx < analysis.length - 1) ? Helpers.findNoteInSameVoice(note, analysis[tickIdx + 1].notes) : null,
        nextBassOnsetNote: null,
        prevNonBassOnsetNote: null,
        nextNoteAnalysis: null,
        nctType: "none"
    };
}