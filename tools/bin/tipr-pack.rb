#!/usr/bin/env ruby

# Usage: ./tipr-pack.rb </PATH/TO/DIP> </PATH/TO/TIPR/PACKAGE>
# Note that both /PATH/TO/DIP and /PATH/TO/TIPR/PACKAGE should exist.
# 
# This file creates a bag in a tipr_bag directory inside /PATH/TO/TIPR/PACKAGE
# and populates it with package files and TIPR files generated from the DIP
#
# Note: Currently the entire DIP is copied, but our representations
#       do not reference any "global" xml files. Should the package
#       contain only referenced files?

require 'dip'
require 'tipr'
require 'bagit'
require 'set'
require 'libxml'

dpath, tpath, csv, gpath = ARGV

sigpath = File.join(tpath, 'tipr.xml.sig')

# Check arguments
raise "Usage: ./tipr-pack.rb <PATH/TO/DIP> <PATH/TO/TIPR>" unless (dpath && tpath)
raise "<PATH/TO/DIP> (#{ARGV[0]}) should exist" unless File.directory? dpath
raise "<PATH/TO/TIPR> (#{ARGV[1]}) should exist" unless File.directory? tpath
puts "WARNING: TIPR signature exists" if File.exists? sigpath

dip = DIP.new(dpath, csv, gpath)                # Our DIP

puts dip.valid? ? "DIP is valid" : "DIP is not valid"

# need original and active representations and their checksums
orep = TIPR.sha1_pair(dip.original_representation.to_s)
arep = TIPR.sha1_pair(dip.current_representation.to_s)

# need tipr envelope
tipr = TIPR.generate_tipr_envelope(dip, orep, arep)

# our schemas for validation
mets = LibXML::XML::Schema.new("http://www.loc.gov/standards/mets/mets.xsd")
#premis_1 = LibXML::XML::Schema.new("http://www.loc.gov/standards/premis/v1/PREMIS-v1-1.xsd")
premis = LibXML::XML::Schema.new("http://www.loc.gov/standards/premis/premis.xsd")

# Create our bag
bag_path = File.join(tpath, 'tipr_bag')
tipr_bag = BagIt::Bag.new bag_path

# bag up files from our DIP
Dir.glob("#{dpath}/**/*") do |f|
  if File.file?(f)
  
    # open the file
    my_file = File.open(f, 'r')
    
    # our bag path should *start* with "DIP-PACKAGE-ID" (messy)
    d = "#{dpath}".split('/').last # the "DIP-PACKAGE-ID"
    fp = f.split("#{dpath}").last  # the path relative to "DIP-PACKAGE-ID" 
    my_new_path = File.join("files", d, fp) # path to use for the bag
    
    tipr_bag.add_file("#{my_new_path}") do |io|
      io.write my_file.read
    end
  end
end

# Bag up any global files as [full_path, rel_path] 2ples

gfiles = []
dip.gfps.each do |gfp|
  
  base_dir = File.dirname(gfp.full_path)
  
  gfp.files.each do |f|
    file_path = f.last.path.split('/', 2)
    p = file_path.first == dip.package_id ? file_path.last : f.last.path
    gfiles.push( { :old_path => File.join(base_dir, p),
                   :new_path => File.join("files", f.last.path)
                 } )
  end
end

gfiles.each do |f|
  gf = File.open(f[:old_path], 'r')

  tipr_bag.add_file(f[:new_path]) do |io|
    io.write gf.read
  end

end

# validate our TIPR envelope, and representations
[orep[:xml], arep[:xml], tipr].each do |xml|
  if TIPR.validate(xml, mets) { |message, flag| puts message }
    puts "validated against mets"
  else
    puts "failed to validate against mets" 
  end
end

# bag our TIPR files
tipr_bag.add_file("tipr-rep-1.xml") { |file| file.puts orep[:xml] }
tipr_bag.add_file("tipr-rep-2.xml") { |file| file.puts arep[:xml] } if orep != arep
tipr_bag.add_file("tipr.xml") { |file| file.puts tipr }
tipr_bag.add_file("tipr-rights.xml") {}

# sign tipr.xml
puts "Creating TIPR signature...."
gpg_code = system("gpg -b -o #{sigpath} #{tpath}/tipr_bag/data/tipr.xml")
raise "Error writing signature" unless gpg_code

# add the sig to our bag and clean up
sig = File.open(sigpath, 'r')
tipr_bag.add_file("tipr.xml.sig"){ |io| io.puts sig.read }
File.delete(sigpath)

# bag our digiprov files
[dip.original_representation, dip.current_representation].uniq.each_with_index do |r,i|

  xml = r.digiprov[:digiprov]
  
  # bag the file    
  tipr_bag.add_file("tipr-rep-#{i+1}-digiprov.xml") { |file| file.puts xml }
  
  # validate the xml
  if TIPR.validate(xml, premis) { |message, flag| puts message }
    puts "digiprov for rep-#{i+1} validates"
  else
    puts "digiprov for rep-#{i+1} did not validate" 
  end
   
end

tipr_bag.manifest!


