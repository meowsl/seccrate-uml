#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
java -jar plantuml.jar -charset UTF-8 -tpng *.puml
java -jar plantuml.jar -charset UTF-8 -tsvg *.puml
echo "Готово"
