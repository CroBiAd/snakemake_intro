# Install/Upgrading Snakemake

The easiest way to run `Snakemake` is to install it into a Python virtual environment. **This only
needs to be done once** and can be accomplished by doing do this on the cluster submission node
`caput`:

```bash
# Snakemake requires Python >=3
module load \
  Python/3.5.1-foss-2015b

# create a Python virtual environment in which to install Snakemake
virtualenv -p python .snakemake_venv

# Activate the Snakemake virtual environment
source .snakemake_venv/bin/activate

# Install Snakemake, and potentially other things, using pip
pip install snakemake
```

To upgrade the `Snakemake` version in the Python virtual environment, simply activate the environment
and use `pip` to upgrade `Snakemake`:

```bash
# Activate the Snakemake virtual environment
source .snakemake_venv/bin/activate

# Upgrade the Snakemake package
pip install --upgrade snakemake
```

# Activate Snakemake Environment

To use `Snakemake` you need to activate the `Snakemake` Python virtual environment:

```bash
module load \
  Python/3.5.1-foss-2015b

source .snakemake_venv/bin/activate

snakemake --version
snakemake --help | less
```

# Run Snakemake Tests

We'll run through some basic invocations of `snakemake` to generate some files. First, lets go into
the `test` subdirectory:

```bash
cd test
```

Now ask `Snakemake` to create the file `out/a.out`:

```bash
snakemake --snakefile Snakefile \
  out/a.out
```

Snakemake automatically looks for a snakefile named `Snakefile` in the current directory, so this
can be shortend to:

```bash
snakemake \
  out/a.out
```

See what happens when if we were to ask `Snakemake` to create the file `out/ab.out`:

```bash
snakemake --dryrun --printshellcmds \
  out/ab.out 
```

Let's view a graph of the jobs which would be run. I'm piping the output of `snakemake` to `ssh` so
I can run the `dot` to `pdf` conversion on the `thor` computer (that's where I have `dot` installed).

```bash
snakemake --dag \
  out/ab.out \
  | ssh nhaigh@thor "dot -Tpdf > /tmp/dag.pdf"

# On thor
atril /tmp/dag.pdf
```

So, why do you think `a` has a dotted line around it? Does this help:

```bash
snakemake --dag --forceall \
  out/ab.out \
  | ssh nhaigh@thor "dot -Tpdf > /tmp/dag_forceall.pdf"

# On thor
atril /tmp/dag_forceall.pdf
```

That's right, the dotted lines indicate that rule doesn't need to be run.

Don't cover this yet:

```bash
snakemake --rulegraph \
  out/ab.out \
  | ssh nhaigh@thor "dot -Tpdf > /tmp/rulegraph.pdf"

# On thor
atril /tmp/rulegraph.pdf
```

We haven't created `out/ab.out` yet, lets submit the jobs to run on `biocluster`:

```bash
snakemake --profile profiles/slurm \
  out/ab.out
```

Create a new rule to make a `out/c.out` file and another rule to combine the output of this rule with
`out/ab.out` to generate `out/abc.out`. You should be able to run `snakemake` to create this using:

```bash
snakemake out/abc.out --dag \
  | ssh nhaigh@thor "dot -Tpdf > /tmp/dag.pdf"

snakemake --profile profiles/slurm \
  out/abc.out
```

Lets cleanup and re-run everything on the cluster:

```bash
snakemake --delete-all-output \
  out/abc.out

snakemake --profile profiles/slurm \
  out/abc.out
```

Lets cleanup again before continuing:

```bash
snakemake --delete-all-output \
  out/abc.out
```

# Real Bioinformatic Examples

```bash
snakemake --profile profiles/slurm --snakefile minimap.snakefile --dryrun --printshellcmds \
  out/reference.fasta.gz/a.bam
```

Modify the rule resource requirements to increase threads for mapping. The rerun the pipeline.
We'll submit ALL jobs at the same time instead of dip-feeding them to Slurm:

```bash
snakemake --profile profiles/slurm --snakefile minimap.snakefile --immediate-submit --notemp \
  out/reference.fasta.gz/a.bam --forceall
```

Now:

  1. Modify job resource requirements for nthreads and rerun with `--forcerun` and --printshellcmds`
  2. Does wildcard string order change and affect the cluster log location under
     `logs/minimap2_pe_mapping/`

```bash
# Detecting changed rules/files etc
AFFECTED_FILES=( $(snakemake --snakefile minimap.snakefile --list-code-changes) )
snakemake --forcerun ${AFFECTED_FILES[@]}

#--list-input-changes
#--list-params-changes
```

# Dynamic Determination of Rule Resource Requirements

In rule specification:

```bash
	resources:
		# scale time required according to input R1 FASTQ size. We assume 5min per 150GB, with 5min being the minimum. If the job fails and is reattempted, we also scale acording to attempt number.
		time_min = lambda wildcards, attempt, input: max(math.ceil(os.path.getsize(input['r1']) / 1e9 / 150), 1) * 5 * attempt,
```

In cluster-config file:

```
"minimap2_pe_mapping:" :
    {   
        "time" : "0-00:{resources.time_min}:00"
    },

```

# External Resources

  * Pip and Virtual Environments - https://packaging.python.org/guides/installing-using-pip-and-virtualenv/

