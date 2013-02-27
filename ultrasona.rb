#!/usr/bin/ruby

require 'rubygems' # this is a gem
require 'ruby-debug'
require 'benchmark'

# proper float rounding in 1.8.7 - http://www.ruby-forum.com/topic/201424
if Float.instance_method(:round).arity == 0
  class Float
    alias_method :_orig_round, :round
    def round( decimals=0 )
      factor = 10**decimals
      (self*factor)._orig_round / factor.to_f
    end
  end
end

time = Benchmark.realtime do
  file = ARGV[0]
  hits = []
  large_files = []

  File.open(file).each_line do |line|
    match = line.match(/^(\S+) (\S+) - - \[.*\] "\w+ (\/.*?) .*?" \d* (\d*)/)
    if match
      host = match[1].gsub("www.","")
      ip = match[2]
      file = match[3]
      bytes = match[4].to_i
      existing_hit = hits.detect { |hit| hit[:host] == host }
      if existing_hit
        existing_hit[:ips] << ip
        existing_hit[:ips].uniq!
        existing_hit[:bytes] += bytes.to_i
      else
        hits << { :host => host, :ips => [ip], :bytes => bytes }
      end
      mb = bytes.to_f / 1024.0 / 1024.0
      if (mb) >= 1
        path = "#{host}#{file}".ljust(100)
        large_files << "#{path} #{mb.round(2)} mb"
      end
    end
  end

  hits.sort! { |a,b| b[:ips].size <=> a[:ips].size }

  puts "#{'DOMAIN'.ljust(40)} #{'Uniques'.ljust(10)} MB\n\n"
  hits.each do |hit|
    mb = hit[:bytes].to_f / 1024.0 / 1024.0
    puts "#{hit[:host].ljust(40)} #{hit[:ips].size.to_s.ljust(10)} #{mb.round(2)} mb"
  end

  puts "LARGE FILES\n\n"
  large_files.uniq.sort.each { |lf| puts lf }

end

puts "\nTime elapsed #{time} seconds"
