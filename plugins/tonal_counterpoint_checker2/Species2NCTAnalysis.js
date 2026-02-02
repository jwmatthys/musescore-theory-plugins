// Species2NCTAnalysis.js - Pattern recognition for Species 2
// Second species only allows passing tones (no neighbor tones, double neighbors, or cambiatas)

.pragma library

.import "HelperFunctions.js" as Helpers

function isStep(tpcDist) {
    var abs = Math.abs(tpcDist);
    return abs === 2 || abs === 5;
}

function isPassingTone(noteAna, hData) {
    if (!noteAna.prevNote || !noteAna.nextNote) return false;
    if (hData.tones.indexOf(noteAna.note.tpc) !== -1) return true; // It's a chord tone
    
    var stepToPrev = Math.abs(noteAna.note.pitch - noteAna.prevNote.pitch);
    var stepToNext = Math.abs(noteAna.note.pitch - noteAna.nextNote.pitch);
    
    var dirToPrev = noteAna.note.pitch - noteAna.prevNote.pitch;
    var dirToNext = noteAna.nextNote.pitch - noteAna.note.pitch;
    var sameDirection = dirToPrev * dirToNext > 0;
    
    // Check for melodic minor exception: sol-le-ti or ti-le-sol
    // This creates an aug2 (3 semitones) but is acceptable
    if ((stepToPrev === 1 && stepToNext === 3 && sameDirection) ||
        (stepToPrev === 3 && stepToNext === 1 && sameDirection)) {
        // Verify it's ascending (sol-le-ti) or descending (ti-le-sol)
        // by checking the overall motion is 4 semitones (aug2 + step)
        var totalMotion = Math.abs(noteAna.nextNote.pitch - noteAna.prevNote.pitch);
        if (totalMotion === 4) {
            return true; // Valid melodic minor passing tone
        }
    }
    
    // Must be approached and left by step (max 2 semitones)
    if (stepToPrev > 2 || stepToNext > 2) return false;
    
    // Passing tone: same direction (both ascending or both descending)
    return sameDirection;
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
        nextBassOnsetNote: null
    };
}