import json

with open("plugins.orig.json", "r") as f:
    plugins = json.load(f)

synth = plugins["synth"]
fx = plugins["fx"]
sf = plugins["soundfont"]
plugins = {
    "synth": {},
    "audioFx": {},
    "soundfont": {}
}


for plugin_id, plugin in synth.items():
    plugins["synth"][plugin_id] = {
        "displayName": plugin["displayName"],
        "description": plugin["description"],
        "longDescription": None,
        "image": f"synths/{plugin['displayName'].lower().replace(' ', '-')}.png",
        "categories": [
            {
                "type": "synth",
                "id": "0000"
            }
        ],
        "currentVersion": "0000",
        "versions": {
            "0000": {
                "visible": True,
                "pluginName": plugin["versions"]["0.0"]["pluginName"],
                "format": plugin["versions"]["0.0"]["format"],
                "path": plugin["versions"]["0.0"]["path"],
                "engineType": plugin["versions"]["0.0"]["engineType"],
                "sha256sum": None,
                "zynthboxVersionAdded": plugin["versions"]["0.0"]["zynthboxVersionAdded"],
                "url": plugin["versions"]["0.0"]["url"] if "url" in plugin["versions"]["0.0"] else None,
                "volumeControls": plugin["versions"]["0.0"]["volumeControls"] if "volumeControls" in plugin["versions"]["0.0"] else None,
                "cutoffControl": plugin["versions"]["0.0"]["cutoffControl"] if "cutoffControl" in plugin["versions"]["0.0"] else None,
                "resonanceControl": plugin["versions"]["0.0"]["resonanceControl"] if "resonanceControl" in plugin["versions"]["0.0"] else None
            }
        }
    }


for plugin_id, plugin in sf.items():
    sha256sum = plugin["currentVersion"]
    plugins["soundfont"][plugin_id] = {
        "displayName": plugin["displayName"],
        "description": None,
        "longDescription": None,
        "image": None,
        "categories": [
            {
                "type": "soundfont",
                "id": "0000"
            }
        ],
        "currentVersion": "0000",
        "versions": {
            "0000": {
                "visible": True,
                "pluginName": plugin["versions"][sha256sum]["pluginName"],
                "format": plugin["versions"][sha256sum]["format"],
                "path": plugin["versions"][sha256sum]["path"],
                "engineType": None,
                "sha256sum": sha256sum,
                "zynthboxVersionAdded": plugin["versions"][sha256sum]["zynthboxVersionAdded"],
                "url": None,
                "volumeControls": None,
                "cutoffControl": None,
                "resonanceControl": None
            }
        }
    }


categoryIdByName = {}

with open("categories.json", "r") as f:
    categoriesJson = json.load(f)

    for categoryId, category in categoriesJson["audioFx"].items():
        categoryIdByName[category["displayName"]] = categoryId


for plugin_id, plugin in fx.items():
    plugins["audioFx"][plugin_id] = {
        "displayName": plugin["displayName"],
        "description": None,
        "longDescription": None,
        "image": None,
        "categories": [
            {
                "type": "audioFx",
                "id": categoryIdByName[plugin["category"]] if plugin["category"] in categoryIdByName else "o.O"
            }
        ],
        "currentVersion": "0000",
        "versions": {
            "0000": {
                "visible": True,
                "pluginName": plugin["versions"]["0.0"]["pluginName"],
                "format": plugin["versions"]["0.0"]["format"],
                "path": plugin["versions"]["0.0"]["path"],
                "engineType": plugin["versions"]["0.0"]["engineType"],
                "sha256sum": None,
                "zynthboxVersionAdded": plugin["versions"]["0.0"]["zynthboxVersionAdded"],
                "url": plugin["versions"]["0.0"]["url"] if "url" in plugin["versions"]["0.0"] else None,
                "volumeControls": plugin["versions"]["0.0"]["volumeControls"] if "volumeControls" in plugin["versions"]["0.0"] else None,
                "cutoffControl": plugin["versions"]["0.0"]["cutoffControl"] if "cutoffControl" in plugin["versions"]["0.0"] else None,
                "resonanceControl": plugin["versions"]["0.0"]["resonanceControl"] if "resonanceControl" in plugin["versions"]["0.0"] else None
            }
        }
    }


print(json.dumps(plugins, indent=2))
