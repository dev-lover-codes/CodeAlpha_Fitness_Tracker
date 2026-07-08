#!/bin/bash
set -e

echo "Running flutter analyze..."
flutter analyze

echo "Running flutter test..."
flutter test --coverage

echo "Tests passed successfully!"
