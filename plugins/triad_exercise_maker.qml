import QtQuick 2.1
import QtQuick.Dialogs 1.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import MuseScore 3.0

MuseScore {
  menuPath: "Exercises.Create.Create Triad ID Exercises"
  version: "0.1"
  description: "Create a practice worksheet of triad identification exercises"
  pluginType: "dialog"

  id: window
  width: 265;height: 280;
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
    id: rootPositionCheckboxLabel
    text: "Root Position"
    anchors.top: dimAugCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: rootPositionCheckbox
    checked: true
    anchors.top: dimAugCheckboxLabel.bottom
    anchors.left: rootPositionCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: firstInversionCheckboxLabel
    text: "First Inversion"
    anchors.top: rootPositionCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: firstInversionCheckbox
    checked: true
    anchors.top: rootPositionCheckboxLabel.bottom
    anchors.left: firstInversionCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: secondInversionCheckboxLabel
    text: "Second Inversion"
    anchors.top: firstInversionCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: secondInversionCheckbox
    checked: true
    anchors.top: firstInversionCheckboxLabel.bottom
    anchors.left: secondInversionCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: difficultySliderText
    text: "Difficulty"
    anchors.top: secondInversionCheckboxLabel.bottom
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
    anchors.top: secondInversionCheckboxLabel.bottom
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
    note.tpc = tpc;
    console.log("createNote:", tpc, oct);
    return note;

  }

  // create note with known midi value
  function createNote2(tpc, pitch) {
    var note = newElement(Element.NOTE);
    note.pitch = pitch;
    note.tpc = tpc;
    console.log("createNote2:", tpc, pitch);
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
      if (!majorMinorCheckbox.checked && !dimAugCheckbox.checked) {
        majorMinorCheckbox.checked = true;
        dimAugCheckbox.checked = true;
      }
      if (!(rootPositionCheckbox.checked || firstInversionCheckbox.checked ||
          secondInversionCheckbox.checked)) {
        rootPositionCheckbox.checked = true;
        firstInversionCheckbox.checked = true;
        secondInversionCheckbox.checked = true;
      }

      if (majorMinorCheckbox.checked) subtitle += "|  Maj/min  ";
      if (dimAugCheckbox.checked) subtitle += "|  dim/Aug  ";
      var probs = numProblems.value;
      var score = newScore("Triad Identification Exercises", "vibraphone", probs);
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
          var tpc0, tpc1, tpc2;
          tpc0 = rrand_i(lowtpc, hightpc + 1);
          var bassNote = createNote(tpc0, 4, 5);
          chord.add(bassNote);
          var upperNote1, upperNote2;
          while (true) {
            var choice = rrand_i(0, 12);
            if (choice == 0 && majorMinorCheckbox.checked && rootPositionCheckbox.checked) break;
            if (choice == 1 && majorMinorCheckbox.checked && rootPositionCheckbox.checked) break;
            if (choice == 2 && dimAugCheckbox.checked && rootPositionCheckbox.checked) break;
            if (choice == 3 && dimAugCheckbox.checked && rootPositionCheckbox.checked) break;
            if (choice == 4 && majorMinorCheckbox.checked && firstInversionCheckbox.checked) break;
            if (choice == 5 && majorMinorCheckbox.checked && firstInversionCheckbox.checked) break;
            if (choice == 6 && dimAugCheckbox.checked && firstInversionCheckbox.checked) break;
            if (choice == 7 && dimAugCheckbox.checked && firstInversionCheckbox.checked) break;
            if (choice == 8 && majorMinorCheckbox.checked && secondInversionCheckbox.checked) break;
            if (choice == 9 && majorMinorCheckbox.checked && secondInversionCheckbox.checked) break;
            if (choice == 10 && dimAugCheckbox.checked && secondInversionCheckbox.checked) break;
            if (choice == 11 && dimAugCheckbox.checked && secondInversionCheckbox.checked) break;
          }

          if (choice == 0) {
            // major
            upperNote1 = createNote2(tpc0 + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(tpc0 + 1, bassNote.pitch + 7);
            tpc1 = tpc0 + 4;
            tpc2 = tpc0 + 1;
          } else if (choice == 1) {
            // minor
            upperNote1 = createNote2(tpc0 - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(tpc0 + 1, bassNote.pitch + 7);
            tpc1 = tpc0 - 3;
            tpc2 = tpc0 + 1;
          } else if (choice == 2) {
            // diminished
            upperNote1 = createNote2(tpc0 - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(tpc0 - 6, bassNote.pitch + 6);
            tpc1 = tpc0 - 3;
            tpc2 = tpc0 - 6;
          } else if (choice == 3) {
            // augmented
            upperNote1 = createNote2(tpc0 + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(tpc0 + 8, bassNote.pitch + 8);
            tpc1 = tpc0 + 4;
            tpc2 = tpc0 + 8;
          } else if (choice == 4) {
            // major, 1st inversion
            upperNote1 = createNote2(tpc0 - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(tpc0 - 4, bassNote.pitch + 8);
            tpc1 = tpc0 - 3;
            tpc2 = tpc0 - 4;
          } else if (choice == 5) {
            // minor, 1st inversion
            upperNote1 = createNote2(tpc0 + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(tpc0 + 3, bassNote.pitch + 9);
            tpc1 = tpc0 + 4;
            tpc2 = tpc0 + 3;
          } else if (choice == 6) {
            // diminished, 1st inversion
            upperNote1 = createNote2(tpc0 - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(tpc0 + 3, bassNote.pitch + 9);
            tpc1 = tpc0 - 3;
            tpc2 = tpc0 + 3;
          } else if (choice == 7) {
            // augmented, 1st inversion
            upperNote1 = createNote2(tpc0 + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(tpc0 - 4, bassNote.pitch + 8);
            tpc1 = tpc0 + 4;
            tpc2 = tpc0 - 4;
          } else if (choice == 8) {
            // major, 2nd inversion
            upperNote1 = createNote2(tpc0 - 1, bassNote.pitch + 5);
            upperNote2 = createNote2(tpc0 + 3, bassNote.pitch + 9);
            tpc1 = tpc0 - 1;
            tpc2 = tpc0 + 3;
          } else if (choice == 9) {
            // minor, 2nd inversion
            upperNote1 = createNote2(tpc0 - 1, bassNote.pitch + 5);
            upperNote2 = createNote2(tpc0 - 4, bassNote.pitch + 8);
            tpc1 = tpc0 - 1;
            tpc2 = tpc0 - 4;
          } else if (choice == 10) {
            // diminished, 2nd inversion
            upperNote1 = createNote2(tpc0 + 6, bassNote.pitch + 6);
            upperNote2 = createNote2(tpc0 + 3, bassNote.pitch + 9);
            tpc1 = tpc0 + 6;
            tpc2 = tpc0 + 3;
          } else if (choice == 11) {
            // augmented, 2nd inversion
            upperNote1 = createNote2(tpc0 - 8, bassNote.pitch + 4);
            upperNote2 = createNote2(tpc0 - 4, bassNote.pitch + 8);
            tpc1 = tpc0 - 8;
            tpc2 = tpc0 - 4;
          }
          chord.add(upperNote1); //add notes to the chord
          chord.add(upperNote2); //add notes to the chord
          chord.notes[1].tpc = tpc0;
          chord.notes[1].tpc1 = tpc0;
          chord.notes[1].tpc2 = tpc0;
          chord.notes[2].tpc = tpc1;
          chord.notes[2].tpc1 = tpc1;
          chord.notes[2].tpc2 = tpc1;
          chord.notes[3].tpc = tpc2;
          chord.notes[3].tpc1 = tpc2;
          chord.notes[3].tpc2 = tpc2;

          var notes = chord.notes;
          chord.remove(notes[0]);
        }
        cursor.next();
      }
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
