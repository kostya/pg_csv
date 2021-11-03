# encoding: utf-8

require File.dirname(__FILE__) + '/spec_helper'

describe PgCsv do

  before :each do
    Test.delete_all
    Test.create a: 1, b: 2, c: 3
    Test.create a: 4, b: 5, c: 6

    @name = tmp_dir + "1.csv"
    FileUtils.rm(@name) rescue nil

    @sql0 = "select a,b,c from tests order by a asc"
    @sql = "select a,b,c from tests order by a desc"
  end

  after :each do
    FileUtils.rm(@name) rescue nil
  end

  describe "simple export" do

    it "1" do
      PgCsv.new(sql: @sql0).export(@name)
      with_file(@name){ |d| expect(d).to eq("1,2,3\n4,5,6\n")}
    end

    it "2" do
      PgCsv.new(sql: @sql).export(@name)
      with_file(@name){ |d| expect(d).to eq("4,5,6\n1,2,3\n") }
    end

    it "delimiter" do
      PgCsv.new(sql: @sql).export(@name, delimiter: "|")
      with_file(@name){ |d| expect(d).to eq("4|5|6\n1|2|3\n") }
    end

    it "encoding" do
      Test.create!(a: 2, b: 3, c: 4, d: "абсд")

      PgCsv.new(sql: "select d from tests where a = 2").export(@name, encoding: "WIN1251")
      with_file(@name){ |d| expect(d.force_encoding('cp1251')).to eq("абсд\n".encode('cp1251')) }
    end

    describe "headers" do
      it "header" do
        PgCsv.new(sql: @sql).export(@name, header: true)
        with_file(@name){ |d| expect(d).to eq("a,b,c\n4,5,6\n1,2,3\n") }
      end

      it "columns" do
        PgCsv.new(sql: @sql).export(@name, columns: %w(q w e))
        with_file(@name){ |d| expect(d).to eq("q,w,e\n4,5,6\n1,2,3\n") }
      end

      it "columns with header" do
        PgCsv.new(sql: @sql).export(@name, header: true, columns: %w(q w e))

        with_file(@name) do |d|
          expect(d).to eq("q,w,e\n4,5,6\n1,2,3\n")
        end
      end
    end

    describe "force_quote" do
      it "force_quote" do
        PgCsv.new(sql: @sql).export(@name, force_quote: true)
        with_file(@name){ |d| expect(d).to eq("\"4\",\"5\",\"6\"\n\"1\",\"2\",\"3\"\n") }
      end

      it "with headers" do
        PgCsv.new(sql: @sql).export(@name, header: true, force_quote: true)
        with_file(@name){ |d| expect(d).to eq("a,b,c\n\"4\",\"5\",\"6\"\n\"1\",\"2\",\"3\"\n") }
      end
    end
  end

  describe "moving options no matter" do
    it "1" do
      PgCsv.new(sql: @sql).export(@name, delimiter: "|")
      with_file(@name){ |d| expect(d).to eq("4|5|6\n1|2|3\n") }
    end

    it "2" do
      PgCsv.new(delimiter: "|").export(@name, sql: @sql)
      with_file(@name){ |d| expect(d).to eq("4|5|6\n1|2|3\n") }
    end
  end

  describe "local options dont recover global" do
    it "test" do
      e = PgCsv.new(sql: @sql, delimiter: "*")
      e.export(@name, delimiter: "|")
      with_file(@name){ |d| expect(d).to eq("4|5|6\n1|2|3\n") }

      e.export(@name)
      with_file(@name){ |d| expect(d).to eq("4*5*6\n1*2*3\n") }
    end
  end

  describe "using temp file" do
    it "at least file should return to target and set correct chmod" do
      expect(File).not_to exist(@name)
      PgCsv.new(sql: @sql, temp_file: true, temp_dir: tmp_dir).export(@name)
      with_file(@name){ |d| expect(d).to eq("4,5,6\n1,2,3\n") }
      expect(sprintf("%o", File.stat(@name).mode).to_i).to eq(100644)
    end

    it "same with gzip" do
      expect(File).not_to exist(@name)
      PgCsv.new(sql: @sql, temp_file: true, temp_dir: tmp_dir, type: :gzip).export(@name)
      with_gzfile(@name){ |d| expect(d).to eq("4,5,6\n1,2,3\n") }
      expect(sprintf("%o", File.stat(@name).mode).to_i).to eq(100644)
    end
  end

  describe "different types of export" do
    it "gzip export" do
      expect(File).not_to exist(@name)
      PgCsv.new(sql: @sql, type: :gzip).export(@name)
      with_gzfile(@name){ |d| expect(d).to eq("4,5,6\n1,2,3\n") }
      expect(sprintf("%o", File.stat(@name).mode).to_i).to eq(100644)
    end

    it "plain export" do
      expect(PgCsv.new(sql: @sql, type: :plain).export).to eq("4,5,6\n1,2,3\n")
    end

    it "custom stream" do
      ex = PgCsv.new(sql: @sql, type: :stream)
      File.open(@name, 'w') do |stream|
        ex.export(stream)
        ex.export(stream, sql: @sql0)
      end

      with_file(@name){ |d| expect(d).to eq("4,5,6\n1,2,3\n1,2,3\n4,5,6\n") }
    end

    it "file as default" do
      PgCsv.new(sql: @sql, type: :file).export(@name)
      with_file(@name){ |d| expect(d).to eq("4,5,6\n1,2,3\n") }
      expect(sprintf("%o", File.stat(@name).mode).to_i).to eq(100644)
    end

    it "yield export" do
      rows = []
      expect(
        PgCsv.new(sql: @sql, type: :yield).export { |row| rows << row }
      ).to eq(2)

      expect(rows).to eq(["4,5,6\n", "1,2,3\n"])
    end
  end

  describe "integration specs" do
    it "1" do
      expect(File).not_to exist(@name)
      PgCsv.new(sql: @sql, type: :gzip).export(
        @name, delimiter: "|", columns: %w(q w e), temp_file: true, temp_dir: tmp_dir
      )
      with_gzfile(@name){ |d| expect(d).to eq("q|w|e\n4|5|6\n1|2|3\n") }
    end

    it "2" do
      Zlib::GzipWriter.open(@name) do |gz|
        e = PgCsv.new(sql: @sql, type: :stream)

        e.export(gz, delimiter: "|", columns: %w(q w e) )
        e.export(gz, delimiter: "*", sql: @sql0)
      end

      with_gzfile(@name){ |d| expect(d).to eq("q|w|e\n4|5|6\n1|2|3\n1*2*3\n4*5*6\n") }
    end

    it "gzip with empty content" do
      expect(File).not_to exist(@name)
      PgCsv.new(sql: "select a,b,c from tests where a = -1", type: :gzip).export(
        @name, temp_file: true, temp_dir: tmp_dir
      )
      with_gzfile(@name){ |d| expect(d).to be_empty }
    end
  end

  it "custom row proc" do
    e = PgCsv.new(sql: @sql)

    e.export(@name) do |row|
      row.split(",").join("-|-")
    end

    with_file(@name){ |d| expect(d).to eq("4-|-5-|-6\n1-|-2-|-3\n") }
  end
end
