require 'rubygems'
require "bundler"
Bundler.setup

$:.unshift(File.dirname(__FILE__) + '/../../lib')
require 'pg_csv'
require 'benchmark'
require 'fileutils'

N = 50000
T = 10

class Raw
  def initialize
    @c = 0
  end

  def exec(x)
    q = ""
    def q.clear
    end
    q
  end

  def get_copy_data()
    @c += 1
    if @c < N
      "#{@c},#{@c*2},#{@c * 249},#{rand(100)},#{rand(@c)},blablabla,hahah,ahah,ahaha,ahahah,ah,1.55234143\n"
    end
  end
end

class Con
  def raw_connection
    @raw ||= Raw.new
  end
end


$con = Con.new

class PgCsv

  module FixConnection
    def connection
      @con ||= Con.new
    end

    def sql
      ""
    end
  end

  include FixConnection

end

class Stre
  def write(str)
  end
end

$stream = Stre.new


tm = Benchmark.realtime{ T.times{ PgCsv.new(:type => :plain).export } }
puts "export plain #{tm}"

tm = Benchmark.realtime{ T.times{ PgCsv.new(:type => :stream).export($stream) }}
puts "export stream #{tm}"

tm = Benchmark.realtime{ T.times{ PgCsv.new(:type => :yield).export{|row| row } }}
puts "export yield #{tm}"

=begin
ree:
export plain 5.67214202880859
export stream 5.46862411499023
export yield 5.83969807624817

1.9.3
export plain 6.976197355
export stream 5.685256024
export yield 5.960436236

=end
