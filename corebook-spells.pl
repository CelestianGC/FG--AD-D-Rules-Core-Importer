#!/usr/bin/perl
#
#
use strict;
use warnings;
use Data::Dumper;
use XML::Entities;
use HTML::Entities;
use XML::Simple;
use XML::Writer;
use IO::File;
use String::Util qw(trim);
use HTML::Tidy;

# <TITLE>Monster Summoning VII-- 9th Level Wizard Spell (Player's Handbook)</TITLE>
# </HEAD><BODY>
# <FONT FACE="Times New Roman" SIZE="3"><B>Monster Summoning VII</B>
# <P></P>
# </FONT><FONT FACE="Times New Roman" COLOR="#ff0000" SIZE="3"><B>(Conjuration/Summoning)</B>
# <P></P>
# </FONT><FONT FACE="Times New Roman" SIZE="3">
#<B>Reversible</B>
# <P></P>
#</FONT><TABLE><TR VALIGN=TOP><TD><FONT FACE="Times New Roman" SIZE="3">Sphere: Elemental (Fire)
# </FONT><TABLE><TR VALIGN=TOP><TD><FONT FACE="Times New Roman" SIZE="3">Range: Special
# <BR></FONT></TD><TD><FONT FACE="Times New Roman" SIZE="3">Components: V, S, M
# <BR></FONT></TD></TR><TR VALIGN=TOP><TD><FONT FACE="Times New Roman" SIZE="3">Duration: 8 rds. + 1 rd./level
# <BR></FONT></TD><TD><FONT FACE="Times New Roman" SIZE="3">Casting Time: 9
# <BR></FONT></TD></TR><TR VALIGN=TOP><TD><FONT FACE="Times New Roman" SIZE="3">Area of Effect: 90-yd. radius
# <BR></FONT></TD><TD><FONT FACE="Times New Roman" SIZE="3">Saving Throw: None
# <BR></FONT></TD></TR></TABLE><FONT FACE="Times New Roman" SIZE="3">
# <P></P>

# <P></P>
 # This spell is much like the 3rd-level spell <I>monster summoning I</I>, except that this spell summons one or two 7th-level monsters that appear one
# round after the spell is cast, or one 8th-level monster that appears two
# rounds after the spell is cast.
# <P></P>

# <P></P>
# <A HREF="DD01405.htm#e6fca08a"></A></FONT><FONT FACE="Times New Roman" COLOR="#008000" SIZE="3"><A HREF="DD01405.htm#e6fca08a">Table of Contents</A></FONT><FONT FACE="Times N
# <P></P>
# </FONT></BODY>
# </HTML>


##### these spells need to be fixed, they are spells but the titles are wrong
# DD01853.htm:<TITLE>Second-Level Spells-- Wizard (Player's Handbook)</TITLE>
# DD01896.htm:<TITLE>Third-Level Spells-- Wizard (Player's Handbook)</TITLE>
# DD01974.htm:<TITLE>Fifth-Level Spells-- Wizard (Player's Handbook)</TITLE>
# DD02014.htm:<TITLE>Sixth-Level Spells-- Wizard (Player's Handbook)</TITLE>
# DD02054.htm:<TITLE>Seventh-Level Spells-- Wizard (Player's Handbook)</TITLE>
# DD02080.htm:<TITLE>Eighth-Level Spells-- Wizard (Player's Handbook)</TITLE>
# DD02102.htm:<TITLE>Ninth-Level Spells-- Wizard (Player's Handbook)</TITLE>
# DD02121.htm:<TITLE>First-Level Spells-- Priest (Player's Handbook)</TITLE>
# DD02145.htm:<TITLE>Second-Level Spells-- Priest (Player's Handbook)</TITLE>
# DD02173.htm:<TITLE>Third-Level Spells-- Priest (Player's Handbook)</TITLE>
# DD02203.htm:<TITLE>Fourth-Level Spells-- Priest (Player's Handbook)</TITLE>
# DD02228.htm:<TITLE>Fifth-Level Spells-- Priest (Player's Handbook)</TITLE>
# DD02251.htm:<TITLE>Sixth-Level Spells-- Priest (Player's Handbook)</TITLE>
# DD02273.htm:<TITLE>Seventh-Level Spells-- Priest (Player's Handbook)</TITLE>
# DD03617.htm:  <TITLE>First-Level Spells-- Wizard (Spells and Magic)</TITLE>
# DD03623.htm:  <TITLE>Second-Level Spells-- Wizard (Spells and Magic)</TITLE>
# DD03628.htm:  <TITLE>Third-Level Spells-- Wizard (Spells and Magic)</TITLE>
# DD03634.htm:  <TITLE>Fourth-Level Spells-- Wizard (Spells and Magic)</TITLE>
# DD03641.htm:  <TITLE>Fifth-Level Spells-- Wizard (Spells and Magic)</TITLE>
# DD03648.htm:  <TITLE>Sixth-Level Spells-- Wizard (Spells and Magic)</TITLE>
# DD03654.htm:  <TITLE>Seventh-Level Spells-- Wizard (Spells and Magic)</TITLE>
# DD03658.htm:  <TITLE>Eighth-Level Spells-- Wizard (Spells and Magic)</TITLE>
# DD03661.htm:  <TITLE>Ninth-Level Spells-- Wizard (Spells and Magic)</TITLE>
# DD03664.htm:<TITLE>First-Level Spells-- Priest (Spells and Magic)</TITLE>
# DD03676.htm:<TITLE>Second-Level Spells-- Priest (Spells and Magic)</TITLE>
# DD03685.htm:<TITLE>Third-Level Spells-- Priest (Spells and Magic)</TITLE>
# DD03696.htm:<TITLE>Fourth-Level Spells-- Priest (Spells and Magic)</TITLE>
# DD03704.htm:<TITLE>Fifth-Level Spells-- Priest (Spells and Magic)</TITLE>
# DD03710.htm:<TITLE>Sixth-Level Spells-- Priest (Spells and Magic)</TITLE>
# DD03713.htm:<TITLE>Seventh-Level Spells-- Priest (Spells and Magic)</TITLE>

