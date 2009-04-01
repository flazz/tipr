# This file contains functionality to extract information from a TIPR package 
# to create a DAITSS SIP.
#
# BUGS: (in templates/daitss_sip.xml.erb) METS StructMap for each representation 
#       only delves 2 divs deep.

require 'nokogiri'
require 'tipr'

SIPFile = Struct.new(:path, :sum)

# SIPRepresentation class should be merged with our other Representation
# class, but for now, I'll just duplicate functionality
class SIPRepresentation
  
  attr_reader :files, :file_groups
  
  # Takes a /path/to/a/tipr-rep-x.xml
  def initialize(rep_path)
    @path = rep_path
    @rep = load_rep
    @fid_map = {}
    @files = load_files        # Load our files and FID map
    @file_groups = load_groups
  end
  
  protected
  
  def load_rep
    open(@path) { |io| Nokogiri::XML io }
  end
  
  # An array of [path, checksum] for all files described by this representation
  def load_files   
    repfiles = @rep.xpath('mets:mets/mets:fileSec//mets:file', TIPR::NS)
    
    # Map to [filepath, checksum], and update fid_map
    repfiles.map do |f|
      file = f.xpath('mets:FLocat/@xlink:href', TIPR::NS).first.content
      sum = f.xpath('@CHECKSUM', TIPR::NS).first.content
      id = f.xpath('@ID', TIPR::NS).first.content
      s = SIPFile.new(file, sum)
      @fid_map[:"#{id}"] = s
      s
    end
        
  end
  
  # Returns an array of arrays and file array elements to describe the structure
  # of a div section
  def get_divs(node)
    file_list = []
    unless node.xpath('mets:div', TIPR::NS).empty?
      divs = node.xpath('mets:div', TIPR::NS)
      divs.each { |d| file_list.push(get_divs(d)) }
    end
    files = node.xpath('mets:fptr/@FILEID', TIPR::NS)
    file_list + files.map { |f| @fid_map[:"#{f.content}"] }
  end
  
  # A mapping of the <div>s in this representation
  def load_groups
    div = @rep.xpath('mets:mets/mets:structMap/mets:div', TIPR::NS).first
    get_divs(div)
  end

end

class SIP

  attr_reader :path, :tipr, :package_id, :partner, :representations, :files

  def initialize(tipr_path)
    @path = tipr_path
    @tipr = load_tipr
    @package_id = load_package_id
    @partner = load_partner
    @representations = load_representations
    @files = load_files
  end

  # Generate the METS for this SIP
  def to_s
    TIPR.generate_sip(self)
  end
  
  protected
  
  # Load the TIPR file as a Nokogiri document
  def load_tipr
    tipr = File.join(@path, 'tipr.xml')
    open(tipr) { |io| Nokogiri::XML io }
  end
  
  # Load the package id to be used by DAITSS
  def load_package_id
    @tipr.xpath('mets:mets/@OBJID', TIPR::NS).first.content
  end
  
  # Load the TIPR partner
  def load_partner
    @tipr.xpath('//mets:metsHdr/mets:agent/mets:name', TIPR::NS).first.content
  end
  
  # Load the representations as Nokogiri docs
  def load_representations
    reps = @tipr.xpath('mets:mets/mets:fileSec//mets:FLocat/@xlink:href', 
                       TIPR::NS)
    reps.map { |r| SIPRepresentation.new(File.join(@path, r)) }
  end
  
  def load_files
    @representations.inject([]) { |fs, rep| fs | rep.files }
  end

end

