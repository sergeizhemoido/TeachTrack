#!/usr/bin/env python3
"""Export the seven named UI-test attachments as App Store-ready PNG files."""

import argparse
import json
import shutil
import struct
import subprocess
import tempfile
from pathlib import Path


NAMES = (
    "01-organizations",
    "02-students",
    "03-calendar",
    "04-finance",
    "05-unpaid-balances",
    "06-lesson-history",
    "07-payment-history",
)
SIZES = {
    "iphone": (1320, 2868),
    "iphone-6.5": (1242, 2688),
    "ipad": (2064, 2752),
}


def png_info(path: Path) -> tuple[int, int, int]:
    with path.open("rb") as image:
        header = image.read(26)
    if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError(f"Not a PNG: {path}")
    width, height = struct.unpack(">II", header[16:24])
    return width, height, header[25]  # PNG color type; 4 and 6 have alpha.


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("result", type=Path, help="xcodebuild .xcresult bundle")
    parser.add_argument("device", choices=SIZES)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    with tempfile.TemporaryDirectory(prefix="teachtrack-screenshots-") as temporary:
        raw = Path(temporary)
        subprocess.run(
            ["xcrun", "xcresulttool", "export", "attachments", "--path", str(args.result),
             "--output-path", str(raw)],
            check=True,
        )
        manifest = json.loads((raw / "manifest.json").read_text())
        attachments = [item for test in manifest for item in test["attachments"]]
        selected = {}
        for attachment in attachments:
            name = attachment["suggestedHumanReadableName"]
            for expected in NAMES:
                if name.startswith(expected + "_"):
                    if expected in selected:
                        raise ValueError(f"Duplicate screenshot: {expected}")
                    selected[expected] = raw / attachment["exportedFileName"]
        if set(selected) != set(NAMES):
            raise ValueError(f"Expected {NAMES}; found {tuple(selected)}")

        args.output.mkdir(parents=True, exist_ok=True)
        for name in NAMES:
            source = selected[name]
            width, height, color_type = png_info(source)
            if (width, height) != SIZES[args.device] or color_type in (4, 6):
                raise ValueError(f"Invalid App Store PNG {name}: {width}x{height}, color type {color_type}")
            target = args.output / f"{name}.png"
            shutil.copy2(source, target)
            print(target)


if __name__ == "__main__":
    main()
