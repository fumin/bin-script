#!/usr/bin/env ruby

require 'ripper'

# Inputs:
#   klass: an array of symbols returned by `Ripper.sexp` representing a class
#   file_text: the raw text of the entire source code
#
# Output: an array of objects, each including
#   * the start and end line number of the test case
#   * the name of the test case
def tests klass, file_text
  bodystmt = klass.find{|a| a.is_a?(Array) && a[0] == :bodystmt}[1]
  bodystmt.map{ |a|
    # We support two test case syntaxes:
    #   "def test_some_method", used by Test::Unit
    #   "test 'some method'", used by Rails
    name, position = if a[0] == :def && a[1][1] =~ /^test_/
        [a[1][1], a[1][2]]
      elsif a[0] == :method_add_block &&
        a[1][1][1] == "test"
        e = a[1][2][1][0][1][1]
        ["test_" + e[1].split.join("_"), e[2]]
      end
    next unless name && position

    # Find the ending line of this test case.
    #
    # The approach we use below takes advantage of the fact that
    # `Ripper.sexp` returns a non-nil value only
    # when the input text is of valid ruby syntax.
    end_line = position[0]
    while true do
      subtext = file_text.split("\n")[(position[0]-1)...end_line].join("\n")
      break if Ripper.sexp(subtext)
      end_line += 1
    end
    [[position[0], end_line], name]
  }.compact
end

# Find the first test class in this ripped result via depth first search.
def test_class ripped
  ripped.each{ |a|
    next unless a.is_a?(Array)
    return a if a[0] == :class

    klass = test_class(a)
    return klass if klass
  }
  nil
end

filename = ARGV[0]
text = File.read(filename)
ripped = Ripper.sexp(text)

klass = test_class ripped
testcases = tests(klass, text)

testcases.each{ |t|
  puts "#{t[0][0]} #{t[0][1]} #{t[1]}"
}
