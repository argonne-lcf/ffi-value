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
