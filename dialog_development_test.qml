import QtQuick 2.1
import QtQuick.Dialogs 1.0
import QtQuick.Controls 1.0
import MuseScore 1.0

MuseScore {
  menuPath: "Plugins.DialogTest"
  version: "0.1"
  description: qsTr("This plugin is a test for applying input from a dialog box to an existing score.")
  property
  var inputText: "hi"
  pluginType: "dialog"
  id: window
  width: 250
  height: 120
  onRun: {
    if (typeof curScore == 'undefined' || curScore == null) {
      console.log("no score found");
      Qt.quit();
    }
}
          
  Label {
    id: textLabel
    wrapMode: Text.WordWrap
    text: qsTr("Enter your staff text.")
    font.pointSize: 12
    anchors.left: window.left
    anchors.top: window.top
    anchors.leftMargin: 10
    anchors.topMargin: 10
  }

ComboBox {
    id: inputText
    anchors.top: textLabel.bottom
    anchors.left: window.left
    anchors.right: window.right
    anchors.bottom: buttonOpenFile.top
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    model: [ "First", "Second", "Third", "Fourth" ]
}

  Button {
    id: buttonOpenFile
    text: qsTr("Go")
    anchors.bottom: window.bottom
    anchors.left: inputText.left
    anchors.right: buttonCancel.left
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    onClicked: {
      processScore();
      Qt.quit();
    }
  }

  Button {
    id: buttonCancel
    text: qsTr("Cancel")
    anchors.bottom: window.bottom
    anchors.right: window.right
    anchors.left: buttonOpenFile.right
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    onClicked: {
      Qt.quit();
    }
  }

  function processScore() {
    var cursor = curScore.newCursor();
    cursor.rewind(0);
    var segment = cursor.segment;
    var testText = inputText.currentText;
    while (segment) {
        var topElem = segment.elementAt(0);
        if (topElem && topElem.type == Element.CHORD) {
          var text = newElement(Element.STAFF_TEXT);
          text.text = testText;
          cursor.add(text);
          cursor.next();
      }
      segment = segment.next;
    }
    console.log("finished.");
    curScore.endCmd(); //Qt.quit();
  }
}
