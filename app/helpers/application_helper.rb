##
# main helper module

module ApplicationHelper

	##
	# Generates the sorting hyperlink for the specified column
	def sortable(column, title = nil)
		# Capitalize first letter of each word only if title is nil 
  		title ||= column.titleize
  		direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
  		link_to title, {:sort => column, :direction => direction}
	end
end
