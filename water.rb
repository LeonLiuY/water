require "sinatra"
require "redcarpet"
require "pygmentize"
require 'sinatra/sequel'

set :database, 'postgres://postgres:@localhost/water'

if !database.table_exists?('links')
    migration "create links table" do
        database.create_table :links do
            String :url
            String :type
            text :content
            primary_key [:url]
        end
    end
end

class Link < Sequel::Model
end

before do
    request.path_info.chomp!("/")
end

get "/" do
    File.read("index.html")
end

get %r{/(.+)} do |url|
    page = get_page(url)
    if page.nil?
        File.read("edit.html").sub("#title", "Create me:").sub("#content", "").sub("#&type", "html")
    else
        if params.has_key?("edit")
            File.read("edit.html").sub("#title", "Change me:")
            .sub("#content", page[:content])
            .sub("#&type", page[:type])
        elsif params.has_key?("delete")
            File.read("delete.html").gsub("#url", url)
        else
            wrap_page(page)
        end
    end
end

post %r{/(.+)} do |url|
    save_page(url, params[:type], params[:text])
    status 200
end

delete %r{/(.+)} do |url|
    delete_page(url)
    status 200
end

def get_page(url)
    Link[url]
end

def save_page(url, type, content)
    link = Link[url]
    if link.nil?
        link = Link.new
        link.url = url
    end
    link.type = type
    link.content = content
    link.save
end

def delete_page(url)
    link = Link[url]
    unless link.nil?
        link.delete
    end

end

def wrap_page(page)
    case page[:type]
    when 'md'
        renderer = PygmentizeHTML
        extensions = {fenced_code_blocks: true}
        redcarpet = Redcarpet::Markdown.new(renderer, extensions)
        File.read("markdown.html").sub("#content", redcarpet.render(page[:content]))
    else
        page[:content]
    end
end

class PygmentizeHTML < Redcarpet::Render::HTML
  def block_code(code, language)
    require 'pygmentize'
    Pygmentize.process(code, language)
  end
end
