# Counterpoint Checking Plugins for MuseScore2

This is a set of plugins that will check for errors in 1st - 4th species tonal counterpoint, with rules set forth at http://sethmonahan.com/TH101HarmonicCounterpoint.html.

## Installation

Copy the included .qml files to your Documents/MuseScore2/Plugins folder. Then open MuseScore and open the Plugin Manager (in the Plugins menu). Check the boxes next to the tonal_species and modal_species entries and click OK. Now when you go to the Plugins menu they will appear under the heading “Proof Reading.”

## Use

This plugin checks the whole file, not a selection. Enter your counterpoint melody on a grand staff and run the plugin from the Plugins menu to check your results. If you are writing your own bass line, be sure to enter figured bass where necessary using ctrl-G.

## Proofreading Codes

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

## Other warning messages

```
Too many consecutive 3rds or 6ths (up to 4 before warning)
Too many consecutive leaps (up to 4 before warning)
Too many perfect interval (up to 50% before warning)
Too many leaps (up to 50% before warning)
Melody should have larger range (experimental warning – uses standard deviation of melody)
```

## Limitations

At this time, the plugin really works best on straightforward species examples. The tonal species plugins have been tested successfully with all of the examples in Seth Monahan’s excellent Two-Part Harmonic Species Counterpoint: An Introduction, available at http://sethmonahan.com/TH101HarmonicCounterpoint.html. The procedures for the tonal plugin are derived from the rules laid out in this book.

The modal species plugins currently only work with the cantus firmus below the counterpoint. (Look for new versions in the future that can work with the cf on top.) The rules come from Peter Schubert’s Modal Counterpoint, Renaissance Style and are generally in agreement with Tom Pankhurst's Guide to Schenkerian Analysis, http://www.schenkerguide.com/.

The plugin may malfunction if there are rests other than an initial rest in 2-4 species. The plugin also malfunctions if there is a bass note without a melody note present. I’m working on finding a way around these problems, which are mainly a problem with the MuseScore2 plugin framework.

## Errors

Please report any errors, questions, or suggestions to joel@matthysmusic.com

Donations

If this plugin is useful to you, please consider buying me a coffee! https://ko-fi.com/D1D07KX5
