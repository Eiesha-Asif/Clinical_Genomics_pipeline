# Lab Manual — Clinical Genomics Pipeline (For Complete Beginners)

Welcome! This manual assumes you have **never used Linux, the command line,
Nextflow, or containers before**. Every command below is copy-pasteable.
Read the explanation under each command before running it — that's how you
actually learn what's happening, not just how to copy-paste blindly.

If a command produces an error, don't panic — jump to
[Section 9: Troubleshooting](#9-troubleshooting).

---

## Table of Contents

1. [What you need before starting](#1-what-you-need-before-starting)
2. [Opening a terminal](#2-opening-a-terminal)
3. [Installing Java](#3-installing-java)
4. [Installing Nextflow](#4-installing-nextflow)
5. [Installing Singularity/Apptainer](#5-installing-singularityapptainer)
6. [Getting this repository onto your computer](#6-getting-this-repository-onto-your-computer)
7. [Building the containers](#7-building-the-containers)
8. [Running the pipeline](#8-running-the-pipeline)
9. [Troubleshooting](#9-troubleshooting)
10. [Understanding your results](#10-understanding-your-results)
11. [Glossary](#11-glossary)

---

## 1. What you need before starting

- A computer running **Linux**, or **Windows with WSL2** installed, or a **Mac**
  with Docker/Colima if you're comfortable with alternatives (Singularity
  itself is Linux-only — WSL2 gives Windows users a real Linux environment).
- At least **20 GB of free disk space** and **8 GB of RAM**.
- An internet connection (needed once, to download tools and containers).
- No prior coding experience required.

> **Don't have a suitable computer?** Use `notebooks/02_run_pipeline_colab.ipynb`
> in Google Colab instead — it gives you a free Linux machine in your browser,
> no installation needed on your own laptop.

---

## 2. Opening a terminal

The "terminal" (also called "command line" or "shell") is a text-based way
to talk to your computer. Every command in this manual is typed into it.

- **Ubuntu/Linux:** Press `Ctrl+Alt+T`, or search "Terminal" in your app menu.
- **Windows (after installing WSL2):** Search "Ubuntu" in the Start menu.
- **Mac:** Search "Terminal" in Spotlight (`Cmd+Space`).

You'll see a blinking cursor after a `$` sign — that's where you type.

---

## 3. Installing Java

Nextflow is written in a language that runs on **Java**, so Java must be
installed first.

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk
```

**What this does, line by line:**
- `sudo` — "run this as administrator" (you'll be asked for your password)
- `apt update` — refreshes the list of software available to install
- `apt install -y openjdk-17-jdk` — installs Java 17; `-y` auto-confirms "yes"

**Check it worked:**
```bash
java -version
```
You should see something starting with `openjdk version "17...`. If you see
"command not found," the install failed — see Troubleshooting.

---

## 4. Installing Nextflow

Nextflow is the workflow engine that reads `main.nf` and runs every step for
you, in the right order, with retries on failure.

```bash
curl -s https://get.nextflow.io | bash
chmod +x nextflow
sudo mv nextflow /usr/local/bin/
```

**What this does:**
- `curl -s https://get.nextflow.io | bash` — downloads and runs the official
  Nextflow installer script (creates a file called `nextflow` in your
  current folder)
- `chmod +x nextflow` — marks that file as "executable" (runnable)
- `sudo mv nextflow /usr/local/bin/` — moves it somewhere your computer can
  find it from any folder, so you can just type `nextflow` anywhere

**Check it worked:**
```bash
nextflow -version
```

---

## 5. Installing Singularity/Apptainer

Singularity (now often called Apptainer, same idea, different name) is what
runs the pipeline's containers — pre-packaged boxes containing exact
software versions, so results are reproducible on any machine.

```bash
sudo apt install -y apptainer
```

If that package isn't available on your Ubuntu version, try:
```bash
sudo apt install -y singularity-container
```

**Check it worked:**
```bash
singularity --version
# or
apptainer --version
```

> This pipeline's config uses the `singularity` command name. If you only
> have `apptainer` installed, most distributions symlink `singularity` to
> `apptainer` automatically. If not, add `alias singularity=apptainer` to
> your `~/.bashrc`.

---

## 6. Getting this repository onto your computer

```bash
git clone https://github.com/<your-username>/clinical-genomics-pipeline.git
cd clinical-genomics-pipeline
```

**What this does:**
- `git clone <url>` — downloads a full copy of this repository, with all
  its history, into a new folder
- `cd clinical-genomics-pipeline` — "change directory", moves your terminal
  into that new folder so following commands run inside it

Don't have `git` installed? `sudo apt install -y git`

**Check you're in the right place:**
```bash
ls
```
`ls` ("list") shows the files in the current folder. You should see
`main.nf`, `nextflow.config`, `modules/`, `containers/`, `README.md`, etc.

---

## 7. Building the containers

The pipeline needs two containers: one with alignment tools, one with
Clair3 (the AI variant caller). You only do this **once** — after that, the
`.sif` files are reused for every run.

### Option A: Build from the included recipe files

```bash
cd containers
sudo singularity build minimap2.sif minimap2.def
sudo singularity build clair3.sif clair3.def
cd ..
```

**What this does:**
- `singularity build <output.sif> <recipe.def>` — reads the recipe file
  (a list of instructions, like a shopping list + assembly guide) and
  builds a single `.sif` image file containing all the installed software
- This step downloads several hundred MB to ~2 GB and can take 10–30
  minutes depending on your internet speed — that's normal.

### Option B: Pull pre-built equivalents (faster, recommended for beginners)

```bash
cd containers
singularity pull --name minimap2.sif docker://staphb/minimap2:2.28
singularity pull --name clair3.sif docker://hkubal/clair3:v1.0.9
cd ..
```

**What this does:** downloads an already-built container image instead of
building one from scratch — much faster, and doesn't need `sudo`.

**Check it worked:**
```bash
ls -lh containers/*.sif
```
You should see two files with real sizes (not 0 bytes).

---

## 8. Running the pipeline

### 8.1 First run — the built-in tiny test dataset
Before using real data, always test with the small example dataset so you can catch problems in seconds, not hours.
#Get small test data from:
1. PacBio official tiny test-data repo ( fast, smoke-test best sample data)

https://github.com/PacificBiosciences/PacBioTestData

#Download the reference genome:
    → GRCh38 primary assembly (Ensembl):
      https://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz 
    Save it into data/reference.fa (after gunzip -k), or point --reference
    directly at wherever you saved it.
    # or get it by:
    
    ```bash
    wget https://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz -O data/reference.fa.gz
    gunzip -k data/reference.fa.gz
    mv data/reference.fa.gz.out data/reference.fa 2>/dev/null || true
# or
    gunzip data/reference.fa.gz    # will make reference.fa 
     ```
# put a small reference.fa and HUCR38.fastq in the data/ folder first —

```bash
nextflow run main.nf -profile test
```
### 8.2 Running with your own data

```bash
nextflow run main.nf \
    --reads /full/path/to/your_reads.fastq \
    --reference /full/path/to/your_reference.fa \
    --sample patient001
```

**What each flag means:**
- `--reads` — path to your FASTQ file (the sequencing reads)
- `--reference` — path to the reference genome FASTA
- `--sample` — a name used to label output files (e.g. patient/sample ID)

### 8.3 Resuming after an interruption

If your laptop sleeps or a step fails partway through, don't start over —
resume instead:

```bash
nextflow run main.nf -profile test -resume
```
Nextflow caches completed steps and only re-runs what's needed.

### 8.4 Generating a report + diagram of the run

```bash
nextflow run main.nf -profile test -with-report report.html -with-dag flowchart.png
```
This creates a browsable HTML report (`report.html`) and a picture
(`flowchart.png`) showing exactly how data flowed through each step.

---

## 9. Troubleshooting

| Symptom | Likely cause | What to do |
|---|---|---|
| `command not found: nextflow` | Step 4 didn't finish, or PATH issue | Re-run Step 4; check with `which nextflow` |
| `command not found: singularity` | Step 5 didn't finish | Re-run Step 5; try `apptainer` instead |
| `Permission denied` while building containers | Missing `sudo` | Add `sudo` before the `singularity build` command |
| `FATAL: while performing build: conveyor failed to get` | The Docker image tag in the recipe doesn't exist right now, or no internet | Use Option B (`singularity pull`) instead |
| Pipeline stops with `Missing --reference parameter` | You forgot `--reference` (and aren't using `-profile test`) | Add the flag, or use `-profile test` |
| Very slow / laptop freezes | Not enough CPU/RAM for the settings in `nextflow.config` | Lower `cpus`/`memory` values for each process (see README → Configuration), or use the tiny test dataset |
| `No such file or directory` for your FASTQ/FASTA | Wrong path typed | Use `pwd` to check your current folder, and use the **full** path (starting with `/`) |
| `report.html already exists` | Old report file present | Delete it, or note this fork already sets `report.overwrite = true` |

**General debugging tip:** every failed step's error log is saved in
Nextflow's `work/` folder. Nextflow will print the exact folder path in the
error message, e.g. `work/3f/a1b2c3.../`. Look inside that folder for a file
called `.command.err` to see the exact tool error.

---

## 10. Understanding your results

After a successful run, open `results/variants/clair3_output/merge_output.vcf.gz`.
This is a **VCF (Variant Call Format)** file — a standard text format listing
every position where your sample differs from the reference genome.

To peek inside it (without needing special software):
```bash
zcat results/variants/clair3_output/merge_output.vcf.gz | head -50
```
`zcat` reads a compressed (`.gz`) file without permanently unzipping it;
`head -50` shows just the first 50 lines.

For a friendlier, visual way to explore it, open
`notebooks/03_explore_results.ipynb`.

---

## 11. Glossary

| Term | Plain-English meaning |
|---|---|
| **FASTA** | A text file format for storing DNA/protein sequences |
| **FASTQ** | Like FASTA, but also stores the sequencer's confidence ("quality") for each letter it read |
| **Reference genome** | A "standard" genome sequence used as the comparison baseline |
| **Alignment** | Figuring out where each sequencing read matches up in the reference |
| **BAM** | A compressed, sorted file format for storing aligned reads |
| **Variant / SNP / Indel** | A position where the sample's DNA differs from the reference (SNP = single letter swap; Indel = small insertion/deletion) |
| **VCF** | The standard file format for listing variants |
| **Container / Singularity image (.sif)** | A self-contained package with a program and everything it needs to run, so it behaves identically on any computer |
| **Pipeline / Workflow** | An automated sequence of steps, each feeding its output into the next |
| **Nextflow** | The tool that runs the pipeline steps in order, in parallel where possible, and retries failures |
| **Process** (in Nextflow) | One step of the pipeline (e.g. "align reads") |
| **Channel** (in Nextflow) | The "pipe" that carries data (like a filename) from one process to the next |

---

You made it through the whole manual — nice work. From here, try modifying
`--sample` and re-running with your own data, or open the notebooks to see
the same pipeline running interactively.
