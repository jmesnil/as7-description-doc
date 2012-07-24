require 'rubygems'
require 'bundler/setup'
Bundler.require

module TextFilter
  def double(input)
    input + input
  end
end

def generate_toc(resource)
  out = "<div id=toc>"
  out += "<ul>"
  out += generate_resource_toc('root', resource, '')
  out += "</ul>"
  out += "</div>"
  out.to_s
end

def generate_resource_toc(name, resource, base)
  out = "<li><a href='##{base}#{name}''>#{name}</a></li>"
  return "" unless resource
  if resource['children'] != nil
    out += "<ul>"
    resource['children'].each { |k, v| out += generate_children_toc(k, v, "#{base}#{name}") }
    out += "</ul>"
  end
  out.to_s
end

def generate_children_toc(name, resource, base)
  out = "<li><a href='##{base}#{name}''>#{name}</a></li>"
  if resource['model-description'] != nil
    out += "<ul>"
    resource['model-description'].each { |k, v| out += generate_resource_toc(k, v, "#{base}#{name}") }
    out += "</ul>"
  end
  out.to_s
end


Liquid::Template.register_filter(TextFilter)
Liquid::Template.file_system = Liquid::LocalFileSystem.new("./views")

get '/resource-description' do
  user = params['user']
  password = params['password']

  return [500, "missing user and password parameters"] unless user and password

  url = 'http://127.0.0.1:9990/management/'
  operation = {:operation => "read-resource-description",
      :recursive => params["recursive"] || false,
      :operations => params["operations"] || false,
      :inherited => params["inherited"] || false,
      "json.pretty" => 1
    }
  res = AS7.query url, user, password, operation.to_json
  if res.code != 200
    [500, res.body.to_s]
  end

  result = JSON.parse(res.body.to_s, :max_nesting => false)

  if result['outcome'] != "success"
    [500, res.body.to_s]
   end
   resource = result['result']
   out = Liquid::Template.parse(File.read('./views/header.liquid')).render
   out += generate_toc(resource)
   out += Liquid::Template.parse(File.read('./views/root.liquid')).render('name' => 'root', 'root' => resource, 'base' => '')
   out += Liquid::Template.parse(File.read('./views/footer.liquid')).render
   out
end

get '/resource-description2' do
  user = params['user']
  password = params['password']

  return [500, "missing user and password parameters"] unless user and password

  url = 'http://127.0.0.1:9990/management/'
  operation = {:operation => "read-resource-description",
      :recursive => params["recursive"] || false,
      :operations => params["operations"] || false,
      :inherited => params["inherited"] || false
    }
  res = AS7.query url, user, password, operation.to_json
  if res.code == 200
    [res.code,   {'Content-type' => 'application/json'}, res.body.to_s]
  else
    [res.code, res.headers, res.body.to_s]
  end
end

class AS7
  include HTTParty
  def AS7.query(url, user, password, operation)
    digest_auth user, password
    post url , :body => operation, :headers => {"Content-type" => "application/json"}
  end
end