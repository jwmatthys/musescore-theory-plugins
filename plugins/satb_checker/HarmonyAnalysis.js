// HarmonyAnalysis.js - Roman numeral analysis for counterpoint checking

.pragma library

var chordMap = {
    "I":      [0, 1, 4],      "III":   [-3, -2, 1], 
    "IV":     [-1, 0, 3],     "V":     [1, 2, 5],  "VI":  [-4, -3, 0], "VII": [-2, -1, 1],
    "i":      [0, 1, -3],     "ii":    [2, 3, -1], "iii": [4, 5, 1], 
    "iv":     [-1, 0, -4],    "v":     [1, 2, -2], "vi":  [3, 4, 0],
    "iio":    [2, -4, -1],    "viio":  [-1, 2, 5],
    "I7":     [0, 1, 4, 5],   "III7":  [-3, -2, 1, 2],  "IV7":   [-1, 0, 3, 4], "VI7":   [-4, -3, 0, 1], "VII7": [-2, -1, 2, 3],
    "i7":     [0, 1, -3, -2], "ii7":   [2, 3, -1, 0], "iii7":  [4, 5, 1, 2],  "iv7":   [-1, 0, -4, -3], "vi7":   [3, 4, 0, 1],
    "V7":     [1, 2, 5, -1],  "viio7": [2, -1, 5, -4], "vii07": [2, -1, 5, 3],  "ii07":  [2, -4, -1, 0],
    "It6":    [0, 0, 6, -4],  "Fr65":  [0, 2, 6, -4],  "Ger65": [0, -3, 6, -4], "N6":    [-5, -4, -1],
    "It":     [0, 0, 6, -4],  "Fr":    [0, 2, 6, -4],  "Ger":   [0, -3, 6, -4], "N":     [-5, -4, -1]
    // Note: "Cad" handled specially in getChordData based on mode
};

// Mode-specific chord definitions
var cadMajor = [1, 0, 4];   // Cad in major: 5, 1, 3 (major third)
var cadMinor = [1, 0, -3];  // Cad in minor: 5, 1, b3 (minor third)

function getChordData(rn, tonicTPC, mode) {
    if (!rn || rn === "") return { tones: [], tendTones: [null, null] };
    
    // Default mode to major if not specified
    if (!mode) mode = "major";

    var parts = rn.split('/');
    var primaryPart = parts[0].replace("ø", "0");
    var targetPart = parts.length > 1 ? parts[1].replace("ø", "0") : null;

    var localTonic = tonicTPC; 
    if (targetPart) {
        var targetData = getChordData(targetPart, tonicTPC, mode);
        if (targetData.tones.length > 0) {
            if (targetPart.toLowerCase().indexOf("viio") !== -1 || targetPart.toLowerCase().indexOf("vii0") !== -1) {
                localTonic = targetData.tones[2];
            } else if (targetPart.match(/^(It|Fr|Ger)/i)) {
                localTonic = targetData.tones[3];
            } else {
                localTonic = targetData.tones[0];
            }
        }
    }

    var lookup = primaryPart;
    var isSeventh = lookup.match(/7|65|43|42/) !== null;
    var baseRN = lookup.replace(/[765432]/g, ''); 
    var searchKey = lookup;
    var offsets = null;

    // Special handling for Cad chord based on mode
    if (baseRN === "Cad") {
        offsets = (mode === "minor") ? cadMinor : cadMajor;
    } else {
        if (!chordMap[searchKey]) {
            if (isSeventh && chordMap[baseRN + "7"]) {
                searchKey = baseRN + "7";
            } else if (chordMap[baseRN]) {
                searchKey = baseRN;
            } else {
                var capitalized = baseRN.charAt(0).toUpperCase() + baseRN.slice(1);
                searchKey = chordMap[capitalized] ? capitalized : null;
            }
        }
        offsets = chordMap[searchKey];
    }

    if (!offsets) return { tones: [], tendTones: [null, null] };
    
    var tones = offsets.map(function(o) { return localTonic + o; });
    var tendTones = [null, null];
    var upperBase = baseRN.toUpperCase();

    if (upperBase === "V" || upperBase === "VIIO" || upperBase === "VII0") {
        tendTones[0] = tones[2]; 
        if (tones.length === 4) tendTones[1] = tones[3]; 
    } 
    return { tones: tones, tendTones: tendTones };
}

