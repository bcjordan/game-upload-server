require 'rubygems'
require 'sinatra'
require 'securerandom'
require 'aws-sdk'
require 'pp'

set :public_folder, Proc.new { File.join(root, "public") }
set :server, %w[thin]

post "/upload" do
    pp request.env
    unique_hash = 'u' + imgur_style_hash()
    game_name = params[:gameName] || 'My Unity Game'
    game_width = params[:gameWidth] || 800
    game_height = params[:gameHeight] || 600
    game_filename = params[:gameFilename] || 'game.unity3d'
    upload(unique_hash + '/' + game_filename, params[:playerFile][:tempfile])
    game_page_object = get_s3_object(unique_hash + '/index.html')
    game_page_object.write(erb(:view_game, {}, {game_name: game_name, game_width: game_width, game_height: game_height, game_filename: game_filename}), :acl => :public_read, :content_type => "text/html")
    body "#{game_page_object.public_url.to_s.chomp('index.html')}"
end

# @return S3Object
def get_s3_object(filename)
  bucket_name = 'unihost'
  s3          = AWS::S3.new(
      :access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
      :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
  )
  puts 'about to store'
  bucket = s3.buckets[bucket_name]
  bucket.objects[filename]
end

helpers do
  def upload(filename, file)
    object = get_s3_object(filename) || S3Object.new(nil, nil)
    object.write(:file => file.path, :acl => :public_read, :content_type => "application/vnd.unity")
    url = object.public_url
    pp "URL is #{url}"
    return url
  end

  def upload_here(filename, file)
    File.open('uploads/' + filename, "w") do |f|
          f.write(file.read)
          return "The file was successfully uploaded!"
    end
  end

  def imgur_style_hash()
    SecureRandom.urlsafe_base64(4).chop
  end
end
