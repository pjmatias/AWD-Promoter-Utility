#credentials for baisc auth must be supplied using the global variables $user and $password
require 'net/http'
require 'nokogiri'
require 'csv'
require 'logger'
require 'io/console'
require_relative 'env_config.rb'

class AwdCall
  attr_writer :uri, :header, :body, :env
  
  def initialize(env, dpc)
    @header = {'Content-Type' => 'application/xml'}
    @env = env
    case dpc
      when "N"
        @uri = URI.parse("#{$server}#{@env}app/awdServer/awd/awdweb")
      when "Y"
        @uri = URI.parse("#{$server_dpc_non}#{@env}app/awdServer/awd/awdweb")
	  when "P"
        @uri = URI.parse("#{$server_dpc_prod}#{@env}app/awdServer/awd/awdweb")
    end
  end
  
  def makehttpcall(verb="get")
  http = Net::HTTP.new(@uri.host, @uri.port)
    case verb.downcase
      when "post" 
        request = Net::HTTP::Post.new(@uri.request_uri, @header)
      when "put"
        request = Net::HTTP::Put.new(@uri.request_uri, @header)
      when "get"
        request = Net::HTTP::Get.new(@uri.request_uri, @header)
    end
  request.basic_auth $user, $password
  request.body = @body
  http.use_ssl = (@uri.scheme == 'https')
  http.ca_file = 'cacert.pem'
  response = http.request(request)
  end
  
  def login
    @body = "<tcAJAXLogon>
    <AWDCredentials>
    <userId>#{$user}</userId>
	<password encrypt =\"Y\">#{$password}<password>
	</AWDCredentials>
  </tcAJAXLogon>"

    makehttpcall("post")
  end
  
  def getmodellist
    @body = "<ProcessViewRequest>
    <getList/>
    <userId>#{$user}</userId>
  </ProcessViewRequest>"

    makehttpcall("post")
  end
  
  def get_deployed_model_vers(guid)
    @body = "<ProcessViewRequest>
  <getListForModel>
    <id>#{guid}</id>
  </getListForModel>
  <userId>#{$user}</userId>
</ProcessViewRequest>"

  makehttpcall("post")
  end
  
  def getservicelist(t)
    @body = "<ServiceViewRequest>
  <getServiceList>
    <type>#{t}</type>
  </getServiceList>
  <userId>#{$user}</userId>
</ServiceViewRequest>"

  makehttpcall("post")
  end
  
  def get_deployed_service_vers(guid)
    @body = "<ServiceViewRequest>
  <getListForModel>
    <id>#{guid}</id>
  </getListForModel>
  <userId>#{$user}</userId>
</ServiceViewRequest>"
  
  makehttpcall("post")
  end
  
  def getformlist
    @body = "<tcAJAXGetUserScreenNames><userScreen><screenFormat>U</screenFormat><screenFormat>E</screenFormat></userScreen></tcAJAXGetUserScreenNames>"

    makehttpcall("post")
  end
  
  def getmodel(guid, version)
    @body = "<ProcessViewRequest>
  <getModel>
    <id>#{guid}</id>
    <version>#{version}</version>
    <lock>false</lock>
  </getModel>
  <userId>#{$user}</userId>
</ProcessViewRequest>"

  makehttpcall("post")
  end
  
  def getservice(guid, version)
    @body = "<ServiceViewRequest>
  <getService>
    <id>#{guid}</id>
    <version>#{version}</version>
    <lock>false</lock>
  </getService>
  <userId>#{$user}</userId>
</ServiceViewRequest>"

  makehttpcall("post")
  end
  
  def getdeployBAWT(guid, version)
    @body = "<ProcessViewRequest>
  <getDeploymentHistoryByIdAndVersion>
    <process>
      <id>#{guid}</id>
      <version>#{version}</version>
    </process>
  </getDeploymentHistoryByIdAndVersion>
</ProcessViewRequest>"

  makehttpcall("post")
  end
  
  def deploymodel(guid, version, name, definition, description, ba, wt)
    @body = "<ProcessViewRequest>
      <deploy>
        <process>
          <id>#{guid}</id>
          <version>#{version}</version>
          <name>#{name}</name>
          <definition>#{definition}</definition>
          <description>#{description}</description>
        </process>
        <deployments>
      <deployment>
        <businessArea>#{ba}</businessArea>
        <workType>#{wt}</workType>
      </deployment>
    </deployments>
      </deploy>
      <userId>#{$user}</userId>
    </ProcessViewRequest>"

  makehttpcall("post")
  end
  
  def deployservice(guid, version, name, definition, description, type)
    @body = "<ServiceViewRequest>
  <deploy>
    <service>
      <id>#{guid}</id>
      <version>#{version}</version>
      <name>#{name}</name>
      <definition>#{definition}</definition>
      <description>#{description}</description>
      <type>#{type}</type>
      <inputSchema></inputSchema>
      <outputSchema></outputSchema>
    </service>
  </deploy>
  <userId>#{$user}</userId>
</ServiceViewRequest>"

  makehttpcall("post")
  end
  
  def savemodel(guid, name, definition, description)
    @body = "<ProcessViewRequest>
    <saveModel>
      <process>
        <id>#{guid}</id>
        <version>0</version>
        <name>#{name}</name>
        <definition>#{definition}</definition>
        <description>#{description}</description>
      </process>
    </saveModel>
    <userId>#{$user}</userId>
  </ProcessViewRequest>"

  makehttpcall("post")
  end
  
  def saveservice(guid, version, name, definition, description, type)
    @body = "<ServiceViewRequest>
<saveModel>
  <service>
    <id>#{guid}</id>
    <version>#{version}</version>
    <name>#{name}</name>
    <definition>#{definition}</definition>
    <description>#{description}</description>
    <type>#{type}</type>
    <inputSchema></inputSchema>
    <outputSchema></outputSchema>
  </service>
</saveModel>
<userId>#{$user}</userId>
</ServiceViewRequest>"

  makehttpcall("post")
  end
  
  def userupdate(userid, status)
    @body = "<UserViewRequest><updateRouting><userRouting>
<userId>#{userid}</userId>
<queueFlag>N</queueFlag><userIdStatus>#{status}</userIdStatus></userRouting></updateRouting></UserViewRequest>"

  makehttpcall("post")
  end
  
  def resetpass(uuser, upass)
    @body = "<UserViewRequest><resetPassword>
<userId>#{uuser}</userId>
<password>#{upass}</password></resetPassword></UserViewRequest>"

  makehttpcall("post")
  end
end