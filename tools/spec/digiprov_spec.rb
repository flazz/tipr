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

    @events = [event_doc.xpath('//daitss:EVENT', 'daitss' => "http://www.fcla.edu/dls/md/daitss/").to_a]
    @premis_schema = "http://www.loc.gov/standards/premis/v1/PREMIS-v1-1.xsd"
    
    raw_xml = TIPR.generate_digiprov(@events, 'E20090127_AAAAAA', 1)
    @doc = Nokogiri::XML raw_xml, nil, nil, Nokogiri::XML::PARSE_NOBLANKS
  end

  it "should be a valid premis document" do
#    Need to deal with validation using PREMIS 2.0 Commented out for now.
#    @doc.should have_xpath('premis:premis')
#    TIPR.validate(@doc.to_xml, LibXML::XML::Schema.new(@premis_schema)).should be_true
  end

  it "should have two objects" do
    @doc.xpath('premis:premis/premis:object', NS_MAP).size.should == 2
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
      @first_object.should have_xpath_with_content('premis:objectIdentifier/premis:objectIdentifierType', "DAITSS")
      @second_object.should have_xpath_with_content('premis:objectIdentifier/premis:objectIdentifierType', "DAITSS")
    end
    
    it "should have an objectIdentifierValue" do
      @first_object.should have_xpath_with_content('premis:objectIdentifier/premis:objectIdentifierValue', "E20090127_AAAAAA")
      @second_object.should have_xpath_with_content('premis:objectIdentifier/premis:objectIdentifierValue', "F20090127_AAAAAA")
    end

    it "should have an objectCategory" do
      @first_object.should have_xpath_with_content('premis:objectCategory', "representation")
      @second_object.should have_xpath_with_content('premis:objectCategory', "file")
    end
  
  end
  
  it "should have three events" do
    @doc.xpath('/premis:premis/premis:event', NS_MAP).size.should == 3
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
      @event.should have_xpath_with_content('premis:eventIdentifier/premis:eventIdentifierValue', "488374")
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
    
    it "should have a related object that points back to the representation object"
    it "should have a related object that points back to the file object"

  end

end
