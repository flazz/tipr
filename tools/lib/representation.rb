require 'nokogiri'
require 'digest/sha1'
require 'tipr'


class EventArray < Array
  
  # Better approach: List only events, not arrays of events (don't worry about OID order)?

  # Probably worrying overmuch about forcing our array to look the way it should...
  
  def push(element)
    raise "Expected a hash" if element.class != Hash   
    element[:events].each do |e| 
      raise "Expected array of Nokogiri::XML::Node" if not e.kind_of?(Nokogiri::XML::Node)
    end
    super(element)
  end  

end



class Representation

attr_reader :type, :ieid, :create_date, :package_id, :global_files, :local_files, :file_events, :package_events

alias_method :to_xml, :to_s

  # Requires a type ('ORIG' or 'ACTIVE'), ieid, date (dateTime object), and package_id)
  
  def initialize(type, ieid, date, package_id) 
    @type = type
    @ieid = ieid
    @create_date = date
    @package_id = package_id
    @global_files = Array.new
    @local_files = Array.new
    @file_events = EventArray.new
    @package_events = EventArray.new
  end
  
  def to_s
    TIPR.generate_rep(self)
  end
  
  def sha_1
    Digest::SHA1.hexdigest(to_s)
  end
  
  def events
    @package_events | @file_events
  end
  
  def files
    @local_files | @global_files
  end
  
  def add_global_file(sha1, path, oid) 
    @global_files.push( { :sha_1 => sha1, :path => path, :oid => oid, :global => true })
  end
  
  def add_local_file(sha1, path, oid)
    @local_files.push( { :sha_1 => sha1, :path => path, :oid => oid })
  end
  
  def add_package_events(event_list, object_format)
    @package_events.push({ :events => event_list, :object_format => object_format })
  end
  
  def add_file_events(event_list, object_format)
    @file_events.push({ :events => event_list, :object_format => object_format })
  end

end
