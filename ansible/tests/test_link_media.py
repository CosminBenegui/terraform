#!/usr/bin/env python3
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "roles/media_link/files"))
import link_media  # noqa: E402


class LinkMediaTests(unittest.TestCase):
    def test_api_key_is_read_from_config_xml(self):
        xml = "<Config><ApiKey>abc123</ApiKey></Config>"
        self.assertEqual(
            link_media.api_key_from_config_xml(xml),
            "abc123",
            "Radarr/Sonarr/Prowlarr API keys live in config.xml and must be reused, not regenerated",
        )

    def test_application_payload_points_at_docker_dns(self):
        schema = {
            "implementation": "Radarr",
            "implementationName": "Radarr",
            "configContract": "RadarrSettings",
            "fields": [
                {"name": "prowlarrUrl", "value": "http://localhost:9696"},
                {"name": "baseUrl", "value": ""},
                {"name": "apiKey", "value": ""},
                {"name": "syncCategories", "value": []},
            ],
        }
        body = link_media.build_arr_application(
            schema, "Radarr", "http://radarr:7878", "key", link_media.MOVIE_CATEGORIES
        )
        fields = {item["name"]: item["value"] for item in body["fields"]}
        self.assertEqual(
            fields["baseUrl"],
            "http://radarr:7878",
            "Prowlarr must call Radarr by container name, not localhost",
        )
        self.assertEqual(
            fields["prowlarrUrl"],
            "http://prowlarr:9696",
            "Radarr rejects localhost:9696 because that address is inside the Radarr container",
        )
        self.assertIn(2000, fields["syncCategories"], "Movie categories must include the Radarr default 2000")
        self.assertEqual(
            set(body["fields"][0].keys()),
            {"name", "value"},
            "Arr APIs reject schema metadata, so each field must be only name and value",
        )

    def test_seerr_accepts_a_wrapped_settings_payload(self):
        wrapped = {"radarr": [{"hostname": "radarr"}]}
        self.assertFalse(
            link_media.seerr_server_missing(wrapped, "radarr"),
            "Seerr sometimes returns servers under a radarr key instead of a bare list",
        )
        existing = [{"hostname": "radarr", "port": 7878}]
        self.assertFalse(
            link_media.seerr_server_missing(existing, "radarr"),
            "A second Seerr Radarr server must not be created when hostname radarr is already set",
        )

    def test_qbittorrent_client_uses_the_docker_hostname(self):
        schema = {
            "implementation": "QBittorrent",
            "implementationName": "qBittorrent",
            "configContract": "QBittorrentSettings",
            "fields": [
                {"name": "host", "value": "localhost"},
                {"name": "port", "value": 8080},
                {"name": "username", "value": ""},
                {"name": "password", "value": ""},
            ],
        }
        body = link_media.build_qbittorrent_client(schema, "secret", "radarr")
        fields = {item["name"]: item["value"] for item in body["fields"]}
        self.assertEqual(fields["host"], "qbittorrent", "Download client host must be the container name")
        self.assertEqual(fields["password"], "secret", "qBittorrent password must come from the host secret file")

    def test_qbit_password_falls_back_to_the_temporary_log_password(self):
        log = "The WebUI administrator password was not set. A temporary password is provided for this session: AbCd12"
        self.assertEqual(
            link_media.qbit_password_candidates(log),
            ["1234", "adminadmin", "AbCd12"],
            "qBittorrent must try 1234, the old default, then the temporary password from the container log",
        )


if __name__ == "__main__":
    unittest.main()
