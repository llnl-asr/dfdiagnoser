#!/bin/bash
# Runs ON the allocated compute node (via
#   flux proxy <jobid> flux run -N 1 bash .gitlab/ci/build-test-docs.sh)
# inside podman containers mirroring the GitHub Actions python environment.
# TEST_TYPE is computed by the CI job (tag => full, otherwise smoke).
set -ex

TEST_TYPE=${TEST_TYPE:-smoke}

PODMAN_STORE=/var/tmp/$USER/podman-root
PODMAN_RUNROOT=/var/tmp/$USER/podman-run
mkdir -p "$PODMAN_STORE" "$PODMAN_RUNROOT"
PODMAN="podman --root $PODMAN_STORE --runroot $PODMAN_RUNROOT"

# --user 0:0: container root maps to the host user under rootless podman, so
# the bind-mounted checkout stays readable even for images with a non-root USER.

# The checkpoint extra pulls dftracer-analyzer from czgitlab over ssh, so the
# container needs the runner account's ssh keys (read-only mount).
$PODMAN run --rm --user 0:0 -v "$PWD:/ws" -w /ws \
  -v "$HOME/.ssh:/root/.ssh:ro" \
  -e GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" \
  -e TEST_TYPE="$TEST_TYPE" \
  docker.io/library/python:3.11 bash -ec '
  apt-get -o APT::Sandbox::User=root update -qq
  apt-get -o APT::Sandbox::User=root install -y -qq openssh-client git
  pip install --quiet --upgrade pip
  pip install --quiet -e ".[streaming,checkpoint]" pytest
  pytest -v -m "$TEST_TYPE" tests/
  dfdiagnoser input=file input.path=/ws/tests/data/facts_bundle output=file output.output_format=json
'

$PODMAN run --rm --user 0:0 -v "$PWD:/ws" -w /ws \
  -v "$HOME/.ssh:/root/.ssh:ro" \
  -e GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" \
  docker.io/library/python:3.11 bash -ec '
  apt-get -o APT::Sandbox::User=root update -qq
  apt-get -o APT::Sandbox::User=root install -y -qq openssh-client git
  pip install --quiet --upgrade pip
  pip install --quiet -r docs/requirements.txt
  pip install --quiet -e .
  sphinx-build -b html docs public
'
