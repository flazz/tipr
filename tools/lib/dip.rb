# This file contains functionality to extract information from a
# DAITSS DIP for use in constructing a TIPR DIP

require 'nokogiri'
require 'time'

class DIP
  
  attr_reader :rel_path, :ieid, :package_id, :create_date, :original_representation, :current_representation, :migration_map, :dfid_map, :global_files_path
  
  NS = {
    'mets' => 'http://www.loc.gov/METS/',
    'daitss' => 'http://www.fcla.edu/dls/md/daitss/',
    'xlink' => 'http://www.w3.org/1999/xlink'
  }

  def initialize(path)
    @path = path.chomp('/')     # Strip any trailing /es
    @doc = load_descriptor
    @global_doc = load_global_descriptor
    @rel_path = load_rel_path
    @global_files_path = load_global_files_path
    @ieid = load_ieid
    @package_id = load_package_id
    @create_date = load_create_date
    @dfid_map = load_dfid_map
    @migration_map = load_migration_map
    @original_representation = load_original_representation
    @current_representation = load_current_representation
  end
  
  def events_by_oid(oid)        # Given an OID, retrieve events
    @doc.xpath('//daitss:EVENT', NS).select do |event|
      event.xpath('./daitss:OID', NS).first.content == oid
    end
  end
  
  def events(fid)               # Given a file id, retrieve events
    events_by_oid(@dfid_map.index(fid).to_s)
  end
  
  protected
  
  def load_descriptor
    matches = Dir.glob "#{@path}/*/AIP_*_LOC.xml"
    raise 'No descriptor found' if matches.empty?
    raise 'Multiple possible descriptors' if matches.size > 1
    descriptor = matches.first
    open(descriptor) { |io| Nokogiri::XML io }
  end
  
  def load_global_descriptor   # For now, we allow nonexistent global file descriptors
    matches = Dir.glob "#{@path}/*/GFP_*_LOC.xml"
    raise "Multiple possible global descriptors found" if matches.size > 1
    descriptor = ( matches.empty? ? nil : matches.first )
    open(descriptor) { |io| Nokogiri::XML io } if descriptor 
  end
  
  def load_rel_path             # includes package_id
    matches = Dir.glob "#{@path}/*/AIP_*_LOC.xml"
    dir = File.dirname(matches.first)
    dir.split("DIPs/").last
  end

  def load_global_files_path
    if @global_doc
      matches = Dir.glob "#{@path}/*/GFP_*_LOC.xml"
      dir = File.dirname(matches.first)
      dir.split("DIPs/").last
    end
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
  
  def load_dfid_map             # Create a map between DFIDs and structMap FILEIDs
    file_ids = @doc.xpath('//mets:file/@ID', NS).map { |a| a.value }
    
    dfid_map = Hash.new
    
    file_ids.compact.each do |fid|
      tmd = @doc.xpath("//mets:file[@ID = '#{fid}']", NS).first['ADMID']
      dfid = @doc.xpath("//mets:techMD[@ID = '#{tmd}']//daitss:DFID", NS).first.content
      dfid_map[:"#{dfid}"] = fid 
    end
    dfid_map
  end
  
  def load_migration_map        # Create a map between migrated FILEIDs
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
      old_file_id = @dfid_map[:"#{old_dfid}"]
      new_file_id = @dfid_map[:"#{new_dfid}"]

      migration_map[:"#{old_file_id}"] = new_file_id

    end
    
    migration_map

  end
  
  def add_global_files(representation)
    # add our global files
    if @global_doc 
      global_ids = @global_doc.xpath('//mets:file', NS)
      global_ids.each do |gid|
        representation.push( { :sha_1 => gid['CHECKSUM'],
                               :path => gid.xpath('mets:FLocat/@xlink:href', NS).first.content
                             } )
      end
    end
    
    representation
  
  end
  
  def load_original_representation
    
    id_list = @doc.xpath('//mets:file', NS)
    
    # If we've had a migration, exclude these new files from this representation
    if not @migration_map.nil? 
      id_list = id_list.select { |node| not @migration_map.has_value?(node['ID']) }
    end
    
    rep = id_list.map do |file_node| 
      {
      	:sha_1 => file_node['CHECKSUM'],
      	:path => file_node.xpath('mets:FLocat/@xlink:href', NS).first.content,
      	:aip_id => file_node['ID']
      }
    end
    
    add_global_files(rep)
  end

  def load_current_representation
  
    return @original_representation if @migration_map.nil? # Original rep is current
    
    # Exclude older files that we've migrated from this representation
    id_list = @doc.xpath('//mets:file', NS).select do |file_node| 
      not @migration_map.member?(:"#{file_node['ID']}")
    end
    
    rep = id_list.map do |file_node| 
      {
        :sha_1 => file_node['CHECKSUM'],
        :path => file_node.xpath('mets:FLocat/@xlink:href', NS).first.content,
        :aip_id => file_node['ID']
      }
    end
    
    add_global_files(rep)
  end
    
end
