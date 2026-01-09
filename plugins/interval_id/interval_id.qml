import QtQuick
import MuseScore

MuseScore {
    title: "Interval Identification"
    version: "1.2"
    description: "Identify intervals between the highest and lowest notes across all selected staves"
    categoryCode: "Analysis"
    thumbnailName: "thumbnail_interval.png"
    requiresScore: true

    /**
     * Gathers all notes from the selection and groups them by tick.
     */
    function getNotesGroupedByTick(selection) {
        var ticks = {}; 

        for (var i = 0; i < selection.elements.length; i++) {
            var el = selection.elements[i];
            if (el.type === Element.NOTE) {
                // Navigate up from Note to Chord to Segment to get the tick
                var tick = el.parent.parent.tick;
                if (!ticks[tick]) {
                    ticks[tick] = [];
                }
                ticks[tick].push(el);
            }
        }
        return ticks;
    }

    /**
     * Original interval logic based on TPC (Tonal Pitch Class)
     */
    function checkInterval(n1, n2) {
        var note1 = n1;
        var note2 = n2;
        // Ensure note1 is the lower pitch
        if (note2.pitch < note1.pitch) {
            note1 = n2;
            note2 = n1;
        }

        var diff = note2.tpc - note1.tpc;
        var quality = "";
        if (diff >= -1 && diff <= 1) quality = "P";
        else if (diff >= 2 && diff <= 5) quality = "M";
        else if (diff >= 6 && diff <= 12) quality = "+";
        else if (diff >= 13 && diff <= 19) quality = "++";
        else if (diff <= -2 && diff >= -5) quality = "m";
        else if (diff <= -6 && diff >= -12) quality = "d";
        else if (diff <= -13 && diff >= -19) quality = "dd";
        else quality = "?";

        var circlediff = (28 + note2.tpc - note1.tpc) % 7;
        var sizes = {1:5, 2:2, 3:6, 4:3, 5:7, 6:4};
        var size = (circlediff === 0) ? (note2.pitch - note1.pitch > 2 ? 8 : 1) : sizes[circlediff];

        return quality + size;
    }

    onRun: {
        if (!curScore) { quit(); return; }

        if (curScore.selection.elements.length === 0) {
            cmd("select-all");
        }

        // Start command for undo history
        curScore.startCmd("Interval Identification");

        // 1. CLEANUP existing labels in the selection
        var intervalRegex = /^(m|M|P|d|\+|\+\+|dd)\d+$/;
        for (var i = curScore.selection.elements.length - 1; i >= 0; i--) {
            var el = curScore.selection.elements[i];
            if (el.type === Element.STAFF_TEXT && intervalRegex.test(el.text)) {
                removeElement(el);
            }
        }

        // 2. GATHER and SORT
        var tickGroups = getNotesGroupedByTick(curScore.selection);
        var sortedTicks = Object.keys(tickGroups).map(Number).sort(function(a, b) { return a - b; });

        // 3. PROCESS
        var cursor = curScore.newCursor();
        // Place text on the top-most staff of the selection
        var anchorStaff = curScore.selection.startStaff;

        for (var j = 0; j < sortedTicks.length; j++) {
            var currentTick = sortedTicks[j];
            var notesAtTick = tickGroups[currentTick];

            // Only process if there are at least 2 notes at this moment
            if (notesAtTick.length >= 2) {
                // Sort notes by pitch to find the outermost notes
                notesAtTick.sort(function(a, b) {
                    return a.pitch - b.pitch;
                });

                var bottomNote = notesAtTick[0];
                var topNote = notesAtTick[notesAtTick.length - 1];

                // Move cursor to the anchor staff and correct tick
                cursor.rewind(0); // Rewind to start of selection
                cursor.staffIdx = anchorStaff;
                cursor.voice = 0;

                while (cursor.segment && cursor.tick < currentTick) {
                    if (!cursor.next()) break;
                }

                if (cursor.segment && cursor.tick === currentTick) {
                    var text = newElement(Element.STAFF_TEXT);
                    text.text = checkInterval(bottomNote, topNote);
                    text.placement = Placement.ABOVE;
                    text.autoplace = true;
                    cursor.add(text);
                }
            }
        }

        curScore.endCmd();
        quit();
    }
}