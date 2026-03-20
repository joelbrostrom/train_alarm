#!/usr/bin/env bash

set -euo pipefail

echo "Building Flutter web app (release + source maps)..."
flutter build web --release --source-maps 2>&1

echo "Deploying to Firebase Hosting..."
firebase deploy --only hosting

echo "Done."
