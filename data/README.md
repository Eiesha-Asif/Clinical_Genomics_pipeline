# Test data

Put your test files here for a quick local run:

- `reference.fa` — a small reference FASTA (e.g. one chromosome, or a few kb region)
- `HUCR38.fastq` — a small PacBio HiFi FASTQ file

These filenames match the `test` profile in `nextflow.config`, so
`nextflow run main.nf -profile test` will find them automatically.

Don't have test data? See `docs/LAB_MANUAL.md` → "Getting a tiny test
dataset" for links to public, free HiFi test reads (e.g. from the
PacBio/Genome in a Bottle public test sets).
