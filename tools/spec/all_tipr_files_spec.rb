require 'erb'
require 'nokogiri'
require 'dip'
require 'spec_helper'

share_as :AllTiprFiles do

  it "should be a mets document" do
    @doc.root.name.should eql('mets')
    @doc.root.should be_in_namespace('http://www.loc.gov/METS/')
  end
  
  it "should have an OBJID" do
    @doc.root['OBJID'].should_not be_nil
  end

  it "should have a mets header" do
    @rchildren.first.name.should eql('metsHdr')
  end

  describe "the header" do
    
    it "should have a create date" do
      @rchildren.first['CREATEDATE'].should_not be_nil
    end
    
    it "should have an agent" do
      @rchildren.first.should have_xpath('mets:agent')
    end

    describe "the agent" do
      it "should have a role of DISSEMINATOR" do
        @rchildren.first.should have_xpath('mets:agent[@ROLE="DISSEMINATOR"]') 
      end  
      
      it "should have a type of ORGANIZATION" do
        @rchildren.first.should have_xpath('mets:agent[@TYPE="ORGANIZATION"]') 
      end
      
      it "should have name of the contributing repository" do
        @rchildren.first.xpath('mets:agent/mets:name',
				NS_MAP).first.content.should_not be_nil
      end
      
      it "should have a note with the tipr version" do
        @rchildren.first.xpath('mets:agent/mets:note', 
                NS_MAP).first.content.should == "rxp-1.0.0"
      end
    end
  end

  # Check for structMap, but don't formalize description
  it "should have a struct map" do
    @doc.root.should have_xpath('//mets:structMap')
  end
 
  # We leave amdSec, dmdSec, fileSec & structMap checks & descriptions
  # to individual types

end
