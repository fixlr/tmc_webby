require 'fileutils'
require 'date'
require 'ostruct'

module ArchivesHelper
  
  ARCHIVES_ROOT = File.join(File.dirname(__FILE__), '..', 'output', 'archives')
  STRIPS_ROOT  = File.join(File.dirname(__FILE__), '..', 'content', 'images', 'strips')

  def archives_list
  	strips = @pages.find(:all, :in_directory => 'images/strips').reject {|s| s.url =~ /^\./}
    strips.sort! {|a,b| a.filename <=> b.filename}
    list   = ArchivesList.new

    strips.each_index do |i|
      a_strip = strips[i]


      # Create individual pages for each archived strip
      page = create_strip_page_for(a_strip)
      page << image_for(a_strip)
      page << '<ul id="nav">'
      page << (i < 1 ? '<li>&nbsp;</li>' : previous_link_for(strips[i-1]))
      page << (i >= strips.size-1 ? '<li>&nbsp;</li>' : next_link_for(strips[i+1]))
      page << '</ul>'
      
      Logging::Logger[self].info "creating #{ARCHIVES_ROOT}/#{page.filename}"
      page.save_to_archives!

      # Add a list item to the archive list
      list << page
    end
    "#{list}"
  end

  private
  def create_strip_page_for(strip)
    StripPage.new(strip)
  end

# TODO:  Find a better way to determine whether this is the first or last
#   strip in the archives.
# TODO:  Make url for previous_link_for and next_link_for actually point
#   to the previous and next pages.  Right now it points to the current page.
  
  def previous_link_for(strip)
    %(<li><a href="#{create_strip_page_for(strip).url}">&lt; Previous</a></li>)
  end

  def next_link_for(strip)
    %(<li><a href="#{create_strip_page_for(strip).url}">Next &gt;</a></li>)
  end
  
  def image_for(strip)
    case strip.ext.downcase
    when /jpg|jpeg/
      image = JPEG.new(File.join(STRIPS_ROOT, "#{strip.filename}.#{strip.ext}"))
    when /gif/
      image = GIF.new(File.join(STRIPS_ROOT, "#{strip.filename}.#{strip.ext}"))
    else
      image = OpenStruct.new({:height => 100, :width => 100})
    end
    
    %(<p id="comic">
        <img src="#{strip.url}" height="#{image.height}" width="#{image.width}" />
      </p>)
  end
  
  
  class StripPage
    attr_reader :filename, :url, :title

    def initialize(strip)
      @created_on = Date.strptime("#{strip.filename}", '%Y%m%d')
      @title = "#{@created_on.year} #{Date::MONTHNAMES[@created_on.month][0..2]} #{"%0.2d" % @created_on.day}"
      @filename = "#{strip.filename}.html"
      @url      = "/archives/#{strip.filename}.html"
      @content  = ''
    end

    def date
      @filename.split('.').first
    end

    def path
      File.join(ARCHIVES_ROOT, @filename)
    end
    
    def <<(s)
      @content << s
    end

    def save_to_archives!
      @page     = OpenStruct.new({:title => @title})

      # TODO: Figure out how to use Webby's renderer so that I can apply other
      # page filters.
      template = ERB.new(File.read(File.dirname(__FILE__) + '/../layouts/strip.rhtml'))
      File.open(self.path, 'w') do |out|
        out << template.result(binding)
      end
    end
  end
  
  class ArchivesList
    def initialize
      @content = '<ol>'
    end
    
    def <<(page)
      @content << %(<li><a href="#{page.url}">#{page.title}</a></li>\n)
    end
    
    def to_s
      "#{@content}</ol>"
    end
  end
      
end

Webby::Helpers.register(ArchivesHelper)
