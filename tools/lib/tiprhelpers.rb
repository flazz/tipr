require 'nokogiri'
require 'tipr'

# Some shared functionality when generating a TIPR DIP from the AIP and GFPs
module TIPRHelpers

  NS = {
    'mets' => 'http://www.loc.gov/METS/',
    'daitss' => 'http://www.fcla.edu/dls/md/daitss/',
    'xlink' => 'http://www.w3.org/1999/xlink'
  }

  # Load the ieid of a package
  def load_ieid(descriptor)
    ieid_node = descriptor.xpath('//daitss:IEID', NS).first
    raise "IEID not found" unless ieid_node
    ieid_node.content
  end

  # Create a FID --> DFID hash from a parsed DAITSS METS descriptor
  def load_dfid_map(descriptor)

    file_ids = descriptor.xpath('//mets:file/@ID', NS).map { |a| a.value }
    dfid_map = Hash.new
    
    file_ids.compact.each do |fid|
      tmd = descriptor.xpath("//mets:file[@ID = '#{fid}']", NS).first['ADMID']
      dfid = descriptor.xpath("//mets:techMD[@ID = '#{tmd}']//daitss:DFID", 
                             NS).first.content
      dfid_map[:"#{fid}"] = dfid 
    end

    dfid_map

  end
  
  # Retrieve events from a descriptor
  def events(oid, descriptor)
    descriptor.xpath('//daitss:EVENT', NS).select do |event|
      event.xpath('./daitss:OID', NS).first.content == oid
    end    
  end

  # Retrieve events by REL_OID from a descriptor
  def related_events(reloid, descriptor)
    descriptor.xpath('//daitss:EVENT', NS).select do |event|
      event.xpath('./daitss:REL_OID', NS).first.content == reloid
    end
  end

  # Retrieve the DAITSS:FORMAT of the file from the given TechMD ID
  def file_format(tmd_id, descriptor)
    node_path = "//mets:techMD[@ID='#{tmd_id}']//daitss:FORMAT"
    descriptor.xpath(node_path, NS).first.content
  end

  # Return the checksum, file path, oid, and events
  def file_info(file_node, path, dmap, descriptor)
    file = file_node.xpath('mets:FLocat/@xlink:href', NS).first.content
    full_file_path = File.join(path, file) 
    oid = dmap[:"#{file_node['ID']}"]
    format = file_format(file_node['ADMID'], descriptor)
    
    { :sum => file_node['CHECKSUM'], :oid => oid, :path => full_file_path,
      :format => DAITSS_FORMATS[:"#{format}"] }
  end

end