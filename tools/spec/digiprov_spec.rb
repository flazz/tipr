require 'erb'
require 'nokogiri'
require 'dip'
require 'tipr'
require 'spec_helper'

describe "the file digiprov descriptor" do

  before(:each) do

    event_doc = Nokogiri::XML <<XML
<daitss xmlns="http://www.fcla.edu/dls/md/daitss/">
  <EVENT>
    <ID>488374</ID>
    <OID>F20090127_AAAAAA</OID>
    <EVENT_TYPE>CV</EVENT_TYPE>
    <DATE_TIME>2009-01-27 14:32:12</DATE_TIME>
    <EVENT_PROCEDURE>Checked for virus during DataFile creation</EVENT_PROCEDURE>
    <OUTCOME>SUCCESS</OUTCOME>
    <NOTE></NOTE>
  </EVENT>
  <EVENT>
    <ID>488375</ID>
    <OID>F20090127_AAAAAA</OID>
    <EVENT_TYPE>VC</EVENT_TYPE>
    <DATE_TIME>2009-01-27 14:32:14</DATE_TIME>
    <EVENT_PROCEDURE>compareMessageDigests</EVENT_PROCEDURE>
    <OUTCOME>SUCCESS</OUTCOME>
    <NOTE>Compared archive-calculated checksum to submitted checksum. Type: sha-1</NOTE>
  </EVENT>
  <EVENT>
    <ID>488376</ID>
    <OID>F20090127_AAAAAB</OID>
    <EVENT_TYPE>CV</EVENT_TYPE>
    <DATE_TIME>2009-01-27 14:32:19</DATE_TIME>
    <EVENT_PROCEDURE>Checked for virus during DataFile creation</EVENT_PROCEDURE>
    <OUTCOME>SUCCESS</OUTCOME>
    <NOTE></NOTE>
  </EVENT>
</daitss>
XML

    package_event_doc = Nokogiri::XML <<XML
<daitss xmlns="http://www.fcla.edu/dls/md/daitss/">
  <EVENT>
    <ID>488274</ID>
    <OID>E20090127_AAAAAA</OID>
    <EVENT_TYPE>SUB</EVENT_TYPE>
    <DATE_TIME>2009-01-27 14:30:12</DATE_TIME>
    <EVENT_PROCEDURE>Package submitted by FIU</EVENT_PROCEDURE>
    <OUTCOME>SUCCESS</OUTCOME>
    <NOTE></NOTE>
  </EVENT>
  <EVENT>
    <ID>488275</ID>
    <OID>E20090127_AAAAAA</OID>
    <EVENT_TYPE>I</EVENT_TYPE>
    <DATE_TIME>2009-01-27 14:31:14</DATE_TIME>
    <EVENT_PROCEDURE>Ingested package from FIU</EVENT_PROCEDURE>
    <OUTCOME>SUCCESS</OUTCOME>
    <NOTE></NOTE>
  </EVENT>
  <EVENT>
    <ID>488399</ID>
    <OID>E20090127_AAAAAA</OID>
    <EVENT_TYPE>D</EVENT_TYPE>
    <DATE_TIME>2009-01-27 18:32:19</DATE_TIME>
    <EVENT_PROCEDURE>Disseminated package to FDA</EVENT_PROCEDURE>
    <OUTCOME>SUCCESS</OUTCOME>
    <NOTE></NOTE>
  </EVENT>
</daitss>
XML


    events = event_doc.xpath('//daitss:EVENT', 'daitss' => "http://www.fcla.edu/dls/md/daitss/").to_a
    package_events = package_event_doc.xpath('//daitss:EVENT', 'daitss' => "http://www.fcla.edu/dls/md/daitss/").to_a
    @events = [ {:events => events, :object_format => "IMG_JPEG_JFIF"}, {:events=> package_events} ]
#    @premis_schema = "http://www.loc.gov/standards/premis/v1/PREMIS-v1-1.xsd"
#    @premis_schema = "http://www.loc.gov/standards/premis/premis.xsd"
    
    @agents = { 
    	        :submission => { :name=>"FIU", :project_code=>252, :type=>"organization" }, 
                :archive => { :name => "FDA", :project_code => 1, :type => "organization" }
              }
    
    raw_xml = TIPR.generate_digiprov(@events, 'E20090127_AAAAAA', 1, @agents)
    @doc = Nokogiri::XML raw_xml, nil, nil, Nokogiri::XML::PARSE_NOBLANKS
    
  end

  it "should be a valid premis document" do
    @doc.should have_xpath('premis:premis')
