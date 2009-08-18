<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        queryBinding='xslt' schemaVersion='ISO19757-3'>
  
  <title>RXP Digital Provenance (rxp-digiprov.xml) schematron</title>

  <!-- rxp-digiprov.xml should always follow the PREMIS 2.0 schema. 
       Additional requirements are outlined by this schematron.
    -->

  <ns prefix="premis" uri="info:lc/xmlns/premis-v2" />
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink" />
  <ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance" />

  <pattern>
  
    <title>PREMIS Elements Required for RXP Digital Provenance</title>
  
    <rule context="premis:premis">
      <assert test="count(premis:object[@xsi:type='representation'])>=1">
        There must be at least one representation object for the RXP package
      </assert>
      <assert test="count(premis:agent)>=1">
        There must be at least one agent which corresponds to the RXP creator
      </assert>
      <assert test="count(premis:event)>=1">
        There must be at least one event
      </assert>
    </rule>

    <!-- representations -->
    <rule context="premis:object">
      <assert test="@xsi:type='representation'">
        All objects must be representations
      </assert>
      <assert test="premis:objectIdentifier/premis:objectIdentifierType[normalize-space(text())='URI']">
        Object identifier type must be URI
      </assert>
      <assert test="premis:objectIdentifier[normalize-space(premis:objectIdentifierValue) != '']">
        The object identifier value must not be empty
      </assert>
    </rule>
    
    <!-- agents -->
    <rule context="premis:agent">
      <assert test="premis:agentIdentifier/premis:agentIdentifierType[normalize-space(text())='URI']">
        Agent identifier type must be URI.
      </assert>
    </rule>
    
    <!-- events -->
    <rule context="premis:event">
      <assert test="premis:eventIdentifier/premis:eventIdentifierType[normalize-space(text())='URI']">
        Event identifier type must be URI.
      </assert>    
      <assert test="premis:linkingObjectIdentifier">
        There must be a linking object identifier for each event
      </assert>
      <assert test="child::*[normalize-space(premis:linkingObjectIdentifierValue)=normalize-space(//premis:object[@xsi:type='representation']//premis:objectIdentifierValue)]">
        Each event must link to a representation object
      </assert>
      <assert test="child::*[normalize-space(premis:linkingAgentIdentifierValue)=normalize-space(//premis:agent//premis:agentIdentifierValue)]">
        Each event must link to an agent
      </assert>
    </rule>
    
  </pattern>

</schema>