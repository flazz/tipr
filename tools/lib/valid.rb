require 'validatable'
require 'digest/sha1'

module Validity
  
  # Do all files in the descriptors exist in the package?  
  def files_exist?
    p = package_path

    files.each do |f| 
      fp = File.join(p, f[:path])
      errors.add :completeness, "#{fp} is referenced by a descriptor but " +
                                "is not in the package" unless File.exist? fp
    end

    errors.on(:file_existence).nil?
  
  end
  
  
  # Are all files in the package included in the descriptor (except the AIP)?
  def all_files_included?
    file_paths = files.map { |f| File.join(package_path, f[:path]) }

    package_files = Dir.glob(File.join(package_path, package_id, "**", "*"))
    package_files = package_files.select { |f| File.file? f }

    package_files.each do |p|
      errors.add :coverage, "#{p} is in the package but is not covered by the" +
                             " representation(s)" unless file_paths.include?(p)  
    end
    
    return errors.on(:coverage).nil?

  end
  
  
  # Do all the files listed have valid checksums?
  def valid_checksums?
    
    p = package_path
    files.each do |f|
      file_path = File.join(p, f[:path])
      
      if File.exist?(file_path)
        digest = Digest::SHA1.hexdigest(File.read(file_path))
        errors.add :checksum_validity, "Digest for #{file_path} in AIP does " +
                                       "not match" unless digest == f[:sha_1]
      end    
    
    end
       
    errors.on(:checksum_validity).nil?
  
  end

end
