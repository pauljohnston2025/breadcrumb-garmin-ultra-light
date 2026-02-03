#!/usr/bin/env python3

# run in <homedir>/AppData/Roaming/Garmin/ConnectIQ/Devices/ directory

import json
from pathlib import Path

# Set 1: The 64-color palette
PALETTE_64 = {
    "000000", "000055", "0000AA", "0000FF", "005500", "005555", "0055AA", "0055FF",
    "00AA00", "00AA55", "00AAAA", "00AAFF", "00FF00", "00FF55", "00FFAA", "00FFFF",
    "550000", "550055", "5500AA", "5500FF", "555500", "555555", "5555AA", "5555FF",
    "55AA00", "55AA55", "55AAAA", "55AAFF", "55FF00", "55FF55", "55FFAA", "55FFFF",
    "AA0000", "AA0055", "AA00AA", "AA00FF", "AA5500", "AA5555", "AA55AA", "AA55FF",
    "AAAA00", "AAAA55", "AAAAAA", "AAAAFF", "AAFF00", "AAFF55", "AAFFAA", "AAFFFF",
    "FF0000", "FF0055", "FF00AA", "FF00FF", "FF5500", "FF5555", "FF55AA", "FF55FF",
    "FFAA00", "FFAA55", "FFAAAA", "FFAAFF", "FFFF00", "FFFF55", "FFFFAA", "FFFFFF"
}

# Set 2: The 16-color MIP palette
PALETTE_16 = {
    "FFFFFF", "AAAAAA", "555555", "000000", "FF0000", "AA0000", 
    "FF5500", "FF00FF", "FFAA00", "5500AA", "00FF00", "00AA00", 
    "00AAFF", "0000FF"
}

def parse_garmin_configs(root_dir='.'):
    pathlist = Path(root_dir).rglob('compiler.json')
    
    for path in pathlist:
        try:
            with open(path, 'r') as f:
                data = json.load(f)
                
                device_id = data.get('deviceId')
                palette = data.get('palette', {})
                # Filter out 'TRANSPARENT' if it exists to compare only hex codes
                colors = [c for c in palette.get('colors', []) if c != "TRANSPARENT"]
                color_set = set(colors)

                # Skip if:
                # 1. No palette exists
                # 2. It matches the 64-color set
                # 3. It matches the 16-color set
                if not colors or color_set == PALETTE_64 or color_set == PALETTE_16:
                    continue

                print(f"Device: {device_id}")
                print(f"Palette: {', '.join(palette.get('colors', []))}")
                print("-" * 30)
                    
        except (json.JSONDecodeError, IOError):
            continue

if __name__ == "__main__":
    parse_garmin_configs()