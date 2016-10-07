require "lokalise/version"

# CODE USAGE
#   Lokalise::Pull.new(options).download project_id
#   See "property" declarations below for the available options
#
# COMMAND-LINE USAGE
# - Install the gems mentioned just below (gem install excon hashie ... )
# - Save this anywhere convenient and run it with no arguments for instructions
#   (or see instructions at bottom of file)
#
# (This should become a gem later on)

%w(rubygems excon hashie json zip slop byebug).each { |gem| require gem }

######################################################################
# USING FROM COMMAND LINE
######################################################################

module Lokalise
  class Pull < Hashie::Dash

    ZIP_FILE = '/tmp/lokalise.zip'

    ######################################################################
    # PUBLIC INTERFACE
    ######################################################################

    property :lokalise_api_token # Get this from https://lokalise.co/en/account
    property :output_folder
    property :output_format, default: :yml
    property :structure, default: '%PROJECT_NAME%.%LANG_ISO%.%FORMAT%'
    property :allow_overwrite
    property :strip
    property :language_fallback
    property :quiet
    property :verbose
    property :yaml_include_root

    def initialize(options)
      options[:lokalise_api_token] ||= ENV['LOKALISE_API_TOKEN']
      super options
      raise "Need Lokalise token passed in or as an environment variable" if !lokalise_api_token
    end

    def download(project_id)
      log "Fetching project #{project_id}"
      # save
      request_zip_from_lokalize project_id
      download_zip
      unzip
      # post-process
      do_strip
      do_language_fallback
      output_files
    end

    private

    ######################################################################
    # SAVE
    ######################################################################

    def request_zip_from_lokalize(project_id)
      headers = { "Content-Type" => "application/x-www-form-urlencoded" }
      body = URI.encode_www_form(
          id: project_id,
          api_token: lokalise_api_token,
          export_all: 1,
          type: self.output_format,
          use_original: '0',
          filter: 'translated',
          bundle_filename: '%PROJECT_NAME%-Locale.zip',
          bundle_structure: self.structure,
          yaml_include_root: boolean_to_binary[yaml_include_root]
      )

      fetch_start = Time.now
      response = Excon.post 'https://lokalise.co/api/project/export',
        headers: headers,
        body: body,
        read_timeout: 600
      log "Fetched in #{(Time.now - fetch_start).round(1)}s"

      if response.status==200
        result = Hashie::Mash.new JSON.parse(response.body)
        log "Result: #{result.pretty_inspect}"
        if result.response.code==403
          raise "Server returned error code - are token and ID correct?"
        else
          log "Server has built zip file"
          @zip_path_on_server = result.bundle.file
        end
      else
        raise "Could not reach Lokalise API"
      end
    end

    def download_zip
      zip_url_on_server = "https://lokalise.co/#{@zip_path_on_server}"
      log "Downloading zip file from #{zip_url_on_server}"
      `curl --silent #{zip_url_on_server} > #{ZIP_FILE}`
    end

    def unzip
      if self.output_folder
        `mkdir #{self.output_folder}` if !File.directory?(self.output_folder)
        Dir.chdir self.output_folder
      end
      #args = ['-qq']
      #args << '-o' if self.allow_overwrite
      #system "unzip #{args.join ' '} #{ZIP_FILE}"
      #log "Zip file has been extracted"
      @output_files = []
      Zip::File.open(ZIP_FILE) do |file|
        file.each do |entry|
          next if entry.name == './'
          `rm #{entry.name}` if self.allow_overwrite && File.exists?(entry.name)
          entry.extract("#{entry.name}")
          @output_files << entry.name
        end
      end
    end

    ######################################################################
    # POST-PROCESS
    ######################################################################

    def do_strip
      return if !self.strip
      @output_files.each { |output_file|
        find_and_replace output_file, /^.+""$\n/, ''
        # for xml, strip out "plurals" if all are empty
        if self.output_format.to_s=='xml'
          find_and_replace output_file, /<plurals name="[a-zA-Z_]+">[\n\r\t ]+(<item quantity="[a-zA-Z_]+"><\/item>[\n\r\t ]+)+<\/plurals>/m, ''
        end
      }
    end

    def do_language_fallback
      return if !self.language_fallback
      languages = Set.new
      languages_with_dialects = Set.new
      dialect_files_by_language = {} # for now we'll just use one of each
      @output_files.each { |output_file|
        if File.basename(output_file) =~ /\A([a-z][a-z])_.*\./
          lang = $1
          languages_with_dialects << lang
          current_dialect_file = dialect_files_by_language[lang]
          if !current_dialect_file || File.size(output_file) > File.size(current_dialect_file)
            dialect_files_by_language[lang] = output_file
          end
        elsif File.basename(output_file) =~ /\A([a-z][a-z])\./
          lang = $1
          languages << lang
        end
        #find_and_replace output_file, /^.+""$\n/, ''
      }
      languages_with_only_dialects = languages_with_dialects - languages
      @language_fallback_files = []
      languages_with_only_dialects.each { |language|
        dialect_file = dialect_files_by_language[language]
        language_file = dialect_file.gsub /([a-z][a-z])_.*(\..+)$/, "\\1\\2"
        `cp #{dialect_file} #{language_file}`
        @language_fallback_files << language_file
        if dialect_file =~ /([a-z][a-z])/ && self.output_format.to_s=='yml'
          find_and_replace language_file, /^\A\S+$/, "#{language}:" # strip dialect string inside file
        end
      }
    end

    def output_files
      puts [@output_files+(@language_fallback_files||[])].join(' ') unless quiet
    end

    ######################################################################
    # HELPERS
    ######################################################################

    def find_and_replace(file, pattern, replacement)
      content = File.read(file).gsub(pattern, replacement)
      File.open(file, "w") { |file| file.puts content }
    end

    def log(s)
      puts s if self.verbose
    end

    def error_log(s)
      puts "ERROR: #{s}"
    end

    def boolean_to_binary
      {
        true => 1,
        false => 0
      }
    end
  end
end
