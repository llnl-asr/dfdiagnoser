# Migration Plan: dfdiagnoser

Selected: 2026-07-30. Source: git@github.com:llnl/dfdiagnoser.git (default branch **main**). Target: ssh://git@czgitlab.llnl.gov:7999/dftracer/dfdiagnoser.git (repo exists on czgitlab).

## Findings

- One workflow: `.github/workflows/ci.yml` ("Build and Test") — matrix
  ubuntu-22.04 x python 3.9–3.12 via astral-sh/setup-uv, `uv sync --all-extras
  --dev`, pytest `-m smoke` (or `-m full` on `v*.*.*` tags / manual dispatch),
  then a `dfdiagnoser input=file ... output=file` CLI run. No publish/docker
  workflows.
- No `docs/` existed — authored fresh host-neutral Sphinx docs (conf.py with
  rtd→alabaster fallback, index.rst, introduction.rst, api.rst,
  requirements.txt), content sourced from README + package modules.
- Dependencies: all third-party PyPI (hydra-core, pandas, rich, structlog, …;
  optional `dftracer-analyzer` via plain PyPI version spec); `spack.yaml` repos
  are third-party (mochi-hpc, diaspora). **No in-place GitLab URL switches
  needed.** README/docs `github.com/LLNL/*` links are prose, untouched.

## Steps

1. [x] Fresh clone (main)
2. [x] gitlab remote added + verified
3. [x] CI: converted ci.yml → `.gitlab-ci.yml` on `.corona-batch` (modules +
   venv + pip instead of uv/setup-python; matrix collapsed to module toolchain
   with comment; tag→full / else smoke logic kept; CLI run kept; rules push +
   merge_request_event). No publish jobs existed to gate.
4. [x] Docs: authored `docs/` + `pages` job (corona batch, rules main +
   temporary gitlab-migration)
5. [x] In-place URL switch: **none needed** (see Findings); REVERT.md updated
   with a dfdiagnoser "no in-place changes" bullet
6. [x] Local tests (see below)
7. [x] Commit on gitlab-migration; `.migration/` synced into repo
8. [x] Push gitlab main, --tags, gitlab-migration
9. [x] Pipeline: <https://czgitlab.llnl.gov/dftracer/dfdiagnoser/-/pipelines>
10. [ ] User merges gitlab-migration → main after green pipeline (then remove
    the temporary gitlab-migration rule from the pages job)

## Local test results (2026-07-30)

- `yaml.safe_load('.gitlab-ci.yml')` — OK
- `sphinx-build -b html docs <scratch>` — "build succeeded"
- venv `pip install -e ".[streaming]" pytest dftracer-analyzer` then
  `pytest -q -m smoke tests/` — **10 passed, 2 skipped, 41 deselected** (skips
  are mofka-transport tests, unavailable locally)
- CLI smoke `dfdiagnoser input=file input.path=tests/data/facts_bundle
  output=file output.output_format=json` — succeeded

## Executed changes (what to undo on revert)

- Remote `gitlab` = ssh://git@czgitlab.llnl.gov:7999/dftracer/dfdiagnoser.git
- Branch `gitlab-migration` from main @ 6a1be773a938b1d91f059b681f4914cab690f6f7,
  adding only: `.gitlab-ci.yml`, `docs/` (5 new files),
  `.migration/REVERT.md`, `.migration/dfdiagnoser.md`
- Commit SHA(s): recorded in status log below
- Pushed to gitlab: `main`, tags (if any), `gitlab-migration`
- `.github/` untouched; nothing pushed to origin; no in-place source edits

## Status log

- 2026-07-30: cloned, remote added, plan created.
- 2026-07-30: CI converted, docs authored, local tests green, no dep URL
  switches needed, committed on gitlab-migration and pushed main +
  gitlab-migration to czgitlab. Awaiting pipeline + user merge.
