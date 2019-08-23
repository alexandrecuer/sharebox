##
# some global validation tests using regular expression
# all what is related to regular expression checking should be concentrated here
module Validations

  MEL = /([^\W])([a-zA-Z0-9_\-]+)*(\.[a-zA-Z0-9_\-]+)*\@([a-zA-Z0-9_\-]+)(\.[a-zA-Z0-9_\-]+)*\.([a-zA-Z]{2,4})/
  CUSTOMER = "Client"
  PROJECT_MANAGER = "Chargé d'affaire"
  DATE = /([0-9]{4}-[0-9]{2}-[0-9]{2})/
  PROJECT_ID = /[a-zA-Z][0-9]{1,2}[a-zA-Z]{1,2}[0-9]{1,4}/
  
  def self.client_pattern
    CUSTOMER
  end
  
  def self.project_manager_pattern
    PROJECT_MANAGER
  end
  
  ##
  # returns exact mel regular expression 
  # used in shared_folders controller + in ajax view _new.js
  def self.mel_reg_exp
    Regexp.new("^#{MEL.source}$")
  end
  
  ##
  # returns date regular expression
  def self.date_reg_exp
    DATE
  end
  
  ##
  # returns project id regular expression
  def self.project_id_reg_exp
    PROJECT_ID
  end
  
  ##
  # returns from str a valid client mel if any
  def self.extract_client(str)
    build_and_extract(str,CUSTOMER,MEL)
  end

  ##
  # returns from str a valid project_manager mel if any
  def self.extract_project_manager(str)
    build_and_extract(str,PROJECT_MANAGER,MEL)
  end
  
end

##
# generic research function
# note ( and ) in the regexp string are necessary for the email to be element 0 of the returned 'matchdata' array
def build_and_extract(str,type,mel_reg)
  valmel=""
  exp = Regexp.new("#{type}: (#{mel_reg.source})")
  # to debug
  #exp.match(str).captures.each do |e|
  #  puts (e)
  #end
  if a = exp.match(str)
    valmel=a.captures[0].to_s
    #puts(valmel)
  end
  valmel
end