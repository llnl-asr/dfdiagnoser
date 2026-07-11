"""Tests for the checkpoint path: `diagnose_checkpoint` / `input=checkpoint`.

Fact-deriving tests run the CLI in a subprocess: importing ``dftracer.analyzer``
registers its Hydra ConfigStore as a side-effect, which would clobber
dfdiagnoser's compose in-process. Guardrail cases raise before that import and
run in-process.
"""
import json
import os
import pathlib
import subprocess
import sys

import pytest

from dfdiagnoser.diagnoser import Diagnoser

pytestmark = [pytest.mark.smoke, pytest.mark.full]

CHECKPOINT_DIR = (
    pathlib.Path(__file__).parent
    / "data" / "dfanalyzer_checkpoints" / "unet3d_v100"
)


def _metric_builder_available() -> bool:
    # Probe in a subprocess: importing dftracer.analyzer registers its Hydra
    # ConfigStore, which would break dfdiagnoser's compose in this process.
    return subprocess.run(
        [sys.executable, "-c",
         "from dftracer.analyzer.fact_engine import MetricFactBuilder"],
        capture_output=True,
    ).returncode == 0


_analyzer = pytest.mark.skipif(
    not _metric_builder_available(),
    reason="dftracer.analyzer MetricFactBuilder not installed (dfanalyzer PR #61)",
)


@_analyzer
def test_cli_checkpoint_to_findings(tmp_path: pathlib.Path) -> None:
    """input=checkpoint derives facts from the flat views and writes findings.jsonl,
    mirroring the input=file bundle path."""
    out_dir = tmp_path / "out"
    run_dir = tmp_path / "run"

    proc = subprocess.run(
        [sys.executable, "-m", "dfdiagnoser",
         "input=checkpoint", f"input.checkpoint_dir={CHECKPOINT_DIR}",
         "output=file", f"output.output_dir={out_dir}",
         f"hydra.run.dir={run_dir}"],
        capture_output=True, text=True,
    )
    assert proc.returncode == 0, proc.stderr

    findings_path = out_dir / "findings.jsonl"
    assert findings_path.exists(), proc.stderr
    records = [json.loads(line) for line in findings_path.read_text().splitlines()]
    assert records, "no findings derived from checkpoint"
    assert all(r["finding_type"].endswith("_ops_slope") for r in records)


@_analyzer
def test_cli_checkpoint_console_output(tmp_path: pathlib.Path) -> None:
    run_dir = tmp_path / "run"
    proc = subprocess.run(
        [sys.executable, "-m", "dfdiagnoser",
         "input=checkpoint", f"input.checkpoint_dir={CHECKPOINT_DIR}",
         "output=console", f"hydra.run.dir={run_dir}"],
        capture_output=True, text=True,
        env={**os.environ, "COLUMNS": "200"},
    )
    assert proc.returncode == 0, proc.stderr
    assert "_ops_slope" in proc.stdout


def test_diagnose_checkpoint_missing_dir_raises() -> None:
    with pytest.raises(FileNotFoundError):
        Diagnoser().diagnose_checkpoint("/nonexistent/checkpoint/dir")


def test_diagnose_checkpoint_no_flat_views_raises(tmp_path: pathlib.Path) -> None:
    empty = tmp_path / "empty_ckpt"
    empty.mkdir()
    with pytest.raises(ValueError, match="_flat_view_"):
        Diagnoser().diagnose_checkpoint(str(empty))
