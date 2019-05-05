##
# the poll model

class Poll < ApplicationRecord

  belongs_to :user

  validates :name, length: { in: 1..100 }

  validates :description, length: { in: 1..1000 }
  
  has_many :satisfactions, :dependent=> :destroy
  
  has_many :surveys, :dependent=> :destroy
  
  ##
  # generate the attributes to explore a satisfactions active record associated to a poll<br>
  # structure is [created_at, case_number/description, all closed questions separated by comma, all open questions separated by comma]
  # DEPRECATED
  def fetch_attributes
    attributes = []
    attributes.push("created_at")
    attributes.push("case_number")

    for i in 1..self.closed_names_number
        attributes.push("closed#{i}")
    end
    for i in 1..self.open_names_number
        attributes.push("open#{i}")
    end
    attributes
  end

  ##
  # generate the csv file containing all the results to the poll
  # DEPRECATED
  def to_csv(emails)
    headers = self.get_names.insert(0,'Email').insert(1,'Date').insert(2,'N° affaire')
    attributes=self.fetch_attributes
    
    CSV.generate(headers: true, :col_sep => ';') do |csv|
      csv << headers

      Satisfaction.where(poll_id: self.id).each do |s|
        csv << emails.values_at(s.user_id) + s.attributes.values_at(*attributes)
      end
    end
  end

  ##
  # Return a table with all closed questions
  # used in views/satisfactions/_form.html.erb 
  def get_closed_names
    self.closed_names.split(';')
  end
  
  ##
  # Return a table with all open questions
  # DEPRECATED
  def get_open_names
    self.open_names.split(';')
  end
  
  ##
  # Return a table with all closed and open questions
  # DEPRECATED
  def get_names
    get_closed_names + get_open_names
  end
  
  ##
  # Return all closed questions in a hash
  def hash_closed
    closed=self.closed_names.split(';')
    hash={}
    closed.each_with_index do |c,i|
      hash["closed#{i+1}"]=c.strip
    end
    hash
  end

  ##
  # Return all open questions in a hash
  def hash_open
    opens=self.open_names.split(';')
    hash={}
    opens.each_with_index do |o,i|
      hash["open#{i+1}"]=o.strip
    end
    hash
  end


  ##
  # Calculates average value for each closed question and for each satisfaction level<br>
  # we have to consider 4 different satisfaction levels plus "left blank" field<br>
  # return a 5 lines table gathering all the results, with one column for each closed question
  # DEPRECATED
  def calc(satisfactions=nil)
    tab = Array.new(self.closed_names_number){Array.new(5,0)}
    number_of_satisfactions = 0 
    unless satisfactions
      satisfactions=Satisfaction.where(poll_id: self.id)
    end
    satisfactions.each do |s|
      for i in 1..self.closed_names_number
        #if value = s.public_send("closed#{i}")
        if value = s["closed#{i}"]
          tab[i-1][value] += 1
        else
          tab[i-1][0] += 1
        end
      end
      number_of_satisfactions +=1
    end
    #puts("#{number_of_satisfactions} VS #{satisfactions.length}")
    for i in 0..self.closed_names_number-1
      for y in 0..4
        tab[i][y] = ( tab[i][y].to_f / satisfactions.length * 100 ).round(2)
      end
    end
    # we return tab
    #puts(tab)
    tab
  end
  
  ##
  # generate csv file for a list of feedbacks
  # please note the satisfactions active records must be done with a jointure on the user table to get the email of the user owner
  def csv(satisfactions=nil)
    unless satisfactions
      satisfactions = self.satisfactions.joins(:user).select("satisfactions.*,users.email as email")
    end
    headers = ['id','Affaire','client','chargé d\'affaire','récolté par','Date réception','Description']+self.get_names
    csv = CSV.generate(headers: true, :col_sep => ';') do |c|
      c << headers
      satisfactions.each do |a|
        casenum = /[a-zA-Z][0-9]{1,2}[a-zA-Z]{1,2}[0-9]{1,4}/.match(a.case_number)
        client = /Client: ([^\W][a-zA-Z0-9_\-]+(\.[a-zA-Z0-9_\-]+)*\@[a-zA-Z0-9_\-]+(\.[a-zA-Z0-9_\-]+)*\.[a-zA-Z]{2,4})/.match(a.case_number)[1].to_s
        w=/Chargé d'affaire: ([^\W][a-zA-Z0-9_\-]+(\.[a-zA-Z0-9_\-]+)*\@[a-zA-Z0-9_\-]+(\.[a-zA-Z0-9_\-]+)*\.[a-zA-Z]{2,4})/.match(a.case_number)[1].to_s
        closed=[]
        for i in (1..self.closed_names_number.to_i)
          closed << a["closed#{i}"]
        end
        open=[]
        for i in (1..self.open_names_number.to_i)
          open << a["open#{i}"]
        end
        c << [a.id,casenum,client,w]+[a.email,a.updated_at,a.case_number]+closed+open             
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
        result[closed["closed#{i}"]][MAIN["satisfaction_level_#{y}"]] = ( tab[i-1][y].to_f / satisfactions.length * 100 ).round(2)
      end
    end
    result
  end
  
  ##
  # Returns, for the active poll, the number of surveys delivered to clients<br>
  # possibility to define a date range and a text indication (groups) to filter on a group of users
  def count_sent_surveys(time_start=nil, time_end=nil, groups=nil)
    puts("BEGIN________________________________count_sent_surveys method poll model")
    # shares to a TEAM email do not count 
    if ENV['TEAM']
      domain=ENV.fetch('TEAM')
    else
      domain="cerema.fr"
    end
    unless time_start && time_end
      nb=SharedFolder.joins(:folder).where("folders.poll_id = ? and shared_folders.share_email not like ?",self.id,"%#{domain}%").count
      nb+=Satisfaction.where("folder_id < ? and poll_id= ?", 0, self.id).count
      nb+=Survey.where(poll_id: self.id).count
    else
      date = /([0-9]{4}-[0-9]{2}-[0-9]{2})/
      if date.match(time_start) && date.match(time_end)
        time_start="#{date.match(time_start)} 00:00:00"
        time_end="#{date.match(time_end)} 00:00:00"
        puts("*******enumerating all surveys for poll on data range #{time_start} to #{time_end}*******")
        unless groups
          request="folders.poll_id = ? and shared_folders.share_email not like ? and shared_folders.created_at BETWEEN ? and ?"
          nb=SharedFolder.joins(:folder).where(request,self.id,"%#{domain}%", time_start, time_end).count
          request="folder_id < ? and created_at BETWEEN ? and ?"
          nb+=self.satisfactions.where(request, 0, time_start, time_end).count
          request="poll_id = ? and created_at BETWEEN ? and ?"
          nb+=Survey.where(request, self.id, time_start, time_end).count
        else
          request="folders.poll_id = ? and shared_folders.share_email not like ? and shared_folders.created_at BETWEEN ? and ? and users.groups like ?"
          nb=SharedFolder.joins(:folder).joins(:user).where(request,self.id,"%#{domain}%", time_start, time_end, "%#{groups}%").count
          request="folder_id < ? and satisfactions.created_at BETWEEN ? and ? and users.groups like ?"
          nb+=self.satisfactions.joins(:user).where(request, 0, time_start, time_end, "%#{groups}%").count
          request="poll_id = ? and surveys.created_at BETWEEN ? and ? and users.groups like ?"
          nb+=Survey.joins(:user).where(request, self.id, time_start, time_end, "%#{groups}%").count
        end
      end
    end
    puts("END__________________________________count_sent_surveys method poll model")
    nb
  end
  
  
end