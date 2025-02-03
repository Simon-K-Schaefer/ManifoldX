# ManifoldX
A wrapper and analysis pipeline for parallelized FoldX workflows for high perfomance computing (HPC) to analyse 3 dimensional protein complex structures. The pipeline involves file cleanup and repair, automated data curation, and a tabular summary of results.
This Version of the pipeline utilises the FoldX PSSM algoritm to substitute subsequently every position in 2 interacting proteins chains with Ala to calculates the interaction energies between
both proteins. This identifies important interaction residues in an automated way to map protein protein interfaces. 

## Hardware Requirements
ManifoldX scales with CPU core counts and hardware requirements and calculation times scales accordingly. The software produces a large
output data folder containing all mutant structures and sufficent free disk space (10gb+) is highly recommended to avoid errors.
Software was tested for Ubuntu 20 LTS and newer versions. 

## Dependencies
#requires FoldX and a valid FoldX license as well as :
https://foldxsuite.crg.eu/

#requires pdb-tools
http://www.bonvinlab.org/pdb-tools/

```bash
pip install pdb-tools
```

Rodrigues, J. P. G. L. M., Teixeira, J. M. C., Trellet, M. & Bonvin, A. M. J. J.
pdb-tools: a swiss army knife for molecular structures. bioRxiv (2018).
doi:10.1101/483305


#requires Perl and the module Sort::Versions

```bash
cpan Sort::Versions
```

#requires GNU parallel
```bash
apt-get install parallel
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

#Core/Thread counts have to be specified in the header section of ManifoldX.sh

* Modify utilised cores to according to system specificications in the header section of ManifoldX.sh (Standard is set to 5 threads).

```plaintext
#----------------------------------------
#----------------------------------------
# Set your desired number of threads here
threads=5
#----------------------------------------
#----------------------------------------
```

## Validate Installation

Open a shell in the FolX/ManifoldX folder and run the test script as described below to validate the installation.
1AVZ is a minimalistic structrure as test case for functionality. Ideally no error messages should occur and 
the folder output-1AVZ-reres-A-B/output/ should contain the file interactions-summary.tsv.


```bash
pdb_fetch 1AVZ > 1AVZ.pdb

bash ManifoldX.sh 1AVZ A B
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
Copy output data to output-folder and clean up
```

## How to use

The pipeline requires input files in the pdb file format. This is a FoldX dependency.
Newer PDB entries wiht only mmcif entries can be converted utilising the gemmi tool.

Online Converter Tool:
https://project-gemmi.github.io/wasm/convert/cif2pdb.html

Repository:
https://github.com/project-gemmi/gemmi

ManifoldX has no GUI and is run via command line:

```bash
pdb_fetch PDB-reference > PDB-reference.pdb

bash ManifoldX.sh PDB-reference chainA chainB
```

## Results and Ouput Files
Potential output demonstrated on the minimalistic bench mark strucutre 1AVZ.pdb.
The main output folder contains clean and renumbered structure files (1AVZ-reres.pdb) and fasta files (1AVZ-raw.fasta) containing
the sequences for every chain of the structure file.

The output folder contains the FoldX energy outputs for every position and two summary files:
* Interaction energies for the protein protein interface (interactions-summary.tsv)
* Energies within the interacting chains as indicator for destabilizing mutations (indiv_interactions-summary.tsv) 
```plaintext
output-1AVZ-reres-A-B/
├── 1AVZ-reres.pdb
├── 1AVZ-raw.fasta
├── output/
│   ├── AAA11/
│   │   ├──Interaction_*_AC.fxout
│   │   └──Interaction_*_AC.fxout
│   ├── AAB13/
│   ├── interactions-summary.tsv
└── └── indiv_interactions-summary.tsv
```

## Ala scan and 20AA scan
The base version of ManifoldX subtitutes every resdiue with Ala to identify important residue due to loss of 
interaction energy. ManifoldX_20AA substitutes every residues with all 20 natural AA to create variants possible
improvements in interaction energy or identify disruptive substitutions.

## Troubleshooting and additional information

* The FoldX license is not perpetual and requires annual redownloads of FoldX with a refreshed license.
  The license runs out every year at 31th of December.

* The Pipeline produces intermediary structures as output. This requires large amount of disk space.
It is therefore reccomended to export output files and delete intermediary structures.

* Chain names can be different between PDB files and fasta files in the NCBI PDB.

* PDB identifier must be entered without the .pdb file extension unless stated outherwise.

* The pipeline contains a pdb file fetch step that is commented out since the NCBI PDB does not provide pdb files for new structures anymore. 

* The pipeline works with FoldX5.0 and FoldX5.1 which produces different output energies (different forcefields).

* If the PDB fetch step fails fetch structure file manually from the NCBI pdb (mmcif/PDBX) and convert as described above.

## Authors
Simon Schäfer,
Anselm H.C. Horn,
Manuel Deubler

## Aknowledgements
The authors gratefully acknowledge the scientific support and HPC resources provided by the Erlangen National High Performance Computing Center (NHR@FAU) of the Friedrich-Alexander-Universität Erlangen-Nürnberg (FAU). The hardware is funded by the German Research Foundation (DFG).

https://hpc.fau.de/
