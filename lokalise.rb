#!/usr/bin/env ruby

# CODE USAGE
#   Player::Lokalise.new(options).download project_id
#   See "property" declarations below for the available options
#
# COMMAND-LINE USAGE
# - Install the gems mentioned just below (gem install excon hashie ... )
# - Save this anywhere convenient and run it with no arguments for instructions
#   (or see instructions at bottom of file)
#
# (This should become a gem later on)

%w(rubygems excon hashie json fileutils zip slop byebug).each { |gem| require gem }

######################################################################
# USING FROM COMMAND LINE
######################################################################

module Player
  class Lokalise < Hashie::Dash

    ZIP_FILE = '/tmp/lokalise.zip'

    ######################################################################
    # PUBLIC INTERFACE
    ######################################################################

    property :lokalise_api_token # Get this from https://lokali.se/en/account
    property :output_folder
    property :output_format, default: :yml
    property :allow_overwrite
    property :strip
    property :language_fallback
    property :quiet
    property :verbose

    def initialize(options)
      super(options)
      self.lokalise_api_token ||= ENV['LOKALISE_API_TOKEN']
      raise "Need Lokalise token passed in or as an environment variable" if !lokalise_api_token
    end

    def download(project_id)
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
          bundle_structure: '%PROJECT_NAME%.%LANG_ISO%.%FORMAT%'
      )
      response = Excon.post 'https://lokali.se/api/project/export', headers: headers, body: body
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
      zip_url_on_server = "https://lokali.se/#{@zip_path_on_server}"
      log "Downloading zip file from #{zip_url_on_server}"
      `curl --silent #{zip_url_on_server} > #{ZIP_FILE}`
    end

    def unzip
      if self.output_folder
        FileUtils.mkdir self.output_folder if !File.directory?(self.output_folder)
        Dir.chdir self.output_folder
      end
      #args = ['-qq']
      #args << '-o' if self.allow_overwrite
      #system "unzip #{args.join ' '} #{ZIP_FILE}"
      #log "Zip file has been extracted"
      @output_files = []
      Zip::File.open(ZIP_FILE) do |file|
        file.each do |entry|
          if entry.name!='./'
            FileUtils.rm(entry.name) if self.allow_overwrite && File.exists?(entry.name)
            entry.extract("#{entry.name}")
            @output_files << entry.name
          end
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
      }
    end

    def do_language_fallback
      return if !self.language_fallback
      languages = Set.new
      languages_with_dialects = Set.new
      dialect_files_by_language = {} # for now we'll just use one of each
      language_files_by_language = {} # for now we'll just use one of each
      @output_files.each { |output_file|
        if output_file =~ /\.([a-z][a-z])_.*\./
          languages_with_dialects << $1
          dialect_files_by_language[$1] = output_file
        elsif output_file =~ /\.([a-z][a-z])\./
          languages << $1
        end
        #find_and_replace output_file, /^.+""$\n/, ''
      }
      languages_with_only_dialects = languages_with_dialects - languages
      languages_with_only_dialects.each { |language|
        dialect_file = dialect_files_by_language[language]
        language_file = dialect_file.gsub /(\.[a-z][a-z])_.*(\..+)$/, "\\1\\2"
        FileUtils.cp dialect_file, language_file
        if dialect_file =~ /\.([a-z][a-z])/
          find_and_replace language_file, /^\S+$/, "#{language}:" # just first line
        end
      }
    end

    def output_files
      puts @output_files.join(' ') unless quiet
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

  end
end

######################################################################
# USING FROM COMMAND LINE
######################################################################

if __FILE__==$0
  opts = Slop.parse do |o|
    o.banner = <<END.chop
lokalise.rb [options] project_id
e.g.: lokalize.rb --token aab14314 -output-folder=translations 1234567e0.0129
Download string files from Lokalize projects
END
    o.string '-t', '--token', 'API token (default: LOKALISE_API_TOKEN env variable)'
    o.string '-f', '--format', 'output format (default: yml)', default: :yml
    o.string '-o', '--output-folder', 'output folder (default: current folder; will be created if doesn''t exist)'
    o.boolean '-s', '--strip', 'strip out entries with empty string value'
    o.boolean '-l', '--language-fallback', 'ensure non-dialect fallback exists for all dialects'
    o.boolean '-v', '--verbose', 'add logging'
    o.boolean '-q', '--quiet', 'no output - suppress showing new files'
    o.on '-h', '--help', 'help' do ; puts opts && exit ; end
  end
  ARGV.replace opts.arguments
  if project_id = ARGV[0]
    Player::Lokalise.new(
      lokalise_api_token: opts[:token],
      output_format: opts[:format],
      output_folder: opts['output-folder'],
      strip: opts['strip'],
      language_fallback: opts['language-fallback'],
      verbose: opts['verbose'],
      quiet: opts['quiet'],
      allow_overwrite: true
    ).download project_id
  else
    puts(opts)
  end
end
