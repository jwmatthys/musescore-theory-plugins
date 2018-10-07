# Plugins for Music Theory and Counterpoint

This is a set of practical plugins to assist with identifying intervals and chords, as well as finding errors in two-part counterpoint and four-part SATB writing. It can also generate interval, triad, and seventh chord exercise pages, and can automatically grade interval worksheets completed in MuseScore.

## Installation

Copy the included .qml files to your Documents/MuseScore2/Plugins folder. Then open MuseScore and open the Plugin Manager (in the Plugins menu). Check the boxes next to the following entries and click OK:
* chord_checker
* interval_exercise_checker
* pop_chord_checker
* seventh_chord_exercise_maker
* triad_exercise_maker
* interval_checker
* interval_exercise_maker
* satb_checker
* species_checker

Now when you go to the Plugins menu the counterpoint, SATB, and interval, chord, and pop chord checkers will appear under the heading “Proof Reading.” The exercise makers and checkers appear in a separate top menu called "Exercises."

## Use

### Counterpoint Checker

Enter your counterpoint melody on a grand staff and run the plugin from the Plugins menu to check your results. If you wish to indicate inversion in a tonal bass line, enter figured bass where necessary using ctrl-G.

At this time, the plugin really works best on straightforward species examples. The tonal species plugins have been tested successfully with all of the examples in Seth Monahan’s excellent Two-Part Harmonic Species Counterpoint: An Introduction, available at http://sethmonahan.com/TH101HarmonicCounterpoint.html. The procedures for the tonal plugin are derived from the rules laid out in this book.

The modal species plugins currently only work with the cantus firmus below the counterpoint. (Look for new versions in the future that can work with the cf on top.) The rules come from Peter Schubert’s Modal Counterpoint, Renaissance Style and are generally in agreement with Tom Pankhurst's Guide to Schenkerian Analysis, http://www.schenkerguide.com/.

#### Counterpoint Proofreading Codes

```
Code   Meaning
acc    Forbidden non-diatonic accidental
AN     Accented Neighbor tone (not an error)
APP    Appoggiatura (not an error)
APT    Accented Passing tone (not an error)
dir5   Direct fifths – usually either P5→d5 or d5→P5; should be avoided
dis    Improperly treated dissonance
DN     Double neighbor (not an error)
ET     Escape Tone (not an error)
hid    Hidden fifths or octaves (consecutive P5 or P8 in contrary motion)
lfd    Leap from dissonant non-chord tone
ltd    Leap to dissonant non-chord tone
ltp    Leap to perfect interval in similar motion
lt     Leading tone not resolved correctly at cadence
lt!    You forgot to raise the leading tone in minor!
mel7   Melody leaps a seventh
NT     Neighbor tone (not an error)
PT     Passing tone (not an error)
rep    Forbidden repeated note
RET    Retardation (not an error) – a suspension that resolves up by half step
sb     Melody leaps a 6th or octave without stepping back in opposite direction afterward
SUS    Suspension (not an error)
X      Melody crosses below bass
x      Forbidden offbeat notes in first species
->+3, ->d5    Melody moves by augmented or diminished interval
2xlt   Leading tone is doubled in bass and melody
7th    The seventh of a V7 moving to I isn’t resolved correctly
||P5, ||P8    Parallel fifths or octaves
```

#### Other Counterpoint Warning Messages

```
Too many consecutive 3rds or 6ths (up to 4 before warning)
Too many consecutive leaps (up to 4 before warning)
Too many perfect interval (up to 50% before warning)
Too many leaps (up to 50% before warning)
Melody should have larger range (experimental warning – uses standard deviation of melody)
```

### SATB Chorale Checker

By default the plugin will run in Major mode. To check minor examples, set the “Lyricist” text field (Add → Text → Lyricist) to “Minor”.

Roman numerals and figured bass should be entered as lyrics. Feel free to use superscript/subscript for figured bass, and to resize the lyrics as desired.

There are multiple valid ways to enter the SATB voices:
* Soprano in layer 1, alto in layer 2 of top staff; tenor in layer 1, bass in layer 2 of bass staff
* Soprano and alto as chords in layer 1 of top staff; tenor and bass as layer 1 of bottom staff
* Soprano, alto, and tenor as layer 1 in top staff; bass as layer 1 of bottom staff (keyboard style)

The plugin will do its best to guess where the voices are placed.

#### SATB Proofreading Codes

```
Code      Meaning
note err      One or more wrong notes in the chord
inv           Incorrect inversion based on figured bass
no root       Missing the root of the chord
no 3rd        Missing the third of the chord
no 7th        Seventh chord is missing the seventh
no 5th        Chord is in inversion and is missing the fifth.
X             Voice crossing error
sp            Spacing error (more than an octave between soprano-alto or alto-tenor)
LTx2          Leading tone is doubled
||P5          Parallel 5ths (hidden 5ths will also be identified as ||P5)
||P8          Parallel octaves
LT res        Leading tone needs to resolve up to tonic*
tendency res  A tendency tone needs to resolve down (usually the 7th of a V7 chord)
d7 res        Seventh of viio7 needs to resolve down
s range       Soprano note is out of standard range (C4 - G5)
a range       Alto note is out of standard range (G3 - D5)
t range       Tenor note is out of standard range (C3 - G4)
b range       Bass note is out of standard range (E2 - C4)
```

#### Doubling Rules

My only restriction about doubling is never double the leading tone. This plugin will not warn about irregular doubling unless you leave out an essential chord tone or have forbidden parallels.

#### Leading Tone Resolution

Many theory texts require that the leading tone resolve up to tonic on V-I or viio-I if the leading tone is in the soprano. In my theory classes I'm a little more hardcore: I say that the leading tone must resolve up no matter what voice it’s in. If you want to change it, you can open the plugin code in the Plugin Creator and change line 15 from true to false.

## Clearing annotations

Usually the score annotations added by any of the plugins can be removed with the undo command. Otherwise, right-click on any of the text and choose Select → All Similar Elements. The press Delete.

## Errors

The counterpoint plugin may malfunction if there are rests other than an initial rest in 2-4 species. The counterpoint plugin also malfunctions if there is a bass note without a melody note present. I’m working on finding a way around these problems, which are mainly a problem with the MuseScore2 plugin framework.

Please report any errors, questions, or suggestions to joel@matthysmusic.com

## Donations

If this plugin is useful to you, please consider buying me a coffee! https://ko-fi.com/D1D07KX5
