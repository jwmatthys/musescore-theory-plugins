import QtQuick 2.1
import QtQuick.Dialogs 1.0
import QtQuick.Controls 1.0
import MuseScore 1.0

MuseScore {
  menuPath: "Plugins.DialogTest"
  version: "0.1"
  description: qsTr("This plugin is a test for adding system text to an existing score with a dialog or dock.")
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

  Button {
    id: buttonGo
    text: qsTr("Go")
    anchors.top: window.top
    anchors.bottom: window.bottom
    anchors.left: window.left
    anchors.right: window.right
    anchors.topMargin: 10
    anchors.bottomMargin: 10
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    onClicked: {
      addText();
    }
  }

  function addText() {
    var cursor = curScore.newCursor();
    cursor.rewind(0);
    var myText = newElement(Element.STAFF_TEXT);
    myText.text = "hello";
    cursor.add(myText);
    cursor.next();
    console.log("finished.");
    Qt.quit();
  }
}
