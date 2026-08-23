#!/usr/bin/env python3
"""Validate GCS Terraform state bucket JSON from `gcloud storage buckets describe --format=json`."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    sys.exit(1)


def load_json(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"bucket-config.json is not valid JSON: {exc}")
    if not isinstance(data, dict):
        fail("bucket-config.json must be a JSON object")
    return data


def main() -> None:
    if len(sys.argv) != 3:
        fail("usage: validate-gcs-bucket.py <bucket-config.json> <expected-region>")

    config_path = Path(sys.argv[1])
    expected_region = sys.argv[2].strip().lower()
    if not config_path.is_file():
        fail(f"missing file {config_path}")

    data = load_json(config_path)
    print("Parsed gcloud JSON keys:")
    print(", ".join(sorted(data.keys())))

    # Fields confirmed from:
    # gcloud storage buckets describe gs://gcp-dev-july-2026-terraform-state --format=json
    if "location" not in data:
        fail("Could not determine bucket location from gcloud bucket configuration.")
    location = str(data["location"]).strip()
    print("Bucket location:")
    print(location)
    if location.lower() != expected_region:
        fail(f"location must be {expected_region}, found {location}")

    if "uniform_bucket_level_access" not in data:
        fail(
            "Could not determine Uniform Bucket-Level Access "
            "from gcloud bucket configuration."
        )
    ubla = data["uniform_bucket_level_access"]
    print("Uniform Bucket-Level Access:")
    if ubla is True:
        print("ENABLED")
    else:
        print(repr(ubla))
        fail("Uniform Bucket-Level Access must be enabled (JSON true).")

    if "public_access_prevention" not in data:
        fail(
            "Could not determine Public Access Prevention "
            "from gcloud bucket configuration."
        )
    pap = str(data["public_access_prevention"]).strip()
    print("Public Access Prevention:")
    print(pap.upper())
    if pap.lower() != "enforced":
        fail("Public Access Prevention must be enforced.")

    print("Terraform state bucket validation: PASSED")


if __name__ == "__main__":
    main()
