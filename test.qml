import QtQuick 2.0
import MuseScore 1.0

MuseScore {
  menuPath: "Test"
  description: "Get staff text"
  version: "0.51"

  onRun: {
    console.log("starting...");
    console.log(typeof curScore);
    if (typeof curScore == 'undefined') {
      console.log("this sucks.");
      Qt.quit();
    }

    var cursor = curScore.newCursor();
    cursor.rewind(0);
    var segment = cursor.segment;
    console.log("Hey dicknose.");
    while (segment) {
      if (segment.elementAt(0)) console.log("type: \n");
      segment = segment.next;
    }
    Qt.quit();
  }
}
