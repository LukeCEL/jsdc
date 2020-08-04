# jsdc.pl
Creates updated stellar radius catalogue for Celestia, using JSDC

## License
This is a modified version of the buildstardb.pl file that is included in Celestia. The original file can be accessed at https://github.com/CelestiaProject/Celestia/blob/master/src/tools/stardb/buildstardb.pl. Elements of this file are also taken from charm2.pl, which can be accessed here at https://github.com/CelestiaProject/Celestia/blob/master/src/tools/charm2/charm2.pl. Both original files are licensed under the GNU General Public License. Per section 5 of the GNU General Public License (v3), this version is also being released under that license.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <https://www.gnu.org/licenses/>.

## About
The official development of Celestia stopped in 2011, and most of the catalogs of astronomical objects have not been updated, even though even though we have so much more astronomical data. This script creates jsdc.stc, a file that supersedes charm2.stc. The old file, charm2.stc, used the [CHARM2 database](http://cdsarc.u-strasbg.fr/viz-bin/cat/J/A+A/431/773) to extract 1,927 stellar radii for Celestia. This one uses [JMMC Stellar Diameters Catalogue](http://cdsarc.u-strasbg.fr/viz-bin/cat/II/346) to extract 66,295 stellar radii. This file uses limb-darkened diameters only, not uniform disk diameters.

The script requires the use of [CDS' XMATCH tool](http://cdsxmatch.u-strasbg.fr). This is because the JSDC doesn't contain Hipparcos indices. To retrieve the distance values that are needed to convert the angular diameters to physical radii, I also used the stars.txt that was outputted by my [buildstardb.pl](https://github.com/LukeCEL/buildstardb) file. This circumvents having to search through multiple catalogues to find distances—because I've already done that. 

The script automatically filters out stars where the error in the diameter is greater than 3% of the diameter itself. It also filters out any stars that are not listed in stars.txt. Therefore, any stars included in revised.stc or other star catalogs will not be included here.

You should know that I'm not a very good coder and it my code may have bugs in it. So please do give feedback!

## Usage
To use this file, you need a copy of stars.dat, the star database of Celestia.

You also need a data file in CSV format from CDS' XMATCH tool, which should be named "diameters.csv". To do that, go to the [XMATCH interface](http://cdsxmatch.u-strasbg.fr). Type in `II/346/jsdc_v2` for the first table, and `I/239/hip_main` for the second table.

Then, click on the "Show options" button. You can modify the cross-match criteria. For this, I've chosen to cross-match by position, and set the limiting radius as 2 arcsec. Finally, click on the button that says "Begin the X-Match". Where it says "Get result", click on "Download as CSV". Rename the file as "diameters.csv".

## Acknowledgements
This has made use of the Jean-Marie Mariotti Center JSDC catalogue, available at http://www.jmmc.fr/catalogue_jsdc.htm, as well as the cross-match service provided by CDS, Strasbourg.

Thanks to Chris Laurel and everyone who helped create Celestia in the first place. Also, a huge thanks to Andrew Tribick (ajtribick) for creating both the original buildstardb.pl file and the charm2.pl file.

