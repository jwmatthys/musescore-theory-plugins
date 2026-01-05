// Species3NCTAnalysis.js - Pattern recognition for Species 3

.pragma library

.import "HelperFunctions.js" as Helpers

function isStep(tpcDist) {
    var abs = Math.abs(tpcDist);
    return abs === 2 || abs === 5;
}

function isLeap3(tpcDist) {
    var abs = Math.abs(tpcDist);
    return abs === 3 || abs === 4;
}

function getNoteSequence(startIdx, count, analysis, bassID) {
    if (startIdx + count > analysis.length) return null;
    var notes = [];
    for (var i = 0; i < count; i++) {
        var ana = analysis[startIdx + i];
        var note = ana.notes.find(function(n) { 
            return !(n.staffIdx === bassID.staffIdx && n.voice === bassID.voice);
        });
        if (!note) return null;
        notes.push(note);
    }
    return notes;
}

function isDoubleNeighbor(i, analysis, bassID) {
    if (i + 3 >= analysis.length) return false;
    var ana = [analysis[i], analysis[i+1], analysis[i+2], analysis[i+3]];
    var n = getNoteSequence(i, 4, analysis, bassID);
    if (!n) return false;
    
    if (!ana[0].isBassOnset || !ana[3].isBassOnset) return false;
    if (ana[1].isBassOnset || ana[2].isBassOnset) return false;
    
    var dist1 = n[1].tpc - n[0].tpc, dist2 = n[2].tpc - n[1].tpc, dist3 = n[3].tpc - n[2].tpc;
    var oppositeDir = (n[1].pitch - n[0].pitch) * (n[2].pitch - n[1].pitch) < 0;
    var returnsHome = (n[3].pitch === n[0].pitch && n[3].tpc === n[0].tpc);
    
    return isStep(dist1) && isLeap3(dist2) && isStep(dist3) && oppositeDir && returnsHome;
}

function isNotaCambiata(i, analysis, bassID) {
    if (i + 3 >= analysis.length) return false;
    var n = getNoteSequence(i, 4, analysis, bassID);
    if (!n || !analysis[i].isBassOnset) return false;
    
    var dist1 = n[1].tpc - n[0].tpc, dist2 = n[2].tpc - n[1].tpc, dist3 = n[3].tpc - n[2].tpc;
    var isStepDown = isStep(dist1) && n[1].pitch < n[0].pitch;
    var isLeap3Down = isLeap3(dist2) && n[2].pitch < n[1].pitch;
    var isStepUp = isStep(dist3) && n[3].pitch > n[2].pitch;
    
    return isStepDown && isLeap3Down && isStepUp && analysis[i].hData.tones.indexOf(n[2].tpc) !== -1;
}

function isPassingOrNeighborTone(noteAna, hData) {
    if (!noteAna.prevNote || !noteAna.nextNote) return false;
    if (hData.tones.indexOf(noteAna.note.tpc) !== -1) return true;
    
    var stepToPrev = Math.abs(noteAna.note.pitch - noteAna.prevNote.pitch);
    var stepToNext = Math.abs(noteAna.note.pitch - noteAna.nextNote.pitch);
    if (stepToPrev > 2 || stepToNext > 2) return false;
    
    var dirToPrev = noteAna.note.pitch - noteAna.prevNote.pitch;
    var dirToNext = noteAna.nextNote.pitch - noteAna.note.pitch;
    
    // Passing tone (same direction) or neighbor tone (opposite direction, returns home)
    return dirToPrev * dirToNext > 0 || 
           (dirToPrev * dirToNext < 0 && noteAna.prevNote.pitch === noteAna.nextNote.pitch && 
            noteAna.prevNote.tpc === noteAna.nextNote.tpc);
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