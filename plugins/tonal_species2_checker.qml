import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 3.0

MuseScore {
    menuPath: "Plugins.Proof Reading.Tonal Species II Counterpoint Checker"
    description: "Check two-part tonal species counterpoint for errors.";
    version: "0.8"

    property bool majorMode: true;
    property bool noErrorsFound: true; // yet...: )
    property bool processAll: false;
    property
    var cantusFirmus: 1; // 1 = lower voice, 0 = upper voice, 2 = check both

    property
    var colorPitchError: accessible_red;

    property
    var colorApproachPerfect: accessible_red;

    property
    var colorVoiceLeading: accessible_amber;

    property
    var colorLeaps: accessible_amber;

    property
    var colorConsecutive: accessible_amber;

    property
    var colorInfo: accessible_blue;

    property
    var keyMode: 0;

    MessageDialog {
        id: msgWarning
        title: "Species Checker"
        text: "Great job! No errors found."

        onAccepted: {
            Qt.quit();
        }

        visible: false;
    }

    function markText(v, dyad, msg, color) {
        var myText = newElement(Element.STAFF_TEXT);
        myText.text = msg;
        myText.color = color;
        noErrorsFound = false;
        var cursor = curScore.newCursor();
        cursor.rewindToTick(dyad.tick);
        cursor.track = v * 4;
        cursor.add(myText);
    }

    // try to guess mode
    function majorOrMinor(segment, processAll, endTick) {
        var majorCount = 0;
        while (segment && (processAll || segment.tick < endTick)) {
            var harmony = getRomanNumeral(segment, 0);
            if (harmony) {
                var rawRomanNumeral = harmony.text;
                var leftRomanNumeralClean = cleanRoman(rawRomanNumeral);
                if ("I" === leftRomanNumeralClean) majorCount++;
                if ("IV" === leftRomanNumeralClean) majorCount++;
                if ("iii" === leftRomanNumeralClean) majorCount++;
                if ("vi" === leftRomanNumeralClean) majorCount++;
                if ("i" === leftRomanNumeralClean) majorCount--;
                if ("iv" === leftRomanNumeralClean) majorCount--;
                if ("III" === leftRomanNumeralClean) majorCount--;
                if ("VI" === leftRomanNumeralClean) majorCount--;
            }
            segment = segment.next;
        }
        if (majorCount >= 0) {
            console.log("Hmm... this looks to me like it's a MAJOR key.");
            return 14; // major key
        } else {
            console.log("Hmm... this looks to me like it's a MINOR key.");
            majorMode = false;
            return 17; // minor key
        }
        return 0;
    }

    function assignVoices(segment, voice) {
        var voices = [];
        var noteCount = 0;
        try {
            voices[0] = segment.elementAt(0).notes;
            noteCount += voices[0].length;
        } catch (err) {
            //console.log(err, segment.tick, "treble voice");
        }
        try {
            voices[1] = segment.elementAt(4).notes;
            noteCount += voices[1].length;
        } catch (err) {
            //console.log(err, segment.tick, "bass voice");
        }
        console.log("noteCount: " + noteCount);
        if (noteCount > 2) {
            msgWarning.text = "This plugin only works on two voice counterpoint.";
            msgWarning.visible = true;
            Qt.quit();
        }
        return voices;
    }

    function getDyads(cursor, processAll, endTick) {
        var index = 0;
        var dyads = new Array();
        var previousTick = -1;
        dyads[index] = new Object;
        do {
            var segment = cursor.segment;

            if (!processAll && segment && segment.tick && segment.tick >= endTick) break;

            try {
                if (segment.tick > previousTick) {
                    index++;
                    previousTick = segment.tick;
                    dyads[index] = new Object;
                    dyads[index].tick = segment.tick;
                    // store tick location in dyad object

                    var voices = assignVoices(segment);
                    dyads[index].voices = voices;
                }
                console.log(index + "\t" + voices[0] + "\t" + voices[1]);
            } catch (err) {
                console.log("error in getDyads");
            }

            /*
                if (voices.length > 2) {
                    
                }
                for (var i = 0; i < 2; i++) {
                    try {
                        dyads[index].pitch[i] = voices[i].pitch;
                        dyads[index].tpc[i] = voices[i].tpc1;
                    } catch (err) {
                        console.log(index, err);
                    }
                }
                var harmony = getRomanNumeral(segment);
                if (harmony) {
                    var rawRomanNumeral = harmony.text;
                    if ("Cad64" === rawRomanNumeral || "cad64" === rawRomanNumeral) {
                        if (majorMode) rawRomanNumeral = "I64";
                        else rawRomanNumeral = "i64";
                    }
                    var figBass = cleanFiguredBass(rawRomanNumeral);
                    var leftRomanNumeralClean = cleanRoman(rawRomanNumeral);
                    var tonicTPC = getCurrentTonicPC(rawRomanNumeral) + cursor.keySignature;
                    var quality = getQuality(leftRomanNumeralClean);
                    var inversion = getInversion(rawRomanNumeral);
                    dyads[index].roman = leftRomanNumeralClean;
                    var chordDef = chordDefinitions[leftRomanNumeralClean];
                    if (chordDef) {
                        dyads[index].key = tonicTPC;
                        dyads[index].chordTones = [];
                        for (var i = 0; i < chordDef.length; i++) {
                            dyads[index].chordTones[i] = chordDef[i];
                        }
                        dyads[index].quality = quality;
                        addSeventhNinth(dyads[index], quality, figBass);
                        secondaryAdjustments(dyads[index].chordTones, tonicTPC);
                        dyads[index].inversion = inversion;
                    } else {
                        var msg = "Unrecognized\nroman numeral\n\"" + leftRomanNumeralClean + "\".";
                        markText(dyads[index], msg, colorOrchestrationError);
                    }
                }
            }*/
        }
        while (cursor.next());
        return dyads;
    }

    // this is much more involved than it needs to be in 1st species, but it will be useful in
    // the other species
    function processPitches(dyads) {
        // second pass - assign missing voices
        var last = {};
        for (var i = 0; i < dyads.length; i++) {
            for (var v = 0; v < 2; v++) {
                try {
                    dyads[i].tpc[v] = dyads[i].voices[v].tpc1;
                    dyads[i].pitch[v] = dyads[i].voices[v].pitch;
                } catch (err) {
                    console.log("processPitch error ", err);
                }
            }

            // get motion by comparing to previous notes
            if (last[0] && last[1] && dyads[i].pitch && dyads[i].pitch) {
                // note: maybe this could fail if notes are enharmonic -- but how often does that
                // pop up in species? And what even is the motion for B - Cb? I would still call
                // that oblique
                dyads[i].motion = getMotion(last[0].pitch, last[1].pitch, dyads[i].pitch[0], dyads[i].pitch[1]);
            }

            if (dyads[i].tpc && dyads[i].tpc[0] && dyads[i].tpc[1]) {
                dyads[i].completeDyad = true;
                dyads[i].interval = dyads[i].tpc[0] - dyads[i].tpc[1];
                dyads[i].perfect = (dyads[i].interval === 0 || dyads[i].interval === 1);
            }
            try {
                last[0] = dyads[i].voices[0];
                last[1] = dyads[i].voices[1];
            } catch (err) {
                console.log(err);
            }
        }
        return dyads;
    }

    function getRomanNumeral(segment, measure) {
        var aCount = 0;
        var annotation = segment.annotations[aCount];
        while (annotation) {
            if (annotation.type == Element.HARMONY)
                return annotation;
            annotation = segment.annotations[++aCount];
        }
        return null;
    }

    function cleanRoman(rn) {
        return rn.split('/')[0].replace(/[2345679]/g, '');
    }

    function cleanFiguredBass(rn) {
        return rn.split('/')[0].replace(/[^2345679]/g, '');
    }

    // This may vary if there are secondary dominants
    function getCurrentTonicPC(rn, measure) {
        var tonic = rn.replace(/[2345679]/g, '').split('/')[1];
        if (tonic) {
            var tonicdyad = chordDefinitions[tonic];
            if (tonicdyad[0]) return tonicdyad[0] + keyMode;
            else {
                msgWarning.text = "There's something wrong with the secondary dyad in measure " + measure;
                msgWarning.visible = true;
                Qt.quit();
            }
        }
        return keyMode;
    }

    function secondaryAdjustments(c, tonic) {
        for (var i = 0; i < c.length; i++) {
            c[i] += tonic;
        }
    }

    function getQuality(roman) {
        var quality = "major";
        switch (roman) {
            case "i":
            case "ii":
            case "iii":
            case "iv":
            case "v":
            case "vi":
                quality = "minor";
                break;
            case "V":
                quality = "dominant";
                break;
            case "iio":
            case "viio":
                quality = "diminished";
                break;
            case "ii0":
            case "vii0":
                quality = "halfDim7";
                break;
            case "It":
            case "Ger":
            case "Fr":
                quality = "aug6";
        }
        return quality;
    }

    function getInversion(roman) {
        var figuredBass = roman.split('/')[0].replace(/[^2345679]/g, '');
        var inversion = inversionDefinitions[figuredBass];
        var rn = cleanRoman(roman); // this is ugly; basically just for Augmented Sixth chords
        switch (rn) {
            case "It":
            case "Ger":
            case "Fr":
                inversion--;
        }
        return inversion;
    }

    function addSeventhNinth(c, quality, figBass) {
        var rootTPC = c.chordTones[0];
        switch (figBass) {
            case "9":
            case "7":
            case "73":
            case "753":
            case "65":
            case "43":
            case "643":
            case "42":
            case "642":
                if ("major" === quality) {
                    c.chordTones.push(rootTPC + 5);
                } else if ("diminished" === quality) {
                    c.chordTones.push(rootTPC - 9);
                } else if ("minor" === quality || "dominant" === quality || "halfDim7" === quality) {
                    c.chordTones.push(rootTPC - 2);
                }
        }
        if ("9" === figBass) c.chordTones.push(rootTPC + 2);
    }

    function checkForDoubledLT(dyads) {
        for (var i = 0; i < dyads.length; i++) {
            var leadingTones = [];
            if (dyads[i].tpc && dyads[i].roman) {
                for (var v = 0; v < dyads[i].tpc.length; v++) {
                    if (dyads[i].tpc[v] == dyads[i].key + 5) leadingTones.push(dyads[i].voices[v]);
                }
            }
            if (leadingTones.length > 1) {
                for (var z = 0; z < leadingTones.length; z++) {
                    leadingTones[z].color = colorDoubledLTError;
                }
                var msg = "Doubled LT of key.";
                markText(v, dyads[i], msg, colorDoubledLTError);
            }
        }
    }

    function getLyrics(segment, part) {
        var sArray = new Array();
        for (var i = part * 4; i < 2 + part * 4; i++) {
            if (segment && segment.elementAt(i) && segment.elementAt(i).lyrics) {
                var lyrics = segment.elementAt(i).lyrics;
                for (var j = 0; j < lyrics.length; j++) {
                    var l = lyrics[j];
                    if (!l)
                        continue;
                    if (sArray[j] == undefined)
                        sArray[j] = "";
                    if (l.syllabic == Lyrics.SINGLE || l.syllabic == Lyrics.END)
                        sArray[j] += l.text + " ";
                    if (l.syllabic == Lyrics.MIDDLE || l.syllabic == Lyrics.BEGIN)
                        sArray[j] += l.text;
                }
            }
        }
        return sArray.toString();
    }

    function getMotion(lower1, upper1, lower2, upper2) {
        if (lower1 == lower2) return "oblique";
        if (upper1 == upper2) return "oblique";
        if (lower1 > lower2 && upper1 > upper2) return "similar";
        if (lower1 < lower2 && upper1 < upper2) return "similar";
        return "contrary";
    }

    function tpcName(tpc) {
        var testTPC = tpc;
        var letterNames = ["C", "G", "D", "A", "E", "B", "F"];
        var noteName = letterNames[(testTPC + 7) % 7];
        while (testTPC < 13) {
            noteName = noteName + "b";
            testTPC += 7;
        }
        while (testTPC > 19) {
            noteName = noteName + "#";
            testTPC -= 7;
        }
        return noteName;
    }

    // it's magic time!
    // This is slightly different from the modal checkApproachToPerfect because
    // we allow approach to perfect in similar motion if it's stepwise
    function checkApproachToPerfect(dyads) {
        var msg = "xxx";
        for (var i = 0; i < dyads.length; i++) {
            if (dyads[i].motion && dyads[i].perfect &&
                (dyads[i].interval === dyads[i - 1].interval)) {
                if ("similar" === dyads[i].motion) {
                    msg = "Parallel " + intervalNames[dyads[i].interval + 11] + ".";
                    dyads[i - 1].voices[0].color = colorApproachPerfect;
                    dyads[i - 1].voices[1].color = colorApproachPerfect;
                    dyads[i].voices[0].color = colorApproachPerfect;
                    dyads[i].voices[1].color = colorApproachPerfect;
                    markText(0, dyads[i - 1], msg, colorApproachPerfect);
                } else if ("contrary" === dyads[i].motion) {
                    msg = "Contrary " + intervalNames[dyads[i].interval + 11] + ".";
                    dyads[i - 1].voices[0].color = colorApproachPerfect;
                    dyads[i - 1].voices[1].color = colorApproachPerfect;
                    dyads[i].voices[0].color = colorApproachPerfect;
                    dyads[i].voices[1].color = colorApproachPerfect;
                    markText(0, dyads[i - 1], msg, colorApproachPerfect);
                } else if ("oblique" === dyads[i].motion &&
                    dyads[i - 1].pitch[0] === dyads[i].pitch[0] &&
                    dyads[i - 1].pitch[1] === dyads[i].pitch[1]) {
                    msg = "Repeated notes\nin both parts.";
                    dyads[i - 1].voices[0].color = colorApproachPerfect;
                    dyads[i - 1].voices[1].color = colorApproachPerfect;
                    dyads[i].voices[0].color = colorApproachPerfect;
                    dyads[i].voices[1].color = colorApproachPerfect;
                    markText(0, dyads[i - 1], msg, colorApproachPerfect);
                }
            } else {
                if ("similar" === dyads[i].motion && dyads[i].perfect) {
                    if (Math.abs(dyads[i].pitch[0] - dyads[i - 1].pitch[0]) > 2) {
                        msg = "Perfect interval\napproached in\nsimilar motion.";
                        dyads[i - 1].voices[0].color = colorApproachPerfect;
                        dyads[i - 1].voices[1].color = colorApproachPerfect;
                        dyads[i].voices[0].color = colorApproachPerfect;
                        dyads[i].voices[1].color = colorApproachPerfect;
                        markText(0, dyads[i - 1], msg, colorApproachPerfect);
                    }
                }
            }
        }

    }

    function checkHorizontalIntervals(dyads) {
        if (!dyads) return;
        for (var i = 0; i < dyads.length - 1; i++) {
            if (dyads[i] && dyads[i].voices) {
                for (var v = 0; v < dyads[i].voices.length; v++) {
                    if (v != cantusFirmus && dyads[i] && dyads[i].tpc && dyads[i + 1].tpc && dyads[i].tpc[v] && dyads[i + 1].tpc[v]) {
                        var horizontalInterval = dyads[i + 1].tpc[v] - dyads[i].tpc[v];
                        if (dyads[i + 1].pitch[v] < dyads[i].pitch[v]) horizontalInterval *= -1;
                        var horizontalDistance = Math.abs(dyads[i + 1].pitch[v] - dyads[i].pitch[v]);
                        if (Math.abs(horizontalInterval) > 5 ||
                            horizontalDistance == 10 ||
                            horizontalDistance == 11) {
                            dyads[i].voices[v].color = colorVoiceLeading;
                            dyads[i + 1].voices[v].color = colorVoiceLeading;
                            var msg = "Avoid writing\nmelodic " + intervalNames[horizontalInterval + 11] + ".";
                            markText(v, dyads[i], msg, colorVoiceLeading);
                        }
                        if (horizontalDistance > 12) {
                            console.log(dyads[i].pitch[v], dyads[i + 1].pitch[v])
                            dyads[i].voices[v].color = colorVoiceLeading;
                            dyads[i + 1].voices[v].color = colorVoiceLeading;
                            var msg = "Melodic leap\ngreater than\nan octave.";
                            markText(v, dyads[i], msg, colorVoiceLeading);
                        }
                    }
                }
            }
        }
    }


    function leapFromDissonance(dyads) {
        for (var i = 0; i < dyads.length - 1; i++) {
            for (var v = 0; v < 2; v++) {
                if (v != cantusFirmus && dyads[i].tpc) {
                    var chordTones = dyads[i].chordTones;
                    if (dyads[i].tpc && chordTones.indexOf(dyads[i].tpc[v]) < 0) {
                        if (dyads[i].pitch && dyads[i + 1].pitch &&
                            Math.abs(dyads[i + 1].pitch[v] - dyads[i].pitch[v]) > 2) { // leap!
                            var msg = "Leap from\nNCT.";
                            dyads[i].voices[v].color = colorLeaps;
                            dyads[i + 1].voices[v].color = colorLeaps;
                            markText(v, dyads[i], msg, colorLeaps);
                        }
                    }
                }
            }
        }
    }

    function leapToDissonance(dyads) {
        for (var i = 1; i < dyads.length; i++) {
            for (var v = 0; v < 2; v++) {
                if (v != cantusFirmus && dyads[i].tpc) {
                    var chordTones = dyads[i].chordTones;
                    if (dyads[i].tpc && chordTones.indexOf(dyads[i].tpc[v]) < 0) {
                        if (Math.abs(dyads[i].pitch[v] - dyads[i - 1].pitch[v]) > 2) { // leap!
                            var msg = "Leap to\nNCT.";
                            dyads[i - 1].voices[v].color = colorLeaps;
                            dyads[i].voices[v].color = colorLeaps;
                            markText(v, dyads[i], msg, colorLeaps);
                        }
                    }
                }
            }
        }
    }


    function stepBack(dyads) {
        for (var i = 0; i < dyads.length - 2; i++) {
            var lookingForStepback = true;
            for (var v = 0; v < 2; v++) {
                if (v != cantusFirmus && dyads[i].tpc && dyads[i].tpc[v]) {
                    var next = i + 1;
                    try {
                        var leapDirection = Math.sign(dyads[next].pitch[v] - dyads[i].pitch[v]);
                        var leapSize = Math.abs(dyads[next].pitch[v] - dyads[i].pitch[v]);
                        if (leapSize > 7) // look for step back
                        {
                            var potentialStepback = dyads[i + 2];
                            if (potentialStepback && potentialStepback.tpc && potentialStepback.tpc[v]) {
                                var resolutionDirection = Math.sign(potentialStepback.pitch[v] - dyads[next].pitch[v]);
                                var resolutionSize = Math.abs(potentialStepback.pitch[v] - dyads[next].pitch[v]);

                                if (leapSize > 7 && (resolutionSize > 2 || resolutionDirection === leapDirection)) {
                                    dyads[next].voices[v].color = colorVoiceLeading;
                                    dyads[i].voices[v].color = colorVoiceLeading;
                                    var msg = "Melody should\nstep back after\nlarge leap.";
                                    markText(v, dyads[next], msg, colorVoiceLeading);
                                }
                            }
                        }
                    } catch (err) {
                        console.log(err);
                    }
                }
            }
        }
    }

    function consecutiveLeaps(dyads) {
        var i, v;
        for (i = 0; i < dyads.length - 3; i++) {
            for (v = 0; v < 2; v++) {
                if (v != cantusFirmus) { // && dyads[i].pitch & dyads[i + 1].pitch && dyads[i + 2].pitch && dyads[i + 3].pitch) {
                    if (dyads[i].pitch && dyads[i + 1].pitch && dyads[i + 2].pitch && dyads[i + 3].pitch) {
                        if (dyads[i].pitch[v] && dyads[i + 1].pitch[v] && dyads[i + 2].pitch[v] && dyads[i + 3].pitch[v]) {
                            var melodicInterval1 = dyads[i + 1].pitch[v] - dyads[i].pitch[v];
                            var melodicInterval2 = dyads[i + 2].pitch[v] - dyads[i + 1].pitch[v];
                            var melodicInterval3 = dyads[i + 3].pitch[v] - dyads[i + 2].pitch[v];
                            if (Math.abs(melodicInterval1) > 2 && // 3 consecutive leaps
                                Math.abs(melodicInterval2) > 2 &&
                                Math.abs(melodicInterval3) > 2 &&
                                Math.sign(melodicInterval1) === Math.sign(melodicInterval2) &&
                                Math.sign(melodicInterval2) === Math.sign(melodicInterval3)) { // and all in the same direction
                                dyads[i].voices[v].color = colorConsecutive;
                                dyads[i + 1].voices[v].color = colorConsecutive;
                                dyads[i + 2].voices[v].color = colorConsecutive;
                                dyads[i + 3].voices[v].color = colorConsecutive;
                                var msg = "Avoid more than\ntwo consecutive leaps\nin the same direction."
                                markText(v, dyads[i + 2], msg, colorConsecutive);
                            }
                            var outlinedInterval = dyads[i + 2].tpc[v] - dyads[i].tpc[v];
                            if (Math.abs(melodicInterval1) > 2 && // 2 consecutive leaps
                                Math.abs(melodicInterval2) > 2 &&
                                Math.sign(melodicInterval1) === Math.sign(melodicInterval2) &&
                                (allowedVerticalIntervals.indexOf(outlinedInterval) < 0 &&
                                    outlinedInterval != -1)) { // outlining dissonance
                                dyads[i].voices[v].color = colorConsecutive;
                                dyads[i + 1].voices[v].color = colorConsecutive;
                                dyads[i + 2].voices[v].color = colorConsecutive;
                                var msg = "Avoid dissonance between\n1st and 3rd notes of\nconsecutive leaps\nin the same direction."
                                markText(v, dyads[i + 1], msg, colorConsecutive);
                            }
                        }
                    }
                }
            }
        }
    }

    function outlinedTritone(dyads) {
        for (var i = 0; i < dyads.length - 3; i++) {
            for (var v = 0; v < 2; v++) {
                if (v != cantusFirmus && dyads[i].pitch && dyads[i + 1].pitch && dyads[i + 2].pitch && dyads[i + 3].pitch &&
                    dyads[i].pitch[v] && dyads[i + 1].pitch[v] && dyads[i + 2].pitch[v] && dyads[i + 3].pitch[v]) {
                    var outlinedInterval = dyads[i + 2].tpc[v] - dyads[i].tpc[v];
                    var direction0to1 = Math.sign(dyads[i + 1].pitch[v] - dyads[i].pitch[v]);
                    var direction1to2 = Math.sign(dyads[i + 2].pitch[v] - dyads[i + 1].pitch[v]);
                    if ((6 === outlinedInterval || -6 === outlinedInterval) && // outlining tritone
                        direction0to1 === direction1to2 &&
                        !isBetween(dyads[i + 2].pitch[v], dyads[i + 1].pitch[v], dyads[i + 3].pitch[v])) { // tritone stands out as change of direction
                        dyads[i].voices[v].color = colorConsecutive;
                        dyads[i + 1].voices[v].color = colorConsecutive;
                        dyads[i + 2].voices[v].color = colorConsecutive;
                        var msg = "Avoid outlining\ntritone in three\nnote pattern."
                        markText(v, dyads[i + 1], msg, colorConsecutive);
                    }
                }
            }
        }
    }

    function isBetween(test, lo, hi) {
        return (Math.sign(test - lo) === Math.sign(hi - test));
    }

    function isThird(interval) {
        if (interval == 4) return true;
        if (interval == -3) return true;
        return false;
    }

    function isSixth(interval) {
        if (interval == -4) return true;
        if (interval == 3) return true;
        return false;
    }

    function ratioOfPerfect(dyads) {
        var perfectCount = 0;
        for (var i = 0; i < dyads.length; i++) {
            if (dyads[i].perfect) perfectCount++;
        }
        var msg;
        var ratio = perfectCount * 1.0 / dyads.length;
        console.log("Percentage of perfect intervals: ", ratio * 100, "%");
        if (ratio >= 0.8) {
            var msg = "Too many perfect\nintervals.\nThere are " + perfectCount + ",\nwhich is " + Math.round(ratio * 100) + "%.";
            markText(0, dyads[0], msg, colorInfo);
        }
        if (ratio > 0.55 && ratio < 0.8) {
            var msg = "Maybe too many\nperfect intervals.\nThere are " + perfectCount + ",\nwhich is " + Math.round(ratio * 100) + "%.";
            markText(0, dyads[0], msg, colorInfo);
        }
    }

    function ratioOfLeaps(dyads) {
        var noteCount = 0;
        var leapCount = 0;
        for (var i = 0; i < dyads.length - 1; i++) {
            for (var v = 0; v < 2; v++) {
                if (v != cantusFirmus) {
                    try {
                        if (dyads[i].pitch[v] != dyads[i + 1].pitch[v]) noteCount++;
                        if (Math.abs(dyads[i].pitch[v] - dyads[i + 1].pitch[v]) > 2) leapCount++;
                    } catch (err) {
                        console.log(err);
                    }
                }
            }
        }
        var ratio = leapCount * 1.0 / noteCount;
        console.log("Percentage of leaps: ", ratio * 100, "%");
        if (ratio > 0.5) {
            var msg = "Melody may be\ntoo disjunct.\nThere are " + leapCount + " leaps,\nwhich is " + Math.round(ratio * 100) + "%.";
            markText(0, dyads[0], msg, colorInfo);
        }
    }

    function melodicRange(dyads) {
        var hi = [];
        var lo = [];
        hi[0] = 0;
        hi[1] = 0;
        lo[0] = 200;
        lo[1] = 200;
        for (var i = 0; i < dyads.length; i++) {
            for (var v = 0; v < 2; v++) {
                if (v != cantusFirmus && dyads[i].pitch[v]) {
                    if (dyads[i].pitch[v] > hi[v]) hi[v] = dyads[i].pitch[v];
                    if (dyads[i].pitch[v] < lo[v]) lo[v] = dyads[i].pitch[v];
                }
            }
        }
        for (var v = 0; v < 2; v++) {
            var voiceRange = hi[v] - lo[v];
            if (voiceRange < 10) markText(v, dyads[0], "Try to cover a\nwider melodic range.", colorInfo);
        }
    }

    function downbeatParallels(dyads) {
        var msg = "xxx";
        for (var i = 1; i < dyads.length - 1; i++) {
            if (dyads[i].completeDyad && dyads[i].perfect) {
                var next;
                for (next = i + 1; next < dyads.length; next++) {
                    if (dyads[next].completeDyad) break;
                }
                if (dyads[i].interval === dyads[next].interval) {
                    var motion = getMotion(dyads[i].pitch[0], dyads[i].pitch[1], dyads[next].pitch[0], dyads[next].pitch[1]);
                    switch (motion) {
                        case "similar":
                            msg = "Downbeat\nparallel " + intervalNames[dyads[i].interval + 11] + ".";
                            break;
                        case "contrary":
                            msg = "Downbeat\ncontrary " + intervalNames[dyads[i].interval + 11] + ".";
                            break;
                    }
                    dyads[next].voices[0].color = colorApproachPerfect;
                    dyads[next].voices[1].color = colorApproachPerfect;
                    dyads[i].voices[0].color = colorApproachPerfect;
                    dyads[i].voices[1].color = colorApproachPerfect;
                    markText(0, dyads[i], msg, colorApproachPerfect);
                    break;
                }
            }
        }
    }

    function checkForWrongPitches(dyads) {
        for (var i = 0; i < dyads.length; i++) {
            if (dyads[i].chordTones) {
                var correctPitches = dyads[i].chordTones;
                for (var v = 0; v < 2; v++) {
                    var testPitch = dyads[i].tpc[v];
                    if (testPitch && correctPitches.indexOf(testPitch) < 0) {
                        var correctPitch = correctPitches[v];
                        dyads[i].voices[v].color = colorPitchError;
                        if (("V" === dyads[i].roman || "viio" === dyads[i].roman || "vii0" === dyads[i].roman) &&
                            (dyads[i].tpc[v] === dyads[i].key - 2)) {
                            var msg = "You need to raise\nthe leading tone.";
                            markText(v * 4, dyads[i], msg, colorPitchError);
                        } else {
                            var noteName = tpcName(dyads[i].tpc[v]);
                            var msg = "Pitch \"" + noteName + "\"\nis not in\n" + dyads[i].roman + " chord .";
                            markText(v, dyads[i], msg, colorPitchError);
                        }
                    }
                }
            }
        }
    }

    function checkForVoiceCrossing(dyads) {
        for (var i = 0; i < dyads.length; i++) {
            if (dyads[i] && dyads[i].pitch && dyads[i].pitch[0] && dyads[i].pitch[1]) {
                if (dyads[i].pitch[1] > dyads[i].pitch[0]) {
                    if (dyads[i].tpc[0]) dyads[i].voices[0].color = colorVoiceLeading;
                    if (dyads[i].tpc[1]) dyads[i].voices[1].color = colorVoiceLeading;
                    var msg = "Don't cross\nvoices.";
                    if (dyads[i].tpc[0]) markText(0, dyads[i], msg, colorVoiceLeading);
                    else if (dyads[i].tpc[1]) markText(1, dyads[i], msg, colorVoiceLeading);
                }
            }
        }
    }

    function checkForRepeatedNotes(dyads) {
        console.log("checking for repeated notes");
        for (var i = 0; i < dyads.length; i++) {
            try {
                if (dyads[i].pitch[0] == dyads[i - 1].pitch[0]) {
                    var msg = "Repeated notes\nare not allowed\nin Species II.";
                    dyads[i].voices[0].color = colorVoiceLeading;
                    dyads[i - 1].voices[0].color = colorVoiceLeading;
                    markText(0, dyads[i], msg, colorVoiceLeading);
                }
            } catch (err) {
                console.log(err);
            }
        }
    }

    function rewind(cursor, processAll) { // go through all staves/voices simultaneously
        if (processAll) {
            //cursor.track = 0;
            cursor.rewind(0);
        } else {
            cursor.rewind(1);
        }
    }


    //------------------------------------------------------------------------------

    onRun: {
        if (typeof curScore === 'undefined' || curScore == null) {
            console.log("No score found.");
            Qt.quit();
        }

        // find selection
        var endTick;

        var cursor = curScore.newCursor();
        cursor.rewind(1);
        if (!cursor.segment) {
            // no selection
            console.log("No selection: processing whole score.");
            processAll = true;
        } else {
            cursor.rewind(2);
            endTick = cursor.tick;
            if (endTick == 0) {
                // selection includes end of score
                // calculate tick from last score segment
                endTick = curScore.lastSegment.tick + 1;
            }
            cursor.rewind(1);
        }
        rewind(cursor, processAll);
        var segment = cursor.segment;

        keyMode = majorOrMinor(segment, processAll, endTick);
        rewind(cursor, processAll);
        // go through all staves/voices simultaneously
        if (processAll) {
            //cursor.track = 0;
            cursor.rewind(0);
        } else {
            cursor.rewind(1);
        }
        var dyads = getDyads(cursor, processAll, endTick);
        /*

        processPitches(dyads);

        checkForWrongPitches(dyads);
        checkForVoiceCrossing(dyads);

        checkForRepeatedNotes(dyads);
        checkApproachToPerfect(dyads);

        stepBack(dyads);
        checkHorizontalIntervals(dyads);
        //leapToDissonance(dyads);
        //leapFromDissonance(dyads);
        //downbeatParallels(dyads);
        consecutiveLeaps(dyads);
        outlinedTritone(dyads);


        ratioOfPerfect(dyads);
        ratioOfLeaps(dyads);

        if (noErrorsFound) {
            msgWarning.text = "Great job! No errors found.";
            msgWarning.visible = true;
        }
        */
        Qt.quit();
    }

    property
    var inversionDefinitions: Object.freeze({
        "": 0,
        "3": 0,
        "53": 0,
        "6": 1,
        "63": 1,
        "64": 2,
        "7": 0,
        "73": 0,
        "753": 0,
        "65": 1,
        "43": 2,
        "643": 2,
        "42": 3,
        "642": 3,
        "9": 0, // we won't do inversions of ninth chords
    });

    property
    var chordDefinitions: Object.freeze({
        // fifth can't be omitted
        "I": [0, 4, 1],
        "i": [0, -3, 1],
        "bII": [-5, -1, -4],
        "N": [-5, -1, -4],
        "ii": [2, -1, 3],
        "iio": [2, -1, -4],
        "ii0": [2, -1, -4],
        "iii": [4, 1, 5],
        "bIII": [-3, 1, -2],
        "III": [-3, 1, -2],
        "iv": [-1, -4, 0],
        "IV": [-1, 3, 0],
        "v": [1, -2, 2],
        "V": [1, 5, 2],
        "bVI": [-4, 0, -3],
        "VI": [-4, 0, -3],
        "vi": [3, 0, 4],
        "bVII": [-2, 2, -1],
        "VII": [-2, 2, -1],
        "viio": [5, 2, -1],
        "vii0": [5, 2, -1],
        "It": [-4, 0, 6],
        "Ger": [-4, 0, -3, 6],
        "Fr": [-4, 0, 2, 6]
    });

    property
    var allowedVerticalIntervals: [0, 1, 3, 4, -3, -4];

    property
    var intervalNames: [
        "dim6",
        "dim3",
        "dim7",
        "dim4",
        "dim8",
        "dim5",
        "m2",
        "m6",
        "m3",
        "m7",
        "P4",
        "P8",
        "P5",
        "M2",
        "M6",
        "M3",
        "M7",
        "aug4",
        "aug8",
        "aug5",
        "aug2",
        "aug6",
        "aug3"
    ];

    property
    var accessible_red: "#B91C1C";

    property
    var accessible_green: "#15803D";

    property
    var accessible_amber: "#B45309";

    property
    var accessible_blue: "#1D4ED8";
}