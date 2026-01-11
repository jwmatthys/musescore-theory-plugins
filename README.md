# MuseScore Studio Plugins for Music Theory and Counterpoint

This is a set of practical plugins to assist with identifying intervals and chords, as well as finding errors in two-part counterpoint and four-part SATB writing.

## Latest MuseScore Studio version Requirement

These plugins have been updated to work with version 4.6.5 of MuseScore Studio.

## Installation

Copy the contents of the plugins folder to your Documents/MuseScore3/Plugins folder. Then open MuseScore Studio and enable the plugins in the Plugins sidebar.

## Use

### SATB Part-Writing Checker

This newly updated plugin checks four-part SATB writing, comparing it against the roman numerals to determine if the pitches are correct. It will check voice leading, range, spacing, forbidden parallels, missing chord tones, and more! I created it to find as many possible inaccuracies and style weaknesses as possible.

Roman numerals should be added with the Roman Numeral Analysis tool (Add -> Text -> Roman Numeral Analysis).

Every chord must have four voices spread across two staves, but they can be arranged in any way you want. You can run the plugin on a full score or a selection, but the first selected chord must have all 4 voices, which are assigned SATB from that point.

You can use diatonic roman numerals with figured bass for inversions. You can also use borrowed chords (mode mixture), secondary chords (V7/V, for instance, or even IV7/IV), Neapolitan, Italian/German/French augmented sixth chords, and Cadential 6/4 chords. Check the example_satb_complex sample file for details.

Any chords that do not have roman numerals will not be analyzed for chord tones, but will still be analyzed for voice leading errors.

The plugin will determine if a progression is in major or minor mode based on the roman numerals.

### Species Counterpoint Checker

#### Harmonic Counterpoint, Species I - IV

The particular "flavor" of harmonic species counterpoint here is derived from Aldwell & Schachter's Harmony and Voice Leading text, as well as the teaching of Seth Monahan at Eastman. This idiosyncratic approach defines dissonance through harmony: consonances are chord tones, and dissonances are simply non-chord tones. This is ultimately a Schenkerian harmonic approach to melody.

First Species counterpoint is note-against-note, with no dissonances (non-chord tones) allowed.

Second Species freely mixes 2:1 (two half notes) or 3:1 (half-quarter-quarter) rhythms; only unaccented passing tones are allowed.

Third Species is similar to second species but neighbor tones (including double neighbors) are permitted.

Fourth Species is strict 2:1 with accented passing and neighbor tones, suspensions/retardations, and appoggiaturas permitted.

#### Modal Counterpoint, Species I (II and III coming soon)

Enter your two part counterpoint melody on a grand staff and run the plugin from the Plugins menu to check your results. If you have selected one or more measures, the plugin will only check the selected measures. If no measures are selected, it will run on the entire file.

The modal species plugins will check both the upper and lower parts for counterpoint errors.

The plugin does not enforce the rhythmic conventions of species counterpoint, so there is some flexibility about the types of counterpoint it can be used to check. The rules come from Peter Schubert’s Modal Counterpoint, Renaissance Style and are generally in agreement with Tom Pankhurst's Guide to Schenkerian Analysis, http://www.schenkerguide.com/.

### Clearing annotations

Usually the score annotations added by any of the plugins can be removed with the undo command. Otherwise, right-click on any of the text and choose Select → All Similar Elements. The press Delete.

## Errors

Please report any errors, questions, or suggestions to joel@matthysmusic.com

## Donations

If this plugin is useful to you, please consider buying me a coffee! https://ko-fi.com/D1D07KX5
