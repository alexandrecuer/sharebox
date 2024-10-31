##
# for real time application<br>
# private users could publish topical information<br>
# public users would be able to subscribe to the topics of particular personal interest<br>
# rigth now all this part of the apllication is empty

module ApplicationCable

  ##
  # channels where to publish and to which users may subscribe
  class Channel < ActionCable::Channel::Base
  end
end
