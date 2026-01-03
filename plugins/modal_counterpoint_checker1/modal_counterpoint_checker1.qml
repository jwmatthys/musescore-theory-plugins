import QtQuick
import MuseScore

MuseScore {
    title: "Counterpoint Checker: 1st Species"
    version: "3.6"
    description: "Strict 1st Species rules (16th Century Counterpoint)"
    categoryCode: "Proofreading"
    requiresScore: true

    // --- CONFIGURATION ---
    property bool checkDissonance: true 
    property bool checkDirect: true 
    property bool checkStartEnd: true
    property bool checkUnison: true
    property bool checkSuccessiveImperfect: true
    property bool checkVoiceCrossing: true
    property bool checkVoiceOverlap: true
    property bool checkClausulaVera: true 
    property bool checkLeadingTone: false 
    property bool checkLeapLimit: true // NEW: Max 2 consecutive leaps
    
// --- ACCESSIBLE CONFIGURATION (WCAG 2.1 AA Compliant) ---
    readonly property string colorError: "#b30000"   // Dark Red (High contrast for errors)
    readonly property string colorWarning: "#855c00" // Dark Ochre (Better than bright orange on white)
    readonly property string colorDiss: "#6a1b9a"    // Deep Purple (Clearly distinguishable from red)
    readonly property string colorStats: "#004a99"   // Deep Blue (Professional and highly legible)

    function getNotesGroupedByTick(selection) {
        var ticks = {}; 
        for (var i = 0; i < selection.elements.length; i++) {
            var el = selection.elements[i];
            if (el.type === Element.NOTE) {
                var tick = el.parent.parent.tick;
                if (!ticks[tick]) { ticks[tick] = []; }
                ticks[tick].push(el);
            }
        }
        return ticks;
    }

    onRun: {
        if (!curScore) { quit(); return; }
        curScore.startCmd("Counterpoint Analysis");
        if (curScore.selection.elements.length === 0) { cmd("select-all"); }

        var tickGroups = getNotesGroupedByTick(curScore.selection);
        var sortedTicks = Object.keys(tickGroups).map(Number).sort(function(a, b) { return a - b; });
        if (sortedTicks.length < 2) { quit(); return; }

        var firstChord = tickGroups[sortedTicks[0]];
        firstChord.sort(function(a, b) { return b.pitch - a.pitch; });
        var trebleID = firstChord[0].voice;
        var trebleStaff = firstChord[0].staffIdx;
        var bassID = firstChord[firstChord.length - 1].voice;
        var bassStaff = firstChord[firstChord.length - 1].staffIdx;

        var sequence = [];
        var perfectCount = 0;

        for (var i = 0; i < sortedTicks.length; i++) {
            var notes = tickGroups[sortedTicks[i]];
            var tNote = null, bNote = null;
            for (var k = 0; k < notes.length; k++) {
                if (notes[k].voice === trebleID && notes[k].staffIdx === trebleStaff) tNote = notes[k];
                if (notes[k].voice === bassID && notes[k].staffIdx === bassStaff) bNote = notes[k];
            }

            if (tNote && bNote) {
                var semitones = tNote.pitch - bNote.pitch;
                var genericSize = (28 + tNote.tpc - bNote.tpc) % 7; 
                var sizeMap = {0:1, 1:5, 2:2, 3:6, 4:3, 5:7, 6:4};
                var size = (genericSize === 0 && semitones > 2) ? 8 : sizeMap[genericSize];
                
                var consSemitones = [0, 3, 4, 7, 8, 9, 12, 15, 16, 19, 20, 21];
                var isConsonant = (consSemitones.indexOf(semitones % 12) !== -1) && (size !== 4);
                
                var diff = tNote.tpc - bNote.tpc;
                var quality = (diff >= -1 && diff <= 1) ? "P" : (diff >= 2 && diff <= 5) ? "M" : "m";

                sequence.push({ 
                    "tick": sortedTicks[i], "treble": tNote, "bass": bNote, 
                    "size": size, "quality": quality, "semitones": semitones, "isConsonant": isConsonant 
                });
                if ([1, 5, 8].indexOf(size) !== -1 && isConsonant) perfectCount++;
            }
        }

        var imperfectRun = 0;
        var tLeapCount = 0;
        var bLeapCount = 0;
        var consecutive3rds = 0; // Independent counter for 3rds
        var consecutive6ths = 0; // Independent counter for 6ths

        // NEW: Find the lowest staff in the selection
        var lastStaff = curScore.selection.startStaff;
        if (curScore.selection.endStaff > lastStaff) {
            lastStaff = curScore.selection.endStaff - 1; 
        }

        var cursor = curScore.newCursor();
        var anchorStaff = curScore.selection.startStaff;

        for (var j = 0; j < sequence.length; j++) {
            var curr = sequence[j];
            var errors = [], warnings = [], diss = [];
            var isParallel = false;

            // 1. HARMONIC CHECKS
            if (!curr.isConsonant) { diss.push("Diss."); curr.treble.color = curr.bass.color = colorDiss; }
            if (checkUnison && curr.size === 1 && j > 0 && j < sequence.length - 1) errors.push("Mid-Unison");
            if (checkVoiceCrossing && curr.treble.pitch < curr.bass.pitch) errors.push("Voice Crossing");

            // 2. CADENCE & RESOLUTION
            if (j === sequence.length - 2) {
                var next = sequence[j+1];
                if (checkClausulaVera) {
                    var okCV = (curr.size === 6 && curr.quality === "M" && next.size === 8) ||
                               (curr.size === 3 && curr.quality === "m");
                    if (!okCV) warnings.push("Improper\nClausula Vera");
                }
                if (checkLeadingTone) {
                    var checkLT = function(vCurr, vNext, label) {
                        var intervalToFinal = vNext.pitch - vCurr.pitch;
                        if (intervalToFinal === 1 || intervalToFinal === 2) {
                            if (intervalToFinal !== 1) warnings.push("Raise Leading Tone?");
                            if (vNext.pitch - vCurr.pitch !== 1) errors.push(label + " LT must resolve Up");
                        }
                    };
                    checkLT(curr.treble, next.treble, "Treble");
                    checkLT(curr.bass, next.bass, "Bass");
                }
            }

            // 3. MELODIC MOVEMENT (Successive Leaps)
            if (j > 0) {
                var prev = sequence[j - 1];
                var tMove = Math.abs(curr.treble.pitch - prev.treble.pitch);
                var bMove = Math.abs(curr.bass.pitch - prev.bass.pitch);

                if (checkLeapLimit) {
                    // Treble Leap Tracking
                    if (tMove > 2) tLeapCount++; else tLeapCount = 0;
                    if (tLeapCount >= 2 && j > 1) {
                         // Check the *current* leap that makes it a string of 2 intervals (3 notes)
                         if (tLeapCount > 2) errors.push("Treble: Too Many Leaps");
                    }
                    // Bass Leap Tracking
                    if (bMove > 2) bLeapCount++; else bLeapCount = 0;
                    if (bLeapCount > 2) errors.push("Bass: Too Many Leaps");
                }

                // Parallels and Overlap
                if (curr.size === prev.size && [1, 5, 8].indexOf(curr.size) !== -1 && (curr.treble.pitch - prev.treble.pitch) !== 0) {
                    isParallel = true;
                    curr.treble.color = curr.bass.color = prev.treble.color = prev.bass.color = colorError;
                } else if (checkDirect && [5, 8].indexOf(curr.size) !== -1 && ((curr.treble.pitch - prev.treble.pitch) * (curr.bass.pitch - prev.bass.pitch) > 0)) {
                    errors.push("Similar to " + curr.size);
                }
                if (checkVoiceOverlap) {
                    if (curr.bass.pitch > prev.treble.pitch) errors.push("Voice Overlap (B)");
                    if (curr.treble.pitch < prev.bass.pitch) errors.push("Voice Overlap (T)");
                }
            }

            // 4. INDEPENDENCE (REVISED LOGIC)
            if (checkSuccessiveImperfect) {
                // Handle 3rds
                if (curr.size === 3) {
                    consecutive3rds++;
                    if (consecutive3rds > 3) warnings.push("Too many\nconsecutive 3rds");
                } else {
                    consecutive3rds = 0;
                }

                // Handle 6ths
                if (curr.size === 6) {
                    consecutive6ths++;
                    if (consecutive6ths > 3) warnings.push("Too many\nconsecutive 6ths");
                } else {
                    consecutive6ths = 0;
                }
            }

            if (checkStartEnd && j === 0) {
                if ([1, 5, 8].indexOf(curr.size) === -1) {
                    curr.treble.color = curr.bass.color = colorError;
                    errors.push("Must Start Perfect");
                }
            }
            if (checkStartEnd && j === sequence.length - 1) {
                if ([1, 5, 8].indexOf(curr.size) === -1) {
                    curr.treble.color = curr.bass.color = colorError;
                    errors.push("Must End Perfect");
                }
            }

            // 5. RENDER TEXT
            cursor.rewind(0); cursor.staffIdx = anchorStaff;
            while (cursor.segment && cursor.tick < curr.tick) { cursor.next(); }
            if (isParallel) {
                var pText = newElement(Element.STAFF_TEXT);
                pText.text = "Parallel P" + curr.size; pText.color = colorError;
                cursor.add(pText);
            }
            var allIssues = errors.concat(diss).concat(warnings);
            if (allIssues.length > 0) {
                var text = newElement(Element.STAFF_TEXT);
                text.text = allIssues.join("\n");
                text.color = errors.length > 0 ? colorError : (diss.length > 0 ? colorDiss : colorWarning);
                cursor.add(text);
            }
        }
        
        cursor.rewind(1); 
        cursor.staffIdx = lastStaff; 

        // 2. Precisely align with the first tick of the analysis
        if (sortedTicks.length > 0) {
            while (cursor.segment && cursor.tick < sortedTicks[0]) {
                cursor.next();
            }
        }

        var footer = newElement(Element.STAFF_TEXT);
        var perfRatio = Math.round((perfectCount / sequence.length) * 100);
        footer.text = "--- ANALYSIS ---\nIntervals: " + sequence.length + " | Perfect: " + perfRatio + "%";
        footer.color = colorStats;
        footer.placement = Placement.BELOW;
        footer.offsetX = -5;
        cursor.add(footer);

        curScore.endCmd(); quit();
    }
}