# strips.rb

require 'fileutils'
require 'date'

module ArchivesHelper

  Image = Struct.new(:url, :filename)

  def archives
    # find all the images in the current directory
    strips = @pages.find(:all, :in_directory => 'images/strips').reject {|s| s =~ /^\./}

    strips.map! do |resource|
      # store all this information in a struct object
      ::ArchivesHelper::Image.new(resource.url, resource.filename)
    end

    # sort all the images based on their creation date/time
    strips.sort! {|a,b| a.filename <=> b.filename}

    # generate the HTML that will be inserted into the page
    html = '<ol>'
    strips.each do |strip|
      html << %Q(<li>)
      html << %Q(<a href="#{strip.url}">)
      html << %Q(#{strip.filename}\n)
      html << %Q(</a>\n)
      html << %Q(</li>\n)
    end
    html << '</ol>'
  end
end  # module StripsHelper

Webby::Helpers.register(ArchivesHelper)
