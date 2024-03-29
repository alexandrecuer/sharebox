##
# the poll model

class Poll < ApplicationRecord

  belongs_to :user

  validates :name, length: { in: 1..100 }

  validates :description, length: { in: 1..1000 }
  
  has_many :satisfactions, :dependent=> :destroy
  
  has_many :surveys, :dependent=> :destroy
  
  # uses validations module

  ##
  # Return a table with all closed questions
  # used in views/satisfactions/_form.html.erb 
  def get_closed_names
    self.closed_names.split(';')
  end
  
  ##
  # Return a table with all open questions
  # used in views/satisfactions/_form.html.erb
  def get_open_names
    self.open_names.split(';')
  end
  
  ##
  # Return a table with all closed and open questions
  # used by the create method of the poll controller
  def get_names
    get_closed_names + get_open_names
  end
  
  ##
  # Return all closed questions in a hash
  def hash_closed
    table=self.closed_names.split(';')
    hash={}
    table.each_with_index do |t,i|
      hash["closed#{i+1}"]=t.strip
    end
    hash
  end

  ##
  # Return all open questions in a hash
  def hash_open
    table=self.open_names.split(';')
    hash={}
    table.each_with_index do |t,i|
      hash["open#{i+1}"]=t.strip
    end
    hash
  end

  ##
  # generate csv file for a list of feedbacks
  # please note the satisfactions active records must be done with a jointure on the user table to get the email of the user owner
  def csv(satisfactions=nil)
    unless satisfactions
      satisfactions = self.satisfactions.joins(:user).select("satisfactions.*,users.email as email")
    end
    headers = ['id',I18n.t('sb.project'),I18n.t('sb.client'),I18n.t('sb.project_manager'),I18n.t('sb.collected_by'),I18n.t('sb.date'),I18n.t('sb.description')]+self.get_names
    csv = CSV.generate(headers: true, :col_sep => ';') do |c|
      c << headers
      satisfactions.each do |a|
        # ****************************************************************************
        # regular expression check !!!!!
        casenum = Validations.project_id_reg_exp.match(a.case_number)
        client = Validations.extract_client(a.case_number)
        w = Validations.extract_project_manager(a.case_number)
        # ****************************************************************************
        project_description = Validations.extract_project_description(a.case_number)
        closed=[]
        for i in (1..self.closed_names_number.to_i)
          closed << a["closed#{i}"]
        end
        open=[]
        for i in (1..self.open_names_number.to_i)
          open << a["open#{i}"]
        end
        c << [a.id,casenum,client,w]+[a.email,a.created_at,project_description]+closed+open             
      end
    end
    csv  
  end
  
  ##
  # Calculates stats on a list of feedbacks
  def stats(satisfactions=nil)
    tab = Array.new(self.closed_names_number){Array.new(5,0)}
    unless satisfactions
      satisfactions=self.satisfactions
    end
    satisfactions.each do |s|
      for i in 1..self.closed_names_number
        if value = s["closed#{i}"]
          tab[i-1][value] += 1
        else
          tab[i-1][0] += 1
        end
      end
    end
    result={}
    closed=self.hash_closed
    puts("stats method poll model working on the following list of closed questions : #{closed}")
    for i in 1..self.closed_names_number
      result[closed["closed#{i}"]]={}
      for y in 0..4
        level=I18n.t("sb.satisfaction_level_#{y}")
        result[closed["closed#{i}"]][level] = ( tab[i-1][y].to_f / satisfactions.length * 100 ).round(2)
      end
    end
    result
  end
  
  ##
  # Returns, for the active poll, the number of surveys delivered to clients<br>
  # possibility to define a date range and a text indication (groups) to filter on a group of users
  # time_start and time_end should be in format AAAA-MM-DD 00:00:00
  def count_sent_surveys(time_start=nil, time_end=nil, groups=nil)
    puts("BEGIN________________________________count_sent_surveys method poll model")
    # shares to a TEAM email do not count 
    if ENV['TEAM']
      domain=ENV.fetch('TEAM')
    else
      domain="cerema.fr"
    end
    sf_req=[]
    sat_req=[]
    sur_req=[]
    sf_expr=[]
    sat_expr=[]
    sur_expr=[]
    #shared_folders basics
    sf_req[0]=""
    sf_expr.push("folders.poll_id = ?")
    sf_req.push(self.id)
    sf_expr.push("shared_folders.share_email not like ?")
    sf_req.push("%#{domain}%")
    #satisfactions basics
    sat_req[0]=""
    sat_expr.push("satisfactions.folder_id < ?")
    sat_req.push(0)
    #surveys basics
    sur_req[0]=""
    #complements :-)
    if Validations.date_reg_exp.match(time_start) && Validations.date_reg_exp.match(time_end)
      time_start = Validations.date_reg_exp.match(time_start)[0]
      time_end = Validations.date_reg_exp.match(time_end)[0]
      sf_expr.push("shared_folders.created_at BETWEEN ? and ?")
      sf_req.push(time_start)
      sf_req.push(time_end)
      sat_expr.push("satisfactions.created_at BETWEEN ? and ?")
      sat_req.push(time_start)
      sat_req.push(time_end)
      sur_expr.push("surveys.created_at BETWEEN ? and ?")
      sur_req.push(time_start)
      sur_req.push(time_end)
    end
    if groups
      unless groups.include?("!")
        sf_expr.push("users.groups like ?")
        sf_req.push("%#{groups}%")
        sat_expr.push("users.groups like ?")
        sat_req.push("%#{groups}%")
        sur_expr.push("users.groups like ?")
        sur_req.push("%#{groups}%")
      else
        sf_expr.push("(users.groups is null or users.groups not like ?)")
        sf_req.push("%#{groups.gsub("!","")}%")
        sat_expr.push("(users.groups is null or users.groups not like ?)")
        sat_req.push("%#{groups.gsub("!","")}%")
        sur_expr.push("(users.groups is null or users.groups not like ?)")
        sur_req.push("%#{groups.gsub("!","")}%")
      end
    end
    sf_req[0]=sf_expr.join(" and ")
    sat_req[0]=sat_expr.join(" and ")
    sur_req[0]=sur_expr.join(" and ")
    puts("********************************************************")
    nb1=SharedFolder.joins(:folder).joins(:user).where(sf_req).count
    nb2=self.satisfactions.joins(:user).where(sat_req).count
    nb3=self.surveys.joins(:user).where(sur_req).count
    puts("satis launched in the folders/files system:#{nb1} satis collected out of the folders/files system:#{nb2} pending surveys #{nb3}")
    nb=nb1+nb2+nb3
    puts("END__________________________________count_sent_surveys method poll model")
    nb
  end
  
  ##
  # consider all surveys to have been sent once<br>
  # Use this method after upgrading old colibri versions (without customer email tracking)
  def consider_all_pending_surveys_sent_once
    log="going to fix all pending surveys without metadatas so that they can be considered to have been sent once...\n"
    metas={}
    metas["sent"]=1
    surveys=Survey.where(poll_id: self.id)
    surveys.each do |s|
      unless s.metas
        s.metas=ActiveSupport::JSON.encode(metas)
        unless s.save
          log="#{log} -> survey #{s.id} updating metadatas failed\n"
        else
          log="#{log} -> survey #{s.id} metadatas correctly fixed to #{metas} \n"
        end
      else
        log="#{log} -> survey #{s.id} has already some metadatas: #{s.metas} \n"
      end
    end
    log
  end  
  
end
