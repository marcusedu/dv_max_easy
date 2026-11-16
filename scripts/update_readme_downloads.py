#!/usr/bin/env python3
"""Substitui o bloco de downloads do README pelos arquivos em dist/."""

from __future__ import annotations

import argparse
import sys
import urllib.parse
from pathlib import Path

START = "<!-- downloads:start -->"
END = "<!-- downloads:end -->"

PLATFORMS = ("macOS", "Windows", "Linux")


def platform_of(name: str) -> str | None:
    if name.endswith(".dmg"):
        return "macOS"
    if name.endswith(".msi") or name.endswith(".zip"):
        return "Windows"
    if name.endswith(".deb") or name.endswith(".tar.gz") or name.endswith(".AppImage"):
        return "Linux"
    return None


def rank(name: str) -> int:
    order = (".msi", ".zip", ".deb", ".tar.gz", ".AppImage", ".dmg")
    for index, suffix in enumerate(order):
        if name.endswith(suffix):
            return index
    return len(order)


def version_of(name: str) -> str | None:
    prefix = "DV_Max_"
    if not name.startswith(prefix):
        return None
    rest = name[len(prefix) :]
    parts = rest.split("_", 1)[0].split(".")
    if len(parts) < 3 or not all(part.isdigit() for part in parts[:3]):
        return None
    return ".".join(parts[:3])


def asset_url(repo: str, tag: str, name: str) -> str:
    quoted_tag = urllib.parse.quote(tag, safe="")
    quoted_name = urllib.parse.quote(name, safe="")
    return f"https://github.com/{repo}/releases/download/{quoted_tag}/{quoted_name}"


def render(files: list[Path], version: str, repo: str, tag: str) -> str:
    grouped: dict[str, list[Path]] = {platform: [] for platform in PLATFORMS}
    for path in files:
        platform = platform_of(path.name)
        if platform is None:
            continue
        grouped[platform].append(path)

    lines = [
        START,
        f"Versão **{version}**.",
        "",
        "| Sistema | Arquivo |",
        "| :--- | :--- |",
    ]
    for platform in PLATFORMS:
        entries = sorted(grouped[platform], key=lambda path: (rank(path.name), path.name))
        if not entries:
            raise SystemExit(f"Nenhum arquivo de {platform} em dist/.")
        links = " · ".join(
            f"[{path.name}]({asset_url(repo, tag, path.name)})" for path in entries
        )
        lines.append(f"| {platform} | {links} |")
    lines.append(END)
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--readme", default="README.md")
    parser.add_argument("--dist", default="dist")
    parser.add_argument("--tag")
    parser.add_argument("--repo")
    parser.add_argument("--version-only", action="store_true")
    args = parser.parse_args()

    files = sorted(path for path in Path(args.dist).iterdir() if path.is_file())
    versions = {version_of(path.name) for path in files if platform_of(path.name)}
    versions.discard(None)
    if len(versions) != 1:
        raise SystemExit(f"A versão dos arquivos em dist/ não é única: {sorted(versions)}")
    version = next(iter(versions))
    if args.version_only:
        print(version)
        return 0
    if not args.tag or not args.repo:
        raise SystemExit("Informe --tag e --repo.")

    readme = Path(args.readme)
    text = readme.read_text(encoding="utf-8")
    if START not in text or END not in text or text.index(START) > text.index(END):
        raise SystemExit("Marcadores <!-- downloads:start/end --> não encontrados no README.")

    block = render(files, version, args.repo, args.tag)
    pre, rest = text.split(START, 1)
    _, post = rest.split(END, 1)
    updated = pre + block + post
    if updated != text:
        readme.write_text(updated, encoding="utf-8")
        print(f"README atualizado para {version}")
    else:
        print(f"README já apontava para {version}")
    print(version)
    return 0


if __name__ == "__main__":
    sys.exit(main())