my ($filepath,$outputfile) =  @ARGV;

my %mytree = {};
#my $filepath = "spellshtml/all";
my $counter = 1;
my $counter_html = 0;
MAIN: {
    
    print "Import files at [$filepath] and output as [$outputfile.xml] \n";
    
    process_files();
    &as_xml();
    
    print "Total Spells: $counter\n";
    print "\nDone.\n";
}

sub process_files{
	opendir my $dir, $filepath or die "Cannot open directory: $!";
	my @files = readdir $dir;
	closedir $dir;
	
	print "Files:\n";
	@files = sort @files;
	foreach my $filename (@files) {
		print "$filepath/$filename\n";

		open(my $fh, '<:encoding(UTF-8)', "$filepath/$filename")  or die "Could not open file '$filepath/$filename' $!";

		my $name = "UNKNOWN";
		my $level = "1";
		my $class = "Wizard";
		my $range = "";
		my $components = "V, S, M";
		my $duration = "";
		my $casttime = "";
		my $aoe = "";
		my $save = "None";
		my $school = "";
		my $sphere = "";
		my $source = "NA";
		my $reverse = 0;
		my @desc;
		my $in_start = 0;
		my $foundtitle = 0;
		
		while (my $row = <$fh>) {
		  #chomp $row;

            $row = cleanup_Description($row);

		  if ($row =~ /<TITLE>(.*)--\s+(\d).. Level (\w+) (.*)(\(.*\))<\/TITLE>/i) {
			# Group 1.	9-30	`Monster Summoning VII`
			# Group 2.	33-34	`9`
			# Group 3.	43-49	`Wizard`
			# Group 4.	50-56	`Spell `
			# Group 5.	56-75	`(Player's Handbook)`

			$name = $1;
			$level = $2;
			$class = $3;
			$source = $5;
			$foundtitle = 1;
            #$name = findNewName($name);
			print "\n** FOUND SPELL, Class:$class, Name:$name, Lev:$level\n";
		  }

		# </FONT><FONT FACE="Times New Roman" COLOR="#ff0000" SIZE="3"><B>(Conjuration/Summoning)</B>
		  if ($row =~ /(<B>\((.*)\)<\/B>)/i) {
			#Group 1.	242-272	`<B>(Conjuration/Summoning)</B>`
			#Group 2.	246-267	`Conjuration/Summoning`
			$school = trim($2);
			print "Found School: $school\n";
		  }
			# </FONT><TABLE><TR VALIGN=TOP><TD><FONT FACE="Times New Roman" SIZE="3">Range: Special
		  if ($row =~ /(Range:(.*))/i ){
			#Group 1.	414-428	`Range: Special`
			#Group 2.	420-428	` Special`
			$range = trim($2);
			print "Found range: $range\n";
		  }
			#<B>Reversible</B>
		  if ($row =~ /(<B>Reversible<\/B>)/i) {
			#Full match	969-986	`<B>Reversible</B>`
			#Group 1.	969-986	`<B>Reversible</B>`
			$reverse = 1;
			print "Found reverse: $reverse\n";
		  }

			# <BR></FONT></TD><TD><FONT FACE="Times New Roman" SIZE="3">Components: V, S, M
		  if ($row =~ /(Components:(.*))/i) {
			#Group 1.	489-508	`Components: V, S, M`
			#Group 2.	500-508	` V, S, M`
			$components= trim($2);
			print "Found components: $components\n";
		  }
			# <BR></FONT></TD></TR><TR VALIGN=TOP><TD><FONT FACE="Times New Roman" SIZE="3">Duration: 8 rds. + 1 rd./level
		  if ($row =~ /(Duration:(.*))/i) {
			$duration = trim($2);
			print "Found duration: $duration\n";
		  }
			# <BR></FONT></TD><TD><FONT FACE="Times New Roman" SIZE="3">Casting Time: 9
		  if ($row =~ /(Casting Time:(.*))/i) {
			$casttime = trim($2);
			print "Found casttime: $casttime\n";
		  }
			# <BR></FONT></TD></TR><TR VALIGN=TOP><TD><FONT FACE="Times New Roman" SIZE="3">Area of Effect: 90-yd. radius
		  if ($row =~ /(Area of Effect:(.*))/i) {
			$aoe = trim($2);
			print "Found aoe: $aoe\n";
		  }

			#</FONT><TABLE><TR VALIGN=TOP><TD><FONT FACE="Times New Roman" SIZE="3">Sphere: Elemental (Fire)
		  if ($row =~ /(Sphere:(.*))/i) {
			$sphere = trim($2);
			print "Found sphere: $sphere\n";
		  }


		  ## THIS IS THE LAST THING LISTED! After this should be description
		  # <BR></FONT></TD><TD><FONT FACE="Times New Roman" SIZE="3">Saving Throw: None
		  if ($row =~ /(Saving Throw:(.*))/i) {
			$save = trim($2);
			# get this and we're now to the "Description" block
			$in_start = 1;
		  }
		  
		  # we're at end of the html file
		  if ($row =~ /(>Table of Contents<)|(<\/html\>)/i) {
			#Full match	1386-1405	`>Table of Contents<`
			#Group 1.	1386-1405	`>Table of Contents<`
			#Match 2
			#Full match	1464-1471	`</HTML>`
			#Group 2.	1464-1471	`</HTML>`
			$in_start = 0;
		  }
		  
		  if ($#desc <= 1 && $row =~ /(<BR><\/FONT><\/TD><\/TR><\/TABLE>)/i) {
			# skip this
			$row =~ s/(<BR><\/FONT><\/TD><\/TR><\/TABLE>)//ig; # end of stuff from cast/save/range/etc table
		  }
			push (@desc, $row) if ($in_start ==1);
		  
		}
		my $description = "";
		my $start_clean = 0;
		for my $i (1..$#desc) {
			if (($start_clean == 0) && ($desc[$i] =~ /^<P><\/P>/i)) {
				$start_clean = 1;
			}
			if ($start_clean == 1 ) {
				# if ($desc[$i] =~ /^<B>$/i) {
					# print "---------------->Solo <B> in $name??? Fix it.. $filepath/$filename\n";
				# } 
			# #				print "--$i : ".$desc[$i]."\n";
				$description = $description.$desc[$i];
			} else {
#				print "--$i IGNORING: ".$desc[$i]."\n";
			}
		}
		
		if ($foundtitle == 1) {
			$mytree{$class}{$name}->{'description'}=cleanup_Description($description);
			$mytree{$class}{$name}->{'level'}=$level;
			$mytree{$class}{$name}->{'range'}=$range;
			$mytree{$class}{$name}->{'components'}=$components;
			$mytree{$class}{$name}->{'duration'}=$duration;
			$mytree{$class}{$name}->{'casttime'}=$casttime;
			$mytree{$class}{$name}->{'aoe'}=$aoe;
			$mytree{$class}{$name}->{'save'}=$save;
			$mytree{$class}{$name}->{'school'}=$school;
			$mytree{$class}{$name}->{'sphere'}=$sphere;
			$mytree{$class}{$name}->{'source'}=$source;
			$mytree{$class}{$name}->{'reverse'}=$reverse;
		} else {
			print "\n*** *** Discarding file $filepath/$filename, did not find title. *** ***\n";
		}

		# reset to not
		$in_start = 0;
		$foundtitle = 0;
		$reverse = 0;

	} # end while for files()

		foreach my $sp_class (sort keys %mytree) {
			print "CLASS: $sp_class\n";
			foreach my $sp_name (sort keys %{ $mytree{$sp_class} }) {
				print "Name: $sp_name\n";
				#print "Save: ".$mytree{$sp_class}{$sp_name}->{'save'}."\n";
				print "Desc: ".$mytree{$sp_class}{$sp_name}{'description'}."\n";
			$counter_html++;
			}
		}
		print "\n\nTotal html files accepted = $counter_html\n";
		#print Dumper(%mytree);
} 

