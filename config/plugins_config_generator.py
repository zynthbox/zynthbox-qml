import json
import lilv
import re
from hashlib import sha256
from pathlib import Path


if __name__ == '__main__':
    world = lilv.World()
    world.load_all()
    world.ns.ev = lilv.Namespace(world, "http://lv2plug.in/ns/ext/event#")
    world.ns.presets = lilv.Namespace(world, "http://lv2plug.in/ns/ext/presets#")
    world.ns.portprops = lilv.Namespace(world, "http://lv2plug.in/ns/ext/port-props#")
    world.ns.portgroups = lilv.Namespace(world, "http://lv2plug.in/ns/ext/port-groups#")

    accepted_synths = [
        "calf monosynth",
        "drumsynth",
        "fabla",
        "foo yc20 organ",
        "helm",
        "nekobi",
        "noize mak3r",
        "obxd",
        "padthv1",
        "raffo synth",
        "red zeppelin 5",
        "string machine",
        "surge",
        "synthv1",
        "vex"
    ]

    accepted_fx = [
        # Chorus
        "gxchorus-stereo",
        "string machine chorus",
        "string machine stereo chorus",
        "yk chorus",
        "zynchorus",

        # Compressor
        "cs10qs",
        "cs10qs-sc",
        "zamcomp",
        "zamcompx2",

        # Delay
        "gxdigital_delay_st",
        "gxecho-stereo",
        "gxtubedelay",
        "modulay",
        "tal-dub-3",
        "zamgrains",
        "zynecho",

        # Distortion
        "ds1",
        "gxbajatubedriver",
        "gxboss ds1",
        "gxdistortionplus",
        "gxtubescreamer",
        "gxvoodoofuzz",
        "open big muff",
        "zyndistortion",

        # Dynamics
        "tap stereo dynamics",

        # EQ
        "3 band eq",

        # Filter
        "tal-filter",

        # Flanger
        "gxflanger",

        # Gate
        "abgate",

        # Modulator
        "calf flanger",
        "calf phaser",
        "gxtremolo",
        "gxwahwah",
        "larynx",
        "tal-vocoder-ii",

        # Phaser
        "gxphaser",
        "zynphaser",

        # Reverb
        "dragonfly early reflections",
        "dragonfly hall reverb",
        "dragonfly plate reverb",
        "dragonfly room reverb",
        "mverb",
        "roomy",
        "shiroverb",
        "tal-reverb",
        "tal-reverb-ii",
        "tal-reverb-iii",
        "tap reverberator",

        # Simulator
        "gxamplifier-stereo-x",
        "gxamplifier-x",
        "tap tubewarmth",
        "x42 whirl - rotary speaker",

        # Spatial
        "ping pong pan",

        # Utility
        "alo",
        "gain",
        "gain 2x2"
    ]

    accepted_sf2 = [
        "ACBass",
        "Acid SQ Neutral",
        "Acoustic Guitars",
        "Analog Saw",
        "Bassguitars",
        "Beeper",
        "Bindo_FingeredBass",
        "BluesBzz",
        "BookerT",
        "BuenosBassSlides",
        "d10 TEK bass",
        "Dance Organs",
        "Dance Trance",
        "Dirty Sub",
        "Djents",
        "Dsix Magic",
        "Dx7 velobass - VS",
        "DX7 Wurlitzer",
        "Expressive Acoustic Guitar",
        "Fazioli Grand",
        "FluidR3Mono_GM",
        "FM Modulator",
        "FM Piano",
        "Full Grands",
        "Funky Guitars",
        "Giga Piano",
        "Guitars Universal 1.4",
        "Heavy Guitars",
        "Hip Hop Combo",
        "JAzz BAzz",
        "Jazz Guitars",
        "jRhodes4",
        "Juno FilterBass ",
        "Kawai Upright Piano",
        "ModSynth_R1",
        "Moogbazz",
        "Naturally Decaying B-Guitars",
        "Nylon Guitar",
        "Oberheim OB-3",
        "Perfect Sine",
        "Pipe Organ",
        "Prophet Killer",
        "Roland Novation Bass",
        "Squierbass",
        "Stratocaster",
        "Super Saw 1",
        "Super Saw 2",
        "Super Saw 3",
        "Synth Samples",
        "Valve OD Guitar",
        "VintageDreamsWaves-v2"
    ]
    accepted_sfz = [
        "Synths",
        "Drum Machines"
    ]
    other_synths = [
        {
            "name": "Aeolus",
            "path": "/usr/bin/aeolus",
            "engineType": "aeolus"
        },
        {
            "name": "FluidSynth",
            "path": "/usr/bin/fluidsynth",
            "engineType": "fluidsynth"
        },
        {
            "name": "setBfree",
            "path": "/usr/bin/setBfree",
            "engineType": "setbfree"
        },
        {
            "name": "Sfizz",
            "path": "/usr/bin/sfizz_jack",
            "engineType": "sfizz"
        },
        {
            "name": "ZynAddSubFX",
            "path": "/usr/bin/zynaddsubfx",
            "engineType": "zynaddsubfx"
        }
    ]

    plugins = {
        "synth": {},
        "soundfont": {},
        "audioFx": {}
    }
    all_plugins_and_engines = {}

    synth_id = 1000
    soundfont_id = 5000
    audiofx_id = 10000

    for plugin in world.get_all_plugins():
        plugin_name = str(plugin.get_name())
        plugin_class = re.sub(' Plugin', '', str(plugin.get_class().get_label()))
        all_plugins_and_engines[plugin_name] = {
            'URL': str(plugin.get_uri()),
            # 'TYPE': get_plugin_type(plugin).value,
            'CLASS': plugin_class,
            # 'ENABLED': is_plugin_enabled(name),
            # 'UI': is_plugin_ui(plugin),
            'BUNDLE_URI': str(plugin.get_bundle_uri()),
            'PLUGIN_TYPE': 'LV2',
            'ENGINE_TYPE': 'jalv'
        }

    # TODO : Also add sf3 to list
    for file in Path("/zynthian/zynthian-data/soundfonts/sf2/").glob("*.sf2"):
        name = file.name.replace(".sf2", "")
        all_plugins_and_engines[name] = {
            "PATH": str(file.absolute()),
            'PLUGIN_TYPE': 'SF2'
        }

    for dir in Path("/zynthian/zynthian-data/soundfonts/sfz/").glob("*"):
        name = dir.name
        all_plugins_and_engines[name] = {
            "PATH": str(dir.absolute()),
            'PLUGIN_TYPE': 'SFZ'
        }

    for synth in other_synths:
        all_plugins_and_engines[synth["name"]] = {
            "PATH": synth["path"],
            'PLUGIN_TYPE': "Other",
            'ENGINE_TYPE': synth["engineType"]
        }

    for plugin_name in all_plugins_and_engines.keys():
        plugin_id = ""
        plugin_class = ""

        print(f"Testing plugin `{plugin_name}`:")
        if plugin_name.lower() in accepted_synths or all_plugins_and_engines[plugin_name]["PLUGIN_TYPE"].lower() == "other":
            plugin_id = f"ZBP_{synth_id}"
            plugin_class = "synth"
            synth_id += 1
        elif plugin_name in accepted_sf2 or plugin_name in accepted_sfz:
            plugin_id = f"ZBP_{soundfont_id}"
            plugin_class = "soundfont"
            soundfont_id += 1
        elif plugin_name.lower() in accepted_fx:
            plugin_id = f"ZBP_{audiofx_id}"
            plugin_class = "audioFx"
            audiofx_id += 1


        if not plugin_id == "":
            print(f"  Generating config for {plugin_name}")
            plugins[plugin_class][plugin_id] = {}
            plugins[plugin_class][plugin_id]["name"] = plugin_name
            plugins[plugin_class][plugin_id]["format"] = all_plugins_and_engines[plugin_name]["PLUGIN_TYPE"] # Store the type of plugin : lv2/sf2/sfz etc
            if plugins[plugin_class][plugin_id]["format"].lower() == "lv2":
                # Considering all synth and audioFx are lv2 plugins, add it's identifier URL to plugins json
                plugins[plugin_class][plugin_id]["url"] = all_plugins_and_engines[plugin_name]["URL"]
                if plugin_class == "audioFx":
                    # Considering all fx are lv2 plugins, add it's category to plugins json
                    plugins[plugin_class][plugin_id]["category"] = all_plugins_and_engines[plugin_name]['CLASS']
                plugins[plugin_class][plugin_id]["path"] = all_plugins_and_engines[plugin_name]['BUNDLE_URI'].replace("file://", "")
                plugins[plugin_class][plugin_id]["version"] = ""
                plugins[plugin_class][plugin_id]["engineType"] = all_plugins_and_engines[plugin_name]['ENGINE_TYPE']
            elif plugins[plugin_class][plugin_id]["format"].lower() == "sf2":
                plugins[plugin_class][plugin_id]["path"] = all_plugins_and_engines[plugin_name]['PATH']
                print(f"  Hashing file : {plugins[plugin_class][plugin_id]['path']}")
                h256 = sha256()
                with open(plugins[plugin_class][plugin_id]["path"], "rb") as f:
                    h256.update(f.read())
                plugins[plugin_class][plugin_id]["sha256sum"] = h256.hexdigest()
            elif plugins[plugin_class][plugin_id]["format"].lower() == "other":
                plugins[plugin_class][plugin_id]["path"] = all_plugins_and_engines[plugin_name]['PATH']
                plugins[plugin_class][plugin_id]["version"] = ""
                plugins[plugin_class][plugin_id]["engineType"] = all_plugins_and_engines[plugin_name]['ENGINE_TYPE']
            plugins[plugin_class][plugin_id]["zynthboxVersionAdded"] = "1"

    print(f"Generated config for {len(plugins['synth'].keys())} synth plugins")
    print(f"Generated config for {len(plugins['soundfont'].keys())} soundfont plugins")
    print(f"Generated config for {len(plugins['audioFx'].keys())} audioFx plugins")

    # TODO : Do not remove existing plugins json data to keep engine overrides
    with open(Path(__file__).parent / "plugins.json", "w") as f:
        sort_plugins_by_id = lambda k: int(k[0].split("_")[1])
        output = {
            "synth": dict(sorted(plugins["synth"].items(), key=sort_plugins_by_id)),
            "soundfont": dict(sorted(plugins["soundfont"].items(), key=sort_plugins_by_id)),
            "audioFx": dict(sorted(plugins["audioFx"].items(), key=sort_plugins_by_id)),
        }
        json.dump(output, f)
