# engine_config.json

engine_config.json provides a way to define non standard attributes for synths so that Zynthbox is able to use them
1. The JSON file expects the engine nickname as the key like `JV/synthv1`, `JV/amsynth`
2. Each engine object can contain any of the following properties :
    - `volumeControls` : A list of controller names which sets the volume of the synth. If not defined, Zynthbox tries to find the default volume controllers with name `Volume` or `volume`
    - `description` : A description text that will be displayed in synth selection page
    - `cutoffControl` : Name of filter cutoff controller. If not defined, Zynthbox tries to find default filter cutoff controller with name `cutoff` or `filter_cutoff`
    - `resonanceControl` : Name of filter resonance controller. If not defined, Zynthbox tries to find default filter cutoff controller with name `resonance` or `filter_resonance`

Here is an example of engine_config.json:

```json
{
    "JV/synthv1": {
        "volumeControls": ["OUT1_VOLUME", "OUT2_VOLUME"],
        "cutoffControl": "DCF1_CUTOFF",
        "resonanceControl": "DCF1_RESO",
        "description": "Synth V1 small description"
    },
    "JV/amsynth": {
        "volumeControls": ["master_vol"],
        "description": "A tiny custom description for amsynth"
    },
    "JV/Red Zeppelin 5": {
        "volumeControls": ["level"]
    },
    "JV/Calf Monosynth": {
        "volumeControls": ["master"]
    }
}
```
