## Knobs


1. Knob events are passed in following order. If not handled then passed to the level below :
    1. Main Window (Handles the global Alt/Metronome + knob event across all pages)
    2. Any Dialog/Popup/Drawer
    3. Current Page
2. Sketchpad has a hierarchy of components that handles knob events according to the visible component. If not handled by the open component, it falls back to the Sketchpad knob handler :
```
  |- Sketchpad
     |- Bottom Bar
        |- Clip Settings
        |- Wave Editor
     |- Mixer
     |- Channel Tab
     |- Clips Tab
     |- Synths Tab
     |- Samples Tab
     |- FX Tab
     |- Sound Combinator
```
4. Other selector pages like library and settings uses Big knob to traverse list.
5. All Dialogs/Drawers/Popups has knob interaction disabled unless explicitly handled by respective Dialog/Drawer/Popup

### Knob interaction of pages

| Page | Small Knob 1 | Small Knob 2 | Small Knob 3 | Big Knob | BK Click |
| ---- | ------------ | ------------ | ------------ | -------- |----------|
| Main Window | `Alt`:Synth Volume<br>`Metronome`: Metronome Volume | `Alt`: Channel Delay Send Amount<br> | `Alt`: Channel Reverb Send Amount<br> | <br>`Metronome`: BPM | |
| Sketchpad | Fallback to Main Window | Fallback to Main Window | Fallback to Main Window | Selected Channel | |
| Sketchpad/Bottom&nbsp;Bar/Clip&nbsp;Settings | Clip Gain | Clip Pitch | Clip Speed Ratio | Clip Bpm | |
| Sketchpad/Bottom&nbsp;Bar/Wave&nbsp;Editor | Clip Start Position | Clip Loop Position | Clip Length | Disabled | |
| Sketchpad/Mixer | Channel Volume | Channl Pan | Fallback to Sketchpad | Fallback to Sketchpad | |
| Sketchpad/Channel&nbsp;Tab | Channel volume | Synth cutoff | Synth resonance | Fallback to Sketchpad | |
| Sketchpad/Clips&nbsp;Tab | Fallback to Sketchpad | Fallback to Sketchpad | Fallback to Sketchpad | Fallback to Sketchpad | |
| Sketchpad/Synths&nbsp;Tab | Synth volume | Synth cutoff | Synth resonance | Fallback to Sketchpad | |
| Sketchpad/Samples&nbsp;Tab | Disabled | Disabled | Disabled | Fallback to Sketchpad | |
| Sketchpad/FX&nbsp;Tab | Disabled | Disabled | Disabled | Fallback to Sketchpad | |
| Sketchpad/Sound&nbsp;Combinator | Channel Volume | Fallback to Sketchpad | Fallback to Sketchpad | Synth Preset | |
| Synth Editpage | 1st dial | 2nd dial | 3rd dial | Selected column | |
| Audio Editpage/General Tab | Clip Start Position | Clip Loop Position | Clip Length | Disabled | |
| Audio Editpage/Envelope Tab | Select previous/next ADSR Element | Control Selected ADSR Element Value | Disabled | Select previous/next ADSR Element | |
| Audio Editpage/Granular Tab | Select previous/next Graineator Element | Control Selected Graineator Element Value | Disabled | Select previous/next Graineator Element | |
| External Editpage | Disabled | Disabled | Disabled | Selected external midi channel | |
| FilePickerDialog.qml | Disabled | Disabled | Disabled | Traverse file/folder list | |
| Any Selector page (Library, Settings, etc) | Disabled | Disabled | Disabled | Traverse list | |
| Global Dialog | Master Volume | Delay FX | Reverb FX | BPM | |
| Song Manager | Bar length | Beat length | Disabled | Select segment | |
| Step Sequencer | Velocity | Length | Position | Select step or note | Open Step Settings for selected step
| Step Sequencer/Step Settings | Velocity | Length | Position | Select note | Close Step Settings
| Step Sequencer/Note Settings | Velocity | Length | Position | Select step |
