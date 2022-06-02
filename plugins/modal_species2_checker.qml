import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 3.0

MuseScore {
  menuPath: "Plugins.Proof Reading.Modal Species II Counterpoint Checker"
  description: "Check two-part modal species counterpoint for errors.";
  version: "0.8"

  property bool majorMode: true;
  property bool noErrorsFound: true; // yet... :)
  property bool processAll: false;
  property
  var cantusFirmus: 2; // 1 = lower voice, 0 = upper voice, 2 = check both
  property
  var cfFound: false;

  property
  var colorBeginningEnd: accessible_amber;

  property
  var colorVertical: accessible_red;

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
  var key: 14;

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

  // not used in modal
  /*  function getRomanNumeral(segment, measure) {
      var aCount = 0;
      var annotation = segment.annotations[aCount];
      while (annotation) {
        if (annotation.type == Element.HARMONY)
          return annotation;
        annotation = segment.annotations[++aCount];
      }
      return null;
    }
  */

  function checkDyad(segment) {
    var voices = [];
    var voiceCount = 0;
    for (var layer = 7; layer >= 0; layer--) {
      if (segment.elementAt(layer)) {
        var thisLayerNotes = segment.elementAt(layer).notes;
        if (thisLayerNotes) {
          if (0 != layer % 4) {
            msgWarning.text = "All notes must be entered in layer 1.";
            msgWarning.visible = true;
            Qt.quit();
          }
          voiceCount += thisLayerNotes.length;
          if (voiceCount > 2) {
            msgWarning.text = "This plugin only works on two voice counterpoint.";
            msgWarning.visible = true;
            Qt.quit();
          }
        }
      }
    }
  }

  function getDyads(segment, processAll, endTick) {
    var i = -1;
    var measure = 1;
    var dyads = new Array();
    //dyads[i] = new Object;

    while (segment && (processAll || segment.tick < endTick)) {
      if (segment &&
        (segment.elementAt(0) && segment.elementAt(0).type == Element.CHORD) ||
        (segment.elementAt(4) && segment.elementAt(4).type == Element.CHORD)) {
        i++;
        checkForCantusFirmus(segment);
        checkDyad(segment);
        dyads[i] = new Object;
        dyads[i].tick = segment.tick;
        dyads[i].measure = measure;
        // OK, this could be clearer by just treating lower and upper, but on the
        // off-chance that someday I'll make this work for more than 2 voices, we'll
        // call them voice[0] and voice[1]
        dyads[i].voices = [];
        dyads[i].tpc = [];
        dyads[i].pitch = [];
        dyads[i].notehead = [];
        //dyads[i].notehead[0] = false;
        //dyads[i].notehead[1] = false;
        for (var v = 0; v < 2; v++) {
          if (segment && segment.elementAt(4 * v)) {
            if (segment.elementAt(4 * v).type == Element.CHORD) {
              dyads[i].voices[v] = segment.elementAt(4 * v).notes[0];
              dyads[i].notehead[v] = true;
            } else if (i > 0 && segment.elementAt(4 * v).type == Element.REST) {
              markText(v,dyads[i], "No rests allowed\nin Species.", "#000000");
            }
          }
        }
      } else if (segment.elementAt(0) && segment.elementAt(0).type == Element.BAR_LINE) measure++;
      segment = segment.next;
    }
    console.log("Cantus firmus is in " + voiceNames[cantusFirmus] + " part.");
    processPitches(dyads);
    return dyads;
  }

  // this is much more involved than it needs to be in 1st species, but it will be useful in
  // the other species
  function processPitches(dyads) {
    // second pass - assign missing voices
    var last = {};
    for (var i = 0; i < dyads.length; i++) {
      dyads[i].downbeat = true;
      for (var v = 0; v < 2; v++) {
        if (!dyads[i].voices[v]) {
          dyads[i].downbeat = false;
          dyads[i].voices[v] = last[v];
        }
        if (dyads[i].voices[v]) {
          dyads[i].tpc[v] = dyads[i].voices[v].tpc1;
          dyads[i].pitch[v] = dyads[i].voices[v].pitch;
        }
      }
      if (last[0] && last[1]) {
        dyads[i].motion = getMotion(last[0].pitch, last[1].pitch, dyads[i].pitch[0], dyads[i].pitch[1]);
      }
      if (dyads[i].tpc[0] && dyads[i].tpc[1]) {
        dyads[i].interval = dyads[i].tpc[0] - dyads[i].tpc[1];
        dyads[i].perfect = (dyads[i].interval === 0 || dyads[i].interval === 1);
      }
      last[0] = dyads[i].voices[0];
      last[1] = dyads[i].voices[1];
    }
    return dyads;
  }

  /*
    function getRoman(rn) {
      return rn.split('/')[0].replace(/[2345679]/g, '');
    }

    function getFiguredBass(rn) {
      return rn.split('/')[0].replace(/[^2345679]/g, '');
    }

    function getTonicTPC(rn, measure) {
      var tonic = rn.replace(/[2345679]/g, '').split('/')[1];
      if (tonic) {
        var tonicdyad = dyadDefinitions[tonic];
        if (tonicdyad[0]) return tonicdyad[0] + key;
        else {
          msgWarning.text = "There's something wrong with the secondary dyad in measure " + measure;
          msgWarning.visible = true;
          Qt.quit();
        }
      }
      return key;
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
      var rn = getRoman(roman); // this is ugly; basically just for Augmented Sixth chords
      switch (rn) {
        case "It":
        case "Ger":
        case "Fr":
          inversion--;
      }
      return inversion;
    }

    function addSeventhNinth(c, quality, figBass) {
      var rootTPC = c.romanPitches[0];
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
            c.romanPitches.push(rootTPC + 5);
          } else if ("diminished" === quality) {
            c.romanPitches.push(rootTPC - 9);
          } else if ("minor" === quality || "dominant" === quality || "halfDim7" === quality) {
            c.romanPitches.push(rootTPC - 2);
          }
      }
      if ("9" === figBass) c.romanPitches.push(rootTPC + 2);
    }
    */

  /*
    function checkForWrongPitches(dyads) {
      for (var i = 0; i < dyads.length; i++) {
        if (dyads[i].romanPitches) {
          var correctPitches = dyads[i].romanPitches;
          for (var v = 0; v < dyads[i].romanPitches.length; v++) {
            var testPitch = dyads[i].tpc[v];
            if (correctPitches.iOf(testPitch) < 0) {
              var correctPitch = correctPitches[v];
              dyads[i].voices[v].color = colorPitchError;
              if (("V" === dyads[i].roman || "viio" === dyads[i].roman || "vii0" === dyads[i].roman) &&
                (dyads[i].tpc[v] === dyads[i].key - 2)) {
                var msg = "You need to raise\nthe leading tone in\nthe " + voiceNames[v] + ".";
                markText(v,dyads[i], msg, colorPitchError);
              } else {
                var msg = "Wrong note in " + voiceNames[v] + ".";
                markText(v,dyads[i], msg, colorPitchError);
              }
            }
          }
        }
      }
    }
    */

  /*
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
          markText(v,dyads[i], msg, colorDoubledLTError);
        }
      }
    }
    */

  function checkForCantusFirmus(segment) {
    if (!cfFound) {
      var checkcf1 = getLyrics(segment, 1).replace(/[^cf]/g, '');
      var checkcf0 = getLyrics(segment, 0).replace(/[^cf]/g, '');
      if ("cf" === checkcf1) {
        cantusFirmus = 1;
        cfFound = true;
      } else if ("cf" === checkcf0) {
        cantusFirmus = 0;
        cfFound = true;
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
  function checkApproachToPerfect(dyads) {
    var msg = "xxx";
    for (var i = 0; i < dyads.length; i++) {
      if (dyads[i].motion && dyads[i].perfect) {
        if (dyads[i].interval === dyads[i - 1].interval) {
          if ("similar" === dyads[i].motion) {
            msg = "Parallel " + intervalNames[dyads[i].interval + 11] + ".";
            dyads[i - 1].voices[0].color = colorApproachPerfect;
            dyads[i - 1].voices[1].color = colorApproachPerfect;
            dyads[i].voices[0].color = colorApproachPerfect;
            dyads[i].voices[1].color = colorApproachPerfect;
            markText(0,dyads[i - 1], msg, colorApproachPerfect);
          } else if ("contrary" === dyads[i].motion) {
            msg = "Contrary " + intervalNames[dyads[i].interval + 11] + ".";
            dyads[i - 1].voices[0].color = colorApproachPerfect;
            dyads[i - 1].voices[1].color = colorApproachPerfect;
            dyads[i].voices[0].color = colorApproachPerfect;
            dyads[i].voices[1].color = colorApproachPerfect;
            markText(0,dyads[i - 1], msg, colorApproachPerfect);
          } else if ("oblique" === dyads[i].motion &&
            dyads[i - 1].pitch[0] === dyads[i].pitch[0] &&
            dyads[i - 1].pitch[1] === dyads[i].pitch[1]) {
            msg = "Repeated notes\nin both parts.";
            dyads[i - 1].voices[0].color = colorApproachPerfect;
            dyads[i - 1].voices[1].color = colorApproachPerfect;
            dyads[i].voices[0].color = colorApproachPerfect;
            dyads[i].voices[1].color = colorApproachPerfect;
            markText(0,dyads[i - 1], msg, colorApproachPerfect);
          }
        } else {
          if ("similar" === dyads[i].motion) {
            //var melodicDist = Math.abs(dyads[i].pitch[testVoice] - dyads[i + 1].pitch[testVoice]);
            //if (melodicDist > 2) {
            msg = "Perfect interval\napproached in\nsimilar motion.";
            dyads[i - 1].voices[0].color = colorApproachPerfect;
            dyads[i - 1].voices[1].color = colorApproachPerfect;
            dyads[i].voices[0].color = colorApproachPerfect;
            dyads[i].voices[1].color = colorApproachPerfect;
            markText(0,dyads[i - 1], msg, colorApproachPerfect);
          }
        }
      }
    }
  }

  /*
    // count "I" vs "i" and use that to determine mode
    function majorOrMinor(segment, processAll, endTick) {
      var majorCount = 0;
      while (segment && (processAll || segment.tick < endTick)) {
        var harmony = getRomanNumeral(segment, 0);
        if (harmony) {
          var rawRomanNumeral = harmony.text;
          var leftRomanNumeralClean = getRoman(rawRomanNumeral);
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
    */

  function checkForDissonantDownbeats(dyads) {
    for (var i = 0; i < dyads.length; i++) {
      if (dyads[i].interval) {
        if (dyads[i].downbeat && allowedVerticalIntervals.indexOf(dyads[i].interval) < 0) {
          var errorNotes = [];
          dyads[i].voices[0].color = colorVertical;
          dyads[i].voices[1].color = colorVertical;
          var msg = "Vertical " + intervalNames[dyads[i].interval + 11] + "\nis not allowed\non downbeat.";
          markText(0,dyads[i], msg, colorVertical);
        }
      }
    }
  }

  function checkHorizontalIntervals(dyads) {
    for (var i = 0; i < dyads.length - 1; i++) {
      for (var v = 0; v < dyads[i].voices.length; v++) {
        if (v != cantusFirmus && dyads[i].tpc[v] && dyads[i + 1].tpc[v]) {
          var horizontalInterval = dyads[i + 1].tpc[v] - dyads[i].tpc[v];
          if (dyads[i + 1].pitch[v] < dyads[i].pitch[v]) horizontalInterval *= -1;
          var horizontalDistance = Math.abs(dyads[i + 1].pitch[v] - dyads[i].pitch[v]);
          if (Math.abs(horizontalInterval) > 5 ||
            horizontalDistance == 10 ||
            horizontalDistance == 11) {
            dyads[i].voices[v].color = colorVoiceLeading;
            dyads[i + 1].voices[v].color = colorVoiceLeading;
            var msg = "Melodic " + intervalNames[horizontalInterval + 11] + "\nis not allowed.";
            markText(v,dyads[i], msg, colorVoiceLeading);
          }
          if (horizontalDistance > 12) {
            dyads[i].voices[v].color = colorVoiceLeading;
            dyads[i + 1].voices[v].color = colorVoiceLeading;
            var msg = "Leaps greater\nthan an octave\nare not allowed.";
            markText(v,dyads[i], msg, colorVoiceLeading);
          }
        }
      }
    }
  }

  function perfectFirst(dyads) {
    var first;
    for (var i = 0; i < dyads.length && !(first + 1); i++) {
      if (dyads[i].tpc[0] && dyads[i].tpc[1]) {
        first = i;
        if (!dyads[first].perfect) {
          var msg = "First interval\n must be\nP1, P5, or P8.";
          markText(0,dyads[i], msg, colorBeginningEnd);
          dyads[i].voices[0].color = colorBeginningEnd;
          dyads[i].voices[1].color = colorBeginningEnd;
        }
      }
    }
  }

  function checkApproachFinal(dyads) {
    var last, penultimate;
    for (var i = dyads.length - 1; i > 1; i--) {
      if (dyads[i].downbeat) {
        last = i;
        penultimate = i - 1;
        break;
      } else {
        if (dyads[i].voices[0]) dyads[i].voices[0].color = colorBeginningEnd;
        if (dyads[i].voices[1]) dyads[i].voices[1].color = colorBeginningEnd;
        var msg = "Extra note\nafter final.";
        markText(0,dyads[i], msg, colorBeginningEnd);
      }
    }
    if (dyads[last] && !dyads[last].perfect) {
      dyads[last].voices[0].color = colorBeginningEnd;
      dyads[last].voices[1].color = colorBeginningEnd;
      var msg = "Must end with\nP1, P5, or P8.";
      markText(0,dyads[last], msg, colorBeginningEnd);
    }
    var horizontalInterval = dyads[last].tpc[0] - dyads[penultimate].tpc[0];
    if (dyads[last].pitch[0] > dyads[penultimate].pitch[0] &&
      horizontalInterval != -5 && // ascending semitone
      dyads[penultimate].pitch[1] - dyads[last].pitch[1] != 1) { // unless plagal
      var msg = "Ascending final\nshould be\napproach by semitone.";
      dyads[last].voices[0].color = colorBeginningEnd;
      dyads[last].voices[1].color = colorBeginningEnd;
      dyads[penultimate].voices[0].color = colorBeginningEnd;
      dyads[penultimate].voices[1].color = colorBeginningEnd;
      markText(0,dyads[penultimate], msg, colorBeginningEnd);
    } else if (dyads[last].tpc[0] && dyads[penultimate].tpc[0]) {
      if (Math.abs(dyads[last].pitch[0] - dyads[penultimate].pitch[0]) > 2) { //larger than a step
        var msg = "Final must be\napproached by step.";
        dyads[last].voices[0].color = colorBeginningEnd;
        dyads[last].voices[1].color = colorBeginningEnd;
        dyads[penultimate].voices[0].color = colorBeginningEnd;
        dyads[penultimate].voices[1].color = colorBeginningEnd;
        markText(0,dyads[penultimate], msg, colorBeginningEnd);
      }
    }
  }

  function leapToFromDissonance(dyads) {
    for (var i = 0; i < dyads.length - 1; i++) {
      for (var v = 0; v < 2; v++) {
        if (v != cantusFirmus && dyads[i].interval) {
          //console.log("measure:", dyads[i].measure, Math.abs(dyads[i + 1].pitch[v] - dyads[i].pitch[v]));
          if (allowedVerticalIntervals.indexOf(dyads[i + 1].interval) < 0 && // dissonance
            Math.abs(dyads[i + 1].pitch[v] - dyads[i].pitch[v]) > 2) { // leap!
            var msg = "Leap to\ndissonance in\n" + voiceNames[v] + " part.";
            dyads[i].voices[v].color = colorLeaps;
            dyads[i + 1].voices[v].color = colorLeaps;
            markText(v,dyads[i], msg, colorLeaps);
          } else if (allowedVerticalIntervals.indexOf(dyads[i].interval) < 0 && // dissonance
            Math.abs(dyads[i + 1].pitch[v] - dyads[i].pitch[v]) > 2) { // leap!
            var msg = "Leap from\ndissonance in\n" + voiceNames[v] + " part.";
            dyads[i].voices[v].color = colorLeaps;
            dyads[i + 1].voices[v].color = colorLeaps;
            markText(v,dyads[i], msg, colorLeaps);
          }
        }
      }
    }
  }

  function stepBack(dyads) {
    for (var i = 0; i < dyads.length - 2; i++) {
      var lookingForStepback = true;
      for (var v = 0; v < 2; v++) {
        if (v != cantusFirmus && dyads[i].notehead[v]) {
          for (var top = i + 1; top < dyads.length - 1 && lookingForStepback; top++) {
            if (dyads[top] && dyads[top].notehead[v]) {
              var leapDirection = Math.sign(dyads[top].pitch[v] - dyads[i].pitch[v]);
              var leapSize = Math.abs(dyads[top].pitch[v] - dyads[i].pitch[v]);
              for (var back = top + 1; back < dyads.length && lookingForStepback; back++) {
                if (dyads[back] && dyads[back].notehead[v] &&
                  (dyads[back].pitch[v] != dyads[top].pitch[v])) {
                  var resolutionDirection = Math.sign(dyads[back].pitch[v] - dyads[top].pitch[v]);
                  var resolutionSize = Math.abs(dyads[back].pitch[v] - dyads[top].pitch[v]);
                  if (leapSize > 7 && (resolutionSize > 2 || resolutionDirection === leapDirection)) {
                    dyads[top].voices[v].color = colorVoiceLeading;
                    dyads[back].voices[v].color = colorVoiceLeading;
                    var msg = "Needs to\nstep back after\nlarge leap in\n" + voiceNames[v] + " part.";
                    markText(v,dyads[i], msg, colorVoiceLeading);
                  }
                  lookingForStepback = false;
                }
              }
            }
          }
        }
      }
    }
  }

  function consecutiveLeaps(dyads) {
    for (var i = 0; i < dyads.length - 3; i++) {
      for (var v = 0; v < 2; v++) {
        if (v != cantusFirmus && dyads[i].pitch[v] && dyads[i + 1].pitch[v] && dyads[i + 2].pitch[v] && dyads[i + 3].pitch[v]) {
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
            markText(v,dyads[i + 3], msg, colorConsecutive);
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
            markText(v,dyads[i], msg, colorConsecutive);
          }
        }
      }
    }
  }

  function outlinedTritone(dyads) {
    for (var i = 0; i < dyads.length - 3; i++) {
      for (var v = 0; v < 2; v++) {
        if (v != cantusFirmus && dyads[i].pitch[v] && dyads[i + 1].pitch[v] && dyads[i + 2].pitch[v] && dyads[i + 3].pitch[v]) {
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
            markText(v,dyads[i + 1], msg, colorConsecutive);
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

  function consecutiveImperfect(dyads) {
    for (var i = 0; i < dyads.length - 4; i++) {
      if (dyads[i].interval && dyads[i + 1].interval &&
        dyads[i + 2].interval && dyads[i + 3].interval &&
        dyads[i + 4].interval) {
        if (isThird(dyads[i].interval) && isThird(dyads[i + 1].interval) &&
          isThird(dyads[i + 2].interval) && isThird(dyads[i + 3].interval) &&
          isThird(dyads[i + 4].interval)) {
          dyads[i + 4].voices[0].color = colorConsecutive;
          dyads[i + 4].voices[1].color = colorConsecutive;
          var msg = "Too many\nconsecutive\nthirds.";
          markText(0,dyads[i + 4], msg, colorConsecutive);
        }
      }
    }
  }

  function ratioOfPerfect(dyads) {
    var perfectCount = 0;
    for (var i = 0; i < dyads.length; i++) {
      if (dyads[i].perfect) perfectCount++;
    }
    var msg;
    var ratio = perfectCount * 1.0 / dyads.length;
    console.log("Percentage of perfect intervals:", ratio * 100, "%");
    if (ratio >= 0.8) {
      var msg = "Too many perfect\nintervals.";
      markText(0,dyads[0], msg, colorInfo);
    }
    if (ratio > 0.55 && ratio < 0.8) {
      var msg = "Maybe too many\nperfect intervals.";
      markText(0,dyads[0], msg, colorInfo);
    }
  }

  function ratioOfLeaps(dyads) {
    var noteCount = 0;
    var leapCount = 0;
    for (var i = 0; i < dyads.length - 1; i++) {
      for (var v = 0; v < 2; v++) {
        if (v != cantusFirmus && dyads[i].pitch[v] && dyads[i + 1].pitch[v]) {
          if (dyads[i].pitch[v] != dyads[i + 1].pitch[v]) noteCount++;
          if (Math.abs(dyads[i].pitch[v] - dyads[i + 1].pitch[v]) > 2) leapCount++;
        }
      }
    }
    var ratio = leapCount * 1.0 / noteCount;
    console.log("Percentage of leaps:", ratio * 100, "%");
    if (ratio > 0.6) {
      var msg = "Too many leaps.";
      markText(0,dyads[0], msg, colorInfo);
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
      if (v != cantusFirmus && voiceRange < 10) markText(0,dyads[0], "Try to cover a\nwider melodic range\nin " + voiceNames[v] + " part.", colorInfo);
    }
  }

  function downbeatParallels(dyads) {
    var msg = "xxx";
    for (var i = 1; i < dyads.length - 1; i++) {
      if (dyads[i].downbeat && dyads[i].perfect) {
        var next;
        for (next = i + 1; next < dyads.length; next++) {
          if (dyads[next].downbeat) break;
        }
        if (dyads[next].downbeat && dyads[i].interval === dyads[next].interval) {
          var motion = getMotion(dyads[i].pitch[0], dyads[i].pitch[1], dyads[next].pitch[0], dyads[next].pitch[1]);
          switch (motion) {
            case "similar":
              msg = "Downbeat\nparallel " + intervalNames[dyads[i].interval + 11] + ".";
              break;
            case "contrary":
              msg = "Downbeat\ncontrary " + intervalNames[dyads[i].interval + 11] + ".";
              break;
          }
          dyads[next].voices[0].color = colorVertical;
          dyads[next].voices[1].color = colorVertical;
          dyads[i].voices[0].color = colorVertical;
          dyads[i].voices[1].color = colorVertical;
          markText(0,dyads[i], msg, colorVertical);
          break;
        }
      }
    }
  }

  function typeOfNCT(dyads) {
    for (var v = 0; v < 2; v++) {
      for (var i = 0; i < dyads.length - 1; i++) {
        if (v != cantusFirmus && dyads[i].notehead[v] && !dyads[i].downbeat) {
          var prev = dyads[i - 1];
          var next = dyads[i + 1];
          if (prev && next && prev.pitch[v] && next.pitch[v] &&
            allowedVerticalIntervals.indexOf(dyads[i].interval) < 0) {
            if (prev.pitch[v] == next.pitch[v] && Math.abs(prev.pitch[v] - dyads[i].pitch[v]) <= 2) {
              dyads[i].voices[v].color = colorLeaps;
              var msg = "Neighbor tones\nare not allowed\nin Species II.";
              //console.log("Neighbor tone found in measure", dyads[i].measure + ". This is an error in second species but not in third species.");
              markText(v,dyads[i - 1], msg, colorLeaps);
            } else if (Math.abs(prev.pitch[v] - next.pitch[v]) <= 4 && Math.abs(prev.pitch[v] - next.pitch[v]) > 2) {
              //console.log("Passing tone found in measure", dyads[i].measure + ". This is not an error in second or third species.");
              //markText(v,dyads[i], "PT", colorLeaps);
            }
          }
        }
      }
    }
  }

  function checkForVoiceCrossing(dyads) {
    for (var i = 0; i < dyads.length; i++) {
      if (dyads[i] && dyads[i].pitch[0] && dyads[i].pitch[1]) {
        if (dyads[i].pitch[1] > dyads[i].pitch[0]) {
          if (dyads[i].downbeat) {
            dyads[i].voices[0].color = colorInfo;
            dyads[i].voices[1].color = colorInfo;
          }
          var msg = "Don't cross\nvoices.";
          if (dyads[i].notehead[0]) markText(0, dyads[i], msg, colorInfo);
          else if (dyads[i].notehead[1]) markText(1, dyads[i], msg, colorInfo);
        }
      }
    }
  }

  //------------------------------------------------------------------------------

  onRun: {
    if (typeof curScore == 'undefined' || curScore == null) {
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

    // go through all staves/voices simultaneously
    if (processAll) {
      //cursor.track = 0;
      cursor.rewind(0);
    } else {
      cursor.rewind(1);
    }
    var segment = cursor.segment;

    //key = cursor.keySignature + majorOrMinor(segment, processAll, endTick);
    var dyads = getDyads(segment, processAll, endTick);

    typeOfNCT(dyads);

    checkForVoiceCrossing(dyads);
    perfectFirst(dyads);
    checkApproachFinal(dyads);

    checkHorizontalIntervals(dyads);
    stepBack(dyads);

    consecutiveImperfect(dyads);

    ratioOfPerfect(dyads);
    ratioOfLeaps(dyads);
    melodicRange(dyads);

    checkForDissonantDownbeats(dyads);
    checkApproachToPerfect(dyads);
    downbeatParallels(dyads);

    leapToFromDissonance(dyads);
    consecutiveLeaps(dyads);
    outlinedTritone(dyads);

    if (noErrorsFound) {
      msgWarning.text = "Great job! No errors found.";
      msgWarning.visible = true;
    }
    Qt.quit();
  }

  /*
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
      "9": 0, // we won't do inversions of ninth dyads
    });

    property
    var dyadDefinitions: Object.freeze({
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
  */

  property
  var voiceNames: Object.freeze({
    0: "upper",
    1: "lower",
    2: "neither"
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
