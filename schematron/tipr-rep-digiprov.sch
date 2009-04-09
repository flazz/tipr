<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        queryBinding='xslt' schemaVersion='ISO19757-3'>
  
  <title>TIPR Representation Provenance (tipr-rep-x-digiprov.xml) schematron</title>

  <!-- tipr-rep-x-digiprov.xml should always follow the PREMIS 2.0 schema. 
       Additional requirements are outlined by this schematron.
    -->

  <ns prefix="premis" uri="info:lc/xmlns/premis-v2" />
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink" />
  <ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance" />

  <pattern name="PREMIS Elements Required by TIPR">
    <rule context="premis:premis">
      <assert test="count(premis:object[@xsi:type='representation'])=1">
        There should one representation object
      </assert>
      <assert test="count(premis:object[@xsi:type='file' or 'bitstream'])>=1" >
        There should one at least one file or bitstream object
      </assert>
    </rule>

    <rule context="//premis:objectIdentifier">
      <assert test="premis:objectIdentifierType[normalize-space(text())='URI']">
        Object identifier type should be URI
      </assert>
      <assert test="self::*[normalize-space(premis:objectIdentifierValue) != '']">
        The object identifier value should not be empty
      </assert>
    </rule>
    
    <rule context="premis:event">
      <assert test="premis:linkingObjectIdentifier">
        There should be a linking object identifier for each event
      </assert>
      <assert test="child::*[normalize-space(premis:linkingObjectIdentifierValue)=normalize-space(//premis:object[@xsi:type='representation']//premis:objectIdentifierValue)]">
        Each event should link to the representation object
      </assert>
    </rule>

    <rule context="premis:event/premis:linkingObjectIdentifier">
      <assert test="premis:linkingObjectIdentifierType[normalize-space(text())='URI']">
        Linking object identifier type should be URI
      </assert>
      <assert test="self::*[normalize-space(premis:linkingObjectIdentifierValue) != '']">
        Linking object identifier value should not be empty
      </assert>    
    </rule>
  
  <!-- FIXME: Need to add rule for agents -->
        
  </pattern>
  
</schema>