sub findNewName {
    my ($name) = @_;
    
    foreach my $keyClass (keys %mytree) {
        foreach my $keyName (keys %{$mytree{$keyClass}}) {
            my ($this_name) = $keyName;
            if ($this_name =~ /^$name$/i) {
            print "RAN INTO DUPLICENAME: $name\n.";
                $name = findNewName($name."X");
                last;
            }
        }
    }
    
    return $name;
}
        

# $mytree{$class}{$name}->{'description'}=$description;
# $mytree{$class}{$name}->{'level'}=$level;
# $mytree{$class}{$name}->{'range'}=$range;
# $mytree{$class}{$name}->{'components'}=$components;
# $mytree{$class}{$name}->{'duration'}=$duration;
# $mytree{$class}{$name}->{'casttime'}=$casttime;
# $mytree{$class}{$name}->{'aoe'}=$aoe;
# $mytree{$class}{$name}->{'save'}=$save;
# $mytree{$class}{$name}->{'school'}=$school;
# $mytree{$class}{$name}->{'sphere'}=$sphere;
# $mytree{$class}{$name}->{'source'}=$source;
# $mytree{$class}{$name}->{'reverse'}=$reverse;
sub as_xml {
    my $simple = XML::Simple->new( );             # initialize the object
    my $output = IO::File->new("> $outputfile.xml");
            
    use XML::Writer;
    #my $wr = new XML::Writer( DATA_MODE => 'true', DATA_INDENT => 2 );
    my $wr = new XML::Writer( OUTPUT => $output, DATA_MODE => 'true', DATA_INDENT => 2, UNSAFE => 'true' );

 my $this_id = 0;
 my $this_missed = 0;
 
 $wr->startTag('spell');
 foreach my $this_class (keys %mytree) {
 
 foreach my $thiskey (keys %{ $mytree{$this_class} })
 {
  
  if ($thiskey) { 
   $this_id++;
   my $this_id_string = sprintf("id-%05d", $this_id);
   $wr->startTag( $this_id_string );

   print " Importing Name: $thiskey.\n";

   ##<name type="string">NameTEXT</name>
   $wr->startTag('name', type => "string" );
   $wr->raw( my_Escape($thiskey) );
   $wr->endTag('name');
   
   ##<castingtime type="string">CastTimeText</castingtime>
   $wr->startTag('castingtime', type => "string" );
   $wr->raw( my_Escape($mytree{$this_class}{$thiskey}->{'casttime'}) );
   $wr->endTag('castingtime');
   
   ##<components type="string">ComponentsText</components>
   $wr->startTag('components', type => "string" );
   $wr->raw( my_Escape($mytree{$this_class}{$thiskey}->{'components'}) );
   $wr->endTag('components');
   
   ##<description type="formattedtext">FormatedText</description>
   $wr->startTag('description', type => "formattedtext" );
   my $desc_1 =  $mytree{$this_class}{$thiskey}->{'description'};
    
    $desc_1 = highlight_Description($desc_1);
    $desc_1 = find_OutOfPlaceMarkup($desc_1);
    
   ## replace only the ones after a period.
#   $desc_1 =~ s/\.(\/\/n)/\.<\/p\>\<p\>/g; # new line

   $desc_1 =~ s/table of contents//gi;
   $desc_1 =~ s/((\s+)?<p>(\s+)?<\/p>(\s+)?)+?$//gi;
   
   
   # $wr->raw( $desc_1 );
   $wr->raw( $desc_1 );
   $wr->endTag('description');
   
   ##<duration type="string">DurationText</duration>
   $wr->startTag('duration', type => "string" );
   $wr->raw( my_Escape($mytree{$this_class}{$thiskey}->{'duration'}) );
   $wr->endTag('duration');

   ##<level type="number">1</level>
   $wr->startTag('level', type => "number" );
   $wr->raw( my_Escape($mytree{$this_class}{$thiskey}->{'level'}) );
   $wr->endTag('level');

   ##<range type="string">RangeText</range>
   $wr->startTag('range', type => "string" );
   $wr->raw( my_Escape($mytree{$this_class}{$thiskey}->{'range'}) );
   $wr->endTag('range');

   ##<school type="string">SchoolTEXT</school>
   $wr->startTag('school', type => "string" );
   $wr->raw( my_Escape($mytree{$this_class}{$thiskey}->{'school'}) );
   $wr->endTag('school');

   ##<shortdescription type="string">SummaryText</shortdescription>
   my $shortdesc = "Range: ".$mytree{$this_class}{$thiskey}->{'range'}.
                   ", AoE: ".$mytree{$this_class}{$thiskey}->{'aoe'}.
                   ", Duration: ".$mytree{$this_class}{$thiskey}->{'duration'}.
                   ", Cast Time: ".$mytree{$this_class}{$thiskey}->{'casttime'}."".
                   ", Save: ".$mytree{$this_class}{$thiskey}->{'save'}."";
   $wr->startTag('shortdescription', type => "string" );
   $wr->raw( my_Escape($shortdesc) );
   $wr->endTag('shortdescription');


   ##<aoe type="string">30 foot radius</name>
   $wr->startTag('aoe', type => "string" );
   $wr->raw( my_Escape($mytree{$this_class}{$thiskey}->{'aoe'}) );
   $wr->endTag('aoe');

   ##<sphere type="string">Animal</name>
   $wr->startTag('sphere', type => "string" );
   $wr->raw( my_Escape($mytree{$this_class}{$thiskey}->{'sphere'}) );
   $wr->endTag('sphere');
   
   ##<save type="string">None</name>
   $wr->startTag('save', type => "string" );
   $wr->raw( my_Escape($mytree{$this_class}{$thiskey}->{'save'}) );
   $wr->endTag('save');
   
   ##<type type="string">Arcane | Divine</name>
   my $mytype = "Arcane";
   if ($this_class !~ /Wizard/i) {
		$mytype = "Divine";
   }
   $wr->startTag('type', type => "string" );
   $wr->raw( $mytype );
   $wr->endTag('type');

   ##<source type="string">Arcane | Divine</name>
   $wr->startTag('source', type => "string" );
   $wr->raw( my_Escape("AD&D Core Rules") );
   $wr->endTag('source');

   ##<reversible type="number">0</ritual>
   $wr->startTag('reversible', type => "number" );
   $wr->raw( my_Escape($mytree{$this_class}{$thiskey}->{'reverse'}) );
   $wr->endTag('reversible');
   
   ##<ritual type="number">0</ritual>
   $wr->startTag('ritual', type => "number" );
   $wr->raw( 0 );
   $wr->endTag('ritual');

   ##<locked type="number">1</locked>
   $wr->startTag('locked', type => "number" );
   $wr->raw( 1 );
   $wr->endTag('locked');

   
   ## done with entry
   $wr->endTag( $this_id_string );
   } ## end valid name
	
	$counter++;
	} ## end foreach
 } ## end foreach sp_class
 $wr->endTag( 'spell' );
 
 print "Ignored total:\t$this_missed\nTotal imported:\t$this_id.\n";
 $wr->end();
 $output->close();        

} # enx as_xml 


