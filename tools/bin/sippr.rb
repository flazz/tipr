#!/usr/bin/env ruby

require 'rxp'
require 'fileutils'

# Package name, TIPR root, and where to save the SIP
pname, tipr_path, sip_path = ARGV

t = RXP.new(tipr_path, pname)
unless t.valid?
  t.errors_on[:completeness].each { |e| puts "Incomplete RXP: " + e.message }
  t.errors_on[:checksum_validity].each { |e| puts "Bad checksum: " + e.message }
  t.errors_on[:schema].each { |e| puts "Schema error: " + e.message }
  t.errors_on[:schematron].each { |e| puts "Schematron error: " + e.message }
  t.errors_on[:sip].each { |e| puts "SIP generated is invalid: " + e.message }
  raise "Invalid RXP."
end
sip_dir = File.join(sip_path, pname)

# Make the SIP directory, and the xml
raise "Sorry, directory exists!" if File.directory?(sip_dir)
Dir.mkdir(sip_dir)
open(File.join(sip_dir, pname + '.xml'), 'w') { |file| file.puts t.generate_sip }

# Copy all relevant files into the SIP
t.files.each do |f|
  
  oldpath = File.join(tipr_path, f[:path])
  newpath = File.join(sip_dir, f[:path].split(/^files\//).last)
  newdir = File::dirname(newpath)
  
  # Make any necessary directories for this file
  FileUtils::makedirs(newdir) unless File.directory?(newdir)
  
  if File.exist?(oldpath)
    FileUtils::copy(oldpath, newpath)
  else
    puts "File doesn't exist: #{oldpath}"
  end

end

