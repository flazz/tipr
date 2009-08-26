require 'rjb'
require 'schematron'
require 'libxml'

include LibXML

module Schemastron

  # setup rjb validator
  def load_validator
    jar_file = File.join(File.dirname(__FILE__), '..', 'ext', 'xmlvalidator.jar')
    
    ENV['CLASSPATH'] = if ENV['CLASSPATH']
      "#{jar_file}:#{ENV['CLASSPATH']}"
    else
      jar_file
    end

    j_Validator = Rjb.import 'edu.fcla.da.xml.Validator'
    j_Validator.new
  end  

  # schematron
  def load_stron name
    schema = File.join(File.dirname(__FILE__), '..', '..', 'schematron', name)
    XML.default_line_numbers = true
    doc = XML::Parser.file(schema).parse
    Schematron::Schema.new doc
  end

  
  def stron_validate(file, stron)
    doc = XML::Parser.file(file).parse
    stron.validate doc
  end

  module_function :load_validator
  module_function :load_stron
  module_function :stron_validate
    
  VALIDATOR = load_validator
  JFILE = Rjb.import 'java.io.File'
  
  RXP_STRON = load_stron "tipr.sch"
  RXP_DIGIPROV_STRON = load_stron "tipr-digiprov.sch"
  RXP_RIGHTS_STRON = load_stron "tipr-rights.sch"
  REP_STRON = load_stron "tipr-rep.sch"
  REP_DIGIPROV_STRON = load_stron "tipr-rep-digiprov.sch"

end
