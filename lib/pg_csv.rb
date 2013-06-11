require 'active_record'

class PgCsv

  module Base

    def initialize(opts = {})
      @options = opts.symbolize_keys
    end
    
    # do export :to - filename or stream  
    def export(to = nil, opts = {}, &row_proc)
      @row_proc = row_proc
      @local_options = opts.symbolize_keys

      raise ":connection should be" unless connection
      raise ":sql should be" unless sql

      with_temp_file?(to, temp_file, temp_dir) do |dest|
        export_to(dest)
      end        
    end
    
  protected

    def with_temp_file?(to, use_temp_file, tmp_dir)
      if use_temp_file && [:file, :gzip].include?(type)
        check_str(to)

        self.class.with_temp_file(to, tmp_dir) do |filename|
          yield(filename)
        end
        
        info "<=== moving export to #{to}"
      else
        yield(to)
      end
    end                                                            

    def export_to(to)
    
      start = Time.now
      info "===> start generate export #{to}, type: #{type}"
      
      result = nil
      exporter = method(:export_to_stream).to_proc

      case type
      
        when :file
          check_str(to)
          File.open(to, 'w', &exporter)
          
        when :gzip
          check_str(to)
          require 'zlib'
          ::Zlib::GzipWriter.open(to, &exporter)
          
        when :stream
          raise "'to' should be" unless to
          exporter[to]
          
        when :plain
          require 'stringio'
          sio = StringIO.new
          exporter[sio]
          result = sio.string
          
        when :yield
          # not real saving anywhere, just yield each record
          raise "row_proc should be" unless @row_proc
          result = load_data{|_|}
      end
      
      info "<=== finished write #{to} in #{Time.now - start}"
      
      result
    end
    
    def check_str(to)
      raise "'to' should be an string" unless to.is_a?(String)
    end
    
    def export_to_stream(stream)
      count = write_csv(stream)
      stream.flush if stream.respond_to?(:flush) && count > 0
      
      info "<= done exporting (#{count}) records."
    end

    def write_csv(stream)
      load_data do |row|
        stream.write(row)
      end
    end
    
    def load_data
      info "#{query}"
      raw = connection.raw_connection
      
      info "=> query"
      q = raw.exec(query)
      info "<= query"

      info "=> write data"
      if columns_str
        yield(@row_proc ? @row_proc[columns_str] : columns_str)
      end

      count = 0    
      if @row_proc
        while row = raw.get_copy_data()
          yield(@row_proc[row])
          count += 1
        end
      else
        while row = raw.get_copy_data()
          yield(row)
          count += 1
        end
      end
      info "<= write data"

      q.clear
      count
    end

    def query
      <<-SQL
  COPY (
    #{sql}
  ) TO STDOUT
  WITH CSV
  DELIMITER '#{delimiter}'
  #{use_pg_header? ? 'HEADER' : ''} #{encoding ? "ENCODING '#{encoding}'" : ''}
      SQL
    end

    def info(message)
      logger.info(message) if logger
    end
    
    # ==== options/defaults =============
    
    def o(key)
      @local_options[key] || @options[key]
    end

    def connection
      o(:connection) || (defined?(ActiveRecord::Base) ? ActiveRecord::Base.connection : nil)
    end
    
    def logger
      o(:logger)
    end

    def type
      o(:type) || :file
    end

    def use_pg_header?
      o(:header) && !o(:columns)
    end

    def columns_str
      if o(:columns)
        col = o(:columns)
        if col.is_a?(Array)
          col.join(delimiter) + "\n"
        else
          col + "\n"
        end
      end
    end

    def delimiter
      o(:delimiter) || ','
    end
    
    def sql
      o(:sql)
    end
    
    def temp_file
      o(:temp_file)
    end
    
    def temp_dir
      o(:temp_dir) || '/tmp'
    end
    
    def encoding
      o(:encoding)
    end
  end

  include Base

  def self.with_temp_file(dest, tmp_dir = '/tmp', &block)
    require 'fileutils'

    filename = File.join(tmp_dir, "pg_csv_#{Time.now.to_f}_#{rand(1000000)}")
    block[filename]

    FileUtils.mv(filename, dest)
  end

end
