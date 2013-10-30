require "sinatra"
require "rdiscount"
get "/" do
    File.read("index.html")
end

get "*" do |url|
    file_path = url_to_file(url)
    files = Dir["#{file_path}.*"]
    if files.empty?
        File.read("edit.html").sub("#title", "Create me:").sub("#content", "").sub("#&type", "html")
    else
        file_path = files[0]
        ext_name = File.extname(file_path)[1..-1]
        if params.has_key?("edit")
            File.read("edit.html").sub("#title", "Change me:")
            .sub("#content", File.read(file_path))
            .sub("#&type", ext_name)
        elsif params.has_key?("delete")
            File.read("delete.html").gsub("#url", url)
        else
            content = File.read(file_path)
            p ext_name
            case ext_name
            when 'md'
                markdown content
            else
                content
            end
        end
    end
end

post "*" do |url|
    ext_name = params[:type]
    file_path = url_to_file(url)
    Dir["#{file_path}.*"].each do |file|
        File.delete(file)
    end
    file_path = "#{file_path}.#{ext_name}"
    FileUtils.mkpath(File.dirname(file_path))
    File.open(file_path, 'w') do |file|
        file.write params[:text]
    end
    status 200
end

delete "*" do |url|
    file_path = url_to_file(url)
    Dir["#{file_path}.*"].each do |file|
        File.delete(file)
    end
    status 200
end

def url_to_file url
    "pages#{url.chomp '/'}"
end