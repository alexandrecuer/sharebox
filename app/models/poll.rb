class Poll < ApplicationRecord

	belongs_to :user

	validates :name, length: { in: 1..100 }

	validates :description, length: { in: 1..1000 }

	has_many :satisfactions, :dependent=> :destroy

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






	def findClosedName(poll,i)
	    array = poll.closed_names.split(";");
	    array[i-1]
	end
	
	def totalclosed(poll,year)
		total = 0
		Satisfaction.all.each do |s|
			if s.poll_id == poll.id && s.created_at.year == year
				total += 1
			end
		end
		total
	end

	def moyenne(number,year,closed_names_id,poll)
		@total = 0
		Satisfaction.all.each do |s|
			if s.created_at.year == year && s.poll_id == poll.id
	    		i = closed_names_id
	    		if s.public_send("closed#{i}") == number
	    			@total += 1
	    		end
	    	end
	    end
	    result = ((@total.to_f / totalclosed(poll,year) ) * 100).round(2)
	end

	def serie(number,closed_names_id,poll)
		arr = (2010..Time.new.year).to_a
		@tab = Array.new

		for i in 0..arr.length-1
			@tab << [arr[i],moyenne(number,arr[i],closed_names_id,poll)]
		end 

		@tab

	end

end