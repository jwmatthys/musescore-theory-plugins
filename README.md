# Plugins for Music Theory and Counterpoint

This is a set of practical plugins to assist with identifying intervals and chords, as well as finding errors in two-part counterpoint and four-part SATB writing. It can also generate interval, triad, and seventh chord exercise pages, and can automatically grade interval worksheets completed in MuseScore.

## Latest MuseScore3 Requirement

The checker plugins have been updated to work with the latest release of MuseScore3. The SATB Checker requires MuseScore 3.5.2 in order to correctly read the roman numeral analysis.

## Installation

Copy the included .qml files to your Documents/MuseScore3/Plugins folder. Then open MuseScore and open the Plugin Manager (in the Plugins menu). Check the boxes next to the following entries and click OK:
* chord_checker
* interval_checker
* interval_exercise_checker
* pop_chord_checker
* satb_checker
* seventh_chord_exercise_maker
* triad_exercise_maker
* interval_exercise_maker

Now when you go to the Plugins menu the counterpoint, SATB, and interval, chord, and pop chord checkers will appear under the heading “Proof Reading.” The exercise makers and checkers appear in a separate top menu called "Exercises."

## Use

### SATB Part-Writing Checker

I've wanted to use MuseScore3's new Roman Numeral Analysis tool with part-writing for a long time! This newly updated plugin checks four-part SATB writing, comparing it against the roman numerals to determine if the pitches are correct. It will check voice leading, range, spacing, forbidden parallels, missing chord tones, and more! I created it to find as many possible inaccuracies and style weaknesses as possible.

Roman numerals should be added with the Roman Numeral Analysis tool (Add -> Text -> Roman Numeral Analysis).

Every chord must have four voices spread across two staves, but they can be arranged in any way you want. The plugin will read them from the bottom-up.

You can use diatonic roman numerals with figured bass for inversions. You can also use borrowed chords (mode mixture), secondary chords (V7/V, for instance, or even ii7/iii!), Neapolitan, Italian/German/French augmented sixth chords, and Cadential 6/4 chords. Check the example_satb_complex sample file for details.

There are no options or settings to tweak on this version. The plugin guesses major or minor mode through a simple trick: if there are more i, iv, III, and VI
chords than I, IV, iii, and vi chords, it infers that it is minor mode.

### Species Counterpoint Checker

## I WILL BE UPDATING THIS SOON! STAND BY

Enter your counterpoint melody on a grand staff and run the plugin from the Plugins menu to check your results. If you have selected one or more measures, the plugin will only check the selected measures. If no measures are selected, it will run on the entire file.

If you wish to indicate inversion in a tonal bass line, enter figured bass where necessary using either MuseScore's figured bass options (ctrl-G) or as lyrics below the bass staff. You may enter roman numerals in the lyrics line as well, but this plugin will ignore them. Only figured bass numbers are read by the plugin, and only in tonal mode.

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


## Clearing annotations

Usually the score annotations added by any of the plugins can be removed with the undo command. Otherwise, right-click on any of the text and choose Select → All Similar Elements. The press Delete.

## Errors

The species counterpoint plugin may malfunction if there are rests other than an initial rest in 2-4 species. The counterpoint plugin also malfunctions if there is a bass note without a melody note present. I’m working on finding a way around these problems, which are mainly a problem with the MuseScore plugin framework.

Please report any errors, questions, or suggestions to joel@matthysmusic.com

## Donations

If this plugin is useful to you, please consider buying me a coffee! https://ko-fi.com/D1D07KX5
