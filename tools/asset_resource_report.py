#!/usr/bin/env python3
from __future__ import annotations

from asset_preview_pipeline import build_resource_report_lines


def main() -> None:
    print("\n".join(build_resource_report_lines()))


if __name__ == "__main__":
    main()
