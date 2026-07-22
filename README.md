# Clinical Genomics Pipeline — HiFi Variant Calling with Clair3

> A beginner-friendly, fully containerized **Nextflow + Singularity** pipeline
> that aligns PacBio HiFi long reads to a reference genome and calls variants
> (SNPs/Indels) using the deep-learning variant caller **Clair3**.

This repository is a documented, beginner-friendly fork of the original
[`clinical_genetics`](https://github.com/liz003-ziz1010/clinical_genetics)
pipeline by liz003-ziz1010. **The pipeline logic itself (Nextflow workflow,
modules, containers) is unchanged in spirit and interface** — this fork adds:

- A much more detailed README (this file)
- A complete **Lab Manual** for absolute beginners (`docs/LAB_MANUAL.md`),
  with every single command explained
- Ready-to-run **Jupyter / Google Colab notebooks**
- Extra comments inside the container definition files and modules, so
  newcomers can understand *what* each line does and *why*
- Small reliability additions (execution report + timeline) in `nextflow.config`

If you are completely new to bioinformatics, command lines, or Nextflow —
**start with `docs/LAB_MANUAL.md`, not this README.** This README is the
technical reference; the manual is the step-by-step tutorial.

---

## Table of Contents

- [What does this pipeline actually do?](#what-does-this-pipeline-actually-do)
- [Who is this for?](#who-is-this-for)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Installation](#installation)
- [Usage](#usage)
- [Pipeline Steps in Detail](#pipeline-steps-in-detail)
- [Containers](#containers)
- [Configuration](#configuration)
- [Outputs](#outputs)
- [Notebooks](#notebooks)
- [System Requirements](#system-requirements)
- [Troubleshooting](#troubleshooting)
- [How this fork differs from the original repo](#how-this-fork-differs-from-the-original-repo)
- [Citation](#citation)
- [License](#license)

---

## What does this pipeline actually do?

In plain words: you give it two files —

1. A **reference genome** (a FASTA file — the "known" genome sequence you compare against)
2. Your **sequencing reads** (a FASTQ file — the raw DNA fragments read by a PacBio HiFi sequencer)

...and it tells you **where your sample's DNA differs from the reference** —
these differences are called **variants** (SNPs = single letter changes,
Indels = small insertions/deletions). This is the core step behind detecting
disease-causing mutations, genetic markers, and much of modern clinical
genomics.

It does this in four automated steps: index the reference → align the reads →
sort/index the alignment → call variants with an AI model (Clair3). Every
step runs inside its own **Singularity container**, so the exact same
software versions run identically on your laptop, a university cluster, or
the cloud — this is what "reproducible" means.

## Who is this for?

- Students learning bioinformatics / clinical genomics
- Wet-lab biologists who need to run a variant-calling pipeline without
  becoming a full-time software engineer
- Anyone who wants a working, minimal example of a Nextflow + Singularity
  pipeline to learn from or build on

You do **not** need prior experience with Linux, Nextflow, or containers —
the Lab Manual explains every command from zero.

---

## Quick Start

```bash
# 1. Clone this repository
git clone https://github.com/<your-username>/clinical-genomics-pipeline.git
cd clinical-genomics-pipeline

# 2. Build (or pull) the two containers — see "Containers" section below
sudo singularity build containers/minimap2.sif containers/minimap2.def
sudo singularity build containers/clair3.sif containers/clair3.def

# 3. Run the pipeline on the built-in tiny test dataset
nextflow run main.nf -profile test
```

If that finishes with "Completed successfully" and creates a `results/`
folder, everything is working. Full explanations of each command are in
`docs/LAB_MANUAL.md`.

---

## Repository Structure

```
clinical-genomics-pipeline/
├── README.md                 # You are here
├── LICENSE                   # MIT license
├── main.nf                   # Workflow orchestrator (the "recipe")
├── nextflow.config           # Settings: containers, resources, profiles
├── flowchart.dot             # Graphviz diagram of the pipeline (Step 1→4)
├── modules/                  # One file per pipeline step
│   ├── index.nf              # SAMTOOLS_FAIDX  (index the reference)
│   ├── align.nf              # MINIMAP2_ALIGN  (align reads)
│   ├── sort.nf               # SAMTOOLS_SORT + SAMTOOLS_INDEX
│   └── variant.nf            # CLAIR3          (call variants)
├── containers/                # Singularity recipes + built .sif images (not committed)
│   ├── minimap2.def          # Recipe: minimap2 + samtools
│   └── clair3.def            # Recipe: Clair3 (AI variant caller)
├── data/                      # Put your test/sample FASTA + FASTQ here
├── results/                   # Pipeline output goes here (auto-created)
├── docs/
│   └── LAB_MANUAL.md         # Full beginner walkthrough, every command explained
└── notebooks/
    ├── 01_environment_setup.ipynb   # Check tools, install what's missing
    ├── 02_run_pipeline_colab.ipynb  # Run the whole pipeline from Colab/Jupyter
    └── 03_explore_results.ipynb     # Load and visualize the VCF results
```

---

## Installation

### Prerequisites

| Requirement | Why | Typical version |
|---|---|---|
| Linux or WSL2 (Windows Subsystem for Linux) | Nextflow & Singularity are Linux-native | Ubuntu 22.04+ |
| Java | Nextflow runs on the JVM | OpenJDK 17 |
| Nextflow | Runs the workflow | ≥ 24.10 |
| Singularity / Apptainer | Runs the containers | 3.x / 1.x |
| 8+ CPU cores, 16+ GB RAM | HiFi alignment + Clair3 are compute-heavy | — |

Full install commands (copy-paste ready) are in `docs/LAB_MANUAL.md` →
"Step 1–3: Installing Java, Nextflow, Singularity". Short version:

```bash
# Java 17
sudo apt update && sudo apt install -y openjdk-17-jdk

# Nextflow
curl -s https://get.nextflow.io | bash
chmod +x nextflow && sudo mv nextflow /usr/local/bin/

# Singularity/Apptainer
sudo apt install -y apptainer   # or: singularity-container
```

### Getting the containers

You have two options — pick one:

**Option A — Build from the included recipes (slower, but transparent):**
```bash
cd containers
sudo singularity build minimap2.sif minimap2.def
sudo singularity build clair3.sif clair3.def
```

**Option B — Pull equivalent pre-built images (faster):**
```bash
cd containers
singularity pull --name minimap2.sif docker://staphb/minimap2:2.28
singularity pull --name clair3.sif docker://hkubal/clair3:v1.0.9
```

> `.sif` container files are large (hundreds of MB to a few GB) and are
> **not committed to git** — you build/pull them locally. See `.gitignore`.

---

## Usage

```bash
# Run with the built-in tiny test dataset (recommended first run)
nextflow run main.nf -profile test

# Run with your own data
nextflow run main.nf \
    --reads /path/to/your_reads.fastq \
    --reference /path/to/your_reference.fa \
    --sample my_sample_name

# Resume a run after a crash/interruption (skips steps already completed)
nextflow run main.nf -profile test -resume

# Generate an execution report and a DAG diagram of the run
nextflow run main.nf -profile test -with-report report.html -with-dag flowchart.png
```

Every flag above is explained with real examples in `docs/LAB_MANUAL.md`.

---

## Pipeline Steps in Detail

| # | Step | Tool | Nextflow process | What it produces |
|---|------|------|-------------------|-------------------|
| 1 | Index reference | `samtools faidx` | `SAMTOOLS_FAIDX` | `reference.fa.fai` |
| 2 | Align reads | `minimap2 -x map-hifi` | `MINIMAP2_ALIGN` | `sample.aligned.bam` |
| 3 | Sort alignment | `samtools sort` | `SAMTOOLS_SORT` | `sample.sorted.bam` |
| 4 | Index alignment | `samtools index` | `SAMTOOLS_INDEX` | `sample.sorted.bam.bai` |
| 5 | Call variants | `Clair3` (deep learning) | `CLAIR3` | `merge_output.vcf.gz` |

See `flowchart.dot` for a visual diagram (render with
`dot -Tpng flowchart.dot -o flowchart.png`, or open it in any Graphviz viewer
/ VS Code Graphviz extension).

---

## Containers

| Container | Base image | Tools inside | Used by |
|---|---|---|---|
| `minimap2.sif` | `ubuntu:22.04` | minimap2, samtools, htslib | FAIDX, ALIGN, SORT, INDEX |
| `clair3.sif` | `hkubal/clair3:v1.0.9` | Clair3, Python, PyTorch, pretrained HiFi model | CLAIR3 |

Both `.def` recipe files in `containers/` are commented line-by-line — open
them even if you never plan to edit them, they're a good way to see exactly
what software is running under the hood.

---

## Configuration

`nextflow.config` controls containers, CPU/RAM per step, and default file
paths. Key block:

```groovy
params {
    reads       = null
    reference   = null
    sample      = "sample1"
    outdir      = "${launchDir}/results"
}

profiles {
    test {
        params.reads     = "${projectDir}/data/HUCR38.fastq"
        params.reference = "${projectDir}/data/reference.fa"
    }
}
```

Resource allocation per step:

| Process | CPUs | Memory | Container |
|---|---|---|---|
| SAMTOOLS_FAIDX | 2 | 4 GB | minimap2.sif |
| MINIMAP2_ALIGN | 8 | 16 GB | minimap2.sif |
| SAMTOOLS_SORT | 2 | 4 GB | minimap2.sif |
| SAMTOOLS_INDEX | 2 | 4 GB | minimap2.sif |
| CLAIR3 | 4 | 8 GB | clair3.sif |

If your machine has fewer resources, lower these numbers directly in
`nextflow.config` (the Lab Manual shows exactly where and how).

---

## Outputs

After a successful run, `results/` will contain:

```
results/
├── reference/
│   └── reference.fa.fai
├── alignment/
│   ├── sample1.aligned.bam
│   ├── sample1.sorted.bam
│   └── sample1.sorted.bam.bai
├── variants/
│   └── clair3_output/merge_output.vcf.gz   # <-- your final variant calls
├── execution_report.html                   # run summary (added in this fork)
└── execution_timeline.html                 # step-by-step timing (added in this fork)
```

The final VCF (`merge_output.vcf.gz`) is what you'd open in IGV, load into
`bcftools`, or hand to an annotation tool. `notebooks/03_explore_results.ipynb`
shows how to load and summarize it in Python.

A pre-generated example execution report is provided at `docs/report.html`
so you can see what a finished run looks like without running anything.

---

## Notebooks

| Notebook | What it does |
|---|---|
| `01_environment_setup.ipynb` | Checks/install Java, Nextflow, Singularity inside Colab or a local Jupyter kernel |
| `02_run_pipeline_colab.ipynb` | Clones this repo, builds containers, downloads tiny test data, runs the full pipeline end-to-end |
| `03_explore_results.ipynb` | Loads the output VCF with `pandas`/`pysam`, shows variant counts, a simple summary table and plot |

Click-to-run badges are inside each notebook. Google Colab gives you a free
Linux machine, which is the easiest way for a beginner to try this pipeline
without installing anything locally.

---

## System Requirements

**Minimum:** Ubuntu 22.04+/WSL2, 4 CPU cores, 8 GB RAM, 20 GB free disk, Java 17

**Recommended:** 8+ CPU cores, 16+ GB RAM, 50 GB free disk (for real genomes,
not just the test data), GPU optional (Clair3 runs fine on CPU-only, just slower)

---

## Troubleshooting

| Problem | Cause | Fix |
|---|---|---|
| `FATAL: while performing build: conveyor failed to get` | Docker image tag doesn't exist / no internet during build | Use `singularity pull` with a Galaxy Depot / verified Docker Hub tag instead |
| `Cannot connect to Docker daemon` | You tried a Docker command by mistake | This pipeline uses **Singularity**, not Docker — no daemon needed |
| Out of memory / WSL crashes | CPU/RAM settings too high for your machine | Lower `cpus`/`memory` in `nextflow.config`, or use `-profile test` |
| `report.html already exists` | Re-running without overwrite | Already fixed in this fork's `nextflow.config` (`report.overwrite = true`) |
| `Graphviz is required` | DAG rendering needs graphviz | `sudo apt install -y graphviz` |
| `run_clair3.sh: command not found` | clair3.sif wasn't built/pulled correctly | Re-check the "Getting the containers" section above |

More detailed, screenshot-level troubleshooting is in `docs/LAB_MANUAL.md`.

---

## How this fork differs from the original repo

To be transparent about exactly what changed:

- **Unchanged:** the workflow logic in `main.nf`, the process names and
  their inputs/outputs, and the settings in `nextflow.config` (only two
  small additions: an execution report + timeline block, for visibility).
- **Rebuilt to match the same interface:** the four files under `modules/`
  and the two container recipes under `containers/` were re-written to
  match exactly what `main.nf` expects (same process names `SAMTOOLS_FAIDX`,
  `MINIMAP2_ALIGN`, `SAMTOOLS_SORT`, `SAMTOOLS_INDEX`, `CLAIR3`, and the
  same inputs/outputs/container paths), with extra comments added for
  beginners. This was necessary because GitHub's automated-access rules
  blocked programmatic retrieval of those specific files while preparing
  this fork — if you have the original files, feel free to drop them in
  as-is; the interface will match.
- **Brand new:** this README, the full Lab Manual, the three notebooks,
  and the comments inside every file.

## Citation

- **Minimap2**: Li, H. (2018). Minimap2: pairwise alignment for nucleotide sequences. *Bioinformatics*, 34(18), 3094-3100.
- **SAMtools**: Danecek, P., et al. (2021). Twelve years of SAMtools and BCFtools. *GigaScience*, 10(2), giab008.
- **Clair3**: Zheng, Z., et al. (2022). Symphonizing pileup and full-alignment for deep learning-based long-read variant calling. *Nature Computational Science*, 2(12), 797-803.
- **Nextflow**: Di Tommaso, P., et al. (2017). Nextflow enables reproducible computational workflows. *Nature Biotechnology*, 35(4), 316-319.

## License

MIT License — see [LICENSE](LICENSE).

---

> Built with Nextflow, Singularity, and a lot of coffee (and chai ☕).
