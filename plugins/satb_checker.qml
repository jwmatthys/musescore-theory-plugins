import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 3.0

MuseScore {
  menuPath: "Plugins.Proof Reading.SATB Checker"
  description: "Check 4-part writing for errors.\nIf roman numerals are present, will check for correct pitches.\nRoman numerals may also include applied (secondary) chords, Neapolitan, and augmented sixth chords.";
  version: "0.34"

  property
  var colorOrchestrationError: "#AF6E4D"; // Range / Crossing / Spacing - brown
  property
  var colorPitchError: "#CE2029"; // Wrong pitch & Inversion error
  property
  var colorInversionError: "#FEDF00";
  property
  var colorDoubledLTError: "#600887";
  property
  var colorMissingTones: "#009F6B";
  property
  var colorParallelPerfect: "#FF4F00";
  property
  var colorContraryPerfect: "#C74375";
  property
  var colorVoiceLeadingWarning: "#DA9100";
  property
  var colorTendencyToneError: "#0047AB";
  property
  var colorTendencyToneWarning: "#8CC5CE";

  property
  var voiceRanges: [
    [40, 60], // bass
    [48, 67], // tenor
    [55, 74], // alto
    [60, 79] // soprano
  ];

  property
  var allRomanNumerals: [
    "I",
    "II",
    "III",
    "IV",
    "V",
    "VI",
    "VII",
    "FR",
    "GER",
    "IT",
    "CAD",
    "CT",
    "N"
  ];

  property bool majorMode: true;
  property bool noErrorsFound: true; // yet... :)
  property bool processAll: false;
  property bool harmonyFound: true;

  property
  var key: 14;
  property
  var keyMode: 0;

  MessageDialog {
    id: msgWarning
    title: "Warning"
    text: "No roman numerals found."

    onAccepted: {
      Qt.quit();
    }

    visible: false;
  }

  function markText(chord, msg, color) {
    var myText = newElement(Element.STAFF_TEXT);
    myText.text = msg;
    myText.color = color;
    noErrorsFound = false;
    var cursor = curScore.newCursor();
    cursor.rewindToTick(chord.tick);
    cursor.add(myText);
  }

  function isThisARomanNumeral(annotation) {
    var testElement = annotation.text.toUpperCase().split('/')[0].replace(/[^IVNFRGERCADT/]/g, '');
    if (allRomanNumerals.indexOf(testElement) >= 0) return true;
    return false;
  }

  function getRomanNumeral(segment) {
    var aCount = 0;
    var annotation = segment.annotations[aCount];
    while (annotation) {
      if (annotation.type == Element.HARMONY) {
        if (isThisARomanNumeral(annotation)) return annotation;
      }
      annotation = segment.annotations[++aCount];
    }
    return null;
  }

  function assignVoices(segment) {
    // first, check for keyboard style
    var voices = [];
    var voiceIndex = 0;
    for (var layer = 7; layer >= 0; layer--) {
      if (segment.elementAt(layer)) {
        var thisLayerNotes = segment.elementAt(layer).notes;
        if (thisLayerNotes) {
          for (var v = 0; v < thisLayerNotes.length; v++) {
            voices[voiceIndex++] = thisLayerNotes[v];
            //console.log(thisLayerNotes[v].pitch);
          }
        }
      }
    }
    return voices;
  }

  function getPitches(segment) {
    // step 1: read pitches
    if (segment && segment.elementAt(4) &&
      (segment.elementAt(4).type == Element.CHORD ||
        segment.elementAt(4).type == Element.REST)) {

      var voices = assignVoices(segment);
      return voices;
    }
  }

  function getChords(cursor, processAll, endTick) {
    var index = 0;
    var chords = new Array();
    chords[index] = new Object;
    do {
      var segment = cursor.segment;
      if (!processAll && segment.tick >= endTick) break;
      if (segment.tick > chords[index].tick) {
        index++;
        chords[index] = new Object;
      }

      chords[index].tick = segment.tick;

      var voices = getPitches(segment);
      if (voices) {
        chords[index].voices = [];
        chords[index].pitches = [];
        chords[index].tpc = [];
        chords[index].voices = voices; // use this to color error noteheads
        for (var i = 0; i < voices.length; i++) {
          chords[index].pitches[i] = voices[i].pitch;
          chords[index].tpc[i] = voices[i].tpc1;
        }
        var harmony = getRomanNumeral(segment);
        if (harmony) {
          var rawRomanNumeral = harmony.text;
          if ("Cad64" === rawRomanNumeral || "cad64" === rawRomanNumeral) {
            if (majorMode) rawRomanNumeral = "I64";
            else rawRomanNumeral = "i64";
          }
          var figBass = getFiguredBass(rawRomanNumeral);
          var leftRomanNumeralClean = getRoman(rawRomanNumeral);
          var tonicTPC = getTonicTPC(rawRomanNumeral) + cursor.keySignature + keyMode;
          var quality = getQuality(leftRomanNumeralClean);
          var inversion = getInversion(rawRomanNumeral);
          chords[index].roman = leftRomanNumeralClean;
          var chordDef = chordDefinitions[leftRomanNumeralClean];
          if (chordDef) {
            chords[index].romanPitches;
            chords[index].key = tonicTPC;
            chords[index].romanPitches = [];
            for (var i = 0; i < chordDef.length; i++) {
              chords[index].romanPitches[i] = chordDef[i];
            }
            chords[index].quality = quality;
            addSeventhNinth(chords[index], quality, figBass);
            secondaryAdjustments(chords[index].romanPitches, tonicTPC);
            chords[index].inversion = inversion;
          } else {
            var msg = "Unrecognized\nroman numeral\n\"" + leftRomanNumeralClean + "\".";
            markText(chords[index], msg, colorOrchestrationError);
          }
          //console.log("pitches:", chords[index].tpc, "romanPitches:", chords[index].romanPitches);
        }
      }
    } while (cursor.next());
    return chords;
  }

  function getRoman(rn) {
    return rn.split('/')[0].replace(/[^IiVvo0NFrGe/]/g, '');
  }

  function getFiguredBass(rn) {
    return rn.split('/')[0].replace(/[^2345679]/g, '');
  }

  function getTonicTPC(rn) {
    var tonic = rn.replace(/[2345679]/g, '').split('/')[1];
    if (tonic) {
      var tonicChord = chordDefinitions[tonic];
      if (tonicChord[0]) return tonicChord[0];
      else {
        msgWarning.text = "There's something wrong with the secondary chord " + rn;
        msgWarning.visible = true;
        Qt.quit();
      }
    }
    return 0;
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

  function isBetween(test, lo, hi) {
    return (Math.sign(test - lo) === Math.sign(hi - test));
  }

  function isWithin(test, low, high) {
    if (test > high) return false;
    if (test < low) return false;
    return true;
  }

  function checkVoiceRanges(chords) {
    for (var i = 0; i < chords.length; i++) {
      if (chords[i].pitches) {
        for (var v = 0; v < 4; v++) {
          if (chords[i].pitches) {
            if (!isWithin(chords[i].pitches[v], voiceRanges[v][0], voiceRanges[v][1])) {
              // voice is out of range - color note and add error message
              chords[i].voices[v].color = colorOrchestrationError;
              var msg = "Out of range (" + voiceNames[v] + ").";
              markText(chords[i], msg, colorOrchestrationError);
            }
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
            chords[i].voices[v].color = colorOrchestrationError;
            chords[i].voices[v + 1].color = colorOrchestrationError;
            var msg = voiceLabels[v - 1] + " voices cross.";
            markText(chords[i], msg, colorOrchestrationError);
          }
        }
      }
    }
  }

  function checkNumVoices(chords) {
    for (var i = 0; i < chords.length; i++) {
      if (chords[i].pitches) {
       if (chords[i].pitches.length > 4) {
        var msg = "Extra note(s).";
        markText(chords[i], msg, colorOrchestrationError);
      } else if (chords[i].pitches.length < 4) {
        var msg = "Missing part.";
        markText(chords[i], msg, colorOrchestrationError);
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
            chords[i].voices[v].color = colorOrchestrationError;
            chords[i].voices[v + 1].color = colorOrchestrationError;
            var msg = voiceLabels[v - 1] + " spacing.";
            markText(chords[i], msg, colorOrchestrationError);
          }
        }
      }
    }
  }

  function checkForWrongPitches(chords) {
    for (var i = 0; i < chords.length; i++) {
      if (chords[i].romanPitches) {
        var correctPitches = chords[i].romanPitches;
        for (var v = 0; v < chords[i].pitches.length; v++) {
          var testPitch = chords[i].tpc[v];
          if (correctPitches.indexOf(testPitch) < 0) {
            var correctPitch = correctPitches[v];
            chords[i].voices[v].color = colorPitchError;
            if (("V" === chords[i].roman || "viio" === chords[i].roman || "vii0" === chords[i].roman) &&
              (chords[i].tpc[v] === chords[i].key - 2)) {
              var msg = "You need to raise\nthe leading tone in\nthe " + voiceNames[v] + ".";
              markText(chords[i], msg, colorPitchError);
            } else {
              var msg = "Wrong note in " + voiceNames[v] + ".";
              markText(chords[i], msg, colorPitchError);
            }
          }
        }
      }
    }
  }

  function checkForWrongInversion(chords) {
    for (var i = 0; i < chords.length; i++) {
      if (chords[i].tpc && chords[i].romanPitches) {
        var inversion = chords[i].inversion;
        var correctBassNote = chords[i].romanPitches[inversion];
        var correctPitches = chords[i].romanPitches;
        var testPitch = chords[i].tpc[0];
        var bassNoteIsInChord = !(correctPitches.indexOf(testPitch) < 0);
        if (bassNoteIsInChord && testPitch != correctBassNote) {
          chords[i].voices[0].color = colorInversionError;
          var msg = "Inversion: bass\nshould be " + tpcName(correctBassNote) + ".";
          markText(chords[i], msg, colorInversionError);
        }
      }
    }
  }

  function checkForDoubledLT(chords) {
    for (var i = 0; i < chords.length; i++) {
      var leadingTones = [];
      if (chords[i].tpc && chords[i].roman) {
        for (var v = 0; v < chords[i].tpc.length; v++) {
          if (chords[i].tpc[v] == chords[i].key + 5) leadingTones.push(chords[i].voices[v]);
        }
      }
      if (leadingTones.length > 1) {
        for (var z = 0; z < leadingTones.length; z++) {
          leadingTones[z].color = colorDoubledLTError;
        }
        var msg = "Doubled LT of key.";
        markText(chords[i], msg, colorDoubledLTError);
      }
    }
  }

  function checkForMissingTones(chords) {
    for (var i = 0; i < chords.length; i++) {
      if (chords[i].tpc && chords[i].romanPitches) {
        var root = chords[i].romanPitches[0];
        var third = chords[i].romanPitches[1];
        if (chords[i].tpc.indexOf(root) < 0) {
          markText(chords[i], "Missing root.", colorMissingTones);
        }
        if (chords[i].tpc.indexOf(third) < 0) {
          markText(chords[i], "Missing 3rd.", colorMissingTones);
        }
        if (chords[i].romanPitches.length > 3) {
          // check for seventh
          var seventh = chords[i].romanPitches[3];
          if (chords[i].tpc.indexOf(seventh) < 0) {
            markText(chords[i], "Missing 7th.", colorMissingTones);
          }
        }
        if (chords[i].romanPitches.length > 4) {
          // check for ninth
          var ninth = chords[i].romanPitches[4];
          if (chords[i].tpc.indexOf(ninth) < 0) {
            markText(chords[i], "Missing 9th.", colorMissingTones);
          }
        }
        if ("It" === chords[i].roman ||
          "Ger" === chords[i].roman ||
          "Fr" === chords[i].roman) {
          // check for remaining tone
          var aug6Tone = chords[i].romanPitches[2];
          if (chords[i].tpc.indexOf(aug6Tone) < 0) {
            var msg = "Missing " + tpcName(aug6Tone) + " from\n" + chords[i].roman + "6 chord."
            markText(chords[i], msg, colorMissingTones);
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
                  chords[i].voices[lowerVoice].color = colorParallelPerfect;
                  chords[i].voices[upperVoice].color = colorParallelPerfect;
                  chords[i + 1].voices[lowerVoice].color = colorParallelPerfect;
                  chords[i + 1].voices[upperVoice].color = colorParallelPerfect;
                  var msg = "Parallel P8\n(" + voiceNames[lowerVoice] + "-" + voiceNames[upperVoice] + ").";
                  markText(chords[i], msg, colorParallelPerfect);
                } else if ("contrary" == direction) {
                  // HIDDEN (contrary) OCTAVES!
                  chords[i].voices[lowerVoice].color = colorContraryPerfect;
                  chords[i].voices[upperVoice].color = colorContraryPerfect;
                  chords[i + 1].voices[lowerVoice].color = colorContraryPerfect;
                  chords[i + 1].voices[upperVoice].color = colorContraryPerfect;
                  var msg = "Contrary P8\n(" + voiceNames[lowerVoice] + "-" + voiceNames[upperVoice] + ").";
                  markText(chords[i], msg, colorContraryPerfect);
                }
              }
            }

            // check for fifths
            if (chords[i].tpc[upperVoice] - chords[i].tpc[lowerVoice] == 1) {
              if (chords[i + 1].tpc[upperVoice] - chords[i + 1].tpc[lowerVoice] == 1) {
                // successive fifth found
                if ("similar" == direction) {
                  // PARALLEL OCTAVES! OH NO!
                  chords[i].voices[lowerVoice].color = colorParallelPerfect;
                  chords[i].voices[upperVoice].color = colorParallelPerfect;
                  chords[i + 1].voices[lowerVoice].color = colorParallelPerfect;
                  chords[i + 1].voices[upperVoice].color = colorParallelPerfect;
                  var msg = "Parallel P5\n(" + voiceNames[lowerVoice] + "-" + voiceNames[upperVoice] + ").";
                  markText(chords[i], msg, colorParallelPerfect);
                } else if ("contrary" == direction) {
                  // HIDDEN (contrary) OCTAVES!
                  chords[i].voices[lowerVoice].color = colorContraryPerfect;
                  chords[i].voices[upperVoice].color = colorContraryPerfect;
                  chords[i + 1].voices[lowerVoice].color = colorContraryPerfect;
                  chords[i + 1].voices[upperVoice].color = colorContraryPerfect;
                  var msg = "Contrary P5\n(" + voiceNames[lowerVoice] + "-" + voiceNames[upperVoice] + ").";
                  markText(chords[i], msg, colorContraryPerfect);
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
          chords[i].voices[soprano].color = colorVoiceLeadingWarning;
          chords[i + 1].voices[soprano].color = colorVoiceLeadingWarning;
          var msg = "Soprano leaps to\nperfect interval\nin similar motion.";
          markText(chords[i + 1], msg, colorVoiceLeadingWarning);
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
          if ((chords[i].tpc[v] == chords[i].key + 5) && chords[i + 1].tpc[v] != chords[i].key) {
            // uh oh! LT was in soprano and didn't resolve up to tonic
            chords[i].voices[3].color = colorTendencyToneError;
            chords[i + 1].voices[3].color = colorTendencyToneError;
            var msg = "Leading tone in soprano\nmust resolve up to\ntonic on V-I or viio-I";
            markText(chords[i + 1], msg, colorTendencyToneError);
          }
          for (v = 1; v < 3; v++) {
            if ((chords[i].tpc[v] == chords[i].key + 5) && chords[i + 1].tpc[v] != chords[i].key) {
              // If LT doesn't resolve up in other voices it's just info
              chords[i].voices[v].color = colorTendencyToneWarning;
              chords[i + 1].voices[v].color = colorTendencyToneWarning;
              var msg = "FYI: Leading tone in " + voiceNames[v] + "\nusually resolves up to tonic.";
              markText(chords[i + 1], msg, colorTendencyToneWarning);
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
      if (chords[i].romanPitches && chords[i + 1].romanPitches) {
        if (chords[i].tpc.length > 3) { // seventh (or 9th) chord found
          for (var v = 0; v < 4; v++) {
            if (chords[i].tpc[v] === chords[i].romanPitches[3]) { //which voice has seventh?
              if ("aug6" === chords[i].quality) {
                if ((chords[i + 1].pitches[v] - chords[i].pitches[v] > 1) ||
                  (chords[i + 1].pitches[v] - chords[i].pitches[v] < 0)) {
                  chords[i].voices[v].color = colorTendencyToneError;
                  chords[i + 1].voices[v].color = colorTendencyToneError;
                  var msg = "Aug6 (" + tpcName(chords[i].tpc[v]) + ") should resolve\nup by semitone.";
                  markText(chords[i], msg, colorTendencyToneError);
                }
              } else {
                if ("V" === chords[i].roman || "viio" === chords[i].roman || "vii0" === chords[i].roman) {
                  var melodicDist = chords[i + 1].pitches[v] - chords[i].pitches[v];
                  if ((chords[i + 1].pitches[v] - chords[i].pitches[v] > 0) ||
                    (chords[i + 1].pitches[v] - chords[i].pitches[v] < -2)) {
                    chords[i].voices[v].color = colorTendencyToneWarning;
                    chords[i + 1].voices[v].color = colorTendencyToneWarning;
                    var msg = "FYI: The 7th of the\ndominant chord usually\nresolves down by step.";
                    markText(chords[i + 1], msg, colorTendencyToneWarning);
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

    keyMode = majorOrMinor(segment, processAll, endTick);
    console.log("keyMode:", keyMode);
    var chords = getChords(cursor, processAll, endTick);

    checkNumVoices(chords);
    checkVoiceSpacing(chords);
    checkVoiceCrossing(chords);
    checkVoiceRanges(chords);

    checkForParallels(chords);
    checkForMissingTones(chords);
    checkForDoubledLT(chords);
    checkForWrongPitches(chords);
    checkForWrongInversion(chords);

    checkForLTResolution(chords);
    checkFor7thResolution(chords);
    checkForSopranoLTP(chords);

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
