require "fileutils"
require "open3"
require "base64"
require "tempfile"
require "mime/types"

module VideoProcessable
  extend ActiveSupport::Concern

  included do
    before_save :process_video
  end

  class_methods do
    def video_attribute(attr_name)
      define_method(:video_attribute_name) { attr_name }
    end
  end

private

  def process_video
    value = public_send(video_attribute_name)
    return if value.blank?
    return unless processable_video?(value)

    file = normalize_video_input(value)
    path = store_video(file)
    public_send("#{video_attribute_name}=", path)
  end

  def processable_video?(value)
    uploaded_file?(value) || data_url?(value)
  end

  def uploaded_file?(value)
    value.is_a?(ActionDispatch::Http::UploadedFile) ||
      value.respond_to?(:original_filename)
  end

  def data_url?(value)
    value.is_a?(String) && value.start_with?("data:")
  end

  def normalize_video_input(value)
    return value if uploaded_file?(value)

    decode_data_url(value)
  end

  def decode_data_url(data_url)
    match = data_url.match(/\Adata:(.*?);base64,(.+)\z/)
    return nil unless match

    content_type = match[1]
    base64_data = match[2]
    decoded_data = Base64.decode64(base64_data)

    create_temp_file(decoded_data, content_type)
  end

  def create_temp_file(data, content_type)
    extension = MIME::Types[content_type].first&.preferred_extension || "mp4"
    tempfile = Tempfile.new([ "upload", ".#{extension}" ])
    tempfile.binmode
    tempfile.write(data)
    tempfile.rewind

    tempfile
  end

  def store_video(uploaded_file)
    key = ULID.generate
    original_path = save_original_video(uploaded_file, key)
    hls_dir = hls_directory(key)
    convert_to_hls(original_path, hls_dir)
    relative_path(hls_dir.join("playlist.m3u8"))
  end

  def save_original_video(uploaded_file, key)
    dir = video_directory(:original, key)
    path = dir.join("original#{file_extension(uploaded_file)}")

    write_uploaded_file(uploaded_file, path)
    path
  end

  def write_uploaded_file(uploaded_file, path)
    uploaded_file.rewind if uploaded_file.respond_to?(:rewind)
    File.open(path, "wb") { |file| IO.copy_stream(uploaded_file, file) }
  end

  def file_extension(uploaded_file)
    return ".mp4" unless uploaded_file.respond_to?(:original_filename)

    File.extname(uploaded_file.original_filename)
  end

  def video_directory(type, key)
    path = Rails.root.join("public", "videos", type.to_s, key)
    FileUtils.mkdir_p(path)
    path
  end

  def hls_directory(key)
    video_directory(:hls, key)
  end

  def convert_to_hls(original_path, hls_dir)
    playlist = hls_dir.join("playlist.m3u8")
    run_ffmpeg_conversion(original_path, playlist)
  end

  def run_ffmpeg_conversion(original_path, playlist)
    stdout, stderr, status = Open3.capture3(
      "ffmpeg", "-y",
      "-i", original_path.to_s,
      "-codec", "copy",
      "-start_number", "0",
      "-hls_time", "1",
      "-hls_list_size", "0",
      "-f", "hls",
      playlist.to_s
    )

    return if status.success?

    raise "ffmpeg failed: #{stderr.presence || stdout}"
  end

  def relative_path(path)
    public_path = Pathname(path).relative_path_from(Rails.root.join("public"))
    "/#{public_path}"
  end
end
