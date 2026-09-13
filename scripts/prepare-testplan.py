"""Resolve generated target IDs and explicitly enable StoreKit for UI tests."""
import json
import subprocess
from pathlib import Path

project = json.loads(subprocess.check_output([
    "plutil", "-convert", "json", "-o", "-", "PlanBridgeAI.xcodeproj/project.pbxproj"
]))
targets = {obj["name"]: key for key, obj in project["objects"].items()
           if obj.get("isa") == "PBXNativeTarget"}
def reference(name):
    return {"containerPath": "container:PlanBridgeAI.xcodeproj",
            "identifier": targets[name], "name": name}
path = Path("PlanBridge.xctestplan")
plan = json.loads(path.read_text())
plan["defaultOptions"]["targetForVariableExpansion"] = reference("PlanBridgeAI")
plan["testTargets"] = [{"target": reference("PlanBridgeUITests")}]
path.write_text(json.dumps(plan, indent=2) + "\n")
