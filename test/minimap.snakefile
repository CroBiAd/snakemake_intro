rule minimap2_fasta_indexing:
	input:
		"reference.fasta.gz"
	output:
		"out/reference.fasta.gz.mmi"
	log:
		"logs/reference.fasta.gz.mmi.log"
	params:
		mem = "50G"
	shell:
		"""
		module purge
		module load \
		  minimap2/2.8-foss-2015b

		minimap2 -I {params.mem} -d {output} {input} 2>&1 > {log}
		"""

rule minimap2_pe_mapping:
	input:
		index = "out/{fasta}.mmi",
		r1  = "{file}_R1.fastq.gz",
		r2  = "{file}_R2.fastq.gz"
	output:
		protected("out/{fasta}/{file,[^\/]}.bam")
	params:
		minimap_K = "1G",
		sort_mem = "5G",
		mapping_option_F = 1000,
		min_mapq = 5,
		read_group_ID = "{file}",
		read_group_LB = "Unknown",
		read_group_PL = "Illumina",
		read_group_PU = "{file}",
		read_group_SM = "{file}"
	threads:
		9999
	shell:
		"""
		module purge
		module load \
		  minimap2/2.8-foss-2015b \
		  SAMtools/1.8-foss-2015b

		TMP_OUT="$(mktemp /tmp/tmp.XXXXXXXXXX.bam)"
		function clean_up {{
		  # Perform program exit housekeeping
		  if [ ! -z "${{TMP_OUT}}" ] && [ -e "${{TMP_OUT}}" ]; then
		    rm -f "${{TMP_OUT}}*"
		  fi
		  trap 0  # reset to default action
		  exit
		}}
		trap clean_up 0 1 2 3 15 #see 'man signal' for descriptions http://man7.org/linux/man-pages/man7/signal.7.html

		minimap2 -a \
		  -x sr \
		  -t {threads} -2 \
		  -K {params.minimap_K} -F {params.mapping_option_F} \
		  -R "@RG\\tID:{params.read_group_ID}\\tLB:{params.read_group_LB}\\tPL={params.read_group_PL}\\tPU={params.read_group_PU}\\tSM:{params.read_group_SM}" \
		  {input.index} \
		  {input.r1} {input.r2} \
		| samtools view -ub -f 2 -q {params.min_mapq} -- \
		| samtools sort -T /tmp --threads 10 -m {params.sort_mem} \
		| samtools calmd -b --threads {threads} - "{wildcards.fasta}" \
		> ${{TMP_OUT}}

		mv ${{TMP_OUT}} {output}
		"""

