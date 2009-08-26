require 'nokogiri'

RXPFile = Struct.new(:sha_1, :path, :uri)

NS = {
         'mets' => 'http://www.loc.gov/METS/',
         'daitss' => 'http://www.fcla.edu/dls/md/daitss/',
         'xlink' => 'http://www.w3.org/1999/xlink',
         'pre' => 'info:lc/xmlns/premis-v2',
         'xsi' => "http://www.w3.org/2001/XMLSchema-instance"
     }

class IngestRepresentation

  attr_reader :files, :digiprov, :rights, :orig_ids, :struct_map

  def initialize(noko_rep, path)
    @path = path
    @doc = noko_rep
    @orig_ids = {}
    @files = load_files
    @digiprov = load_provenance
    @rights = load_rights
    @struct_map = load_struct_map
  end
  
  protected
  
  def load_files
    files = @doc.xpath('//mets:fileGrp[not(@USE="METADATA")]/mets:file', NS)
    files.map do |f|
      sha1 = f.xpath('@CHECKSUM', NS).first.content
      path = f.xpath('mets:FLocat/@xlink:href', NS).first.content
      fileid = f.xpath('@ID', NS).first.content
      uri = f.xpath('@OWNERID', NS).empty? ? nil : f.xpath('@OWNERID', NS).first.content

      @orig_ids[fileid] = RXPFile.new(sha1, path, uri)
      
    end
  end
  
  def load_provenance
    # Take all PREMIS elements under the root node
    prov_path = @doc.xpath('//mets:digiprovMD//@xlink:href', NS).first.content
    prov = open(File.join(@path, prov_path)) { |io| Nokogiri::XML io }
    rep = prov.xpath('//pre:object[@xsi:type="representation"]', NS).first
    rep_files = prov.xpath('//pre:object[@xsi:type="file"]', NS)
    
    rep_files.each do |rf|
      
      ident_value = rf.xpath('pre:objectIdentifier/pre:objectIdentifierValue',
                             NS).first.content.strip
    
      if rep.xpath("pre:relationship[normalize-space(
              pre:relatedObjectIdentification/pre:relatedObjectIdentifierValue
              ) != '#{ident_value}']", NS).empty?
 
        # Create a new relationship node
        n = Nokogiri::XML::Node.new('relationship', prov)
        rep.add_child(n)
        n.add_child(Nokogiri::XML::Node.new('relationshipType', prov))
        n.add_child(Nokogiri::XML::Node.new('relationshipSubType', prov))
        inode = Nokogiri::XML::Node.new('relatedObjectIdentification', prov)
        
        # object type
        obtype = Nokogiri::XML::Node.new('relatedObjectIdentifierType', prov)
        obtype.content="URI"
        
        # object identifier
        obvalue = Nokogiri::XML::Node.new('relatedObjectIdentifierValue', prov)
        obvalue.content=ident_value
        
        
        inode.add_child(obtype)
        inode.add_child(obvalue)
        n.add_child(inode)
        prov.namespaces.each_pair { |k, v| n.add_namespace(k,v) }
        links = rep.xpath("pre:linkingEventIdentifier | 
                           pre:linkingIntellectualEntityIdentifier |
                           pre:linkingRightsStatement", NS)
        if links.empty?
          rep.add_child(n)
        else
          link = links.first
          link.add_previous_sibling(n)
        end 

      end
    
    end
    
    prov.root
  end
  
  def load_rights
    # Load the rights document
    rights_path = @doc.xpath('//mets:rightsMD//@xlink:href', NS)
    if rights_path.empty?
      nil
    else
      rp = rights_path.first.content
      rights = open(File.join(@path, rp)) { |io| Nokogiri::XML io }
      rights.root
    end
  end
  
  def load_struct_map
    @doc.xpath('//mets:structMap', NS).first.children
  end

end