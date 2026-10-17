#!/usr/bin/env python3
"""Validate the proposed marketing exports using Python's standard library."""
import hashlib
import json
from pathlib import Path
import struct
import subprocess
import sys

root = Path(sys.argv[1] if len(sys.argv) > 1 else "docs/app-store/screenshot-redesign-2026-10-17")
manifest = json.loads((root / "manifest.json").read_text())
assert len(manifest) == 10
assert len({item["file"] for item in manifest}) == 10
expected = {"iphone": (1320, 2868), "ipad": (2064, 2752)}
results = []
for item in manifest:
    file = root / item["file"]
    data = file.read_bytes()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", file
    width, height, depth, color_type = struct.unpack(">IIBB", data[16:26])
    assert (width, height) == expected[item["platform"]], file
    assert (depth, color_type) == (8, 2), f"Expected opaque 8-bit RGB: {file}"
    assert len(data) > 10_000, file
    profile = subprocess.check_output(["sips", "-g", "profile", str(file)], text=True)
    assert "sRGB IEC61966-2.1" in profile, file
    raw = root / item["source"]
    source_bytes = raw.read_bytes()
    rw, rh = struct.unpack(">II", source_bytes[16:24])
    crop = item["sourceCrop"]
    assert crop["x"] >= 0 and crop["y"] >= 0
    assert crop["x"] + crop["width"] <= rw
    assert crop["y"] + crop["height"] <= rh
    rect = item["drawRect"]
    assert rect["x"] >= 0 and rect["y"] >= 0
    assert rect["x"] + rect["width"] <= width + .01
    assert rect["y"] + rect["height"] <= height + .01
    assert abs(rect["width"] / crop["width"] - rect["height"] / crop["height"]) < .00001
    results.append({"file": item["file"], "width": width, "height": height,
                    "bitDepth": depth, "colorType": "RGB", "hasAlpha": False,
                    "colorProfile": "sRGB IEC61966-2.1", "bytes": len(data),
                    "sha256": hashlib.sha256(data).hexdigest(), "source": item["source"],
                    "sourceSHA256": hashlib.sha256(source_bytes).hexdigest()})
for platform in expected:
    assert len([item for item in manifest if item["platform"] == platform]) == 5
description = (root / "description-en-US.txt").read_text().strip()
assert 0 < len(description) <= 4000
approved = (root / "approval.json").exists()
result = {"status": "approved" if approved else "proposed-awaiting-approval", "passed": True,
          "appleRequirementsCheckedOn": "2026-10-17",
          "appleRequirementsURL": "https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/",
          "count": len(results), "exports": results,
          "descriptionCharacters": len(description),
          "descriptionSHA256": hashlib.sha256((root / "description-en-US.txt").read_bytes()).hexdigest(),
          "manifestSHA256": hashlib.sha256((root / "manifest.json").read_bytes()).hexdigest(),
          "contactSheets": [{"file": f"{p}-sequence.png", "sha256": hashlib.sha256((root / f"{p}-sequence.png").read_bytes()).hexdigest()} for p in expected]}
if (root / "approved-hashes.json").exists():
    locked = json.loads((root / "approved-hashes.json").read_text())
    assert {item["file"]: item["sha256"] for item in results} == locked["exports"], "Approved image bytes changed"
    assert result["descriptionSHA256"] == locked["descriptionSHA256"], "Approved Description changed"
(root / "validation.json").write_text(json.dumps(result, indent=2) + "\n")
print(f"Validated {len(results)} opaque sRGB screenshots; Description {len(description)}/4000 characters.")
