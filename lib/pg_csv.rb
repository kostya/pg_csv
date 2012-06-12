require 'active_record'

class PgCsv

  # opts:
  #   :sql        => "select u.*, p.* from users u, projects p where p.user_id = u.id order by email limit 100"
  #   :connection => AR.connection
  #   :delimiter  => ["\t", ",", ]
  #   :header     => boolean, use pg header for fields?
  #   :logger     => logger
  #   :columns    => manual array of column names, ignore :header option

  #   :temp_file  => boolean, generating throught temp file, final file appears by mv
  #   :temp_dir   => path, ex: /tmp
  
  #   :type       => :plain - return full string
  #               => :gzip  - save file to gzip
  #               => :stream - save to stream
  #               => :file - just save to file * default
  
  def initialize(opts = {})
    @options = opts.symbolize_keys
  end
  
  # do export :to - filename or stream  
  def export(to, opts = {}, &block)
    @block = block
    @local_options = opts.symbolize_keys
    
    raise ":connection should be" unless connection
    raise ":sql should be" unless sql

    with_temp_file(to, temp_file, temp_dir) do |_to|
      export_to(_to)
    end        
  end
  
protected

  def with_temp_file(to, use_temp_file, tmp_dir)
    if use_temp_file
      check_str(to)
      
      require 'fileutils'
      require 'tempfile'
                    
      tempfile = Tempfile.new("pg_csv", tmp_dir)
      yield(tempfile.path)
      FileUtils.mv(tempfile.path, to)
      info "<=== moving export to #{to}"
    else
      yield(to)
    end
  end                                                            

  def export_to(to)
  
    start = Time.now
    info "===> start generate export #{to}, type: #{type}"
    
    result = nil

    case type
    
      when :file
        check_str(to)
        File.open(to, 'w', &exporter)
        
      when :gzip
        check_str(to)
        Zlib::GzipWriter.open(to, &exporter)
        
      when :stream
        exporter[to]
        
      when :plain
        require 'stringio'
        sio = StringIO.new
        exporter[sio]
        result = sio.string
        
      when :yield
        # not real saving anywhere, just yield each record
        raise "block should be" unless @block
        load_data do |row|
          @block.call(row)
        end                
    end
    
    info "<=== finished write #{to} in #{Time.now - start}"
    
    result
  end
  
  def check_str(to)
    raise "'to' should be an string" unless to.is_a?(String)
  end
  
  def exporter
    method(:export_to_stream).to_proc
  end
  
  def export_to_stream(stream)
    count = write_csv(stream)
    stream.flush if stream.respond_to?(:flush)
    
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
    yield(prepare_row(columns_str)) if columns_str

    count = 0    
    while row = raw.get_copy_data()
      yield prepare_row(row)
      count += 1
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
#{use_pg_header? ? 'HEADER' : ''}
    SQL
  end

  def prepare_row(row)
    row
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
  
end