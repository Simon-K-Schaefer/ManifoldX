# ManifoldX
A wrapper and analysis pipeline for parallelised FoldX workflows for high performance computing (HPC) to analyse 3 dimensional protein complex structures. The pipeline involves file cleanup and repair, automated data curation, and a tabular summary of results.
This version of the pipeline utilises the FoldX PSSM algorithm to substitute subsequently every position in 2 interacting protein chains with Ala or alternatively with each of the 20 
natural AA to calculate the interaction energies between
both protein chains and the influence on the stability of each chain. This identifies important interaction residues in an automated way to map protein-protein interfaces. 

## Hardware Requirements
ManifoldX scales with CPU core counts and hardware requirements and calculation times scales accordingly. The software produces a large
output data folder containing all mutant structures and sufficient free disk space (10gb+) is highly recommended to avoid errors.
Software was tested for Ubuntu 20 LTS and newer versions. 

## Dependencies
#requires FoldX and a valid FoldX licence:
https://foldxsuite.crg.eu/

Although ManifoldX is compatible with FoldX 5.1, we recommend FoldX Version 5.0 instead after the initial evaluation of the capabilities of FoldX 5.1 for complex structures.

#requires pdb-tools
http://www.bonvinlab.org/pdb-tools/
```bash
pip install pdb-tools
```

Rodrigues, J. P. G. L. M., Teixeira, J. M. C., Trellet, M. & Bonvin, A. M. J. J.
pdb-tools: a swiss army knife for molecular structures. bioRxiv (2018).
doi:10.1101/483305


requires Perl and the module Sort::Versions

```bash
cpan Sort::Versions
```

requires GNU parallel
```bash
apt-get install parallel
```
requires pandas and biopython
```bash
pip install pandas biopython
```

## How to Install
* Download FoldX and unzip to target location.
* Download ManifoldX and unzip files in the same folder as FoldX.
* Rename foldx-VersionNR to foldx
* make Foldx executable with the following command
  
```bash
chmod +x ./foldx
```

#ManifoldX is designed for HPC workflows and requires no input during the process after the initial process call.

#Core/Thread counts have to be specified in the header section of ManifoldX.sh and ManifoldX_20AA.sh

* Modify utilised cores to according to system specifications in the header section of ManifoldX.sh (Standard is set to 5 threads).

```plaintext
#----------------------------------------
#----------------------------------------
# Set your desired number of threads here
threads=5
#----------------------------------------
#----------------------------------------
```

## Validate Installation

Open a shell in the FoldX/ManifoldX folder and run the test script as described below to validate the installation.
1AVZ is a minimalistic structure as test case for functionality. Ideally no error messages should occur and 
the folder output-1AVZ-reres-A-B/output/ should contain the file interactions-summary.tsv and 1AVZ_interactions-summary.tsv.


```bash
pdb_fetch 1AVZ > 1AVZ.pdb

bash ManifoldX.sh 1AVZ.pdb A B
```

## Pipeline workflow

```plaintext
ManifoldX.sh
  |
Validate Files (PDB Tools)
  |
Renumber every residue per chain (PDB Tools)
  |
Repair files (FoldX:Optimize)
  |
Create FoldX config files (single-config-creator.pl)
  |
Run FoldX PSSM in parallel (GNU parallel)
  |
  +-----------------------+
  |                       |
PSSM (parallel)      PSSM (parallel)
  |                       |
  +-----------+-----------+
  |
Merge results for interaction energies (interactions-summary.tsv)
  |
Merge results for intrachain energies (indiv_interactions-summary.tsv)
  |
Map interaction results back to PDB res numbers ([PDB-file]_indiv_interactions-summary.tsv)
  |
Map intrachain results back to PDB res numbers ([PDB-file]_indiv_interactions-summary.tsv)
  |
Copy output data to output-folder and clean up
```

## How to use

The pipeline requires input files in the pdb file format containing at least two protein chains. This is a FoldX dependency.
Additional protein chains do not hinder the workflow and may improve the overall analysis accuracy.
Larger additional structures present in the file can significantly increase calculation time.

Newer PDB entries with only mmcif entries can be converted utilising the gemmi tool.

Online Converter Tool:
https://project-gemmi.github.io/wasm/convert/cif2pdb.html

