# ManifoldX
A wrapper and analysis pipeline for parallelized FoldX workflows. The pipeline involves file cleanup and repair, automated data curation, and a summary of results.


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



Requirements:
The pipeline requires input files in the pdb file format. This is a FoldX dependency requirement.
Newer PDB entries wiht only mmcif entries can be converted utilising the gemmi tool.

Online Converter Tool:
https://project-gemmi.github.io/wasm/convert/cif2pdb.html

Repository:
https://github.com/project-gemmi/gemmi

## How to install
Download FoldX and unzip to target location.
Download ManifoldX folder and unzip files in the same folder.

#ManifoldX is designed for HPC worklfows and requires no input during the process after the initial process call.

#Core counts have to be specified in the header section of ManifoldX.sh

Modify utilised cores and RAM to compatible system specificications.

## How to use

```bash
bash ManifoldX PDB-reference chainA chainB
```

## Authors
Simon Schäfer
Anselm Horn
Manuel Deubler