function getCurrentHarmonyContext(tick, bassOnsets, tickGroups, tonicTPC, mode, curScore, Element) {
    var contextTick = null;
    for (var i = bassOnsets.length - 1; i >= 0; i--) {
        if (bassOnsets[i] <= tick) {
            contextTick = bassOnsets[i];
            break;
        }
    }
    if (contextTick === null) return { rn: "", hData: getChordData("", tonicTPC, mode) };
    
    var cursor = curScore.newCursor(); 
    cursor.rewindToTick(contextTick);
    var rn = "";
    if (cursor.segment) {
        cursor.segment.annotations.forEach(function(ann) {
            if (ann.type === Element.HARMONY) rn = ann.text;
        });
    }
    return { rn: rn, hData: getChordData(rn, tonicTPC, mode) };
}

// Key signature to TPC mapping (for major keys)
// Key sig value: -7 to +7 (flats negative, sharps positive)
// Returns the TPC of the major key tonic
function keySigToMajorTPC(keySig) {
    // Key sig 0 = C major (TPC 14)
    // Each sharp adds 1 to TPC, each flat subtracts 1
    return 14 + keySig;
}

// Get the relative minor TPC from major TPC (up 3 on TPC circle)
// C major (TPC 14) -> A minor (TPC 17)
function majorTPCtoMinorTPC(majorTPC) {
    return majorTPC + 3;
}

function determineKeyAndMode(sortedTicks, tickGroups, curScore, Element, newElement) {
    var result = { tonic: 14, mode: "major" };
    
    // ===== STAGE 1: Read key signature at start of selection =====
    var keySig = null;
    var cursor = curScore.newCursor();
    
    // Go to the first tick in the selection to get the key signature there
    if (sortedTicks.length > 0) {
        cursor.rewindToTick(sortedTicks[0]);
    } else {
        cursor.rewind(0);
    }
    
    if (cursor.keySignature !== undefined) {
        keySig = cursor.keySignature;
    }
    
    var majorTPC = (keySig !== null) ? keySigToMajorTPC(keySig) : 14;
    var minorTPC = majorTPCtoMinorTPC(majorTPC);
    
    // Default assumption: major key from key signature
    result.tonic = majorTPC;
    result.mode = "major";
    
    // ===== STAGE 2: Find first root position V or V7 (not secondary) =====
    var foundV = false;
    for (var i = 0; i < sortedTicks.length && !foundV; i++) {
        var t = sortedTicks[i];
        cursor.rewindToTick(t);
        if (cursor.segment && cursor.segment.annotations) {
            for (var j = 0; j < cursor.segment.annotations.length; j++) {
                var ann = cursor.segment.annotations[j];
                if (ann.type === Element.HARMONY) {
                    var rn = ann.text;
                    // Check for root position V or V7 (not secondary - no slash)
                    if (rn.match(/^V7?$/)) {
                        var chordNotes = tickGroups[t].sort(function(a,b) { return a.pitch - b.pitch; });
                        if (chordNotes.length > 0) {
                            var bassTPC = chordNotes[0].tpc;
                            var impliedTonic = bassTPC - 1; // V is 1 fifth above tonic
                            
                            // Check if implied tonic matches major or minor from key sig
                            if (impliedTonic === majorTPC) {
                                result.tonic = majorTPC;
                                result.mode = "major";
                                foundV = true;
                                break;
                            } else if (impliedTonic === minorTPC) {
                                result.tonic = minorTPC;
                                result.mode = "minor";
                                foundV = true;
                                break;
                            }
                        }
                    }
                }
            }
        }
    }
    
    // ===== STAGE 3: Statistical analysis of roman numerals =====
    if (!foundV) {
        var majorScore = 0;
        
        sortedTicks.forEach(function(t) {
            cursor.rewindToTick(t);
            if (cursor.segment && cursor.segment.annotations) {
                cursor.segment.annotations.forEach(function(ann) {
                    if (ann.type === Element.HARMONY) {
                        var rn = ann.text;
                        var primary = rn.split('/')[0];
                        var base = primary.replace(/[765432]/g, '');
                        
                        // Major indicators: I, ii, iii, IV, vi (+1)
                        if (base === "I" || base === "ii" || base === "iii" || base === "IV" || base === "vi") {
                            majorScore++;
                        }
                        // Minor indicators: i, iio, III, iv, VI (-1)
                        else if (base === "i" || base === "iio" || base === "ii0" || base === "III" || base === "iv" || base === "VI") {
                            majorScore--;
                        }
                    }
                });
            }
        });
        
        if (majorScore > 0) {
            result.tonic = majorTPC;
            result.mode = "major";
        } else if (majorScore < 0) {
            result.tonic = minorTPC;
            result.mode = "minor";
        } else {
            // Tie or no data - default to major from key sig
            result.tonic = majorTPC;
            result.mode = "major";
        }
    }
    
    return result;
}