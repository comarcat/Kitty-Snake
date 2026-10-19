#!/usr/bin/env bash
# Serve the Web build locally (file:// does not work). Open http://localhost:8080
cd "$(dirname "$0")/../builds/web" && python3 -m http.server 8080
