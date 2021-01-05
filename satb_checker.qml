import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 3.0

MuseScore {
  menuPath: "Plugins.Proof Reading.SATB Checker"
  description: "Check 4-part writing for errors.\nIf roman numerals are present, will check for correct pitches.\nRoman numerals may also include applied (secondary) chords, Neapolitan, and augmented sixth chords.";
  version: "0.3"

  // colors taken from this palette: https://coolors.co/003049-d62828-f77f00-fcbf49-eae2b7
  property
  var colorError: "#d62828";
  property
  var colorWarning: "#f77f00";
  property
  var colorInfo: "#fcbf49";
  property
  var colorText: "003049";

  property
  var voiceRanges: [
    [40, 60], // bass
    [48, 67], // tenor
    [55, 74], // alto
    [60, 79] // soprano
  ];

  property bool noErrorsFound: true; // yet... :)
  property bool processAll: false;
  property bool harmonyFound: true;

  property
  var key: 14;

  MessageDialog {
    id: msgWarning
    title: "Warning"
    text: "No roman numerals found."

    onAccepted: {
      Qt.quit();
    }

    visible: false;
  }

  function markText(chord, msg) {
    var myText = newElement(Element.STAFF_TEXT);
    myText.text = msg;
    noErrorsFound = false;
    var cursor = curScore.newCursor();
    cursor.rewindToTick(chord.tick);
    cursor.add(myText);
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

  function assignVoices(segment, measure) {
    // first, check for keyboard style
    var voices = [];
    var voiceIndex = 0;
    for (var layer = 7; layer >= 0; layer--) {
      if (segment.elementAt(layer)) {
        var thisLayerNotes = segment.elementAt(layer).notes;
        if (thisLayerNotes) {
          for (var v = 0; v < thisLayerNotes.length; v++) {
            voices[voiceIndex++] = thisLayerNotes[v];
            if (voiceIndex > 4) {
              msgWarning.text = "Too many notes in measure " + measure + ".\nThis plugin only works on 4 voices.";
              msgWarning.visible = true;
              Qt.quit();
            }
          }
        }
      }
    }
    return voices;
  }

  function getPitches(segment, measure) {
    // step 1: read pitches
    if (segment.elementAt(4).type == Element.CHORD ||
      segment.elementAt(4).type == Element.REST) {

      var voices = assignVoices(segment, measure);
      if (!segment.elementAt(0).notes) {
        msgWarning.text = "Empty treble staff.";
        msgWarning.visible = true;
      }
      return voices;
    }
  }

  function getChords(segment, processAll, endTick) {
    var index = 0;
    var measure = 1;
    var chords = new Array();
    chords[index] = new Object;

    while (segment && (processAll || segment.tick < endTick)) {
      if (segment.tick > chords[index].tick) {
        index++;
        chords[index] = new Object;
      }

      chords[index].tick = segment.tick;
      chords[index].measure = measure;

      var voices = getPitches(segment, measure);
      if (voices) {
        chords[index].voices = [];
        chords[index].pitches = [];
        chords[index].tpc = [];
        chords[index].voices = voices; // use this to color error noteheads
        for (var i = 0; i < voices.length; i++) {
          chords[index].pitches[i] = voices[i].pitch;
          chords[index].tpc[i] = voices[i].tpc1;
        }
        var harmony = getRomanNumeral(segment, measure);
        if (harmony) {
          var rawRomanNumeral = harmony.text;
          var figBass = getFiguredBass(rawRomanNumeral);
          var leftRomanNumeralClean = getRoman(rawRomanNumeral);
          var tonicTPC = getTonicTPC(rawRomanNumeral);
          var quality = getQuality(leftRomanNumeralClean);
          var inversion = getInversion(rawRomanNumeral);

          //console.log(rawRomanNumeral, figBass, leftRomanNumeralClean, tonicTPC, quality);

          chords[index].roman = leftRomanNumeralClean;
          var chordDef = chordDefinitions[leftRomanNumeralClean];
          chords[index].romanPitches = [];
          chords[index].key = tonicTPC;
          for (var i = 0; i < chordDef.length; i++) {
            chords[index].romanPitches[i] = chordDef[i];
          }
          chords[index].quality = quality;
          addSeventhNinth(chords[index], quality, figBass);
          secondaryAdjustments(chords[index].romanPitches, tonicTPC);
          chords[index].inversion = inversion;
          //console.log("pitches:", chords[index].tpc, "romanPitches:", chords[index].romanPitches);
        }
      }

      if (segment.elementAt(0) && segment.elementAt(0).type == Element.BAR_LINE) measure++;
      segment = segment.next;
    }
    return chords;
  }

  function getRoman(rn) {
    return rn.split('/')[0].replace(/[2345679]/g, '');
  }

  function getFiguredBass(rn) {
    return rn.split('/')[0].replace(/[^2345679]/g, '');
  }

  function getTonicTPC(rn, measure) {
    var tonic = rn.replace(/[2345679]/g, '').split('/')[1];
    if (tonic) {
      var tonicChord = chordDefinitions[tonic];
      if (tonicChord[0]) return tonicChord[0] + key;
      else {
        msgWarning.text = "There's something wrong with the secondary chord in measure " + measure;
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
        quality = "halfdim7";
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
    var rn = getRoman(roman); // this is ugly; basically just for augmented sixth chords
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
        } else if ("minor" === quality || "dominant" === quality || "halfdim7" === quality) {
          c.romanPitches.push(rootTPC - 2);
        }
    }
    if ("9" === figBass) c.romanPitches.push(rootTPC + 2);
  }

  function processPitches() {} // maybe we don't need this?

  function isBetween(val, low, hi) {
    if (val < low) return false;
    if (val > hi) return false;
    return true;
  }

  function checkVoiceRanges(chords) {
    for (var i = 0; i < chords.length; i++) {
      for (var v = 0; v < 4; v++) {
        if (chords[i].pitches) {
          if (!isBetween(chords[i].pitches[v], voiceRanges[v][0], voiceRanges[v][1])) {
            // voice is out of range - color note and add error message
            chords[i].voices[v].color = colorError;
            var msg = "Out of range (" + voiceNames[v] + ").";
            markText(chords[i], msg);
          }
        }
      }
    }
  }

  function checkVoiceCrossing(chords) {
    var voiceLabels = ["Ten-alto", "Alto-sopr"];
    for (var i = 0; i < chords.length; i++) {
      for (var v = 0; v < 3; v++) {
        if (chords[i].pitches) {
          if (chords[i].pitches[v] > chords[i].pitches[v + 1]) {
            chords[i].voices[v].color = colorError;
            chords[i].voices[v + 1].color = colorError;
            var msg = voiceLabels[v - 1] + " voices cross.";
            markText(chords[i], msg);
          }
        }
      }
    }
  }

  function checkVoiceSpacing(chords) {
    var voiceLabels = ["Ten-alto", "Alto-sopr"];
    for (var i = 0; i < chords.length; i++) {
      for (var v = 1; v < 3; v++) {
        if (chords[i].pitches) {
          if (chords[i].pitches[v + 1] - chords[i].pitches[v] > 12) {
            chords[i].voices[v].color = colorError;
            chords[i].voices[v + 1].color = colorError;
            var msg = voiceLabels[v - 1] + " spacing.";
            markText(chords[i], msg);
          }
        }
      }
    }
  }

  function checkForWrongPitches(chords) {
    for (var i = 0; i < chords.length; i++) {
      if (chords[i].romanPitches) {
        var correctPitches = chords[i].romanPitches;
        for (var v = 0; v < 4; v++) {
          var testPitch = chords[i].tpc[v];
          if (correctPitches.indexOf(testPitch) < 0) {
            var correctPitch = correctPitches[v];
            chords[i].voices[v].color = colorError;
            var msg = "Wrong note in " + voiceNames[v] + ".\nIt should be " + tpcName(correctPitch);
            markText(chords[i], msg);
          }
        }
      }
    }
  }

  function checkForWrongInversion(chords) {
    for (var i = 0; i < chords.length; i++) {
      if (chords[i].tpc && chords[i].roman) {
        var inversion = chords[i].inversion;
        var correctBassNote = chords[i].romanPitches[inversion];
        if (chords[i].tpc[0] != correctBassNote) {
          chords[i].voices[0].color = colorError;
          var msg = "Inversion error:\nbass note should be " + tpcName(correctBassNote) + ".";
          markText(chords[i], msg);
        }
      }
    }
  }

  function checkForDoubledLT(chords) {
    for (var i = 0; i < chords.length; i++) {
      var leadingTones = [];
      if (chords[i].tpc && chords[i].roman) {
        for (var v = 0; v < 4; v++) {
          if (chords[i].tpc[v] == chords[i].key + 5) leadingTones.push(chords[i].voices[v]);
        }
      }
      if (leadingTones.length > 1) {
        for (var z = 0; z < leadingTones.length; z++) {
          leadingTones[z].color = colorError;
        }
        var msg = "Doubled LT of key.";
        markText(chords[i], msg);
      }
    }
  }

  function checkForMissingTones(chords) {
    for (var i = 0; i < chords.length; i++) {
      if (chords[i].tpc && chords[i].romanPitches) {
        var root = chords[i].romanPitches[0];
        var third = chords[i].romanPitches[1];
        if (chords[i].tpc.indexOf(root) < 0) {
          markText(chords[i], "Missing root.");
        }
        if (chords[i].tpc.indexOf(third) < 0) {
          markText(chords[i], "Missing 3rd.");
        }
        if (chords[i].romanPitches.length > 3) {
          // check for seventh
          var seventh = chords[i].romanPitches[3];
          if (chords[i].tpc.indexOf(seventh) < 0) {
            markText(chords[i], "Missing 7th.");
          }
        }
        if (chords[i].romanPitches.length > 4) {
          // check for ninth
          var ninth = chords[i].romanPitches[4];
          if (chords[i].tpc.indexOf(ninth) < 0) {
            markText(chords[i], "Missing 9th.");
          }
        }
        if ("It" === chords[i].roman ||
          "Ger" === chords[i].roman ||
          "Fr" === chords[i].roman) {
          // check for remaining tone
          var aug6Tone = chords[i].romanPitches[2];
          if (chords[i].tpc.indexOf(aug6Tone) < 0) {
            markText(chords[i], "Missing " + tpcName(aug6Tone) + " from\n" + chords[i].roman + "6 chord.");
          }
        }
      }
    }
  }

  function getIntervalDirection(lower1, upper1, lower2, upper2) {
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
  function checkForParallels(chords) {
    for (var i = 0; i < chords.length - 1; i++) {
      if (chords[i].tpc && chords[i + 1].tpc) {
        for (var lowerVoice = 0; lowerVoice < 3; lowerVoice++) {
          for (var upperVoice = lowerVoice + 1; upperVoice < 4; upperVoice++) {
            var direction = getIntervalDirection(chords[i].pitches[lowerVoice], chords[i].pitches[upperVoice],
              chords[i + 1].pitches[lowerVoice], chords[i + 1].pitches[upperVoice]);
            // check for octaves
            if (chords[i].tpc[lowerVoice] == chords[i].tpc[upperVoice]) {
              if (chords[i + 1].tpc[lowerVoice] == chords[i + 1].tpc[upperVoice]) {
                if ("similar" == direction) {
                  // PARALLEL OCTAVES! OH NO!
                  chords[i].voices[lowerVoice].color = colorError;
                  chords[i].voices[upperVoice].color = colorError;
                  chords[i + 1].voices[lowerVoice].color = colorError;
                  chords[i + 1].voices[upperVoice].color = colorError;
                  var msg = "Parallel P8\n(" + voiceNames[lowerVoice] + "-" + voiceNames[upperVoice] + ").";
                  markText(chords[i], msg);
                } else if ("contrary" == direction) {
                  // HIDDEN (contrary) OCTAVES!
                  chords[i].voices[lowerVoice].color = colorWarning;
                  chords[i].voices[upperVoice].color = colorWarning;
                  chords[i + 1].voices[lowerVoice].color = colorWarning;
                  chords[i + 1].voices[upperVoice].color = colorWarning;
                  var msg = "Hidden P8\n(" + voiceNames[lowerVoice] + "-" + voiceNames[upperVoice] + ").";
                  markText(chords[i], msg);
                }
              }
            }

            // check for fifths
            if (chords[i].tpc[upperVoice] - chords[i].tpc[lowerVoice] == 1) {
              if (chords[i + 1].tpc[upperVoice] - chords[i + 1].tpc[lowerVoice] == 1) {
                // successive fifth found
                if ("similar" == direction) {
                  // PARALLEL OCTAVES! OH NO!
                  chords[i].voices[lowerVoice].color = colorError;
                  chords[i].voices[upperVoice].color = colorError;
                  chords[i + 1].voices[lowerVoice].color = colorError;
                  chords[i + 1].voices[upperVoice].color = colorError;
                  var msg = "Parallel P5\n(" + voiceNames[lowerVoice] + "-" + voiceNames[upperVoice] + ").";
                  markText(chords[i], msg);
                } else if ("contrary" == direction) {
                  // HIDDEN (contrary) OCTAVES!
                  chords[i].voices[lowerVoice].color = colorWarning;
                  chords[i].voices[upperVoice].color = colorWarning;
                  chords[i + 1].voices[lowerVoice].color = colorWarning;
                  chords[i + 1].voices[upperVoice].color = colorWarning;
                  var msg = "Hidden P5\n(" + voiceNames[lowerVoice] + "-" + voiceNames[upperVoice] + ").";
                  markText(chords[i], msg);
                }
              }
            }
          }
        }
      }
    }
  }

  function checkForSopranoLTP(chords) {
    for (var i = 0; i < chords.length - 1; i++) {
      if (chords[i].tpc && chords[i + 1].tpc) {
        var soprano = 3;
        var bass = 0;
        var direction = getIntervalDirection(chords[i].pitches[bass], chords[i].pitches[soprano],
          chords[i + 1].pitches[bass], chords[i + 1].pitches[soprano]);
        // 3 conditions to meet between bass and soprano
        // 1. similar motion
        // 2. soprano is leaping, not stepping
        // 3. soprano lands on P5 or P8
        var melodicDist = Math.abs(chords[i].pitches[soprano] - chords[i + 1].pitches[soprano]);
        if ("similar" === direction && //1
          melodicDist > 2 && //2
          ((chords[i + 1].tpc[soprano] - chords[i + 1].tpc[bass] == 1) || //3
            (chords[i + 1].tpc[soprano] == chords[i + 1].tpc[bass]))
        ) {
          chords[i].voices[soprano].color = colorWarning;
          chords[i + 1].voices[soprano].color = colorWarning;
          var msg = "Soprano leaps to\nperfect interval\nin similar motion.";
          markText(chords[i + 1], msg);
          //console.log("soprano leaped to perfect interval in similar motion");
        }
      }
    }
  }

  // LT in soprano must resolve up to tonic on "V" -> "I" or "i"
  // LT in soprano must resolve up to tonic on "viio" or "vii0" -> "I" or "i"
  // In other voices, give as info
  // I think this won't affect secondary dominants (for now we'll ignore)
  function checkForLTResolution(chords) {
    for (var i = 0; i < chords.length - 1; i++) {
      if (chords[i].tpc && chords[i + 1].tpc) {
        if (("I" === chords[i + 1].roman || "i" === chords[i + 1].roman) &&
          ("V" === chords[i].roman || "viio" === chords[i].roman || "vii0" === chords[i].roman)) {
          // cadential motion confirmed!
          var v = 3; // check soprano first
          if ((chords[i].tpc[v] == key + 5) && chords[i + 1].tpc[v] != key) {
            // uh oh! LT was in soprano and didn't resolve up to tonic
            chords[i].voices[3].color = colorError;
            chords[i + 1].voices[3].color = colorError;
            var msg = "Leading tone in soprano\nmust resolve up to\ntonic on V-I or viio-I";
            markText(chords[i + 1], msg);
          }
          for (v = 0; v < 3; v++) {
            if ((chords[i].tpc[v] == key + 5) && chords[i + 1].tpc[v] != key) {
              // If LT doesn't resolve up in other voices it's just info
              chords[i].voices[v].color = colorInfo;
              chords[i + 1].voices[v].color = colorInfo;
              var msg = "FYI: Leading tone in " + voiceNames[v] + "\nisn't resolving up to tonic\n(free resolution)";
              markText(chords[i + 1], msg);
            }
          }
        }
      }
    }
  }

  // let's say that chordal sevenths must resolve downward by step or remain the same
  // unless it's an aug6 chord, in which case it must resolve up by semitone or stay the same (rare)
  function checkFor7thResolution(chords) {
    for (var i = 0; i < chords.length - 1; i++) {
      if (chords[i].tpc && chords[i + 1].tpc) {
        if (chords[i].tpc.length > 3) { // seventh (or 9th) chord found
          for (var v = 0; v < 4; v++) {
            if (chords[i].tpc[v] === chords[i].romanPitches[3]) { //which voice has seventh?
              if ("aug6" === chords[i].quality) {
                if ((chords[i + 1].pitches[v] - chords[i].pitches[v] > 1) ||
                  (chords[i + 1].pitches[v] - chords[i].pitches[v] < 0)) {
                  chords[i].voices[v].color = colorError;
                  chords[i + 1].voices[v].color = colorError;
                  var msg = "Aug6 (" + tpcName(chords[i].tpc[v]) + ") must resolve\nup by semitone.";
                  markText(chords[i], msg);
                }
              } else {
                if ("dominant" === chords[i].quality || "diminished" === chords[i].quality) {
                  var melodicDist = chords[i + 1].pitches[v] - chords[i].pitches[v];
                  if ((chords[i + 1].pitches[v] - chords[i].pitches[v] > 0) ||
                    (chords[i + 1].pitches[v] - chords[i].pitches[v] < -2)) {
                    chords[i].voices[v].color = colorError;
                    chords[i + 1].voices[v].color = colorError;
                    var msg = "Chordal 7th of dominant\nmust resolve down by step.";
                    markText(chords[i], msg);
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  // count "I" vs "i" and use that to determine mode
  function majorOrMinor(segment, processAll, endTick) {
    var majorCount = 0;
    while (segment && (processAll || segment.tick < endTick)) {
      var harmony = getRomanNumeral(segment, 0);
      if (harmony) {
        var rawRomanNumeral = harmony.text;
        var leftRomanNumeralClean = getRoman(rawRomanNumeral);
        if ("I" === leftRomanNumeralClean) majorCount++;
        else if ("i" === leftRomanNumeralClean) majorCount--;
      }
      segment = segment.next;
    }
    if (majorCount >= 0) {
      console.log("Hmm... this looks to me like it's a MAJOR key.");
      return 14; // major key
    } else {
      console.log("Hmm... this looks to me like it's a MINOR key.");
      return 17; // minor key
    }
    return 0;
  }

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

    key = cursor.keySignature + majorOrMinor(segment, processAll, endTick);
    var chords = getChords(segment, processAll, endTick);

    checkForLTResolution(chords);
    checkFor7thResolution(chords);
    checkForSopranoLTP(chords);
    checkForParallels(chords);

    checkForMissingTones(chords);
    checkForDoubledLT(chords);
    checkForWrongInversion(chords);
    checkForWrongPitches(chords);
    checkVoiceSpacing(chords);
    checkVoiceCrossing(chords);
    checkVoiceRanges(chords);

    if (noErrorsFound) {
      msgWarning.text = "Great job! No errors found.";
      msgWarning.visible = true;
    }
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
  var voiceNames: Object.freeze({
    0: "bass",
    1: "tenor",
    2: "alto",
    3: "soprano"
  });

  property
  var trebleStaff: 0;
  property
  var bassStaff: 0;

}
