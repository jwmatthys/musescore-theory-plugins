import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 1.0

MuseScore {
  menuPath: "Plugins.Proof Reading.Counterpoint.Tonal.Species 5 Major"
  description: "Check for Errors in Tonal Counterpoint Writing"
  version: "0.5"

  property
  var mode: "Major";
  property
  var counterpointRestrictions: Object.freeze({
    Show_Intervals: true, // can be turned off if you want your students to figure these out themselves
    Dissonant_Downbeats: true, // true means that these things will be checked, ie errors - DONE
    Dissonant_Offbeats: true, // DONE
    Voice_Crossing: true, // DONE
    Accidentals: true, // will still allow raised 6 and raised 7 in minor - DONE
    Melodic_Perfect_Parallels: true, // DONE
    Consecutive_Downbeat_Parallels: true, // DONE
    Direct_Fifths: true, // refers specifically to P5-d5 or d5-P5 - DONE
    Hidden_Parallels: true, // Consecutive parallel P5 or P8 moving in opposite direction - DONE
    Leap_To_Similar_Perfect: true, // melody leaps to a perfect interval in similar motion - DONE
    Leap_From_Dissonance: true, // a general truism - DONE
    Leap_To_Dissonance: true, // exception is Allow_Appoggiatura or Allow_Retardation - DONE
    Melodic_Aug_Or_Dim: true, // DONE
    Melodic_Seventh: true, // DONE
    Offbeat: false, // no offbeats, ie first species - DONE
    Doubled_LT: true, // DONE
    Cadence_raised_LT: true, // DONE
    Cadence_LT_Resolution: true, // DONE
    V7_Resolution: true, // DONE
    Repeated_Note_Over_Barline: false, // strict species forbids this in spec 2 & 3 but not 4 - DONE
    Repeated_Offbeat: false, // This is usually true - DONE
    Allow_Passing_Tone: true, // DONE
    Allow_Neighbor_Tone: true, // DONE
    Allow_Appoggiatura: true, // DONE
    Allow_Retardation: true, // DONE
    Allow_Suspension: true, // DONE
    Allow_Accented_Passing_Tone: true, // for species 4
    Allow_Accented_Neighbor: true, // for species 4
    Nota_Cambiata: true, // DONE
    Double_Neighbor: true, // the more general version of nota combiata that can move up or down - DONE
    Escape_Tone: true, // overrides Leap_From_Dissonance DONE
    Step_Back_After_Leap: true, // warns if leap of 6th or octave doesn't step back the opposite direction - DONE
    Max_Perfect: 50, // percent; warn if too many perfect intervals - DONE
    Max_Leaps: 50, // percent; warn if too many leaps - DONE
    Max_Consecutive_36: 4, // maximum number of consecutive 3rds or 6ths - DONE
    Max_Consecutive_Leaps: 4, // DONE
    Min_Std_Dev: 2 // experimental: measure of how much melody - DONE, but what is the threshold??
  });

  property
  var errorMessage: Object.freeze({
    Dissonant_Downbeats: "dis",
    Dissonant_Offbeats: "dis",
    Voice_Crossing: "X",
    Accidentals: "acc", // will still allow raised 6 and raised 7 in minor
    Melodic_Perfect_Parallels: "||",
    Consecutive_Downbeat_Parallels: "||",
    Direct_Fifths: "dir", // refers specifically to P5-d5 or d5-P5
    Hidden_Parallels: "hid", // Consecutive parallel P5 or P8 moving in opposite direction
    Leap_To_Similar_Perfect: "ltp", // melody leaps to a perfect interval in similar motion
    Leap_From_Dissonance: "lfd", // a general truism
    Leap_To_Dissonance: "ltd", // (only exception is appoggiatura)
    Melodic_Aug_Or_Dim: "->",
    Melodic_Seventh: "mel7",
    Offbeat: "x", // no offbeats, ie first species
    Doubled_LT: "2xlt",
    Cadence_raised_LT: "lt!",
    Cadence_LT_Resolution: "lt",
    V7_Resolution: "7th",
    Repeated_Note_Over_Barline: "rep", // strict species forbids this in spec 2 & 3 but not 4
    Repeated_Offbeat: "rep", // This is usually true
    Allow_Passing_Tone: "PT",
    Allow_Neighbor_Tone: "NT",
    Allow_Appoggiatura: "APP",
    Allow_Retardation: "RET",
    Allow_Suspension: "SUS",
    Allow_Accented_Passing_Tone: "APT", // for species 4
    Allow_Accented_Neighbor: "AN", // for species 4
    Nota_Cambiata: "NC",
    Double_Neighbor: "DN", // the more general version of nota combiata that can move up or down
    Escape_Tone: "ET", // overrides Leap_From_Dissonance
    Step_Back_After_Leap: "sb", // warns if leap of 6th or octave doesn't step back the opposite direction
    Max_Perfect: 0.5, // warn if too many perfect intervals
    Max_Leaps: 0.5, // warn if too many leaps
    Max_Consecutive_36: 4, // maximum number of consecutive 3rds or 6ths
    Max_Consecutive_Leaps: 3,
    Min_Std_Dev: 0 // experimental: measure of how much melody
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
  var colorCT: "#000000"
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
    title: "Counterpoint Proof Reading Messages"
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
      var sd = null;
      if (note) {
        var circleDiff = (21 + note.tpc - key) % 7;
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
        if (tic == 0) tic = 7;
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
    }

    if (this.note1) this.note1.sd = this.getScaleDegree(this.note1);
    if (this.note2) this.note2.sd = this.getScaleDegree(this.note2);
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
      if (this.size == 4) return false; // P4 is actually a dissonance
      return (intervalQual.PERFECT == this.quality);
    }

    this.toString = function() {
      if (!this.size) return "";
      var printSize = this.size;
      if (this.size == 8 && Math.abs(this.note1.pitch - this.note2.pitch) < 3) printSize = 1;
      return this.quality + printSize;
    }
  }

  function cDyad(segment, measure) {
    this.segment = segment; // type Cursor.SEGMENT
    this.permittedDissonance = false;

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
    this.newTop = false;
    this.newBot = false;
    this.prevTop = null; //type ELEMENT.CHORD
    this.prevBot = null; //type ELEMENT.CHORD
    this.prevFB = null; //type Element.FIGURED_BASS
    this.interval = null;
    this.nct = null; //type bool
    this.consonances = inversion.ROOT;
    this.errorYpos = 0; // type int
    this.measure = measure; // type int

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
      if (this.topNote) this.newTop = true;
      else {
        this.topNote = this.prevTop; // top note tied over
        if (this.topNote) this.newTop = false;
      }
      if (this.botNote) this.newBot = true;
      else {
        this.botNote = this.prevBot; // bottom note still sounding
        if (this.botNote) this.newBot = false;
      }
      this.interval = new cInterval(this.topNote, this.botNote, key);
      this.nct = (this.consonances.indexOf(this.interval.size) == -1);
      //console.log("interval: "+this.interval.toString()+" = NCT? " +this.nct );
    }

    this.isDissonant = function() {
      if (this.permittedDissonance) return false;
      if (this.nct) return true;
      //if (this.interval.quality == intervalQual.DIM) return true;
      //if (this.interval.quality == intervalQual.AUGMENTED) return true;
      if (this.interval.quality == intervalQual.OTHER) return true;
      return false;
    }

    this.voiceCross = function() {
      return (this.topNote.pitch < this.botNote.pitch);
    }

    this.isVchord = function() {
      if (this.botNote && this.botNote.sd == 5 &&
        (this.consonances == inversion.ROOT || this.consonances == inversion.ROOT7)) return true;
      if (this.botNote && this.botNote.sd == 7 &&
        (this.consonances == inversion.FIRSTINV || this.consonances == inversion.FIRSTINV7)) return true;
      if (this.botNote && this.botNote.sd == 2 &&
        (this.consonances == inversion.SECONDINV || this.consonances == inversion.SECONDINV7)) return true;
      if (this.botNote && this.botNote.sd == 4 &&
        (this.consonances == inversion.THIRDINV || this.consonances == inversion.THIRDINV7)) return true;
      return false;
    }

    this.isIchord = function() {
      if (this.botNote && this.botNote.sd == 1 && this.consonances == inversion.ROOT) return true;
      if (this.botNote && this.botNote.sd == 3 && this.consonances == inversion.FIRSTINV) return true;
      if (this.botNote && this.botNote.sd == 5 && this.consonances == inversion.SECONDINV) return true;
    }
  }

  function isPassing(note1, note2, note3) {
    // TODO: Maybe allow Aug2 passing between sd 6 and 7
    if ((note1.pitch - note2.pitch) * (note2.pitch - note3.pitch) <= 0) return false; // direction check
    if (Math.abs(note1.pitch - note2.pitch) > 2) return false;
    if (Math.abs(note2.pitch - note3.pitch) > 2) return false;
    return true;
  }

  function isNeighbor(note1, note2, note3) {
    if ((note1.pitch - note2.pitch) * (note2.pitch - note3.pitch) >= 0) return false; // direction check
    if (Math.abs(note1.pitch - note2.pitch) > 2) return false;
    if (Math.abs(note2.pitch - note3.pitch) > 2) return false;
    return true;
  }

  function stepsBackAfterBigLeap(note1, note2, note3) {
    var int1 = new cInterval(note1, note2);
    if (int1.size == 6 || int1.size == 8) {
      if (note1.pitch - note2.pitch == 0) return true;
      if ((note1.pitch - note2.pitch) * (note2.pitch - note3.pitch) > 0) return false; // direction check
      var int2 = new cInterval(note2, note3);
      if (int2.direction == 0) return true;
      if (int2.size > 2) return false;
    }
    return true;
  }

  function counterpointError(cursor, note) {
    this.cursor = cursor;
    this.note = note;

    this.annotate = function(msg, col) {
      var text = newElement(Element.STAFF_TEXT);
      text.pos.y = note.errorYpos;
      text.pos.x = 0;
      text.text = msg;
      text.color = col;
      cursor.add(text);
      note.errorYpos -= 2;
    }
  }

  function motion(dyad1, dyad2) {
    var result;
    var topMotion = 0;
    var botMotion = 0;
    if (dyad1.topNote && dyad2.topNote) topMotion = dyad2.topNote.pitch - dyad1.topNote.pitch; // 0 if oblique, + if ascending, - if descending
    if (dyad1.botNote && dyad2.botNote) botMotion = dyad2.botNote.pitch - dyad1.botNote.pitch;
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
    var prevDownbeat = 0;
    var measure = 1;
    var cursor = curScore.newCursor();
    cursor.rewind(0);
    key = cursor.keySignature + 14;
    if (mode == "Minor") key += 3;
    var segment = cursor.segment;

    // Process all dyads and mark intervals
    for (var index = 0; segment;) {
      //while (segment) {
      var topElem = segment.elementAt(0);
      var botElem = segment.elementAt(4);

      if ((topElem && topElem.type == Element.CHORD) || (botElem && botElem.type == Element.CHORD)) {
        dyads[index] = new cDyad(segment, measure); // This is where the magic happens...
        if (index > 0) {
          dyads[index].prevTop = dyads[index - 1].topNote;
          dyads[index].prevBot = dyads[index - 1].botNote;
          dyads[index].prevFB = dyads[index - 1].fb;
        }
        dyads[index].processFiguredBass();
        dyads[index].processInterval();
        // Label intervals
        if (counterpointRestrictions.Show_Intervals) {
          var text = newElement(Element.STAFF_TEXT);
          text.pos.y = 10;
          text.text = dyads[index].interval.toString();
          if (dyads[index].interval.isPerfect()) text.color = colorPerf;
          if (dyads[index].nct) text.color = colorNCT;
          cursor.add(text);
        }
        cursor.next();
        index++;
      } else if (segment.elementAt(0) && segment.elementAt(0).type == Element.BAR_LINE) measure++;
      segment = segment.next;
    }

    cursor.rewind(0);
    for (var index = 0; index < dyads.length; index++) {
      // Here come the verticality error checks!
      var error = new counterpointError(cursor, dyads[index]);

      if (dyads[index].topNote && dyads[index].botNote) {
        if (counterpointRestrictions.Offbeat) {
          if (!dyads[index].newBot) {
            error.annotate(errorMessage.Offbeat, colorError);
            errorDetails.text += "Measure " + dyads[index].measure + ": First species allows only one melody note per bass note\n";
          }
        }

        if (index > 0 && index < (dyads.length - 1)) // Let's go after those triples (PT, NT, app, ret, sus, apt)
        {
          if (counterpointRestrictions.Allow_Passing_Tone) {
            if (dyads[index].nct && dyads[index].botNote && !dyads[index].newBot) {
              if (isPassing(dyads[index - 1].topNote, dyads[index].topNote, dyads[index + 1].topNote)) {
                error.annotate(errorMessage.Allow_Passing_Tone, colorCT);
                dyads[index].permittedDissonance = true;
              }
            }
          }

          if (counterpointRestrictions.Allow_Accented_Passing_Tone) {
            if (dyads[index].nct && dyads[index].botNote && dyads[index].newBot) {
              if (isPassing(dyads[index - 1].topNote, dyads[index].topNote, dyads[index + 1].topNote)) {
                error.annotate(errorMessage.Allow_Accented_Passing_Tone, colorCT);
                dyads[index].permittedDissonance = true;
              }
            }
          }

          if (counterpointRestrictions.Allow_Neighbor_Tone) {
            if (dyads[index].nct && dyads[index].botNote && !dyads[index].newBot) {
              if (isNeighbor(dyads[index - 1].topNote, dyads[index].topNote, dyads[index + 1].topNote)) {
                error.annotate(errorMessage.Allow_Neighbor_Tone, colorCT);
                dyads[index].permittedDissonance = true;
              }
            }
          }

          if (counterpointRestrictions.Allow_Accented_Neighbor) {
            if (dyads[index].nct && dyads[index].botNote && dyads[index].newBot) {
              if (isNeighbor(dyads[index - 1].topNote, dyads[index].topNote, dyads[index + 1].topNote)) {
                error.annotate(errorMessage.Allow_Accented_Neighbor, colorCT);
                dyads[index].permittedDissonance = true;
              }
            }
          }
        }

        if (counterpointRestrictions.Nota_Cambiata && index > 0 && index < dyads.length - 4) {
          var int1 = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
          var int2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
          var int3 = new cInterval(dyads[index + 1].topNote, dyads[index + 2].topNote);
          var int4 = new cInterval(dyads[index + 2].topNote, dyads[index + 3].topNote);
          if (int1.direction == -1 && int2.direction == 1 && int3.direction == -1 && int4.direction == -1 &&
            dyads[index - 1].newBot && !dyads[index].newBot && !dyads[index + 1].newBot && !dyads[index + 2].newBot && dyads[index + 3].newBot &&
            int1.size == 2 && int2.size == 3 && int3.size == 2 && int4.size == 2 &&
            !dyads[index - 1].nct && !dyads[index + 3].nct) {
            error.annotate(errorMessage.Nota_Cambiata, colorCT);
            dyads[index].permittedDissonance = true;
            dyads[index + 1].permittedDissonance = true;
            dyads[index + 2].permittedDissonance = true;
          }
        }

        if (counterpointRestrictions.Double_Neighbor && index > 0 && index < dyads.length - 4) {
          var int1 = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
          var int2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
          var int3 = new cInterval(dyads[index + 1].topNote, dyads[index + 2].topNote);
          var int4 = new cInterval(dyads[index + 2].topNote, dyads[index + 3].topNote);
          var dir1 = int1.direction;
          if (dir1 != 0 && int1.direction == dir1 && int2.direction == dir1 * -1 && int3.direction == dir1 && int4.direction == dir1 &&
            dyads[index - 1].newBot && !dyads[index].newBot && !dyads[index + 1].newBot && !dyads[index + 2].newBot && dyads[index + 3].newBot &&
            int1.size == 2 && int2.size == 3 && int3.size == 2 && int4.size == 2 &&
            !dyads[index - 1].nct && !dyads[index + 3].nct) {
            error.annotate(errorMessage.Double_Neighbor, colorCT);
            dyads[index].permittedDissonance = true;
            dyads[index + 1].permittedDissonance = true;
            dyads[index + 2].permittedDissonance = true;
          }
        }

        if (counterpointRestrictions.Allow_Suspension && index > 0 && index < dyads.length - 2) {
          var melodicInterval2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
          if (dyads[index - 1].topNote && dyads[index].topNote && dyads[index + 1].topNote &&
            !dyads[index - 1].nct && !dyads[index + 1].nct && dyads[index].newBot &&
            dyads[index - 1].topNote.pitch == dyads[index].topNote.pitch && melodicInterval2.size == 2 &&
            ((melodicInterval2.direction < 0) || (melodicInterval2.direction > 0 && melodicInterval2.quality == intervalQual.MINOR))) {
            error.annotate(errorMessage.Allow_Suspension, colorCT);
            dyads[index].permittedDissonance = true;
          }
        }

        if (index > 0 && index < (dyads.length - 2) && counterpointRestrictions.Allow_Appoggiatura) {
          var melodicInterval = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
          var melodicInterval2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
          if (melodicInterval.direction > 0 && melodicInterval.size > 2 && dyads[index].newBot && dyads[index].nct &&
            melodicInterval2.direction < 0 && melodicInterval2.size == 2 && !dyads[index + 1].nct) {
            error.annotate(errorMessage.Allow_Appoggiatura, colorCT);
            dyads[index].permittedDissonance = true;
          }
        }

        if (index > 0 && index < (dyads.length - 2) && counterpointRestrictions.Allow_Retardation) {
          var melodicInterval = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
          var melodicInterval2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
          if (melodicInterval.direction < 0 && melodicInterval.size > 2 && !dyads[index + 1].nct && dyads[index].newBot &&
            melodicInterval2.direction > 0 && melodicInterval2.size == 2 && melodicInterval2.quality == intervalQual.MINOR) {
            error.annotate(errorMessage.Allow_Retardation, colorCT);
            dyads[index].permittedDissonance = true;
          }
        }

        if (index > 0 && index < (dyads.length - 2) && counterpointRestrictions.Escape_Tone) {
          var melodicInterval = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
          var melodicInterval2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
          if (melodicInterval.size == 2 && !!dyads[index - 1].nct && dyads[index].nct &&
            !dyads[index].newBot && !dyads[index + 1].nct &&
            melodicInterval2.direction != 0 && melodicInterval.direction == -1 * melodicInterval2.direction) {
            error.annotate(errorMessage.Escape_Tone, colorCT);
            dyads[index].permittedDissonance = true;
          }
        }


        if (counterpointRestrictions.Dissonant_Downbeats) {
          if (dyads[index].newBot && dyads[index].isDissonant()) {
            error.annotate(errorMessage.Dissonant_Downbeats, colorError);
            errorDetails.text += "Measure " + dyads[index].measure + ": Dissonant interval " + dyads[index].interval.toString() + " over bass note change\n";
          }
        }

        if (counterpointRestrictions.Dissonant_Offbeats) {
          if (!dyads[index].newBot && dyads[index].isDissonant()) {
            error.annotate(errorMessage.Dissonant_Offbeats, colorError);
            errorDetails.text += "Measure " + dyads[index].measure + ": Dissonant interval " + dyads[index].interval.toString() + " off the beat\n";
          }
        }


        if (counterpointRestrictions.Voice_Crossing) {
          if (dyads[index].voiceCross()) {
            error.annotate(errorMessage.Voice_Crossing, colorError);
            errorDetails.text += "Measure " + dyads[index].measure + ": Melody crosses bass\n";
          }
        }

        if (counterpointRestrictions.Doubled_LT) {
          if (dyads[index].topNote.sd == 7 && dyads[index].botNote.sd == 7) {
            error.annotate(errorMessage.Doubled_LT, colorError);
            errorDetails.text += "Measure " + dyads[index].measure + ": Doubled Leading Tone\n";
          }
        }

        if (counterpointRestrictions.Accidentals) {
          if (dyads[index].topNote.accidental) {
            if (mode != "Minor") {
              error.annotate(errorMessage.Accidentals, colorError);
              errorDetails.text += "Measure " + dyads[index].measure + ": Accidentals are restricted in this species\n";
              dyads[index].topNote.accidental.color = "#ff0000";
            } else {
              if (dyads[index].topNote.sd < 6 || dyads[index].topNote.sd > 7) {
                error.annotate(errorMessage.Accidentals, colorError);
                errorDetails.text += "Measure " + dyads[index].measure + ": Only scale degrees 6 & 7 can be altered with accidentals in this species\n";
                dyads[index].topNote.accidental.color = "#ff0000";
              }
            }
          }
        }

        if (counterpointRestrictions.Consecutive_Downbeat_Parallels) {
          if (dyads[index].newBot) {
            if (index - prevDownbeat > 1 &&
              dyads[prevDownbeat].interval.isPerfect() &&
              dyads[index].interval.isPerfect() &&
              dyads[prevDownbeat].interval.size == dyads[index].interval.size &&
              motion(dyads[prevDownbeat], dyads[index]) == tonalMotion.SIMILAR) {
              error.annotate(errorMessage.Consecutive_Downbeat_Parallels + dyads[index].interval.toString(), colorError);
              errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Parallel " + dyads[index].interval.toString() + " on consecutive downbeats\n";
            }
            prevDownbeat = index;
          }
        }

      }

      // Now the checks of 2 consecutive notes
      if (index > 0) {
        if (counterpointRestrictions.Melodic_Aug_Or_Dim) {
          var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
          if (melodicInterval.quality != intervalQual.PERFECT &&
            melodicInterval.quality != intervalQual.MAJOR &&
            melodicInterval.quality != intervalQual.MINOR &&
            melodicInterval.size != null) {
            error.annotate(errorMessage.Melodic_Aug_Or_Dim + melodicInterval.toString(), colorError);
            errorDetails.text += "Measure " + dyads[index].measure + ": Melody leaps by dissonant interval " + melodicInterval.toString() + "\n";
          }
        }
        if (counterpointRestrictions.Melodic_Seventh) {
          var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
          if (melodicInterval.size == 7) {
            error.annotate(errorMessage.Melodic_Seventh, colorError);
            errorDetails.text += "Measure " + dyads[index].measure + ": Melody leaps " + melodicInterval.toString() + "\n";
          }
        }
        if (counterpointRestrictions.Melodic_Perfect_Parallels) {
          if (dyads[index].interval.isPerfect() &&
            dyads[index - 1].interval.isPerfect() &&
            dyads[index].interval.size == dyads[index - 1].interval.size &&
            motion(dyads[index], dyads[index - 1]) == tonalMotion.SIMILAR) {
            error.annotate(errorMessage.Melodic_Perfect_Parallels + dyads[index].interval.toString(), colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Parallel " + dyads[index].interval.toString() + "\n";
          }
        }
        if (counterpointRestrictions.Direct_Fifths) {
          if (dyads[index].interval.size == 5 &&
            dyads[index - 1].interval.size == 5 &&
            dyads[index].interval.quality != dyads[index - 1].interval.quality &&
            motion(dyads[index], dyads[index - 1]) == tonalMotion.SIMILAR) {
            error.annotate(errorMessage.Direct_Fifths, colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Consecutive 5ths in same direction\n";
          }
        }
        if (counterpointRestrictions.Hidden_Parallels) {
          if (dyads[index].newBot && dyads[index].interval.isPerfect() &&
            dyads[index - 1].interval.isPerfect() &&
            dyads[index].interval.size == dyads[index - 1].interval.size &&
            motion(dyads[index], dyads[index - 1]) == tonalMotion.CONTRARY) {
            error.annotate(errorMessage.Hidden_Parallels + dyads[index].interval.toString(), colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Hidden " + dyads[index].interval.toString() + "\n";
          }
        }
        if (counterpointRestrictions.Leap_To_Similar_Perfect) {
          if (dyads[index].interval.isPerfect()) {
            var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
            if (motion(dyads[index], dyads[index - 1]) == tonalMotion.SIMILAR &&
              melodicInterval.size > 2) {
              error.annotate(errorMessage.Leap_To_Similar_Perfect, colorError);
              errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Melody leaps to " + dyads[index].interval.toString() + " in similar motion\n";
            }
          }
        }

        if (counterpointRestrictions.Leap_From_Dissonance) {
          if (dyads[index - 1].isDissonant()) {
            var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
            if (melodicInterval.size > 2) {
              error.annotate(errorMessage.Leap_From_Dissonance, colorError);
              errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Melody leaps from NCT or dissonant interval " + dyads[index - 1].interval.toString() + "\n";
            }
          }
        }

        if (counterpointRestrictions.Leap_To_Dissonance) {
          if (dyads[index].isDissonant()) {
            var melodicInterval = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
            if (melodicInterval.size > 2) {
              error.annotate(errorMessage.Leap_To_Dissonance, colorError);
              errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Melody leaps to NCT or dissonant interval " + dyads[index].interval.toString() + "\n";
            }
          }
        }

        if (counterpointRestrictions.Repeated_Offbeat) {
          if (dyads[index].topNote && dyads[index - 1].topNote &&
            dyads[index].botNote && !dyads[index].newBot &&
            dyads[index].topNote.pitch == dyads[index - 1].topNote.pitch &&
            dyads[index].topNote.tpc == dyads[index - 1].topNote.tpc) {
            error.annotate(errorMessage.Repeated_Offbeat, colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Offbeat melody note repeats\n";
          }
        }

        if (counterpointRestrictions.Repeated_Note_Over_Barline) {
          if (dyads[index].topNote && dyads[index - 1].topNote &&
            dyads[index].botNote && dyads[index].newBot &&
            dyads[index].topNote.pitch == dyads[index - 1].topNote.pitch &&
            dyads[index].topNote.tpc == dyads[index - 1].topNote.tpc &&
            !dyads[index].permittedDissonance) {
            error.annotate(errorMessage.Repeated_Note_Over_Barline, colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Melody note repeats over bass change\n";
          }
        }

        if (dyads[index - 1].isVchord() && dyads[index].isIchord()) {
          if (counterpointRestrictions.V7_Resolution && dyads[index - 1].topNote.sd == 4 && dyads[index].topNote.sd != 3) {
            error.annotate(errorMessage.V7_Resolution, colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Seventh of V7 must resolve down by step\n";
          } else if (dyads[index - 1].topNote.sd == 7 && dyads[index].topNote.sd != 1) {
            error.annotate(errorMessage.V7_Resolution, colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Leading tone in V-I must resolve up to tonic\n";
          }
        }

        if (counterpointRestrictions.Cadence_raised_LT && index <= dyads.length - 2 &&
          dyads[index].isVchord() && dyads[index + 1].isIchord() && mode == "Minor" &&
          dyads[index].topNote.sd == 7 && !dyads[index].topNote.accidental) {
          error.annotate(errorMessage.Cadence_raised_LT, colorError);
          errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Leading tone needs to be raised at cadence\n";
        }

        if (counterpointRestrictions.Step_Back_After_Leap && index > 1) {
          if (!stepsBackAfterBigLeap(dyads[index - 2].topNote, dyads[index - 1].topNote, dyads[index].topNote)) {
            error.annotate(errorMessage.Step_Back_After_Leap, colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Melody should step back in opposite direction after a large leap\n";
          }
        }

        if (counterpointRestrictions.Max_Consecutive_36 && index > counterpointRestrictions.Max_Consecutive_36 - 1) {
          var testSize = dyads[index].interval.size;
          if (testSize == 3 || testSize == 6) {
            var tooManyConsecutive = true;
            for (var count = 1; count < counterpointRestrictions.Max_Consecutive_36 + 1; count++) {
              if (dyads[index - count].interval.size != testSize) {
                tooManyConsecutive = false;
                break;
              }
            }
            if (tooManyConsecutive) {
              error.annotate(testSize, colorError);
              errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Too many consecutive " + testSize + "\n";
            }
          }
        }
      } // index > 0
      cursor.next();
    }
    var perfectCount = 0;
    var leapCount = 0;
    var pitchSum = 0;
    var pitchMean;
    var numNotes = 0;
    for (index = 0; index < dyads.length; index++) {
      if (dyads[index].interval == intervalQual.PERFECT) perfectCount++;
      if (dyads[index].topNote) {
        pitchSum += dyads[index].topNote.pitch;
        numNotes++;
      }
      if (index > 0) {
        var leapCheck = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
        if (leapCheck.size > 2) leapCount++;
      }
    }
    pitchMean = pitchSum * 1.0 / numNotes;
    var sumSquares = 0;
    for (index = 0; index < dyads.length; index++) {
      if (dyads[index].topNote) {
        var pitchdiff = dyads[index].topNote.pitch - pitchMean;
        sumSquares += (pitchdiff * pitchdiff);
      }
    }
    var pitchDeviation = Math.sqrt(sumSquares / (numNotes - 1));

    if (leapCount * 100.0 / (dyads.length - 1) > counterpointRestrictions.Max_Leaps) {
      errorDetails.text = errorDetails.text + "Melody has more than " + counterpointRestrictions.Max_Leaps + "% leaps\n";
    }
    if (perfectCount * 100.0 / dyads.length > counterpointRestrictions.Max_Perfect) {
      errorDetails.text = errorDetails.text + "Melody has more than " + counterpointRestrictions.Max_Perfect + "% perfect intervals\n";
    }
    if (pitchDeviation < counterpointRestrictions.Min_Std_Dev) {
      errorDetails.text = errorDetails.text + "Melody should have larger range";
    }
    errorDetails.visible = true;
    Qt.quit();
  }
}
