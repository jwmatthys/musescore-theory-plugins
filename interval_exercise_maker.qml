import QtQuick 2.1
import QtQuick.Dialogs 1.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import MuseScore 1.0

MuseScore {
  menuPath: "Exercises.Create Interval Worksheet"
  version: "0.0"
  description: "Create a practice worksheet of interval exercises"
  pluginType: "dialog"

  id: window
  width: 250;height: 120;
  onRun: {}

  //  property
  //  var naturalPitch: [0, 2, 4, 5, 7, 9, 11];

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

  Text {
    id: numProblemsLabel
    text: "Number of problems"
    anchors.top: window.top
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  SpinBox {
    id: numProblems
    minimumValue: 5
    maximumValue: 100
    stepSize: 5
    anchors.left: numProblemsLabel.right
    anchors.right: window.right
    anchors.top: window.top
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    Layout.fillWidth: true
    Layout.preferredHeight: 25
    value: 5
  }

  Text {
    id: trebleClefCheckboxLabel
    text: "Treble Clef"
    anchors.top: numProblemsLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: trebleClefCheckbox
    checked: true
    anchors.top: numProblemsLabel.bottom
    anchors.left: trebleClefCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: bassClefCheckboxLabel
    text: "Bass Clef"
    anchors.top: numProblemsLabel.bottom
    anchors.left: trebleClefCheckbox.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: bassClefCheckbox
    checked: false
    anchors.top: numProblemsLabel.bottom
    anchors.left: bassClefCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  function rrand_i(val1, val2) {
    return Math.floor(Math.random() * (val2 - val1)) + val1;
  }

  function tpc2pc(tpc) {
    var tpc0 = [2, 9, 4, -1, 6, 1, 8, 3, 10, 5, 0, 7];
    for (var enh = 0; enh < 3; enh++) {
      for (var pc = 0; pc < 12; pc++) {
        if (tpc == (tpc0[pc] + (12 * enh))) {
          return pc;
        }
      }
    }
  }

  function createNote(tpc, oct) {
    var note = newElement(Element.NOTE);
    note.pitch = tpc2pc(tpc) + 12 * (oct + 1);
    note.tpc1 = tpc;
    note.tpc2 = tpc;
    note.headType = NoteHead.HEAD_AUTO;
    console.log("  created note with tpc: ", note.tpc1, " ", note.tpc2, " pitch: ", note.pitch);
    return note;
  }

  function setCursorToTime(cursor, time) {
    cursor.rewind(0);
    while (cursor.segment) {
      var current_time = cursor.tick;
      if (current_time >= time) {
        return true;
      }
      cursor.next();
    }
    cursor.rewind(0);
    return false;
  }

  Button {
    id: buttonCreateWorksheet
    text: "Create Worksheet"
    anchors.bottom: window.bottom
    anchors.left: window.left
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    anchors.leftMargin: 10
    onClicked: {
      var probs = numProblems.value;
      var score = newScore("Interval Worksheet", "treble", probs);
      score.startCmd();
      score.addText("title", "Interval Worksheet");
      score.addText("subtitle", "subtitle");

      var cursor = score.newCursor();
      cursor.track = 0;

      //var ts = newElement(Element.TIMESIG);
      //ts.setSig(4, 4);
      //cursor.add(ts);

      cursor.rewind(0);

      for (var j = 0; j < probs; j++) {
        cursor.setDuration(4, 4);
        cursor.addNote(60);
      }

      cursor.rewind(0);

      for (var j = 0; j < probs; j++) {
        var chord = cursor.element; //get the chord created when 1st note was inserted
        if (chord.type == Element.CHORD) {
          var testnote1, testnote2, testInterval;
          do {
            testnote1 = createNote(rrand_i(6, 27), rrand_i(4, 6));
            testnote2 = createNote(rrand_i(6, 27), rrand_i(4, 6));
            testInterval = checkInterval(testnote1, testnote2);
          } while (testInterval[1] == 'A' || testInterval[1] == 'd');
          chord.add(testnote1); //add notes to the chord
          chord.add(testnote2); //add notes to the chord
          var notes = chord.notes;
          chord.remove(notes[0]);
          //var text = newElement(Element.STAFF_TEXT);
          //text.text = testInterval;
          //cursor.add(text);
        }
        cursor.next();
        //setCursorToTime(cursor, next_time);
      }
      score.doLayout();
      score.endCmd();
      Qt.quit();
    }
  }

  Button {
    id: buttonCancel
    text: "Cancel"
    anchors.bottom: window.bottom
    anchors.right: window.right
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    anchors.rightMargin: 10
    onClicked: {
      Qt.quit();
    }
  }
}
