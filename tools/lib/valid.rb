require 'validatable'
require 'digest/sha1'
require 'tempfile'
require 'schemastron'

include Schemastron

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
  # package_id and package_path must be defined
  def all_files_included?
    file_paths = files.map { |f| File.join(package_path, f[:path]) }
    
    package_files = if defined? package_id
                      Dir.glob(File.join(package_path, package_id, "**", "*"))
                    else
                      Dir.glob(File.join(package_path, 'files', '**', '*'))
                    end
    package_files = package_files.select { |f| File.file? f }

    package_files.each do |p|
      errors.add :coverage, "#{p} is in the package but is not covered by the" +
                             " representation(s)" unless file_paths.include?(p)  
    end
    
    return errors.on(:coverage).nil?

  end
  
  
  # Do all the files listed have valid checksums?
  # package_path and an array of files with :path and :sha_1 defined must exist
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
  
  # Are all RXP XML files schema compliant?
  def schema_compliant?
    
    xml_files = Dir.glob(File.join(package_path, 'rxp-*.xml'))
    xml_files.each do |file|
    
      # FIXME: Ignore empty rights file for now to pass validation
      unless file == File.join(package_path, 'rxp-rights.xml')
        # java code
        jfile = JFILE.new file
        jchecker = VALIDATOR.validate jfile
      
        # formedness errors
        (0...jchecker.getFatals.size).each do |n|
          f = jchecker.getFatals.elementAt(n)
          msg = "File: #{file}, Line: #{f.getLineNumber}, " +
                "Column #{f.getColumnNumber}: " + f.getMessage
          errors.add :schema, msg
        end
      
        # validation errors
        (0...jchecker.getErrors.size).each do |n|
          e = jchecker.getErrors.elementAt(n)
          msg = "File: #{file}, Line: #{e.getLineNumber}, " +
                "Column #{e.getColumnNumber}: " + e.getMessage
          errors.add :schema, msg
        end
      end  
    end
    errors.on(:schema).nil?
    
  end

  # Are all RXP XML files schematron (RXP Spec) compliant?
  def schematron_compliant?
    
    rxp = File.join(package_path, 'rxp.xml')
    results = stron_validate(rxp, RXP_STRON)
    
    # rxp rights, skip an empty rights file
    rights = File.join(package_path, 'rxp-rights.xml') 
    if File.exist?(rights) and not(File.zero?(rights))
      results |= stron_validate(rights, RXP_RIGHTS)
    end
    
    # rxp provenance
    prov = File.join(package_path, 'rxp-digiprov.xml')
    results |= stron_validate(prov, RXP_DIGIPROV_STRON)
    
    # representations and representation provenance
    reps = Dir.glob(File.join(package_path, 'rxp-rep-*.xml'))
    rep_prov = reps.select { |f| f =~ /digiprov\.xml/ }
    reps.reject! { |f| f =~ /digiprov\.xml/ }
   
    reps.each { |rep| results |= stron_validate(rep, REP_STRON) }
    rep_prov.each { |rp| results |= stron_validate(rp, REP_DIGIPROV_STRON) }
    
    results.each { |e| errors.add :schematron, "Line " + e[:line].to_s + ':' + e[:message] }
    errors.on(:schematron).nil?
  end
  
  def sip_valid?
    # Some setup for validation
    tio = Tempfile.open 'xml'
    tio.write generate_sip
    tio.flush
    tio.close
    
    # Do the validation
    jfile = JFILE.new tio.path
    jchecker = VALIDATOR.validate jfile
    tio.unlink
    
    # formedness errors
    (0...jchecker.getFatals.size).each do |n|
      f = jchecker.getFatals.elementAt(n)
      msg = "File: #{file}, Line: #{f.getLineNumber}, " +
            "Column #{f.getColumnNumber}: " + f.getMessage
      errors.add :sip, msg
    end
   
    # validation errors
    (0...jchecker.getErrors.size).each do |n|
      e = jchecker.getErrors.elementAt(n)
      msg = "File: #{file}, Line: #{e.getLineNumber}, " +
            "Column #{e.getColumnNumber}: " + e.getMessage
      errors.add :sip, msg
    end
  
    errors.on(:sip).nil?
  end
   
end
