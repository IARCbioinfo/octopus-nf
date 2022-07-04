#! /usr/bin/env nextflow

// Copyright (C) 2017 IARC/WHO

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

params.help          	= null
params.ref           	= null
params.tn_pairs      	= null
params.snp_vcf         	= null
params.indel_vcf       	= null
params.bed              = null
params.cpu            	= "2"
params.mem           	= "20"
params.output_folder  	= "octopus_output"

log.info ""
log.info "----------------------------------------------------------------"
log.info "  Octopus 1.0 : variant calling with Octopus using nextflow "
log.info "----------------------------------------------------------------"
log.info "Copyright (C) IARC/WHO"
log.info "This program comes with ABSOLUTELY NO WARRANTY; for details see LICENSE"
log.info "This is free software, and you are welcome to redistribute it"
log.info "under certain conditions; see LICENSE for details."
log.info "--------------------------------------------------------"
log.info ""

if (params.help) {
    log.info "--------------------------------------------------------"
    log.info "  USAGE                                                 "
    log.info "--------------------------------------------------------"
    log.info ""
    log.info "nextflow run iarcbioinfo/octopus.nf -profile singularity --ref hg38.fa --tn_pairs pairs.txt --bed region.bed"
    log.info ""
    log.info "Mandatory arguments:"
    log.info "--ref                  FILE                 Genome reference file"
    log.info "--tn_pairs             FILE                 Tab delimited text file with at least two columns called normal and tumor"
    log.info "                                            optionally a sample column and a vcf column to use mutect's --forcedGT"
    log.info "--bed                  FILE                 region file in bed format"
    log.info "--snp_vcf              FILE                 dbsnp vcf file"
    log.info "--indel_vcf            FILE                 dbindel vcf file"
    log.info ""
    log.info "--cpu                  INT                  number of CPU (default 2)"
    log.info "--mem                  INT                  max memory in Gb (default 20)"
    log.info ""
    log.info "--output_folder        FOLDER               output folder name"
    log.info ""
    exit 0
}

/* Software information */
log.info ""
log.info "ref           	= ${params.ref}"
log.info "tn_pairs              = ${params.tn_pairs}"
log.info "bed                   = ${params.bed}"
log.info "snp_vcf               = ${params.snp_vcf}"
log.info "indel_vcf             = ${params.indel_vcf}"
log.info "cpu                   = ${params.cpu}"
log.info "mem                   = ${params.mem}Gb"
log.info "output_folder         = ${params.output_folder}"
log.info ""

tn_pairs = file( params.tn_pairs )
fasta_ref = file( params.ref )
fasta_ref_fai = file( params.ref+'.fai' )
snp_vcf = file( params.snp_vcf ) 
snp_vcf_tbi = file( params.snp_vcf+'.tbi' )
indel_vcf = file( params.indel_vcf )
indel_vcf_tbi = file( params.indel_vcf+'.tbi' )
bed = file ( params.bed )

pairs = Channel.fromPath(params.tn_pairs).splitCsv(header: true, sep: '\t', strip: true)
	.map{ row -> [ row.sample , file(row.tumor), file(row.tumor+'.bai'), file(row.normal), file(row.normal+'.bai') ]}
			
process run_octopus {

    cpus params.cpu
    memory params.mem+'GB'

    //container = 'docker://iarcbioinfo/octopus.sif'
 
    publishDir params.output_folder+"/VCFs/raw", mode: 'copy', pattern: "*vcf*"

     input:
     //set val(sample), file(bamT), file(baiT) , file(bamN), file(baiN), val(SM) from pairs
     set val(sample), file(bamT), file(baiT) , file(bamN), file(baiN) from pairs
     file(snp_vcf)
     file(snp_vcf_tbi)
     file(indel_vcf)
     file(indel_vcf_tbi)
     file(fasta_ref)
     file(fasta_ref_fai)
     file(bed)

     output:
     file '*somatic.vcf.gz' into vcffiles
  
     shell:
     output_prefix="${bamT}_vs_${bamN}.somatic"
     '''
     SM=`samtools view -H !{bamN} | grep '^@RG' | sed "s/.*SM://"`
     # --filter_vcf do not seem to be the parameter for dbsnp and dbindel filtering !?
     #octopus -R !{fasta_ref} -I !{bamT} !{bamN} --normal-sample ${SM} -o !{output_prefix}.vcf.gz --threads !{params.cpu} --regions-file !{bed} -C cancer --filter-vcf !{snp_vcf} !{indel_vcf} --annotations AD ADP AF
     octopus -R !{fasta_ref} -I !{bamT} !{bamN} --normal-sample ${SM} -o !{output_prefix}.vcf.gz --threads !{params.cpu} --regions-file !{bed} -C cancer --annotations AD ADP AF
     '''
  }


