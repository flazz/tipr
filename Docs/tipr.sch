<schema xmlns="http://purl.oclc.org/dsdl/schematron"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        queryBinding='xslt' schemaVersion='ISO19757-3'>
  
  <title>A TIPR Envelope (tipr.xml) schematron</title>

  <!-- tipr.xml should always follow the METS schema. Additional requirements are outlined by this schematron -->

  <ns prefix="mets" uri="http://www.loc.gov/METS/" />
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink" />

  <xsl:key name="file_ids" match="//mets:fptr" use="@FILEID"/> 

  <pattern name="METS Elements Required by TIPR">
    <rule context = "mets:mets">
      <assert test="@OBJID">There should be an OBJID (the TIPR creator's package identifier)</assert>
      <assert test="@LABEL">There should be a LABEL (the affiliate's package identifier)</assert>
      <assert test="mets:metsHdr">There should be a METS Header</assert>
      <assert test="mets:amdSec">There should be an amdSec</assert>
      <report test="mets:dmdSec">This tipr.xml has a dmdSec (not required)</report>
      <assert test="mets:fileSec">There should be a fileSec</assert>
    </rule>
  </pattern>

  <pattern name="metsHdr Content and Attributes">

    <rule context="mets:mets/mets:metsHdr">
      <assert test="@CREATEDATE">The METS Header should have a CREATEDATE</assert>
      <assert test="mets:agent">The METS Header should have an agent</assert>
    </rule>

    <rule context="mets:mets/mets:metsHdr/mets:agent">
      <assert test="@ROLE='DISSEMINATOR'">The agent role should be DISSEMINATOR</assert>
      <assert test="@TYPE='ORGANIZATION'">The agent type should be ORGANIZATION</assert>
      <assert test="mets:name">The agent should have a name</assert>

      <!-- For now, we'll restrict the TIPR version. 
           [FIXME: In the future, this schematron should address versioning differences] 
        -->
      <assert test="mets:note[text()='tipr-1.0.0']">The tipr version should be 1.0.0</assert>
    </rule>

  </pattern>
  
  <pattern name="The rightsMD Content">

    <rule context="mets:mets/mets:amdSec">
      <assert test="mets:rightsMD">There should be a rightsMD section</assert>
    </rule>
    
    <rule context="mets:mets/mets:amdSec/mets:rightsMD">
      <assert test="mets:mdRef">The rights section should have an mdRef</assert>
      <assert test="mets:mdRef[@LOCTYPE='URL']">The rights location should be a URL</assert>
      <assert test="mets:mdRef[@MDTYPE='PREMIS']">The rights type should be PREMIS</assert>
      <assert test="mets:mdRef[@xlink:href='tipr-rights.xml']">The rights URL should point to tipr-rights.xml</assert>
    </rule>

  </pattern>
  
  <pattern name="The fileSec Content">

    <rule context="mets:mets/mets:fileSec">
      <assert test="count(mets:fileGrp)=1">There should only be one file group</assert>
      <assert test="mets:fileGrp/mets:file">There should be at least one representation file listed in the fileSec</assert>
    </rule>
    
    <rule context="mets:mets/mets:fileSec/mets:fileGrp/mets:file">
      <assert test="@ID">All files in the fileSec should have an ID</assert>
      <assert test="@CHECKSUM and @CHECKSUMTYPE='SHA-1'">All files in the fileSec should have sha-1 checksums</assert>
      <assert test="mets:FLocat">All files in the fileSec should point to an external location</assert>
      <assert test="mets:FLocat[@LOCTYPE='URL']">A representation should be referenced by a URL</assert>
      <assert test="mets:FLocat[starts-with(@xlink:href, 'tipr')]">Representation files should have 'tipr' prefix</assert>
      <assert test="key('file_ids', @ID)">Files should be referenced in the structMap</assert>
    </rule>

  </pattern>
  
  <pattern name="The structMap Content">
    
    <rule context="mets:mets/mets:structMap">  <!-- required per METS -->
      <assert test="mets:div/mets:div">The struct map should have at least one inner div</assert>
    </rule>
    
    <rule context="mets:mets/mets:structMap/mets:div">
      <assert test="count(mets:div[@ORDER='1'])=1">There should be one original representation (ORDER='1')</assert>
      <assert test="count(mets:div[@TYPE='ACTIVE'])=1">There should be one active representation (TYPE='ACTIVE')</assert>
      <assert test="count(mets:div[not(@ORDER=preceding-sibling::*/@ORDER)])=count(mets:div/@ORDER)">
        No representations should share the same order
      </assert>
    </rule>
    
  </pattern>
  
  
</schema>
