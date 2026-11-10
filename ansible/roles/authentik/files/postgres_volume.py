#!/usr/bin/env python3
"""Remove an Authentik Postgres volume mounted at the path Postgres 18 rejects."""

import json
import subprocess

OLD_DATA_PATH = "/var/lib/postgresql/data"


def legacy_volume_name(mounts):
    for mount in mounts:
        if mount.get("Destination") == OLD_DATA_PATH and mount.get("Name"):
            return mount["Name"]
    return ""


def main():
    try:
        raw = subprocess.check_output(["docker", "inspect", "authentik-postgresql"], text=True)
    except subprocess.CalledProcessError:
        return
    data = json.loads(raw)
    if not data:
        return
    name = legacy_volume_name(data[0].get("Mounts", []))
    if not name:
        return
    subprocess.check_call(["docker", "rm", "-f", "authentik-postgresql"])
    subprocess.check_call(["docker", "volume", "rm", name])
    print(f"removed {name}")


if __name__ == "__main__":
    main()
