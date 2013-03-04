class SlideMgr
    attr_accessor :num_slides
    attr_reader :broadcaster, :slide_number

    def initialize num_slides = 1
        @num_slides = num_slides
        @slide_number = 1
    end

    def broadcaster=(broad)
        @broadcaster = broad.register_channel
        broadcast
    end

    def broadcast
        @broadcaster.broadcast(
            label: 'slide',
            parcel: @slide_number
        ) if @broadcaster
        @slide_number
    end

    def next
        self[@slide_number.succ] unless @slide_number == @num_slides
    end
    alias_method :n, :next

    def prev
        self[@slide_number.pred] unless @slide_number == 0
    end
    alias_method :p, :prev

    def first
        self[1]
    end
    alias_method :begin, :first

    def last
        self[@num_slides]
    end

    def slide_number=(num)
        unless (1..@num_slides).include? num
            raise ArgumentError, "#{num} outside range: #{(1..@num_slides)}"
        end
        @slide_number = num
        broadcast
    end
    alias_method :[], :slide_number=
end
