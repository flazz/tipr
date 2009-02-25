# This module holds a set of helper functions used by scripts and specs
# to manage various parts of constructing the TIPR package

require 'erb'          # ERB for generating our xml files
require 'digest/sha1'  # SHA1 library for calculating checksums
require 'libxml'       # For validating our xml files against schemas

# Some useful mappings....
DAITSS_FORMATS = {
            :APP_BZIP2        => { :name => "x-bzip2"},      
            :APP_DOS_EXEC     => { :name => "x-dosexec"},        
            :APP_GZIP         => { :name => "x-gzip"},           
            :APP_MS_EXCEL     => { :name => "vnd.ms-excel"},
            :APP_MS_WORD      => { :name => "msword"},   
            :APP_PDF_1_0      => { :name => "pdf", :version => "1.0"},
            :APP_PDF_1_1      => { :name => "pdf", :version => "1.1"},
            :APP_PDF_1_2      => { :name => "pdf", :version => "1.2"},
            :APP_PDF_1_3      => { :name => "pdf", :version => "1.3"},
            :APP_PDF_1_4      => { :name => "pdf", :version => "1.4"},
            :APP_PDF_1_5      => { :name => "pdf", :version => "1.5"},
            :APP_PDF_1_6      => { :name => "pdf", :version => "1.6"},
            :APP_PDF_1_7      => { :name => "pdf", :version => "1.7"},
            :APP_POSTSCRIPT   => { :name => "postscript"},      
            :APP_PRO          => { :name => "x-pro"},             
            :APP_RAR_COMP     => { :name => "x-rar-compressed"},
            :APP_UNK          => { :name => "octet-stream"},     
            :APP_XML_1_0      => { :name => "xml", :version => "1.0"},         
            :APP_XMLDTD_1_0   => { :name => "xml-dtd", :version => "1.0"},
            :APP_ZIP          => { :name => "zip"},
            :AUDIO_MPEG       => { :name => "mpeg"},               
            :AUDIO_UNK        => { :name => "unknown"},                
            :AUDIO_WAVE       => { :name => "x-wav"},                  
            :IMG_BMP          => { :name => "bmp"},                   
            :IMG_GIF          => { :name => "gif"},                   
            :IMG_JP2_1_0      => { :name => "jp2", :version => "1.0"},
            :IMG_JPEG_ADOBE   => { :name => "jpeg"},
            :IMG_JPEG_JFIF    => { :name => "jpeg"},                 
            :IMG_JPEG_UNKNOWN => { :name => "jpeg"},                   
            :IMG_JPX_1_0      => { :name => "jpx"},                   
            :IMG_PNG          => { :name => "png"},     
            :IMG_PORT_BMP     => { :name => "x-portable-bitmap"},    
            :IMG_PORT_GMP     => { :name => "x-portable-greymap"},    
            :IMG_PORT_PXMP    => { :name => "x-portable-pixmap"},    
            :IMG_TIFF_4_0     => { :name => "tiff", :version => "4.0"},     
            :IMG_TIFF_5_0     => { :name => "tiff", :version => "5.0"},
            :IMG_TIFF_6_0     => { :name => "tiff", :version => "6.0"},                 
            :TXT_CSV          => { :name => "csv"},              
            :TXT_HTML_4_0     => { :name => "html", :version => "4.0"},        
            :TXT_HTML_4_0_1   => { :name => "html", :version => "4.0.1"},           
            :TXT_PLAIN        => { :name => "plain"},                  
            :TXT_PRO          => { :name => "x-pro"},                   
            :TXT_RTF          => { :name => "rtf"},                   
            :TXT_SGML         => { :name => "sgml"},                    
            :VIDEO_AVI_1_0    => { :name => "avi", :version => "1.0"},                  
            :VIDEO_MPEG       => { :name => "mpeg"}, 
            :VIDEO_MS_VIDEO   => { :name => "x-msvideo"},             
            :VIDEO_QUICKTIME  => { :name => "quicktime"}
                }
                
DAITSS_EVENTS = {                       
            :CPD => "decrease pre{ :name => servation level",   
            :CPU => "increase preservation level",   
            :CV  => "virus check",                       
            :D   => "disseminate",                       
            :DEL => "deleted a previously ingested file",
            :DLK => "downloaded link",                   
            :FC  => "fixity Check",                      
            :I   => "ingest",                            
            :L   => "localized",                         
            :M   => "migrated",                          
            :N   => "normalized",                        
            :RM  => "refreshed media",
            :SUB => "submission", # we don't really track this, but it will make mocking easier                
            :UNKNOWN => "unknown event type",            
            :VC  => "verify checksum",                   
            :WA  => "withdraw by affiliate",             
            :WO  => "withdraw by operator"               
                }                                        
                                                                                
DAITSS_ROLES = {                                         
            :DLK => "Local copy of linked file",         
            :L   => "Version of file with local links",  
            :M   => "Migrated file"                      
                }                                        



module TIPR

  # Generates xml from the specified template

  def self.gen_xml(template)
    t = open File.join('templates', template) do |io|
      string = io.read
      ERB.new(string, nil, '<>')
    end
    t.result binding
  end

  # Generates representation xml from a template, dip, and the 
  # representation type

  def self.generate_rep(rep)
    @rep = rep
    gen_xml('rep.xml.erb')
  end
  
  # Generates the tipr envelope xml from a template, dip, and
  # original and active representations (xml + checksum)
  # In the future, this should be fixed to only require checksums

  def self.generate_tipr_envelope(dip, orig, active)
    @dip = dip
    @orig = orig
    @active = active
    gen_xml('tipr.xml.erb')
  end

  # Generates digiprov xml for a list of events
  # 
  # The oid should be provided when generating digiprov for an 
  # entire package in case the set of events is empty. 
  #
  # object_category should be file, representation, or bitstream 
  # to conform with premis.
    
  def self.generate_digiprov(events, package_id, rep_num, agents={})
    @package_id = package_id
    @events = events
    @rep_num = rep_num
    @agents = agents
    gen_xml('digiprov.xml.erb')
  end
  
  # Creates a simple hash of the input file and sha-1 sum.
  # Intended to facilitate generating and looping through representations.

  def self.sha1_pair(xml)
    {
      :sha_1 => Digest::SHA1.hexdigest(xml),
      :xml => xml
    }
  end
  
  # Validate an xml file against a schema. Schema must be a 
  # LibXML::XML::Schema;
  
  def self.validate(xml_string, schema)

    # parse xml to be validated
    instance = LibXML::XML::Document.string(xml_string)

    # validate
    instance.validate_schema(schema) { yield }
  end
end
