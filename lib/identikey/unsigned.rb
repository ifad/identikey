#
# Wrapper for an integer immediate value, that is used only as an annotation
# for typed_attributes_list_from() in order to generate the correct XSD type
# from an Object's class.
#
class Unsigned < BasicObject
  def initialize(value)
    @int = ::Kernel::Integer(value)

    if @int < 0
      raise ArgumentError, "Invalid input syntax for Unsigned integer: #{value}"
    end
  end

  def class
    ::Unsigned
  end

  def method_missing(meth, *args, &block)
    @int.public_send(meth, *args, &block)
  end
end

module Kernel
  def Unsigned(value)
    ::Unsigned.new(value)
  end
end
