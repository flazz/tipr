<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        queryBinding='xslt' schemaVersion='ISO19757-3'>
  
  <title>TIPR Rights (tipr-rights.xml) schematron</title>

  <!-- tipr-rights.xml should always follow the PREMIS 2.0 schema. 
       Additional requirements are outlined by this schematron.
    -->

  <ns prefix="premis" uri="info:lc/xmlns/premis-v2" />
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink" />
  <ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance" />

  <pattern>
  
    <title>PREMIS Elements Required for TIPR Rights</title>
  
    <rule context="premis:premis">
      <assert test="count(premis:object[@xsi:type='representation'])=1">
        There should one representation object to describe the TIPR package
      </assert>
      <assert test="count(premis:agent)>=2">
        There should be at least two agents for license information linking
      </assert>
      <assert test="count(premis:rights)>=1">
        There should be at least one rights entity
      </assert>
    </rule>

    <rule context="premis:object">
      <assert test="@xsi:type='representation'">
        All objects should be representations
      </assert>
      <assert test="premis:objectIdentifier/premis:objectIdentifierType[normalize-space(text())='URI']">
        Object identifier type should be URI
      </assert>
      <assert test="premis:objectIdentifier/[normalize-space(premis:objectIdentifierValue) != '']">
        The object identifier value should not be empty
      </assert>
    </rule>


    <rule context="premis:agent">
      <assert test="premis:agentIdentifier/premis:agentIdentifierType[normalize-space(text())='URI']">
        Agent identifier type should be URI.
      </assert>   
    </rule>

    
    <rule context="premis:rights">
      <assert test="premis:rightsStatement">
        There should be a rights statement
      </assert>
      <assert test="contains(premis:rightsStatement/premis:rightsBasis/text(), 'license')">
        The rights basis should be a license agreement
      </assert>
      <assert test="premis:rightsStatement/premis:licenseInformation/premis:licenseIdentifier">
        There should be license information with a license identifier
      </assert>
      <assert test="premis:rightsStatement//premis:licenseIdentifierType[normalize-space(text())='URI']">
        The license identifier type should be URI
      </assert>
      <assert test="count(premis:linkingAgentIdentifier)>=2">
        There should be at least two agents linked to this rights section
      </assert>
      <assert test="premis:linkingAgentIdentifier/premis:linkingAgentIdentifierType[normalize-space(text())='URI']">
        All linking agent identifier type should be URIs
      </assert>
      <assert test="child::*[normalize-space(premis:linkingAgentIdentifierValue)=normalize-space(//premis:agent//premis:agentIdentifierValue)]">
        Each rights section should link to existing agents
      </assert>
    </rule>
    
  </pattern>

</schema>