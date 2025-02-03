#! /usr/bin/perl
# Simon K. Schaefer

use strict;
use warnings;

my $counter1;
my $counter2;
my $output_suffix;
my $input_file;
my $output_file;
my $fasta_seqlong;
my $string;
my $header;
my $sequence;
my $chain;
my $chain1 = "H";
my $chain2 = "L";
my @lines;
my @file;
my @fasta80;
my %hash;
my @chain1;
my @chain2;



#############################################################
## The area below can be edited to adapt FoldX workflow    ##
#############################################################

#Switch between Ala Scan and Full Amino Acid Scan
#my @aminoacids = ("A");
my @aminoacids = ("A","C","D","E","F","G","H","I","K","L","M","N","P","Q","R","S","T","V","W","Y");

#############################################################
## The area above can be edited to adapt FoldX workflow    ##
#############################################################

my $chaincounter;

#input via commandline
$input_file = $ARGV[0];
$chain1 = $ARGV[1];
$chain2 = $ARGV[2];

$output_suffix = substr($input_file,0,int((length($input_file)))-6);

#open file and test for filetype 
if ($input_file =~ m/.*\.fasta$/i){
open(READ,"$input_file") || die "error:cant open file";
	@file = <READ>;
	#chomp (@file);
	close(READ);
}else{
	die "error:wrong file type";	
}

#iterates over all lines in the file and creates fasta format with header and content
foreach (@file){

#iterates over all lines in file 1
$string = join ("",@file);

#print "$string\n";

while ($string =~ m/(\>.*?)\n(.*?)(?=\>.?)/gis) {

	
#output header and sequence in fasta file
	#print FILE ">$13\n$12\n";
	$header = $1;
	$sequence = $2;
	chomp($header);
	chomp($sequence);
	$sequence =~ s/\R//g;
	
	if ($header =~ m/(>PDB\|)(.)/gis) {
		$chain = $2;
	}
	$hash{$chain} = $sequence;
	}


}


@chain1 = split("",$hash{$chain1});
@chain2 = split("",$hash{$chain2});


foreach (@chain1) {
$counter1++;

$chaincounter = $_;


#############################################################
## The area below can be edited to adapt FoldX workflow    ##
#############################################################
foreach (@aminoacids){

#open output file
open (FILE, ">config/$_$chaincounter$chain1$counter1") || die "problem opening $output_file\n";

#FoldX command: PSSM in this case
print FILE "command=Pssm\n";

print FILE "pdb=$output_suffix-reres.pdb\n";
print FILE "positions=";

print FILE"$chaincounter"."$chain1"."$counter1"."a\t";

print FILE "\n";
print FILE "aminoacids=$_\n";
print FILE "analyseComplexChains=$chain1,$chain2\n";
print FILE "output-dir=output/$_$chaincounter$chain1$counter1\n";

#close output file
close (FILE);

}

#############################################################
## The area above can be edited to adapt FoldX workflow    ##
#############################################################


}

$counter1 = 0;

foreach (@chain2) {
$counter1++;

$chaincounter = $_;

foreach (@aminoacids){

#open output file
open (FILE, ">config/$_$chaincounter$chain2$counter1") || die "problem opening $output_file\n";

print FILE "command=Pssm\n";
print FILE "pdb=$output_suffix-reres.pdb\n";
print FILE "positions=";

print FILE"$chaincounter"."$chain2"."$counter1"."a\t";

print FILE "\n";
print FILE "aminoacids=$_\n";
print FILE "analyseComplexChains=$chain1,$chain2\n";
print FILE "output-dir=output/$_$chaincounter$chain2$counter1\n";

#close output file
close (FILE);

}

}
