#!/usr/bin/perl

# jsdc.pl
#
# Builds jsdc.stc file for Celestia
#
# Version 2.1 - LukeCEL (2020-02-23)

use Math::Trig;
use strict;

# default file paths
my $JSDC_PATH  = 'diameters.csv';
my $STARS_PATH = 'stars.dat';
my $TXT_PATH  = 'jsdc.stc';

# conversion constants
my $MAS_TO_DEG = 3600000;
my $LY_TO_KM = 9460730472580.8;

# data stored in these arrays
my %stars = (); # star details

ReadRadii();
ReadStars();
CheckStars();
WriteStc();

# ---------------------------- END OF MAIN PROGRAM --------------------------- #

# --------------------------- INPUT/OUTPUT FUNCTIONS ------------------------- #

# Read the Astrometric Catalogue into associative array
sub ReadRadii
{
	print "Reading Cross-Matched Catalogues...\n";

	local(*JSDCFILE);
	if(!open(JSDCFILE, '<', $JSDC_PATH))
	{
		print "  ERROR: Could not open $JSDC_PATH\n";
		return;
	}

	my $numStars = 0;
	while (my $curLine = <JSDCFILE>)
	{
		next if $. < 2;

		chomp $curLine;

		# split into separate fields using commas
		my @fields = split(',', $curLine);

		my $HIP = $fields[3];

		my %star = (
			'LDD'    => $fields[32],
			'e_LDD'    => $fields[33],
		);

		$stars{$HIP} = {
			'LDD'       => $star{'LDD'},
			'e_LDD'     => $star{'e_LDD'},
			'Dist'      => ''
		};

		$numStars++;
	}

	close(JSDCFILE);
	print "  Read a total of $numStars records.\n";
}

sub ReadStars
{
	print "Reading stars.dat file...\n";

    open STARS, '<', $STARS_PATH or die "Cannot open stars.dat for reading.\n";
    binmode STARS;
    
    # read file header: test whether this is a star database and get number of stars
    read(STARS, my $buf, 14);
    
    my ($fileType, $version, $numStars) = unpack('A8SL', $buf);
    
    die "Bad stars.dat format" if(($fileType ne 'CELSTARS') || ($version != 0x0100));
    
    for (my $i = 0; $i < $numStars; $i++) {
        read(STARS, $buf, 20);
        my ($HIP, $x, $y, $z) = unpack('Lfffx4', $buf); # don't need magnitude or spectral type
        if(exists $stars{$HIP}) {
            $stars{$HIP}{'Dist'} = sqrt($x * $x + $y * $y + $z * $z);
        }
    }
    
    close(STARSFILE);
	
	print "  Read a total of $numStars records.\n";
}

sub WriteStc
{
	my $numStars = keys %stars;
	print "Writing files...\n";
	
	print "  Writing text database to $TXT_PATH\n";
	local(*TXTFILE);
	open(TXTFILE, '>', $TXT_PATH) or die "ERROR: Could not write to $TXT_PATH\n";
	
	# write file header
	print TXTFILE "# Updated Catalogue of Stellar Radii for Celestia\n";
	print TXTFILE "# Version 1.0 (2018-12-22)\n";
	print TXTFILE "# LukeCEL, made from a script modified from one by Andrew Tribick\n";
	print TXTFILE "#\n";
	print TXTFILE "# Bourges, L et al. (2017), ASP 485, 223\n";
	print TXTFILE "# The JMMC Stellar Diameters Catalog v2 (JSDC): A New Release Based on\n";
	print TXTFILE "# SearchCal Improvements\n";
	print TXTFILE "#\n";
	print TXTFILE "# This catalogue was made using a Perl script, jsdc.pl. Stellar radii were\n";
	print TXTFILE "# calculated from angular diameters and distances. Limb-darkened disk\n";
	print TXTFILE "# diameters were taken from the JMMC Stellar Diameters Catalogue (JSDC v2.0)\n";
	print TXTFILE "# and cross-matched with the Hipparcos Catalogue using the CDS XMATCH tool.\n";
	print TXTFILE "# Distances were read from Celestia's binary-format star database\n";
	print TXTFILE "# (stars.dat). Only diameters where the error is less than 3% of the\n";
	print TXTFILE "# value itself are used.\n\n";
	
	# write each star
	foreach my $HIP (sort { $a <=> $b } keys %stars)
	{
		my $dist = $stars{$HIP}{'Dist'};
		my $ldd = $stars{$HIP}{'LDD'};
		my $e_ldd = $stars{$HIP}{'e_LDD'};
		my $radius = AngularToPhysical($dist, $ldd);

		print TXTFILE "Modify $HIP\n{\n\tRadius ";
		print TXTFILE sprintf('%.0f', sprintf('%.4g', $radius));
		print TXTFILE sprintf(" # Diameter = %s +/- %s mas\n}\n\n", $ldd, $e_ldd);
	}
	
	close(TXTFILE);
	
	print "  Wrote a total of $numStars stars.\n";
}

# -------------------------- DATA HANDLING ROUTINES -------------------------- #

# drop stars with bad data
sub CheckStars
{
	print "Checking data...\n";
	my $good = 0;
	my $higherror = 0;
	my $missingdist = 0;

	foreach my $HIP (keys %stars)
	{
		# print "$HIP\n";
		my $badness = TestDubious($stars{$HIP});
		if ($badness == 0)
		{
			# good stars are fine
			$good++;
		}
		elsif ($badness >= 1)
		{
			delete $stars{$HIP};
			$higherror++;
			# print "HIP $HIP\n";
		}

	}
	print "  $good stars with good data included.\n";
	print "  $higherror stars dropped.\n";
}

# reject stars 
sub TestDubious
{
	my $star = shift;
	my $dubious = 0;

	# if there is no distance information, we can't include this
	$dubious = 1 if($star->{'Dist'} eq '');

	# if there is no diameter information, we can't include this
	$dubious = 2 if($star->{'LDD'} eq '');
	
	# if diameter error is greater than 3 percent of the diameter, reject
	if ($star->{'LDD'} ne '')
	{
		$dubious = 3 if(($star->{'e_LDD'} * 0.03 gt $star->{'LDD'}));
	}
	
	# otherwise the star is fine
	return $dubious;
}

# ------------------------ ASTROPHYSICAL CALCULATIONS ------------------------ #

# convert angular diameter in milliarcseconds to physical radius in km
sub AngularToPhysical
{
	my $dist = shift;
	my $ldd = shift;

	my $dist = $dist * $LY_TO_KM; # convert distance in ly to km
	my $ldd = $ldd / $MAS_TO_DEG; # convert diameter in mas to degrees
	return (tan(deg2rad($ldd)/2) * $dist);
}
