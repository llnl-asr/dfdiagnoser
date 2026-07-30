API Reference
=============

This overview covers the main public modules of the ``dfdiagnoser`` package.

``dfdiagnoser`` (package)
-------------------------

The package root wires the Hydra config store, inputs, outputs, and the
diagnoser together.

- ``DFDiagnoserInstance`` — dataclass bundling a ``Diagnoser``, the Hydra
  config, and the configured input/output. Provides ``diagnose_file(path)``
  to diagnose an analyzer ``output=file`` bundle directory.
- ``InputType`` / ``OutputType`` — unions of the supported input
  (``FileInput``, ``CheckpointInput``, ``MofkaInput``, ``ZMQInput``) and
  output (``ConsoleOutput``, ``FileOutput``) dataclasses.

``dfdiagnoser.diagnoser``
-------------------------

- ``Diagnoser`` — the core engine: ingests fact envelopes, tracks each
  ``(fact_type, scope)`` along its temporal axis, and produces a
  ``DiagnosisResult``.
- ``TEMPORAL_VIEW_TYPES`` — views treated as longitudinal
  (``window``, ``epoch``, ``step``, ``time_range``).
- ``TEMPORAL_COORD`` — the longitudinal coordinate field per temporal view
  (e.g. ``window`` → ``window_index``, ``time_range`` → ``time_bucket``).

``dfdiagnoser.types``
---------------------

Wire/result dataclasses:

- ``TrendEvidence`` — ``prevalence``, ``persistence``, ``onset_window``,
  ``peak_severity_window``, ``last_seen_window``, ``support_windows``,
  ``trend_direction``.
- ``DiagnosisFinding`` — ``finding_type``, ``scope``, ``layer``, ``motif``,
  ``severity`` / ``severity_score``, ``confidence``, ``trend``,
  ``contributing_facts``, opportunity tags and recommendation bundle.
- ``DiagnosisResult`` — the full set of findings for a run.
- ``FileOutputFormat`` — ``"csv" | "json" | "parquet"``.

``dfdiagnoser.state``
---------------------

- ``FactObservation`` — one observation of a fact in one window
  (``window_index``, ``epoch``, ``severity_score``, evidence, tags).
- ``FactTracker`` — tracks all observations of one ``(fact_type, scope)``
  combination across windows.

``dfdiagnoser.trend``
---------------------

Trend detection strategies for longitudinal severity analysis:

- ``FixedWindowTrend`` (default) — compares mean severity of the last N
  observations against the preceding N.
- ``EWMATrend`` — exponentially weighted moving average of window-level
  severity scores.
- ``CUSUMTrend`` — Page's CUSUM change-point detector.
- ``get_trend_strategy(...)`` — factory selecting a ``TrendStrategy``.
- ``TrendDirection`` — ``"improving" | "worsening" | "stable" |
  "insufficient_data"``.

``dfdiagnoser.input`` / ``dfdiagnoser.output``
----------------------------------------------

Input dataclasses (Hydra-instantiated):

- ``FileInput(path)`` — offline, reads ``<path>/facts.jsonl`` from a
  DFAnalyzer ``output=file`` bundle.
- ``CheckpointInput(checkpoint_dir)`` — offline, derives facts from a
  DFAnalyzer checkpoint's flat views.
- ``MofkaInput`` / ``ZMQInput`` — online streaming transports
  (``dfdiagnoser.streaming.mofka_io`` / ``dfdiagnoser.streaming.zmq_io``).

Outputs:

- ``ConsoleOutput`` — rich tree/panel rendering of findings.
- ``FileOutput`` — writes findings as CSV / JSON / Parquet.

``dfdiagnoser.config``
----------------------

Hydra structured configs (``*Config`` dataclasses) for every input/output and
``init_hydra_config_store()`` registering them with the config store.
