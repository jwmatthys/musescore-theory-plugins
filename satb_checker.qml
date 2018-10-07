import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 1.0

MuseScore {
  menuPath: "Plugins.Proof Reading.SATB Checker"
  description: "This plugin will check for part-writing errors in tonal SATB chorales"
  version: "0.21"

  property
  var mode: "Major";
  property
  var key: 14;
  property
  var resolveAllLTs: true;

  // it pains me to use all caps for these roman numerals but
  // the scale degrees are the same anyway.
  property
  var chordTones: Object.freeze({
    "I": [1, 3, 5],
    "CAD": [1, 3, 5],
    "II": [2, 4, 6],
    "IIO": [2, 4, 6],
    "III": [3, 5, 7],
    "IV": [4, 6, 1],
    "V": [5, 7, 2],
    "VI": [6, 1, 3],
    "VII": [7, 2, 4],
    "VIIO": [7, 2, 4],
    "I7": [1, 3, 5, 7],
    "II7": [2, 4, 6, 1],
    "IIO7": [2, 4, 6, 1],
    "III7": [3, 5, 7, 2],
    "IV7": [4, 6, 1, 3],
    "V7": [5, 7, 2, 4],
    "VI7": [6, 1, 3, 5],
    "VIIO7": [7, 2, 4, 6]
  });

  property
  var inversions: Object.freeze({
    "": [0, false], // first number is inversion, second is whether its a seventh chord
    "3": [0, false],
    "53": [0, false],
    "6": [1, false],
    "63": [1, false],
    "64": [2, false],
    "7": [0, true],
    "73": [0, true],
    "753": [0, true],
    "65": [1, true],
    "43": [2, true],
    "643": [2, true],
    "42": [3, true],
    "642": [3, true]
  });

  property
  var voices: Object.freeze({
    0: "T-B",
    1: "A-B",
    2: "S-B",
    3: "A-T",
    4: "S-T",
    5: "S-A"
  });

  property
  var individualVoice: Object.freeze({
    0: "bass",
    1: "tenor",
    2: "alto",
    3: "soprano",
  });

  property
  var colorError: "#ff0000";
  property
  var colorPerf: "#22aa00";
  property
  var colorNCT: "#0000ff"
  property
  var colorCT: "#000000"

  property
  var intervalQual: Object.freeze({
    DIM: "d",
    MINOR: "m",
    MAJOR: "M",
    PERFECT: "P",
    AUGMENTED: "+",
    OTHER: "?"
  });

  MessageDialog {
    id: errorDetails
    title: "SATB Part Writing Proofreading Messages"
    text: ""
    onAccepted: {
      Qt.quit();
    }
    visible: false;
  }

  function checkInterval(note1, note2) {
    this.note1 = note1;
    this.note2 = note2;

    this.getIntervalSize = function() {
      var topsd;
      var botsd;
      var direction;
      if (this.note1 && this.note2) {
        if (this.note1.pitch >= this.note2.pitch) {
          topsd = this.note1.sd;
          botsd = this.note2.sd;
        } else {
          topsd = this.note2.sd;
          botsd = this.note1.sd;
        }
        var tic = (21 + topsd - botsd) % 7;
        if (tic == 0 && Math.abs(this.note1.pitch - this.note2.pitch) > 2) tic = 7;
        this.size = tic + 1;
      }
    }

    this.getIntervalDirection = function() {
      this.direction = 0;
      if (this.note1 && this.note2) {
        var dir = this.note2.pitch - this.note1.pitch;
        if (dir < 0) this.direction = -1;
        else if (dir > 0) this.direction = 1;
      }
    }

    this.getIntervalQuality = function() {
      // There's got to be a better way... *shrug*
      var ic;
      if (this.note1 && this.note2) {
        ic = Math.abs(this.note1.pitch - this.note2.pitch) % 12;
        this.quality = intervalQual.OTHER;
        if (this.size == 8 || this.size == 1) {
          if (11 == ic) this.quality = intervalQual.DIM;
          if (0 == ic) this.quality = intervalQual.PERFECT;
          if (1 == ic) this.quality = intervalQual.AUGMENTED;
        } else if (this.size == 2) {
          if (0 == ic) this.quality = intervalQual.DIM;
          if (1 == ic) this.quality = intervalQual.MINOR;
          if (2 == ic) this.quality = intervalQual.MAJOR;
          if (3 == ic) this.quality = intervalQual.AUGMENTED;
        } else if (this.size == 3) {
          if (2 == ic) this.quality = intervalQual.DIM;
          if (3 == ic) this.quality = intervalQual.MINOR;
          if (4 == ic) this.quality = intervalQual.MAJOR;
          if (5 == ic) this.quality = intervalQual.AUGMENTED;
        } else if (this.size == 4) {
          if (4 == ic) this.quality = intervalQual.DIM;
          if (5 == ic) this.quality = intervalQual.PERFECT;
          if (6 == ic) this.quality = intervalQual.AUGMENTED;
        } else if (this.size == 5) {
          if (6 == ic) this.quality = intervalQual.DIM;
          if (7 == ic) this.quality = intervalQual.PERFECT;
          if (8 == ic) this.quality = intervalQual.AUGMENTED;
        } else if (this.size == 6) {
          if (7 == ic) this.quality = intervalQual.DIM;
          if (8 == ic) this.quality = intervalQual.MINOR;
          if (9 == ic) this.quality = intervalQual.MAJOR;
          if (10 == ic) this.quality = intervalQual.AUGMENTED;
        } else if (this.size == 7) {
          if (9 == ic) this.quality = intervalQual.DIM;
          if (10 == ic) this.quality = intervalQual.MINOR;
          if (11 == ic) this.quality = intervalQual.MAJOR;
          if (0 == ic) this.quality = intervalQual.AUGMENTED;
        }
      }
    }

    this.getIntervalSize();
    this.getIntervalQuality();
    this.getIntervalDirection();

    this.isDimOrAug = function() {
      if (this.quality == intervalQual.MINOR) return false;
      if (this.quality == intervalQual.MAJOR) return false;
      if (this.quality == intervalQual.PERFECT) return false;
      return true;
    }

    this.isOctave = function() {
      return ((this.note1.sd == this.note2.sd) &&
        (this.note1.pitch - this.note2.pitch) != 0);
    }

    this.isPerfect = function() {
      if (this.size == 4) return false; // parallel 4ths are A-OK
      return (intervalQual.PERFECT == this.quality);
    }

    this.toString = function() {
      if (!this.size) return "";
      var printSize = this.size;
      if (this.size == 8 && Math.abs(this.note1.pitch - this.note2.pitch) < 3) printSize = 1;
      return this.quality + printSize;
    }
  }

  function getChord(segment, measure) {
    this.segment = segment; // type Cursor.SEGMENT

    this.errorCount = 0;
    this.errorText = "";
    this.longErrorText = "";

    this.addError = function(meas, shortError, longError) {
      this.errorCount++;
      this.errorText += shortError + "\n";
      this.longErrorText += "m. " + meas + ": " + longError + "\n";
    }

    this.getNote = function(elem) {
      var result = null;
      if (elem && elem.type == Element.CHORD) {
        result = elem.notes;
      }
      return result;
    }

    this.getScaleDegree = function(note) {
      var sd = null;
      if (note) {
        var circleDiff = (42 + note.tpc - key) % 7;
        if (0 == circleDiff) sd = 1;
        if (2 == circleDiff) sd = 2;
        if (4 == circleDiff) sd = 3;
        if (6 == circleDiff) sd = 4;
        if (1 == circleDiff) sd = 5;
        if (3 == circleDiff) sd = 6;
        if (5 == circleDiff) sd = 7;
      }
      return sd;
    }

    this.measure = measure; // type int
    this.soprano = null;
    this.alto = null;
    this.tenor = null;
    this.bass = null;
    this.all4voices = false;
    this.hasRoot = null;
    this.hasThird = null;
    this.voiceCross = null;

    this.trebleLayer1 = this.getNote(this.segment.elementAt(0));
    this.trebleLayer2 = this.getNote(this.segment.elementAt(1));
    this.bassLayer1 = this.getNote(this.segment.elementAt(4));
    this.bassLayer2 = this.getNote(this.segment.elementAt(5));

    if (this.trebleLayer1 && this.trebleLayer1.length > 1) {
      this.soprano = this.trebleLayer1[this.trebleLayer1.length - 1];
      this.alto = this.trebleLayer1[this.trebleLayer1.length - 2];
    } else if (this.trebleLayer1 && this.trebleLayer2) {
      this.soprano = this.trebleLayer1[this.trebleLayer1.length - 1];
      this.alto = this.trebleLayer2[this.trebleLayer2.length - 1];
    }

    if (this.bassLayer1 && this.bassLayer1.length > 1) {
      this.tenor = this.bassLayer1[this.bassLayer1.length - 1];
      this.bass = this.bassLayer1[this.bassLayer1.length - 2];
    } else if (this.bassLayer1 && this.bassLayer2) {
      this.tenor = this.bassLayer1[this.bassLayer1.length - 1];
      if (this.bassLayer2) this.bass = this.bassLayer2[this.bassLayer2.length - 1];
    }
    if (this.trebleLayer1 && this.bassLayer1 && this.trebleLayer1.length > 2) { // keyboard style
      this.tenor = this.trebleLayer1[this.trebleLayer1.length - 3];
      this.bass = this.bassLayer1[this.bassLayer1.length - 1];
    }

    this.all4voices = (this.soprano && this.alto && this.tenor && this.bass);
    if (this.all4voices) {
      this.soprano.sd = this.getScaleDegree(this.soprano);
      this.alto.sd = this.getScaleDegree(this.alto);
      this.tenor.sd = this.getScaleDegree(this.tenor);
      this.bass.sd = this.getScaleDegree(this.bass);
      this.satb = [this.bass, this.tenor, this.alto, this.soprano];
      this.satb.sd = [this.bass.sd, this.tenor.sd, this.alto.sd, this.soprano.sd];
      this.satb.pitch = [this.bass.pitch, this.tenor.pitch, this.alto.pitch, this.soprano.pitch];

      if (this.soprano.pitch > 80 || this.soprano.pitch < 60) this.addError(this.measure, "S range", "soprano out of range");
      if (this.alto.pitch > 75 || this.alto.pitch < 55) this.addError(this.measure, "A range", "alto out of range");
      if (this.tenor.pitch > 68 || this.tenor.pitch < 48) this.addError(this.measure, "T range", "tenor out of range");
      if (this.bass.pitch > 60 || this.bass.pitch < 40) this.addError(this.measure, "B range", "bass out of range");

      this.checkVoiceCrossing = function() {
        if (this.alto.pitch > this.soprano.pitch) return true;
        if (this.tenor.pitch > this.alto.pitch) return true;
        if (this.bass.pitch > this.tenor.pitch) return true;
        return false;
      }

      this.checkSpacing = function() {
        if (this.soprano.pitch - this.alto.pitch > 12) return true;
        if (this.alto.pitch - this.tenor.pitch > 12) return true;
        return false;
      }

      this.checkNotes = function() {
        var result = 0;
        for (var i = 0; i < 4; i++) {
          if (this.chordTones.indexOf(this.satb[i].sd) < 0) result++;
        }
        return result;
      }

      this.checkDoubledLT = function() {
        var result = 0;
        for (var i = 0; i < 4; i++) {
          if (this.satb[i].sd == 7) result++;
        }
        return result;
      }

      this.voiceCross = this.checkVoiceCrossing();
      this.spacingError = this.checkSpacing();
      this.doubledLT = this.checkDoubledLT();

      this.getRoman = function() {
        var sArray = new Array();
        for (var i = 4; i < 6; i++) {
          if (segment.elementAt(i) && segment.elementAt(i).lyrics) {
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

      this.romanText = this.getRoman().replace(/[^IiVvoCad]/g, '');
      this.romanNumeral = this.romanText.toUpperCase();
      this.figuredBass = this.getRoman().replace(/[^234567]/g, '');
      this.inversion = inversions[this.figuredBass][0];
      this.seventhChord = inversions[this.figuredBass][1];
      if (this.seventhChord) this.romanNumeral += "7";
      this.chordTones = chordTones[this.romanNumeral];
      this.intervals = [];
      for (var a1 = 0; a1 < 4; a1++) {
        for (var a2 = a1; a2 < 4; a2++) {
          if (a1 != a2) {
            this.intervals.push(new checkInterval(this.satb[a1], this.satb[a2]));
          }
        }
      }
      this.LTneedsResolving = null;
      this.seventhNeedsResolving = null;
      this.dim5dim7NeedsResolving = null;
      this.missingSeventh = false;
      if (this.chordTones) {
        this.hasRoot = (this.satb.sd.indexOf(this.chordTones[0]) >= 0);
        this.hasThird = (this.satb.sd.indexOf(this.chordTones[1]) >= 0);
        this.hasFifth = (this.satb.sd.indexOf(this.chordTones[2]) >= 0);
        if (this.seventhChord) this.missingSeventh = !(this.satb.sd.indexOf(this.chordTones[3]) >= 0);
        this.wrongInversion = this.bass.sd != this.chordTones[this.inversion];
        this.wrongNote = this.checkNotes();
        if (this.romanNumeral == "V" || this.romanNumeral == "V7" || this.romanNumeral == "VIIO" || this.romanNumeral == "VIIO7") {
          for (var a3 = 0; a3 < 4; a3++)
            if (this.satb[a3].sd == 7) this.LTneedsResolving = a3;
        }
        if (this.romanNumeral == "V7" || this.romanNumeral == "VIIO7") {
          for (var a4 = 0; a4 < 4; a4++)
            if (this.romanNumeral == "V7" && (this.satb[a4].sd == this.chordTones[3])) this.seventhNeedsResolving = a4;
            else if (this.romanNumeral == "VIIO7" && (this.satb[a4].sd == this.chordTones[2])) this.seventhNeedsResolving = a4;
        }
        if (this.romanNumeral == "VIIO" || this.romanNumeral == "VIIO7") {
          for (var a5 = 0; a5 < 4; a5++)
            if (this.satb[a5].sd == this.chordTones[3]) this.dim7NeedsResolving = a5;
        }
      }

      this.createErrorText = function(cursor) {
        if (this.wrongNote) {
          if (this.wrongNote == 1) this.addError(this.measure, this.wrongNote + " note err", "one note error");
          else this.addError(this.measure, this.wrongNote + " note err", this.wrongNote + " wrong notes");
        }
        if (this.wrongNote <= 2) {
          if (this.wrongInversion) this.addError(this.measure, "inv", "incorrect bass note for inversion");
          if (!this.hasRoot) this.addError(this.measure, "no root", "chord is missing root");
          if (!this.hasThird) this.addError(this.measure, "no 3rd", "chord is missing third");
          if (this.inversion > 0 && !this.hasFifth) this.addError(this.measure, "no 5", "warning: chord is in inversion and is missing fifth");
          if (this.missingSeventh) this.addError(this.measure, "no 7th", "chord is missing seventh");
          if (this.voiceCross) this.addError(this.measure, "X", "voice crossing");
          if (this.spacingError) this.addError(this.measure, "sp", "spacing greater than an octave in upper voices");
          if (this.doubledLT > 1) this.addError(this.measure, "LTx" + this.doubledLT, "doubled leading tone");
        }

        var text = newElement(Element.STAFF_TEXT);
        text.pos.y = -2.5 * (this.errorCount - 1);
        text.pos.x = 0;
        text.text = this.errorText;
        text.color = colorError;
        cursor.add(text);
      }
    }
  }

  onRun: {
    if (typeof curScore == 'undefined' || curScore == null) {
      console.log("no score found");
      Qt.quit();
    }
    var tetrachords = [];
    var measure = 1;
    var cursor = curScore.newCursor();
    if (curScore.poet.toUpperCase() == "MINOR") {
      mode = "Minor";
    }
    cursor.rewind(0);
    key = cursor.keySignature + 14;
    if (mode == "Minor") key += 3;
    var segment = cursor.segment;

    for (var index = 0; segment;) {

      var treble = segment.elementAt(0);
      var bass = segment.elementAt(4);

      if ((treble && treble.type == Element.CHORD) || (bass && bass.type == Element.CHORD)) {
        tetrachords[index] = new getChord(segment, measure); // This is where the magic happens...
        //errorDetails.text += tetrachords[index].romanText + ", " + tetrachords[index].romanNumeral + "," + tetrachords[index].inversion + ", " + tetrachords[index].seventhChord + "\n";
        var all4voices = tetrachords[index].all4voices;
        if (all4voices) {
          if (index > 0) { // check with parallels starting with second chord
            for (var a = 0; a < 6; a++) {
              var currentInterval = tetrachords[index].intervals[a];
              var lastInterval = tetrachords[index - 1].intervals[a];
              var oblique = (tetrachords[index].intervals[a].note1.pitch == tetrachords[index - 1].intervals[a].note1.pitch);
              if (currentInterval.toString() == lastInterval.toString() && currentInterval.isPerfect() && !oblique) {
                tetrachords[index].addError(measure, "||" + currentInterval.toString(), "parallel " + currentInterval.toString() + " in " + voices[a]);
              }
            }
            if (tetrachords[index - 1].LTneedsResolving) {
              var resolution = tetrachords[index].satb[tetrachords[index - 1].LTneedsResolving].sd;
              var isTonicOrDeceptive = (tetrachords[index].romanNumeral == "I" || tetrachords[index].romanNumeral == "VI");
              var whichVoice = individualVoice[tetrachords[index - 1].LTneedsResolving];
              if (resolution != 1 && isTonicOrDeceptive && (whichVoice == "soprano" || resolveAllLTs)) tetrachords[index].addError(measure, "LT res", whichVoice + ": leading tone needs to resolve up to tonic");
            }
            if (tetrachords[index - 1].seventhNeedsResolving) {
              var resolution = tetrachords[index].satb[tetrachords[index - 1].seventhNeedsResolving].sd;
              var whichVoice = individualVoice[tetrachords[index - 1].seventhNeedsResolving];
              if (resolution != 3) tetrachords[index].addError(measure, "tendency res", whichVoice + ": tendency tone in " + tetrachords[index - 1].romanText + " chord needs to resolve down");
            }
            if (tetrachords[index - 1].dim7NeedsResolving) {
              var resolution = tetrachords[index].satb[tetrachords[index - 1].dim7NeedsResolving].sd;
              var whichVoice = individualVoice[tetrachords[index - 1].dim7NeedsResolving];
              if (resolution != 5) tetrachords[index].addError(measure, "d7 res", whichVoice + ": seventh of " + tetrachords[index - 1].romanText + " chord needs to resolve down");
            }
          }
          tetrachords[index].createErrorText(cursor);
        }
        if (tetrachords[index].trebleLayer1) cursor.next();
        if (all4voices) index++;
      } else if (segment.elementAt(0) && segment.elementAt(0).type == Element.BAR_LINE) measure++;
      segment = segment.next;
    }
    for (var a = 0; a < tetrachords.length; a++) {
      errorDetails.text += tetrachords[a].longErrorText;
    }
    if (errorDetails.text == "") errorDetails.text = "No part-writing errors found!\n";
    errorDetails.visible = true;
    Qt.quit();
  }
}
