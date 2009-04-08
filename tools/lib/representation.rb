require 'nokogiri'
require 'digest/sha1'
require 'tipr'

DIPFile = Struct.new(:sha_1, :path, :oid)

class EventArray < Array
  
  # Better approach: List only events, not arrays of events (don't worry about OID order)?

  # Probably worrying overmuch about forcing our array to look the way it should...
  
  def push(element)
    raise "Expected a hash" if element.class != Hash
    raise "Should have events" if not element[:events].kind_of?(Array)
    element[:events].each do |e| 
      raise "Expected array of Nokogiri::XML::Node" if not e.kind_of?(Nokogiri::XML::Node)
    end
    super(element)
  end  

end



class Representation

attr_reader :type, :ieid, :create_date, :package_id, :files, :events, :agents

alias_method :to_xml, :to_s

  # Requires a type ('ORIG' or 'ACTIVE'), ieid, date (dateTime object), and package_id)
  
  def initialize(type, ieid, date, package_id, submitting_agent) 
    @type = type
    @ieid = ieid
    @create_date = date
    @package_id = package_id
    @files = Array.new
    @events = EventArray.new
    @agents = { :archive => { :name=>"FDA", :project_code=>"1", :type=>"organization" }}
    @agents[:submission] = submitting_agent if submitting_agent and not submitting_agent.empty?
  end
  
  def to_s
    TIPR.generate_rep(self)
  end
  
  def sha_1
    Digest::SHA1.hexdigest(to_s)
  end

  def add_file(sha1, path, oid)
    @files.push( DIPFile.new(sha1, path, oid) )
  end

  def add_events(event_list, object_format)
    @events.push({ :events => event_list, :object_format => object_format })
  end
  
end
