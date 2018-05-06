import MuseScore 1.0

MuseScore {
  menuPath: "Exercises.Check.Check Interval ID Exercises"
  version: "0.1"
  description: "Check interval identification exercises"

  function getUserInterval(segment) {
    var sArray = new Array();
    var lyrics = segment.elementAt(0).lyrics;
    if (lyrics) {
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
    var temp = sArray.toString();
    var temp_fixAug = temp.replace(/[\+]/g, 'A');
    var temp_stripped = temp_fixAug.replace(/[^12345678AdMmP]/g, '');
    return temp_stripped;
  }

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
      quality = "A";
    } else if (diff >= 13 && diff <= 19) {
      quality = "AA";
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
    var count = 0;
    do {
      var chord = cursor.element; //get the chord created when 1st note was inserted
      if (chord.type == Element.CHORD) {
        var notes = chord.notes;
        if (notes.length > 1) {
          var segment = cursor.segment;
          var userInterval = getUserInterval(segment);
          var userSize = userInterval.replace(/[^12345678]/g, '');
          var userQuality = userInterval.replace(/[^AdMmP]/g, '');

          var interval = checkInterval(notes[0], notes[1]);
          var trueSize = interval.replace(/[^12345678]/g, '');
          var trueQuality = interval.replace(/[^AdMmP]/g, '');
          var text = newElement(Element.STAFF_TEXT);
          text.color = "#FF0000";
          if (userSize == "" || userQuality == "") {
            text.text = "?";
          } else if (userSize != trueSize && userQuality != trueQuality) {
            text.text = "size\nqual";
          } else if (userSize != trueSize) {
            text.text = "size";
          } else if (userQuality != trueQuality) {
            text.text = "qual";
          } else {
            text.text = "OK";
            text.color = "#00BB00";
            count++;
          }
          text.pos.y = -2;
          cursor.add(text);
        }
      }
    } while (cursor.next());

    curScore.addText("poet", "Number correct: " + count);
    Qt.quit();
  }
}
