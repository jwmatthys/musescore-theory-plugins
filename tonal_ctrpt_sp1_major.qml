import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 1.0

MuseScore {
  menuPath: "Plugins.Check Tonal Counterpoint.First Species"
  description: "Check for Errors in Tonal Counterpoint Writing"
  version: "0.2"
  //pluginType: "dialog"
  //width:  150
  //height: 75

  property var colorError: "#ff0000";
  property var colorPerf: "#22aa00";
  property var colorNCT: "#0000ff"

  MessageDialog {
            id: errorDetails
            title: "First Species Tonal Counterpoint Errors"
            text: ""
            onAccepted: {
                  Qt.quit();
            }
            visible: false;
      }
  
  function tonalDyad ()
  {
    var QUALITY = Object.freeze({DIM: 1, MINOR: 2, MAJOR: 3, PERFECT: 4, AUGMENTED: 5, OTHER: 6});
    var MODE = Object.freeze({MAJOR: 1, MINOR: 2, MODAL: 3});
    var CONSONANCES = Object.freeze({ROOT: [8,5,3], FIRSTINV: [8,6,3], SECONDINV: [8,6,4], ROOT7: [8,7,5,3], FIRSTINV7: [8,6,5,3], SECONDINV7: [8,6,4,3], THIRDINV7: [8,6,4,2]});
    this.botNote = null; //type Element.CHORD
    this.topNote = null; //type Element.CHORD
    this.topSD = null; // 1-7 (scale degree)
    this.botSD = null; // 1-7 (scale degree)
    this.botNew = false; //type bool
    this.topNew = false; //type bool
    this.prevTop = null; //type ELEMENT.CHORD
    this.prevBot = null; //type ELEMENT.CHORD
    this.fb = null; //type Element.FIGURED_BASS
    this.prevFB = null; //type Element.FIGURED_BASS
    this.index = 0;
    this.size = null; // 2 - 8 (interval size)
    this.quality = null;
    this.nct = null; //type bool
    this.hasAccidental = false; //type bool
    this.key = 14; //type int
    this.mode = MODE.MAJOR;
    this.errorYpos = 0; // type int
    this.consonances = CONSONANCES.ROOT;
    
    this.getFiguredBass = function (segment)
    {
      this.fb = segment.annotations[0];
      if (this.botNew) this.consonances = CONSONANCES.ROOT;
      else this.fb = this.prevFB;
      if (this.fb && this.fb.type == Element.FIGURED_BASS)
      {
        if (this.fb.text=="6" || this.fb.text=="6\n3")       this.consonances = CONSONANCES.FIRSTINV;
        if (this.fb.text=="6\n4")                            this.consonances = CONSONANCES.SECONDINV;
        if (this.fb.text=="7" || this.fb.text=="7\n5\n3")    this.consonances = CONSONANCES.ROOT7
        if (this.fb.text=="6\n5" || this.fb.text=="6\n5\n3") this.consonances = CONSONANCES.FIRSTINV7;
        if (this.fb.text=="4\n3" || this.fb.text=="6\n4\n3") this.consonances = CONSONANCES.SECONDINV7;
        if (this.fb.text=="4\n2" || this.fb.text=="6\n4\n2") this.consonances = CONSONANCES.THIRDINV7;
      }
    }

    this.getNote = function (elem)
    {
      var result = null;
      if (elem && elem.type == Element.CHORD)
      {
        var notes = elem.notes;
        if (notes.length > 1)
        {
          console.log("found chord with more than one note!");
          this.error = true;
        }
        result = notes[notes.length-1];
      }
      return result;
    }
    
    this.getScaleDegree = function (note)
    {
      var circleDiff = (21 + note.tpc - this.key) % 7;
      var sd = null;
      if (0 == circleDiff) sd = 1;
      if (2 == circleDiff) sd = 2;
      if (4 == circleDiff) sd = 3;
      if (6 == circleDiff) sd = 4;
      if (1 == circleDiff) sd = 5;
      if (3 == circleDiff) sd = 6;
      if (5 == circleDiff) sd = 7;
      return sd;
    }
    
    this.getIntervalSize = function ()
    {
      var tic = (21 + this.topSD - this.botSD) % 7;
      if (tic == 0) tic = 7;
      this.size = tic + 1;
    }
    
    this.getIntervalQuality = function ()
    {
      // There's got to be a better way... *shrug*
      var ic = Math.abs (this.topNote.pitch - this.botNote.pitch)%12;
      this.quality = QUALITY.OTHER;
      if (this.size == 8)
      {
        if (11 == ic)  this.quality = QUALITY.DIM;
        if (0 == ic)  this.quality = QUALITY.PERFECT;
        if (1 == ic)  this.quality = QUALITY.AUGMENTED;
      }
      else if (this.size == 2)
      {
        if (0 == ic)  this.quality = QUALITY.DIM;
        if (1 == ic)  this.quality = QUALITY.MINOR;
        if (2 == ic)  this.quality = QUALITY.MAJOR;
        if (3 == ic)  this.quality = QUALITY.AUGMENTED;
      }
      else if (this.size == 3)
      {
        if (2 == ic)  this.quality = QUALITY.DIM;
        if (3 == ic)  this.quality = QUALITY.MINOR;
        if (4 == ic)  this.quality = QUALITY.MAJOR;
        if (5 == ic)  this.quality = QUALITY.AUGMENTED;
      }
      else if (this.size == 4)
      {
        if (4 == ic)  this.quality = QUALITY.DIM;
        if (5 == ic)  this.quality = QUALITY.PERFECT;
        if (6 == ic)  this.quality = QUALITY.AUGMENTED;
      }
      else if (this.size == 5)
      {
        if (6 == ic)  this.quality = QUALITY.DIM;
        if (7 == ic)  this.quality = QUALITY.PERFECT;
        if (8 == ic)  this.quality = QUALITY.AUGMENTED;
      }
      else if (this.size == 6)
      {
        if (7 == ic)  this.quality = QUALITY.DIM;
        if (8 == ic)  this.quality = QUALITY.MINOR;
        if (9 == ic)  this.quality = QUALITY.MAJOR;
        if (10 == ic)  this.quality = QUALITY.AUGMENTED;
      }
      else if (this.size == 7)
      {
        if (9 == ic)  this.quality = QUALITY.DIM;
        if (10 == ic)  this.quality = QUALITY.MINOR;
        if (11 == ic)  this.quality = QUALITY.MAJOR;
        if (0 == ic)  this.quality = QUALITY.AUGMENTED;
      }
    }
    
    this.processInterval = function (segment)
    {
      this.topNote = this.getNote(segment.elementAt(0));
      this.botNote = this.getNote(segment.elementAt(4));
      
      if (this.topNote.accidental)
      {
        this.hasAccidental = true;
      }

      // If no new note is articulated, carry over pitch from before
      if (this.topNote) this.topNew = true;
         else if (this.prevTop) this.topNote = this.prevTop; // top note tied over
      if (this.botNote) this.botNew = true;
         else if (this.prevBot)
         {
           this.botNote = this.prevBot; // bottom note still sounding
         }
      this.getFiguredBass(segment);
      
      if (this.topNote && this.botNote)
      {
        this.topSD = this.getScaleDegree (this.topNote);
        this.botSD = this.getScaleDegree (this.botNote);
        this.getIntervalSize ();
        this.getIntervalQuality ();
        this.nct = (this.consonances.indexOf(this.size)==-1);
      }
    }
    
    this.getIntervalText = function ()
    {
      var text = "!?";
      if (this.size && this.quality)
      {
        if (this.quality == QUALITY.DIM) text = "d";
        else if (this.quality == QUALITY.PERFECT)   text = "P";
        else if (this.quality == QUALITY.MINOR)     text = "m";
        else if (this.quality == QUALITY.MAJOR)     text = "M";
        else if (this.quality == QUALITY.AUGMENTED) text = "+";
        text = text + this.size;
      }
      return text;
    }
    
    this.isPerfect = function ()
    {
      return (QUALITY.PERFECT == this.quality); 
    }
    
    this.isDissonant = function ()
    {
      if (QUALITY.PERFECT == this.quality) return false;
      if (QUALITY.MAJOR == this.quality) return false;
      if (QUALITY.MINOR == this.quality) return false;
      return true;
    }
  }
  
  function errorMessage (msg, xpos, note, cursor)
  {
    var text  = newElement(Element.STAFF_TEXT);
    text.pos.x = xpos;
    text.pos.y = note.errorYpos;
    text.text = msg;
    text.color = colorError;
    cursor.add(text); 
    note.errorYpos -= 2;
  }
  
  function motion (interval1, interval2)
  {
    var result;
    var topMotion = interval2.topNote.pitch - interval1.topNote.pitch; // 0 if oblique, + if ascending, - if descending
    var botMotion = interval2.botNote.pitch - interval1.botNote.pitch;
    var direction = topMotion * botMotion; // + if similar, - if contrary, 0 if oblique
    //console.log("topMotion: "+topMotion+", botMotion: "+botMotion+", direction: "+direction);
    if (direction <= 0) return -1;
    // if similar motion, check to see if stepwise motion
    if (Math.abs(topMotion) > 3) return 2; // leap in similar motion
    //console.log(interval2.topSD +", " +interval1.topSD);
    if (Math.abs(interval2.topSD - interval1.topSD) > 1) return 2;
    return 1; // step
  }
  
  function dissonantDownbeat (interval)
  {
    return (interval.botNew && (interval.nct || interval.isDissonant()));
  }
  
  onRun:
  {
    if (typeof curScore == 'undefined' || curScore == null)
    {
      console.log("no score found");
      Qt.quit();
    }
    
    var dyads = [];
    var index = 0;
    var measure = 1;
    var cursor = curScore.newCursor();
    cursor.rewind(0);
    var segment = cursor.segment;
  
    // Process all dyads and mark intervals
    while (segment)
    {
      var topElem = segment.elementAt(0);
      var botElem = segment.elementAt(4);
      if ((topElem && topElem.type == Element.REST) || (botElem && botElem.type == Element.REST))
      {
        // No rests except maybe at beginning
        errorDetails.text += "No rests allowed after the beginning.\n";
        Qt.quit();
      }
      if ((topElem && topElem.type == Element.CHORD) || (botElem && botElem.type == Element.CHORD))
      {
        dyads[index] = new tonalDyad(); // This is where the magic happens...
        if (index > 0)
        {
          dyads[index].prevTop = dyads[index-1].topNote;
          dyads[index].prevBot = dyads[index-1].botNote;
          dyads[index].prevFB = dyads[index-1].fb;
        }
        dyads[index].processInterval(segment);
        // Check for parallel perfect and leaps to perfect intervals in similar motion
        if (index > 0 && dyads[index].isPerfect() && dyads[index].botNew && dyads[index].topNew)
        {
          if (dyads[index].size == dyads[index-1].size) // PARALLEL PERFECT OH NO
          {
            if (dyads[index].isPerfect() && dyads[index-1].isPerfect())
            {
              if (motion (dyads[index-1], dyads[index]) > 0)
              {
                errorMessage ("|| P"+dyads[index].size, -1, dyads[index], cursor);
                errorDetails.text = errorDetails.text + "Measure "+ measure + ": Parallel P"+dyads[index].size + "\n";
              }
              else
              {
                errorMessage ("Hidden\nP"+dyads[index].size, -1, dyads[index], cursor);
                errorDetails.text += "Measure "+ measure + ": Hidden P"+dyads[index].size+"\n";
              }
            }
            else
            {
              errorMessage ("||"+dyads[index].size, -1, dyads[index], cursor);
              var intervalName = "fifths";
              if (dyads[index].size == 8) intervalName = "octaves";
              errorDetails.text += "Measure "+ measure + ": Consecutive "+intervalName+" in similar motion (avoid)\n";
            }
        }
        else if (motion (dyads[index-1], dyads[index]) > 1)
          {
            errorMessage ("sim"+dyads[index].getIntervalText(), -1, dyads[index], cursor);
            errorDetails.text += "Measure "+ measure + ": Perfect interval approached by leap in similar motion\n";
          }
        }
        if (dyads[index].nct || dyads[index].isDissonant())
        {
            errorMessage ("diss.", 0, dyads[index], cursor);     
            errorDetails.text += "Measure " + measure + ": Interval "+dyads[index].getIntervalText()+" is dissonant here\n";
        }
        if (!dyads[index].botNew)
        {
            errorMessage ("X", 0, dyads[index], cursor);
            errorDetails.text += "Measure " + measure + ": First species forbids extra notes in melody\n";
        }
        if (dyads[index].nct)
        {
            errorMessage ("nct", 0, dyads[index], cursor);
            errorDetails.text += "Measure " + measure + ": Only chord tones are permitted in first species\n";
        
        }
        if (dyads[index].topNote.accidental)
        {
          dyads[index].topNote.accidental.color = "#ff0000";
          errorDetails.text += "Measure " + measure + ": Accidentals are forbidden in major mode\n";
        }
        var text  = newElement(Element.STAFF_TEXT);
        text.pos.y = 10;
        text.text = dyads[index].getIntervalText();
        if (dyads[index].isPerfect()) text.color = colorPerf;
        if (dyads[index].nct) text.color = colorNCT;
        cursor.add(text);
        cursor.next();
        index++;
      }
      else if (segment.elementAt(0).type == Element.BAR_LINE) measure++;

      segment = segment.next;
    }
    errorDetails.visible = true;
    Qt.quit();
  }
}
