require 'fileutils'

conn = {'adapter' => 'postgresql', 'database' => 'pgcsv_test', :encoding => "unicode"}
ActiveRecord::Base.establish_connection conn

class Test < ActiveRecord::Base
  self.table_name = 'tests'
end

def pg_create_schema
  ActiveRecord::Migration.create_table :tests do |t|
    t.integer :a
    t.integer :b
    t.integer :c
    t.string  :d
  end
end

def pg_drop_data
  ActiveRecord::Migration.drop_table :tests
end

pg_drop_data rescue nil
pg_create_schema

def tmp_dir
  File.dirname(__FILE__) + "/tmp/"
end

def with_file(name)
  File.exists?(name).should be_true
  q = 1
  File.open(name) do |file|
    data = file.read
    yield data
    q = 2
  end
  
  q.should == 2
end

def with_gzfile(name)
  File.exist?(name).should be_true
  q = 1
  Zlib::GzipReader.open(name) do |gz|
    data = gz.read
    yield data
    q = 2
  end
  q.should == 2
end
