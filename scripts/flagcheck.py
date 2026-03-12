#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import sys


def derive_flag(seed: str, flag_id: str) -> str:
    # Deterministic, rotating flags: rotate by changing the seed (per lab deploy).
    # Validation does not require revealing the expected value unless requested.
    payload = f"{seed.strip()}:{flag_id.strip()}".encode("utf-8")
    digest = hashlib.sha256(payload).hexdigest()[:32]
    return f"NYXERA{{{flag_id}:{digest}}}"


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Validate lab-only rotating flags (deterministic from a per-lab seed)."
    )
    ap.add_argument("--seed", required=True, help="Per-lab secret seed (from terraform output).")
    ap.add_argument("--id", required=True, dest="flag_id", help="Flag identifier (e.g. APT29-L2).")
    ap.add_argument("--flag", required=True, help="Captured flag value to validate.")
    ap.add_argument(
        "--show-expected",
        action="store_true",
        help="Print the expected flag (debugging / lab authoring only).",
    )
    args = ap.parse_args()

    expected = derive_flag(args.seed, args.flag_id)
    ok = args.flag.strip() == expected

    if args.show_expected:
        print(expected)

    if ok:
        print("OK")
        return 0

    print("NOPE", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
