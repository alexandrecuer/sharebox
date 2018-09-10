## 
# the main engine from which all models inherit

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
