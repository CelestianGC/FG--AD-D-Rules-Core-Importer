=== corebook-html.pl Importer ===

This perl script can be used to import the AD&D Core Rules *.htm/html files (BOOKS) into Fantasy Grounds. Since everthing is already in html it's not to difficult to fiddle with the data into something Fantasy Grounds and display. 

To use this script you'll need at least a basic understanding of perl and perl modules. This script requires the following modules to run. I just use CPAN to "CPAN install Module::Name".

* use Data::Dumper;
* use XML::Entities;
* use HTML::Entities;
* use XML::Simple;
* use XML::Writer;
* use IO::File;
* use String::Util qw(trim);
* use HTML::Tidy;

Once you have the modules installed, you can run it:

./corebook-html.pl path/to/html/files path/to/outfilename

==== Examples ====

./corebook-html.pl core/PHB phb

This would take the PHB entries and convert them to a XML file that you can then copy/paste into a campaign db.xml file. 

==== How to Import data ====

To import the xml file into FG...

* Create a new campaign. 
* Start the campaign. Once loaded type /save, then close FG.

* Open the created xml file created by corebook-html.pl (in the example above, phb.xml)
* Select ALL the text in the XML file and "copy"
* Close file

* Open up the db.xml file in the newly created campaign's directory
* Below the "\</calendar\>" paste the text from phb.xml
* Save the db.xml and close file.

* Start the campaign again and look in your "Story" selection.
* I export that into a module (/export and select Story) and then use the module in other campaigns. Keep this one for just updating the module.  

HTML files for the DMG will also cause the *_items.xml to be created. These are magic items it found.

HTML files for the PHB will also cause the *_skills.xml to be created. These are skills the script found.

More documentation to follow.

==== NOTES ====

This tool doesn't work with all of the files (some, for whatever reason have different formats. Like \<TITLE\>SectionOfBook (Player's Handbook)\</TITLE\> will look like \<TITLE\>SectionOfBook (Player's Handbook\</TITLE\>, notice the missing ) at the end of Handbook. There are also some incorrect entries in the html files for paragraphs, tables, fonts/etc. HTML::Tidy cleans most of that up but you might have issues on some files.  Just watch for "Discarding file" in the output of the script to see which ones it couldn't figure out.

Note that most of the "Discarding" messages you see when importing the PHB and TM will be the spells. I excluded those since my spell import script already has them in a spell format you can use. 

==== TODO ====

* Make an index? Use Library/sections?
* Port my spells and monster script into this script as an all-in-one tool.

------------------------------------------------------------------------------------------------------------------------------

=== corebook-spells.pl ===
 
* This will allow you to import your Corerules CD files into a "Spells" format that Fantasy Grounds can use. The best way to import ALL spells is to just copy all the html files into one directory and then point the import tool to that directory. I placed the copied all the files in PHB/* and TM/* into "all/" and then imported all those files into a single XML file.

==== Command/Examples ====
./corebook-spells.pl spells/all spells

==== How to Import Spell data into Fantasy Grounds ===

To import the xml file into FG...

* Create a new campaign. 
* Start the campaign. Once loaded type /save, then close FG.

* Open the created xml file created by corebook-spells.pl (in the example above, spells.xml)
* Select ALL the text in the XML file and "copy"
* Close file

* Open up the db.xml file in the newly created campaign's directory
* Below the "\</calendar\>" paste the text from spells.xml
* Save the db.xml and close file.

* Start the campaign again and look in your "Story" selection.
* I export that into a module (/export and select Story) and then use the module in other campaigns. Keep this one for just updating the Spells module.  
