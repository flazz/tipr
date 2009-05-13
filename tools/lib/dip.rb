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
              :current_representation, :migration_map
  

  def initialize(path)
    @path = path.chomp('/')     # Strip any trailing /es
    @descriptor_path = load_descriptor_path
    @global_descriptor_path = load_descriptor_path(true)
    @doc = load_descriptor
    @global_doc = load_descriptor(true)
    @ieid = load_ieid(@doc)
    @package_id = load_package_id
    @create_date = load_create_date
    @dfid_map  = load_dfid_map(@doc)
    @global_dfid_map = load_dfid_map(@global_doc) unless @global_doc.nil?
    @migration_map = load_migration_map
    @submitting_agent = load_submitting_agent
    @original_representation = load_original_representation
    @current_representation = load_current_representation
  end
  
  def global_files?
    @global_doc ? true : false
  end
    
  def package_path
    package = @path.split("/").last
    @path.split(package).first
  end
  
  # Returns an array of [path, sha_1] pairs for each distinct file in the
  # package
  def files
    @original_representation.files | @current_representation.files
  end

  protected
  
  # Get the relative path to a dip file
  def rel_path(global=false)    
    path = global ? "#{@path}/*/GFP_*_LOC.xml" : "#{@path}/*/AIP_*_LOC.xml"
    matches = Dir.glob(path)
    dir = File.dirname(matches.first)
    dir.split("DIPs/").last
  end
  
  def load_descriptor_path(global=false)
    desc_path = global ? "#{@path}/*/GFP_*_LOC.xml" : "#{@path}/*/AIP_*_LOC.xml"
    matches = Dir.glob(desc_path)
    raise 'No descriptor found' if not global and matches.empty?
    raise 'Multiple possible descriptors' if matches.size > 1
    matches.empty? ? nil : matches.first
  end
  
  # Load a descriptor -- for now, allow nonexistent global file descriptors
  def load_descriptor(global=false)
    descriptor = global ? @global_descriptor_path : @descriptor_path
    open(descriptor) { |io| Nokogiri::XML io } if descriptor
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
  def load_representation(type, global=false, rep=nil)

    # Select the appropriate descriptor and dfid_map
    doc = global ? @global_doc : @doc
    dfid_map = global ? @global_dfid_map : @dfid_map
    
    return rep unless doc
    
    # Create a new representation if we weren't provided with one
    rep = Representation.new(type, @ieid, @create_date, @package_id, 
                             @submitting_agent) unless rep
                             
    # And add our descriptor to the representation
    descriptor = global ? @global_descriptor_path : @descriptor_path
    
    # Create an arbitrary OID for the descriptor, and set the format to XML
    if descriptor
      descriptor_name = descriptor.split('/').last
      digest = Digest::SHA1.hexdigest(File.read(descriptor))
      descriptor_path = File.join(rel_path(global), descriptor_name)
      rep.add_file(digest, descriptor_path, @ieid + "_AIP", 
                  { :name => "XML", :version=> "1.0" } )
    end
    
    
    # Create a basic list of file IDs
    id_list = doc.xpath('//mets:file', NS)
    
    unless global or @migration_map.nil? # Don't log any global migrations
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
    
    # extract information about our files                            
    populate_representation!(rep, id_list, @dfid_map, rel_path(global), doc)
        
    rep.add_events(events(@ieid, doc)) unless (global or events(@ieid, doc).empty?)
    rep = load_representation(type, true, rep) unless global
    rep
  end
  
  def load_original_representation
    load_representation('ORIG')
  end

  def load_current_representation
    migration_map.nil? ? @original_representation : load_representation('ACTIVE')    
  end
  
  # Add files and related events info into a representation based on IEIDs
  def populate_representation!(rep, id_list, dmap, path, descriptor)
    id_list.each do |file_node|
      
      # Look up information about each file
      results = file_info(file_node, path, dmap, descriptor)
      rep.add_file(results[:sum], results[:path], results[:oid], results[:format])
      
      # Look up related events and add them
      evs = events(results[:oid], descriptor)
      rep.add_events(evs) unless evs.empty?
    end
  end
    
end
