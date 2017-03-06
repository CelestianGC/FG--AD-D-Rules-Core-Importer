=== Corebook Importer ===

This perl script can be used to import the AD&D Core Rules *.htm/html files (BOOKS) into Fantasy Grounds.

./corebook-html.pl path/to/html/files path/to/xml/file/for/fantasygrounds

Example
./corebook-html.pl core/PHB phb.xml

This would take the PHB entries and convert them to a XML file that you can then copy/paste into a campaign db.xml file. 

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
 
More documentation to follow.

=== TODO ===

* Make an index? Use Library/sections?
* Port my spells and monster script into this script as an all-in-one tool.