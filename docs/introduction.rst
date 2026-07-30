Introduction
============

DFDiagnoser consumes ``analyzer.fact-envelope.v1`` facts emitted by
`DFAnalyzer <https://github.com/LLNL/dfanalyzer>`_ — one per analysis window per
view — and summarizes each ``(fact_type, scope)`` along its temporal axis into
**diagnosis findings** that answer: *is this bottleneck persistent, getting
worse, where, and what class of fix does it call for?* The findings feed
`DFOptimizer <https://github.com/LLNL/dfoptimizer>`_. It runs identically
**offline** (replaying a saved fact bundle) and **online** (consuming a live
stream over Mofka or ZMQ).

Features
--------

- **Pure fact consumer**: scoring and fact-building live in the analyzer;
  DFDiagnoser only tracks trajectories.
- Per ``(fact_type, scope)`` trajectory summary:

  - **persistence** — longest run of consecutive windows the fact appears in
  - **prevalence** — fraction of windows it appears in
  - **trend** — improving / stable / worsening (fixed-window, EWMA, or CUSUM
    strategies)
  - **motif** — classified pattern (e.g. ``persistent_pressure``,
    ``metadata_bound``, ``warmup_transient``)
  - **recommendation_bundle** and **opportunity_tags** — the class of fix
    (e.g. ``input_pipeline_tuning``)

- Temporal views (``window`` online; ``epoch``/``step``/``time_range`` offline)
  form the longitudinal axis; spatial views (``file_name``/``proc_name``/host)
  are one-shot.
- Online, per-window **control findings** can be emitted so the optimizer acts
  on fresh state.

Installation
------------

.. code-block:: bash

   pip install dfdiagnoser                 # core (offline)
   pip install "dfdiagnoser[streaming]"    # + online transports (pyzmq / mofka)

From source:

.. code-block:: bash

   git clone https://github.com/LLNL/dfdiagnoser.git && cd dfdiagnoser
   uv sync && uv pip install -e .

Requirements: Python >= 3.9, and DFAnalyzer fact envelopes (run DFAnalyzer
with ``facts.enabled=true``). Online transports need ``pyzmq`` (ZMQ) or
``mochi-mofka`` (Mofka), via the ``[streaming]`` extra.

Quick start
-----------

The CLI is a Hydra app selecting an ``input`` (``file`` / ``checkpoint`` /
``mofka`` / ``zmq``) and an ``output`` (``console`` / ``file``).

Offline — replay a DFAnalyzer fact bundle written with ``output=file``:

.. code-block:: bash

   dfdiagnoser input=file input.path=/tmp/bundle output=console

Online — live ZMQ stream (DFDiagnoser binds and waits for facts, DFAnalyzer
pushes window-view fact envelopes with ``output=zmq``):

.. code-block:: bash

   dfdiagnoser input=zmq input.address="tcp://*:5556" output=console

Online — Mofka (LiveFlow):

.. code-block:: bash

   dfdiagnoser input=mofka \
       input.group_file="$MOFKA_GROUP_FILE" \
       input.topic_name=analyzer_facts \
       input.output_topic=diagnosis_findings \
       output=console

All paths yield the same ``DiagnosisResult.findings``; only the transport
differs. Each finding's wire form carries ``finding_type``, ``scope``,
``motif``, ``severity_score``, ``prevalence``, ``persistence``,
``trend_direction``, ``opportunity_tags``, ``recommendation_bundle``, and
``key_metrics`` — the fields DFOptimizer gates actuation on.