sub highlight_Description {
    my($desc) = @_;
    
    ## highlight/bold stuff that causes half damage
    $desc =~ s/((^|<\/p>|[^\.]+) (cause(s)?|inflict(s)?) only half([^\.]+|$))/<b><u>$1<\/u><\/b>/gim;

    ## highlight anything with "save versus" "saving throw versus"
    $desc =~ s/((^|<\/p>|[^\.]+)?(Saving(s)? throw(s)?|save) (versus|vrs|vrs\.|v|v\.|vs\.) ([^\.]+|$))/<b><u>$1<\/u><\/b>/gim;

    ## dice rolls
    $desc =~ s/(\d+[\-dD]\d+([\+\-]\d+)?)/<b>$1<\/b>/gim;
    
    return $desc;
} ##



## encode/scape stuff
sub my_Escape {
 my($this_string)=@_;

 $this_string = encode_entities($this_string);
 $this_string = XML::Entities::numify('all',$this_string);

## return XML::Entities::numify('all',encode_entities(@_));
 
 return "$this_string";
}

sub cleanup_Description {
 my($this_string)=@_;

    $this_string =~ tr{\n}{ }; #eol
    $this_string =~ tr{\r}{ }; #return
    
    $this_string =~ s/\\xD7/x/g;
    $this_string =~ s/\\xBC/1\/2/g;
    $this_string =~ s/\\xBD/1\/2/g;
    $this_string =~ s/\\x88/'/g;
    $this_string =~ s/\\x9C/'/g;
    $this_string =~ s/\\xFB/u/g;
    $this_string =~ s/\\x88/'/g;
    $this_string =~ s/\\x91/'/g;
    $this_string =~ s/\\x92/'/g;
    $this_string =~ s/\\x93/'/g;
    $this_string =~ s/\\x94/'/g;
    $this_string =~ s/\\x95//g;
    $this_string =~ s/\\x96//g;
    $this_string =~ s/\\x97//g;
    $this_string =~ s/\\xD7/x/g;
    $this_string =~ s/\\x..//g;
    
    $this_string =~ s/^<p><\/p> <\/b>//ig;
    #   $this_string =~ s/(<BR><\/FONT><\/TD><\/TR><\/TABLE>)//ig; # end of stuff from cast/save/range/etc table
    $this_string =~ s/(<FONT([^>]+)?>)//ig; ## chuck all <FONT
    $this_string =~ s/(<\/FONT>)//ig; ## chuck all </FONT
    $this_string =~ s/(<A([^>]+)?>([^<]+)?<\/A>)   //ig; ## chuck all <a something=osdjfgn>some wasted text</a>

    $this_string =~ s/\<small\>//ig; # remove <small/small>
    $this_string =~ s/\<\/small\>//ig; # 
    $this_string =~ s/\<th\>/<td>/ig; # swap th for td
    $this_string =~ s/\<\/th\>/<\/td>/ig; # 
    $this_string =~ s/\<br([^<]+)?\>//ig; #<br>
    $this_string =~ s/\<b ([^<]+)?\>/<b>/ig; #<b *>
    #<table class="ip">
    #   $this_string =~ s/\<table class\=\"ip\"\>/<table>/g; 
    $this_string =~ s/\<table[ ^>]+>/<table>/ig; 
    #<tr class="bk">
    #   $this_string =~ s/\<tr class\=\"bk\"\>/<tr>/g;  
    $this_string =~ s/\<tr [^>]+>/<tr>/ig;  
    #<tr class="cn">
    #   $this_string =~ s/\<tr class\=\"cn\"\>/<tr>/g;  
    $this_string =~ s/\<tr [^>]+>/<tr>/ig;  
    $this_string =~ s/\<td [^>]+>/<td>/ig;  
    #<ol></ol>
    $this_string =~ s/\<ol\>//ig;  
    $this_string =~ s/\<\/ol\>//ig;  
    $this_string =~ s/\<ul\>//ig;  
    $this_string =~ s/\<ul[^>]+?\>//ig; #<ul>
    $this_string =~ s/\<\/ul\>//ig;  
    $this_string =~ s/\<p [^>]+?\>/<p>/ig;
    $this_string =~ s/\<i [^>]+?\>/<i>/ig;
    $this_string =~ s/\<q>/<i>/ig;
    $this_string =~ s/\<\/q>/<\/i>/ig;
    $this_string =~ s/\<a[^>]+?\>//ig;
    $this_string =~ s/\<\/a\>//ig;
    $this_string =~ s/\<\/a //ig;
    $this_string =~ s/\<img[^>]+?\>//ig;
    #<map name="map"> 
    $this_string =~ s/\<map[^>]+?\>//ig;
    #<area 
    $this_string =~ s/\<area[^>]+?\>//ig;
    $this_string =~ s/\<href[^>]+?\>//ig;
    $this_string =~ s/\<span[^>]+?\>//ig;
    $this_string =~ s/\<\/span\>//ig;
    #<table cellspacing="0" cellpadding="0"> 
    $this_string =~ s/\<table [^>]+?\>/<table>/ig;
    $this_string =~ s/\<th [^>]+?\>/<td>/ig;
    $this_string =~ s/\<tr [^>]+?\>/<tr>/ig;
    $this_string =~ s/\<\(/</ig;
    # replace all <hX> with <p><b>/etc...
    $this_string =~ s/\<h\d>([^<]+)<\/h\d>/<p><b>$1<\/b><\/p>/g;

    $this_string =~ s/<\/html>//ig; 
    $this_string =~ s/<\/body>//ig; 

    $this_string =~ s/<TR>/<tr>/g; # FG seems case sensitive on these
    $this_string =~ s/<\/TR>/<\/tr>/g; # FG seems case sensitive on these
    $this_string =~ s/<TD>/<td>/g; # FG seems case sensitive on these
    $this_string =~ s/<\/TD>/<\/td>/g; # FG seems case sensitive on these
    $this_string =~ s/<TABLE>/<table>/g; # FG seems case sensitive on these
    $this_string =~ s/<\/TABLE>/<\/table>/g; # FG seems case sensitive on these
    $this_string =~ s/<P>/<p>/g; # FG seems case sensitive on these
    $this_string =~ s/<\/P>/<\/p>/g; # FG seems case sensitive on these
    $this_string =~ s/<B>/<b>/g; # FG seems case sensitive on these
    $this_string =~ s/<\/B>/<\/b>/g; # FG seems case sensitive on these
    $this_string =~ s/<I>/<i>/g; # FG seems case sensitive on these
    $this_string =~ s/<\/I>/<\/i>/g; # FG seems case sensitive on these
 
 return "$this_string";
 } ## end cleanup_Description

## fix broken html 
sub find_OutOfPlaceMarkup {
    my($this_string)=@_;
    
    #print "MARKUP_BEFORE:\n$this_string\n";
#    my $tidy = HTML::Tidy->new();
    my $tidy = HTML::Tidy->new( {
                                    #'wrap-sections' => 0,
                                    #'enclose-block-text' => 0,
                                    'enclose-text' => 0,
                                    #'output-xhtml' => 0,
                                    #'tidy-mark' => 0,
                                    
                                    'char-encoding' => 'utf8',
                                    'output-encoding' => 'utf8',
                                    'output-html' => 0,
                                    'numeric-entities' => 0,
                                    'ascii-chars' => 1,
                                    'doctype' => 'loose',
                                    'clean' => 0,
                                    'bare' => 0,
                                    'fix-uri' => 1,
                                    'indent' => 0,
                                    'indent-spaces' => 2,
                                    'tab-size' => 2,
                                    'wrap-attributes' => 0,
                                    'wrap' => 0,
                                    'indent-attributes' => 0,
                                    'join-classes' => 0,
                                    'join-styles' => 0,
                                    'fix-bad-comments' => 1,
                                    'fix-backslash' => 0,
                                    'replace-color' => 0,
                                    'wrap-asp' => 0,
                                    'wrap-jste' => 0,
                                    'wrap-php' => 0,
                                    'wrap-sections' => 0,
                                    'drop-proprietary-attributes' => 0,
                                    'hide-comments' => 0,
                                    'hide-endtags' => 0,
                                    'drop-empty-paras' => 0,
                                    'quote-ampersand' => 0,
                                    'quote-marks' => 0,
                                    'quote-nbsp' => 0,
                                    'vertical-space' => 1,
                                    'wrap-script-literals' => 0,
                                    'tidy-mark' => 0,
                                    'merge-divs' => 0,
                                    'break-before-br' => 0                                    
                                } );
    #$tidy->parse( $this_string );
    #for my $message ( $tidy->messages ) {
    #    print $message->as_string;
    #}
    $this_string = $tidy->clean($this_string);

    $this_string =~ tr{\n}{ }; #eol
    $this_string =~ tr{\r}{ }; #return

    # find any new paragraphs <p> followed by another <p>. Lots of them in the html files
    # replace them with a single <p> otherwise FG complains
    $this_string =~ s/<p>(\s+)?<p>/<p>/g; 
    
    if ($this_string =~ /<body>(.*)<\/body>/i) {
        $this_string = $1;
    }
    
    #print "MARKUP_AFTER:\n$this_string\n";
    return $this_string;
} ## end find_OutOfPlaceMarkup
 