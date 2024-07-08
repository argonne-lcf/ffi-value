[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }
require 'minitest/autorun'
require 'ffi-value'

module SmallPthread
  extend FFI::Library
  begin
    ffi_lib "pthread"
  rescue LoadError
    ffi_lib "libpthread.so.0"
  end
  callback :start_routine, [:value], :pointer
  attach_function :pthread_create, [:pointer, :pointer, :start_routine, :value], :int
  attach_function :pthread_join, [:ulong, :pointer], :int, blocking: true
  attach_function :pthread_create2, :pthread_create, [:pointer, :pointer, :start_routine, :pointer], :int
end

class TestFFIValue < Minitest::Test

  def test_value
    success = false
    val = { foo: 1, bar: "baz" }
    l = lambda { |v| success = (v == val); nil }

    ptid = FFI::MemoryPointer.new(:ulong)
    res = SmallPthread.pthread_create(ptid, nil, l, val)
    assert_equal(0, res)
    pret = FFI::MemoryPointer.new(:pointer)
    res = SmallPthread.pthread_join(ptid.read_ulong, pret)
    assert_equal(0, res)
    assert(success)
    assert(pret.read_pointer.null?)
  end

  def test_volatile_value
    success = false
    l = lambda { |v| success = (v == { foo: 1, bar: "baz" }); FFI.dec_ref(v); nil }
    val = { foo: 1, bar: "baz" }
    FFI.inc_ref(val)
    val = val.object_id
    GC.start

    ptid = FFI::MemoryPointer.new(:ulong)
    res = SmallPthread.pthread_create2(ptid, nil, l, FFI::Pointer.new(val))
    assert_equal(0, res)
    pret = FFI::MemoryPointer.new(:pointer)
    res = SmallPthread.pthread_join(ptid.read_ulong, pret)
    assert_equal(0, res)
    assert(success)
    assert(pret.read_pointer.null?)
    GC.start
    assert_raises(RangeError, "\"#{val}\" is recycled object") { ObjectSpace._id2ref(val) }
  end

  def test_ref_count
    obj = "foo"
    assert_raises(ArgumentError, "Object: #{obj.object_id} was not previously referenced!") { FFI.dec_ref(obj) }
    assert_equal(1, FFI.inc_ref(obj))
    assert_equal(2, FFI.inc_ref(obj))
    assert_equal(1, FFI.dec_ref(obj))
    assert_equal(2, FFI.inc_ref(obj))
    assert_equal(1, FFI.dec_ref(obj))
    assert_equal(0, FFI.dec_ref(obj))
    assert_raises(ArgumentError, "Object: #{obj.object_id} was not previously referenced!") { FFI.dec_ref(obj) }
  end

  def test_memory
    vals = [ :foo, 15, nil ]
    mem = FFI::MemoryPointer.new(:value, vals.size)
    mem.put_value(0, :foo)
    assert_equal(:foo, mem.read_value)
    mem.write_value(:bar)
    assert_equal(:bar, mem.get_value(0))
    mem.put_array_of_value(0, vals)
    assert_equal(vals, mem.read_array_of_value(vals.size))
    mem.write_array_of_value(vals.reverse)
    assert_equal(vals.reverse, mem.get_array_of_value(0, vals.size))
  end
  
end
