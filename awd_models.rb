require_relative 'awd_classes.rb'

class AWDModels
	attr_accessor :sourceenv, :sourcedpc, :guid_name, :guid_type, :guid_vers, :output
	
	def initialize (sourceenv, sourcedpc)
		@sourceenv = sourceenv
		@sourcedpc = sourcedpc
	end
	
	def getGUIDgrid
		@guid_name = Hash.new("None")
		@guid_vers = Hash.new("None")
		@guid_type = Hash.new("None")

		#SERVICES
		#gets list of services, in source env, for all three types: 1=PF, 2=AS, 3=SS
		(1..3).each do |t|
		  svc_call = AwdCall.new(@sourceenv, @sourcedpc)
		  svc_call_resp = svc_call.getservicelist(t)

		#populates hashes with the guid/name and guid/version combinations
		xmldoc = Nokogiri::XML(svc_call_resp.body)
		xmldoc.xpath("//id").each do |i|
			@guid_name[i.content] = 1
			@guid_vers[i.content] = 1
			@guid_type[i.content] = 'S'
		  end

		#for each GUID, adds deployed version number and name as a hash within the models hash
		  @guid_name.each do |k, v|
		  svc = AwdCall.new(@sourceenv, @sourcedpc)
		  response = svc.get_deployed_service_vers(k)
		  xmldoc = Nokogiri::XML(response.body)
		  @guid_name[k] = xmldoc.xpath("/ServiceViewResponse/getListForModelResponse/services/service[modelStateCode=2]/name").first.content
		  @guid_vers[k] = xmldoc.xpath("/ServiceViewResponse/getListForModelResponse/services/service[modelStateCode=2]/version").first.content
		  end
		end

		#PROCESSES
		#gets list of processes, in source env
		proc_call = AwdCall.new(@sourceenv, @sourcedpc)
		proc_call_resp = proc_call.getmodellist


		#populates hashes with the guid/name and guid/version combinations
		xmldoc = Nokogiri::XML(proc_call_resp.body)
		xmldoc.xpath("//id").each do |i|
		  @guid_name[i.content] = 1
		  @guid_vers[i.content] = 1
		  @guid_type[i.content] = 'P'
		end

		#for each GUID, adds deployed version number and name as a hash within the models hash
		@guid_name.each do |k, v|
			proc = AwdCall.new(@sourceenv, @sourcedpc)
			response = proc.get_deployed_model_vers(k)
			xmldoc = Nokogiri::XML(response.body)
			version = xmldoc.xpath("/ProcessViewResponse/getListForModelResponse/processes/process[modelStateCode=1]/version").first
			name = xmldoc.xpath("/ProcessViewResponse/getListForModelResponse/processes/process[modelStateCode=1]/name").first
			@guid_name[k] = name.content unless version.nil?
			@guid_vers[k] = version.content unless version.nil?
		end
	end
	
	def deploymodels (targetenv, targetdpc, todeploy)
		logger = Logger.new('deploymodels.log', 'weekly')
		logger.sev_threshold = Logger::INFO
		
		todeploy.each do |x|
			modelguid = x[0]
			modelv = x[1]
			modeln = x[3]
			puts "Preparing to move #{modeln}..."
			
			case x[2]
				when 'P'
					#gets the physical model contents, for a given GUID, from the source env
					call = AwdCall.new(@sourceenv, @sourcedpc)
					response = call.getmodel(modelguid, modelv)
					
					#parses out the necessary elements - definition, description, and name
					xmldoc = Nokogiri::XML(response.body)
					begin
						definition = xmldoc.xpath('//definition').first.content
					rescue NoMethodError => e
						logger.error "Error exporting #{modelguid}. Response: #{response.body}"
					else
						name = xmldoc.xpath('//name').first.content
						description = xmldoc.xpath('//description').first.content

						#gets BA/WT from sourceenv to deploy to
						response = call.getdeployBAWT(modelguid, modelv)

						#parses out BA/WT
						xmldoc = Nokogiri::XML(response.body)
						ba = xmldoc.xpath('//businessArea').first.content
						wt = xmldoc.xpath('//workTypeName').first.content
						
						#deploys the physical contents in the target env
						call = AwdCall.new(targetenv, targetdpc)
						response = call.deploymodel(modelguid, modelv, name, definition, description, ba, wt)
						
						#parses out response for validation and logging
						xmldoc = Nokogiri::XML(response.body)
						begin
							resver = xmldoc.xpath('//processVersion').first.content
						rescue NoMethodError => e
							logger.error "Model #{name} errored. Response: #{response.body}"
						else
						resstate = xmldoc.xpath('//modelState').first.content
						puts "Model #{name} now in #{targetenv} in a #{resstate} state. Version #{resver}."
						logger.info "Model #{name} now in #{targetenv} in a #{resstate} state. Version #{resver}."
						end
					end
					
				when 'S'
					#gets the physical model contents, for a given GUID, from the source env
					call = AwdCall.new(@sourceenv, @sourcedpc)
					response = call.getservice(modelguid, modelv)

					#parses out the necessary elements - definition, description, and name
					xmldoc = Nokogiri::XML(response.body)
					definition = xmldoc.xpath('//definition').first.content
					name = xmldoc.xpath('//name').first.content
					description = xmldoc.xpath('//description').first.content
					type = xmldoc.xpath('//type').first.content

					#saves, without deploying, the physical contents in the target env
					call = AwdCall.new(targetenv, targetdpc)
					response = call.saveservice(modelguid, modelv, name, definition, description, type)

					xmldoc = Nokogiri::XML(response.body)
					begin
						version = xmldoc.xpath('//version').first.content 
					rescue NoMethodError => e
						logger.error "Model #{name} errored. Response: #{response.body}"
					else
						#deploys the physical contents in the target env
						response = call.deployservice(modelguid, modelv, name, definition, description, type)
						xmldoc = Nokogiri::XML(response.body) 
						resver = xmldoc.xpath('//version').first.content
						resstate = xmldoc.xpath('//modelState').first.content
						puts "Model #{name} now in #{targetenv} in a #{resstate} state. Version #{resver}."
						logger.info "Model #{name} now in #{targetenv} in a #{resstate} state. Version #{resver}."
					end
				else
					nil
				end
		end
	end

	def savemodels (targetenv, targetdpc, todeploy)
		logger = Logger.new('deploymodels.log', 'weekly')
		logger.sev_threshold = Logger::INFO
		
		todeploy.each do |x|
			modelguid = x[0]
			modelv = x[1]
			modeln = x[3]
			puts "Preparing to move #{modeln}..."
			
			case x[2]
				when 'P'
					#gets the physical model contents, for a given GUID, from the source env
					call = AwdCall.new(@sourceenv, @sourcedpc)
					response = call.getmodel(modelguid, modelv)
					
					#parses out the necessary elements - definition, description, and name
					xmldoc = Nokogiri::XML(response.body)
					begin
						definition = xmldoc.xpath('//definition').first.content
					rescue NoMethodError => e
						logger.error "Error exporting #{modelguid}. Response: #{response.body}"
					else
						name = xmldoc.xpath('//name').first.content
						description = xmldoc.xpath('//description').first.content

						#gets BA/WT from sourceenv to deploy to
						response = call.getdeployBAWT(modelguid, modelv)

						#parses out BA/WT
						xmldoc = Nokogiri::XML(response.body)
						ba = xmldoc.xpath('//businessArea').first.content
						wt = xmldoc.xpath('//workTypeName').first.content
						
						#deploys the physical contents in the target env
						call = AwdCall.new(targetenv, targetdpc)
						response = call.savemodel(modelguid, name, definition, description)
						
						#parses out response for validation and logging
						xmldoc = Nokogiri::XML(response.body)
						begin
							resver = xmldoc.xpath('//processVersion').first.content
						rescue NoMethodError => e
							logger.error "Model #{name} errored. Response: #{response.body}"
						else
						resstate = xmldoc.xpath('//modelState').first.content
						puts "Model #{name} now in #{targetenv} in a #{resstate} state. Version #{resver}."
						logger.info "Model #{name} now in #{targetenv} in a #{resstate} state. Version #{resver}."
						end
					end
					
				when 'S'
					#gets the physical model contents, for a given GUID, from the source env
					call = AwdCall.new(@sourceenv, @sourcedpc)
					response = call.getservice(modelguid, modelv)

					#parses out the necessary elements - definition, description, and name
					xmldoc = Nokogiri::XML(response.body)
					definition = xmldoc.xpath('//definition').first.content
					name = xmldoc.xpath('//name').first.content
					description = xmldoc.xpath('//description').first.content
					type = xmldoc.xpath('//type').first.content

					#saves, without deploying, the physical contents in the target env
					call = AwdCall.new(targetenv, targetdpc)
					response = call.saveservice(modelguid, modelv, name, definition, description, type)

					xmldoc = Nokogiri::XML(response.body)
					begin
						version = xmldoc.xpath('//version').first.content 
					rescue NoMethodError => e
						logger.error "Model #{name} errored. Response: #{response.body}"
					else
						resver = xmldoc.xpath('//version').first.content
						resstate = xmldoc.xpath('//modelState').first.content
						puts "Model #{name} now in #{targetenv} in a #{resstate} state. Version #{resver}."
						logger.info "Model #{name} now in #{targetenv} in a #{resstate} state. Version #{resver}."
					end
				else
					nil
				end
		end
	end

	def comparemodels (targetenv, targetdpc)
		source_models = Hash.new("None")
		target_models = Hash.new("None")
		@output = []
		logger = Logger.new('comparemodels.log', 'weekly')
		logger.sev_threshold = Logger::INFO
		
		#source env - processes
		call = AwdCall.new(@sourceenv, @sourcedpc)
		call_resp = call.getmodellist
		xmldoc = Nokogiri::XML(call_resp.body)
	
		xmldoc.xpath("//id").each do |i|
			source_models[i.content] = "Not Deployed in target"
        end
		
		source_models.each do |k, v|
			model = AwdCall.new(@sourceenv, @sourcedpc)
			response = model.get_deployed_model_vers(k)

			xmldoc = Nokogiri::XML(response.body)
			begin
				version = xmldoc.xpath("/ProcessViewResponse/getListForModelResponse/processes/process[modelStateCode=1]/version").first
			rescue NoMethodError => e
				logger.error "No deployed version in #{@sourceenv} for #{k}"
			else
				name = xmldoc.xpath("/ProcessViewResponse/getListForModelResponse/processes/process[modelStateCode=1]/name").first
				source_models[k] = {"Version" => version.content, "Name" => name.content} unless version.nil?
			end
        end
		
		#target env - processes
		call = AwdCall.new(targetenv, targetdpc)
		call_resp = call.getmodellist
		xmldoc = Nokogiri::XML(call_resp.body)
		
		xmldoc.xpath("//id").each do |i|
			target_models[i.content] = "Not Deployed in source"
		end
		target_models.each do |k, v|
			model = AwdCall.new(targetenv, targetdpc)
			response = model.get_deployed_model_vers(k)

			xmldoc = Nokogiri::XML(response.body)
			begin
				version = xmldoc.xpath("/ProcessViewResponse/getListForModelResponse/processes/process[modelStateCode=1]/version").first
			rescue NoMethodError => e
				logger.error "No deployed version in #{targetenv} for #{k}"
			else
				name = xmldoc.xpath("/ProcessViewResponse/getListForModelResponse/processes/process[modelStateCode=1]/name").first
				target_models[k] = {"Version" => version.content, "Name" => name.content} unless version.nil?
			end
		end
		
		#builds output array with models
		(source_models.keys & target_models.keys).each {|k| @output << "#{k},#{source_models[k]["Version"]},#{source_models[k]["Name"]}" unless source_models[k]["Version"] == target_models[k]["Version"]}
		
		#clears hashes for use with services
		source_models.clear
		target_models.clear
		
		#source env - services
		(1..3).each do |t|
			call = AwdCall.new(@sourceenv, @sourcedpc)
			call_resp = call.getservicelist(t)
			
			#populates the models hash with GUID values for all models
			xmldoc = Nokogiri::XML(call_resp.body)
			xmldoc.xpath("//id").each do |i|
				source_models[i.content] = "Not Deployed in target"
			end
			
			#for each GUID, adds deployed version number and name as a hash within the models hash
			source_models.each do |k, v|
				model = AwdCall.new(@sourceenv, @sourcedpc)
				response = model.get_deployed_service_vers(k)
				xmldoc = Nokogiri::XML(response.body)
				begin
					source_models[k] = {"Version" => xmldoc.xpath("/ServiceViewResponse/getListForModelResponse/services/service[modelStateCode=2]/version").first.content, "Name" => xmldoc.xpath("/ServiceViewResponse/getListForModelResponse/services/service[modelStateCode=2]/name").first.content}
				rescue NoMethodError => e
					logger.error "No deployed version in #{@sourceenv} for #{k}"
				else
					nil
				end
			end
		end
		#target env - services
		(1..3).each do |t|
			call = AwdCall.new(targetenv, targetdpc)
			call_resp = call.getservicelist(t)
		
			#populates the models hash with GUID values for all models
			xmldoc = Nokogiri::XML(call_resp.body)
			xmldoc.xpath("//id").each do |i|
				target_models[i.content] = "Not Deployed in source"
			end
			
			#for each GUID, adds deployed version number and name as a hash within the models hash
			target_models.each do |k, v|
				model = AwdCall.new(targetenv, targetdpc)
				response = model.get_deployed_service_vers(k)
				xmldoc = Nokogiri::XML(response.body)
				begin
					target_models[k] = {"Version" => xmldoc.xpath("/ServiceViewResponse/getListForModelResponse/services/service[modelStateCode=2]/version").first.content, "Name" => xmldoc.xpath("/ServiceViewResponse/getListForModelResponse/services/service[modelStateCode=2]/name").first.content}
				rescue NoMethodError => e
					logger.error "No deployed version in #{targetenv} for #{k}"
				else
					nil
				end
			end
		end
		
		#adds services to output array
		(source_models.keys & target_models.keys).each {|k| @output << "#{k},#{source_models[k]["Version"]},#{source_models[k]["Name"]}" unless source_models[k]["Version"] == target_models[k]["Version"]}
	end

	end