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
my ($filepath,$outputfile) =  @ARGV;
my $counter = 1;
my $skipped_file = 0;

MAIN: {
    process_files();
    &as_xml();
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
		print "opening $filepath/$filename\n";

		open(my $fh, '<:encoding(UTF-8)', "$filepath/$filename")  or die "Could not open file '$filepath/$filename' $!";

		my $name = "UNKNOWN";
        my $source = "NOT-FOUND";
		my @desc;
		my $foundtitle = 0;
		
		while (my $row = <$fh>) {
            if ($row !~ /<TITLE>(.*)--\s+(\d).. Level (\w+) (.*)(\(.*\))<\/TITLE>/i and 
                $row =~ /<TITLE>(.*)\((.*)\)<\/TITLE>/i) {
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
            # big hammer, tired of fucking with it
            $row =~ s/\<h2>/<b>/gi;
            $row =~ s/\<\/h2>/<\/b>/gi;

            $row =~ s/\\xD7/x/gi;
            $row =~ s/\\xBC/1\/2/gi;
            $row =~ s/\\xBD/1\/2/gi;
            $row =~ s/\\x88/'/gi;
            $row =~ s/\\x9C/'/gi;
            $row =~ s/\\xFB/u/gi;
            $row =~ s/\\x88/'/gi;
            $row =~ s/\\x91/'/gi;
            $row =~ s/\\x92/'/gi;
            $row =~ s/\\x93/'/gi;
            $row =~ s/\\x94/'/gi;
            $row =~ s/\\x95//gi;
            $row =~ s/\\x96//gi;
            $row =~ s/\\x97//gi;
            $row =~ s/\\xD7/x/gi;
            $row =~ s/\\x..//gi;

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
} # end process files        


# $mytree{$class}{$name}->{'description'}=$description;
sub as_xml {
my $simple = XML::Simple->new( );             # initialize the object
my $output = IO::File->new("> $outputfile.xml");
		
#my $wr = new XML::Writer( DATA_MODE => 'true', DATA_INDENT => 2 );
my $wr = new XML::Writer( OUTPUT => $output, DATA_MODE => 'true', DATA_INDENT => 2, UNSAFE => 'true' );

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

   ## replace only the ones after a period.
#   $desc_1 =~ s/\.(\/\/n)/\.<\/p\>\<p\>/g; # new line

   $desc_1 =~ tr{\n}{ }; #eol
   $desc_1 =~ tr{\r}{ }; #return
   $desc_1 =~ s/^<p><\/p> <\/b>//ig;
#   $desc_1 =~ s/(<BR><\/FONT><\/TD><\/TR><\/TABLE>)//ig; # end of stuff from cast/save/range/etc table
   $desc_1 =~ s/(<FONT([^>]+)?>)//ig; ## chuck all <FONT
   $desc_1 =~ s/(<\/FONT>)//ig; ## chuck all </FONT
   $desc_1 =~ s/(<A([^>]+)?>([^<]+)?<\/A>)   //ig; ## chuck all <a something=osdjfgn>some wasted text</a>

   $desc_1 =~ s/\<small\>//ig; # remove <small/small>
   $desc_1 =~ s/\<\/small\>//ig; # 
   $desc_1 =~ s/\<th\>/<td>/ig; # swap th for td
   $desc_1 =~ s/\<\/th\>/<\/td>/ig; # 
   $desc_1 =~ s/\<br([^<]+)?\>//ig; #<br>
   $desc_1 =~ s/\<b ([^<]+)?\>/<b>/ig; #<b *>
	#<table class="ip">
#   $desc_1 =~ s/\<table class\=\"ip\"\>/<table>/g; #<br>
   $desc_1 =~ s/\<table[ ^>]+>/<table>/ig; #<br>
	#<tr class="bk">
#   $desc_1 =~ s/\<tr class\=\"bk\"\>/<tr>/g; #<br>
   $desc_1 =~ s/\<tr [^>]+>/<tr>/ig; #<br>
	#<tr class="cn">
#   $desc_1 =~ s/\<tr class\=\"cn\"\>/<tr>/g; #<br>
   $desc_1 =~ s/\<tr [^>]+>/<tr>/ig; #<br>
   $desc_1 =~ s/\<td [^>]+>/<td>/ig; #<br>
   #<ol></ol>
   $desc_1 =~ s/\<ol\>//ig; #<br>
   $desc_1 =~ s/\<\/ol\>//ig; #<br>
   $desc_1 =~ s/\<ul\>//ig; #<br>
   $desc_1 =~ s/\<ul[^>]+?\>//ig; #<ul>
   $desc_1 =~ s/\<\/ul\>//ig; #<br>
	$desc_1 =~ s/\<p [^>]+?\>/<p>/ig;
	$desc_1 =~ s/\<i [^>]+?\>/<i>/ig;
	$desc_1 =~ s/\<q>/<i>/ig;
	$desc_1 =~ s/\<\/q>/<\/i>/ig;
	$desc_1 =~ s/\<a[^>]+?\>//ig;
	$desc_1 =~ s/\<\/a\>//ig;
	$desc_1 =~ s/\<\/a //ig;
	$desc_1 =~ s/\<img[^>]+?\>//ig;
	#<map name="map"> 
	$desc_1 =~ s/\<map[^>]+?\>//ig;
	#<area 
	$desc_1 =~ s/\<area[^>]+?\>//ig;
	$desc_1 =~ s/\<href[^>]+?\>//ig;
	$desc_1 =~ s/\<span[^>]+?\>//ig;
	$desc_1 =~ s/\<\/span\>//ig;
	#<table cellspacing="0" cellpadding="0"> 
	$desc_1 =~ s/\<table [^>]+?\>/<table>/ig;
	$desc_1 =~ s/\<th [^>]+?\>/<td>/ig;
	$desc_1 =~ s/\<tr [^>]+?\>/<tr>/ig;
	$desc_1 =~ s/\<\(/</ig;
	# big hammer, tired of fucking with it
	$desc_1 =~ s/\<h2>/<b>/ig;

	$desc_1 =~ s/<\/html>//ig; # FG seems case sensitive on these
	$desc_1 =~ s/<\/body>//ig; # FG seems case sensitive on these

	$desc_1 =~ s/<TR>/<tr>/gi; # FG seems case sensitive on these
	$desc_1 =~ s/<\/TR>/<\/tr>/gi; # FG seems case sensitive on these
	$desc_1 =~ s/<TD>/<td>/gi; # FG seems case sensitive on these
	$desc_1 =~ s/<\/TD>/<\/td>/gi; # FG seems case sensitive on these
	$desc_1 =~ s/<TABLE>/<table>/gi; # FG seems case sensitive on these
	$desc_1 =~ s/<\/TABLE>/<\/table>/gi; # FG seems case sensitive on these
	$desc_1 =~ s/<P>/<p>/gi; # FG seems case sensitive on these
	$desc_1 =~ s/<\/P>/<\/p>/gi; # FG seems case sensitive on these
	$desc_1 =~ s/<B>/<b>/gi; # FG seems case sensitive on these
	$desc_1 =~ s/<\/B>/<\/b>/gi; # FG seems case sensitive on these
	$desc_1 =~ s/<I>/<i>/gi; # FG seems case sensitive on these
	$desc_1 =~ s/<\/I>/<\/i>/gi; # FG seems case sensitive on these
    $desc_1 =~ s/table of contents//gi;
    #$desc_1 =~ s/((\s+)?<p>(\s+)?<\/p>(\s+)?)+?$//gi
    
   #make sure to do this before the 
   $desc_1 = find_OutOfPlaceMarkup($desc_1);
   ## before this, so that we clean up the markup
   ## and get all the extra/bogus <p>s off the end.
   $desc_1 =~ s/((\s+)?<p>(\s+)?<\/p>(\s+)?)+?$//gi;
   ##
   
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

