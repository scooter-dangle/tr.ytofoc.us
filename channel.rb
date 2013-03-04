# So sloppy! Need to turn this into a subclass of Array or
# something! What a mess!
class Channel < Array
    attr_accessor :archive_limit, :broadcaster
    def initialize broadcaster, archive_limit
        @broadcaster = broadcaster
        @archive_limit = archive_limit
    end

    def broadcast msg
        push msg
        shift [0, size - @archive_limit].max
        @broadcaster.broadcast msg
    end
end
