// HelperFunctions.js - Utility functions for counterpoint analysis

.pragma library

function tpcToName(tpc) {
    var names = {
        6:"Abb", 7:"Ebb", 8:"Gb", 9:"Db", 10:"Ab", 11:"Eb", 12:"Bb", 
        13:"F", 14:"C", 15:"G", 16:"D", 17:"A", 18:"E", 19:"B", 
        20:"F#", 21:"C#", 22:"G#", 23:"D#", 24:"A#", 25:"E#", 26:"B#", 
        27:"Fx", 28:"Cx", 29:"Gx", 30:"Dx", 31:"Ax"
    };
    return names[tpc] || ("TPC:" + tpc);
}

function getIntervalType(bass, sop) {
    if (!bass || !sop) return null;
    var tpcDist = sop.tpc - bass.tpc;
    var pitchDist = sop.pitch - bass.pitch;
    var semitones = Math.abs(pitchDist % 12);
    
    if (tpcDist === 0 && semitones === 0) return "P8";
    if (Math.abs(tpcDist) === 1 && semitones === 7) return "P5";
    return null;
}

function findNoteInSameVoice(sourceNote, nextTickNotes) {
    if (!sourceNote || !nextTickNotes) return null;
    for (var i = 0; i < nextTickNotes.length; i++) {
        if (nextTickNotes[i].staffIdx === sourceNote.staffIdx && 
            nextTickNotes[i].voice === sourceNote.voice) {
            return nextTickNotes[i];
        }
    }
    return null;
}

function isStep(tpcDist) {
    var abs = Math.abs(tpcDist);
    return abs === 2 || abs === 5;
}

function isHalfStep(tpcDist, pitchDist) {
    return isStep(tpcDist) && Math.abs(pitchDist) === 1;
}

function isLeap(tpcDist) {
    return Math.abs(tpcDist) >= 3;
}

function identifyBassOnsets(sortedTicks, tickGroups, bassID, curScore, Element) {
    var bassOnsets = [];
    
    for (var i = 0; i < sortedTicks.length; i++) {
        var tick = sortedTicks[i];
        
        // Check if there's a bass note at this tick
        var hasBassNote = tickGroups[tick].some(function(n) { 
            return n.staffIdx === bassID.staffIdx && n.voice === bassID.voice; 
        });
        
        // Check if there's a harmony annotation at this tick
        var hasHarmony = false;
        if (curScore && Element) {
            var cursor = curScore.newCursor();
            cursor.rewindToTick(tick);
            if (cursor.segment && cursor.segment.annotations) {
                cursor.segment.annotations.forEach(function(ann) {
                    if (ann.type === Element.HARMONY) {
                        hasHarmony = true;
                    }
                });
            }
        }
        
        // Create bass onset if there's either a bass note or harmony
        if (hasBassNote || hasHarmony) {
            bassOnsets.push(tick);
        }
    }
    return bassOnsets;
}