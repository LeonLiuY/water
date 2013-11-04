require "sinatra"
require "rdiscount"
require "pg"

@@conn = PG.connect(ENV["DB_INFO"] || "dbname=water")
@@conn.prepare("find", "select * from link where url = $1")
@@conn.prepare("save",
    "with new_values (url, type, content) as (values($1, $2, $3)), upsert as (update link l set type = nv.type, content= nv.content from new_values nv where l.url = nv.url returning l.*) insert into link select * from new_values where not exists (select 1 from upsert up where up.url = new_values.url)")
@@conn.prepare("delete", "delete from link where url = $1")

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
            .sub("#content", page['content'])
            .sub("#&type", page['type'])
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
    result = @@conn.exec_prepared('find', [url])
    if result.ntuples == 0
        nil
    else
        result[0]
    end
end

def save_page(url, type, content)
    @@conn.exec_prepared('save', [url, type, content])
end

def delete_page(url)
    @@conn.exec_prepared('delete', [url])
end

def wrap_page(page)
    case page['type']
    when 'md'
        markdown page['content']
    else
        page['content']
    end
end