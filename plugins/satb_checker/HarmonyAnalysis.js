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

function determineMode(sortedTicks, curScore, Element) {
    // Scan roman numerals to determine mode
    // Look for definitive minor indicators: i, iv, or lowercase tonic-function chords
    // Look for definitive major indicators: I, IV
    var minorCount = 0;
    var majorCount = 0;
    
    sortedTicks.forEach(function(t) {
        var cursor = curScore.newCursor(); 
        cursor.rewindToTick(t);
        if (cursor.segment && cursor.segment.annotations) {
            cursor.segment.annotations.forEach(function(ann) {
                if (ann.type === Element.HARMONY) {
                    var rn = ann.text;
                    // Get the primary chord (before any slash)
                    var primary = rn.split('/')[0];
                    
                    // Remove inversion figures to get base RN
                    var base = primary.replace(/[765432]/g, '');
                    
                    // Check for tonic/subdominant indicators
                    if (base === "i" || base === "iv") {
                        minorCount++;
                    } else if (base === "I" || base === "IV") {
                        majorCount++;
                    }
                    // Also check for iio (common in minor) vs ii (common in major)
                    else if (base === "iio" || base === "ii0") {
                        minorCount++;
                    } else if (base === "ii") {
                        majorCount++;
                    }
                }
            });
        }
    });
    
    // Default to major if no clear indicators or tie
    return (minorCount > majorCount) ? "minor" : "major";
}

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

function determineTonic(sortedTicks, tickGroups, curScore, Element) {
    var tpc = 14;
    sortedTicks.forEach(function(t) {
        var cursor = curScore.newCursor(); 
        cursor.rewindToTick(t);
        if (cursor.segment && cursor.segment.annotations) {
            cursor.segment.annotations.forEach(function(ann) {
                if (ann.type === Element.HARMONY && ann.text.match(/^V7?$/)) {
                    var chordNotes = tickGroups[t].sort(function(a,b) { return a.pitch - b.pitch; });
                    if (chordNotes.length > 0) tpc = chordNotes[0].tpc - 1; 
                }
            });
        }
    });
    return tpc;
}
