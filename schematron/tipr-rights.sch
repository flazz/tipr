<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        queryBinding='xslt' schemaVersion='ISO19757-3'>
  
  <title>RXP Rights (rxp-rights.xml) schematron</title>

  <!-- rxp-rights.xml should always follow the PREMIS 2.0 schema. 
       Additional requirements are outlined by this schematron.
    -->

  <ns prefix="premis" uri="info:lc/xmlns/premis-v2" />
  <ns prefix="xlink" uri="http://www.w3.org/1999/xlink" />
  <ns prefix="xsi" uri="http://www.w3.org/2001/XMLSchema-instance" />

  <pattern>
  
    <title>PREMIS Elements Required for RXP Rights</title>
  
    <rule context="premis:premis">
      <assert test="count(premis:object[@xsi:type='representation'])=1">
        There must one representation object to describe the RXP
      </assert>
      <assert test="count(premis:rights)>=1">
        There must be at least one rights entity
      </assert>
    </rule>

    <rule context="premis:object">
      <assert test="@xsi:type='representation'">
        All objects must be representations
      </assert>
      <assert test="premis:objectIdentifier/premis:objectIdentifierType[normalize-space(text())='URI']">
        Object identifier type must be URI
      </assert>
      <assert test="premis:objectIdentifier[normalize-space(premis:objectIdentifierValue) != '']">
        The object identifier value may not be empty
      </assert>
    </rule>

    
    <rule context="premis:rights">
      <assert test="premis:rightsStatement">
        There must be a rights statement
      </assert>
      <assert test="contains(premis:rightsStatement/premis:rightsBasis/text(), 'license')">
        The rights basis must be a license agreement
      </assert>
      <assert test="premis:rightsStatement/premis:licenseInformation/premis:licenseIdentifier">
        There must be license information with a license identifier
      </assert>
      <assert test="premis:rightsStatement//premis:licenseIdentifierType[normalize-space(text())='URI']">
        The license identifier type must be URI
      </assert>
      <assert test="premis:rightsStatement//premis:licenseNote">
        The license note must contain contact information for acquiring a copy
        of the license
      </assert>
    </rule>
    
  </pattern>

</schema>