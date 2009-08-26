# RXP class takes a path to the root of a RXP and builds information about it

require 'nokogiri'
require 'validatable'
require 'valid'
require 'ingest_rep'
require 'erb'

NS = {
         'mets' => 'http://www.loc.gov/METS/',
         'daitss' => 'http://www.fcla.edu/dls/md/daitss/',
         'xlink' => 'http://www.w3.org/1999/xlink',
         'pre' => 'info:lc/xmlns/premis-v2',
         'xsi' => "http://www.w3.org/2001/XMLSchema-instance"
     }


class RXP

  include Validity
  include Validatable
  
  # The RXP should point to actual files
  validates_true_for :completeness, :logic => lambda {files_exist?}

  # All files should be included in the RXP XML files
  validates_true_for :coverage, :logic => lambda {all_files_included?}

  # All checksums listed by representations should check out
  validates_true_for :checksum_validity, :logic => lambda {valid_checksums?}
  
  # Check for schema and schematron compliance
  validates_true_for :schema, :logic => lambda {schema_compliant?}
  validates_true_for :schematron, :logic => lambda {schematron_compliant?}
  
  # Make sure the SIP is valid
  validates_true_for :sip, :logic => lambda {sip_valid?}
   

  attr_reader :representations, :rxp, :files, :rights, :digiprov, :name, 
              :struct_map

  # A RXP has a root, a rxp.xml doc, representation docs
  def initialize(rxp_root, name)
    
    # Two different kinds of files in a RXP
    @rxp_files = {}
    @package_files = []
  
    @name = name
    @path = rxp_root
    @rxp = load_rxp
    @representations = load_representations
    @files = load_files
    @rights = load_rights
    @digiprov = load_digiprov
    @struct_map = load_struct_map
  end
  
  def package_path
    @path
  end
  
  def generate_sip
    @sip = self
    st = File.join(File.dirname(__FILE__), '..', 'templates', 'sip.xml.erb')
    t = open st  do |io|
      string = io.read
      ERB.new(string, nil, '<>')
    end
    sip = Nokogiri::XML.parse(t.result(binding))
    
    @representations.each_with_index do |r, i|
      div_node = sip.xpath('//mets:div/mets:div', NS)[i]
      @struct_map[i].each { |n| div_node << n }
    end
    sip.to_xml
  end
  
  protected
  
  def load_files
    @representations.inject([]) { |files, r| files | r.files }
  end

  # Load rxp.xml
  def load_rxp
    tp = File.join(@path, 'rxp.xml')
    raise "Missing rxp.xml" unless File.exist? tp    
    open(tp) { |io| Nokogiri::XML io }
  end
    
  
  # Load rxp-rep-X.xml
  def load_representations
  
    # FDA only cares about original and active representations
    orig = @rxp.xpath('//mets:div[@ORDER="1"]//@FILEID', NS).first.content
    actv = @rxp.xpath('//mets:div[@TYPE="ACTIVE"]//@FILEID', NS).first.content
    
    
    rps = [orig, actv].uniq 
    raise "Missing representation XML" if rps.empty?
    rps.map! do |r|
      @rxp.xpath("//mets:file[@ID='#{r}']//@xlink:href", NS).first.content
    end

    
    rps.map! do |r|
      open(File.join(@path, r)) { |io| Nokogiri::XML io }
    end
    
    rps.map { |d| IngestRepresentation.new(d, @path) }
  end
  
  # Load rxp-rights.xml
  def load_rights
    # Load the rights document
    rights_path = @rxp.xpath('//mets:rightsMD//@xlink:href', NS)
    if rights_path.empty?
      nil
    else
      rp = rights_path.first.content
      rights = open(File.join(@path, rp)) { |io| Nokogiri::XML io }
      rights.root
    end
  end
  
  # Load rxp-digiprov.xml
  def load_digiprov
    # Take all PREMIS elements under the root node
    prov_path = @rxp.xpath('//mets:digiprovMD//@xlink:href', NS).first.content
    prov = open(File.join(@path, prov_path)) { |io| Nokogiri::XML io }
    prov.root  
  end
  
  def load_struct_map
    @representations.map do |r|
      fptrs = r.struct_map.xpath('//mets:fptr', NS)
      fptrs.each do |fptr| 
        oldid = fptr['FILEID']
        file = r.orig_ids[oldid]
        fptr['FILEID']="FILE-#{@files.index(file)}"
      end
      r.struct_map
    end
  end
  

end