#    TIPR.validate(@doc.to_xml, LibXML::XML::Schema.new(@premis_schema)).should be_true
  end

  it "should have two objects, one with xsi:type representation, the other with xsi:type file" do
    @doc.xpath('premis:premis/premis:object', NS_MAP).size.should == 2
    @doc.should have_xpath("premis:premis/premis:object[@xsi:type = 'file']", NS_MAP)
    @doc.should have_xpath("premis:premis/premis:object[@xsi:type = 'representation']", NS_MAP)
  end
    
  describe "the objects" do

    before(:each) do
      @first_object = @doc.xpath('/premis:premis/premis:object', NS_MAP).first
      @second_object = @doc.xpath('/premis:premis/premis:object', NS_MAP).last

    end
  
    it "should have an objectIdentifier" do
      @first_object.should have_xpath('premis:objectIdentifier')
      @second_object.should have_xpath('premis:objectIdentifier')
    end
  
    it "should have an objectIdentifierType" do
      @first_object.should have_xpath_with_content('premis:objectIdentifier/premis:objectIdentifierType', "URI")
      @second_object.should have_xpath_with_content('premis:objectIdentifier/premis:objectIdentifierType', "URI")
    end
    
    it "should have an objectIdentifierValue" do
      @first_object.should have_xpath_with_content('premis:objectIdentifier/premis:objectIdentifierValue', 
                                                   "info:fcla/daitss/E20090127_AAAAAA/representation/1")
      @second_object.should have_xpath_with_content('premis:objectIdentifier/premis:objectIdentifierValue', 
                                                   "info:fcla/daitss/E20090127_AAAAAA/representation/1/F20090127_AAAAAA")
    end

  end


  it "should have two agents" do
    @doc.xpath('premis:premis/premis:agent', NS_MAP).length.should == 2
  end
  
  describe "the agent" do

    before(:each) do
      @agent = @doc.xpath('/premis:premis/premis:agent', NS_MAP).first
    end
    
    it "should have an agentIdentifierType" do
      @agent.should have_xpath_with_content('premis:agentIdentifier/premis:agentIdentifierType', 'URI')
    end
    
    it "should have an agentIdentifierValue" do
      @agent.should have_xpath_with_content('premis:agentIdentifier/premis:agentIdentifierValue', 
                                            "info:fcla/daitss/agent/")
    end
    
    it "should have an agentName" do
      @agent.should have_xpath('premis:agentName')
    end
    
    it "should have an agentType" do
      @agent.should have_xpath_with_content('premis:agentType', 'organization')
    end
  
  end


  
  it "should have six events" do
    @doc.xpath('/premis:premis/premis:event', NS_MAP).size.should == 6
  end

  describe "the event" do

    before(:each) do
      @event = @doc.xpath('/premis:premis/premis:event', NS_MAP).first
    end

    it "should have an eventIdentifier" do
      @event.should have_xpath('premis:eventIdentifier')
    end


    it "should have an eventIdentifierType" do
      @event.should have_xpath('premis:eventIdentifier/premis:eventIdentifierType')
    end

    it "should have an eventIdentifierValue which matches the daitss:event id" do
      @event.should have_xpath_with_content('premis:eventIdentifier/premis:eventIdentifierValue', 
                                            "info:fcla/daitss/E20090127_AAAAAA/event/488374")
    end

    it "should have an eventType" do
      @event.should have_xpath_with_content("premis:eventType", "virus check")
    end

    it "should have an eventDateTime" do
      expected_time = Time.parse('2009-01-27 14:32:12').xmlschema
      @event.should have_xpath_with_content("premis:eventDateTime", expected_time)
    end

    it "should have an eventDetail which matches the daitss:procedure" do
      @event.should have_xpath_with_content("premis:eventDetail",
        'Checked for virus during DataFile creation')
    end

    it "should have eventOutcomeInformation" do
      outcome = @event.xpath('premis:eventOutcomeInformation', NS_MAP).first
      outcome.should have_xpath_with_content('premis:eventOutcome', "SUCCESS")
      detail = outcome.xpath('premis:eventOutcomeDetail', NS_MAP).first
      detail.content.should be_empty
    end
    
    it "should point back to the representation object" do
      @event.should have_xpath_with_content('premis:linkingObjectIdentifier/premis:linkingObjectIdentifierValue',
                                            "info:fcla/daitss/E20090127_AAAAAA/representation/1")
    end
    
    it "should point back to a file object" do
      @event.should have_xpath_with_content('premis:linkingObjectIdentifier/premis:linkingObjectIdentifierValue',
                                            "info:fcla/daitss/E20090127_AAAAAA/representation/1/F20090127_AAAAAA")
    end

  end
  
  it "should have a submission event which references the submission agent" do
    event = @doc.xpath('//premis:eventType[contains(text(), "submission")]', NS_MAP).first
    event.parent.should have_xpath_with_content('premis:linkingAgentIdentifier/premis:linkingAgentIdentifierValue',
                                                 'info:fcla/daitss/agent/FIU')
    
  end
  
  it "should have an ingest event which references the archival agent" do
    event = @doc.xpath('//premis:eventType[contains(text(), "ingest")]', NS_MAP).first
    event.parent.should have_xpath_with_content('premis:linkingAgentIdentifier/premis:linkingAgentIdentifierValue',
                                                 'info:fcla/daitss/agent/FDA')
  end
  

end
