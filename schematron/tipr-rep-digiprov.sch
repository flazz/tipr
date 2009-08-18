<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        queryBinding='xslt' schemaVersion='ISO19757-3'>
  
  <title>RXP Representation Provenance (rxp-rep-x-digiprov.xml) schematron</title>

  <!-- rxp-rep-x-digiprov.xml should always follow the PREMIS 2.0 schema. 
       Additional requirements are outlined by this schematron.
    -->

  <ns prefix="premis" uri="info:lc/xmlns/premis-v2" />
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink" />
  <ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance" />

  <pattern>
  
    <title>PREMIS Elements Required by RXP</title>
  
    <rule context="premis:premis">
      <assert test="count(premis:object[@xsi:type='representation'])=1">
        There must one representation object
      </assert>
      <assert test="count(premis:object[@xsi:type='file' or 'bitstream'])>=1" >
        There must one at least one file or bitstream object
      </assert>
      <report test="count(premis:agent)=0">
        There should be at least one agent
      </report>
    </rule>

    <rule context="//premis:objectIdentifier">
      <assert test="premis:objectIdentifierType[normalize-space(text())='URI']">
        Object identifier type must be URI
      </assert>
      <assert test="self::*[normalize-space(premis:objectIdentifierValue) != '']">
        The object identifier value must not be empty
      </assert>
    </rule>
    
    <rule context="premis:event">
      <assert test="premis:linkingObjectIdentifier">
        There must be a linking object identifier for each event
      </assert>
      <assert test="child::*[normalize-space(premis:linkingObjectIdentifierValue)=normalize-space(//premis:object[@xsi:type='representation']//premis:objectIdentifierValue)]">
        Each event must link to the representation object
      </assert>
    </rule>

    <rule context="premis:event/premis:linkingObjectIdentifier">
      <assert test="premis:linkingObjectIdentifierType[normalize-space(text())='URI']">
        Linking object identifier type must be URI
      </assert>
      <assert test="self::*[normalize-space(premis:linkingObjectIdentifierValue) != '']">
        Linking object identifier value must not be empty
      </assert>    
    </rule>

    <rule context="premis:agent/premis:agentIdentifier">
      <assert test="premis:agentIdentifierType[normalize-space(text())='URI']">
        Agent identifier type must be URI.
      </assert>
    </rule>
        
  </pattern>
  
</schema>
