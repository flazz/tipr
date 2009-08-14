# This file contains functionality to extract information from a
# DAITSS DIP for use in constructing a TIPR DIP

# DIP package must be off of a DIPs directory to properly determine the path


require 'nokogiri'
require 'time'
require 'representation'
require 'validatable'
require 'digest/sha1'
require 'valid'
require 'tiprhelpers'
require 'tipr'
require 'csv'
require 'gfp'

# An object to hold old TIPR information, if it exists
RXP = Struct.new(:objects, :events, :agents)

class DIP
  include Validatable
  include Validity
  include TIPRHelpers

  # The AIP should point to actual files
  validates_true_for :completeness, :logic => lambda {files_exist?}

  # All files should be included in the AIP
  # TODO: Implement coverage if it's necessary
  validates_true_for :coverage, :logic => lambda {all_files_included?}

  # All checksums listed by representations should check out
  validates_true_for :checksum_validity, :logic => lambda {valid_checksums?}
  
  
  attr_reader :ieid, :package_id, :create_date, :original_representation, 
              :current_representation, :migration_map, :gfps, :rxp
  

  def initialize(path, global_csv=nil, global_pkgs_path=nil)
    @path = path.chomp('/')     # Strip any trailing /es
    @descriptor_path = load_descriptor_path
    @doc = load_descriptor
    @rxp = load_rxp
    @ieid = load_ieid(@doc)
    @package_id = load_package_id
    @create_date = load_create_date
    @gfps = load_gfps(global_csv, global_pkgs_path)    
    @dfid_map  = load_dfid_map(@doc)
    @migration_map = load_migration_map
    @submitting_agent = load_submitting_agent
    @original_representation = load_original_representation
    @current_representation = load_current_representation

  end
  
  def global_files?
    @gfps ? true : false
  end
    
  def package_path
    package = @path.split("/").last
    @path.split(package).first
  end
  
  # Returns an array of [path, sha_1] pairs for each distinct file in the
  # package
  def files
    @original_representation.files.values | @current_representation.files.values
  end
  
  def global_files
    global_files? ? @gfps.inject({}) { |files, gfp| files.merge gfp.files } : nil
  end
  
  def global_events
    global_files? ? @gfps.inject([]) { |events, gfp| events.concat gfp.events } : nil
  end
  
  # Create a hash of the XML and checksum of our TIPR-level provenance.
  def digiprov
    TIPR.sha1_pair(TIPR.generate_tipr_provenance(self, @rxp))
  end

  protected
  
  def load_gfps(csv, path)
    return nil unless csv and path
    
    gfp_list = []
    # Only get files that relate to this DIP
    gfp_files = CSV.readlines(csv).select { |l| l[0] == @ieid }
    
    # Get a short list of the related GFPs
    gfps = gfp_files.inject([]) { |list, l| list.push(l[1]) }
    gfps.uniq!
    
    # Go through the GFPs one by one and create GFPartials for each.
    gfps.each do |gfp|
      # Get the GFP descriptor
      matches = Dir.glob(File.join(path, gfp, 'GFP_*_LOC.xml'))      
      raise "No global descriptor found for #{gfp}" if matches.empty?
      descriptor = matches.first
      
      # Create the list of files
      file_list = gfp_files.select { |l| l[1] == gfp } 
      files = file_list.inject([]) { |list, line| list.push(line[3]) }
      files.uniq!
      
      # Add our GFP to our gfp list
      gfp_list.push(GFPartial.new(descriptor, files, @package_id))
    end
    
    gfp_list
    
  end  
  
  # Get the relative path to a dip file
  def rel_path   
    dir = File.dirname(@descriptor_path)
    dir.split("DIPs/").last
  end
  
  def load_descriptor_path
    desc_path = "#{@path}/*/AIP_*_LOC.xml"
    matches = Dir.glob(desc_path)
    raise 'No descriptor found' if matches.empty?
    raise 'Multiple possible descriptors' if matches.size > 1
    matches.first
  end
  
  # Load a descriptor
  def load_descriptor
    open(@descriptor_path) { |io| Nokogiri::XML io }
  end

  def load_rxp
    # TODO: pull the RXP from DAITSS 2
    RXP.new(nil, nil, nil)
  end
    
  def load_package_id
    package_id_node = @doc.xpath('//daitss:ENTITY_ID', NS).first
    raise "PACAKGE ID not found" unless package_id_node
    package_id_node.content
  end

  def load_create_date
    create_date_node = @doc.xpath('//mets:metsHdr/@CREATEDATE', NS).first
    raise "CREATE DATE not found" unless create_date_node
    Time.parse create_date_node.content
  end
  
   
  # Create a map between migrated FILEIDs
  def load_migration_map

    mnodes = @doc.xpath('//daitss:REL_TYPE', NS).select { |n| n.content == 'MIGRATED_TO' }
    return nil if mnodes.empty?	# Don't bother going further  
    migration_map = Hash.new    # Will hold FILEID migration relationships
    
    # Look up our DFIDs in our migration relationships, and add their  
    # corresponding FILEIDs to our migration_map hash.

    mnodes.each do |n|

      # DFIDs
      old_dfid = n.parent.xpath('./daitss:DFID_1', NS).first.content 
      new_dfid = n.parent.xpath('./daitss:DFID_2', NS).first.content 
      
      # FILEIDs
      old_file_id = @dfid_map.index(old_dfid)
      new_file_id = @dfid_map.index(new_dfid)

      migration_map[:"#{old_file_id}"] = new_file_id

    end
    
    migration_map

  end
  
  # Create a hash to represent the submitting agent of this package
  def load_submitting_agent
    name = @doc.xpath("//mets:techMD//daitss:AGREEMENT_INFO/@ACCOUNT", NS).first.content
    project_code = @doc.xpath("//mets:techMD//daitss:ACCOUNT_PROJECT", NS).first.content
    { :name => name, :project_code => project_code, :type => "organization" }
  end
  
  # Load our representation  
  def load_representation(type)

    # Create a new representation
    rep = Representation.new(type, @ieid, @create_date, @package_id, 
                             @submitting_agent, global_files, global_events)

    # Add our AIP descriptor to the representation
    # Create an arbitrary OID and set the format to XML
    descriptor_name = @descriptor_path.split('/').last
    digest = Digest::SHA1.hexdigest(File.read(@descriptor_path))
    descriptor_path = File.join(rel_path, descriptor_name)
    rep.add_file(digest, descriptor_path, @ieid + "_AIP", 
                { :name => "xml", :version=> "1.0" } )
    
    # Create a basic list of file IDs
    id_list = @doc.xpath('//mets:file', NS)
    
    unless @migration_map.nil?
      case type
            
        when 'ORIG'     
          # If we've had a migration, exclude newer files
          id_list = id_list.reject { |n| @migration_map.has_value?(:"#{n['ID']}") }
      
        when 'ACTIVE'
          # Use new, improved files in this representation
          id_list = id_list.reject { |n| @migration_map.member?(:"#{n['ID']}") }

        else
          raise 'Representation type should be "ORIG" or "ACTIVE"'
      end
    end
    
    rep.add_events(events(@ieid, @doc)) unless events(@ieid, @doc).empty?
    # extract information about our files                            
    populate_representation!(rep, id_list, @dfid_map, rel_path)
    rep.load_events(@doc)
    rep
  end
  
  def load_original_representation
    load_representation('ORIG')
  end

  def load_current_representation
    migration_map.nil? ? @original_representation : load_representation('ACTIVE')    
  end
  
  # Add files and related events info into a representation based on IEIDs
  def populate_representation!(rep, id_list, dmap, path)
    id_list.each do |file_node|
      
      # Look up information about each file
      results = file_info(file_node, path, dmap, @doc)
      rep.add_file(results[:sum], results[:path], results[:oid], results[:format])
      
      # Look up related events and add them
      evs = events(results[:oid], @doc)
      rep.add_events(evs) unless evs.empty?
    end
  end
    
end
