import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 1.0

MuseScore {
  menuPath: "Plugins.Check Tonal Counterpoint.First Species"
  description: "Check for Errors in Tonal Counterpoint Writing"
  version: "0.2"

  property
  var mode: "Major";
  property
  var counterpointRestrictions: Object.freeze({
    Dissonant_Downbeats: true, // true means that these things will be checked, ie errors - DONE
    Voice_Crossing: true, // DONE
    Accidentals: true, // will still allow raised 6 and raised 7 in minor - DONE
    Melodic_Perfect_Parallels: true, // DONE
    Consecutive_Downbeat_Parallels: true,
    Direct_Fifths: true, // refers specifically to P5-d5 or d5-P5 - DONE
    Hidden_Parallels: true, // Consecutive parallel P5 or P8 moving in opposite direction - DONE
    Leap_To_Similar_Perfect: true, // melody leaps to a perfect interval in similar motion - DONE
    Leap_From_Dissonance: true, // a general truism - DONE
    Leap_To_Dissonance: true, // (only exception is appoggiatura) - DONE
    Melodic_Aug_Or_Dim: true, // DONE
    Melodic_Seventh: true, // DONE
    Offbeat: false, // no offbeats, ie first species - DONE
    Cadence_raised_LT: true,
    Cadence_LT_Resolution: true,
    Cadence_V7_Resolution: true,
    Repeated_Note: true, // strict species forbids repeated notes in 2-4 species
    Passing_Tone: true,
    Neighbor_Tone: true,
    Appoggiatura: true,
    Retardation: true,
    Nota_Cambiata: false,
    Double_Neighbor: true, // the more general version of nota combiata that can move up or down
    Escape_Tone: false, // overrides Leap_From_Dissonance
    Step_Back_After_Leap: true, // warns if leap of 6th or octave doesn't step back the opposite direction
    Max_Perfect: 0.5, // warn if too many perfect intervals
    Max_Leaps: 0.5, // warn if too many leaps
    Max_Consecutive_36: 4, // maximum number of consecutive 3rds or 6ths
    Max_Consecutive_Leaps: 3,
    Min_Std_Dev: 0, // experimental: measure of how much melody
  });

  property
  var errorMessage: Object.freeze({
    Dissonant_Downbeats: "dis",
    Voice_Crossing: "X",
    Accidentals: "acc", // will still allow raised 6 and raised 7 in minor
    Melodic_Perfect_Parallels: "||",
    Consecutive_Downbeat_Parallels: "||",
    Direct_Fifths: "dir", // refers specifically to P5-d5 or d5-P5
    Hidden_Parallels: "hid", // Consecutive parallel P5 or P8 moving in opposite direction
    Leap_To_Similar_Perfect: "ltp", // melody leaps to a perfect interval in similar motion
    Leap_From_Dissonance: "lfd", // a general truism
    Leap_To_Dissonance: "ltd", // (only exception is appoggiatura)
    Melodic_Aug_Or_Dim: "mel",
    Melodic_Seventh: "mel7",
    Offbeat: "x", // no offbeats, ie first species
    Cadence_raised_LT: "LT!",
    Cadence_LT_Resolution: "LT",
    Cadence_V7_Resolution: "7th",
    Repeated_Note: "rpt", // strict species forbids repeated notes in 2-4 species
    Passing_Tone: "PT",
    Neighbor_Tone: "NT",
    Appoggiatura: "App",
    Retardation: "Ret",
    Nota_Cambiata: "NC",
    Double_Neighbor: "DN", // the more general version of nota combiata that can move up or down
    Escape_Tone: "ET", // overrides Leap_From_Dissonance
    Step_Back_After_Leap: "", // warns if leap of 6th or octave doesn't step back the opposite direction
    Max_Perfect: 0.5, // warn if too many perfect intervals
    Max_Leaps: 0.5, // warn if too many leaps
    Max_Consecutive_36: 4, // maximum number of consecutive 3rds or 6ths
    Max_Consecutive_Leaps: 3,
    Min_Std_Dev: 0, // experimental: measure of how much melody
  });

  property
  var key: 14;
  property
  var colorError: "#ff0000";
  property
  var colorPerf: "#22aa00";
  property
  var colorNCT: "#0000ff"
  property
  var inversion: Object.freeze({
    ROOT: [8, 5, 3],
    FIRSTINV: [8, 6, 3],
    SECONDINV: [8, 6, 4],
    ROOT7: [8, 7, 5, 3],
    FIRSTINV7: [8, 6, 5, 3],
    SECONDINV7: [8, 6, 4, 3],
    THIRDINV7: [8, 6, 4, 2]
  });
  property
  var intervalQual: Object.freeze({
    DIM: "d",
    MINOR: "m",
    MAJOR: "M",
    PERFECT: "P",
    AUGMENTED: "+",
    OTHER: "?"
  });
  property
  var tonalMotion: Object.freeze({
    OBLIQUE: "Oblique",
    CONTRARY: "Contrary",
    SIMILAR: "Similar",
    PARALLEL: "Parallel"
  });

  MessageDialog {
    id: errorDetails
    title: "First Species Tonal Counterpoint Errors"
    text: ""
    onAccepted: {
      Qt.quit();
    }
    visible: false;
  }

  function cInterval(note1, note2) {
    this.note1 = note1;
    this.note2 = note2;

    this.getScaleDegree = function(note) {
      var circleDiff = (21 + note.tpc - key) % 7;
      var sd = null;
      if (0 == circleDiff) sd = 1;
      if (2 == circleDiff) sd = 2;
      if (4 == circleDiff) sd = 3;
      if (6 == circleDiff) sd = 4;
      if (1 == circleDiff) sd = 5;
      if (3 == circleDiff) sd = 6;
      if (5 == circleDiff) sd = 7;
      return sd;
    }

    this.getIntervalSize = function() {
      var topsd;
      var botsd;
      if (this.note1.pitch >= this.note2.pitch) {
        topsd = this.note1.sd;
        botsd = this.note2.sd;
      } else {
        topsd = this.note2.sd;
        botsd = this.note1.sd;
      }
      var tic = (21 + topsd - botsd) % 7;
      if (tic == 0) tic = 7;
      this.size = tic + 1;
    }

    this.getIntervalQuality = function() {
      // There's got to be a better way... *shrug*
      var ic = Math.abs(this.note1.pitch - this.note2.pitch) % 12;
      this.quality = intervalQual.OTHER;
      if (this.size == 8) {
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

    this.note1.sd = this.getScaleDegree(this.note1);
    this.note2.sd = this.getScaleDegree(this.note2);
    this.getIntervalSize();
    this.getIntervalQuality();

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
      return (intervalQual.PERFECT == this.quality);
    }

    this.toString = function() {
      var printSize = this.size;
      if (this.size == 8 && Math.abs(this.note1.pitch - this.note2.pitch) < 3) printSize = 1;
      return this.quality + printSize;
    }
  }

  function cDyad(segment) {
    this.segment = segment; // type Cursor.SEGMENT


    this.getNote = function(elem) {
      var result = null;
      if (elem && elem.type == Element.CHORD) {
        var notes = elem.notes;
        if (notes.length > 1) {
          errorDetails.text = errorDetails.text + "This plugin only checks the top note of any chord\n";
        }
        result = notes[notes.length - 1];
      }
      return result;
    }

    this.topNote = this.getNote(this.segment.elementAt(0));
    this.botNote = this.getNote(this.segment.elementAt(4));
    this.prevTop = null; //type ELEMENT.CHORD
    this.prevBot = null; //type ELEMENT.CHORD
    this.prevFB = null; //type Element.FIGURED_BASS
    this.interval = null;
    this.nct = null; //type bool
    this.consonances = inversion.ROOT;
    this.errorYpos = 0; // type int

    this.processFiguredBass = function() {
      this.fb = this.segment.annotations[0];
      if (this.botNote) this.consonances = inversion.ROOT;
      else this.fb = this.prevFB;
      if (this.fb && this.fb.type == Element.FIGURED_BASS) {
        if (this.fb.text == "6" || this.fb.text == "6\n3") this.consonances = inversion.FIRSTINV;
        if (this.fb.text == "6\n4") this.consonances = inversion.SECONDINV;
        if (this.fb.text == "7" || this.fb.text == "7\n5\n3") this.consonances = inversion.ROOT7
        if (this.fb.text == "6\n5" || this.fb.text == "6\n5\n3") this.consonances = inversion.FIRSTINV7;
        if (this.fb.text == "4\n3" || this.fb.text == "6\n4\n3") this.consonances = inversion.SECONDINV7;
        if (this.fb.text == "4\n2" || this.fb.text == "6\n4\n2") this.consonances = inversion.THIRDINV7;
      }
    }

    this.processInterval = function() {
      // If no new note is articulated, carry over pitch from before
      if (this.topNote) this.topNote.new = true;
      else if (this.prevTop) {
        this.topNote = this.prevTop; // top note tied over
        this.topNote.new = false;
      }
      if (this.botNote) this.botNote.new = true;
      else if (this.prevBot) {
        this.botNote = this.prevBot; // bottom note still sounding
        this.botNote.new = false;
      }
      this.interval = new cInterval(this.topNote, this.botNote, key);
      this.nct = (this.consonances.indexOf(this.interval.size) == -1);
      //console.log("interval: "+this.interval.toString()+" = NCT? " +this.nct );
    }

    this.isDissonant = function() {
      if (this.nct) return true;
      if (this.interval.quality == intervalQual.DIM) return true;
      if (this.interval.quality == intervalQual.AUGMENTED) return true;
      if (this.interval.quality == intervalQual.OTHER) return true;
      return false;
    }

    this.voiceCross = function() {
      return (this.topNote.pitch < this.botNote.pitch);
    }
  }

  function counterpointError(cursor, note) {
    this.cursor = cursor;
    this.note = note;

    this.annotate = function(msg, xpos) {
      var text = newElement(Element.STAFF_TEXT);
      text.pos.x = xpos;
      text.pos.y = note.errorYpos;
      text.text = msg;
      text.color = colorError;
      cursor.add(text);
      note.errorYpos -= 2;

    }
  }

  function motion(dyad1, dyad2) {
    var result;
    var topMotion = dyad2.topNote.pitch - dyad1.topNote.pitch; // 0 if oblique, + if ascending, - if descending
    var botMotion = dyad2.botNote.pitch - dyad1.botNote.pitch;
    var direction = topMotion * botMotion; // + if similar, - if contrary, 0 if oblique
    //console.log("topMotion: "+topMotion+", botMotion: "+botMotion+", direction: "+direction);
    if (direction <= 0) return tonalMotion.CONTRARY;
    if (direction == 0) return tonalMotion.OBLIQUE;
    return tonalMotion.SIMILAR;
  }

  onRun: {
    if (typeof curScore == 'undefined' || curScore == null) {
      console.log("no score found");
      Qt.quit();
    }
    var dyads = [];
    var index = 0;
    var measure = 1;
    var cursor = curScore.newCursor();
    cursor.rewind(0);
    key = cursor.keySignature + 14;
    if (mode == "Minor") key += 3;
    var segment = cursor.segment;

    // Process all dyads and mark intervals
    while (segment) {
      var topElem = segment.elementAt(0);
      var botElem = segment.elementAt(4);
      if ((topElem && topElem.type == Element.REST) || (botElem && botElem.type == Element.REST)) {
        // No rests except maybe at beginning
        errorDetails.text += "No rests allowed after the beginning.\n";
        Qt.quit();
      }
      if ((topElem && topElem.type == Element.CHORD) || (botElem && botElem.type == Element.CHORD)) {
        dyads[index] = new cDyad(segment); // This is where the magic happens...
        if (index > 0) {
          dyads[index].prevTop = dyads[index - 1].topNote;
          dyads[index].prevBot = dyads[index - 1].botNote;
          dyads[index].prevFB = dyads[index - 1].fb;
        }
        dyads[index].processFiguredBass();
        dyads[index].processInterval();
        // Label intervals
        var text = newElement(Element.STAFF_TEXT);
        text.pos.y = 10;
        text.text = dyads[index].interval.toString();
        if (dyads[index].interval.quality == intervalQual.PERFECT) text.color = colorPerf;
        if (dyads[index].nct) text.color = colorNCT;
        cursor.add(text);

        // Here come the verticality error checks!
        var error = new counterpointError(cursor, dyads[index]);

        if (counterpointRestrictions.Offbeat) {
          if (!dyads[index].botNote.new) {
            error.annotate(errorMessage.Offbeat, 0);
            errorDetails.text += "Measure " + measure + ": First species allows only one melody note per bass note\n";
          }
        }

        if (counterpointRestrictions.Dissonant_Downbeats) {
          if (dyads[index].botNote.new && dyads[index].isDissonant()) {
            error.annotate(errorMessage.Dissonant_Downbeats, 0);
            errorDetails.text += "Measure " + measure + ": Dissonant interval " + dyads[index].interval.toString() + " over bass note change\n";
          }

        }

        if (counterpointRestrictions.Voice_Crossing) {
          if (dyads[index].voiceCross()) {
            error.annotate(errorMessage.Voice_Crossing, 0);
            errorDetails.text += "Measure " + measure + ": Melody crosses bass\n";
          }
        }

        if (counterpointRestrictions.Accidentals) {
          if (dyads[index].topNote.accidental) {
            if (mode != "Minor") {
              error.annotate(errorMessage.Accidentals, 0);
              errorDetails.text += "Measure " + measure + ": Accidentals are restricted in this species\n";
              dyads[index].topNote.accidental.color = "#ff0000";
            } else {
              if (dyads[index].topNote.sd < 6 || dyads[index].topNote.sd > 7) {
                error.annotate(errorMessage.Accidentals, 0);
                errorDetails.text += "Measure " + measure + ": Only scale degrees 6 & 7 can be altered with accidentals in this species\n";
                dyads[index].topNote.accidental.color = "#ff0000";
              }
            }
          }
        }

        // Now the checks of 2 consecutive notes
        if (index > 0) {
          if (counterpointRestrictions.Melodic_Aug_Or_Dim) {
            var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
            if (melodicInterval.quality != intervalQual.PERFECT &&
              melodicInterval.quality != intervalQual.MAJOR &&
              melodicInterval.quality != intervalQual.MINOR) {
              error.annotate(errorMessage.Melodic_Aug_Or_Dim, 0);
              errorDetails.text += "Measure " + measure + ": Melody changes by dissonant interval " + melodicInterval.toString() + "\n";
            }
          }
          if (counterpointRestrictions.Melodic_Seventh) {
            var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
            if (melodicInterval.size == 7) {
              error.annotate(errorMessage.Melodic_Seventh, 0);
              errorDetails.text += "Measure " + measure + ": Melody leaps " + melodicInterval.toString() + "\n";
            }
          }
          if (counterpointRestrictions.Melodic_Perfect_Parallels) {
            if (dyads[index].interval.quality == intervalQual.PERFECT &&
              dyads[index - 1].interval.quality == intervalQual.PERFECT &&
              dyads[index].interval.size == dyads[index - 1].interval.size &&
              motion(dyads[index], dyads[index - 1]) == tonalMotion.SIMILAR) {
              error.annotate(errorMessage.Melodic_Perfect_Parallels + dyads[index].interval.toString());
              errorDetails.text = errorDetails.text + "Measure " + measure + ": Parallel " + dyads[index].interval.toString() + "\n";
            }
          }
          if (counterpointRestrictions.Direct_Fifths) {
            if (dyads[index].interval.size == 5 &&
              dyads[index - 1].interval.size == 5 &&
              dyads[index].interval.quality != dyads[index - 1].interval.quality &&
              motion(dyads[index], dyads[index - 1]) == tonalMotion.SIMILAR) {
              error.annotate(errorMessage.Direct_Fifths);
              errorDetails.text = errorDetails.text + "Measure " + measure + ": Consecutive 5ths in same direction\n";
            }
          }
          if (counterpointRestrictions.Hidden_Parallels) {
            if (dyads[index].interval.quality == intervalQual.PERFECT &&
              dyads[index - 1].interval.quality == intervalQual.PERFECT &&
              dyads[index].interval.size == dyads[index - 1].interval.size &&
              motion(dyads[index], dyads[index - 1]) == tonalMotion.CONTRARY) {
              error.annotate(errorMessage.Hidden_Parallels + dyads[index].interval.toString());
              errorDetails.text = errorDetails.text + "Measure " + measure + ": Hidden " + dyads[index].interval.toString() + "\n";
            }
          }
          if (counterpointRestrictions.Leap_To_Similar_Perfect) {
            if (dyads[index].interval.quality == intervalQual.PERFECT) {
              var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
              if (motion(dyads[index], dyads[index - 1]) == tonalMotion.SIMILAR &&
                melodicInterval.size > 2) {
                error.annotate(errorMessage.Leap_To_Similar_Perfect);
                errorDetails.text = errorDetails.text + "Measure " + measure + ": Melody leaps to " + dyads[index].interval.toString() + " in similar motion\n";
              }
            }
          }
          if (counterpointRestrictions.Leap_From_Dissonance) {
            if (dyads[index - 1].isDissonant()) {
              var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
              if (melodicInterval.size > 2) {
                error.annotate(errorMessage.Leap_From_Dissonance);
                errorDetails.text = errorDetails.text + "Measure " + measure + ": Melody leaps from NCT or dissonant interval " + dyads[index - 1].interval.toString() + "\n";
              }
            }
          }
          if (counterpointRestrictions.Leap_To_Dissonance) {
            if (dyads[index].isDissonant()) {
              var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
              if (melodicInterval.size > 2) {
                error.annotate(errorMessage.Leap_To_Dissonance);
                errorDetails.text = errorDetails.text + "Measure " + measure + ": Melody leaps to NCT or dissonant interval " + dyads[index].interval.toString() + "\n";
              }
            }
          }
          if (counterpointRestrictions.Repeated_Note) {
            if (dyads[index].topNote.pitch == dyads[index - 1].topNote.pitch &&
              dyads[index].topNote.tpc == dyads[index - 1].topNote.tpc) {
              error.annotate(errorMessage.Repeated_Note);
              errorDetails.text = errorDetails.text + "Measure " + measure + ": Melody note repeats\n";
            }
          }
        } // index > 0

        // Moving on...
        cursor.next();
        index++;
      } else if (segment.elementAt(0).type == Element.BAR_LINE) measure++;

      segment = segment.next;
    }
    errorDetails.visible = true;
    Qt.quit();
  }
}
