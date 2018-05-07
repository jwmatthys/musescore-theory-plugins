import QtQuick 2.1
import QtQuick.Dialogs 1.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import MuseScore 1.0

MuseScore {
  menuPath: "Exercises.Create.Create Triad ID Exercises"
  version: "0.1"
  description: "Create a practice worksheet of triad identification exercises"
  pluginType: "dialog"

  id: window
  width: 265;height: 260;
  onRun: {}

  property
  var difficulty: [
    [15, 17],
    [13, 19], // naturals only
    [11, 21], // Eb, Bb, F#, C#
    [9, 23], // Db - D#
  ];

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
    id: majorMinorCheckboxLabel
    text: "Major & Minor Triads"
    anchors.top: numProblemsLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: majorMinorCheckbox
    checked: true
    anchors.top: numProblemsLabel.bottom
    anchors.left: majorMinorCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: dimAugCheckboxLabel
    text: "Diminished & Augmented Triads"
    anchors.top: majorMinorCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: dimAugCheckbox
    checked: true
    anchors.top: majorMinorCheckboxLabel.bottom
    anchors.left: dimAugCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: difficultySliderText
    text: "Difficulty"
    anchors.top: dimAugCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Slider {
    id: difficultySlider
    maximumValue: 4
    minimumValue: 1
    stepSize: 1
    value: 2
    anchors.top: dimAugCheckboxLabel.bottom
    anchors.left: difficultySliderText.right
    anchors.right: window.right
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
    return note;
  }

  // create note with known midi value
  function createNote2(tpc, pitch) {
    var note = newElement(Element.NOTE);
    note.pitch = pitch;
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
      var subtitle = "Difficulty: " + difficultySlider.value + "  ";
      if (majorMinorCheckbox.checked) subtitle += "|  Maj/min  ";
      if (dimAugCheckbox.checked) subtitle += "|  dim/Aug  ";
      var probs = numProblems.value;
      var score = newScore("Triad Identification Exercises", "treble", probs);
      score.startCmd();
      score.addText("title", "Triad Identification Exercises");
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
          var lowtpc = difficulty[difficultySlider.value - 1][0];
          var hightpc = difficulty[difficultySlider.value - 1][1];
          var bassNote = createNote(rrand_i(lowtpc, hightpc + 1), 4, 5);
          chord.add(bassNote);
          var upperNote1, upperNote2;
          while (true) {
            var choice = rrand_i(0, 12);
            if (choice == 0 && majorMinorCheckbox.checked) break;
            if (choice == 1 && majorMinorCheckbox.checked) break;
            if (choice == 2 && dimAugCheckbox.checked) break;
            if (choice == 3 && dimAugCheckbox.checked) break;
            if (choice == 4 && majorMinorCheckbox.checked) break;
            if (choice == 5 && majorMinorCheckbox.checked) break;
            if (choice == 6 && dimAugCheckbox.checked) break;
            if (choice == 7 && dimAugCheckbox.checked) break;
            if (choice == 8 && majorMinorCheckbox.checked) break;
            if (choice == 9 && majorMinorCheckbox.checked) break;
            if (choice == 10 && dimAugCheckbox.checked) break;
            if (choice == 11 && dimAugCheckbox.checked) break;
          }

          if (choice == 0) {
            // major
            upperNote1 = createNote2(bassNote.tpc + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc + 1, bassNote.pitch + 7);
          } else if (choice == 1) {
            // minor
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc + 1, bassNote.pitch + 7);
          } else if (choice == 2) {
            // diminished
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc - 6, bassNote.pitch + 6);
          } else if (choice == 3) {
            // augmented
            upperNote1 = createNote2(bassNote.tpc + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc + 8, bassNote.pitch + 8);
          } else if (choice == 4) {
            // major, 1st inversion
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc - 4, bassNote.pitch + 8);
          } else if (choice == 5) {
            // minor, 1st inversion
            upperNote1 = createNote2(bassNote.tpc + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc + 3, bassNote.pitch + 9);
          } else if (choice == 6) {
            // diminished, 1st inversion
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc + 3, bassNote.pitch + 9);
          } else if (choice == 7) {
            // augmented, 1st inversion
            upperNote1 = createNote2(bassNote.tpc + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc - 4, bassNote.pitch + 8);
          } else if (choice == 8) {
            // major, 2nd inversion
            upperNote1 = createNote2(bassNote.tpc - 1, bassNote.pitch + 5);
            upperNote2 = createNote2(bassNote.tpc + 3, bassNote.pitch + 9);
          } else if (choice == 9) {
            // minor, 2nd inversion
            upperNote1 = createNote2(bassNote.tpc - 1, bassNote.pitch + 5);
            upperNote2 = createNote2(bassNote.tpc - 4, bassNote.pitch + 8);
          } else if (choice == 10) {
            // diminished, 2nd inversion
            upperNote1 = createNote2(bassNote.tpc + 6, bassNote.pitch + 6);
            upperNote2 = createNote2(bassNote.tpc + 3, bassNote.pitch + 9);
          } else if (choice == 11) {
            // augmented, 2nd inversion
            upperNote1 = createNote2(bassNote.tpc - 8, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc - 4, bassNote.pitch + 8);
          }
          chord.add(upperNote1); //add notes to the chord
          chord.add(upperNote2); //add notes to the chord
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
