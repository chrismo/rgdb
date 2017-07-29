# TODO: go back and research the facter 2.4.6 exception - see error.txt
# TODO: continue from where last run left off?

Bundler.require
require 'bundler/inline'
require 'logger'

most_popular_sql = <<-S
  select rg.name, v.number, gd.count 
  from rubygems rg join gem_downloads gd 
    on gd.rubygem_id=rg.id join versions v 
    on gd.version_id=v.id 
  order by gd.count desc 
  limit 1000
S

most_recent_sql = <<-S
  select rg.name, v.number, gd.count 
  from rubygems rg join gem_downloads gd 
    on gd.rubygem_id=rg.id join versions v 
    on gd.version_id=v.id 
  order by v.created_at desc 
  limit 1000
S
# 825353 total

@log = Logger.new('logfile.log')

def log_puts(msg, level=:info)
  puts msg
  @log.send(level, msg)
end

conn = PG.connect(dbname: 'rubygems')
# p conn.exec(sql) {|res| p res.each_row.to_a.length}; exit
log_puts "STARTING: #{start = Time.now}"
conn.exec(most_recent_sql) do |result|
  result.each_row do |row|
    name = row[0]
    version = row[1]
    # name = 'faraday_middleware'; version = '0.11.0'
    log_puts "Installing #{name}, #{version}"
    begin
      gemfile(true) do
        source 'https://rubygems.org'
        gem name, version
      end
    rescue Bundler::SecurityError => e
      log_puts e.message, :error
    rescue StandardError => e
      # TODO: is this an inline error in 1.14?
      p e.message
    end
  end
end
log_puts "FINISHING: #{Time.now}. Seconds elapsed: #{Time.now - start}"

