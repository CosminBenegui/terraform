#!/usr/bin/env python3
"""Link Prowlarr, Radarr, Sonarr, Seerr, and qBittorrent. Idempotent."""

import json
import re
import subprocess
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

MOVIE_CATEGORIES = [2000, 2010, 2020, 2030, 2040, 2045, 2050, 2060, 2070, 2080]
TV_CATEGORIES = [5000, 5010, 5020, 5030, 5040, 5045, 5050, 5060, 5070, 5080]
QBIT_PASSWORD = "1234"
TEMP_QBIT_PASSWORD = re.compile(r"temporary password.*?:\s*(\S+)", re.IGNORECASE)


def api_key_from_config_xml(xml_text):
    root = ET.fromstring(xml_text)
    node = root.find("ApiKey")
    if node is None or not (node.text or "").strip():
        raise ValueError("config.xml has no ApiKey")
    return node.text.strip()


def set_field_values(fields, values):
    updated = []
    for field in fields:
        item = dict(field)
        if item.get("name") in values:
            item["value"] = values[item["name"]]
        updated.append(item)
    return updated


def build_arr_application(schema_entry, name, base_url, api_key, categories):
    return {
        "name": name,
        "implementation": schema_entry["implementation"],
        "implementationName": schema_entry["implementationName"],
        "configContract": schema_entry["configContract"],
        "syncLevel": "fullSync",
        "fields": public_fields(
            set_field_values(
                schema_entry["fields"],
                {
                    "baseUrl": base_url,
                    "apiKey": api_key,
                    "syncCategories": categories,
                },
            )
        ),
    }


def build_qbittorrent_client(schema_entry, password, category):
    return {
        "name": "qBittorrent",
        "implementation": schema_entry["implementation"],
        "implementationName": schema_entry["implementationName"],
        "configContract": schema_entry["configContract"],
        "enable": True,
        "fields": public_fields(
            set_field_values(
                schema_entry["fields"],
                {
                    "host": "qbittorrent",
                    "port": 8080,
                    "username": "admin",
                    "password": password,
                    "category": category,
                },
            )
        ),
    }


def public_fields(fields):
    return [{"name": field["name"], "value": field.get("value")} for field in fields if field.get("name")]


def server_rows(payload):
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if isinstance(payload, dict):
        for key in ("radarr", "sonarr"):
            value = payload.get(key)
            if isinstance(value, list):
                return [item for item in value if isinstance(item, dict)]
    return []


def seerr_server_missing(existing, hostname):
    return not any(item.get("hostname") == hostname for item in server_rows(existing))


def temporary_qbit_password(log_text):
    found = TEMP_QBIT_PASSWORD.findall(log_text)
    return found[-1] if found else ""


def qbit_password_candidates(log_text, preferred=QBIT_PASSWORD):
    ordered = [preferred, "adminadmin", temporary_qbit_password(log_text)]
    candidates = []
    for item in ordered:
        if item and item not in candidates:
            candidates.append(item)
    return candidates


def qbit_login(base_url, username, password):
    data = urllib.parse.urlencode({"username": username, "password": password}).encode()
    request = urllib.request.Request(
        base_url + "/api/v2/auth/login",
        data=data,
        headers={"Referer": base_url + "/"},
    )
    try:
        with urllib.request.urlopen(request, timeout=15) as response:
            body = response.read().decode()
            cookie = response.headers.get("Set-Cookie", "")
    except urllib.error.URLError:
        return ""
    if "Ok" not in body:
        return ""
    for part in cookie.split(";"):
        if part.strip().startswith("SID="):
            return part.strip()
    return ""


def qbit_set_password(base_url, sid, password):
    data = urllib.parse.urlencode({"json": json.dumps({"web_ui_password": password})}).encode()
    request = urllib.request.Request(
        base_url + "/api/v2/app/setPreferences",
        data=data,
        headers={"Cookie": sid, "Referer": base_url + "/"},
    )
    with urllib.request.urlopen(request, timeout=15):
        return


def ensure_qbit_password(base_url, log_text, preferred=QBIT_PASSWORD):
    session = ""
    for candidate in qbit_password_candidates(log_text, preferred):
        session = qbit_login(base_url, "admin", candidate)
        if session:
            if candidate != preferred:
                try:
                    qbit_set_password(base_url, session, preferred)
                except urllib.error.URLError:
                    return ""
            return preferred
    return ""


def container_ip(name):
    output = subprocess.check_output(
        [
            "docker",
            "inspect",
            "-f",
            "{{range $name, $net := .NetworkSettings.Networks}}{{println $net.IPAddress}}{{end}}",
            name,
        ],
        text=True,
    )
    ips = [line.strip() for line in output.splitlines() if line.strip()]
    if not ips:
        raise RuntimeError(f"{name} has no IP")
    return ips[0]


def container_file(name, path):
    return subprocess.check_output(["docker", "exec", name, "cat", path], text=True)


