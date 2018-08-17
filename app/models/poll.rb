class Poll < ApplicationRecord

  belongs_to :user

  validates :name, length: { in: 1..100 }

  validates :description, length: { in: 1..1000 }
  
  has_many :satisfactions, :dependent=> :destroy

  # Méthode qui permet de générer l'export CSV, lorsque les titres des colonnes ne sont pas forcément identiques aux identifiants de la base de données, il faut les écrire en dure dans le code 
  def to_csv(emails)
    headers = self.get_names.insert(0,'Date').insert(1,'Email').insert(2,'N° d''affaire')

    CSV.generate(headers: true, :col_sep => ';') do |csv|
      csv << headers

      attributes = ["created_at"]
      attributes1 = ["case_number"]

      for i in 1..self.closed_names_number
        attributes1.push("closed"+i.to_s)
      end
      for i in 1..self.open_names_number
        attributes1.push("open"+i.to_s)
      end

      Satisfaction.where(poll_id: self.id).each do |s|
        csv << s.attributes.values_at(*attributes) + emails.values_at(s.user_id) + s.attributes.values_at(*attributes1)
      end
    end
  end

  # Permet de retourner un tableau où chaque élément sera le titre d'une question fermée
  def get_closed_names
    c = self.closed_names.split(';')
  end

  # Permet de retourner un tableau où chaque élément sera le titre d'une question ouverte
  def get_open_names
    o = self.open_names.split(';')
  end

  # Tableau avec les titres des questions fermées + ouvertes
  def get_names
    o = get_closed_names + get_open_names
  end

  # Crée un tableau qui correspond au pourcentages.
  # 5 lignes ( Très satisfait, Satisfait, etc )
  # Le nombre de colonnes correspond au nombre de questions fermées du sondage
  def calc()
    tab = Array.new(self.closed_names_number){Array.new(5,0)}
    number_of_satisfactions = 0 

    Satisfaction.where(poll_id: self.id).each do |s|
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
    tab
  end
end