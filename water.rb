require "sinatra"

get "/" do
    File.read("index.html")
end

get "*" do |url|
    html_file_path = url_to_file(url)
    unless File.exists?(html_file_path)
        File.read("edit.html").sub("#title", "Create me:").sub("#content", "")
    else
        if params.has_key?("edit")
            File.read("edit.html").sub("#title", "Change me:").sub("#content", File.read(html_file_path))
        elsif params.has_key?("delete")
            File.read("delete.html").gsub("#url", url)
        else
            File.read(html_file_path)
        end
    end
end

post "*" do |url|
    html_file_path = url_to_file url
    FileUtils.mkpath(File.dirname(html_file_path))
    File.open(html_file_path, 'w') do |file|
        file.write params[:text]
    end
    status 200
end

delete "*" do |url|
    html_file_path = url_to_file url
    File.delete(html_file_path)
    status 200
end

def url_to_file url
    "pages#{url.chomp '/'}.html"
end