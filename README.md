PgCsv
=====

Fast AR/PostgreSQL csv export. Uses pg function 'copy to csv'. Effective on millions rows.

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
  :sql        => "select p.* from users u, projects p where p.user_id = u.id order by email limit 10"
  :connection => AR.connection
  :delimiter  => ["\t", ",", ]
  :header     => boolean, use pg header for fields?
  :logger     => logger
  :columns    => manual array of column names, ignore :header option

  :temp_file  => boolean, generate throught temp file, final file appears by mv
  :temp_dir   => for :temp_file, ex: '/tmp'

  :type       => :plain - return full string
              => :gzip  - save file to gzip
              => :stream - save to stream
              => :file - just save to file = default
```

Examples:
``` ruby
  PgCsv.new(:sql => User.good.to_sql).export('a1.csv')
  PgCsv.new(:sql => sql).export('a2.gz', :type => :gzip)
  PgCsv.new(:sql => sql).export('a3.csv', :temp_file => true)
  PgCsv.new(:sql => sql).export(nil, :type => :plain)
  File.open("a4.csv", 'a'){|f| FastPgCsv.new(:sql => "select * from users").\
      export(f, :type => :stream) }
  PgCsv.new(:sql => sql).export('a5.csv', :delimiter => "\t")
  PgCsv.new(:sql => sql).export('a6.csv', :header => true)
  PgCsv.new(:sql => sql).export('a7.csv', :columns => %w{id a b c})
  PgCsv.new(:sql => sql, :connection => SomeDb.connection, :columns => %w{id a b c}, :delimiter => "|").\
      export('a8.gz', :type => :gzip, :temp_file => true)

  # example collect from shards
  Zlib::GzipWriter.open('some.gz') do |stream|
    e = PgCsv.new(:sql => sql, :type => :stream)
    ConnectionPool.each_shard do |connection|
      e.export(stream, :connection => connection)
    end
  end
```
