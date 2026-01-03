import QtQuick
import MuseScore

MuseScore {
    title: "Tonal Counterpoint Species 2 Checker"
    description: "Checks two-part species 2 counterpoint with passing tones"
    version: "1.0"
    categoryCode: "Proofreading"
    requiresScore: true

    readonly property string colorError: "#b30000" 
    readonly property string colorDiss: "#6a1b9a"  
    readonly property string colorStats: "#004a99"

    readonly property var chordMap: {
        "I":     [0, 1, 4],      "III":   [4, 5, 8], 
        "IV":    [-1, 0, 3],     "V":     [1, 2, 5],  "VI":  [-4, -3, 0], "VII": [-2, -1, 1],
        "i":     [0, 1, -3],     "ii":    [2, 3, -1], "iii": [4, 5, 1], 
        "iv":    [-1, 0, -4],    "v":     [1, 2, -2], "vi":  [3, 4, 0],
        "iio":   [2, -4, -1],    "viio":  [-1, 2, 5],
        "I7":    [0, 1, 4, 5],   "III7":  [-3, -2, 1, 2],  "IV7":   [-1, 0, 3, 4], "VI7":   [-4, -3, 0, 1], "VII7": [-2, -1, 2, 3],
        "i7":    [0, 1, -3, -2], "ii7":   [2, 3, -1, 0], "iii7":  [4, 5, 1, 2],  "iv7":   [-1, 0, -4, -3], "vi7":   [3, 4, 0, 1],
        "V7":    [1, 2, 5, -1],  "viio7": [2, -1, 5, -4], "vii07": [2, -1, 5, 3],  "ii07":  [2, -4, -1, 0],
        "It6":   [0, 0, 6, -4],  "Fr65":    [0, 2, 6, -4],   "Ger65":   [0, -3, 6, -4], "N6":     [-5, -4, -1],
        "It":    [0, 0, 6, -4],  "Fr":    [0, 2, 6, -4],   "Ger":   [0, -3, 6, -4], "N":     [-5, -4, -1], "Cad": [1, 0, 4]
    }

    // --- HELPER FUNCTIONS ---

    function tpcToName(tpc) {
        var names = {6:"Abb", 7:"Ebb", 8:"Gb", 9:"Db", 10:"Ab", 11:"Eb", 12:"Bb", 13:"F", 14:"C", 15:"G", 16:"D", 17:"A", 18:"E", 19:"B", 20:"F#", 21:"C#", 22:"G#", 23:"D#", 24:"A#", 25:"E#", 26:"B#", 27:"Fx", 28:"Cx", 29:"Gx", 30:"Dx", 31:"Ax"};
        return names[tpc] || ("TPC:" + tpc);
    }

    function getIntervalType(bass, sop) {
        if (!bass || !sop) return null;
        var tpcDist = sop.tpc - bass.tpc;
        var semitones = Math.abs(sop.pitch - bass.pitch) % 12;
        if (tpcDist === 0 && semitones === 0) return "P8";
        if (tpcDist === 1 && semitones === 7) return "P5";
        return null;
    }

    function findNoteInSameVoice(sourceNote, nextTickNotes) {
        if (!sourceNote) return null;
        for (var i = 0; i < nextTickNotes.length; i++) {
            if (nextTickNotes[i].staffIdx === sourceNote.staffIdx && nextTickNotes[i].voice === sourceNote.voice) return nextTickNotes[i];
        }
        return null;
    }

    function getChordData(rn, tonicTPC) {
        if (!rn || rn === "") return { tones: [], tendTones: [null, null] };

        var parts = rn.split('/');
        var primaryPart = parts[0].replace("ø", "0");
        var targetPart = parts.length > 1 ? parts[1].replace("ø", "0") : null;

        var localTonic = tonicTPC; 
        if (targetPart) {
            var targetData = getChordData(targetPart, tonicTPC);
            if (targetData.tones.length > 0) {
                if (targetPart.toLowerCase().indexOf("viio") !== -1 || targetPart.toLowerCase().indexOf("vii0") !== -1) {
                    localTonic = targetData.tones[2];
                }
                else if (targetPart.match(/^(It|Fr|Ger)/i)) {
                    localTonic = targetData.tones[3];
                }
                else {
                    localTonic = targetData.tones[0];
                }
            }
        }

        var lookup = primaryPart;
        var isSeventh = lookup.match(/7|65|43|42/) !== null;
        var baseRN = lookup.replace(/[765432]/g, ''); 
        var searchKey = null;

        if (chordMap[lookup]) {
            searchKey = lookup;
        } else if (isSeventh && chordMap[baseRN + "7"]) {
            searchKey = baseRN + "7";
        } else if (chordMap[baseRN]) {
            searchKey = baseRN;
        } else {
            var capitalized = baseRN.charAt(0).toUpperCase() + baseRN.slice(1);
            if (chordMap[capitalized]) searchKey = capitalized;
        }

        var offsets = chordMap[searchKey];
        if (!offsets) return { tones: [], tendTones: [null, null] };
        
        var tones = offsets.map(o => localTonic + o);
        var tendTones = [null, null];
        var upperBase = baseRN.toUpperCase();

        if (upperBase === "V" || upperBase === "VIIO" || upperBase === "VII0") {
            tendTones[0] = tones[2]; 
            if (tones.length === 4) tendTones[1] = tones[3]; 
        } 
        return { tones: tones, tendTones: tendTones };
    }

    // --- SPECIES 2 SPECIFIC FUNCTIONS ---

    function identifyBassOnsets(sortedTicks, tickGroups, bassID) {
        var bassOnsets = [];
        var lastBassTick = null;
        
        for (var i = 0; i < sortedTicks.length; i++) {
            var tick = sortedTicks[i];
            var notes = tickGroups[tick];
            var bassNote = notes.find(n => n.staffIdx === bassID.staffIdx && n.voice === bassID.voice);
            
            if (bassNote) {
                if (lastBassTick === null) {
                    bassOnsets.push(tick);
                    lastBassTick = tick;
                } else {
                    var lastBassNote = tickGroups[lastBassTick].find(n => 
                        n.staffIdx === bassID.staffIdx && n.voice === bassID.voice);
                    if (!lastBassNote || bassNote.pitch !== lastBassNote.pitch || 
                        bassNote.tpc !== lastBassNote.tpc) {
                        bassOnsets.push(tick);
                        lastBassTick = tick;
                    }
                }
            }
        }
        return bassOnsets;
    }

    function getCurrentHarmonyContext(tick, bassOnsets, tickGroups, tonicTPC) {
        var contextTick = null;
        for (var i = bassOnsets.length - 1; i >= 0; i--) {
            if (bassOnsets[i] <= tick) {
                contextTick = bassOnsets[i];
                break;
            }
        }
        
        if (contextTick === null) return { rn: "", hData: getChordData("", tonicTPC) };
        
        var cursor = curScore.newCursor(); 
        cursor.rewindToTick(contextTick);
        var rn = "";
        if (cursor.segment) {
            cursor.segment.annotations.forEach(ann => {
                if (ann.type === Element.HARMONY) rn = ann.text;
            });
        }
        
        return { rn: rn, hData: getChordData(rn, tonicTPC) };
    }

    function isPassingTone(note, prevNote, nextNote, hData) {
        if (!prevNote || !nextNote) return false;
        
        if (hData.tones.indexOf(note.tpc) !== -1) return true;
        
        var stepToPrev = Math.abs(note.pitch - prevNote.pitch);
        var stepToNext = Math.abs(note.pitch - nextNote.pitch);
        
        if (stepToPrev > 2 || stepToNext > 2) return false;
        
        var dirToPrev = note.pitch - prevNote.pitch;
        var dirToNext = nextNote.pitch - note.pitch;
        
        return (dirToPrev * dirToNext > 0);
    }

    // --- CHECK LOGIC METHODS ---

    function determineTonic(sortedTicks, tickGroups) {
        var tpc = 14;
        sortedTicks.forEach(t => {
            var cursor = curScore.newCursor(); cursor.rewindToTick(t);
            if (cursor.segment && cursor.segment.annotations) {
                cursor.segment.annotations.forEach(ann => {
                    if (ann.type === Element.HARMONY && ann.text.match(/^V7?$/)) {
                        var chordNotes = tickGroups[t].sort((a,b)=>a.pitch-b.pitch);
                        if (chordNotes.length > 0) tpc = chordNotes[0].tpc - 1; 
                    }
                });
            }
        });
        return tpc;
    }

    function checkVoiceCrossing(voices, notes) {
        var errors = [];
        if (voices.length > 1) {
            for (var v = 0; v < voices.length - 1; v++) {
                var lowV = voices[v], highV = voices[v+1];
                var ln = null, hn = null;
                notes.forEach(n => {
                    if (n.staffIdx === lowV.staffIdx && n.voice === lowV.voice) ln = n;
                    if (n.staffIdx === highV.staffIdx && n.voice === highV.voice) hn = n;
                });
                if (ln && hn && ln.pitch > hn.pitch) {
                    errors.push("Voice Crossing");
                    ln.color = colorError; hn.color = colorError;
                }
            }
        }
        return errors;
    }

    function checkTonesAndTendencies(notes, nextNotes, rn, hData, bassID, sopID, isBassOnset, nextIsBassOnset) {
        var errors = [];
        
        // Check for doubled tendency tones only at bass onsets
        if (isBassOnset) {
            var bassNote = notes.find(n => n.staffIdx === bassID.staffIdx && n.voice === bassID.voice);
            var sopNote = notes.find(n => n.staffIdx === sopID.staffIdx && n.voice === sopID.voice);
            
            if (bassNote && sopNote && bassNote.tpc === sopNote.tpc) {
                var isTendency0 = (hData.tendTones[0] !== null && bassNote.tpc === hData.tendTones[0]);
                var isTendency1 = (hData.tendTones[1] !== null && bassNote.tpc === hData.tendTones[1]);
                
                if (isTendency0 || isTendency1) {
                    errors.push("Doubled\nTendency Tone");
                    // Color all notes that match this TPC (both bass and soprano)
                    notes.forEach(function(n) {
                        if (n.tpc === bassNote.tpc && !(n.staffIdx === bassID.staffIdx && n.voice === bassID.voice)) {
                            n.color = colorError;
                        }
                    });
                }
            }
        }
        
        notes.forEach(note => {
            var isB = (note.staffIdx === bassID.staffIdx && note.voice === bassID.voice);
            
            if (isB) return;
            
            // Check for non-chord tones at bass onsets
            if (isBassOnset && rn !== "" && hData.tones.indexOf(note.tpc) === -1) {
                errors.push("Invalid\nNCT");
                note.color = colorError;
            }
            
            // Check for repeated melody notes
            if (nextNotes) {
                var nN = findNoteInSameVoice(note, nextNotes);
                if (nN && nN.pitch === note.pitch && nN.tpc === note.tpc) {
                    errors.push("Repeated\nMelody Note");
                    note.color = colorError;
                    nN.color = colorError;
                }
            }
            
            if (nextIsBassOnset && nextNotes) {
                var nN = findNoteInSameVoice(note, nextNotes);
                if (nN) {
                    var dist = nN.pitch - note.pitch;
                    
                    if (hData.tendTones[0] === note.tpc && (dist < 1 || dist > 2)) {
                        errors.push(tpcToName(note.tpc) + " should\nstep UP");
                        note.color = colorError;
                    }
                    if (hData.tendTones[1] === note.tpc && (dist > -1 || dist < -2)) {
                        errors.push(tpcToName(note.tpc) + " should\nstep DOWN");
                        note.color = colorError;
                    }
                }
            }
        });
        return errors;
    }

    function checkVoiceLeading(notes, nextNotes, bassID, sopID, checkPerfects) {
        var errors = [];
        if (!nextNotes) return errors;

        for (var x = 0; x < notes.length; x++) {
            for (var y = x + 1; y < notes.length; y++) {
                var n1 = notes[x], n2 = notes[y];
                var nN1 = findNoteInSameVoice(n1, nextNotes);
                var nN2 = findNoteInSameVoice(n2, nextNotes);
                
                if (nN1 && nN2) {
                    [n1, n2].forEach(note => {
                        var nextNote = (note === n1) ? nN1 : nN2;
                        var tpcDist = nextNote.tpc - note.tpc;
                        if (Math.abs(tpcDist) >= 6) {
                            var qual = (tpcDist >= 6) ? "Aug." : "Dim.";
                            errors.push("Melodic " + qual);
                            note.color = colorError;
                            nextNote.color = colorError;
                        }
                    });

                    if (checkPerfects) {
                        var lC = (n1.pitch < n2.pitch) ? n1 : n2; 
                        var hC = (n1.pitch < n2.pitch) ? n2 : n1;
                        var lN = (nN1.pitch < nN2.pitch) ? nN1 : nN2; 
                        var hN = (nN1.pitch < nN2.pitch) ? nN2 : nN1;

                        var cT = getIntervalType(lC, hC);
                        var nT = getIntervalType(lN, hN);
                        
                        if (cT && cT === nT && (nN1.pitch !== n1.pitch)) {
                            errors.push("Parallel " + nT);
                            lC.color = colorError; hC.color = colorError;
                            lN.color = colorError; hN.color = colorError;
                        }
                        
                        var isBass = (lC.staffIdx === bassID.staffIdx && lC.voice === bassID.voice);
                        var isSop = (hC.staffIdx === sopID.staffIdx && hC.voice === sopID.voice);
                        
                        if (isBass && isSop && nT && !cT) {
                            var bM = lN.pitch - lC.pitch;
                            var sM = hN.pitch - hC.pitch;
                            if ((bM * sM > 0) && Math.abs(sM) > 2) {
                                errors.push("Direct " + nT);
                                hN.color = colorError; 
                            }
                        }
                    }
                }
            }
        }
        return errors;
    }

    function checkPassingTones(sortedTicks, tickGroups, bassOnsets, tonicTPC, bassID) {
        var errors = [];
        
        for (var i = 0; i < sortedTicks.length; i++) {
            var tick = sortedTicks[i];
            var isBassOnset = (bassOnsets.indexOf(tick) !== -1);
            
            if (!isBassOnset) {
                var notes = tickGroups[tick];
                var context = getCurrentHarmonyContext(tick, bassOnsets, tickGroups, tonicTPC);
                var prevTick = (i > 0) ? sortedTicks[i - 1] : null;
                var nextTick = (i < sortedTicks.length - 1) ? sortedTicks[i + 1] : null;
                
                notes.forEach(note => {
                    var isB = (note.staffIdx === bassID.staffIdx && note.voice === bassID.voice);
                    if (!isB && context.hData.tones.indexOf(note.tpc) === -1) {
                        var prevNote = prevTick ? findNoteInSameVoice(note, tickGroups[prevTick]) : null;
                        var nextNote = nextTick ? findNoteInSameVoice(note, tickGroups[nextTick]) : null;
                        
                        if (!isPassingTone(note, prevNote, nextNote, context.hData)) {
                            errors.push({ tick: tick, msg: "Invalid\nNCT", note: note });
                        }
                    }
                });
            }
        }
        return errors;
    }

    function addErrorLabels(tick, errors) {
        if (errors.length > 0) {
            var outCursor = curScore.newCursor(); outCursor.rewindToTick(tick);
            var text = newElement(Element.STAFF_TEXT);
            text.text = [...new Set(errors)].join("\n");
            text.color = colorError;
            outCursor.add(text);
        }
    }

    function addStatisticsFooter(sortedTicks, tickGroups, lastStaff, bassOnsets) {
        var totalIntervalsChecked = 0;
        var totalPerfectCount = 0;

        for (var i = 0; i < sortedTicks.length; i++) {
            var tick = sortedTicks[i];
            var notesAtTick = tickGroups[tick];
            if (notesAtTick && notesAtTick.length > 1) {
                for (var x = 0; x < notesAtTick.length; x++) {
                    for (var y = x + 1; y < notesAtTick.length; y++) {
                        var n1 = notesAtTick[x];
                        var n2 = notesAtTick[y];
                        var lowNote = (n1.pitch < n2.pitch) ? n1 : n2;
                        var highNote = (n1.pitch < n2.pitch) ? n2 : n1;
                        totalIntervalsChecked++;
                        if (getIntervalType(lowNote, highNote)) {
                            totalPerfectCount++;
                        }
                    }
                }
            }
        }

        var cursor = curScore.newCursor();
        cursor.rewind(1); 
        cursor.staffIdx = lastStaff; 
        
        if (sortedTicks.length > 0) {
            while (cursor.segment && cursor.tick < sortedTicks[0]) {
                cursor.next();
            }
        }

        var footer = newElement(Element.STAFF_TEXT);
        var perfRatio = (totalIntervalsChecked > 0) ? Math.round((totalPerfectCount / totalIntervalsChecked) * 100) : 0;
        footer.text = "--- SPECIES 2 ANALYSIS ---\nBass Onsets: " + bassOnsets.length + " | Intervals: " + totalIntervalsChecked + " | Perfect: " + perfRatio + "%";
        footer.color = colorStats;
        footer.placement = Placement.BELOW;
        footer.offsetX = -5;
        cursor.add(footer);
    }

    // --- MAIN RUN ---

    onRun: {
        if (!curScore) { quit(); return; }
        curScore.startCmd("Species 2 Counterpoint Analysis");
        if (curScore.selection.elements.length === 0) { cmd("select-all"); }

        var tickGroups = {};
        curScore.selection.elements.forEach(el => {
            if (el && el.type === Element.NOTE && el.parent && el.parent.parent) {
                var tick = el.parent.parent.tick;
                if (!tickGroups[tick]) tickGroups[tick] = [];
                tickGroups[tick].push(el);
            }
        });

        var lastStaff = curScore.selection.startStaff;
        if (curScore.selection.endStaff > lastStaff) {
            lastStaff = curScore.selection.endStaff - 1; 
        }

        var sortedTicks = Object.keys(tickGroups).map(Number).sort((a,b)=>a-b);
        if (sortedTicks.length === 0) { quit(); return; }

        var tonicTPC = determineTonic(sortedTicks, tickGroups);
        var firstChord = tickGroups[sortedTicks[0]].sort((a,b)=>a.pitch-b.pitch);
        var voices = firstChord.map(n => ({ staffIdx: n.staffIdx, voice: n.voice }));
        var bassID = voices[0];
        var sopID = voices[voices.length - 1];

        var bassOnsets = identifyBassOnsets(sortedTicks, tickGroups, bassID);

        var passingErrors = checkPassingTones(sortedTicks, tickGroups, bassOnsets, tonicTPC, bassID);
        passingErrors.forEach(err => {
            err.note.color = colorError;
            addErrorLabels(err.tick, [err.msg]);
        });

        for (var j = 0; j < sortedTicks.length; j++) {
            var tick = sortedTicks[j];
            var notes = tickGroups[tick];
            var isBassOnset = (bassOnsets.indexOf(tick) !== -1);
            
            var nextTick = (j + 1 < sortedTicks.length) ? sortedTicks[j + 1] : null;
            var nextTickNotes = nextTick ? tickGroups[nextTick] : null;
            var nextTickIsBassOnset = nextTick ? (bassOnsets.indexOf(nextTick) !== -1) : false;
            
            var nextBassOnsetTick = null;
            for (var k = j + 1; k < sortedTicks.length; k++) {
                if (bassOnsets.indexOf(sortedTicks[k]) !== -1) {
                    nextBassOnsetTick = sortedTicks[k];
                    break;
                }
            }
            var nextBassOnsetNotes = nextBassOnsetTick ? tickGroups[nextBassOnsetTick] : null;

            var context = getCurrentHarmonyContext(tick, bassOnsets, tickGroups, tonicTPC);
            var errors = [];

            errors = errors.concat(checkVoiceCrossing(voices, notes));
            errors = errors.concat(checkTonesAndTendencies(notes, nextTickNotes, context.rn, context.hData, bassID, sopID, isBassOnset, nextTickIsBassOnset));
            errors = errors.concat(checkVoiceLeading(notes, nextBassOnsetNotes, bassID, sopID, true));

            addErrorLabels(tick, errors);
        }

        addStatisticsFooter(sortedTicks, tickGroups, lastStaff, bassOnsets);

        curScore.endCmd(); 
        quit();
    }
}