Repository:
https://github.com/project-gemmi/gemmi

ManifoldX has no GUI and is run via command line:

```bash
pdb_fetch PDB-reference > PDB_file.pdb

bash ManifoldX.sh PDB_file.pdb chainA chainB
```

## Results and Ouput Files
Potential output is demonstrated on the minimalistic benchmark structure 1AVZ.pdb.
The main output folder contains clean and renumbered structure files (1AVZ-reres.pdb) and fasta files (1AVZ-raw.fasta) containing
the sequences for every chain of the structure file.

The output folder contains the FoldX energy outputs for every position and two summary files:
* Interaction energies for the protein protein interface ([PDB-file]_interactions-summary.tsv)
* Energies within the interacting chains as indicator for destabilising mutations ([PDB-file]_indiv_interactions-summary.tsv) 
```plaintext
output-1AVZ-reres-A-B/
├── 1AVZ-reres.pdb
├── 1AVZ.fasta
├── output/
│   ├── AAA11/
│   │   ├──Interaction_*_AC.fxout
│   │   └──Interaction_*_AC.fxout
│   ├── AAB13/
│   ├── 1AVZ_interactions-summary.tsv
└── └── 1AVZ_indiv_interactions-summary.tsv
```

## Ala scan and 20AA scan
The base version of ManifoldX substitutes every residue with Ala to identify important residue due to loss of 
interaction energy. ManifoldX_20AA substitutes every residues with all 20 natural AA to create protein variants with possible interaction energy 
improvements or identify disruptive substitutions for binding or structural stability. ManifoldX_20AA contains the Ala Scan as subset. The Ala scan is roughly 20-fold faster than the 20AA substitution. 


```bash
pdb_fetch PDB-reference > PDB-reference.pdb

bash ManifoldX_20AA.sh PDB_file.pdb chainA chainB
```

## Troubleshooting and additional information

* The FoldX licence is not perpetual and requires annual redownloads of FoldX with a refreshed licence.
  The licence runs out every year at 31st of December.

* The pipeline works with FoldX5.0 and FoldX5.1 which produces different output energies (different forcefields).

* The Pipeline produces intermediary structures as output. This requires large amount of disk space.
It is therefore recomended to export output summary files and delete intermediary structures.

* Chain names can be different between PDB files and fasta files for the same NCBI PDB entry.

* The pipeline contains a pdb file fetch step that is commented out since the NCBI PDB does not provide pdb files for new structures anymore. 

* If the PDB fetch step fails fetch structure file manually from the NCBI pdb (mmcif/PDBX) and convert as described above.


# Visualisation wiht plot_ManifoldX

Visualize per-residue ΔΔG for a selcted chain from ManifoldX output files (*_interactions-summary.tsv). One figure with a full profile + one zoom panel per region.

## Usage

python plot_ManifoldX *_interactions-summary.tsv [options]

Most useful options

--chain B — chain ID (default: B).

--start N — minimum position to include (inclusive).

--end N — maximum position to include (inclusive).

--regions "Name1:s-e,Name2:s-e" — explicit zoom regions (overrides auto hotspots).

--auto-zoom K — number of auto-selected hotspot regions (default: 3).

--window W — width of each auto window (default: 11).

--title LABEL — panel label tag (default: Target).

--out PATH — save figure (PNG if no extension). If omitted, shows interactively.

Input TSV must contain: chain, pos, res, dif_energy.

## Examples

Basic

```bash
python plot_ManifoldX interactions-summary.tsv
```
Restrict to 50–200 and auto-pick 3 regions

```bash
python plot_ManifoldX interactions-summary.tsv --start 50 --end 200 --auto-zoom 3
```
Manual regions and save to file

```bash
python plot_ManifoldX interactions-summary.tsv \
  --regions "R1:120-140,R2:160-175,R3:185-195" --out fig.png
```
## Authors
Simon Schäfer,
Anselm H.C. Horn,
Manuel Deubler

## Acknowledgements
The authors gratefully acknowledge the scientific support and HPC resources provided by the Erlangen National High Performance Computing Center (NHR@FAU) of the Friedrich-Alexander-Universität Erlangen-Nürnberg (FAU). The hardware is funded by the German Research Foundation (DFG).

https://hpc.fau.de/
