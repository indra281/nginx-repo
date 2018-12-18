Facter.add :aws_region do
  setcode do
    has_ec2_data = Facter.value(:ec2_metadata).to_s

    if !(has_ec2_data == '') # dont break on-prem
      # get region from AWS Meta-Data
      require 'net/http'
      require 'uri'

      uri = URI.parse("http://169.254.169.254/latest/meta-data/placement/availability-zone")
      response = Net::HTTP.get_response(uri)
      instanceRegion = response.body
      instanceRegion = instanceRegion[0...-1]

      instanceRegion
    end
  end
end
