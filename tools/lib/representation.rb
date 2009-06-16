require 'nokogiri'
require 'digest/sha1'
require 'tipr'

DIPFile = Struct.new(:sha_1, :path, :oid, :format)

class Representation

attr_reader :type, :ieid, :create_date, :package_id, :files, :events, :agents, 
            :global_files, :global_events

alias_method :to_xml, :to_s

  # Requires a type ('ORIG' or 'ACTIVE'), ieid, date (dateTime object), and package_id)
  
  def initialize(type, ieid, date, package_id, submitting_agent, global_files=nil, global_events=nil) 
    @type = type
    @ieid = ieid
    @create_date = date
    @package_id = package_id
    @files = Hash.new
    @events = Array.new
    @agents = { :archive => { :name=>"FDA", :project_code=>"1", :type=>"organization" }}
    @agents[:submission] = submitting_agent if submitting_agent and not submitting_agent.empty?
    @global_files = (global_files or {})
    @global_events = (global_events or [])
  end
  
  def to_s
    TIPR.generate_rep(self)
  end
  
  def sha_1
    Digest::SHA1.hexdigest(to_s)
  end
  
  def digiprov
    i = @type == 'ORIG' ? 1 : 2
    dp = TIPR.generate_digiprov(@events + @global_events, @ieid, i, 
                                @agents, @files.merge(@global_files))
    sum = Digest::SHA1.hexdigest(dp)
    { :sha_1 => sum, :digiprov => dp }
  end

  def add_file(sha1, path, oid, format)
    @files[:"#{sha1}"]= DIPFile.new(sha1, path, oid, format)
  end

  def add_events(event_list)
    @events |= event_list
  end
  
  # load file events for this representation from the given METS file
  def load_events(mets_file)
    events = mets_file.xpath('//daitss:EVENT', TIPR::NS).select do |event|
      @files.include? :"#{event.xpath('./daitss:OID', TIPR::NS).first.content}"
    end
    add_events events
  end
  
end
