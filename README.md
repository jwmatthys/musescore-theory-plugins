# MuseScore Plugins for Music Theory and Counterpoint

This is a set of practical plugins to assist with identifying intervals and chords, as well as finding errors in two-part counterpoint and four-part SATB writing. It can also generate interval, triad, and seventh chord exercise pages, and can automatically grade interval worksheets completed in MuseScore.

## Latest MuseScore3 Requirement

The checker plugins have been updated to work with the latest release of MuseScore3. The SATB checker and species counterpoint checkers require MuseScore 3.5.2 or later in order to correctly read the roman numeral analysis.

## Installation

Copy the included .qml files to your Documents/MuseScore3/Plugins folder. Then open MuseScore and open the Plugin Manager (in the Plugins menu). Check the boxes next to the plugins that you would like to enable. If you're planning to use the SATB checker or the species counterpoint checkers, I receommend you assign a shortcut key.

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

#### Modal Counterpoint, Species I - III

Enter your two part counterpoint melody on a grand staff and run the plugin from the Plugins menu to check your results. If you have selected one or more measures, the plugin will only check the selected measures. If no measures are selected, it will run on the entire file.

The modal species plugins will check both the upper and lower parts for counterpoint errors. You may optionally use the lyric tool to attach the word "cf" to the staff you would like to designate the cantus firmus.

The plugin does not enforce the rhythmic conventions of species counterpoint, so there is some flexibility about the types of counterpoint it can be used to check. The rules come from Peter Schubert’s Modal Counterpoint, Renaissance Style and are generally in agreement with Tom Pankhurst's Guide to Schenkerian Analysis, http://www.schenkerguide.com/.

#### Tonal Counterpoint, Species I - III

### Currently being updated! (Summer 2022)

The tonal species plugins have been tested successfully with all of the examples in Seth Monahan’s excellent Two-Part Harmonic Species Counterpoint: An Introduction available at http://sethmonahan.com/TH101HarmonicCounterpoint.html. The tonal plugins evaluation procedures are derived from the rules laid out in this book.

### Clearing annotations

Usually the score annotations added by any of the plugins can be removed with the undo command. Otherwise, right-click on any of the text and choose Select → All Similar Elements. The press Delete.

## Errors

Please report any errors, questions, or suggestions to joel@matthysmusic.com

## Donations

If this plugin is useful to you, please consider buying me a coffee! https://ko-fi.com/D1D07KX5
