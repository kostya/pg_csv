PgCsv
=====

Fast Ruby PG csv export. Uses pg function 'copy to csv'. Effective on millions rows.

Gemfile:
``` ruby
gem 'pg_csv'
```

Usage:
``` ruby
PgCsv.new(opts).export(to, opts)
```

'to' is a stream or filename

Options:
``` ruby
:sql         => plain sql ("select id, name from users")
:connection  => ActiveRecord::Base.connection or PG::Connection(gem pg)
:delimiter   => ["\t", ",", ]
:header      => boolean, use pg header for fields?
:logger      => logger
:columns     => array of column names, ignore :header option
:encoding    => encoding (default is pg_default), list of encodings: http://www.postgresql.org/docs/8.4/static/multibyte.html#CHARSET-TABLE
:force_quote => boolean, force quotes around all non-NULL data?

:temp_file   => boolean, generate throught temp file? final file appears by mv
:temp_dir    => for :temp_file, ex: '/tmp'

:type        => :plain - return full string
             => :gzip  - save file to gzip
             => :stream - save to stream
             => :file - just save to file = default
             => :yield - return each row to block
```

Examples:
``` ruby
PgCsv.new(sql: sql).export('a1.csv')
PgCsv.new(sql: sql).export('a2.gz', type: :gzip)
PgCsv.new(sql: sql).export('a3.csv', temp_file: true)
PgCsv.new(sql: sql, type: :plain).export
File.open("a4.csv", 'a'){ |f| PgCsv.new(sql: "select * from users").\
    export(f, type: :stream) }
PgCsv.new(sql: sql).export('a5.csv', delimiter: "\t")
PgCsv.new(sql: sql).export('a6.csv', header: true)
PgCsv.new(sql: sql).export('a7.csv', columns: %w(id a b c))
PgCsv.new(sql: sql, connection: SomeDb.connection, columns: %w(id a b c), delimiter: "|").\
    export('a8.gz', type: :gzip, temp_file: true)

# example collect from shards
Zlib::GzipWriter.open('some.gz') do |stream|
  e = PgCsv.new(sql: sql, type: :stream)
  ConnectionPool.each_shard do |connection|
    e.export(stream, connection: connection)
  end
end

# yield example
PgCsv.new(sql: sql, type: :yield).export do |row|
  puts row
end
```
