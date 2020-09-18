# frozen_string_literal: true

require 'open3'
require 'csv'

module Biodiversity
  # Parser provides a namespace for functions to parse scientific names.
  module Parser
    def self.parse(name, simple = false)
      if simple
        output_csv(parse_go_csv(name))
      else
        output_compact(parse_go_compact(name))
      end
    end

    def self.parse_ary(ary, simple = false)
      if simple
        parse_ary_go_csv(ary)
      else
        parse_ary_go_compact(ary)
      end
    end

    private_class_method def self.output_csv(parsed)
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
    end

    private_class_method def self.output_compact(parsed)
      JSON.parse(parsed, symbolize_names: true)
    end

    @csv_mapping = {}

    private_class_method def self.get_csv_value(csv, field_name)
      csv[@csv_mapping[field_name]]
    end

    private_class_method def self.start_gnparser
      io = {}

      platform_suffix = Gem.platforms[1].os == 'mingw32' ? '.exe' : ''
      path = File.join(__dir__, '..', '..',
                       'ext', "gnparser#{platform_suffix}")

      %w[compact csv].each do |format|
        stdin, stdout, stderr = Open3.popen3("#{path} --format #{format}")
        io[format.to_sym] = { stdin: stdin, stdout: stdout, stderr: stderr }
      end

      CSV.new(io[:csv][:stdout].gets).read[0].each.with_index do |header, index|
        @csv_mapping[header] = index
      end

      @pid = Process.pid
      @io = io
    end

    @semaphore = Mutex.new
    @pid = nil

    private_class_method def self.clean_name(name)
      name.gsub(/(\n|\r\n|\r)/, ' ')
    end

    private_class_method def self.parse_go(name, format)
      @semaphore.synchronize do
        start_gnparser unless Process.pid == @pid
        @io[format][:stdin].puts(clean_name(name))
        @io[format][:stdout].gets
      end
    end

    private_class_method def self.parse_go_compact(name)
      parse_go(name, :compact)
    end

    private_class_method def self.parse_go_csv(name)
      parse_go(name, :csv)
    end

    private_class_method def self.parse_ary_go(ary, format, simple)
      @semaphore.synchronize do
        start_gnparser unless Process.pid == @pid

        count = ary.count
        Thread.new do
          ary.each { |n| @io[format][:stdin].puts(clean_name(n)) }
        end

        hsh = {}
        if simple
          count.times.each do
            res = output_csv(@io[format][:stdout].gets)
            hsh[res[:verbatim]] = res
          end
        else
          count.times.each do
            res = output_compact(@io[format][:stdout].gets)
            hsh[res[:verbatim]] = res
          end
        end

        ary.map { |n| hsh[clean_name(n)] }
      end
    end

    private_class_method def self.parse_ary_go_compact(ary)
      parse_ary_go(ary, :compact, false)
    end

    private_class_method def self.parse_ary_go_csv(ary)
      parse_ary_go(ary, :csv, true)
    end
  end
end
