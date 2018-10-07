import MuseScore 1.0

MuseScore {
  menuPath: "Plugins.Proof Reading.Interval Checker"
  version: "0.1"
  description: "This plugin runs on the current open document to label intervals by size and quality"

  function checkInterval(n1, n2) {
    var note1 = n1;
    var note2 = n2;
    if (note2.pitch < note1.pitch) {
      note1 = n2;
      note2 = n1;
    }
    var size = 0;
    var quality = "";
    var diff = note2.tpc - note1.tpc;
    if (diff >= -1 && diff <= 1) {
      quality = "P";
    } else if (diff >= 2 && diff <= 5) {
      quality = "M";
    } else if (diff >= 6 && diff <= 12) {
      quality = "+";
    } else if (diff >= 13 && diff <= 19) {
      quality = "++";
    } else if (diff <= -2 && diff >= -5) {
      quality = "m";
    } else if (diff <= -6 && diff >= -12) {
      quality = "d";
    } else if (diff <= -13 && diff >= -19) {
      quality = "dd";
    } else quality = "?";

    var circlediff = (28 + note2.tpc - note1.tpc) % 7;
    if (circlediff == 1) {
      size = 5;
    } else if (circlediff == 2) {
      size = 2;
    } else if (circlediff == 3) {
      size = 6;
    } else if (circlediff == 4) {
      size = 3;
    } else if (circlediff == 5) {
      size = 7;
    } else if (circlediff == 6) {
      size = 4;
    } else {
      if ((note2.pitch - note1.pitch) > 2)
        size = 8;
      else size = 1;
    }
    return quality + size;
  }

  onRun: {
    if (typeof curScore == 'undefined' || curScore == null) {
      console.log("no score found");
      Qt.quit();
    }
    var cursor = curScore.newCursor();
    cursor.rewind(0);
    do {
      var chord = cursor.element; //get the chord created when 1st note was inserted
      if (chord.type == Element.CHORD) {
        var notes = chord.notes;
        if (notes.length > 1) {
          var interval = checkInterval(notes[0], notes[1]);
          var text = newElement(Element.STAFF_TEXT);
          text.text = interval;
          text.pos.y = -1;
          text.color = "#0000FF";
          cursor.add(text);
        }
      }
    } while (cursor.next());

    Qt.quit();
  }
}
