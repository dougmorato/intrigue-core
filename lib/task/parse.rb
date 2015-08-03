require 'open-uri'
require 'yomu'

module Task
module Parse

  ###
  ### Entity Parsing
  ###

  def parse_entities_from_content(source_uri, content, optional_strings=nil)

    @task_log.log "Parsing text from #{source_uri}" if @task_log

    # Make sure we have something to parse
    unless content
      @task_log.error "No content to parse, returning" if @task_log
      return nil
    end

    # Scan for email addresses
    addrs = content.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,8}/)
    addrs.each do |addr|
      _create_entity("EmailAddress", {:name => addr, :source => source_uri})
    end

    # Scan for dns records
    dns_records = content.scan(/^[A-Za-z0-9]+\.[A-Za-z0-9]+\.[a-zA-Z]{2,6}$/)
    dns_records.each do |dns_record|
      _create_entity("DnsRecord", {:name => dns_record, :source => source_uri})
    end

    # Scan for phone numbers
    phone_numbers = content.scan(/((\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4})/)
    phone_numbers.each do |phone_number|
      _create_entity("PhoneNumber", { :name => "#{phone_number[0]}", :source => source_uri })
    end

    # Scan for Links
    #urls = content.scan(/https?:\/\/[\S]+/)
    #urls.each do |url|
    #  _create_entity("Uri", {:name => url, :source => source_uri })
    #end

    if optional_strings
      optional_strings.each do |string|
        found = content.scan(/#{string}/)
        found.each do |x|
          _create_entity("String", { :name => "#{x[0]}", :source => source_uri })
        end
      end
    end
  end

  def download_and_extract_metadata(uri)

    # Download file and store locally. This helps prevent mime-type confusion
    #
    file = open(uri)
    yomu = Yomu.new file

    # General Metadata
    #
    _create_entity("Info", :name => "Metadata for #{uri}",:metadata => yomu.metadata)

    ### PDF
    #
    if yomu.metadata["Content-Type"] == "application/pdf"

      _create_entity "File", { :type => "PDF",
        :name => uri,
        :created => yomu.metadata["Creation-Date"],
        :last_modified => yomu.metadata["Last-Modified"],
        :created_with => yomu.metadata["xmp:CreatorTool"],
        :plugin => yomu.metadata["producer"]
      }
      _create_entity "Person", { :name => yomu.metadata["Author"], :source => uri } if yomu.metadata["Author"]
      _create_entity "SoftwarePackage", { :name => "#{yomu.metadata["xmp:CreatorTool"]}", :plugin => "#{yomu.metadata["producer"]}", :source => uri } if yomu.metadata["producer"]

    end

    # Look for entities in the text
    parse_entities_from_content(uri,yomu.text)

    # Clean up
    #
    file.unlink
  end


end
end
