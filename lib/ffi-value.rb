require 'ffi'

module FFI
  ValueStore = Hash.new { |h, k| h[k.object_id] = [k, 0] }
  ValueStoreMutex = Mutex.new

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

  if TypeDefs.frozen?
    t = TypeDefs.dup
    remove_const(:TypeDefs)
    const_set(:TypeDefs, t)
    typedef m, :value
    TypeDefs.freeze
  else
    typedef m, :value
  end

  def self.inc_ref(object)
    refcount = nil
    ValueStoreMutex.synchronize {
      _, refcount = ValueStore[object.object_id]
      refcount += 1
      ValueStore[object.object_id] = [object, refcount]
    }
    refcount
  end

  def self.dec_ref(object)
    refcount = nil
    ValueStoreMutex.synchronize {
      _, refcount = ValueStore[object.object_id]
      refcount -= 1
      if (refcount <= 0) then
        ValueStore.delete(object.object_id)
      else
        ValueStore[object.object_id] = [object, refcount]
      end
    }
    if refcount < 0
      raise ArgumentError.new("Object: #{object.object_id} was not previously referenced!")
    end
    refcount
  end

  class AbstractMemory
    if FFI::Type::POINTER.size == 8
      def put_value(offset, value)
        put_uint64(offset, value.object_id)
      end
      def write_value(value)
        write_uint64(value.object_id)
      end
      def put_array_of_value(offset, ary)
        put_array_of_uint64(offset, ary.collect(&:object_id))
      end
      def write_array_of_value(ary)
        write_array_of_uint64(ary.collect(&:object_id))
      end
      def get_value(offset)
        ObjectSpace._id2ref(get_uint64(offset))
      end
      def read_value
        ObjectSpace._id2ref(read_uint64)
      end
      def get_array_of_value(offset, length)
        get_array_of_uint64(offset, length).collect { |v| ObjectSpace._id2ref(v) }
      end
      def read_array_of_value(length)
        read_array_of_uint64(length).collect { |v| ObjectSpace._id2ref(v) }
      end
    else
      def put_value(offset, value)
        put_uint32(offset, value.object_id)
      end
      def write_value(value)
        write_uint32(value.object_id)
      end
      def put_array_of_value(offset, ary)
        put_array_of_uint32(offset, ary.collect(&:object_id))
      end
      def write_array_of_value(ary)
        write_array_of_uint32(ary.collect(&:object_id))
      end
      def get_value(offset)
        ObjectSpace._id2ref(get_uint32(offset))
      end
      def read_value
        ObjectSpace._id2ref(read_uint32)
      end
      def get_array_of_value(offset, length)
        get_array_of_uint32(offset, length).collect { |v| ObjectSpace._id2ref(v) }
      end
      def read_array_of_value(length)
        read_array_of_uint32(length).collect { |v| ObjectSpace._id2ref(v) }
      end
    end
  end
end
