import MuseScore 3.0

MuseScore {
  menuPath: "Plugins.Proof Reading.Pop Chord Checker"
  version: "0.1"
  description: "This plugin runs on the current open document to label chords with lead sheet (pop) chord symbols"

  function getNoteName(note_tpc) {
    var notename = "";
    var tpc_str = ["Cbb", "Gbb", "Dbb", "Abb", "Ebb", "Bbb",
      "Fb", "Cb", "Gb", "Db", "Ab", "Eb", "Bb", "F", "C", "G", "D", "A", "E", "B", "F#", "C#", "G#", "D#", "A#", "E#", "B#",
      "F##", "C##", "G##", "D##", "A##", "E##", "B##", "Fbb"
    ]; //tpc -1 is at number 34 (last item).
    if (note_tpc != 'undefined' && note_tpc <= 33) {
      if (note_tpc == -1)
        notename = tpc_str[34];
      else
        notename = tpc_str[note_tpc];
    }
    return notename;
  }

  function onlyUnique(value, index, self) {
    return self.indexOf(value) === index;
  }

  function checkTriad(chord) {
    var tempTpc = new Array();
    for (var i = 0; i < chord.notes.length; i++) {
      tempTpc[i] = chord.notes[i].tpc;
    }
    // remove dupes
    var unsortedTriad = tempTpc.filter(onlyUnique);

    var bass = unsortedTriad[0];
    var upperVoices = unsortedTriad.filter(function(x) {
      return x !== bass;
    });
    var testchord = upperVoices.map(function(x) {
      return x - bass;
    }).sort();

    var chordID = "";
    var root;
    if (testchord.length == 2) {
      var triadTPC = [
        [0, 1, 4, "", 0],
        [0, -3, 1, "m", 0],
        [0, -3, -6, "<sup>o</sup>", 0],
        [0, 4, 8, "+", 0],
        [0, -3, -4, "", 2],
        [0, 3, 4, "m", 1],
        [0, -3, 3, "<sup>o</sup>", 2],
        [0, -4, 4, "+", 1],
        [0, -1, 3, "", 1],
        [0, -1, -4, "m", 1],
        [0, 3, 6, "<sup>o</sup>", 2],
        [0, -4, -8, "+", 2]
      ];
      for (var k = 0; k < triadTPC.length; k++) {
        if (testchord[0] == triadTPC[k][1] &&
          testchord[1] == triadTPC[k][2]) {
          chordID = triadTPC[k][3];
          var whichRoot = triadTPC[k][4];
          root = triadTPC[k][whichRoot] + bass;
          if (k > 3) chordID += "/" + getNoteName(bass);
        }
      }
    } else if (testchord.length == 3) {
      var seventhChordTPC = [
        [0, 1, 4, 5, "Maj7", 0],
        [0, -2, 1, 4, "7", 0],
        [0, -3, 1, 5, "m(<sup>#7</sup>)", 0],
        [0, -2, -3, 1, "m7", 0],
        [0, -2, -3, -6, "m7b5", 0],
        [0, -3, -6, -9, "<sup>o</sup>7", 0],
        [0, -3, -4, 1, "Maj7", 2],
        [0, -3, -4, -6, "7", 2],
        [0, 3, 4, 8, "m(<sup>#7</sup>)", 1],
        [0, 1, 3, 4, "m7", 2],
        [0, -3, 1, 3, "m7b5", 3],
        [0, -3, -6, 3, "<sup>o</sup>7", 3],
        [0, -1, 3, 4, "Maj7", 1],
        [0, -1, -3, 3, "7", 1],
        [0, -1, -4, 4, "m(<sup>#7</sup>)", 1],
        [0, -1, -3, -4, "m7", 1],
        [0, 3, 4, 6, "m7b5", 3],
        [0, -3, 3, 6, "<sup>o</sup>7", 3],
        [0, -1, -4, -5, "Maj7", 3],
        [0, 2, 3, 6, "7", 1],
        [0, -4, -5, -8, "m(<sup>#7</sup>)", 2],
        [0, -1, 2, 3, "m7", 2],
        [0, -1, -4, 2, "m7b5", 3],
        [0, 3, 6, 9, "<sup>o</sup>7", 3]
      ];
      //chordID = testchord[0] + ":" + testchord[1] + ":" + testchord[2];
      for (var k = 0; k < seventhChordTPC.length; k++) {
        if (testchord[0] == seventhChordTPC[k][1] &&
          testchord[1] == seventhChordTPC[k][2] &&
          testchord[2] == seventhChordTPC[k][3]
        ) {
          chordID = seventhChordTPC[k][4];
          var whichRoot = seventhChordTPC[k][5];
          root = seventhChordTPC[k][whichRoot] + bass;
          if (k > 5) chordID += "/" + getNoteName(bass);
        }
      }
    }
    return getNoteName(root) + chordID;
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
      if (chord.type == Element.CHORD && chord.notes.length > 2) {
        if (chord.notes.length > 2) {
          var chordName = checkTriad(chord);
          var text = newElement(Element.STAFF_TEXT);
          text.text = chordName;
          //text.pos.y = -1;
          text.color = "#0000FF";
          cursor.add(text);
        }
      }
    } while (cursor.next());

    Qt.quit();
  }
}
