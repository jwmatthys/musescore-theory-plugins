import QtQuick
import MuseScore

MuseScore {
    title: "Pop and Jazz Chord Labeler"
    version: "1.0"
    description: "Adds pop and jazz chord analysis as Staff Text"
    categoryCode: "Analysis"
    thumbnailName: "thumbnail_popchord.png"
    requiresScore: true

    // --- 1. HARVEST NOTES ---
    function getGlobalGroups(selection) {
        var groups = {}; 
        var minStaff = 999;
        for (var i = 0; i < selection.elements.length; i++) {
            var el = selection.elements[i];
            if (el.type === Element.NOTE) {
                var chord = el.parent;
                var segment = chord.parent;
                if (segment && segment.tick !== undefined) {
                    var tick = segment.tick;
                    if (!groups[tick]) groups[tick] = { "notes": [], "tick": tick };
                    groups[tick].notes.push(el);
                    if (chord.staffIdx < minStaff) minStaff = chord.staffIdx;
                }
            }
        }
        var list = [];
        for (var t in groups) { list.push(groups[t]); }
        list.sort(function(a, b) { return a.tick - b.tick; });
        return { "groups": list, "topStaff": minStaff };
    }

    // --- 2. CLEAN GLOBAL TPC TRANSLATION ---
    function getProperNoteName(tpc) {
        var names = {
            "-1":"F♭♭", "0":"C♭♭", "1":"G♭♭", "2":"D♭♭", "3":"A♭♭", "4":"E♭♭", "5":"B♭♭",
            "6":"F♭",  "7":"C♭",  "8":"G♭",  "9":"D♭",  "10":"A♭", "11":"E♭", "12":"B♭",
            "13":"F",  "14":"C",  "15":"G",  "16":"D",  "17":"A",  "18":"E",  "19":"B",
            "20":"F♯", "21":"C♯", "22":"G♯", "23":"D♯", "24":"A♯", "25":"E♯", "26":"B♯",
            "27":"F♯♯", "28":"C♯♯", "29":"G♯♯", "30":"D♯♯", "31":"A♯♯", "32":"E♯♯", "33":"B♯♯"
        };
        return qsTranslate("global", names[tpc] || "?");
    }

    // --- 3. DYNAMIC CHORD LOGIC ---
    function identifyPopChord(chordNotes) {
        var tpcs = [];
        var lowestPitch = 999;
        var bassTPC = -1;

        for (var i = 0; i < chordNotes.length; i++) {
            var n = chordNotes[i];
            if (tpcs.indexOf(n.tpc) === -1) tpcs.push(n.tpc);
            if (n.pitch < lowestPitch) {
                lowestPitch = n.pitch;
                bassTPC = n.tpc;
            }
        }
        if (tpcs.length < 3) return null;

        var candidates = [];

        // Try each note as potential root
        for (var r = 0; r < tpcs.length; r++) {
            var root = tpcs[r];
            var deltas = tpcs.map(function(t) { return t - root; });
            var has = function(d) { return deltas.indexOf(d) !== -1; };
            
            // Count how many notes are "explained" by each chord type
            var checkFit = function(validDeltas) {
                var explained = 0;
                for (var i = 0; i < deltas.length; i++) {
                    if (validDeltas.indexOf(deltas[i]) !== -1) explained++;
                }
                return explained;
            };

            var quality = null;
            var ext = "";
            var weight = 0;

            // === SEVENTH CHORDS ===
            // Dom7: root, M3, P5, m7 (and extensions)
            if (has(4) && has(-2)) {
                var dom7Valid = [0, 4, 1, -2, 2, 3, 6, -5, 9]; // root, 3, 5, 7, 9, 13, #11, b9, #9
                var fit = checkFit(dom7Valid);
                if (fit === tpcs.length) {
                    quality = "7"; weight = 4;
                    if (has(3)) { quality = "13"; weight++; }
                    else if (has(2)) { quality = "9"; weight++; }
                    if (has(6)) ext += "♯11";
                    if (has(-5)) ext += "♭9";
                    if (has(9)) ext += "♯9";
                }
            }
            
            // Maj7: root, M3, P5, M7
            if (quality === null && has(4) && has(5)) {
                var maj7Valid = [0, 4, 1, 5, 2, 3, 6]; // root, 3, 5, 7, 9, 13, #11
                var fit = checkFit(maj7Valid);
                if (fit === tpcs.length) {
                    quality = "maj7"; weight = 4;
                    if (has(3)) { quality = "maj13"; weight++; }
                    else if (has(2)) { quality = "maj9"; weight++; }
                    if (has(6)) ext += "♯11";
                }
            }
            
            // m7: root, m3, P5, m7
            if (quality === null && has(-3) && has(-2)) {
                var m7Valid = [0, -3, 1, -2, 2, 3, -1]; // root, b3, 5, b7, 9, 11, 4
                var fit = checkFit(m7Valid);
                if (fit === tpcs.length) {
                    quality = "m7"; weight = 4;
                    if (has(-6)) { quality = "m7♭5"; weight++; }
                    else if (has(3)) { quality = "m11"; weight++; }
                    else if (has(2)) { quality = "m9"; weight++; }
                }
            }
            
            // dim7: root, m3, d5, d7
            if (quality === null && has(-3) && has(-6) && has(-9)) {
                quality = "dim7"; weight = 5;
            }
            
            // m7b5 (half-dim): root, m3, d5, m7
            if (quality === null && has(-3) && has(-6) && has(-2)) {
                var hdValid = [0, -3, -6, -2];
                var fit = checkFit(hdValid);
                if (fit === tpcs.length) {
                    quality = "m7♭5"; weight = 4;
                }
            }

            // === ADD CHORDS (triad + 2nd, no 7th) ===
            if (quality === null) {
                if (has(4) && has(1) && has(2) && !has(5) && !has(-2)) { 
                    var addValid = [0, 4, 1, 2];
                    if (checkFit(addValid) === tpcs.length) {
                        quality = "add2"; weight = 3;
                    }
                }
                else if (has(-3) && has(1) && has(2) && !has(-2)) {
                    var maddValid = [0, -3, 1, 2];
                    if (checkFit(maddValid) === tpcs.length) {
                        quality = "madd2"; weight = 3;
                    }
                }
            }

            // === TRIADS ===
            if (quality === null) {
                // Major triad
                if (has(4) && has(1)) {
                    var majValid = [0, 4, 1];
                    if (checkFit(majValid) === tpcs.length) {
                        quality = ""; weight = 2;
                    }
                }
                // Minor triad
                if (quality === null && has(-3) && has(1)) {
                    var minValid = [0, -3, 1];
                    if (checkFit(minValid) === tpcs.length) {
                        quality = "m"; weight = 2;
                    }
                }
                // Diminished triad
                if (quality === null && has(-3) && has(-6)) {
                    var dimValid = [0, -3, -6];
                    if (checkFit(dimValid) === tpcs.length) {
                        quality = "dim"; weight = 2;
                    }
                }
                // Augmented triad
                if (quality === null && has(4) && has(8)) {
                    var augValid = [0, 4, 8];
                    if (checkFit(augValid) === tpcs.length) {
                        quality = "aug"; weight = 2;
                    }
                }
            }

            // === SUS CHORDS ===
            if (quality === null) {
                if (has(-1) && has(1) && !has(4) && !has(-3)) {
                    var sus4Valid = [0, -1, 1];
                    if (checkFit(sus4Valid) === tpcs.length) {
                        quality = "sus4"; weight = 1;
                    }
                }
                else if (has(2) && has(1) && !has(4) && !has(-3)) {
                    var sus2Valid = [0, 2, 1];
                    if (checkFit(sus2Valid) === tpcs.length) {
                        quality = "sus2"; weight = 1;
                    }
                }
            }

            if (quality !== null) {
                var label = getProperNoteName(root) + quality + ext;
                var isRootInChord = (tpcs.indexOf(root) !== -1);
                var isRootBass = (root === bassTPC);
                
                if (!isRootBass) label += "/" + getProperNoteName(bassTPC);
                
                candidates.push({
                    label: label, 
                    score: weight + (isRootBass ? 1 : 0), 
                    isSus: (quality.indexOf("sus") !== -1),
                    isRootBass: isRootBass
                });
            }
        }

        if (candidates.length === 0) return null;

        candidates.sort(function(a, b) {
            if (a.score !== b.score) return b.score - a.score;
            if (a.isSus !== b.isSus) return a.isSus ? 1 : -1;
            if (a.isRootBass !== b.isRootBass) return a.isRootBass ? -1 : 1;
            return 0;
        });

        return candidates[0].label;
    }

    // --- 4. MAIN RUN ---
    onRun: {
        if (!curScore) quit();
        if (curScore.selection.elements.length === 0) cmd("select-all");
        
        curScore.startCmd("Generate Pop Chords");
        var data = getGlobalGroups(curScore.selection);
        var cursor = curScore.newCursor();
        cursor.staffIdx = data.topStaff;
        cursor.rewind(0);

        var lastChordText = ""; 

        for (var j = 0; j < data.groups.length; j++) {
            var group = data.groups[j];
            while (cursor.segment && cursor.tick < group.tick) cursor.next();

            if (cursor.segment && cursor.tick === group.tick) {
                var currentChordText = identifyPopChord(group.notes);
                
                if (currentChordText && currentChordText !== lastChordText) {
                    var text = newElement(Element.STAFF_TEXT);
                    text.text = currentChordText;
                    
                    // Reverting to the font that worked
                    text.fontFace = "MuseJazz Text";
                    text.fontSize = 12;
                    text.fontWeight = 700;
                    text.placement = Placement.ABOVE;
                    
                    cursor.add(text);
                    lastChordText = currentChordText; 
                }
            }
        }
        curScore.endCmd();
        quit();
    }
}