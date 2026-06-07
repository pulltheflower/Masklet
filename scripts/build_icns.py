from io import BytesIO
from pathlib import Path
import struct

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "Resources" / "Icons" / "AppIcon.png"
OUTPUT = ROOT / "Resources" / "Icons" / "AppIcon.icns"

CHUNKS = [
    ("icp4", 16),
    ("icp5", 32),
    ("icp6", 64),
    ("ic07", 128),
    ("ic08", 256),
    ("ic09", 512),
    ("ic10", 1024),
]


def png_bytes(image: Image.Image, size: int) -> bytes:
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    buffer = BytesIO()
    resized.save(buffer, format="PNG")
    return buffer.getvalue()


def main() -> None:
    image = Image.open(SOURCE).convert("RGBA")
    chunks = []

    for chunk_type, size in CHUNKS:
        data = png_bytes(image, size)
        chunks.append(chunk_type.encode("ascii") + struct.pack(">I", len(data) + 8) + data)

    body = b"".join(chunks)
    OUTPUT.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)
    print(OUTPUT)


if __name__ == "__main__":
    main()
