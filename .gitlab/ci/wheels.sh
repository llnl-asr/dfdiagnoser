#!/bin/bash
# Builds the sdist and pure-python wheel into wheelhouse/, versioned
# .postN.dev0 like the sibling repos. No tags here, so N counts from the root.
set -eo pipefail
cd "$CI_PROJECT_DIR"

base=$(sed -n 's/^version = "\(.*\)"/\1/p' pyproject.toml | head -1)
[ -n "$base" ] || { echo "ERROR: no version in pyproject.toml"; exit 1; }

if described=$(git describe --tags --long --match 'v*' 2>/dev/null); then
  tag=${described%-*-g*}
  distance=${described#"$tag"-}
  distance=${distance%-g*}
  base=${tag#v}
else
  distance=$(git rev-list --count HEAD)
fi

if [ "$distance" = "0" ]; then
  VERSION="$base"
else
  VERSION="$base.post$distance.dev0"
fi
echo "building version $VERSION"

# hatchling offers no version override, and the checkout is disposable.
sed -i "s/^version = \".*\"/version = \"$VERSION\"/" pyproject.toml

PODMAN_STORE=/var/tmp/$USER/podman-root
PODMAN_RUNROOT=/var/tmp/$USER/podman-run
mkdir -p "$PODMAN_STORE" "$PODMAN_RUNROOT"

rm -rf wheelhouse
podman --root "$PODMAN_STORE" --runroot "$PODMAN_RUNROOT" run --rm --user 0:0 \
  -v "$PWD:/ws" -w /ws \
  docker.io/library/python:3.11 bash -ec '
    pip install --quiet --upgrade pip build
    python3 -m build --outdir wheelhouse .
  '
git checkout -- pyproject.toml
ls -1 wheelhouse
