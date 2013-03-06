class Nothing
    def initialize obj
        @obj = obj
    end

    def method_missing *_
        @obj
    end
end
