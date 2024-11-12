#!/bin/bash
#version 1.1
#written by S. K. Schaefer

#requires pdb-tools
#Rodrigues, J. P. G. L. M., Teixeira, J. M. C., Trellet, M. & Bonvin, A. M. J. J.
#pdb-tools: a swiss army knife for molecular structures. bioRxiv (2018). 
#doi:10.1101/483305

# To download
#git clone https://github.com/haddocking/pdb-tools
#cd pdb-tools

# To install
#python setup.py install


file="$1"
chain1=$2
chain2=$3

filename=$file".pdb"
rm -r output-$file-$chain1-$chain2

#Downloads a structure in PDB format from the RCSB website. Allows downloading
#the (first) biological structure if selected.
#pdb_fetch $file > $filename

##run foldx to optimize further (repair broken side chains)
./foldx --command=Optimize --pdb=$filename

mv ./"Optimized_"$filename ./$filename 

if [ ! -d "output-$file-$chain1-$chain2" ]; then
    mkdir output-$file-$chain1-$chain2
fi
if [ ! -d "output-$file-$chain1-$chain2/split" ]; then
    mkdir output-$file-$chain1-$chain2/split
fi

#pdb_validate before process
echo "---------------------"
echo "validation before cleanup"
echo "---------------------"
#Validates the PDB file ATOM/HETATM lines according to the format specifications.
#Does not catch all the errors though... people are creative!
pdb_validate $filename
echo ""
echo ""
echo "---------------------"
echo "before cleanup"
echo "---------------------"
#Detects gaps between consecutive residues in the sequence, both by a distance
#criterion or discontinuous residue numbering. Only applies for protein residues.
pdb_gap $filename
pdb_gap $filename > output-$file-$chain1-$chain2/$file-gaps-before.txt
echo ""
echo ""

#sort RMARK/ATOM/HETATM/END
pdb_sort $filename > output-$file-$chain1-$chain2/$file-sort.pdb
#Modifies the file to adhere (as much as possible) to the format specifications.
#Expects a sorted file - REMARK/ATOM/HETATM/END - so use pdb_sort in case you are
#not sure.
#
#This includes:
#    - Adding TER statements after chain breaks/changes
#    - Truncating/Padding all lines to 80 characters
#    - Adds END statement at the end of the file
#
#Will remove all original TER/END statements from the file.
pdb_tidy output-$file-$chain1-$chain2/$file-sort.pdb > output-$file-$chain1-$chain2/$file-tidy.pdb

#split pdb to single chains for renumbering
pdb_splitchain output-$file-$chain1-$chain2/$file-tidy.pdb
mv $file-tidy*.pdb output-$file-$chain1-$chain2/split/

for i in output-$file-$chain1-$chain2/split/$file-tidy*.pdb
do
base=${i%.pdb}
#Renumbers the residues of the PDB file starting from a given number (default 1).
pdb_reres $i > $base-reres.pdb
#Extracts the residue sequence in a PDB file to FASTA format. Canonical amino
#acids and nucleotides are represented by their one-letter code while all others
#are represented by 'X'.
pdb_delhetatm $base-reres.pdb | pdb_tofasta >> output-$file-$chain1-$chain2/$file-raw.fasta
done 
awk 'BEGIN {RS=">"; ORS=""} $2 {print ">"$0}' output-$file-$chain1-$chain2/$file-raw.fasta > output-$file-$chain1-$chain2/$file.fasta
echo ">" >> output-$file-$chain1-$chain2/$file.fasta

#Merges several PDB files into one. The contents are not sorted and no lines are
#deleted (e.g. END, TER statements) so we recommend piping the results through
#`pdb_tidy.py`.
pdb_merge output-$file-$chain1-$chain2/split/*-reres.pdb > output-$file-$chain1-$chain2/$file-merged.pdb

#Modifies the file to adhere (as much as possible) to the format specifications.
#Expects a sorted file - REMARK/ATOM/HETATM/END - so use pdb_sort in case you are
#not sure.
#
#This includes:
#    - Adding TER statements after chain breaks/changes
#    - Truncating/Padding all lines to 80 characters
#    - Adds END statement at the end of the file
#
#Will remove all original TER/END statements from the file.
pdb_tidy output-$file-$chain1-$chain2/$file-merged.pdb > output-$file-$chain1-$chain2/$file-reres.pdb

echo "---------------------"
echo "after cleanup"
echo "---------------------"
#Detects gaps between consecutive residues in the sequence, both by a distance
#criterion or discontinuous residue numbering. Only applies for protein residues.
pdb_gap output-$file-$chain1-$chain2/$file-reres.pdb
pdb_gap output-$file-$chain1-$chain2/$file-reres.pdb > output-$file-$chain1-$chain2/$file-gaps-after.txt
echo ""
echo ""

#pdb_validate after process
echo "---------------------"
echo "validation after cleanup"
echo "---------------------"
#Validates the PDB file ATOM/HETATM lines according to the format specifications.
#Does not catch all the errors though... people are creative!
pdb_validate output-$file-$chain1-$chain2/$file-reres.pdb
echo "---------------------"
echo ""

### get files from pdb tools cleaner workflow
cp output-$file-$chain1-$chain2/$file-reres.pdb ./
cp output-$file-$chain1-$chain2/$file.fasta ./

### remove data from previous (failed) workflows
rm -r ./output/
rm -r ./config/

### create data directories
mkdir ./config/
mkdir ./output/

### create config file for each residue from cleaned fasta
### no AA diff between fasta and pdb

perl ./single-config-creator.pl $file".fasta" $chain1 $chain2



### create output directory for every res config file 
for i in ./config/*
do
FILE="$i"
basename "$FILE"
f="$(basename -- $FILE)"
mkdir output/$f
done


### run foldX for every config file as loop - neccessary because of bug in foldX batch modes
ls ./config/* | parallel -j 10 ./foldx -f
wait

### move output from optimization step
mv Unrecognized_molecules.txt ./output/
mv OP_*.fxout ./output/

### move tools
cp ./Alascan.pl ./output/
cp ./Indivscan.pl ./output/
cp ./gliding_window.py ./output/


### energy analysis
cd output/
grep "" ./*/Interaction_*_AC.fxout > interactions.txt
grep "" ./*/Indiv_energies_*_AC.fxout > indiv_interactions.txt
perl Alascan.pl interactions.txt
perl Indivscan.pl indiv_interactions.txt
#python3 ./gliding_window.py interactions-summary.csv 
cd ..
mv ./output output-$file-$chain1-$chain2/

##cleanup
rm -r ./config/
rm $file.fasta
rm $file.pdb
rm $file-reres.pdb
for i in output-pipe-*/output/A*/ ; do rm -r $i ; done