class Api:
    def __init__(self, base_url, api_key):
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key

    def request(self, method, path, body=None):
        data = None if body is None else json.dumps(body).encode()
        req = urllib.request.Request(
            self.base_url + path,
            data=data,
            method=method,
            headers={"X-Api-Key": self.api_key, "Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=20) as response:
                raw = response.read().decode()
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode(errors="replace")
            raise RuntimeError(f"{method} {path} failed: {exc.code} {detail}") from exc
        return json.loads(raw) if raw else None


def schema_named(schemas, implementation):
    for entry in schemas:
        if entry.get("implementation") == implementation:
            return entry
    raise RuntimeError(f"schema {implementation} not found")


def upsert_named(api, collection_path, body):
    current = api.request("GET", collection_path) or []
    for item in current:
        if item.get("name") == body["name"]:
            body["id"] = item["id"]
            api.request("PUT", f"{collection_path}/{item['id']}", body)
            return "updated"
    api.request("POST", collection_path, body)
    return "created"


def ensure_root_folder(api, path):
    folders = api.request("GET", "/rootfolder") or []
    if any(item.get("path") == path for item in folders):
        return "present"
    api.request("POST", "/rootfolder", {"path": path})
    return "created"


def link(qbit_password):
    radarr_key = api_key_from_config_xml(container_file("radarr", "/config/config.xml"))
    sonarr_key = api_key_from_config_xml(container_file("sonarr", "/config/config.xml"))
    prowlarr_key = api_key_from_config_xml(container_file("prowlarr", "/config/config.xml"))

    prowlarr = Api(f"http://{container_ip('prowlarr')}:9696/api/v1", prowlarr_key)
    radarr = Api(f"http://{container_ip('radarr')}:7878/api/v3", radarr_key)
    sonarr = Api(f"http://{container_ip('sonarr')}:8989/api/v3", sonarr_key)

    app_schema = prowlarr.request("GET", "/applications/schema")
    results = {
        "prowlarr-radarr": upsert_named(
            prowlarr,
            "/applications",
            build_arr_application(
                schema_named(app_schema, "Radarr"),
                "Radarr",
                "http://radarr:7878",
                radarr_key,
                MOVIE_CATEGORIES,
            ),
        ),
        "prowlarr-sonarr": upsert_named(
            prowlarr,
            "/applications",
            build_arr_application(
                schema_named(app_schema, "Sonarr"),
                "Sonarr",
                "http://sonarr:8989",
                sonarr_key,
                TV_CATEGORIES,
            ),
        ),
        "radarr-root": ensure_root_folder(radarr, "/movies"),
        "sonarr-root": ensure_root_folder(sonarr, "/tv"),
    }

    desired_qbit_password = qbit_password or QBIT_PASSWORD
    qbit_base = f"http://{container_ip('qbittorrent')}:8080"
    qbit_logs = subprocess.check_output(
        ["docker", "logs", "qbittorrent"],
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
    )
    if ensure_qbit_password(qbit_base, qbit_logs, desired_qbit_password):
        for label, api in (("radarr-qbit", radarr), ("sonarr-qbit", sonarr)):
            schemas = api.request("GET", "/downloadclient/schema")
            results[label] = upsert_named(
                api,
                "/downloadclient",
                build_qbittorrent_client(
                    schema_named(schemas, "QBittorrent"),
                    desired_qbit_password,
                    "radarr" if label.startswith("radarr") else "tv-sonarr",
                ),
            )
    else:
        results["qbit"] = "skipped-no-login"

    try:
        settings = json.loads(container_file("seerr", "/app/config/settings.json"))
        seerr_key = settings["main"]["apiKey"]
        seerr = Api(f"http://{container_ip('seerr')}:5055/api/v1", seerr_key)
        for label, path, hostname, port, key, root in (
            ("seerr-radarr", "/settings/radarr", "radarr", 7878, radarr_key, "/movies"),
            ("seerr-sonarr", "/settings/sonarr", "sonarr", 8989, sonarr_key, "/tv"),
        ):
            existing = server_rows(seerr.request("GET", path))
            if not seerr_server_missing(existing, hostname):
                results[label] = "present"
                continue
            seerr.request(
                "POST",
                path,
                {
                    "name": hostname,
                    "hostname": hostname,
                    "port": port,
                    "apiKey": key,
                    "useSsl": False,
                    "baseUrl": "",
                    "activeProfileId": 1,
                    "activeDirectory": root,
                    "is4k": False,
                    "isDefault": True,
                },
            )
            results[label] = "created"
    except (subprocess.CalledProcessError, KeyError, json.JSONDecodeError, urllib.error.URLError, RuntimeError, TypeError) as exc:
        results["seerr"] = f"skipped-until-wizard: {exc}"

    return results


def main():
    password = QBIT_PASSWORD
    try:
        text = open("/home/cosmin/.config/lab/secrets.env", encoding="utf-8").read()
    except OSError:
        text = ""
    for line in text.splitlines():
        if line.startswith("QBIT_PASSWORD="):
            password = line.split("=", 1)[1].strip()
    print(json.dumps(link(password), indent=2))


if __name__ == "__main__":
    main()
