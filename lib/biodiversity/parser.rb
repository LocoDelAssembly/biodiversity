# frozen_string_literal: true

require 'open3'
require 'csv'

module Biodiversity
  # Parser provides a namespace for functions to parse scientific names.
  module Parser
    def self.parse(name, simple = false)
      parsed = simple ? parse_go_csv(name) : parse_go_compact(name)
      output(parsed, simple)
    end

    def self.parse_ary(ary, simple = false)
      ary.map { |n| parse(n, simple) }
    end

    def self.output(parsed, simple)
      if simple
        csv = CSV.new(parsed)
        parsed = csv.read[0]
        {
          id: get_csv_value(parsed, 'Id'),
          verbatim: get_csv_value(parsed, 'Verbatim'),
          cardinality: get_csv_value(parsed, 'Cardinality'),
          canonicalName: {
            full: get_csv_value(parsed, 'CanonicalFull'),
            simple: get_csv_value(parsed, 'CanonicalSimple'),
            stem: get_csv_value(parsed, 'CanonicalStem')
          },
          authorship: get_csv_value(parsed, 'Authorship'),
          year: get_csv_value(parsed, 'Year'),
          quality: get_csv_value(parsed, 'Quality')
        }
      else
        JSON.parse(parsed, symbolize_names: true)
      end
    end

    @csv_mapping = {}

    private_class_method def self.get_csv_value(csv, field_name)
      csv[@csv_mapping[field_name]]
    end

    private_class_method def self.start_gnparser
      @pid = Process.pid
      io = {}

      platform_suffix =
        case Gem.platforms[1].os
        when 'linux'
          'linux'
        when 'darwin'
          'mac'
        when 'mingw32'
          'win.exe'
        else
          raise "Unsupported platform: #{Gem.platforms[1].os}"
        end

      path = File.join(__dir__, '..', '..',
                       'binaries', "gnparser-#{platform_suffix}")

      %w[compact csv].each do |format|
        stdin, stdout, stderr = Open3.popen3("#{path} --format #{format}")
        io[format.to_sym] = { stdin: stdin, stdout: stdout, stderr: stderr }
      end

      CSV.new(io[:csv][:stdout].gets).read[0].each.with_index do |header, index|
        @csv_mapping[header] = index
      end

      @io = io
    end

    @semaphore = Mutex.new
    @pid = nil

    private_class_method def self.parse_go(name, format)
      @semaphore.synchronize do
        start_gnparser unless Process.pid == @pid
        @io[format][:stdin].puts(name)
        @io[format][:stdout].gets
      end
    end

    private_class_method def self.parse_go_compact(name)
      parse_go(name, :compact)
    end

    private_class_method def self.parse_go_csv(name)
      parse_go(name, :csv)
    end
  end
end
