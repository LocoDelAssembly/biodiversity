# frozen_string_literal: true

desc 'Downloads platform-specific gnparser executable'
task :download_gnparser do
  url_path =
    case Gem.platforms[1].os
    when 'linux'
      '7d6ed7e3b1eee0fd6c9ae51f5bf711c0/gnparser-v0.14.1-linux.tar.gz'
    when 'darwin'
      '47d90de5bdaf8c51d578bc1f74a05859/gnparser-v0.14.1-mac.tar.gz'
    when 'mingw32'
      '021f4982aa08c24ed8aa65698f5ece4c/gnparser-v0.14.1-win-64.zip'
    else
      raise "Unsupported platform: #{Gem.platforms[1].os}"
    end

  url = 'https://gitlab.com/gogna/gnparser/uploads/' + url_path
  exe_path = "#{File.expand_path('..', __dir__)}/ext"

  unless File.exist? "#{exe_path}/gnparser"
    `curl -o #{exe_path}/#{url_path.split('/').last} #{url}`
    if url.end_with?('zip')
      `unzip #{exe_path}/#{url_path.split('/').last} -d #{exe_path}`
    else
      `tar xf #{exe_path}/#{url_path.split('/').last} -C #{exe_path}`
    end
    `rm #{exe_path}/#{url_path.split('/').last}`
  end

  raise 'gnpaser download failed!' unless
    system("#{exe_path}/gnparser --version")
end
