import QtQuick 2.1
import QtQuick.Dialogs 1.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import MuseScore 1.0

MuseScore {
  menuPath: "Exercises.Create.Create Interval ID Exercises"
  version: "0.1"
  description: "Create a practice worksheet of interval identification exercises"
  pluginType: "dialog"

  id: window
  width: 265;height: 260;
  onRun: {}

  property
  var difficulty: [
    [13, 19], // naturals only
    [11, 21], // Eb, Bb, F#, C#
    [9, 23], // Db - D#
    [6, 26], // Fb - B#
    [-1, 33] // All
  ];

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
    value: 10
  }

  Text {
    id: perfectIntervalCheckboxLabel
    text: "Perfect intervals"
    anchors.top: numProblemsLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: perfectIntervalCheckbox
    checked: true
    anchors.top: numProblemsLabel.bottom
    anchors.left: perfectIntervalCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: imperfectIntervalCheckboxLabel
    text: "M/m intervals"
    anchors.top: perfectIntervalCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: imperfectIntervalCheckbox
    checked: true
    anchors.top: perfectIntervalCheckboxLabel.bottom
    anchors.left: imperfectIntervalCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: dimaugIntervalCheckboxLabel
    text: "Aug/dim intervals"
    anchors.top: imperfectIntervalCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: dimaugIntervalCheckbox
    checked: true
    anchors.top: imperfectIntervalCheckboxLabel.bottom
    anchors.left: dimaugIntervalCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: doubleDimaugIntervalCheckboxLabel
    text: "Double Aug/dim intervals"
    anchors.top: dimaugIntervalCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: doubleDimaugIntervalCheckbox
    checked: false
    anchors.top: dimaugIntervalCheckboxLabel.bottom
    anchors.left: doubleDimaugIntervalCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: difficultySliderText
    text: "Difficulty"
    anchors.top: doubleDimaugIntervalCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Slider {
    id: difficultySlider
    maximumValue: 5
    minimumValue: 1
    stepSize: 1
    value: 3
    anchors.top: doubleDimaugIntervalCheckboxLabel.bottom
    anchors.left: difficultySliderText.right
    anchors.right: window.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  function checkboxText(interval) {
    // return false if the interval is permitted?
    if (interval == 'A1') return true; // nobody wants augmented unison!
    if (interval == 'AA1') return true; // even more true of doubly augmented unison.
    if (interval[0] == 'P' && perfectIntervalCheckbox.checked) return false;
    if (interval[0] == 'm' && imperfectIntervalCheckbox.checked) return false;
    if (interval[0] == 'M' && imperfectIntervalCheckbox.checked) return false;
    if (interval[1] == 'd' && doubleDimaugIntervalCheckbox.checked) return false;
    if (interval[1] == 'A' && doubleDimaugIntervalCheckbox.checked) return false;
    if (interval[0] == 'd' && interval[1] != 'd' && dimaugIntervalCheckbox.checked) return false;
    if (interval[0] == 'A' && interval[1] != 'A' && dimaugIntervalCheckbox.checked) return false;
    return true;
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
    id: buttonCreateExercises
    text: "Create Exercises"
    anchors.bottom: window.bottom
    anchors.left: window.left
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    anchors.leftMargin: 10
    onClicked: {
      if (!(perfectIntervalCheckbox.checked &&
          imperfectIntervalCheckbox.checked &&
          dimaugIntervalCheckbox.checked &&
          doubleDimaugIntervalCheckbox.checked)) imperfectIntervalCheckbox.checked = true;
      //if (doubleDimaugIntervalCheckbox.checked && difficultySlider.value < 3) doubleDimaugIntervalCheckbox.checked = false;
      var subtitle = "Difficulty: " + difficultySlider.value + "  ";
      if (perfectIntervalCheckbox.checked) subtitle += "|  Perf  ";
      if (imperfectIntervalCheckbox.checked) subtitle += "|  Maj/min  ";
      if (dimaugIntervalCheckbox.checked) subtitle += "|  dim/Aug  ";
      if (doubleDimaugIntervalCheckbox.checked) subtitle += "|  dd/AA";
      var probs = numProblems.value;
      var score = newScore("Interval Identification Exercises", "treble", probs);
      score.startCmd();
      score.addText("title", "Interval Identification Exercises");
      score.addText("subtitle", subtitle);

      var cursor = score.newCursor();
      cursor.track = 0;

      cursor.rewind(0);

      for (var j = 0; j < probs; j++) {
        cursor.setDuration(4, 4);
        cursor.addNote(60);
      }

      cursor.rewind(0);

      for (var j = 0; j < probs; j++) {
        var chord = cursor.element; //get the chord created when 1st note was inserted
        if (chord.type == Element.CHORD) {
          var testnote1, testnote2;
          while (true) {
            var lowtpc = difficulty[difficultySlider.value - 1][0];
            var hightpc = difficulty[difficultySlider.value - 1][1];
            testnote1 = createNote(rrand_i(lowtpc, hightpc + 1), rrand_i(4, 6));
            testnote2 = createNote(rrand_i(lowtpc, hightpc + 1), rrand_i(4, 6));
            var testInterval = checkInterval(testnote1, testnote2);
            if (testInterval == 'A1') continue;
            if (testInterval[0] == 'P' && perfectIntervalCheckbox.checked) break;
            if (testInterval[0] == 'm' && imperfectIntervalCheckbox.checked) break;
            if (testInterval[0] == 'M' && imperfectIntervalCheckbox.checked) break;
            if (testInterval[1] == 'd' && doubleDimaugIntervalCheckbox.checked) break;
            if (testInterval[1] == 'A' && doubleDimaugIntervalCheckbox.checked) break;
            if (testInterval[0] == 'd' && testInterval[1] != 'd' && dimaugIntervalCheckbox.checked) break;
            if (testInterval[0] == 'A' && testInterval[1] != 'A' && dimaugIntervalCheckbox.checked) break;
          }
          chord.add(testnote1); //add notes to the chord
          chord.add(testnote2); //add notes to the chord
          var notes = chord.notes;
          chord.remove(notes[0]);
        }
        cursor.next();
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
