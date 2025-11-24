#!/usr/bin/env sh
# Create a local venv, install backend requirements and run tests non-interactively.
# Usage (fish shell or bash):
#   sh backend/run_tests_in_venv.sh
set -e

# Create virtualenv in backend/.venv
python -m venv backend/.venv

# Use the venv's python to upgrade pip and install requirements
backend/.venv/bin/python -m pip install --upgrade pip
backend/.venv/bin/python -m pip install -r backend/requirements.txt

# Run pytest in the backend tests directory
backend/.venv/bin/pytest -q backend/tests
