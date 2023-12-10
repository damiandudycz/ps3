#!/usr/bin/env ruby

if ARGV.length < 2
  puts "Usage: apply-diffconfig DIFF ORIG_CONFIG"
  exit 1
end

begin
  diff = File.read ARGV[0]
  config = File.read ARGV[1]
rescue
  puts "Failed to read file"
  exit 1
end

diff = diff.split("\n")
config = config.split("\n")

for entry in diff do

  if entry.match(/^-/)
    cfg_option = entry.gsub("-", "CONFIG_").split(" ").first
    config.reject!{|x| x.match(cfg_option)}
    next
  end

  if entry.match(/^\+/)
    cfg_option = entry.gsub("+", "CONFIG_").gsub(" ", "=")
    config.push cfg_option
  end

  if entry.match(/^ /)
    cfg_array = entry.split(" ")
    cfg_option_name = "CONFIG_" + cfg_array.shift
    cfg_array = cfg_array.join(" ").split(" -> ")
    cfg_old_val = cfg_array.first
    cfg_new_val = cfg_array.last

    i = config.index config.select{|x|
      x.match cfg_option_name + "=" + cfg_old_val
    }.first

    if i
      config[i].gsub!(cfg_old_val, cfg_new_val)
    else
      config.push cfg_option_name + "=" + cfg_new_val
    end
  end

end

puts config.join("\n")
