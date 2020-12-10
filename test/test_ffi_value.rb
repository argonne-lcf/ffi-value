[ '../lib', 'lib' ].each { |d| $:.unshift(d) if File::directory?(d) }
require 'minitest/autorun'
require 'ffi-value'

module SmallPthread
  extend FFI::Library
  ffi_lib "pthread"

  callback :start_routine, [:value], :pointer
  attach_function :pthread_create, [:pointer, :pointer, :start_routine, :value], :int
  attach_function :pthread_join, [:ulong, :pointer], :int, blocking: true
end

class TestFFIValue < Minitest::Test

  def test_value
    $val = { foo: 1, bar: "baz" }
    l = lambda { |v| assert_equal(v, $val); nil }

    ptid = FFI::MemoryPointer.new(:ulong)
    res = SmallPthread.pthread_create(ptid, nil, l, $val)
    assert_equal(0, res)
    pret = FFI::MemoryPointer.new(:pointer)
    res = SmallPthread.pthread_join(ptid.read_ulong, pret)
    assert_equal(0, res)
    assert(pret.read_pointer.null?)
  end
  
end
