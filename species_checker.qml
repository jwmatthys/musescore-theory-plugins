import QtQuick 2.2
import QtQuick.Dialogs 1.1
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import MuseScore 1.0

MuseScore {
  menuPath: "Plugins.Proof Reading.Species Counterpoint Checker"
  description: "This plugin will check for errors in strict tonal or modal species counterpoint"
  version: "0.7"
  pluginType: "dialog"

  id: window
  width: 500;height: 570;

  MessageDialog {
    id: errorDetails
    title: "Counterpoint Proof Reading Messages"
    text: ""
    onAccepted: {
      Qt.quit();
    }
    visible: false;
  }

  Text {
    id: speciesComboBoxText
    text: "Select species:"
    anchors.top: window.top
    anchors.left: window.left;
    anchors.topMargin: 10
    anchors.bottomMargin: 15
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  ComboBox {
    id: speciesComboBox
    width: 80
    model: ['First', 'Second', 'Third', 'Fourth', 'Fifth']
    anchors.top: window.top
    anchors.left: speciesComboBoxText.right;
    anchors.topMargin: 10
    anchors.bottomMargin: 15
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    onCurrentIndexChanged: {
      switch (speciesComboBox.currentIndex + 1) {
        case 1:
          forbid_All_Dissonance_checkbox.checked = true;
          forbid_Offbeats_checkbox.checked = true;
          forbid_Dissonant_Downbeats_checkbox.checked = true;
          forbid_Repeated_Note_Over_Barline_checkbox.checked = false;
          forbid_Leap_From_Dissonance_checkbox.checked = false; // no need to check
          forbid_Leap_To_Dissonance_checkbox.checked = false; // no need to check
          allow_Passing_Tone_checkbox.checked = false;
          allow_Neighbor_Tone_checkbox.checked = false;
          allow_Appoggiatura_checkbox.checked = false;
          allow_Appoggiatura_Down_checkbox.checked = false;
          allow_Suspension_checkbox.checked = false;
          allow_Retardation_checkbox.checked = false;
          allow_Nota_Cambiata_checkbox.checked = false;
          allow_Double_Neighbor_checkbox.checked = false;
          allow_Escape_Tone_checkbox.checked = false;
          break;
        case 2:
          forbid_Dissonant_Downbeats_checkbox.checked = true;
          forbid_Repeated_Note_Over_Barline_checkbox.checked = true;
          allow_Passing_Tone_checkbox.checked = true;
          forbid_All_Dissonance_checkbox.checked = false;
          forbid_Offbeats_checkbox.checked = false;
          forbid_Leap_From_Dissonance_checkbox.checked = true;
          forbid_Leap_To_Dissonance_checkbox.checked = true;
          allow_Neighbor_Tone_checkbox.checked = false;
          allow_Appoggiatura_checkbox.checked = false;
          allow_Appoggiatura_Down_checkbox.checked = false;
          allow_Suspension_checkbox.checked = false;
          allow_Retardation_checkbox.checked = false;
          allow_Nota_Cambiata_checkbox.checked = false;
          allow_Double_Neighbor_checkbox.checked = false;
          allow_Escape_Tone_checkbox.checked = false;
          break;
        case 3:
          forbid_Dissonant_Downbeats_checkbox.checked = true;
          forbid_Repeated_Note_Over_Barline_checkbox.checked = true;
          forbid_Leap_From_Dissonance_checkbox.checked = true;
          forbid_Leap_To_Dissonance_checkbox.checked = true;
          allow_Passing_Tone_checkbox.checked = true;
          allow_Neighbor_Tone_checkbox.checked = true;
          allow_Nota_Cambiata_checkbox.checked = true;
          allow_Double_Neighbor_checkbox.checked = true;
          forbid_All_Dissonance_checkbox.checked = false;
          forbid_Offbeats_checkbox.checked = false;
          allow_Appoggiatura_checkbox.checked = false;
          allow_Appoggiatura_Down_checkbox.checked = false;
          allow_Suspension_checkbox.checked = false;
          allow_Retardation_checkbox.checked = false;
          allow_Escape_Tone_checkbox.checked = false;
          break;
        case 4:
          allow_Passing_Tone_checkbox.checked = true;
          allow_Neighbor_Tone_checkbox.checked = true;
          allow_Appoggiatura_checkbox.checked = true;
          allow_Appoggiatura_Down_checkbox.checked = true;
          allow_Suspension_checkbox.checked = true;
          allow_Retardation_checkbox.checked = true;
          allow_Nota_Cambiata_checkbox.checked = false;
          allow_Double_Neighbor_checkbox.checked = false;
          forbid_All_Dissonance_checkbox.checked = false;
          forbid_Offbeats_checkbox.checked = false;
          forbid_Dissonant_Downbeats_checkbox.checked = false;
          forbid_Leap_From_Dissonance_checkbox.checked = true;
          forbid_Leap_To_Dissonance_checkbox.checked = true;
          forbid_Repeated_Note_Over_Barline_checkbox.checked = false;
          allow_Escape_Tone_checkbox.checked = false;
          break;
        default: // fifth species
          forbid_All_Dissonance_checkbox.checked = false;
          forbid_Offbeats_checkbox.checked = false;
          forbid_Dissonant_Downbeats_checkbox.checked = false;
          forbid_Repeated_Note_Over_Barline_checkbox.checked = false;
          forbid_Repeated_Offbeats_checkbox.checked = false;
          forbid_Leap_From_Dissonance_checkbox.checked = true;
          forbid_Leap_To_Dissonance_checkbox.checked = true;
          allow_Passing_Tone_checkbox.checked = true;
          allow_Neighbor_Tone_checkbox.checked = true;
          allow_Appoggiatura_checkbox.checked = true;
          allow_Appoggiatura_Down_checkbox.checked = true;
          allow_Suspension_checkbox.checked = true;
          allow_Retardation_checkbox.checked = true;
          allow_Nota_Cambiata_checkbox.checked = true;
          allow_Double_Neighbor_checkbox.checked = true;
          allow_Escape_Tone_checkbox.checked = true;
          break;
      }
    }
  }

  Text {
    id: modeComboBoxText
    text: "Select mode:"
    anchors.top: window.top
    anchors.left: speciesComboBox.right;
    anchors.topMargin: 10
    anchors.bottomMargin: 15
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  ComboBox {
    id: modeComboBox
    width: 120
    model: ['Tonal Major', 'Tonal Minor', 'Modal']
    anchors.top: window.top
    anchors.left: modeComboBoxText.right
    anchors.topMargin: 10
    anchors.bottomMargin: 15
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    onCurrentIndexChanged: {
      switch (modeComboBox.currentIndex) {
        case 0: // tonal major
          forbid_Doubled_LT_checkbox.checked = true;
          require_Perfect_First_And_Last_checkbox.checked = false;
          require_Ti_Do_Resolution_On_V_I_checkbox.checked = true;
          require_Fa_Mi_Resolution_On_V7_I_checkbox.checked = true;
          allow_Raised_La_Ti_Minor_checkbox.checked = false;
          break;
        case 1: // tonal minor
          forbid_Doubled_LT_checkbox.checked = true;
          require_Perfect_First_And_Last_checkbox.checked = false;
          require_Ti_Do_Resolution_On_V_I_checkbox.checked = true;
          require_Fa_Mi_Resolution_On_V7_I_checkbox.checked = true;
          allow_Raised_La_Ti_Minor_checkbox.checked = true;
          break;
        default: // modal
          forbid_Accidentals_checkbox.checked = false;
          forbid_Doubled_LT_checkbox.checked = false;
          require_Perfect_First_And_Last_checkbox.checked = true;
          require_Ti_Do_Resolution_On_V_I_checkbox.checked = false;
          require_Fa_Mi_Resolution_On_V7_I_checkbox.checked = false;
          allow_Raised_La_Ti_Minor_checkbox.checked = false;
          break;
      }
    }
  }

  CheckBox {
    id: show_Intervals_checkbox
    text: "Show intervals"
    checked: true
    anchors.top: speciesComboBoxText.bottom
    anchors.left: window.left
    anchors.topMargin: 30
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Voice_Crossing_checkbox
    text: "Forbid voice crossing"
    checked: true
    anchors.top: speciesComboBoxText.bottom
    anchors.right: window.right
    anchors.topMargin: 30
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_All_Dissonance_checkbox
    text: "Forbid all dissonance"
    checked: false
    anchors.top: forbid_Voice_Crossing_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: allow_Passing_Tone_checkbox
    text: "Allow passing tone"
    checked: false
    anchors.top: forbid_All_Dissonance_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Offbeats_checkbox
    text: "Forbid offbeats"
    checked: false
    anchors.top: forbid_All_Dissonance_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: allow_Neighbor_Tone_checkbox
    text: "Allow neighbor tone"
    checked: false
    anchors.top: allow_Passing_Tone_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Dissonant_Downbeats_checkbox
    text: "Forbid dissonant downbeats"
    checked: false
    anchors.top: allow_Passing_Tone_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: allow_Appoggiatura_checkbox
    text: "Allow upward appoggiatura"
    checked: false
    anchors.top: allow_Neighbor_Tone_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Accidentals_checkbox
    text: "Forbid all accidentals"
    checked: false
    anchors.top: allow_Neighbor_Tone_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: allow_Appoggiatura_Down_checkbox
    text: "Allow downward appoggiatura"
    checked: false
    anchors.top: allow_Appoggiatura_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Consecutive_Parallels_checkbox
    text: "Forbid consecutive P5/P8"
    checked: true
    anchors.top: allow_Appoggiatura_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: allow_Suspension_checkbox
    text: "Allow suspension"
    checked: false
    anchors.top: allow_Appoggiatura_Down_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Consecutive_Downbeat_Parallels_checkbox
    text: "Forbid all accidentals"
    checked: true
    anchors.top: allow_Appoggiatura_Down_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: allow_Retardation_checkbox
    text: "Allow retardation"
    checked: false
    anchors.top: allow_Suspension_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Direct_Fifths_checkbox
    text: "Forbid direct fifths"
    checked: true
    anchors.top: allow_Suspension_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: allow_Nota_Cambiata_checkbox
    text: "Allow nota cambiata"
    checked: false
    anchors.top: allow_Retardation_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Hidden_Parallels_checkbox
    text: "Forbid hidden parallels"
    checked: true
    anchors.top: allow_Retardation_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: allow_Double_Neighbor_checkbox
    text: "Allow double neighbor"
    checked: false
    anchors.top: allow_Nota_Cambiata_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Leap_To_Perfect_in_Similar_Motion_checkbox
    text: "Forbid leap to Perfect in sim. motion"
    checked: true
    anchors.top: allow_Nota_Cambiata_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: allow_Escape_Tone_checkbox
    text: "Allow escape tone"
    checked: false
    anchors.top: allow_Double_Neighbor_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Leap_From_Dissonance_checkbox
    text: "Forbid leap from dissonance"
    checked: true
    anchors.top: allow_Double_Neighbor_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Leap_To_Dissonance_checkbox
    text: "Forbid leap to dissonance"
    checked: true
    anchors.top: allow_Escape_Tone_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: require_Perfect_First_And_Last_checkbox
    text: "Require perfect beginning & end"
    checked: false
    anchors.top: forbid_Leap_To_Dissonance_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Melodic_Aug_Or_Dim_checkbox
    text: "Forbid melodic aug or dim"
    checked: true
    anchors.top: forbid_Leap_To_Dissonance_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: require_Step_Back_After_Leap_checkbox
    text: "Require step back after leap"
    checked: true
    anchors.top: require_Perfect_First_And_Last_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Melodic_Seventh_checkbox
    text: "Forbid melodic seventh"
    checked: false
    anchors.top: require_Perfect_First_And_Last_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: require_Ti_Do_Resolution_On_V_I_checkbox
    text: "Require ti-do resolution on V-I"
    checked: false
    anchors.top: require_Step_Back_After_Leap_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Doubled_LT_checkbox
    text: "Forbid doubled LT"
    checked: false
    anchors.top: require_Step_Back_After_Leap_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: require_Fa_Mi_Resolution_On_V7_I_checkbox
    text: "Require fa-mi resolution on V7-I"
    checked: false
    anchors.top: require_Ti_Do_Resolution_On_V_I_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Repeated_Offbeats_checkbox
    text: "Forbid repeated offbeats"
    checked: true
    anchors.top: require_Ti_Do_Resolution_On_V_I_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Repeated_Note_Over_Barline_checkbox
    text: "Forbid repeated note over barline"
    checked: false
    anchors.top: require_Fa_Mi_Resolution_On_V7_I_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: allow_Raised_La_Ti_Minor_checkbox
    text: "Allow raised 6-7 in minor"
    checked: false
    anchors.top: forbid_Repeated_Note_Over_Barline_checkbox.bottom
    anchors.left: window.left
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }

  CheckBox {
    id: forbid_Unison_On_Downbeat_checkbox
    text: "Forbid mid-phrase downbeat unison"
    checked: true
    anchors.top: forbid_Repeated_Note_Over_Barline_checkbox.bottom
    anchors.right: window.right
    anchors.topMargin: 5
    anchors.bottomMargin: 5
    anchors.leftMargin: 10
    anchors.rightMargin: 10
  }


  //----------------------------------------------------------------------------

  Button {
    id: buttonCheckCounterpoint
    text: "Check Counterpoint"
    anchors.bottom: window.bottom
    anchors.right: window.right
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    onClicked: {
      goSpecies();
      curScore.doLayout();
      curScore.endCmd();
      //window.visible = false;
      errorDetails.visible = true;
    }
  }

  Button {
    id: buttonCancel
    text: "Cancel"
    anchors.bottom: window.bottom
    anchors.right: buttonCheckCounterpoint.left
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    onClicked: {
      Qt.quit();
    }
  }

  onRun: {}

  property
  var mode: "Major";
  property
  var counterpointRestrictions: Object.freeze({
    Max_Perfect: 30, // percent; warn if too many perfect intervals - DONE
    Max_Leaps: 50, // percent; warn if too many leaps - DONE
    Max_Consecutive_36: 4, // maximum number of consecutive 3rds or 6ths - DONE
    Max_Consecutive_Leaps: 4, // DONE
    Min_Std_Dev: 1 // experimental: measure of how much melody - DONE, but what is the threshold??
  });

  property
  var errorMessage: Object.freeze({
    Forbid_Dissonant_Downbeats: "dis",
    Forbid_All_Dissonance: "dis",
    Forbid_Voice_Crossing: "X",
    Forbid_Accidentals: "acc",
    Require_Perfect_First_And_Last: "~P", // generally false for tonal, true for modal
    Forbid_Consecutive_Perfect_Parallels: "||",
    Forbid_Consecutive_Downbeat_Parallels: "||",
    Forbid_Direct_Fifths: "dir", // refers specifically to P5-d5 or d5-P5
    Forbid_Hidden_Parallels: "hid", // Consecutive parallel P5 or P8 moving in opposite direction
    Forbid_Leap_To_Perfect_in_Similar_Motion: "ltp", // melody leaps to a perfect interval in similar motion
    Forbid_Leap_From_Dissonance: "lfd", // a general truism
    Forbid_Leap_To_Dissonance: "ltd", // (only exception is appoggiatura)
    Forbid_Melodic_Aug_Or_Dim: "->",
    Forbid_Melodic_Seventh: "mel7",
    Forbid_Offbeats: "x", // no offbeats, ie first species
    Forbid_Doubled_LT: "2xlt",
    Check_For_Raised_LT_On_V_I: "lt!",
    Check_For_Ti_Do_Resolution_On_V_I: "lt",
    Check_For_Fa_Mi_Resolution_On_V7_I: "7th",
    Forbid_Repeated_Note_Over_Barline: "rep", // strict species forbids this in spec 2 & 3 but not 4
    Forbid_Repeated_Offbeats: "rep", // This is usually true
    Forbid_Unison_On_Downbeat: "~1", // Prohibits harmonic unison except beginning and end and offbeats
    Allow_Passing_Tone: "PT",
    Allow_Neighbor_Tone: "NT",
    Allow_Appoggiatura: "APP",
    Allow_Downward_Appoggiatura: "APP",
    Allow_Suspension: "SUS",
    Allow_Retardation: "RET",
    Allow_Accented_Passing_Tone: "APT", // for species 4
    Allow_Accented_Neighbor: "AN", // for species 4
    Allow_Nota_Cambiata: "NC",
    Allow_Double_Neighbor: "DN", // the more general version of nota combiata that can move up or down
    Allow_Escape_Tone: "ET", // an exception to Forbid_Leap_From_Dissonance
    Check_For_Step_Back_After_Leap: "sb", // warns if leap of 6th or octave doesn't step back the opposite direction
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
    MODAL: [8, 6, 5, 3, 1],
    ROOT: [8, 5, 3, 1],
    FIRSTINV: [8, 6, 3, 1],
    SECONDINV: [8, 6, 4, 1],
    ROOT7: [8, 7, 5, 3, 1],
    FIRSTINV7: [8, 6, 5, 3, 1],
    SECONDINV7: [8, 6, 4, 3, 1],
    THIRDINV7: [8, 6, 4, 2, 1]
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
        if (tic == 0 && Math.abs(this.note1.pitch - this.note2.pitch) > 2) tic = 7;
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
        if (this.size == 8 || this.size == 1) {
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

    this.checkRaisedLT = function(note) {
      if (note) {
        return (5 == note.tpc - key);
      }
    }

    this.checkRaised6or7inMinor = function(note) {
      var result = false;
      if (note) {
        var circleDiff = note.tpc - key;
        if (3 == circleDiff) result = true;
        if (5 == circleDiff) result = true;
      }
      return result;
    }

    this.topNote = this.getNote(this.segment.elementAt(0));
    this.botNote = this.getNote(this.segment.elementAt(4));
    this.newTop = false;
    this.isDownbeat = false;
    this.prevTop = null; //type ELEMENT.CHORD
    this.prevBot = null; //type ELEMENT.CHORD
    this.previousFiguredBass = null; //type Element.FIGURED_BASS
    this.interval = null;
    this.nct = null; //type bool
    this.isRaised6or7 = this.checkRaised6or7inMinor(this.topNote);
    this.isRaisedLT = this.checkRaisedLT(this.topNote);
    this.errorYpos = 0; // type int
    this.measure = measure; // type int

    this.getRoman = function() {
      var sArray = new Array();
      for (var i = 4; i < 6; i++) {
        if (this.segment.elementAt(i) && this.segment.elementAt(i).lyrics) {
          console.log("found lyrics in layer " + i);
          var lyrics = this.segment.elementAt(i).lyrics;
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
      console.log("lyric: " + sArray.toString())
      return sArray.toString();
    }

    this.processFiguredBass = function() {
      if (2 == modeComboBox.currentIndex) {
        this.consonances = inversion.MODAL;
        return;
      }
      var cleanedFBtext = "";
      if (!this.botNote) {
        this.figuredBass = this.previousFiguredBass;
        this.consonances = this.previousConsonances;
      } else {
        cleanedFBtext = this.getRoman().replace(/[^234567\&\^\$]/g, '');
        cleanedFBtext = cleanedFBtext.replace(/[\&]/g, '7'); // Sicilian numerals font uses these characters for superscript
        cleanedFBtext = cleanedFBtext.replace(/[\^]/g, '6');
        cleanedFBtext = cleanedFBtext.replace(/[\$]/g, '4');
        console.log("cleanedFBtext: " + cleanedFBtext);
        if (this.segment.annotations[0] && this.segment.annotations[0].type == Element.FIGURED_BASS) {
          cleanedFBtext = this.segment.annotations[0].text.replace(/[^234567]/g, '');
          console.log("FB replaced with " + cleanedFBtext);
        }
        this.consonances = inversion.ROOT;
        if (cleanedFBtext == "6" || cleanedFBtext == "63") this.consonances = inversion.FIRSTINV;
        if (cleanedFBtext == "64") this.consonances = inversion.SECONDINV;
        if (cleanedFBtext == "7" || cleanedFBtext == "753") this.consonances = inversion.ROOT7
        if (cleanedFBtext == "65" || cleanedFBtext == "653") this.consonances = inversion.FIRSTINV7;
        if (cleanedFBtext == "43" || cleanedFBtext == "643") this.consonances = inversion.SECONDINV7;
        if (cleanedFBtext == "42" || cleanedFBtext == "642") this.consonances = inversion.THIRDINV7;
      }
    }

    this.processInterval = function() {
      // If no new note is articulated, carry over pitch from before
      if (this.topNote) this.newTop = true;
      else {
        this.topNote = this.prevTop; // top note tied over
        if (this.topNote) this.newTop = false;
      }
      if (this.botNote) this.isDownbeat = true;
      else {
        this.botNote = this.prevBot; // bottom note still sounding
        if (this.botNote) this.isDownbeat = false;
      }
      this.interval = new cInterval(this.topNote, this.botNote, key);
      //console.log("size: " + this.interval.size);
      this.nct = (this.consonances.indexOf(this.interval.size) == -1);
      //console.log("interval: " + this.interval.toString() + " = NCT? " + this.nct);
    }

    this.isDissonant = function() {
      if (this.permittedDissonance) return false;
      if (this.nct) return true;
      if (mode == "Modal") {
        if (this.interval.quality == intervalQual.DIM) return true;
        if (this.interval.quality == intervalQual.AUGMENTED) return true;
      }
      if (this.interval.quality == intervalQual.OTHER) return true;
      return false;
    }

    this.voiceCross = function() {
      return (this.topNote.pitch < this.botNote.pitch);
    }

    this.isVchord = function() {
      if (this.botNote) {
        if (this.botNote.sd == 5 &&
          (this.consonances == inversion.ROOT || this.consonances == inversion.ROOT7)) return true;
        if (this.botNote.sd == 7 &&
          (this.consonances == inversion.FIRSTINV || this.consonances == inversion.FIRSTINV7)) return true;
        if (this.botNote.sd == 2 &&
          (this.consonances == inversion.SECONDINV || this.consonances == inversion.SECONDINV7)) return true;
        if (this.botNote.sd == 4 &&
          (this.consonances == inversion.THIRDINV || this.consonances == inversion.THIRDINV7)) return true;
      }
      return false;
    }

    this.isIchord = function() {
      if (this.botNote) {
        if (this.botNote.sd == 1 && this.consonances == inversion.ROOT) return true;
        if (this.botNote.sd == 3 && this.consonances == inversion.FIRSTINV) return true;
        if (this.botNote.sd == 5 && this.consonances == inversion.SECONDINV) return true;
      }
      return false;
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
    if (int1.size == 5 || int1.size == 6 || int1.size == 8) {
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

  function goSpecies() {
    errorDetails.text = modeComboBox.textAt(modeComboBox.currentIndex) + " " + speciesComboBox.textAt(speciesComboBox.currentIndex) + " Species:\n";

    if (typeof curScore == 'undefined' || curScore == null) {
      console.log("no score found");
      Qt.quit();
    }
    curScore.startCmd();
    var dyads = [];
    var prevDownbeat = 0;
    var measure = 1;
    var cursor = curScore.newCursor();
    var endTick;
    var fullScore = false;
    cursor.rewind(1);
    if (!cursor.segment) { // no selection
      fullScore = true;
    } else {
      cursor.rewind(2);
      if (cursor.tick === 0) {
        // this happens when the selection includes
        // the last measure of the score.
        // rewind(2) goes behind the last segment (where
        // there's none) and sets tick=0
        endTick = curScore.lastSegment.tick + 1;
      } else {
        endTick = cursor.tick;
      }
    }

    cursor.rewind(1);
    key = cursor.keySignature + 14;
    if (1 == modeComboBox.currentIndex) key += 3;
    var segment = cursor.segment;

    // Process all dyads and mark intervals
    for (var index = 0; (segment && (fullScore || cursor.tick < endTick));) {
      //while (segment) {
      var topElem = segment.elementAt(0);
      var botElem = segment.elementAt(4);

      if ((topElem && topElem.type == Element.CHORD) || (botElem && botElem.type == Element.CHORD)) {
        dyads[index] = new cDyad(segment, measure); // This is where the magic happens...
        if (index > 0) {
          dyads[index].prevTop = dyads[index - 1].topNote;
          dyads[index].prevBot = dyads[index - 1].botNote;
          dyads[index].previousFiguredBass = dyads[index - 1].figuredBass;
          dyads[index].previousConsonances = dyads[index - 1].consonances;
        }
        dyads[index].processFiguredBass();
        dyads[index].processInterval();
        // Label intervals
        if (show_Intervals_checkbox.checked) {
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

    cursor.rewind(1);
    var lastConsonance = null;
    var lastDownbeat = null;

    for (var index = 0; index < dyads.length; index++) {
      // Here come the verticality error checks!
      var error = new counterpointError(cursor, dyads[index]);

      if (require_Perfect_First_And_Last_checkbox.checked) {
        if (index == 0 && dyads[index].topNote && !dyads[index].interval.isPerfect()) {
          error.annotate(errorMessage.Require_Perfect_First_And_Last, colorError);
          errorDetails.text += "Measure " + dyads[index].measure + ": Must begin on perfect consonance\n";
        } else if (index == 1 && !dyads[0].topNote && !dyads[index].interval.isPerfect()) { // if it starts with rest
          error.annotate(errorMessage.Require_Perfect_First_And_Last, colorError);
          errorDetails.text += "Measure " + dyads[index].measure + ": Must begin on perfect consonance\n";
        } else if (index == dyads.length - 1 && !dyads[index].interval.isPerfect()) {
          error.annotate(errorMessage.Require_Perfect_First_And_Last, colorError);
          errorDetails.text += "Measure " + dyads[index].measure + ": Must end on perfect consonance\n";
        }
      }

      if (forbid_Unison_On_Downbeat_checkbox.checked) {
        if (dyads[index].interval.size == 1 && dyads[index].isDownbeat &&
          index < dyads.length - 1 && index > 0) {
          error.annotate(errorMessage.Forbid_Unison_On_Downbeat, colorError);
          errorDetails.text += "Measure " + dyads[index].measure + ": P1 may only occur at the start, end, or offbeat\n";
        }
      }

      if (dyads[index].topNote && dyads[index].botNote) {
        if (forbid_Offbeats_checkbox.checked) {
          if (!dyads[index].isDownbeat) {
            error.annotate(errorMessage.Forbid_Offbeats, colorError);
            errorDetails.text += "Measure " + dyads[index].measure + ": First species allows only one melody note per bass note\n";
          }
        }

        if (index > 0 && index < (dyads.length - 1)) // Let's go after those triples (PT, NT, app, ret, sus, apt)
        {
          if (allow_Passing_Tone_checkbox.checked) {
            if (dyads[index].nct && dyads[index].botNote && !dyads[index].isDownbeat) {
              if (isPassing(dyads[index - 1].topNote, dyads[index].topNote, dyads[index + 1].topNote)) {
                error.annotate(errorMessage.Allow_Passing_Tone, colorCT);
                dyads[index].permittedDissonance = true;
              }
            }
          }

          if (allow_Passing_Tone_checkbox.checked && !forbid_Dissonant_Downbeats_checkbox.checked) {
            if (dyads[index].nct && dyads[index].botNote && dyads[index].isDownbeat) {
              if (isPassing(dyads[index - 1].topNote, dyads[index].topNote, dyads[index + 1].topNote)) {
                error.annotate(errorMessage.Allow_Accented_Passing_Tone, colorCT);
                dyads[index].permittedDissonance = true;
              }
            }
          }

          if (allow_Neighbor_Tone_checkbox.checked) {
            if (dyads[index].nct && dyads[index].botNote && !dyads[index].isDownbeat) {
              if (isNeighbor(dyads[index - 1].topNote, dyads[index].topNote, dyads[index + 1].topNote)) {
                error.annotate(errorMessage.Allow_Neighbor_Tone, colorCT);
                dyads[index].permittedDissonance = true;
              }
            }
          }

          if (allow_Neighbor_Tone_checkbox.checked && !forbid_Dissonant_Downbeats_checkbox.checked) {
            if (dyads[index].nct && dyads[index].botNote && dyads[index].isDownbeat) {
              if (isNeighbor(dyads[index - 1].topNote, dyads[index].topNote, dyads[index + 1].topNote)) {
                error.annotate(errorMessage.Allow_Accented_Neighbor, colorCT);
                dyads[index].permittedDissonance = true;
              }
            }
          }

          if (allow_Nota_Cambiata_checkbox.checked && index > 0 && index < dyads.length - 3) {
            var int1 = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
            var int2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
            var int3 = new cInterval(dyads[index + 1].topNote, dyads[index + 2].topNote);
            if (int1.direction == -1 && int2.direction == -1 && int3.direction == 1 &&
              dyads[index - 1].isDownbeat && !dyads[index].isDownbeat && !dyads[index + 1].isDownbeat && !dyads[index + 2].isDownbeat &&
              ((dyads[index - 1].interval.size == 8 && dyads[index].interval.size == 7 &&
                  dyads[index + 1].interval.size == 5 && dyads[index + 2].interval.size == 6) ||
                (dyads[index - 1].interval.size == 6 && dyads[index].interval.size == 5 &&
                  dyads[index + 1].interval.size == 3 && dyads[index + 2].interval.size == 4))) {
              error.annotate(errorMessage.Allow_Nota_Cambiata, colorCT);
              dyads[index].permittedDissonance = true;
              dyads[index + 1].permittedDissonance = true;
              dyads[index + 2].permittedDissonance = true;
            }
          }

          if (allow_Double_Neighbor_checkbox.checked && index > 0 && index < dyads.length - 4) {
            var int1 = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
            var int2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
            var int3 = new cInterval(dyads[index + 1].topNote, dyads[index + 2].topNote);
            var int4 = new cInterval(dyads[index + 2].topNote, dyads[index + 3].topNote);
            var dir1 = int1.direction;
            if (dir1 != 0 && int1.direction == dir1 && int2.direction == dir1 * -1 && int3.direction == dir1 && int4.direction == dir1 &&
              dyads[index - 1].isDownbeat && !dyads[index].isDownbeat && !dyads[index + 1].isDownbeat && !dyads[index + 2].isDownbeat && dyads[index + 3].isDownbeat &&
              int1.size == 2 && int2.size == 3 && int3.size == 2 && int4.size == 2 &&
              !dyads[index - 1].nct && !dyads[index + 3].nct) {
              error.annotate(errorMessage.Allow_Double_Neighbor, colorCT);
              dyads[index].permittedDissonance = true;
              dyads[index + 1].permittedDissonance = true;
              dyads[index + 2].permittedDissonance = true;
            }
          }

          if (allow_Suspension_checkbox.checked && index > 0 && index < dyads.length - 2) {
            var melodicInterval2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
            if (dyads[index - 1].topNote && dyads[index].topNote && dyads[index + 1].topNote &&
              !dyads[index - 1].nct && !dyads[index + 1].nct && dyads[index].isDownbeat &&
              dyads[index - 1].topNote.pitch == dyads[index].topNote.pitch && melodicInterval2.size == 2 &&
              melodicInterval2.direction < 0) {
              error.annotate(errorMessage.Allow_Suspension, colorCT);
              dyads[index].permittedDissonance = true;
            }
          }

          if (allow_Retardation_checkbox.checked && index > 0 && index < dyads.length - 2) {
            var melodicInterval2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
            if (dyads[index - 1].topNote && dyads[index].topNote && dyads[index + 1].topNote &&
              !dyads[index - 1].nct && !dyads[index + 1].nct && dyads[index].isDownbeat &&
              dyads[index - 1].topNote.pitch == dyads[index].topNote.pitch && melodicInterval2.size == 2 &&
              melodicInterval2.direction > 0 && melodicInterval2.quality == intervalQual.MINOR) {
              error.annotate(errorMessage.Allow_Retardation, colorCT);
              dyads[index].permittedDissonance = true;
            }
          }

          if (index > 0 && index < (dyads.length - 2) && allow_Appoggiatura_checkbox.checked) {
            var melodicInterval = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
            var melodicInterval2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
            if (melodicInterval.direction > 0 && melodicInterval.size > 2 && dyads[index].isDownbeat && dyads[index].nct &&
              melodicInterval2.direction < 0 && melodicInterval2.size == 2 && !dyads[index + 1].nct) {
              error.annotate(errorMessage.Allow_Appoggiatura, colorCT);
              dyads[index].permittedDissonance = true;
            }
          }

          if (index > 0 && index < (dyads.length - 2) && allow_Appoggiatura_Down_checkbox.checked) {
            var melodicInterval = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
            var melodicInterval2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
            if (melodicInterval.direction < 0 && melodicInterval.size > 2 && !dyads[index + 1].nct && dyads[index].isDownbeat &&
              melodicInterval2.direction > 0 && melodicInterval2.size == 2 && melodicInterval2.quality == intervalQual.MINOR) {
              error.annotate(errorMessage.Allow_Downward_Appoggiatura, colorCT);
              dyads[index].permittedDissonance = true;
            }
          }

          if (index > 0 && index < (dyads.length - 2) && allow_Escape_Tone_checkbox.checked) {
            var melodicInterval = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
            var melodicInterval2 = new cInterval(dyads[index].topNote, dyads[index + 1].topNote);
            if (melodicInterval.size == 2 && !!dyads[index - 1].nct && dyads[index].nct &&
              !dyads[index].isDownbeat && !dyads[index + 1].nct &&
              melodicInterval2.direction != 0 && melodicInterval.direction == -1 * melodicInterval2.direction) {
              error.annotate(errorMessage.Allow_Escape_Tone, colorCT);
              dyads[index].permittedDissonance = true;
            }
          }

          if (forbid_Dissonant_Downbeats_checkbox.checked) {
            if (dyads[index].isDownbeat && dyads[index].isDissonant()) {
              error.annotate(errorMessage.Forbid_Dissonant_Downbeats, colorError);
              errorDetails.text += "Measure " + dyads[index].measure + ": Dissonant interval " + dyads[index].interval.toString() + " over bass note change\n";
            }
          }

          if (forbid_All_Dissonance_checkbox.checked) {
            if (!dyads[index].isDownbeat && dyads[index].isDissonant()) {
              error.annotate(errorMessage.Forbid_All_Dissonance, colorError);
              errorDetails.text += "Measure " + dyads[index].measure + ": Dissonant interval " + dyads[index].interval.toString() + " off the beat\n";
            }
          }

          if (forbid_Voice_Crossing_checkbox.checked) {
            if (dyads[index].voiceCross()) {
              error.annotate(errorMessage.Forbid_Voice_Crossing, colorError);
              errorDetails.text += "Measure " + dyads[index].measure + ": Melody crosses bass\n";
            }
          }

          if (forbid_Doubled_LT_checkbox.checked) {
            if (dyads[index].topNote.sd == 7 && dyads[index].botNote.sd == 7) {
              error.annotate(errorMessage.Forbid_Doubled_LT, colorError);
              errorDetails.text += "Measure " + dyads[index].measure + ": Doubled Leading Tone\n";
            }
          }

          if (forbid_Accidentals_checkbox.checked && dyads[index].topNote.accidental) {
            if (!allow_Raised_La_Ti_Minor_checkbox.checked) {
              error.annotate(errorMessage.Forbid_Accidentals, colorError);
              errorDetails.text += "Measure " + dyads[index].measure + ": Accidentals are restricted in this species\n";
              dyads[index].topNote.accidental.color = "#ff0000";
            } else if (!dyads[index].isRaised6or7) {
              error.annotate(errorMessage.Forbid_Accidentals, colorError);
              errorDetails.text += "Measure " + dyads[index].measure + ": Only raised scale degrees 6 & 7 can be altered with accidentals in this species\n";
              dyads[index].topNote.accidental.color = "#ff0000";
            }
          }

          if (forbid_Consecutive_Downbeat_Parallels_checkbox.checked && dyads[index].isDownbeat) {
            if (lastDownbeat && lastDownbeat.interval) {
              if (dyads[index].interval.toString() == lastDownbeat.interval.toString() &&
                motion(lastDownbeat, dyads[index]) == tonalMotion.SIMILAR) {
                error.annotate(errorMessage.Forbid_Consecutive_Downbeat_Parallels + dyads[index].interval.toString(), colorError);
                errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Parallel " + dyads[index].interval.toString() + " on consecutive downbeats\n";
              }
            }
            lastDownbeat = dyads[index];
          }

          if (lastConsonance && lastConsonance.interval) {
            if (dyads[index].interval.isPerfect() && dyads[index].interval.toString() == lastConsonance.interval.toString()) {
              if (forbid_Consecutive_Parallels_checkbox.checked && motion(dyads[index], lastConsonance) == tonalMotion.SIMILAR) {
                error.annotate(errorMessage.Forbid_Consecutive_Perfect_Parallels + dyads[index].interval.toString(), colorError);
                errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Parallel " + dyads[index].interval.toString() + "\n";
              } else if (forbid_Hidden_Parallels_checkbox.checked && motion(dyads[index], lastConsonance) == tonalMotion.CONTRARY) {
                error.annotate(errorMessage.Forbid_Hidden_Parallels + dyads[index].interval.toString(), colorError);
                errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Hidden " + dyads[index].interval.toString() + "\n";
              }
            }
          }
          if (!dyads[index].nct) {
            lastConsonance = dyads[index];
          }
        }
      }


      // Now the checks of 2 consecutive notes
      if (index > 0) {
        if (forbid_Melodic_Aug_Or_Dim_checkbox.checked) {
          var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
          if (melodicInterval.quality != intervalQual.PERFECT &&
            melodicInterval.quality != intervalQual.MAJOR &&
            melodicInterval.quality != intervalQual.MINOR &&
            melodicInterval.size != null) {
            error.annotate(errorMessage.Forbid_Melodic_Aug_Or_Dim + melodicInterval.toString(), colorError);
            errorDetails.text += "Measure " + dyads[index].measure + ": Melody leaps by dissonant interval " + melodicInterval.toString() + "\n";
          }
        }
        if (forbid_Melodic_Seventh_checkbox.checked) {
          var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
          if (melodicInterval.size == 7) {
            error.annotate(errorMessage.Forbid_Melodic_Seventh, colorError);
            errorDetails.text += "Measure " + dyads[index].measure + ": Melody leaps " + melodicInterval.toString() + "\n";
          }
        }
        if (forbid_Direct_Fifths_checkbox.checked) {
          if (dyads[index].interval.size == 5 &&
            dyads[index - 1].interval.size == 5 &&
            dyads[index].interval.quality != dyads[index - 1].interval.quality &&
            motion(dyads[index], dyads[index - 1]) == tonalMotion.SIMILAR) {
            error.annotate(errorMessage.Forbid_Direct_Fifths, colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Consecutive 5ths in same direction\n";
          }
        }
        if (forbid_Leap_To_Perfect_in_Similar_Motion_checkbox.checked) {
          if (dyads[index].interval.isPerfect()) {
            var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
            if (motion(dyads[index], dyads[index - 1]) == tonalMotion.SIMILAR &&
              melodicInterval.size > 2) {
              error.annotate(errorMessage.Forbid_Leap_To_Perfect_in_Similar_Motion, colorError);
              errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Melody leaps to " + dyads[index].interval.toString() + " in similar motion\n";
            }
          }
        }

        if (forbid_Leap_From_Dissonance_checkbox.checked) {
          if (dyads[index - 1].isDissonant()) {
            var melodicInterval = new cInterval(dyads[index].topNote, dyads[index - 1].topNote);
            if (melodicInterval.size > 2) {
              error.annotate(errorMessage.Forbid_Leap_From_Dissonance, colorError);
              errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Melody leaps from NCT or dissonant interval " + dyads[index - 1].interval.toString() + "\n";
            }
          }
        }

        if (forbid_Leap_To_Dissonance_checkbox.checked) {
          if (dyads[index].isDissonant()) {
            var melodicInterval = new cInterval(dyads[index - 1].topNote, dyads[index].topNote);
            if (melodicInterval.size > 2) {
              error.annotate(errorMessage.Forbid_Leap_To_Dissonance, colorError);
              errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Melody leaps to NCT or dissonant interval " + dyads[index].interval.toString() + "\n";
            }
          }
        }

        if (forbid_Repeated_Offbeats_checkbox.checked) {
          if (dyads[index].topNote && dyads[index - 1].topNote &&
            dyads[index].botNote && !dyads[index].isDownbeat &&
            dyads[index].topNote.pitch == dyads[index - 1].topNote.pitch &&
            dyads[index].topNote.tpc == dyads[index - 1].topNote.tpc) {
            error.annotate(errorMessage.Forbid_Repeated_Offbeats, colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Offbeat melody note repeats\n";
          }
        }

        if (forbid_Repeated_Note_Over_Barline_checkbox.checked) {
          if (dyads[index].topNote && dyads[index - 1].topNote &&
            dyads[index].botNote && dyads[index].isDownbeat &&
            dyads[index].topNote.pitch == dyads[index - 1].topNote.pitch &&
            dyads[index].topNote.tpc == dyads[index - 1].topNote.tpc &&
            !dyads[index].permittedDissonance) {
            error.annotate(errorMessage.Forbid_Repeated_Note_Over_Barline, colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Melody note repeats over bass change\n";
          }
        }

        if (dyads[index - 1].isVchord() && dyads[index].isIchord()) {
          if (require_Fa_Mi_Resolution_On_V7_I_checkbox.checked && dyads[index - 1].topNote.sd == 4 && dyads[index].topNote.sd != 3) {
            error.annotate(errorMessage.Check_For_Fa_Mi_Resolution_On_V7_I, colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Seventh of V7 must resolve down by step\n";
          } else if (dyads[index - 1].topNote.sd == 7 && dyads[index].topNote.sd != 1 && dyads[index].topNote.sd != dyads[index - 1].topNote.sd) {
            error.annotate(errorMessage.Check_For_Fa_Mi_Resolution_On_V7_I, colorError);
            errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Leading tone in V-I must resolve up to tonic\n";
          }
        }

        if (require_Ti_Do_Resolution_On_V_I_checkbox.checked && index <= dyads.length - 2 &&
          dyads[index].isVchord() && dyads[index + 1].isIchord() &&
          dyads[index].topNote.sd == 7 && !dyads[index].isRaisedLT) {
          error.annotate(errorMessage.Check_For_Raised_LT_On_V_I, colorError);
          errorDetails.text = errorDetails.text + "Measure " + dyads[index].measure + ": Leading tone needs to be raised at cadence\n";
        }

        if (require_Step_Back_After_Leap_checkbox.checked && index > 1) {
          if (!stepsBackAfterBigLeap(dyads[index - 2].topNote, dyads[index - 1].topNote, dyads[index].topNote)) {
            error.annotate(errorMessage.Check_For_Step_Back_After_Leap, colorError);
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
  }
}
