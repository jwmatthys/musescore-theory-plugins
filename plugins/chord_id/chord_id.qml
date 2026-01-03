import QtQuick
import MuseScore

MuseScore {
    title: "Chord Identification"
    version: "4.0"
    description: "Identify chords across multiple staves and voices"
    categoryCode: "Proofreading"
    requiresScore: true

    // --- 1. HARVEST NOTES ACROSS ALL SELECTED STAVES ---
    function getGlobalGroups(selection) {
        var groups = {}; 
        var minStaff = 999;

        for (var i = 0; i < selection.elements.length; i++) {
            var el = selection.elements[i];
            if (el.type === Element.NOTE) {
                var chord = el.parent;
                var segment = chord.parent;
                if (segment && segment.type === Element.SEGMENT) {
                    var tick = segment.tick;
                    if (!groups[tick]) {
                        groups[tick] = { "notes": [], "tick": tick };
                    }
                    groups[tick].notes.push(el);
                    
                    // Track the top-most staff to place the label there
                    if (chord.staffIdx < minStaff) minStaff = chord.staffIdx;
                }
            }
        }
        
        var list = [];
        for (var t in groups) { list.push(groups[t]); }
        list.sort(function(a, b) { return a.tick - b.tick; });
        
        return { "groups": list, "topStaff": minStaff };
    }

    // --- 2. CHORD LOGIC (Same TPC Geometry) ---
    function identifyChord(chordNotes) {
        var tpcs = [];
        for (var i = 0; i < chordNotes.length; i++) {
            var tpc = chordNotes[i].tpc;
            if (tpcs.indexOf(tpc) === -1) tpcs.push(tpc);
        }
        if (tpcs.length < 3) return null;

        var formulas = {
            "1,4": "Major", "-3,1": "Minor", "4,8": "Aug", "-6,-3": "dim",
            "-2,1,4": "Dom7", "1,4,5": "Maj7", "-3,-2,1": "m7", "-9,-6,-3": "dim7", "-6,-3,-2": "half-dim7"
        };

        for (var r = 0; r < tpcs.length; r++) {
            var deltas = [];
            for (var n = 0; n < tpcs.length; n++) {
                if (r === n) continue;
                deltas.push(tpcs[n] - tpcs[r]);
            }
            deltas.sort(function(a, b){ return a - b; });
            var key = deltas.join(",");
            if (formulas[key]) return formulas[key];
        }
        return null;
    }

    onRun: {
        if (!curScore) { quit(); return; }

        // If nothing selected, select everything
        if (curScore.selection.elements.length === 0) {
            curScore.startCmd("Identify Chords: Full Score");
            cmd("select-all");
        } else {
            curScore.startCmd("Identify Chords: Selection");
        }

        // 1. Cleanup old labels
        var chordRegex = /^(Major|Minor|Aug|dim|Maj7|m7|dim7|half-dim7|Dom7)$/;
        for (var i = 0; i < curScore.selection.elements.length; i++) {
            var el = curScore.selection.elements[i];
            if (el.type === Element.STAFF_TEXT && chordRegex.test(el.text)) {
                removeElement(el);
            }
        }

        // 2. Gather data
        var data = getGlobalGroups(curScore.selection);
        var groups = data.groups;

        // 3. Process and apply labels to the TOP staff only
        var cursor = curScore.newCursor();
        cursor.staffIdx = data.topStaff;
        cursor.voice = 0;
        cursor.rewind(0);

        for (var j = 0; j < groups.length; j++) {
            var group = groups[j];

            // Fast-forward cursor to the chord's time position
            while (cursor.segment && cursor.tick < group.tick) {
                if (!cursor.next()) break;
            }

            if (cursor.segment && cursor.tick === group.tick) {
                var result = identifyChord(group.notes);
                if (result) {
                    var text = newElement(Element.STAFF_TEXT);
                    text.text = result;
                    text.placement = Placement.ABOVE;
                    cursor.add(text);
                }
            }
        }

        curScore.endCmd();
        quit();
    }
}