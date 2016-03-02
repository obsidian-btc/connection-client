class Connection
  class Client
    module ReconnectPolicy
      module Defaults
        module Name
          def self.get
            :never
          end
        end
      end
    end
  end
end
