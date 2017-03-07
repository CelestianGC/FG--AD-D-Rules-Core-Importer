#!/usr/bin/perl
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
## use this to parse html


my %mytree = {};
my %myskills = {};
my ($filepath,$outputfile) =  @ARGV; ## command line HTML PATH (without trailing slash) and outputfilename.xml
my ($outputfile_skills) = $outputfile."_skills";
my $skipped_file = 0;
my $counter = 1;
my $counter_html = 0;
my $skills_count = 0;
my $simple = XML::Simple->new( );             # initialize the object
my $output = IO::File->new("> $outputfile.xml");  # xml output file
my $output_skills = IO::File->new("> $outputfile_skills.xml");  # xml output file
my $wr = new XML::Writer( OUTPUT => $output, 
                            DATA_MODE => 'true', 
                            DATA_INDENT => 2, 
                            UNSAFE => 'true' );
                            
my $wr_skills = new XML::Writer( OUTPUT => $output_skills, 
                            DATA_MODE => 'true', 
                            DATA_INDENT => 2, 
                            UNSAFE => 'true' );

MAIN: {
    process_files();
    
    &as_xml();

    ## if there are skills
    if ($skills_count > 0) {
        print "\nCreating $skills_count in $outputfile_skills also.\n";
        &as_xml_skills();
    }

    print "\nDone.\n";    
}

sub process_files {
    print "-------------> $filepath and $outputfile\n";
        opendir my $dir, $filepath or die "Cannot open directory: $!";
        my @files = readdir $dir;
        closedir $dir;
        
        print "Files:\n";
        @files = sort @files;
        foreach my $filename (@files) {
            print "opening $filepath/$filename\n";

            open(my $fh, '<:encoding(UTF-8)', "$filepath/$filename")  or die "Could not open file '$filepath/$filename' $!";

            my $name = "UNKNOWN";
            my $source = "NOT-FOUND";
            my @desc;
            my $foundtitle = 0;
            
            while (my $row = <$fh>) {
                if ($row !~ /<TITLE>(.*)--\s+(\d).. Level (\w+) (.*)(\(.*\))<\/TITLE>/i and 
                    $row =~ /<TITLE>(.*)\((.*)\)<\/TITLE>/i) {
                    # Group 1.	9-30	`Strength`
                    # Group 2.	33-34	`Player's Handbook`

                    $name = trim($1);
                    $source = trim($2);
                    $foundtitle = 1;
                    print "\n** FOUND PAGE, $1 in $2\n";
                } ## if

                $row =~ s/^<p><\/p> <\/b>//g;
                $row =~ s/\<p [^>]+?\>/<p>/g;
                $row =~ s/\<i [^>]+?\>/<i>/g;
                $row =~ s/\<q>/<i>/g;
                $row =~ s/\<\/q>/<\/i>/g;
                $row =~ s/\<a[^>]+?\>//g;
                $row =~ s/\<\/a\>//g;
                $row =~ s/\<\/a //g;
                $row =~ s/\<img[^>]+?\>//g;
                #<map name="map"> 
                $row =~ s/\<map[^>]+?\>//g;
                #<area 
                $row =~ s/\<area[^>]+?\>//g;
                $row =~ s/\<href[^>]+?\>//g;
                $row =~ s/\<span[^>]+?\>//g;
                $row =~ s/\<\/span\>//g;
                #<table cellspacing="0" cellpadding="0"> 
                $row =~ s/\<table [^>]+?\>/<table>/g;
                $row =~ s/\<th [^>]+?\>/<td>/g;
                $row =~ s/\<tr [^>]+?\>/<tr>/g;
                $row =~ s/\<\(/</g;
                # big hammer, tired of fucking with it
                $row =~ s/\<h2>/<b>/g;
                $row =~ s/\<\/h2>/<\/b>/g;

                $row =~ s/\\xD7/x/g;
                $row =~ s/\\xBC/1\/2/g;
                $row =~ s/\\xBD/1\/2/g;
                $row =~ s/\\x88/'/g;
                $row =~ s/\\x9C/'/g;
                $row =~ s/\\xFB/u/g;
                $row =~ s/\\x88/'/g;
                $row =~ s/\\x91/'/g;
                $row =~ s/\\x92/'/g;
                $row =~ s/\\x93/'/g;
                $row =~ s/\\x94/'/g;
                $row =~ s/\\x95//g;
                $row =~ s/\\x96//g;
                $row =~ s/\\x97//g;
                $row =~ s/\\xD7/x/g;
                $row =~ s/\\x..//g;

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
                $mytree{$source}{$name}->{'description'}=$description;
                #Agriculture-- Nonweapon Proficiency
                if ($name =~ /([\w ]+)([\-]+) (Nonweapon Proficiency)/i) {
                    #Full match	0-35	`Agriculture-- Nonweapon Proficiency`
                    #Group 1.	0-11	`Agriculture`
                    #Group 2.	11-13	`--`
                    #Group 3.	13-35	` Nonweapon Proficiency`
                    $myskills{'NonweaponProf'}{$1}->{'description'}=$description;
                    $skills_count++;
                }
            } else {
                print "\n*** *** Discarding file $filepath/$filename, did not find title. *** ***\n";
                $skipped_file++;
            }

            # reset to not
            $foundtitle = 0;
            ## on to next file
        } # end while for files()

            foreach my $item_source (sort keys %mytree) {
    #			print "SOURCE: $item_source\n";
                foreach my $item_name (sort keys %{ $mytree{$item_source} }) {
    #				print "NAME: $item_name\n";
    #				print "Desc: ".$mytree{$item_source}{$item_name}{'description'}."\n";
                $counter_html++;
                }
            }
            print "\n\nTotal html files accepted = $counter_html\n";
            #print Dumper(%mytree);
}

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

## encode/scape stuff
sub my_Escape {
 my($this_string)=@_;

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


 $this_string = encode_entities($this_string);
 $this_string = XML::Entities::numify('all',$this_string);

## return XML::Entities::numify('all',encode_entities(@_));
 
 return "$this_string";
}

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
 
 return "$this_string";
 } ## end cleanup_Description

