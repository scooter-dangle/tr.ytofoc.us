require './channel.rb'
require 'json'

class Broadcaster < Array
    attr_accessor :channels, :archive_limit, :formatter
    @@default_archive_limit = 20

    def initialize
        @archive_limit = @@default_archive_limit
        @channels = []
        @formatter = ->(msg) { JSON.dump msg }
    end

    def clear_archives!
        @channels.each &:clear
    end

    # Used for when an object wants its most recent
    # message to be automatically sent to a new sub-
    # scriber.
    def register_channel
        new_chan = Channel.new self, @archive_limit
        @channels.push new_chan
        new_chan
    end

    def broadcast msg
        msg = @formatter[msg]
        each { |x| x.send msg }
    end

    def push x
        @channels.each { |channel| x.send @formatter[channel.last] }
        super x
    end
end
