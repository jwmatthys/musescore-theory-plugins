import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 1.0

MuseScore {
  menuPath: "Plugins.Proof Reading.SATB"
  description: "Check for Part Writing Errors in Tonal SATB Chorales"
  version: "0.1"

  property
  var mode: "Major";
  property
  var key: 14;

  MessageDialog {
    id: errorDetails
    title: "SATB Part Writing Proofreading Messages"
    text: ""
    onAccepted: {
      Qt.quit();
    }
    visible: false;
  }

  function getChord(segment, measure) {
    this.segment = segment; // type Cursor.SEGMENT
    this.permittedDissonance = false;

    this.getNote = function(elem) {
      var result = null;
      if (elem && elem.type == Element.CHORD) {
        result = elem.notes;
      }
      return result;
    }

    this.measure = measure; // type int
    this.sopr = null;
    this.alto = null;
    this.tenor = null;
    this.bass = null;
    this.hasRoot = null;
    this.hasThird = null;
    this.voiceCross = null;

    this.trebleLayer1 = this.getNote(this.segment.elementAt(0));
    this.trebleLayer2 = this.getNote(this.segment.elementAt(1));
    this.bassLayer1 = this.getNote(this.segment.elementAt(4));
    this.bassLayer2 = this.getNote(this.segment.elementAt(5));

    if (this.trebleLayer1.length > 1) {
      this.sopr = this.trebleLayer1[this.trebleLayer1.length - 1];
      this.alto = this.trebleLayer1[this.trebleLayer1.length - 2];
    } else {
      this.sopr = this.trebleLayer1[this.trebleLayer1.length - 1];
      this.alto = this.trebleLayer2[this.trebleLayer2.length - 1];
    }

    if (this.bassLayer1.length > 1) {
      this.tenor = this.bassLayer1[this.bassLayer1.length - 1];
      this.bass = this.bassLayer1[this.bassLayer1.length - 2];
    } else {
      this.tenor = this.bassLayer1[this.bassLayer1.length - 1];
      if (this.bassLayer2) this.bass = this.bassLayer2[this.bassLayer2.length - 1];
    }
    if (this.trebleLayer1.length > 2) { // keyboard style
      this.tenor = this.trebleLayer1[this.trebleLayer1.length - 3];
      this.bass = this.bassLayer1[this.bassLayer1.length - 1];
    }

    this.checkVoiceCrossing = function() {
      if (this.alto.pitch > this.sopr.pitch) return true;
      if (this.tenor.pitch > this.alto.pitch) return true;
      if (this.bass.pitch > this.tenor.pitch) return true;
      return false;
    }

    this.voiceCross = this.checkVoiceCrossing();

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

    this.roman = this.getRoman();
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
        errorDetails.text += "m. " + tetrachords[index].measure + ". " + tetrachords[index].roman + ": ";
        errorDetails.text += tetrachords[index].sopr.pitch + ", " + tetrachords[index].alto.pitch + ", " + tetrachords[index].tenor.pitch + ", " + tetrachords[index].bass.pitch + "\n";
        cursor.next();
      } else if (segment.elementAt(0) && segment.elementAt(0).type == Element.BAR_LINE) measure++;
      segment = segment.next;
    }
    errorDetails.visible = true;
    Qt.quit();
  }
}
