require 'ffi'

module FFI
  m = Module.new do
    extend FFI::DataConverter
    if FFI::Type::POINTER.size == 8
      def self.native_type
        FFI::Type::UINT64
      end
    else
      def self.native_type
        FFI::Type::UINT32
      end
    end

    def self.from_native(value, context)
      ObjectSpace._id2ref(value)
    end

    def self.to_native(value, context)
      value.object_id
    end
  end

  typedef m, :value
end
