import QtQuick 2.1
import QtQuick.Dialogs 1.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import MuseScore 1.0

MuseScore {
  menuPath: "Exercises.Create.Create Seventh Chord ID Exercises"
  version: "0.1"
  description: "Create a practice worksheet of seventh chord identification exercises"
  pluginType: "dialog"

  id: window
  width: 265;height: 300;
  onRun: {}

  property
  var difficulty: [
    [13, 19], // naturals only
    [12, 20],
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
    id: majorMinorSeventhCheckboxLabel
    text: "Major & Minor Chords"
    anchors.top: numProblemsLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: majorMinorSeventhCheckbox
    checked: true
    anchors.top: numProblemsLabel.bottom
    anchors.left: majorMinorSeventhCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: dimSeventhCheckboxLabel
    text: "Diminished Seventh Chords"
    anchors.top: majorMinorSeventhCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: dimSeventhCheckbox
    checked: true
    anchors.top: majorMinorSeventhCheckboxLabel.bottom
    anchors.left: dimSeventhCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: rootPositionCheckboxLabel
    text: "Root Position"
    anchors.top: dimSeventhCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: rootPositionCheckbox
    checked: true
    anchors.top: dimSeventhCheckboxLabel.bottom
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
    id: thirdInversionCheckboxLabel
    text: "Third Inversion"
    anchors.top: secondInversionCheckboxLabel.bottom
    anchors.left: window.left
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  CheckBox {
    id: thirdInversionCheckbox
    checked: true
    anchors.top: secondInversionCheckboxLabel.bottom
    anchors.left: thirdInversionCheckboxLabel.right
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    anchors.topMargin: 10
    anchors.bottomMargin: 10
  }

  Text {
    id: difficultySliderText
    text: "Difficulty"
    anchors.top: thirdInversionCheckboxLabel.bottom
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
    anchors.top: thirdInversionCheckboxLabel.bottom
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
      if (!majorMinorSeventhCheckbox.checked && !dimSeventhCheckbox.checked) {
        majorMinorSeventhCheckbox.checked = true;
        dimSeventhCheckbox.checked = true;
      }
      if (!(rootPositionCheckbox.checked || firstInversionCheckbox.checked ||
          secondInversionCheckbox.checked || thirdInversionCheckbox.checked)) {
        rootPositionCheckbox.checked = true;
        firstInversionCheckbox.checked = true;
        secondInversionCheckbox.checked = true;
        thirdInversionCheckbox.checked = true;
      }
      if (majorMinorSeventhCheckbox.checked) subtitle += "|  MM/Mm/mm  ";
      if (dimSeventhCheckbox.checked) subtitle += "|  dim7/<sup>Ø</sup>7  ";
      var probs = numProblems.value;
      var score = newScore("Seventh Chord Identification Exercises", "treble", probs);score.startCmd();score.addText("title", "Seventh Chord Identification Exercises");score.addText("subtitle", subtitle);

      var cursor = score.newCursor();cursor.track = 0;

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
          var bassNote, upperNote1, upperNote2, upperNote3;
          while (true) {
            bassNote = createNote(rrand_i(lowtpc, hightpc + 1), 4, 5);
            var choice = rrand_i(0, 20);
            if (choice == 0 && majorMinorSeventhCheckbox.checked && rootPositionCheckbox.checked) break;
            if (choice == 1 && majorMinorSeventhCheckbox.checked && rootPositionCheckbox.checked) break;
            if (choice == 2 && majorMinorSeventhCheckbox.checked && rootPositionCheckbox.checked) break;
            if (choice == 3 && dimSeventhCheckbox.checked && rootPositionCheckbox.checked) break;
            if (choice == 4 && dimSeventhCheckbox.checked && rootPositionCheckbox.checked) break;
            if (choice == 5 && majorMinorSeventhCheckbox.checked && firstInversionCheckbox.checked) break;
            if (choice == 6 && majorMinorSeventhCheckbox.checked && firstInversionCheckbox.checked) break;
            if (choice == 7 && majorMinorSeventhCheckbox.checked && firstInversionCheckbox.checked) break;
            if (choice == 8 && dimSeventhCheckbox.checked && firstInversionCheckbox.checked) break;
            if (choice == 9 && dimSeventhCheckbox.checked && firstInversionCheckbox.checked) break;
            if (choice == 10 && majorMinorSeventhCheckbox.checked && secondInversionCheckbox.checked) break;
            if (choice == 11 && majorMinorSeventhCheckbox.checked && secondInversionCheckbox.checked) break;
            if (choice == 12 && majorMinorSeventhCheckbox.checked && secondInversionCheckbox.checked) break;
            if (choice == 13 && dimSeventhCheckbox.checked && secondInversionCheckbox.checked) break;
            if (choice == 14 && dimSeventhCheckbox.checked && secondInversionCheckbox.checked) break;
            if (choice == 15 && majorMinorSeventhCheckbox.checked && bassNote.pitch > 62 && thirdInversionCheckbox.checked) break;
            if (choice == 16 && majorMinorSeventhCheckbox.checked && bassNote.pitch > 62 && thirdInversionCheckbox.checked) break;
            if (choice == 17 && majorMinorSeventhCheckbox.checked && bassNote.pitch > 62 && thirdInversionCheckbox.checked) break;
            if (choice == 18 && dimSeventhCheckbox.checked && bassNote.pitch > 62 && thirdInversionCheckbox.checked) break;
            if (choice == 19 && dimSeventhCheckbox.checked && bassNote.pitch > 62 && thirdInversionCheckbox.checked) break;
          }

          if (choice == 0) {
            // MM
            upperNote1 = createNote2(bassNote.tpc + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc + 1, bassNote.pitch + 7);
            upperNote3 = createNote2(bassNote.tpc + 5, bassNote.pitch + 11);
          } else if (choice == 1) {
            // Mm
            upperNote1 = createNote2(bassNote.tpc + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc + 1, bassNote.pitch + 7);
            upperNote3 = createNote2(bassNote.tpc - 2, bassNote.pitch + 10);
          } else if (choice == 2) {
            // mm
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc + 1, bassNote.pitch + 7);
            upperNote3 = createNote2(bassNote.tpc - 2, bassNote.pitch + 10);
          } else if (choice == 3) {
            // half dim
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc - 6, bassNote.pitch + 6);
            upperNote3 = createNote2(bassNote.tpc - 2, bassNote.pitch + 10);
          } else if (choice == 4) {
            // dim7
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc - 6, bassNote.pitch + 6);
            upperNote3 = createNote2(bassNote.tpc - 9, bassNote.pitch + 9);
          } else if (choice == 5) {
            // MM, 1st inv
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc + 1, bassNote.pitch + 7);
            upperNote3 = createNote2(bassNote.tpc - 4, bassNote.pitch + 8);
          } else if (choice == 6) {
            // Mm, 1st inv
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc - 6, bassNote.pitch + 6);
            upperNote3 = createNote2(bassNote.tpc - 4, bassNote.pitch + 8);
          } else if (choice == 7) {
            // mm, 1st inv
            upperNote1 = createNote2(bassNote.tpc + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc + 1, bassNote.pitch + 7);
            upperNote3 = createNote2(bassNote.tpc + 3, bassNote.pitch + 9);
          } else if (choice == 8) {
            // half dim, 1st inv
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc + 1, bassNote.pitch + 7);
            upperNote3 = createNote2(bassNote.tpc + 3, bassNote.pitch + 9);
          } else if (choice == 9) {
            // dim7, 1st inv
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc + 6, bassNote.pitch + 6);
            upperNote3 = createNote2(bassNote.tpc + 3, bassNote.pitch + 9);
          } else if (choice == 10) {
            // MM, 2nd inv
            upperNote1 = createNote2(bassNote.tpc + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc - 1, bassNote.pitch + 5);
            upperNote3 = createNote2(bassNote.tpc + 3, bassNote.pitch + 9);
          } else if (choice == 11) {
            // Mm, 2nd inv
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc - 1, bassNote.pitch + 5);
            upperNote3 = createNote2(bassNote.tpc + 3, bassNote.pitch + 9);
          } else if (choice == 12) {
            // mm, 2nd inv
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc - 1, bassNote.pitch + 5);
            upperNote3 = createNote2(bassNote.tpc - 4, bassNote.pitch + 8);
          } else if (choice == 13) {
            // half dim, 2nd inv
            upperNote1 = createNote2(bassNote.tpc + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc + 6, bassNote.pitch + 6);
            upperNote3 = createNote2(bassNote.tpc + 3, bassNote.pitch + 9);
          } else if (choice == 14) {
            // dim7, 2nd inv
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc + 6, bassNote.pitch + 6);
            upperNote3 = createNote2(bassNote.tpc + 3, bassNote.pitch + 9);
          } else if (choice == 15) {
            // MM
            upperNote1 = createNote2(bassNote.tpc + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc + 1, bassNote.pitch + 7);
            upperNote3 = createNote2(bassNote.tpc + 5, bassNote.pitch - 1);
          } else if (choice == 16) {
            // Mm
            upperNote1 = createNote2(bassNote.tpc + 4, bassNote.pitch + 4);
            upperNote2 = createNote2(bassNote.tpc + 1, bassNote.pitch + 7);
            upperNote3 = createNote2(bassNote.tpc - 2, bassNote.pitch - 2);
          } else if (choice == 17) {
            // mm
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc + 1, bassNote.pitch + 7);
            upperNote3 = createNote2(bassNote.tpc - 2, bassNote.pitch - 2);
          } else if (choice == 18) {
            // half dim
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc - 6, bassNote.pitch + 6);
            upperNote3 = createNote2(bassNote.tpc - 2, bassNote.pitch - 2);
          } else if (choice == 19) {
            // dim7
            upperNote1 = createNote2(bassNote.tpc - 3, bassNote.pitch + 3);
            upperNote2 = createNote2(bassNote.tpc - 6, bassNote.pitch + 6);
            upperNote3 = createNote2(bassNote.tpc - 9, bassNote.pitch - 3);
          }
          chord.add(bassNote);
          chord.add(upperNote1); //add notes to the chord
          chord.add(upperNote2); //add notes to the chord
          chord.add(upperNote3); //add notes to the chord
          var notes = chord.notes;
          chord.remove(notes[0]);
        }
        cursor.next();
      }
      score.doLayout();score.endCmd();Qt.quit();
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
