import QtQuick
import MuseScore

MuseScore {
    title: "Pop and Jazz Chord Labeler"
    version: "1.0"
    description: "Adds pop and jazz chord analysis as Staff Text"
    categoryCode: "Analysis"
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

        for (var r = 0; r < tpcs.length; r++) {
            var root = tpcs[r];
            var deltas = tpcs.map(function(t) { return t - root; });
            var has = function(d) { return deltas.indexOf(d) !== -1; };

            var quality = null;
            var ext = "";
            var weight = 0;

            // Priority 1: Jazz Shells
            if (has(4) && has(-2)) { // Dom7
                quality = "7"; weight = 3;
                if (has(3)) { quality = "13"; weight++; }
                else if (has(2)) { quality = "9"; weight++; }
                if (has(6)) { ext = "♯11"; weight++; }
                if (has(-5)) { ext = "♭9"; weight++; }
                if (has(9)) { ext = "♯9"; weight++; }
            }
            else if (has(4) && has(5)) { // Maj7
                quality = "maj7"; weight = 3;
                if (has(3)) { quality = "maj13"; weight++; }
                else if (has(2)) { quality = "maj9"; weight++; }
                if (has(6)) { ext = "♯11"; weight++; }
            }
            else if (has(-3) && has(-2)) { // m7
                quality = "m7"; weight = 3;
                if (has(-6)) { quality = "m7♭5"; weight++; }
                else if (has(3)) { quality = "m11"; weight++; }
                else if (has(2)) { quality = "m9"; weight++; }
            }
            else if (has(-3) && has(-9)) { // dim7
                quality = "dim7"; weight = 4;
            }

            // Priority 2: Triads
            if (quality === null) {
                if (has(4) && (has(1) || deltas.length === 2)) { quality = ""; weight = 2; }
                else if (has(-3) && (has(1) || deltas.length === 2)) { quality = "m"; weight = 2; }
                else if (has(-3) && has(-6)) { quality = "dim"; weight = 2; }
                else if (has(4) && has(8)) { quality = "aug"; weight = 2; }
            }

            // Priority 3: Sus
            if (quality === null) {
                if (has(-1)) { quality = "sus4"; weight = 1; }
                else if (has(-2)) { quality = "sus2"; weight = 1; }
            }

            if (quality !== null) {
                var label = getProperNoteName(root) + quality + ext;
                if (root !== bassTPC) label += "/" + getProperNoteName(bassTPC);
                candidates.push({
                    label: label, 
                    score: weight + 1, 
                    isSus: (quality.indexOf("sus") !== -1),
                    isRootBass: (root === bassTPC)
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