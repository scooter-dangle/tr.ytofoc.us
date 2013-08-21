# Contains Object#mb definition for more easily handling hash
# lookups that return nil... eventually should remove some
# of this and validate incoming data instead
require_relative './object.rb'

class SubscriptionMgr
    attr_accessor :broadcasters, :subscribers
    def initialize
        @broadcasters, @subscribers = {}, {}
    end

    def add_broadcaster name, broadcaster
        @broadcasters[name] = broadcaster
    end

    def add_subscriber signature, subscriber
        @subscribers[signature] = { subscriber: subscriber, broadcasters: [] }
    end

    # Using :mb here is super defensive... not sure if I should move
    # some of these checks to somewhere else
    def remove_subscriber signature
        subscriber = @subscribers[signature]
        subscriber.mb[:broadcasters].mb.each do |broad_name|
            @broadcasters[broad_name].delete subscriber[:subscriber]
        end
        @subscribers.mb.delete signature
    end

    # Defensive use of :mb
    def manage signature, parcel
        parcel['unsubscribe'].mb.each { |broadcaster_name| unsubscribe signature, broadcaster_name }
        parcel['subscribe'].mb.each { |broadcaster_name| subscribe signature, broadcaster_name }
    end

    # Defensive use of :mb
    def subscribe signature, broadcaster_name
        subscriber = @subscribers[signature]
        @broadcasters[broadcaster_name].mb.push subscriber[:subscriber]
        # Could be incorrect broadcaster name here...need validation
        subscriber[:broadcasters].push(broadcaster_name).uniq!
    end

    # Defensive use of :mb
    def unsubscribe signature, broadcaster_name
        subscriber = @subscribers[signature]
        @broadcasters[broadcaster_name].mb.delete subscriber[:subscriber]
        subscriber[:broadcasters].delete broadcaster_name
    end
end
