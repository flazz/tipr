<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        queryBinding='xslt' schemaVersion='ISO19757-3'>
  
  <title>A TIPR Envelope (tipr.xml) schematron</title>

  <!-- tipr.xml should always follow the METS schema. Additional requirements 
       are outlined by this schematron 
    -->

  <ns prefix="mets" uri="http://www.loc.gov/METS/" />
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink" />

  <xsl:key name="file_ids" match="//mets:fptr" use="@FILEID"/>

  <pattern>
  
    <title>METS Elements Required by TIPR</title>
  
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
        This tipr.xml has a dmdSec (not required)
      </report>
      <assert test="count(mets:fileSec)=1">
        There should be one fileSec
      </assert>
      <assert test="count(mets:structMap)=1">
        There should be one structMap
      </assert>
    </rule>
  </pattern>

  <pattern>
    
    <title>METS Header Content and Attributes</title>

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

      <!-- For now, we'll restrict the TIPR version. 
           [FIXME: In the future, we should address versioning differences] 
        -->
      <assert test="mets:note[text()='tipr-1.0.0']">
        The tipr version should be 1.0.0
      </assert>
    </rule>

  </pattern>
  
  <pattern>

    <title>The amdSec Content</title>

    <rule context="mets:mets/mets:amdSec">
      <assert test="count(mets:rightsMD)=1">
        There should be one rightsMD section
      </assert>
      <assert test="count(mets:digiprovMD)=1">
        There should be one digiprovMD section
      </assert>
      <assert test="count(child::*)=2">
        There should only be one rightsMD and one digiprovMD in the amdSec
      </assert>
    </rule>
    
    <rule context="mets:mets/mets:amdSec/mets:rightsMD">
      <assert test="mets:mdRef">
        The rights section should have an mdRef
      </assert>
      <assert test="mets:mdRef[@LOCTYPE='URL']">
        The rights location should be a URL
      </assert>
      <assert test="mets:mdRef[@MDTYPE='PREMIS']">
        The rights type should be PREMIS
      </assert>
      <assert test="mets:mdRef[@xlink:href='tipr-rights.xml']">
        The rights URL should point to tipr-rights.xml
      </assert>
    </rule>

    <rule context="mets:mets/mets:amdSec/mets:digiprovMD">
      <assert test="mets:mdRef">
        The digiprov section should have an mdRef
      </assert>
      <assert test="mets:mdRef[@LOCTYPE='URL']">
        The digiprov location should be a URL
      </assert>
      <assert test="mets:mdRef[@MDTYPE='PREMIS']">
        The digiprov type should be PREMIS
      </assert>
      <assert test="mets:mdRef[@xlink:href='tipr-digiprov.xml']">
        The digiprov URL should point to tipr-digiprov.xml
      </assert>
    </rule>

  </pattern>
  
  <pattern>

    <title>The fileSec Content</title>

    <rule context="mets:mets/mets:fileSec">
      <assert test="count(mets:fileGrp)=2">
        There should be two file groups
      </assert>
      <assert test="count(mets:fileGrp[@USE='METADATA'])=1">
        There should be one metadata file group
      </assert>
      <assert test="mets:fileGrp/mets:file/mets:FLocat[@xlink:href='tipr-rep-1.xml']">
        There should be an original representation in the fileSec
      </assert>
    </rule>

    <rule context="mets:mets/mets:fileSec/mets:fileGrp[not(@USE='METADATA')]">
      <assert test="mets:file/mets:FLocat[starts-with(@xlink:href, 'tipr-rep-')]">
        Representation files should have 'tipr-rep-' prefix
      </assert>
      <assert test="key('file_ids', mets:file/@ID)">
        Files in the fileSec should be referenced in the structMap
      </assert>
    </rule>
    
    <rule context="mets:mets/mets:fileSec/mets:fileGrp[@USE='METADATA']">
      <assert test="count(mets:file)=2">
        There should only be two files described in the metadata file group
      </assert>
      <assert test="mets:file/mets:FLocat[@xlink:href='tipr-rights.xml']">
        The TIPR rights file should be described in the metadata file group
      </assert>
      <assert test="mets:file/mets:FLocat[@xlink:href='tipr-digiprov.xml']">
        The TIPR digiprov file should be described in the metadata file group
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
        A representation should be referenced by a URL
      </assert>
    </rule>

  </pattern>
  
  <pattern>

  <title>The structMap Content</title>

    <rule context="mets:mets/mets:structMap/mets:div">
      <assert test="count(mets:div)>=1">
        The struct map should have at least one inner div
      </assert>
      <assert test="count(mets:div[@TYPE='ACTIVE'])=1">
        There should be one active representation (TYPE='ACTIVE')
      </assert>
      <assert test="count(mets:div[not(@ORDER=preceding-sibling::*/@ORDER)])=count(mets:div/@ORDER)">
        No representations should share the same order
      </assert>
    </rule>
    
    <rule context="mets:mets/mets:structMap/mets:div//mets:fptr">
      <assert test="./@FILEID = //mets:file/@ID">
        Files referenced in the structMap should exist in the fileSec
      </assert>
    </rule>
    
  </pattern>
  
  
</schema>
