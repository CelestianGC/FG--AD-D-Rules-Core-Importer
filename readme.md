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

===== Ref-Manual ======

This method uses the books/refmanual feature in FG.



Exit Fantasy Grounds, close it.

After the import has run you will see a PHB.client.xml file. This file is the skeleton ref-manual file. To use this you need to create a new directory under "modules/". 

(In this example "PHB.client.xml" is what we use. However the same options work for DMG.client.xml or anything else. Just tweak the text in the definition.xml file ("2e Players Handbook Reference" and change it to "2e DMG" or whatever you like) and the name of the module directory.)

We'll assume you use modules/PHB, then you need to create a file called "definition.xml" within that directory. The contents should look something like this:

```
<?xml version="1.0" encoding="iso-8859-1"?>
<root version="3.3" release="8|CoreRPG:3">
	<name>AD&#38;D 2e Players Handbook Reference</name>
	<category>2e\</category>
	<author>version 1.2</author>
	<ruleset>AD&#38;D Core</ruleset>
</root>
```

Create "client.xml" and place the contents on PHB.client.xml in the location indicated below

```
<?xml version="1.0" encoding="iso-8859-1"?>
<root version="3.3" release="8|CoreRPG:3">
	<library>
		<adnd_refmanual_library>
			<categoryname type="string">2e</categoryname>
			<entries>
				<id-00001>
					<librarylink type="windowreference">
						<class>reference_manual</class>
						<recordname>reference.refmanualindex</recordname>
					</librarylink>
					<name type="string">PHB Stuff....</name>
				</id-00001>
			</entries>
			<name type="string">Name-Ref-Manual-PlaceHolder-Text</name>
		</adnd_refmanual_library>
	</library>
  
  ....................PASTE ALL CONTENTS OF XML FILE HERE.............................

</root>  
```

You can also find a image that looks like the cover of the book you are using and place it into this directory called "thumbnail.png".

Once you have done the above, start up Fantasy Grounds and in your Library/Modules look for "AD&D 2e Players Handbook Reference" and "load" it. Now you can see it in your library and can browse it. More than likely you will want to go in a rework some of the ordering/errors from the import. You'll need to either do that on the ref-manual file (client.xml) or fix the html files and re-run the import and replace the client.xml file with the new one. I noticed particularly that the Paladin's Handbook didn't have chapters labeled properly and fixing it in the .html file was better method to correct. Other than that more trouble shooting on this is outside the scope of this document.

===== Story Entries ======

This method places the content imported into "Story" entries. (If you have a choice, ref-manuals tend to be better).

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

HTML files will also sometimes produce the *_items.xml to be created. These are magic items it found.

HTML files will also sometimes produce  the *_skills.xml to be created. These are skills the script found.

Both the *_items.xml and _skills.xml files are similar to the others. To add them copy/paste the contents into the campaign file "db.xml" within <skills> or <item> xml blocks.

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

* Start the campaign again and look in your "Spells" selection.
* I export that into a module (/export and select Spells) and then use the module in other campaigns. Keep this one for just updating the Spells module.  
