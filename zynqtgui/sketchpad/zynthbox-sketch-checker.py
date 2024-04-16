#!/bin/python3

import argparse
import magic
import json
import os
import sys
import taglib

def testFileExists(filename):
    if os.path.isfile(filename):
        if filename.endswith("sketch.wav"):
            return {"isValid": True}
        else:
            return {"isValid": False, "errorString": "The file does not have the expected suffix .sketch.wav"}
    else:
        return {"isValid": False, "errorString": "The file does not exist"}

def testIsWaveFile(filename):
    resultData = testFileExists(filename)
    if resultData["isValid"]:
        mime = magic.from_file(filename, mime = True)
        if mime != "audio/x-wav":
            resultData = {"isValid": False, "errorString": "Not a wave audio file (and definitely not a Zynthbox Sketch)"}
    return resultData

def testIsSketch(filename):
    resultData = testIsWaveFile(filename)
    if resultData["isValid"]:
        tagFile = None
        try:
            tagFile = taglib.File(filename)
            resultData = {"isValid": True}
        except Exception as e:
            resultData = {"isValid": False, "erorrString": "Could not open file to read the tags"}
        if resultData["isValid"]:
            # Basic testing out of the way at this point, time to actually perform Zynthbox Sketch linting
            if "ZYNTHBOX_BPM" in tagFile.tags:
                if "ZYNTHBOX_PATTERN_JSON" in tagFile.tags:
                    if "ZYNTHBOX_AUDIOTYPESETTINGS" in tagFile.tags:
                        if "ZYNTHBOX_ROUTING_STYLE" in tagFile.tags:
                            if "ZYNTHBOX_ACTIVELAYER" in tagFile.tags:
                                if "ZYNTHBOX_AUDIO_TYPE" in tagFile.tags:
                                    # This can now be assumed to be a valid Zynthbox Sketch file
                                    # Let's construct some suggested tags to go with the validation
                                    suggestedTags = []
                                    suggestedTags.append(f"media##duration={tagFile.length}")
                                    suggestedTags.append(f"audio##samplerate={tagFile.sampleRate}")
                                    suggestedTags.append(f"audio##channels={tagFile.channels}")
                                    if len(tagFile.tags["ZYNTHBOX_BPM"]) == 1:
                                        suggestedTags.append(f"music##bpm={tagFile.tags['ZYNTHBOX_BPM'][0]}")
                                    if len(tagFile.tags["ZYNTHBOX_PATTERN_JSON"]) == 1:
                                        patternData = json.loads(tagFile.tags["ZYNTHBOX_PATTERN_JSON"][0])
                                        octaveValues = {"octavenegative1": 0, "octave0": 12, "octave1": 24, "octave2": 36, "octave3": 48, "octave4": 60, "octave5": 72, "octave6": 84, "octave7": 96, "octave8": 108, "octave9": 120}
                                        octave = octaveValues[patternData["octave"]]
                                        pitchValues = {"c": 0, "csharp": 1, "dflat": 1, "d": 2, "dsharp": 3, "eflat": 3, "e": 4, "f": 5, "fsharp": 6, "gflat": 6, "g": 7, "gsharp": 8, "aflat": 8, "a": 9, "asharp": 10, "bflat": 10, "b": 11}
                                        pitch = pitchValues[patternData["pitch"]]
                                        rootKey = octave + pitch
                                        suggestedTags.append(f"music##rootkey={rootKey}")
                                        suggestedTags.append(f"music##rootpitch={patternData['pitch']}")
                                        scale = patternData["scale"]
                                        suggestedTags.append(f"music##scale={scale}")
                                    if "ZYNTHBOX_SAMPLES" in tagFile.tags:
                                        pass
                                    if len(tagFile.tags["ZYNTHBOX_AUDIOTYPESETTINGS"]) == 1:
                                        audioType = "synth"
                                        if tagFile.tags["ZYNTHBOX_AUDIOTYPESETTINGS"][0].startswith("sample-"):
                                            audioType = "sample"
                                        elif tagFile.tags["ZYNTHBOX_AUDIOTYPESETTINGS"][0] == "external":
                                            audioType = "sample"
                                        suggestedTags.append(f"zynthbox##audiotype={audioType}")
                                    resultData = {"isValid": True, "suggestedTags": suggestedTags}
                                else:
                                    resultData = {"isValid": False, "errorString": "This wave file does not contain the Audio Type tag required to be recognized as a Zynthbox Sketch"}
                            else:
                                resultData = {"isValid": False, "errorString": "This wave file does not contain the Active Layer tag required to be recognized as a Zynthbox Sketch"}
                        else:
                            resultData = {"isValid": False, "errorString": "This wave file does not contain the Routing Style tag required to be recognized as a Zynthbox Sketch"}
                    else:
                        resultData = {"isValid": False, "errorString": "This wave file does not contain the Audio Type Settings tag required to be recognized as a Zynthbox Sketch"}
                else:
                    resultData = {"isValid": False, "errorString": "This wave file does not contain the Pattern JSON tag required to be recognized as a Zynthbox Sketch"}
            else:
                resultData = {"isValid": False, "errorString": "This wave file does not contain the BPM tag required to be recognized as a Zynthbox Sketch"}
    return resultData

if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog='zynthbox-sketch-checker',
        description='Tool for checking validity of Zynthbox Sketches',
        epilog='The output will be a json formatted string. The root object will always contain the element isValid, which will be true if the file is a valid Zynthbox Sketch, and false if not. In the case of failure, it will also contain the key errorString, containing a human-readable description of the failure. In the case of a successful result, the key suggestedTags will contain a list of suggested tags that would usefully describe the file.')
    parser.add_argument('sketch_file',
        type=str,
        help='The Zynthbox Sketch file to test - these are created by Zynthbox and will have the double suffix .sketch.wav')
    args = parser.parse_args()

    resultData = testIsSketch(args.sketch_file)
    print(json.dumps(resultData))

    if resultData["isValid"]:
        sys.exit(0)
    else:
        sys.exit(-1)
