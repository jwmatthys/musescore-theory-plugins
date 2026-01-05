import QtQuick
import MuseScore
import "HarmonyAnalysis.js" as Harmony
import "SATBErrorChecking.js" as Errors

MuseScore {
    title: "SATB Part-Writing Checker"
    description: "Checks SATB part-writing for range, spacing, parallels, and voice leading"
    version: "1.0"
    categoryCode: "Proofreading"
    requiresScore: true

    readonly property string colorError: "#b30000" 
    readonly property string colorStats: "#004a99"

    function identifyVoiceLayout(firstChordNotes) {
        // Sort notes by pitch, low to high
        var sorted = firstChordNotes.slice().sort(function(a, b) { 
            return a.pitch - b.pitch; 
        });
        
        if (sorted.length !== 4) {
            console.log("Warning: First chord does not have exactly 4 notes");
            return null;
        }
        
        // Check if this is keyboard style (3 notes in one staff, 1 in another)
        var staffCounts = {};
        sorted.forEach(function(n) {
            if (!staffCounts[n.staffIdx]) staffCounts[n.staffIdx] = [];
            staffCounts[n.staffIdx].push(n);
        });
        
        var staffKeys = Object.keys(staffCounts).sort(function(a,b) { return a - b; });
        var isKeyboardStyle = (staffKeys.length === 2 && 
                               staffCounts[staffKeys[0]].length === 3 && 
                               staffCounts[staffKeys[1]].length === 1);
        
        // For keyboard style, we track by staff only (not voice) for the upper staff
        // and assign S/A/T by pitch order within that staff
        if (isKeyboardStyle) {
            return {
                isKeyboardStyle: true,
                upperStaff: parseInt(staffKeys[0]),
                lowerStaff: parseInt(staffKeys[1]),
                bassVoice: { staffIdx: sorted[0].staffIdx, voice: sorted[0].voice }
            };
        }
        
        // For non-keyboard style, track each voice individually
        return {
            isKeyboardStyle: false,
            B: { staffIdx: sorted[0].staffIdx, voice: sorted[0].voice },
            T: { staffIdx: sorted[1].staffIdx, voice: sorted[1].voice },
            A: { staffIdx: sorted[2].staffIdx, voice: sorted[2].voice },
            S: { staffIdx: sorted[3].staffIdx, voice: sorted[3].voice }
        };
    }

    function getNotesForVoices(tickNotes, voiceLayout) {
        if (voiceLayout.isKeyboardStyle) {
            // Keyboard style: get all notes from upper staff, sort by pitch, assign S/A/T
            var upperNotes = tickNotes.filter(function(n) {
                return n.staffIdx === voiceLayout.upperStaff;
            }).sort(function(a, b) { return a.pitch - b.pitch; });
            
            var bassNote = tickNotes.find(function(n) {
                return n.staffIdx === voiceLayout.bassVoice.staffIdx && 
                       n.voice === voiceLayout.bassVoice.voice;
            });
            
            if (upperNotes.length === 3 && bassNote) {
                // Return as object with voice labels for proper identification
                return {
                    B: bassNote,
                    T: upperNotes[0],
                    A: upperNotes[1],
                    S: upperNotes[2]
                };
            }
            return null;
        } else {
            // Non-keyboard style: find each voice by staffIdx and voice
            var result = {};
            var voiceLabels = ['S', 'A', 'T', 'B'];
            
            voiceLabels.forEach(function(label) {
                var voiceID = voiceLayout[label];
                result[label] = tickNotes.find(function(n) {
                    return n.staffIdx === voiceID.staffIdx && n.voice === voiceID.voice;
                }) || null;
            });
            
            return result;
        }
    }

    function hasAllFourVoices(tickNotes, voiceLayout) {
        var notes = getNotesForVoices(tickNotes, voiceLayout);
        if (!notes) return false;
        return notes.S && notes.A && notes.T && notes.B;
    }

    function notesObjToArray(notesObj) {
        // Convert {S, A, T, B} object to array for compatibility
        if (!notesObj) return [];
        return [notesObj.S, notesObj.A, notesObj.T, notesObj.B].filter(function(n) { return n; });
    }

    function addErrorLabels(tick, errors) {
        if (errors.length === 0) return;
        var outCursor = curScore.newCursor(); 
        outCursor.rewindToTick(tick);
        var text = newElement(Element.STAFF_TEXT);
        text.text = [...new Set(errors)].join("\n");
        text.color = colorError;
        outCursor.add(text);
    }

    function calculateStatistics(analyzedTicks, tickGroups, voiceLayout) {
        var totalIntervals = 0, perfectCount = 0;
        
        analyzedTicks.forEach(function(tick) {
            var notesObj = getNotesForVoices(tickGroups[tick], voiceLayout);
            var notes = notesObjToArray(notesObj);
            if (notes.length >= 2) {
                for (var x = 0; x < notes.length; x++) {
                    for (var y = x + 1; y < notes.length; y++) {
                        totalIntervals++;
                        var low = (notes[x].pitch < notes[y].pitch) ? notes[x] : notes[y];
                        var high = (notes[x].pitch < notes[y].pitch) ? notes[y] : notes[x];
                        if (Errors.getIntervalType(low, high)) perfectCount++;
                    }
                }
            }
        });
        return { total: totalIntervals, perfect: perfectCount };
    }

    function describeVoiceAssignment(voiceLayout) {
        if (voiceLayout.isKeyboardStyle) {
            return "Keyboard style (SAT/B)";
        }
        
        var voiceLabels = ['S', 'A', 'T', 'B'];
        var staffCounts = {};
        
        voiceLabels.forEach(function(label) {
            var key = voiceLayout[label].staffIdx;
            if (!staffCounts[key]) staffCounts[key] = [];
            staffCounts[key].push(label);
        });
        
        var staffKeys = Object.keys(staffCounts).sort(function(a,b) { return a - b; });
        
        if (staffKeys.length === 1) {
            return "All voices on staff " + staffKeys[0];
        } else if (staffKeys.length === 2) {
            var upper = staffCounts[staffKeys[0]].join("");
            var lower = staffCounts[staffKeys[1]].join("");
            if (upper === "SA" && lower === "TB") {
                return "Choral style (SA/TB)";
            } else {
                return upper + "/" + lower;
            }
        }
        return staffKeys.length + " staves";
    }

    function addStatisticsFooter(analyzedTicks, tickGroups, voiceLayout, lastStaff) {
        var stats = calculateStatistics(analyzedTicks, tickGroups, voiceLayout);
        var perfRatio = (stats.total > 0) ? Math.round((stats.perfect / stats.total) * 100) : 0;
        var voiceDesc = describeVoiceAssignment(voiceLayout);
        
        var cursor = curScore.newCursor();
        cursor.rewind(1); 
        cursor.staffIdx = lastStaff; 
        
        var footer = newElement(Element.STAFF_TEXT);
        footer.text = "--- SATB ANALYSIS ---\n" + voiceDesc + 
                     "\nChords: " + analyzedTicks.length + " | Perfect: " + perfRatio + "%";
        footer.color = colorStats; 
        footer.placement = Placement.BELOW;
        cursor.add(footer);
    }

    onRun: {
        if (!curScore) { quit(); return; }
        curScore.startCmd("SATB Part-Writing Analysis");
        if (curScore.selection.elements.length === 0) { cmd("select-all"); }

        // Collect notes by tick
        var tickGroups = {};
        curScore.selection.elements.forEach(function(el) {
            if (el && el.type === Element.NOTE && el.parent && el.parent.parent) {
                var tick = el.parent.parent.tick;
                if (!tickGroups[tick]) tickGroups[tick] = [];
                tickGroups[tick].push(el);
            }
        });

        var lastStaff = curScore.selection.endStaff > curScore.selection.startStaff ? 
                       curScore.selection.endStaff - 1 : curScore.selection.startStaff;
        var sortedTicks = Object.keys(tickGroups).map(Number).sort(function(a,b) { return a - b; });
        if (sortedTicks.length === 0) { quit(); return; }

        // Identify voice layout from first chord (must have 4 notes)
        var voiceLayout = identifyVoiceLayout(tickGroups[sortedTicks[0]]);
        if (!voiceLayout) {
            console.log("Error: Could not identify 4 voices from first chord");
            curScore.endCmd();
            quit();
            return;
        }

        // Determine tonic and mode
        var tonicTPC = Harmony.determineTonic(sortedTicks, tickGroups, curScore, Element);
        var mode = Harmony.determineMode(sortedTicks, curScore, Element);

        // Filter to only ticks with all 4 voices
        var analyzedTicks = sortedTicks.filter(function(tick) {
            return hasAllFourVoices(tickGroups[tick], voiceLayout);
        });

        // Main check loop
        for (var j = 0; j < analyzedTicks.length; j++) {
            var tick = analyzedTicks[j];
            var notesObj = getNotesForVoices(tickGroups[tick], voiceLayout);
            var notes = notesObjToArray(notesObj);
            
            // Find next tick with all 4 voices
            var nextNotesObj = null;
            if (j + 1 < analyzedTicks.length) {
                nextNotesObj = getNotesForVoices(tickGroups[analyzedTicks[j + 1]], voiceLayout);
            }

            // Get roman numeral at this tick
            var rn = "";
            var cursor = curScore.newCursor(); 
            cursor.rewindToTick(tick);
            if (cursor.segment) {
                cursor.segment.annotations.forEach(function(ann) {
                    if (ann.type === Element.HARMONY) rn = ann.text;
                });
            }

            var hData = Harmony.getChordData(rn, tonicTPC, mode);
            var errors = Errors.checkTickErrors(notes, notesObj, nextNotesObj, rn, hData, voiceLayout, mode, tonicTPC);
            addErrorLabels(tick, errors);
        }

        // Add statistics
        addStatisticsFooter(analyzedTicks, tickGroups, voiceLayout, lastStaff);
        
        curScore.endCmd(); 
        quit();
    }
}
