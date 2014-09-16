
#encoding: utf-8

# <?xml version="1.0" standalone="yes"?>
# <item>
# <station>
# <title>105.5 Rock FM</title>
# <streamURL>http://radio.onweb.gr:8078/</streamURL>
# <siteURL>http://www.1055rock.gr</siteURL>
# <genre>Rock</genre>
# <location>Θεσσαλονίκη</location>
# </station>
# </item>


puts "<?xml version=\"1.0\" standalone=\"yes\"?>"
puts "<item>"

ratio = 0

File.foreach(ARGV[0]).with_index { |line, line_num|

  if line != "\n"
          
      if ratio == 0
        puts "<station>"
        puts "<title>#{line.chomp}</title>"
      elsif ratio == 1
        puts "<streamURL>#{line.chomp}</streamURL>"
      elsif ratio == 2
        puts "<siteURL>#{line.chomp}</siteURL>"
      elsif ratio == 3
        puts "<genre>#{line.chomp}</genre>"
      elsif ratio == 4
        puts "<location>#{line.chomp}</location>"
        puts "</station>"      
      end
      
      ratio += 1
      
      if ratio == 5
        ratio = 0
      end
      
  end
}

puts "</item>"
