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

We'll run through some basic invocations of `snakemake` to generate some files. First, ask
`Snakemake` to create the file `out/a.out`:

```bash
snakemake --snakefile test/Snakefile out/a.out
```

See what happens when if we were to ask `Snakemake` to create the file `out/ab.out`:

```bash
snakemake --snakefile test/Snakefile out/ab.out --dryrun --printshellcmds
```

Let's view a graph of the jobs which would be run. I'm piping the output of `snakemake` to `ssh` so
I can run the `dot` to `pdf` conversion on the `thor` computer (that's where I have `dot` installed).

```bash
snakemake --snakefile test/Snakefile out/ab.out --dag \
  | ssh nhaigh@thor "dot -Tpdf > /tmp/dag.pdf"

# On thor
atril /tmp/dag.pdf
```

So, why do you think `a` has a dotted line around it? Does this help:

```bash
snakemake --snakefile test/Snakefile out/ab.out --dag --forceall \
  | ssh nhaigh@thor "dot -Tpdf > /tmp/dag_forceall.pdf"

# On thor
atril /tmp/dag_forceall.pdf
```

That's right, the dotted lines indicate that rule doesn't need to be run.

Don't cover this yet:

```bash
snakemake --snakefile test/Snakefile out/ab.out --rulegraph \
  | ssh nhaigh@thor "dot -Tpdf > /tmp/rulegraph.pdf"

# On thor
atril /tmp/rulegraph.pdf
```

We haven't created `out/ab.out` yet, lets submit the jobs to run on `biocluster`:

```bash
snakemake --profile profiles/slurm --snakefile test/Snakefile out/ab.out
```

Create a new rule to make a `out/c.out` file and another rule to combine the output of this rule with
`out/ab.out` to generate `out/abc.out`. You should be able to run `snakemake` to create this using:

```bash
snakemake --snakefile test/Snakefile out/abc.out --dag \
  | ssh nhaigh@thor "dot -Tpdf > /tmp/dag.pdf"

snakemake --profile profiles/slurm --snakefile test/Snakefile out/abc.out
```

Lets cleanup and re-run everything on the cluster:

```bash
rm -rf logs out
snakemake --profile profiles/slurm --snakefile test/Snakefile out/abc.out
```


# Real Bioinformatics Examples





# External Resources

  * Pip and Virtual Environments - https://packaging.python.org/guides/installing-using-pip-and-virtualenv/

