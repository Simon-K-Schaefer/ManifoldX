# ManifoldX
A wrapper and analysis pipeline for parallelized FoldX workflows for high perfomance computing (HPC) to analyse 3 dimensional protein complex structures. The pipeline involves file cleanup and repair, automated data curation, and a tabular summary of results.
This Version of the pipeline utilises the FoldX PSSM algoritm to substitute subsequently every position in 2 interacting proteins chains with Ala to calculates the interaction energies between
both proteins. This identifies important interaction residues in an automated way to map protein protein interfaces. 

## Hardware Requirements
ManifoldX scales with CPU core counts and hardware requirements scale accordingly.

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
* Download ManifoldX folder and unzip files in the same folder.
* Rename foldx-VersionNR to foldx
* make foldx executable
  
```bash
chmod +x ./foldx
```

#ManifoldX is designed for HPC workflows and requires no input during the process after the initial process call.

#Core/Thread counts have to be specified in the header section of ManifoldX.sh

* Modify utilised cores to according to system specificications in the header section of ManifoldX.sh (Standard is set to 5 threads).

## Validate Install

open a shell in the FolX/ManifoldX folder and run the test script to validate the Installation.
1AVZ is a minimalistic structrure as test case for functionality.

```bash
pdb_fetch 1AVZ > 1AVZ.pdb

bash ManifoldX.sh 1AVZ A B
```

## How to use

The pipeline requires input files in the pdb file format. This is a FoldX dependency requirement.
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
Output demonstrated on our bench mark structure 

## Troubleshooting

* THe FoldX license is not perpetual and requires annual redownloads of FOldX with a refreshed license.
  The license runs out every year at 31th of December.

* The Pipeline produces intermediary structures as output. This requires large amount of disk space.
It is therefore reccomended to export output files and delete intermediary structures.

* Chains names can be different between PDB files and fasta files in the NCBI PDB.

## Authors
Simon Schäfer
Anselm Horn
Manuel Deubler
