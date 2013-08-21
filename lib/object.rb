require_relative './nothing.rb'

class Object
    # Allows you to continue long method chains
    # on a value retrieved from a hash without having
    # to filter out nil values
    def mb
        nil? ?  Nothing.new(self) : self
    end
end
