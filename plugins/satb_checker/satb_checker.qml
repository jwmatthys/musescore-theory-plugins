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
        
        // Check staff distribution
        var staffCounts = {};
        sorted.forEach(function(n) {
            if (!staffCounts[n.staffIdx]) staffCounts[n.staffIdx] = [];
            staffCounts[n.staffIdx].push(n);
        });
        
        var staffKeys = Object.keys(staffCounts).sort(function(a,b) { return a - b; });
        
        // Keyboard style: 3 notes in upper staff, 1 in lower (SAT/B)
        // Also check that the 3 notes share the same voice
        var isKeyboardStyle = false;
        if (staffKeys.length === 2 && 
            staffCounts[staffKeys[0]].length === 3 && 
            staffCounts[staffKeys[1]].length === 1) {
            var upperNotes = staffCounts[staffKeys[0]];
            var sameVoice = (upperNotes[0].voice === upperNotes[1].voice && 
                            upperNotes[1].voice === upperNotes[2].voice);
            isKeyboardStyle = sameVoice;
        }
        
        // Choral style: 2 notes in each staff, AND notes in each staff share the same voice
        var isChoralStyle = false;
        if (staffKeys.length === 2 && 
            staffCounts[staffKeys[0]].length === 2 && 
            staffCounts[staffKeys[1]].length === 2) {
            var upperNotes = staffCounts[staffKeys[0]];
            var lowerNotes = staffCounts[staffKeys[1]];
            var upperSameVoice = (upperNotes[0].voice === upperNotes[1].voice);
            var lowerSameVoice = (lowerNotes[0].voice === lowerNotes[1].voice);
            isChoralStyle = upperSameVoice && lowerSameVoice;
        }
        
        if (isKeyboardStyle) {
            return {
                style: "keyboard",
                upperStaff: parseInt(staffKeys[0]),
                lowerStaff: parseInt(staffKeys[1]),
                bassVoice: { staffIdx: sorted[0].staffIdx, voice: sorted[0].voice }
            };
        }
        
        if (isChoralStyle) {
            return {
                style: "choral",
                upperStaff: parseInt(staffKeys[0]),
                lowerStaff: parseInt(staffKeys[1])
            };
        }
        
        // Open score or other arrangement: track each voice individually
        return {
            style: "open",
            B: { staffIdx: sorted[0].staffIdx, voice: sorted[0].voice },
            T: { staffIdx: sorted[1].staffIdx, voice: sorted[1].voice },
            A: { staffIdx: sorted[2].staffIdx, voice: sorted[2].voice },
            S: { staffIdx: sorted[3].staffIdx, voice: sorted[3].voice }
        };
    }

    function getNotesForVoices(tickNotes, voiceLayout) {
        if (voiceLayout.style === "keyboard") {
            // Keyboard style: get all notes from upper staff, sort by pitch, assign S/A/T
            var upperNotes = tickNotes.filter(function(n) {
                return n.staffIdx === voiceLayout.upperStaff;
            }).sort(function(a, b) { return a.pitch - b.pitch; });
            
            var bassNote = tickNotes.find(function(n) {
                return n.staffIdx === voiceLayout.bassVoice.staffIdx && 
                       n.voice === voiceLayout.bassVoice.voice;
            });
            
            if (upperNotes.length === 3 && bassNote) {
                return {
                    B: bassNote,
                    T: upperNotes[0],
                    A: upperNotes[1],
                    S: upperNotes[2]
                };
            }
            return null;
        } 
        
        if (voiceLayout.style === "choral") {
            // Choral style: 2 notes per staff, assign by pitch within each staff
            var upperNotes = tickNotes.filter(function(n) {
                return n.staffIdx === voiceLayout.upperStaff;
            }).sort(function(a, b) { return a.pitch - b.pitch; });
            
            var lowerNotes = tickNotes.filter(function(n) {
                return n.staffIdx === voiceLayout.lowerStaff;
            }).sort(function(a, b) { return a.pitch - b.pitch; });
            
            if (upperNotes.length === 2 && lowerNotes.length === 2) {
                return {
                    B: lowerNotes[0],
                    T: lowerNotes[1],
                    A: upperNotes[0],
                    S: upperNotes[1]
                };
            }
            return null;
        }
        
        // Open score: find each voice by staffIdx and voice
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

    function hasAllFourVoices(tickNotes, voiceLayout) {
        if (voiceLayout.style === "keyboard") {
            var upperCount = tickNotes.filter(function(n) {
                return n.staffIdx === voiceLayout.upperStaff;
            }).length;
            var bassNote = tickNotes.find(function(n) {
                return n.staffIdx === voiceLayout.bassVoice.staffIdx && 
                       n.voice === voiceLayout.bassVoice.voice;
            });
            return upperCount === 3 && bassNote;
        }
        
        if (voiceLayout.style === "choral") {
            var upperCount = tickNotes.filter(function(n) {
                return n.staffIdx === voiceLayout.upperStaff;
            }).length;
            var lowerCount = tickNotes.filter(function(n) {
                return n.staffIdx === voiceLayout.lowerStaff;
            }).length;
            return upperCount === 2 && lowerCount === 2;
        }
        
        // Open score
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

    function describeVoiceAssignment(voiceLayout) {
        if (voiceLayout.style === "keyboard") {
            return "Keyboard style (SAT/B)";
        }
        
        if (voiceLayout.style === "choral") {
            return "Choral style (SA/TB)";
        }
        
        // Open score
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
        } else if (staffKeys.length === 4) {
            return "Open score (4 staves)";
        }
        
        return staffKeys.length + " staves";
    }

    function tpcToKeyName(tpc) {
        var names = {
            6:"Abb", 7:"Ebb", 8:"Bb", 9:"Db", 10:"Ab", 11:"Eb", 12:"Bb", 
            13:"F", 14:"C", 15:"G", 16:"D", 17:"A", 18:"E", 19:"B", 
            20:"F#", 21:"C#", 22:"G#", 23:"D#", 24:"A#", 25:"E#", 26:"B#", 
            27:"Fx", 28:"Cx", 29:"Gx", 30:"Dx", 31:"Ax"
        };
        return names[tpc] || ("TPC:" + tpc);
    }

    function addStatisticsFooter(voiceLayout, tonicTPC, mode, lastStaff) {
        var voiceDesc = describeVoiceAssignment(voiceLayout);
        var keyName = tpcToKeyName(tonicTPC) + " " + mode;
        
        var cursor = curScore.newCursor();
        cursor.rewind(1); 
        cursor.staffIdx = lastStaff; 
        
        var footer = newElement(Element.STAFF_TEXT);
        footer.text = "--- SATB ANALYSIS ---\n" + keyName + "\n" + voiceDesc;
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

        // Determine tonic and mode using 3-stage approach
        var keyResult = Harmony.determineKeyAndMode(sortedTicks, tickGroups, curScore, Element, newElement);
        var tonicTPC = keyResult.tonic;
        var mode = keyResult.mode;

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
        addStatisticsFooter(voiceLayout, tonicTPC, mode, lastStaff);
        
        curScore.endCmd(); 
        quit();
    }
}
