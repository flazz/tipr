require 'rxp'
require 'schemastron'
require 'tempfile'
#require 'spec_helper'

# SIP a TIPR package
describe RXP do

  before :all do
    @rxp = RXP.new(File.join(File.dirname(__FILE__), '..', '..', 'RXPs', 'FDA0666002'), 
                             'FDA0666002')
  end
  
  # in the future, this could change
  it "should be initialized by a path to a tipr.xml" do
    lambda { @t = RXP.new(File.join(File.dirname(__FILE__), '..', '..', 'RXPs', 'FDA0666002'), 
                          'FDA0666002') }.should_not raise_error
  end
  
  it "should be validatable" do
    puts @rxp.errors.full_messages unless @rxp.valid?
    lambda { @rxp.valid? }.should_not raise_error
  end
  
  describe "the validation" do
  
    # Schema validation is in java; schematron validation is in ruby
    it "should have a method for determining if the RXP XML is schema compliant" do
      lambda { @rxp.schema_compliant? }.should_not raise_error
    end    
    
    it "should have a method for determining if the RXP XML is schematron compliant" do
      lambda { @rxp.schematron_compliant? }.should_not raise_error
    end
    
    it "should have a method to determine if it is complete" do
      lambda { @rxp.files_exist? }.should_not raise_error
    end
    
    it "should have a method to determine if it is covered" do
      lambda { @rxp.all_files_included? }.should_not raise_error
    end
  
    it "should have a method for determining if all METS checksums are valid" do
      lambda { @rxp.valid_checksums? }.should_not raise_error
    end
  end
  
  it "should output a valid DAITSS2 SIP" do
    @rxp.should generate_a_valid_sip
  end

end
