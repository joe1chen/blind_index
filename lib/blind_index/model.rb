module BlindIndex
  module Model
    def blind_index(name, key: nil, iterations: nil, attribute: nil, expression: nil, bidx_attribute: nil, callback: true)
      iterations ||= 10000
      attribute ||= name
      bidx_attribute ||= :"encrypted_#{name}_bidx"

      name = name.to_sym
      attribute = attribute.to_sym
      method_name = :"compute_#{name}_bidx"

      class_eval do
        class << self
          def blind_indexes
            @blind_indexes ||= {}
          end unless method_defined?(:blind_indexes)
        end

        raise BlindIndex::Error, "Duplicate blind index: #{name}" if blind_indexes[name]

        blind_indexes[name] = {
          key: key,
          iterations: iterations,
          attribute: attribute,
          expression: expression,
          bidx_attribute: bidx_attribute
        }

        define_method method_name do
          self.send("#{bidx_attribute}=", BlindIndex.generate_bidx(send(attribute), self.class.blind_indexes[name]))
        end

        if callback
          before_validation method_name, if: -> { changes.key?(attribute.to_s) }
        end

        # use include so user can override
        include InstanceMethods if blind_indexes.size == 1
      end
    end
  end

  module InstanceMethods
    def read_attribute_for_validation(key)
      if (bi = self.class.blind_indexes[key])
        send(bi[:attribute])
      else
        super
      end
    end
  end
end
