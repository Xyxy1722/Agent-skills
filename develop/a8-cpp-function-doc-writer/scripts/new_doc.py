#!/usr/bin/env python3

import argparse
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(
        description="Create a new Markdown skeleton for RTFA function analysis docs."
    )
    parser.add_argument("--function-id", required=True, help="Function number, such as 83300100")
    parser.add_argument("--function-name", required=True, help="Entry function or short flow name")
    parser.add_argument("--output", required=True, help="Output Markdown file path")
    return parser.parse_args()


def render_template(function_id: str, function_name: str) -> str:
    return f"""# {function_id}-{function_name}

## Summary

- TODO: summarize the function or business flow.

## Involved tables

- TODO

## Involved macros / enums

- TODO

## Entry

- {function_name} -> `TODO:path:line`

## Procedure

- {function_name} -> `TODO:path:line`

## Key checks

- TODO

## Bottom-level methods

- TODO

## TODO

- TODO
"""


def main():
    args = parse_args()
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(
        render_template(args.function_id, args.function_name), encoding="utf-8"
    )


if __name__ == "__main__":
    main()
