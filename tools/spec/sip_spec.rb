require 'sip'

# A model for constructing a DAITSS ingest SIP from a TIPR package

describe SIP do
  
  before do
    @sip_path = File.join '..', 'TIPR-IP', 'M2', 'data'
    @sip = SIP.new @sip_path
  end
  
  it "should be initialized from a TIPR tipr.xml file" do
    lambda { SIP.new @sip_path }.should_not raise_error
  end
  
  it "should have an package ID" do
    @sip.package_id.should == 'info:fcla/daitss/E20090127_AAAAAA'
  end
  
  it "should have at least one representation" do
    @sip.representations.should_not be_empty
  end

  it "should have a list of files" do
    @sip.files.length.should == 7
    @sip.files.first.class.should == SIPFile
  end
  
end