# $mytree{$class}{$name}->{'description'}=$description;
sub as_xml {
    my $this_id = 0;
 
    $wr->startTag('encounter');
    foreach my $this_source (keys %mytree) {
 
        foreach my $this_name (keys %{ $mytree{$this_source} })
        {
            if ($this_name) { 
            $this_id++;
            my $this_id_string = sprintf("id-%05d", $this_id);
            $wr->startTag( $this_id_string );

            print " Importing Name: $this_source: $this_name.\n";

            ##<name type="string">NameTEXT</name>
            $wr->startTag('name', type => "string" );
            $wr->raw( my_Escape($this_name) );
            $wr->endTag('name');


            ##<description type="formattedtext">FormatedText</description>
            $wr->startTag('text', type => "formattedtext" );
            my $desc_1 =  $mytree{$this_source}{$this_name}->{'description'};

            $desc_1 = cleanup_Description($desc_1);
            # $wr->raw( $desc_1 );
            $wr->raw( find_OutOfPlaceMarkup($desc_1) );
            $wr->endTag('text');

            ## done with entry
            $wr->endTag( $this_id_string );
            } ## end valid name

            $counter++;
        } ## end foreach
    } ## end foreach sp_class
    $wr->endTag( 'encounter' );
    $wr->end();
    $output->close();        

    print "\nTotal imported:\t$this_id.\nTotal skipped $skipped_file.\n"
} # enx as_xml 

## write skills if they existed in the book?
sub as_xml_skills {

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
            $desc_1 =~ s/Table of Contents//g;
            # $wr_skills->raw( $desc_1 );
            $wr_skills->raw( find_OutOfPlaceMarkup($desc_1) );
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



