require 'erb'
require 'nokogiri'
require 'spec'
require 'representation'
require 'tipr'

describe Representation do
  before :all do
    submitting_agent = { :name => "FIU", :project_code=>252, :type=>"organization"}
    @date = Time.now
    @rep = Representation.new('ORIG', 'E20081121_AAAAEW', @date,  'FDA0666002', submitting_agent)
    @rep_doc = TIPR.generate_rep(@rep)
  end

  before :each do
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
    <DATE_TIME>2009-01-27 14:32:13</DATE_TIME>
    <EVENT_PROCEDURE>Verified checksum of data file</EVENT_PROCEDURE>
    <OUTCOME>SUCCESS</OUTCOME>
    <NOTE></NOTE>
  </EVENT>
</daitss>
XML
    @events = event_doc.xpath('//daitss:EVENT', 'daitss' => "http://www.fcla.edu/dls/md/daitss/").to_a
    @event_set = { :events => @events, :object_format => "JPEG" }

  end

  it "should have a create date" do
    @rep.create_date.should == @date
  end

  it "should have a package id" do
    @rep.package_id.should == 'FDA0666002'
  end

  it "should have an ieid" do
    @rep.ieid.should == 'E20081121_AAAAEW'
  end
  
  it "should have an empty global file array" do
    @rep.global_files.should be_kind_of(Array)
    @rep.global_files.should be_empty
  end
  it "should have an empty local file array" do
    @rep.local_files.should be_kind_of(Array)
    @rep.local_files.should be_empty
  end

  it "should have an empty package event array" do
    @rep.package_events.should be_kind_of(EventArray)
    @rep.package_events.should be_empty
  end

  it "should have an empty file event array" do
    @rep.file_events.should be_kind_of(EventArray)
    @rep.file_events.should be_empty
  end
  
  it "should have two agents" do
    @rep.agents.length.should == 2
  end
  
  it "should print out as xml derived from the rep.xml.erb template when to_s is called"  do
    @rep.to_s.should == @rep_doc.to_s
  end

  it "should have a sha_1 method which calculates the sha1 digest of its xml" do
    @rep.sha_1.should == Digest::SHA1::hexdigest(@rep_doc.to_s)
  end
  
  it "should have a method for adding a local package file" do
    @rep.add_local_file('e66bcfa9c53003156d58256c2326f80531e8b303', 'bin/findaip.rb', 'MYFILEID')
    @rep.local_files.length.should == 1 
  end
  
  it "should have a method for adding a global package file" do
    @rep.add_global_file('478959110067f97abb1c3cd7f6914613c82b4a4c', 'bin/tipr-pack.rb', 'MYGLOBALID')
    @rep.global_files.length.should == 1
  end 
  
  it "should have a method which lists all files in the representation" do
    @rep.files.length.should == 2
  end
  
  it "should have a method for combining file events and package-wide events" do
    @rep.file_events.push(@event_set)
    @rep.package_events.push( {:events => @events, :object_format => "TIFF"})
    @rep.events.length.should == 2
  end
  
end



describe EventArray do
  before :each do
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
    <DATE_TIME>2009-01-27 14:32:13</DATE_TIME>
    <EVENT_PROCEDURE>Verified checksum of data file</EVENT_PROCEDURE>
    <OUTCOME>SUCCESS</OUTCOME>
    <NOTE></NOTE>
  </EVENT>
</daitss>
XML
    @events = event_doc.xpath('//daitss:EVENT', 'daitss' => "http://www.fcla.edu/dls/md/daitss/").to_a
    @event_set = { :events => @events, :object_format => "JPEG" }
    @event_array = EventArray.new
  end
  
  it "should not allow you to add an invalid event" do
    lambda { @event_array.push('hate to say i told you so') }.should raise_error
    lambda { @event_array.push(@event_set.push('la di da')) }.should raise_error
  end
  
  it "should allow you to add a hash with an array of Nokogiri::XML::Nodes" do
    lambda { @event_array.push(@event_set) }.should_not raise_error
  end
end
