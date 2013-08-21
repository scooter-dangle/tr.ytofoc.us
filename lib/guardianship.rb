require 'fiber'
require 'sourcify'
require './publicist'

class Guardianship
    attr_accessor :stage_name
    attr_reader :publicist, :ward, :running_methods

    # Development only
    attr_accessor :extended_engagements, :ongoing_engagements

    def initialize ward
        @ward = ward

        @ongoing_engagements = []
        @publicist = Publicist.new

        # Development only - maybe
        @extended_engagements = [
            :each,
            :select,
            :select!,
            :keep_if,
            :reject,
            :reject!,
            :delete_if,
            :assoc,
            :rassoc,
            :map,
            :map!,
            :cycle,
            :reverse_each,
            :delete_if,
        ]
    end

    def publicist=(publicist)
        @publicist.remove self unless @publicist.nil?
        publicist.add self
        @publicist = publicist
    end

    def next *args
        if @ongoing_engagements.empty? then
            print "No ongoing_engagements.\n"
            return
        end
        # Should possibly prune engagements here
        out = @ongoing_engagements.last[:fiber].resume *args
        prune_engagements
        out
    end

    def ongoing_engagements
        @ongoing_engagements.map { |x| x.reject { |k| k == :fiber } }
    end

    def publicize hsh = {}
        @publicist.publicize self, hsh
    end
    alias_method :publicise, :publicize

    def make_entrance
        publicize
    end

    def drop_everything
        @ongoing_engagements.clear
        make_entrance
    end

    class << self; attr_accessor :sourcification; end
    self.sourcification = :full

    def self.get_source block
        case sourcification
        when :full
            block.to_source
        when :defensive
            begin
                block.to_source
            # Super clobbery
            rescue Exception => e
                "Block source unavailable"
            end
        when :none
            "Block source unavailable"
        end
    end

    alias_method :base_respond_to?, :respond_to?
    def respond_to? arg
        (base_respond_to? arg) or (@ward.respond_to? arg)
    end

    private
    def enter_extended_engagement meth, *args, hsh
        raise StandardError, 'Cannot nest inverted iteration in non-inverted iteration' if inversion_check hsh
        fiber = Fiber.new do
            out = @ward.__send__ meth, *args, &->(x) {
                @ongoing_engagements.last[:yield] = x
                publicize
                Fiber.yield x
            }
            @ongoing_engagements.pop
            press_packet = {}
            press_packet[:name] = meth
            press_packet[:args] = args
            press_packet[:result] = out
            press_packet[:block] = hsh[:block] if hsh[:block]
            publicize press_packet
            out
        end

        press_packet = {}
        press_packet[:name] = meth
        press_packet[:args] = args
        press_packet[:block] = hsh[:block] if hsh[:block]
        press_packet[:fiber] = fiber
        @ongoing_engagements.push press_packet
        self
    end

    def inversion_check hsh
        # Need to return true when someone attempts to nest inverted iteration
        # in non-inverted iteration
        false
    end

    def prune_engagements
        unless @ongoing_engagements.empty? or @ongoing_engagements.last[:fiber].alive?
            meth, dead_fib = *@ongoing_engagements.pop
            prune_engagements
        end
    end

    def method_missing meth, *args, &block
        return super unless @ward.respond_to? meth

        if block_given?
            num = @ongoing_engagements.size
            enter_extended_engagement meth, *args, inverted: false, block: self.class.get_source(block)
            yielder = self.next
            until @ongoing_engagements.size == num
                result = block[yielder]
                yielder = self.next result
            end
            yielder
        elsif @extended_engagements.include? meth
            enter_extended_engagement meth, *args, inverted: true
        else
            out = @ward.__send__ meth, *args, &block
            publicize name: meth, args: args, result: out
            out
        end
    end
end
