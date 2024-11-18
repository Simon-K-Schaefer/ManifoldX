#! /usr/bin/perl

##############################
##     load modules
##############################

use strict;
use warnings;
use Sort::Versions;

##############################
##     declare variables
##############################

my $input_file1;
my $output_file;
my $output_suffix1;
my $string;
my $counter;


my $header;
my @file1;
my $file_energy;
my $Group1;
my $Group2;
my $Interaction_Energy;

my $DIF_energy;
my $WT_energy;
my $MT_energy;
my $Interface_Residues;
my $Interface_Residues_Clashing;
my $Interface_Residues_VdW_Clashing;


my %output_hash;

#input via commandline
$input_file1 = $ARGV[0];

##############################
##     open file
##############################

#open files and test for filetype
if ($input_file1 =~ m/.*\.txt$/i){
open(READ1,"$input_file1") || die "error:cant open file";
	@file1 = <READ1>;
	close(READ1);
}else{
	print "enter --help for more information\n";
	exit 1;
}

##############################
##     read file
##############################

#create output suffix from input file
$output_suffix1 = substr($input_file1,0,int((length($input_file1)))-4);

open (FILE, "> $output_suffix1-summary.tsv") || die "problem opening output file\n";

print FILE "PDB	Chain	Pos	Res	Mut	WT_energy	MT_energy	DIF_energy	Interface_Residues	Interface_Residues_Clashing	Interface_Residues_VdW_Clashing\n";
print "PDB	Chain+Pos	Res	Mut	WT_energy	MT_energy	DIF_energy	Interface_Residues	Interface_Residues_Clashing	Interface_Residues_VdW_Clashing\n";

foreach (@file1){
	
		
	if ($_ =~ m/(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*?)	(.*)/i){
	
	$file_energy = $1;
	$Group1 = $2;
	$Group2 = $3;
	$Interaction_Energy = $6;
	$Interface_Residues = $29;
	$Interface_Residues_Clashing = $30;
	$Interface_Residues_VdW_Clashing = $31;
	
	if ($file_energy =~ m/.*:output\/(.)(.)(.)(.*?)\/.*wt_(.*)_1\.pdb/i){
	#print "wildtyp\n";
	$WT_energy=$Interaction_Energy;
	$DIF_energy=$WT_energy-$MT_energy;
	print "$5	$3$4	$2	$1	$WT_energy	$MT_energy	$DIF_energy	$Interface_Residues	$Interface_Residues_Clashing	$Interface_Residues_VdW_Clashing\n";
	$output_hash{"$1$3$4"} = "$5	$3	$4	$2	$1	$WT_energy	$MT_energy	$DIF_energy	$Interface_Residues	$Interface_Residues_Clashing	$Interface_Residues_VdW_Clashing";
	
	}
	elsif ($file_energy =~ m/.*:output.*/i){
	#print "mutant\n";
	$MT_energy=$Interaction_Energy;
	}
	
	}
	
}

foreach (sort { versioncmp($a, $b) } keys %output_hash) {
print FILE "$output_hash{$_}\n";
}


#close output file
close (FILE);

