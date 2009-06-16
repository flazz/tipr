require 'time'
require 'dip'

# A model for a DAITSS AIP that provides functionality for
# constructing a TIPR package
describe DIP do
  
  before do
    @path = File.join '..', 'DIPs', 'FDA0666002'
    @dip = DIP.new @path
  end
  
  it "should be initialized from a DAITSS DIP" do
    lambda { DIP.new @path }.should_not raise_error
  end
  
  it "should have an IEID" do
    @dip.ieid.should == 'E20090127_AAAAAA'
  end
  
  it "should have a package ID" do
    @dip.package_id.should == 'FDA0666002'
  end
  
  it "should have a creation date" do
    @dip.create_date.should == Time.parse('2009-01-27T14:32:55Z')
  end
  
  it "should have an original representation" do
    @dip.original_representation.should_not be_nil
  end
  
  it "should have a current representation" do
    @dip.current_representation.should_not be_nil
  end
  
  it "should have the AIP in its list of files" do
    aip = @dip.original_representation.files.values.select do |file|
            file[:path].match(/AIP_.*_LOC\.xml\Z/)
          end
    aip.should_not be_empty
  end
  
  it "should be valid" do
    @dip.should be_valid
  end
end
