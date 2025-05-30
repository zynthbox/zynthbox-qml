import json

with open("plugins.json", "r") as f:
    plugins = json.load(f)

synths = plugins["synth"]
fx = plugins["audioFx"]
sf = plugins["soundfont"]
plugins = {
    "synth": {},
    "fx": {},
    "soundfont": {}
}

index = 0

for plugin_id, plugin in synths.items():
    new_plugin_id = f"ZBP_SYNTH_{index:05d}"
    plugins["synth"][new_plugin_id] = {
        "displayName": plugin["name"],
        "description": plugin["description"],
        "currentVersion": "0.0",
        "versions": {
            "0.0": {
                "pluginName": plugin["name"],
                "format": plugin["format"],
                "path": plugin["path"],
                "engineType": plugin["engineType"],
                "zynthboxVersionAdded": plugin["zynthboxVersionAdded"]
            }
        }
    }

    if "url" in plugin:
        plugins["synth"][new_plugin_id]["versions"]["0.0"]["url"] = plugin["url"]
    if "volumeControls" in plugin:
        plugins["synth"][new_plugin_id]["versions"]["0.0"]["volumeControls"] = plugin["volumeControls"]
    if "cutoffControl" in plugin:
        plugins["synth"][new_plugin_id]["versions"]["0.0"]["cutoffControl"] = plugin["cutoffControl"]
    if "resonanceControl" in plugin:
        plugins["synth"][new_plugin_id]["versions"]["0.0"]["resonanceControl"] = plugin["resonanceControl"]

    index += 1

index = 0

for plugin_id, plugin in fx.items():
    new_plugin_id = f"ZBP_FX_{index:05d}"
    plugins["fx"][new_plugin_id] = {
        "displayName": plugin["name"],
        "category": plugin["category"],
        "currentVersion": "0.0",
        "versions": {
            "0.0": {
                "pluginName": plugin["name"],
                "format": plugin["format"],
                "path": plugin["path"],
                "engineType": plugin["engineType"],
                "zynthboxVersionAdded": plugin["zynthboxVersionAdded"]
            }
        }
    }

    if "url" in plugin:
        plugins["fx"][new_plugin_id]["versions"]["0.0"]["url"] = plugin["url"]

    index += 1


index = 0

for plugin_id, plugin in sf.items():
    new_plugin_id = f"ZBP_SF_{index:05d}"
    plugins["soundfont"][new_plugin_id] = plugin

    index += 1

print(json.dumps(plugins, indent=2))
