<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        queryBinding='xslt' schemaVersion='ISO19757-3'>
  
  <title>A TIPR Representation (tipr-rep-x.xml) schematron</title>

  <!-- tipr-rep-x.xml should always follow the METS schema. 
       Additional requirements are outlined by this schematron.
    -->

  <ns prefix="mets" uri="http://www.loc.gov/METS/" />
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink" />

  <xsl:key name="file_ids" match="//mets:fptr" use="@FILEID"/>

  <pattern name="METS Elements Required by TIPR">
    <rule context = "mets:mets">
      <assert test="@OBJID">
        There should be an OBJID (the TIPR creator's package identifier)
      </assert>
      <assert test="count(mets:metsHdr)=1">
        There should be one METS Header
      </assert>
      <assert test="count(mets:amdSec)=1">
        There should be one amdSec
      </assert>
      <report test="mets:dmdSec">
        This representation has a dmdSec (not required)
      </report>
      <assert test="count(mets:fileSec)=1">
        There should be one fileSec
      </assert>
      <assert test="count(mets:structMap)=1">
        There should be one structMap
      </assert>
    </rule>
  </pattern>

  <pattern name="metsHdr Content and Attributes">

    <rule context="mets:mets/mets:metsHdr">
      <assert test="@CREATEDATE">
        The METS Header should have a CREATEDATE
      </assert>
      <assert test="count(mets:agent)=1">
        The METS Header should have one agent
      </assert>
    </rule>

    <rule context="mets:mets/mets:metsHdr/mets:agent">
      <assert test="@ROLE='DISSEMINATOR'">
        The agent role should be DISSEMINATOR
      </assert>
      <assert test="@TYPE='ORGANIZATION'">
        The agent type should be ORGANIZATION
      </assert>
      <assert test="mets:name[text() != '']">
        The agent should have a name
      </assert> 

      <!-- For now, we restrict the TIPR version. -->
      <assert test="mets:note[text()='tipr-1.0.0']">
        The tipr version should be 1.0.0
      </assert>
    </rule>

  </pattern>
  
  <pattern name="The digiprovMD Content">

    <rule context="mets:mets/mets:amdSec">
      <assert test="count(mets:digiprovMD)=1">
        There should be one digiprovMD section
      </assert>
    </rule>
    
    <rule context="mets:mets/mets:amdSec/mets:digiprovMD">
      <assert test="mets:mdRef">
        The digital provenance section should have an mdRef
      </assert>
      <assert test="mets:mdRef[@LOCTYPE='URL']">
        The digital provenance should reference a URL
      </assert>
      <assert test="mets:mdRef[@MDTYPE='PREMIS']">
        The provenance type should be PREMIS
      </assert>
      <assert test="mets:mdRef[starts-with(@xlink:href, 'tipr-rep-')]">
        The provenance URL should point to tipr-rep-x-digiprov.xml
      </assert>
      <assert test="mets:mdRef[contains(@xlink:href, '-digiprov.xml')]">
        The provenance URL should point to tipr-rep-x-digiprov.xml
      </assert>
    </rule>

  </pattern>
  
  <pattern name="The fileSec Content">

    <rule context="mets:mets/mets:fileSec">
      <assert test="count(mets:fileGrp)=2">
        There should be two file groups
      </assert>
      <assert test="count(mets:fileGrp[@USE='METADATA'])=1">
        There should be one metadata file group
      </assert>
      <assert test="count(mets:fileGrp[@USE='METADATA']/mets:file)=1">
        There should be exactly one file in the metadata file group
      </assert>
    </rule>

    <rule context="mets:mets/mets:fileSec/mets:fileGrp[not(@USE='METADATA')]">
      <assert test="key('file_ids', mets:file/@ID)">
        Files in the fileSec should be referenced in the structMap
      </assert>
      <assert test="mets:file/mets:FLocat[starts-with(@xlink:href, 'files/')]">
        All files in this representation should be in the files directory
      </assert>
    </rule>
    
    <rule context="mets:mets/mets:fileSec/mets:fileGrp[@USE='METADATA']">
      <assert test="count(mets:file/mets:FLocat[starts-with(@xlink:href, 'tipr-rep-')])=1">
        The representation digiprov file should be referenced in the metadata file group
      </assert>
      <assert test="count(mets:file/mets:FLocat[contains(@xlink:href, '-digiprov.xml')])=1">
        The representation digiprov file should be referenced in the metadata file group
      </assert>   
    </rule>
    
    <rule context="mets:mets/mets:fileSec/mets:fileGrp/mets:file">
      <assert test="@ID">All files in the fileSec should have an ID</assert>
      <assert test="@CHECKSUM and @CHECKSUMTYPE='SHA-1'">
        All files in the fileSec should have sha-1 checksums
      </assert>
      <assert test="string-length(@CHECKSUM) = 40">
        The SHA-1 checksum must be 40 characters.
      </assert>
      <assert test="string-length(translate(@CHECKSUM, '0987654321abcdefABCDEF', '')) = 0">
        The SHA-1 checksum may only contain characters 0-9, A-Z, a-z
      </assert>
      <assert test="count(mets:FLocat)=1">
        All files in the fileSec should point to one external location
      </assert>
      <assert test="mets:FLocat[@LOCTYPE='URL']">
        A file should be referenced by a URL
      </assert>
    </rule>

  </pattern>
  
  <pattern name="The structMap Content">

    <rule context="mets:mets/mets:structMap">
      <assert test="count(mets:div)>=1">
        The struct map should have at least one div
      </assert>
    </rule>
    
    <rule context="mets:mets/mets:structMap/mets:div//mets:fptr">
      <assert test="./@FILEID = //mets:file/@ID">
        Files referenced in the structMap should exist in the fileSec
      </assert>      
    </rule>
    
  </pattern>
  
  
</schema>
