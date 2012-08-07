#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'

# Produce the output filename
def generateOutputPath

  # Retrieve the current date/time of the local machine.
  currentTime = Time.new

  '%s/%s/%s-%d-%d-%d.mobi' % [
    ENV['HOME'],
    "Dropbox/Public/mobi",
    "instapaper",
    currentTime.year,
    currentTime.month,
    currentTime.day,
    "mobi"
  ]

end

# Check that the correct number of arguments are present.
def validateArgs
  unless ARGV.length == 2
    puts "Incorrect number of arguments supplied."
    puts "Usage: ruby instamobi.rb <username> <password>\n"
    exit
  end
end

# Do some basic validation on the arguments.
validateArgs

username = ARGV[0]
password = ARGV[1]
output_dir = generateOutputPath

agent = Mechanize.new

# Allows you to download the file without loading it into
# memory. Should you prefer to load the file into memory
# first, you could use something like:
# 	agent.get('...').save_as '...'
agent.pluggable_parser.default = Mechanize::Download

# Retrieve the login page
puts "Retrieving login page ..."
page = agent.get('http://www.instapaper.com/user/login')

# Submit the login form
form = page.form_with(:action => '/user/login')

# Debug: this line of code will output the form's contents. This allows you to figure out the
#        correct field names to fill, such as 'username' and 'password' below. These could
#        just as easily be something like 'un' and 'pwd' in which case you would use 'form.un'.
# pp form

# Populate form
puts "Populating login form ..."
form.username = username
form.password = password

# Submit form and handle redirect
puts "Submitting login ..."
page = agent.submit(form)
redirect = page.link_with(:text => 'Click here if you aren\'t redirected')

# Check that a redirect link is present. Otherwise, login probably failed.
if redirect == nil
  puts "No post-login redirect link could be found."
  puts "Looks like login failed. Exiting."
  exit
end

page = redirect.click
puts "Login looks to have been successful!"

# Debug: this line of code will output the URI of the current page. Handy in figuring out the
#        use of relative URIs and things like that.
# puts agent.page.uri.to_s

# Count the number of unread items. If none exist, exit the app without getting an empty
# mobi.
puts "Checking for unread links ..."

count = page.links_with(:dom_class => "tableViewCellTitleLink").count

if count == 0
  puts "Looks like no unread items exist. Exiting."
  exit
end

puts "Unread Item(s): %d" % [count]

# Save the generated .mobi file to file.
# It's worth noting that the .save() method is clever enough to append digits to the file name
# if a file with the current name already exists. The advantage of this, at least from a test
# perspective, is the files won't be overridden.
puts "Retrieving all Kindle compilation of all unread items ..."
agent.get(agent.page.uri.to_s + '/mobi').save(output_dir)
puts "Kindle compilation saved to %s" % [output_dir]

# Having downloaded the file successfully, the next step is to archive all current unread items.
puts "Archiving all unread items."
form = page.form_with(:action => "/bulk-archive")
agent.submit(form)
puts "Job done. Exiting."
