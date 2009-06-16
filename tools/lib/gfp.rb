require 'nokogiri'
require 'tiprhelpers'
require 'representation'

class GFPartial
  
  include TIPRHelpers
  
  attr_reader :files, :events, :ieid, :full_path
  
  # Initialize a partial GFP
  def initialize(descriptor_path, file_list, pid=nil)
    @doc = load_descriptor(descriptor_path)
    @path = File::dirname(descriptor_path)
    @full_path = File.expand_path(@path)
    @ieid = load_ieid(@doc)
    @dfid_map = load_dfid_map(@doc)
    @files = load_files(file_list, pid)
    @events = load_events
  end
  
  protected
  
  def load_descriptor(dpath)
    open(dpath) { |io| Nokogiri::XML io } if File.exist? dpath
  end
  
  # Generate a list of files with information
  def load_files(file_list, package)
    files = {}
    id_list = @doc.xpath('//mets:file', NS)

    id_list = id_list.select do |f|
      file_list.include?(f.xpath('mets:FLocat/@xlink:href', NS).first.content)
    end
    
    id_list.each do |f|
      results = file_info(f, @ieid, @dfid_map, @doc)
      sum, oid, format = results[:sum], results[:oid], results[:format]
      path = package ? File.join(package, results[:path]) : results[:path]
      files[:"#{results[:oid]}"] = (DIPFile.new(sum, path, oid, format))  
    end
    files
  end

  # Generate a list of related events, weeding out the ones we don't need
  def load_events
    
    all_events = @doc.xpath('//daitss:EVENT', NS)
    
    # All events where oid (and rel_oid, if it exists) are in our file list
    good_events = all_events.select do |e|
      oid = :"#{e.xpath('daitss:OID', NS).first.content}"
      rel_oid = e.xpath('daitss:REL_OID', NS)
      
      @files.include? oid and (rel_oid.empty? or @files.include? :"#{rel_oid.first.content}")
    end

    # All events with a rel_oid
    rel_oid_events = all_events.reject do |e|
      e.xpath('daitss:REL_OID', NS).empty?
    end
    
    # Events we're not sure about
    questionable_events = rel_oid_events.select do |e|
      oid = :"#{e.xpath('daitss:OID', NS).first.content}"
      rel_oid = :"#{e.xpath('daitss:REL_OID', NS).first.content}"
      
      @files.include?(oid) ^ @files.include?(rel_oid)
    end
    
    questionable_events.each do |e|
      rel_oid = :"#{e.xpath('daitss:REL_OID', NS).first.content}"
      oid = :"#{e.xpath('daitss:OID', NS).first.content}"
      case e.xpath('daitss:EVENT_TYPE', NS).first.content
        when 'DLK'
          # Downloaded links (DLK)
          raise "Need to add REL_OID" unless @files.include?(oid)
          note_text = e.xpath('daitss:NOTE', NS).first.content
          
          e.xpath('daitss:NOTE', NS).first.content= note_text.concat( ". Linked to by #{rel_oid.to_s}.")
          e.xpath('daitss:REL_OID', NS).remove
          good_events.push(e)
        when 'L'
          # TODO: Deal with L(ocalization)
          raise 'Localization event: Not implemented'
        when 'N'
          # TODO: Deal with N(ormalization)
          raise 'Normalization event: Not implemented'
        else 
          raise "Didn't recognize REL_OID event"
      end 
    end

    good_events
  end
end