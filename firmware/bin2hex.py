#!/usr/bin/env python3
"""
Convert binary firmware image into 32-bit Verilog $readmemh hex format.
Usage: python3 bin2hex.py <input.bin> <output.hex> [mem_words]
"""
import sys

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 bin2hex.py <input.bin> <output.hex> [mem_words]")
        sys.exit(1)

    bin_path = sys.argv[1]
    hex_path = sys.argv[2]
    mem_words = int(sys.argv[3]) if len(sys.argv) > 3 else 16384 # 64 KB default

    with open(bin_path, "rb") as f:
        data = f.read()

    # Pad data to multiple of 4 bytes
    remainder = len(data) % 4
    if remainder != 0:
        data += b"\x00" * (4 - remainder)

    words = []
    for i in range(0, len(data), 4):
        chunk = data[i:i+4]
        word = int.from_bytes(chunk, byteorder="little")
        words.append(f"{word:08x}")

    with open(hex_path, "w") as f:
        for w in words:
            f.write(w + "\n")

    print(f"Generated {hex_path} with {len(words)} words ({len(data)} bytes).")

if __name__ == "__main__":
    main()
