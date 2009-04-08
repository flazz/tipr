require 'erb'
require 'nokogiri'
require 'dip'
require 'tipr'
require 'spec_helper'
require 'all_tipr_files_spec'

share_examples_for "all representations" do

  before(:each) do

    # need a daitss DIP
    path = File.join '..', 'DIPs', 'FDA0666002'
    @dip = DIP.new path

    # need the rep.xml template
    raw_xml = @type=='ORIG'? @dip.original_representation : @dip.current_representation
    @doc = Nokogiri::XML raw_xml.to_s

    # some additional instance variables to help clean up the code 
    @rchildren = @doc.root.children.select { |child| child.name != 'text'}
    @divs = @doc.root.xpath('//mets:structMap/mets:div', NS_MAP)
    @files = @doc.root.xpath('//mets:fileSec//mets:file', NS_MAP)
    @digiprov = @doc.root.xpath('//mets:amdSec/mets:digiprovMD', NS_MAP)
    @mynum = @type=='ORIG'? 1 : 2
  end

  it_should_behave_like AllTiprFiles
  
  it "should have an amdSec" do
    @doc.root.should have_xpath('//mets:amdSec')
  end
  
  describe "the amdSec" do

    it "should have one digiprov pertaining to the entire representation" do
      @doc.root.should have_xpath("//mets:amdSec/mets:digiprovMD[@ID='DPMD1']")
    end
    
    describe "each digiprov" do
      it "should reference an xml file" do
        @digiprov.each do |dp|
          dp.xpath('mets:mdRef', NS_MAP).first.should reference_an_xml_file
        end
      end
      
      it "should have an MDTYPE of PREMIS" do
        @digiprov.each do |dp|
          dp.should have_xpath("mets:mdRef[@MDTYPE='PREMIS']")
        end
      end
      
    end

  end

  it "should have a fileSec" do
    @doc.should have_xpath('//mets:fileSec')
  end
  
  describe "the fileSec" do

    it "should point to representation descriptors" do
      # Validate each file representation descriptor.
      @files.each do |f|
        f['ID'].should_not be_nil
        f['CHECKSUM'].should_not be_nil
        f['CHECKSUMTYPE'].should eql('SHA-1')
        f.xpath('./mets:FLocat', NS_MAP).first.should reference_a_file      
      end    
    end
    
    it "should have a metadata file group" do
      mdgroup = @doc.root.xpath('//mets:fileSec/mets:fileGrp[@USE="METADATA"]',
                                NS_MAP)
                                
      mdgroup.length.should == 1
    end

  end
  
  describe "the struct map" do
    it "should have a file pointer for each file in the filesec" do
      fptrs = @divs.xpath('./mets:fptr', NS_MAP).map { |fp| fp['FILEID'] }
      @files.each { |f| fptrs.should include(f['ID']) unless f['ID'] == 'REP-DPMD' }
    end
  end
end


describe "the original representation" do
  before(:each) do
    # this is the original representation
    @type = 'ORIG'
  end

  it_should_behave_like "all representations"  
end


describe "the active representation" do
  before(:each) do
    # this is the active representation
    @type = 'ACTIVE'
  end
  
  it_should_behave_like "all representations"
end
