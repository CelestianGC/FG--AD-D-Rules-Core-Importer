#!/usr/bin/perl
#
use strict;
use warnings;
#use File::Basename;
use Data::Dumper;
use XML::Entities;
use HTML::Entities;
use XML::Simple;
use XML::Writer;
use IO::File;
use String::Util qw(trim);
use HTML::Tidy;
## use this to parse html

my %mytree = {};
my %myskills = {};
my %myitems = {};
my ($filepath,$outputfile) =  @ARGV;
my ($outputfile_skills) = $outputfile."_skills";
my ($outputfile_items) = $outputfile."_items";
my $counter = 1;
my $skipped_file = 0;
my $skills_count = 0;
my $item_count = 0;
my $simple = XML::Simple->new( );             # initialize the object

MAIN: {
    process_files();
    &as_xml();
    &as_ref_manual();
    
    ## if there are skills
    if ($skills_count > 0) {
        print "\nCreating $skills_count in $outputfile_skills also.\n";
        &as_xml_skills();
    }
    if ($item_count > 0) {
        print "\nCreating $item_count in $outputfile_items also.\n";
        &as_xml_items();
    }
    
    print "\nDone.\n";
}

sub process_files {
print "-------------> $filepath and $outputfile.xml\n";
my $counter_html = 0;

	opendir my $dir, $filepath or die "Cannot open directory: $!";
	my @files = readdir $dir;
	closedir $dir;
	
	print "Files:\n";
	@files = sort @files;
	foreach my $filename (@files) {
    if (length($filename) > 2) {
		print "opening $filepath/$filename\n";
        ## strip off trailing .ext
        (my $this_record = $filename) =~ s/\.[^.]+$//;
        ## strip off leading letters
        $this_record =~ s/^\D+(\d+)$/$1/i;
        ## now it's just a number, sorts nicely!
		open(my $fh, '<:encoding(UTF-8)', "$filepath/$filename")  or die "Could not open file '$filepath/$filename' $!";

		my $name = "UNKNOWN";
        my $source = "NOT-FOUND";
		my @desc;
		my $foundtitle = 0;
		
		while (my $row = <$fh>) {
            ## if a spell entry
            if ($row =~ /<TITLE>(.*)--\s+(\d)[a-z]+? Level (\w+) (.*)(\(.*\))<\/TITLE>/i) {
                $name = trim($1);
                my $this_level = trim($2);
                my $this_class = trim($3);
                $name = "$name, $this_class Spell Level $this_level";
                $source = trim($5);
                $foundtitle = 1;
                print "\n** FOUND SPELL PAGE, $1 in $5\n";
            } ## if
            ## anything but spell entries
            elsif ($row =~ /<TITLE>(.*)\((.*)\)<\/TITLE>/i) {
                $name = trim($1);
                $source = trim($2);
                $foundtitle = 1;
                print "\n** FOUND PAGE, $1 in $2\n";
            } ## if
            

            $row =~ s/^<p><\/p> <\/b>//gi;
            $row =~ s/\<p [^>]+?\>/<p>/gi;
            $row =~ s/\<i [^>]+?\>/<i>/gi;
            $row =~ s/\<q>/<i>/gi;
            $row =~ s/\<\/q>/<\/i>/gi;
            $row =~ s/\<a[^>]+?\>//gi;
            $row =~ s/\<\/a\>//gi;
            $row =~ s/\<\/a //gi;
            $row =~ s/\<img[^>]+?\>//gi;
            #<map name="map"> 
            $row =~ s/\<map[^>]+?\>//gi;
            #<area 
            $row =~ s/\<area[^>]+?\>//gi;
            $row =~ s/\<href[^>]+?\>//gi;
            $row =~ s/\<span[^>]+?\>//gi;
            $row =~ s/\<\/span\>//gi;
            #<table cellspacing="0" cellpadding="0"> 
            $row =~ s/\<table [^>]+?\>/<table>/gi;
            $row =~ s/\<th [^>]+?\>/<td>/gi;
            $row =~ s/\<tr [^>]+?\>/<tr>/gi;
            $row =~ s/\<\(/</gi;
            # # big hammer, tired of messing with it
            # $row =~ s/\<h2>/<b>/gi;
            # $row =~ s/\<\/h2>/<\/b>/gi;
            ## replace headers with bold and new lines
            $row =~ s/\<h\d>([^<]+)<\/h\d>/<p><b>$1<\/b><\/p>/gi;

            push (@desc, $row);
        } ## end of file while
        
        ## get @desc and push into description
		my $description = "";
		for my $i (0..$#desc) {
			$description = $description.$desc[$i];
		}
		
        # remove EOL and returns
        $description =~ tr{\n}{ }; #eol
        $description =~ tr{\r}{ }; #return
        # collect just text between <body></body>
        if ($description =~ /<body>(.*)<\/body>/i) {
            $description = $1;
        }
    
        #print "===================>DESCRIPTION\n$description\n";
        
        ## found title, so lets push 
        if ($foundtitle == 1) {
print "-------->>>>source: $source, record: $this_record\n";            
            ## ADD EVERYTING first as story entry
            $mytree{$source}{$this_record}{$name}->{'description'}=$description;
            #$mytree{$source}{$name}->{'description'}=$description;
            
            #Agriculture-- Nonweapon Proficiency
            if ($name =~ /(.*)(--) (Nonweapon Proficiency)/i) {
                #Full match	0-35	`Agriculture-- Nonweapon Proficiency`
                #Group 1.	0-11	`Agriculture`
                #Group 2.	11-13	`--`
                #Group 3.	13-35	` Nonweapon Proficiency`
                my($name_skill) = $1;
                $name_skill =~ s/--/,/g;
                $myskills{'NonweaponProf'}{$name_skill}->{'description'}=$description;
                $skills_count++;
                print ("SKILL:Found $name_skill.\n");
            } ## if nonweapon prof
            
            #Fire Breath-- Potion
            #Beaker of Plentiful Potions-- Magical Item
            #Protection from Petrification-- Scroll
            #Scimitar of Speed-- Magical Weapon
            ##print "\nNAME-============>$name\n";
            if ($name =~ /(.*)(--) ((Potion)|(Scroll)|(Magical))/i) {
                #Full match	0-21	`#Fire Breath-- Potion`
                #Group 1.	0-12	`#Fire Breath`
                #Group 2.	12-14	`--`
                #Group 3.	15-21	`Potion`
                #Group 4.	15-21	`Potion`                
                my($name_item) = "$3, $1";
                $name_item =~ s/--/,/g;
                $myitems{'ItemMagicOrOtherwise'}{$name_item}->{'description'}=$description;
                $item_count++;
                print ("ITEM:Found $name_item.\n");
                ## end potions/scrolls/etc
            } elsif ($name =~ /((staff|wand|rod|ring) of(.*))/i) {
                # Match 1
                # Full match	7-27	`Ring of the Wizardry`
                # Group 1.	7-27	`Ring of the Wizardry`
                # Group 2.	7-11	`Ring`
                # Group 3.	14-27	` the Wizardry`
                my($name_item) = "$1";
                $name_item =~ s/--/,/g;
                $name_item = trim($name_item);
                $myitems{'ItemMagicOrOtherwise'}{$name_item}->{'description'}=$description;
                $item_count++;
                print ("ITEM2:Found $name_item.\n");
            }## end rod/staff/wand/ring
            
        } else {
            print "\n*** *** Discarding file $filepath/$filename, did not find title. *** ***\n";
            $skipped_file++;
        }
        
		# reset to not
		$foundtitle = 0;
        ## on to next file
      }# file length check, windows thing for . and ..
	} # end while for files()

		foreach my $item_source (sort keys %mytree) {

            foreach my $item_record (sort keys %{ $mytree{$item_source} }) {
#			print "SOURCE: $item_source\n";
                foreach my $item_name (sort keys %{ $mytree{$item_source}{$item_record} }) {
    #				print "NAME: $item_name\n";
    #				print "Desc: ".$mytree{$item_source}${item_record}{$item_name}{'description'}."\n";
                $counter_html++;
                }
            } ## item_record
		}
		print "\n\nTotal html files accepted = $counter_html\n";
		#print Dumper(%mytree);
} # end process files        


sub cleanup_Description {
 my($this_string)=@_;

    $this_string =~ tr{\n}{ }; #eol
    $this_string =~ tr{\r}{ }; #return
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
    # big hammer, tired of fucking with it
    $this_string =~ s/\<h2>/<b>/ig;

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
 
    $this_string =~ s/\\xD7/x/gi;
    $this_string =~ s/\\xBC/1\/2/gi;
    $this_string =~ s/\\xBD/1\/2/gi;
    $this_string =~ s/\\x88/'/gi;
    $this_string =~ s/\\x9C/'/gi;
    $this_string =~ s/\\xFB/u/gi;
    $this_string =~ s/\\x88/'/gi;
    $this_string =~ s/\\x91/'/gi;
    $this_string =~ s/\\x92/'/gi;
    $this_string =~ s/\\x93/'/gi;
    $this_string =~ s/\\x94/'/gi;
    $this_string =~ s/\\x95//gi;
    $this_string =~ s/\\x96//gi;
    $this_string =~ s/\\x97//gi;
    $this_string =~ s/\\xD7/x/gi;
    $this_string =~ s/\\x..//gi;

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
    $this_string =~ s/<p>(\s+)?<p>/<p>/gi;
    $this_string =~ s/<p>(\s+)?<\/p>(\s+)?<p>(\s+)?<\/p>/<p><\/p>/gi;
    if ($this_string =~ /<body>(.*)<\/body>/i) {
        $this_string = $1;
    }
    
    #print "MARKUP_AFTER:\n$this_string\n";
    return $this_string;
} ## end find_OutOfPlaceMarkup
## encode/scape stuff
sub my_Escape {
 my($this_string)=@_;

		  $this_string =~ s/\\xD7/x/gi;
		  $this_string =~ s/\\xBC/1\/2/gi;
		  $this_string =~ s/\\xBD/1\/2/gi;
		  $this_string =~ s/\\x88/'/gi;
		  $this_string =~ s/\\x9C/'/gi;
		  $this_string =~ s/\\xFB/u/gi;
		  $this_string =~ s/\\x88/'/gi;
		  $this_string =~ s/\\x91/'/gi;
		  $this_string =~ s/\\x92/'/gi;
		  $this_string =~ s/\\x93/'/gi;
		  $this_string =~ s/\\x94/'/gi;
		  $this_string =~ s/\\x95//gi;
		  $this_string =~ s/\\x96//gi;
		  $this_string =~ s/\\x97//gi;
		  $this_string =~ s/\\xD7/x/gi;
		  $this_string =~ s/\\x..//gi;


 $this_string = encode_entities($this_string);
 $this_string = XML::Entities::numify('all',$this_string);

## return XML::Entities::numify('all',encode_entities(@_));
 
 return "$this_string";
}


# $mytree{$class}{$name}->{'description'}=$description;
# <[reference_manual_navigation_data_path]>
  # <chapters>
    # <[chapter_00]>
      # <name type="string">[Chapter Name]</name>
      # <subchapters>
        # <[subchapter_00]>
          # <name type="string">[Subchapter Name]</name>
          # <refpages>
            # <[refpage_00]>
              # <name type="string">[Page Name]</name>
              # <text type="formattedtext">[Optional. Any formatted text to display before the manual data.]</text>
              # <keywords type="string">[List of Keywords to be searchable separated by spaces]</keywords>
                # <listlink type="windowreference">
                    # <class>reference_manualtextwide</class>
                    # <recordname>..</recordname>
                    # <description field="name" />
                # </listlink>
              # <blocks>
                # <[block_01]>
                  # <blocktype type="string">[See below]</blocktype>
                  # <align type="string">[See below]</align>
                  # <size type="string">[Only used for image/token blocks. Comma delimited width and height of image/token.]</size>
                  # <frame type="string">[Only used for text blocks. See below.]</size>
                  # <image type="image"><bitmap>[Only used for image blocks. Local file path to image within the module.]</bitmap></image>
                  # <picture type="token">[Only used for token blocks. Local file path to token within the module.]</picture >
                  # <text type="formattedtext">[Only used for text blocks. Textual information to display]</text>
                  # <text2 type="formattedtext">[Only used for multi-column text blocks. Textual information to display]</text2>
                # </[block_01]>
                # ...
              # </blocks>
            # </[refpage_00]>
          # </refpages>
        # </[subchapter_00]>
        # ...
      # </subchapters>
    # </[chapter_00]>
    # ...
  # </chapters>
# </[reference_manual_navigation_data_path]>
sub as_ref_manual {
    my $output = IO::File->new("> $outputfile.client.xml");  # xml output file
    my $wr = new XML::Writer( OUTPUT => $output, 
                            DATA_MODE => 'true', 
                            DATA_INDENT => 2, 
                            UNSAFE => 'true' );

 my $this_id = 0;
 my $this_chapter = 0;
 my $this_id_chapter = "";
 
 my $this_subchapter = 0;
 my $this_id_subchapter = "";
 my $subchapter_renewed = 0;

 my $this_refpage = 0;
 my $this_id_refpage = "";
 
 my $this_block = 0;
 
 $wr->startTag('reference');
 $wr->startTag('refmanualindex');
   $wr->startTag('chapters');
   $this_chapter++;
   $this_id_chapter = sprintf("chapter-%05d", $this_chapter);
     $wr->startTag($this_id_chapter);
        $wr->startTag('name', type => "string" );
        $wr->raw( my_Escape($outputfile));
        $wr->endTag('name');
    
    ## SUBCHAPTER WIDE BLOCK
    $wr->startTag('subchapters');
        
 foreach my $this_source (sort keys %mytree) {
 print " (REF) Importing Source: $this_source\n";
 foreach my $this_record (sort keys %{ $mytree{$this_source} }) {
 foreach my $this_name (sort keys %{ $mytree{$this_source}{$this_record} })
 {
  
  if ($this_name) { 
   print " (REF) Importing Name: $this_name from record: $this_record in source: $this_source.\n";
    
   $this_id++;

   ## SUBCHAPTER
   ## either we've never had a new subchapter or the name triggers new subchapter
   if ($this_subchapter == 0 or $this_name =~ /chap|intro|credits|foreward|appendix|index|welcome|table of content/i) { ## if "Chapter" in name, just make a new sub
        $subchapter_renewed = 1;
        if ($this_subchapter != 0) {
            if ($this_refpage != 0) {
                $wr->endTag( $this_id_refpage );
                $wr->endTag('refpages');
            } ## 
            $wr->endTag( $this_id_subchapter );
            ## SUBCHAPTER END
       }
        $this_subchapter++;
        $this_id_subchapter = sprintf("subchapter-%05d", $this_subchapter);
        $wr->startTag( $this_id_subchapter );
            $wr->startTag('name', type => "string" );
            $wr->raw( my_Escape($this_name) );
            $wr->endTag('name');
    
        ## REFPAGE
        $wr->startTag('refpages');
    } else { ## end check if sub-chapter needs to be made
        $subchapter_renewed = 0;
    }

    ## either subchapters updated or we've never
    ## had a refpage yet
   
    ## REFPAGE, always add one
    $wr->endTag( $this_id_refpage ) if ($this_refpage != 0 && $subchapter_renewed != 1);
    $this_refpage++;
    $this_id_refpage = sprintf("refpage-%05d", $this_refpage);
    $wr->startTag( $this_id_refpage );
    ## Name/Keyboards
    $wr->startTag('name', type => "string" );
    $wr->raw( my_Escape($this_name) );
    $wr->endTag('name');
    $wr->startTag('keywords', type => "string" );
    $wr->raw( my_Escape($this_name) );
    $wr->endTag('keywords');
    # <listlink type="windowreference">
    $wr->startTag('listlink', type => "windowreference" );
        # <class>reference_manualtextwide</class>
        $wr->startTag('class');
        $wr->raw( "reference_manualtextwide" );
        $wr->endTag('class');
        # <recordname>..</recordname>
        $wr->startTag('recordname');
        $wr->raw( ".." );
        $wr->endTag('recordname');
        # <description field="name" />
        $wr->startTag('description', type => "field" );
        $wr->raw( "name" );
        $wr->endTag('description');
    $wr->endTag('listlink');
    
    
    ##BLOCK SECTION
    $this_block++;
    my $this_id_block = sprintf("block-%05d", $this_block);
    $wr->startTag('blocks');
    $wr->startTag( $this_id_block );
    
   ##<description type="formattedtext">FormatedText</description>
   $wr->startTag('text', type => "formattedtext" );
   my $desc_1 =  $mytree{$this_source}{$this_record}{$this_name}->{'description'};

   $desc_1 = cleanup_Description($desc_1);
   #make sure to do this... 
   $desc_1 = find_OutOfPlaceMarkup($desc_1);
   ## ...before this, so that we clean up the markup
   ## and get all the extra/bogus <p>s off the end.
   $desc_1 =~ s/table of contents//gi;
   $desc_1 =~ s/(<p>(\s+)?<\/p>(\s+)?<p>(\s+)?<\/p>)+?/<p><\/p>/gi;
   $desc_1 =~ s/((\s+)?<p>(\s+)?<\/p>(\s+)?)+?$//gi;
   ##
   
   # $wr->raw( $desc_1 );
   $wr->raw( $desc_1 );
   $wr->endTag('text');
   
   ## done with entry
   $wr->endTag( $this_id_block );
   $wr->endTag('blocks');
   ## BLOCK END
   
#--   $wr->endTag( $this_id_string );

   } ## end valid name
	
	$counter++;

	} ## end foreach
    } ## end foreach record

 } ## end foreach sp_class
 
    ## close ref/subchapters/chapters, we're done.
    $wr->endTag( $this_id_refpage );
    $wr->endTag('refpages');
    ## REFPAGE END
    $wr->endTag( $this_id_subchapter );
    ## SUBCHAPTER END
    $wr->endTag( 'subchapters' );
    ## SUBCHAPTER END WIDE
    $wr->endTag( $this_id_chapter );
    $wr->endTag( 'chapters' );
    $wr->endTag( 'refmanualindex' );
    $wr->endTag( 'reference' );

 $wr->end();
 $output->close();        
 
 print "\nTotal imported:\t$this_id.\nTotal skipped $skipped_file.\n"
 
} # end as_ref_manual 

sub as_xml {
    my $output = IO::File->new("> $outputfile.xml");  # xml output file
    my $wr = new XML::Writer( OUTPUT => $output, 
                            DATA_MODE => 'true', 
                            DATA_INDENT => 2, 
                            UNSAFE => 'true' );

 my $this_id = 0;
 
 $wr->startTag('encounter');
 foreach my $this_source (sort keys %mytree) {
 
 foreach my $this_record (sort keys %{ $mytree{$this_source} }) {
 foreach my $this_name (sort keys %{ $mytree{$this_source}{$this_record} })
 {
  
  if ($this_name) { 
   $this_id++;
   my $this_id_string = sprintf("id-%05d", $this_id);
   $wr->startTag( $this_id_string );

   print " (STORY) Importing source:$this_source record:$this_record name:$this_name (ID:$this_id_string).\n";

   ##<name type="string">NameTEXT</name>
   $wr->startTag('name', type => "string" );
   $wr->raw( my_Escape($this_name) );
   $wr->endTag('name');
   
   
   ##<description type="formattedtext">FormatedText</description>
   $wr->startTag('text', type => "formattedtext" );
   my $desc_1 =  $mytree{$this_source}{$this_record}{$this_name}->{'description'};

   $desc_1 = cleanup_Description($desc_1);
   #make sure to do this... 
   $desc_1 = find_OutOfPlaceMarkup($desc_1);
   ## ...before this, so that we clean up the markup
   ## and get all the extra/bogus <p>s off the end.
   $desc_1 =~ s/table of contents//gi;
   $desc_1 =~ s/((\s+)?<p>(\s+)?<\/p>(\s+)?)+?$//gi;
   ##
   
   # $wr->raw( $desc_1 );
   $wr->raw( $desc_1 );
   $wr->endTag('text');
   
   ## done with entry
   $wr->endTag( $this_id_string );
   } ## end valid name
	
	$counter++;
	} ## end foreach
    } ## end foreach record
 } ## end foreach sp_class
 $wr->endTag( 'encounter' );

 $wr->end();
 $output->close();        
 
 print "\nTotal imported:\t$this_id.\nTotal skipped $skipped_file.\n"
 
} # enx as_xml 

## write skills if they existed in the book?
sub as_xml_skills {
    my $output_skills = IO::File->new("> $outputfile_skills.xml");  # xml output file
    my $wr_skills = new XML::Writer( OUTPUT => $output_skills, 
                            DATA_MODE => 'true', 
                            DATA_INDENT => 2, 
                            UNSAFE => 'true' );

 my $this_id = 0;
 
 $wr_skills->startTag('skill');
 foreach my $this_source (keys %myskills) {
 
    foreach my $this_name (keys %{ $myskills{$this_source} })
    {
  
        if ($this_name) { 
            $this_id++;
            my $this_id_string = sprintf("id-%05d", $this_id);
            $wr_skills->startTag( $this_id_string );

            print " Importing Skill Name: $this_source: $this_name.\n";

            ##<name type="string">NameTEXT</name>
            $wr_skills->startTag('name', type => "string" );
            $wr_skills->raw( my_Escape($this_name) );
            $wr_skills->endTag('name');


            ##<description type="formattedtext">FormatedText</description>
            $wr_skills->startTag('text', type => "formattedtext" );
            my $desc_1 =  $myskills{$this_source}{$this_name}->{'description'};
            $desc_1 = cleanup_Description($desc_1);
            #make sure to do this... 
            $desc_1 = find_OutOfPlaceMarkup($desc_1);
            ## ...before this, so that we clean up the markup
            ## and get all the extra/bogus <p>s off the end.
            $desc_1 =~ s/table of contents//gi;
            $desc_1 =~ s/((\s+)?<p>(\s+)?<\/p>(\s+)?)+?$//gi;
            ##
            # $wr_skills->raw( $desc_1 );
            $wr_skills->raw( $desc_1 );
            $wr_skills->endTag('text');

            ## done with entry
        $wr_skills->endTag( $this_id_string );
        } ## end valid name
    } ## end foreach
 } ## end foreach sp_class
 $wr_skills->endTag( 'skill' );
 $wr_skills->end();
 $output_skills->close();        

 print "\nTotal Skills imported:\t$this_id.\n";
 
} # enx as_xml 

## write skills if they existed in the book?
sub as_xml_items {
my $output_items = IO::File->new("> $outputfile_items.xml");  # xml output file
my $wr_items = new XML::Writer( OUTPUT => $output_items, 
                            DATA_MODE => 'true', 
                            DATA_INDENT => 2, 
                            UNSAFE => 'true' );

 my $this_id = 0;
 
 $wr_items->startTag('item');
 foreach my $this_source (keys %myitems) {
 
    foreach my $this_name (keys %{ $myitems{$this_source} })
    {
  
        if ($this_name) { 
            $this_id++;
            my $this_id_string = sprintf("id-%05d", ($this_id+100));
            $wr_items->startTag( $this_id_string );

            print " Importing Item Name: $this_source: $this_name.\n";

            ##<name type="string">NameTEXT</name>
            $wr_items->startTag('name', type => "string" );
            $wr_items->raw( my_Escape($this_name) );
            $wr_items->endTag('name');


            ##<description type="formattedtext">FormatedText</description>
            $wr_items->startTag('description', type => "formattedtext" );
            my $desc_1 =  $myitems{$this_source}{$this_name}->{'description'};
            $desc_1 = cleanup_Description($desc_1);
            #make sure to do this... 
            $desc_1 = find_OutOfPlaceMarkup($desc_1);
            ## ...before this, so that we clean up the markup
            ## and get all the extra/bogus <p>s off the end.
            $desc_1 =~ s/table of contents//gi;
            $desc_1 =~ s/((\s+)?<p>(\s+)?<\/p>(\s+)?)+?$//gi;
            ##
            # $wr_items->raw( $desc_1 );
            $wr_items->raw( $desc_1 );
            $wr_items->endTag('description');

            ## done with entry
        $wr_items->endTag( $this_id_string );
        } ## end valid name
    } ## end foreach
 } ## end foreach sp_class
 $wr_items->endTag( 'item' );
 $wr_items->end();
 $output_items->close();        

 print "\nTotal Items imported:\t$this_id.\n";
 
} # done with items
