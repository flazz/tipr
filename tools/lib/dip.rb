# This file contains functionality to extract information from a
# DAITSS DIP for use in constructing a TIPR DIP

require 'nokogiri'
require 'time'
require 'representation'
require 'validatable'
require 'digest/sha1'
require 'valid'


class DIP
  include Validatable
  include Validity

  # The AIP should point to actual files
  validates_true_for :completeness, :logic => lambda {files_exist?}

  # All files should be included in the AIP
  # TODO: Implement coverage if it's necessary
  validates_true_for :coverage, :logic => lambda {all_files_included?}

  # All checksums listed by representations should check out
  validates_true_for :checksum_validity, :logic => lambda {valid_checksums?}
  
  
  attr_reader :ieid, :package_id, :create_date, :original_representation, 
              :current_representation, :migration_map
  
  NS = {
    'mets' => 'http://www.loc.gov/METS/',
    'daitss' => 'http://www.fcla.edu/dls/md/daitss/',
    'xlink' => 'http://www.w3.org/1999/xlink'
  }

  def initialize(path)
    @path = path.chomp('/')     # Strip any trailing /es
    @descriptor_path = load_descriptor_path
    @global_descriptor_path = load_descriptor_path(true)
    @doc = load_descriptor
    @global_doc = load_descriptor(true)
    @ieid = load_ieid
    @package_id = load_package_id
    @create_date = load_create_date
    @dfid_map  = load_dfid_map
    @global_dfid_map = load_dfid_map(true)
    @migration_map = load_migration_map
    @submitting_agent = load_submitting_agent
    @original_representation = load_original_representation
    @current_representation = load_current_representation
  end
  
  # Given an OID, retrieve events
  def events(oid, global=false)
    doc = global ? @global_doc : @doc
    return [] unless doc
    
    doc.xpath('//daitss:EVENT', NS).select do |event|
      event.xpath('./daitss:OID', NS).first.content == oid
    end
  end
  
  def package_path
    package = @path.split("/").last
    @path.split(package).first
  end
  
  def files
    @original_representation.files || @current_representation.files
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
  
  def load_ieid
    ieid_node = @doc.xpath('//daitss:IEID', NS).first
    raise "IEID not found" unless ieid_node
    ieid_node.content
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
  
  
  # Create a map between DFIDs and structMap FILEIDs
  
  def load_dfid_map(global=false)

    doc = global ? @global_doc : @doc
    return {} if doc.nil?       # Nothing to map

    file_ids = doc.xpath('//mets:file/@ID', NS).map { |a| a.value }
    dfid_map = Hash.new
    
    file_ids.compact.each do |fid|
      tmd = doc.xpath("//mets:file[@ID = '#{fid}']", NS).first['ADMID']
      dfid = doc.xpath("//mets:techMD[@ID = '#{tmd}']//daitss:DFID", NS).first.content
      dfid_map[:"#{fid}"] = dfid 
    end
    dfid_map
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
  
  
  # retrieve the DAITSS:FORMAT of the file from the given TechMD ID
  
  def file_format(tmd_id, global=false)
    doc = global ? @global_doc : @doc    
    doc.xpath("//mets:techMD[@ID='#{tmd_id}']//daitss:FORMAT", NS).first.content
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
        
    if descriptor
      descriptor_name = descriptor.split('/').last
      digest = Digest::SHA1.hexdigest(File.read(descriptor))
      descriptor_path = File.join(rel_path(global), descriptor_name)
      rep.add_file(digest, descriptor_path, nil)
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
    id_list.each do |file_node|
      
      file = file_node.xpath('mets:FLocat/@xlink:href', NS).first.content
      full_file_path = File.join(rel_path(global), file) 
      oid = dfid_map[:"#{file_node['ID']}"]
      format = file_format(file_node['ADMID'], global)
      event_list = events(oid, global)
            
      rep.add_file( file_node['CHECKSUM'], full_file_path, oid )
      rep.add_events(event_list, format) if not event_list.empty?
    end
    
    rep.add_events(events(@ieid), nil) unless (global or events(@ieid).empty?)
    rep = load_representation(type, true, rep) unless global
    rep
  end
  
  def load_original_representation
    load_representation('ORIG')
  end

  def load_current_representation
    migration_map.nil? ? @original_representation : load_representation('ACTIVE')    
  end
    
end
