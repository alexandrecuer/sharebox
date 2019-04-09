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
  def get_closed_names
    self.closed_names.split(';')
  end

  ##
  # Return a table with all open questions
  def get_open_names
    self.open_names.split(';')
  end

  ##
  # Return a table with all closed and open questions 
  def get_names
    get_closed_names + get_open_names
  end

  ##
  # Calculates average value for each closed question and for each satisfaction level<br>
  # we have to consider 4 different satisfaction levels plus "left blank" field<br>
  # return a 5 lines table gathering all the results, with one column for each closed question
  def calc(satisfactions=nil)
    tab = Array.new(self.closed_names_number){Array.new(5,0)}
    number_of_satisfactions = 0 
    unless satisfactions
      satisfactions=Satisfaction.where(poll_id: self.id)
    end
    satisfactions.each do |s|
      for i in 1..self.closed_names_number
        if value = s.public_send("closed#{i}")
          tab[i-1][value] += 1
        else
          tab[i-1][0] += 1
        end
      end
      number_of_satisfactions +=1
    end

    for i in 0..self.closed_names_number-1
      for y in 0..4
        tab[i][y] = ( tab[i][y].to_f / number_of_satisfactions * 100 ).round(2)
      end
    end
    # we return tab
    tab
  end
  
  
end