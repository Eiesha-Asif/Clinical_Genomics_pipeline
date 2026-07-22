# About `report.html`

The original repository includes a `report.html` — a Nextflow execution
report generated after a real run of the pipeline (it shows per-process CPU,
memory, and timing statistics, produced automatically by Nextflow's
`-with-report` flag).

This fork keeps that same behaviour switched **on by default**: every run
now automatically produces:

- `results/execution_report.html` — resource usage per step
- `results/execution_timeline.html` — a Gantt-style timeline of the run

Open either file in any web browser after a run completes — no extra
software needed. If you'd like a report from a run that hasn't happened yet
on your machine, the Quick Start / Lab Manual will produce a fresh one the
first time you run the pipeline.
