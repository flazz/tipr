<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        queryBinding='xslt' schemaVersion='ISO19757-3'>
  
  <title>Repository eXchange Package Envelope (rxp.xml) schematron</title>

  <!-- rxp.xml must always follow the METS schema. Additional requirements 
       are outlined by this schematron 
    -->

  <ns prefix="mets" uri="http://www.loc.gov/METS/" />
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink" />

  <xsl:key name="file_ids" match="//mets:fptr" use="@FILEID"/>

  <pattern>
  
    <title>METS Elements Required by the RXP</title>
  
    <rule context = "mets:mets">
      <assert test="@OBJID">
        There must be an OBJID (the RXP creator's package identifier)
      </assert>
      <assert test="count(mets:metsHdr)=1">
        There must be one METS Header
      </assert>
      <assert test="count(mets:amdSec)=1">
        There must be one amdSec
      </assert>
      <assert test="count(mets:dmdSec)=0">
        There must not be a dmdSec
      </assert>
      <assert test="count(mets:fileSec)=1">
        There must be one fileSec
      </assert>
      <assert test="count(mets:structMap)=1">
        There must be one structMap
      </assert>
    </rule>
  </pattern>

  <pattern>
    
    <title>METS Header Content and Attributes</title>

    <rule context="mets:mets/mets:metsHdr">
      <report test="not(@CREATEDATE)">
        The METS Header should have a CREATEDATE
      </report>
      <assert test="count(mets:agent)=1">
        The METS Header must have one agent
      </assert>
    </rule>

    <rule context="mets:mets/mets:metsHdr/mets:agent">
      <assert test="@ROLE='DISSEMINATOR'">
        The agent role must be DISSEMINATOR
      </assert>
      <assert test="@TYPE='ORGANIZATION'">
        The agent type must be ORGANIZATION
      </assert>
      <assert test="mets:name[normalize-space(text()) != '']">
        The agent must have a name
      </assert> 
      <assert test="mets:note[text()='rxp-1.0.0']">
        The rxp version must be 1.0.0
      </assert>
    </rule>

  </pattern>
  
  <pattern>

    <title>The amdSec Content</title>

    <rule context="mets:mets/mets:amdSec">
      <report test="count(mets:rightsMD)!=1">
        There should be one rightsMD section
      </report>
      <assert test="count(mets:digiprovMD)=1">
        There must be one digiprovMD section
      </assert>
      <assert test="count(child::*)=1 or count(child::*)=2">
        There must only be one digiprovMD and at most one rightsMD in the amdSec
      </assert>
    </rule>
    
    <rule context="mets:mets/mets:amdSec/mets:rightsMD">
      <assert test="mets:mdRef">
        The rights section must have an mdRef
      </assert>
      <assert test="mets:mdRef[@LOCTYPE='URL']">
        The rights location must be a URL
      </assert>
      <assert test="mets:mdRef[@MDTYPE='PREMIS']">
        The rights type must be PREMIS
      </assert>
      <assert test="mets:mdRef[@xlink:href='rxp-rights.xml']">
        The rights URL must point to rxp-rights.xml
      </assert>
    </rule>

    <rule context="mets:mets/mets:amdSec/mets:digiprovMD">
      <assert test="mets:mdRef">
        The digiprov section must have an mdRef
      </assert>
      <assert test="mets:mdRef[@LOCTYPE='URL']">
        The digiprov location must be a URL
      </assert>
      <assert test="mets:mdRef[@MDTYPE='PREMIS']">
        The digiprov type must be PREMIS
      </assert>
      <assert test="mets:mdRef[@xlink:href='rxp-digiprov.xml']">
        The digiprov URL must point to rxp-digiprov.xml
      </assert>
    </rule>

  </pattern>
  
  <pattern>

    <title>The fileSec Content</title>

    <rule context="mets:mets/mets:fileSec">
      <assert test="count(mets:fileGrp)=2">
        There must be two file groups
      </assert>
      <assert test="count(mets:fileGrp[@USE='METADATA'])=1">
        There must be one metadata file group
      </assert>
      <assert test="mets:fileGrp/mets:file/mets:FLocat[@xlink:href='rxp-rep-1.xml']">
        There must be an original representation in the fileSec
      </assert>
    </rule>

    <rule context="mets:mets/mets:fileSec/mets:fileGrp[not(@USE='METADATA')]">
      <assert test="mets:file/mets:FLocat[starts-with(@xlink:href, 'rxp-rep-')]">
        Representation files must have 'rxp-rep-' prefix
      </assert>
      <assert test="key('file_ids', mets:file/@ID)">
        Files in the fileSec must be referenced in the structMap
      </assert>
    </rule>
    
    <rule context="mets:mets/mets:fileSec/mets:fileGrp[@USE='METADATA']">
      <assert test="count(mets:file)=1 or count(mets:file)=2">
        There must only be at most two files described in the metadata file group
      </assert>
      <assert test="count(mets:file/mets:FLocat[@xlink:href='rxp-rights.xml']) = 
                    count(parent::node()/parent::node()/mets:amdSec/mets:rightsMD)">
        The RXP rights file should be in a rightsMD section and described in the
        metadata file group
      </assert>
      <assert test="mets:file/mets:FLocat[@xlink:href='rxp-digiprov.xml']">
        The RXP digiprov file must be described in the metadata file group
      </assert>
    </rule>
    
    <rule context="mets:mets/mets:fileSec/mets:fileGrp/mets:file">
      <assert test="@ID">All files in the fileSec must have an ID</assert>
      <assert test="@CHECKSUM and @CHECKSUMTYPE='SHA-1'">
        All files in the fileSec must have sha-1 checksums
      </assert>
      <assert test="string-length(@CHECKSUM) = 40">
        The SHA-1 checksum must be 40 characters.
      </assert>
      <assert test="string-length(translate(@CHECKSUM, '0987654321abcdefABCDEF', '')) = 0">
        The SHA-1 checksum may only contain characters 0-9, A-Z, a-z
      </assert>
      <assert test="count(mets:FLocat)=1">
        All files in the fileSec must point to one external location
      </assert>
      <assert test="mets:FLocat[@LOCTYPE='URL']">
        A representation must be referenced by a URL
      </assert>
    </rule>

  </pattern>
  
  <pattern>

  <title>The structMap Content</title>

    <rule context="mets:mets/mets:structMap/mets:div">
      <assert test="count(mets:div)>=1">
        The struct map must have at least one inner div
      </assert>
      <assert test="count(mets:div[@TYPE='ACTIVE'])=1">
        There must be one active representation (TYPE='ACTIVE')
      </assert>
      <assert test="count(mets:div[not(@ORDER=preceding-sibling::*/@ORDER)])=count(mets:div/@ORDER)">
        No representations may share the same order
      </assert>
    </rule>
    
    <rule context="mets:mets/mets:structMap/mets:div//mets:fptr">
      <assert test="./@FILEID = //mets:file/@ID">
        Files referenced in the structMap must exist in the fileSec
      </assert>
    </rule>
    
  </pattern>
  
  
</schema>
