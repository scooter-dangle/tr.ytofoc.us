class Publicist
    attr_reader :broadcaster
    def initialize
        @clientele = {}
    end

    def add client
        @clientele[client.stage_name] = package client
    end

    def broadcaster=(broad)
        @broadcaster = broad.register_channel
    end

    def remove client
        @clientele.delete client.stage_name
    end

    def prep client, hash
        out = package client
        out[:methods].push hash unless hash.empty?
        @clientele[client.stage_name] = out
        out
    end

    def package client
        meths = client.ongoing_engagements.map do |x|
            x.select { |k| [:name, :args, :block, :yield, :result].include? k }
        end

        {
            name:       client.stage_name,
            obj:        client.ward,
            methods:    meths
        }
    end

    def publicize client, meth_hash
        prep client, meth_hash
        @broadcaster.broadcast(
            label: 'update',
            parcel: @clientele.values
        ) if @broadcaster
    end
    alias_method :publicise, :publicize
end
