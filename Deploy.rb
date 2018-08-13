require_relative 'awd_classes.rb'
require_relative 'AWD_models.rb'
sourceenv = String.new
sourcedpc = String.new
targetenv = String.new
targetdpc = String.new

#splash page for ux
puts 'Welcome to the AWD Promote Utility! What would you like to do?'
puts '1 - Compare models'
puts '2 - Stage models'
puts '3 - Deploy models'
#puts '4 - Deploy forms'
print 'Enter number:'
user_action = gets.chomp

credentials = Proc.new do |e,d|
		print "User name:"
		$user = gets.chomp
		print "Password:"
		$password = STDIN.noecho(&:gets).chomp
		test = AwdCall.new(e, d)
		testlogin = test.getmodellist
		case testlogin.code
			when '401'
				puts testlogin.body
				raise 'AWD login error!'
			else
				puts
		end
end

source_input = Proc.new do
	print "Source environment:"
	sourceenv = gets.chomp.downcase
	print "Is source env on DPC? (Y or N):"
	sourcedpc = gets.chomp.upcase
	credentials.call(sourceenv, sourcedpc)
end

target_input = Proc.new do
	print "Target environment:"
	targetenv = gets.chomp.downcase
	print "Is target env on DPC? (Y or N):"
	targetdpc = gets.chomp.upcase
	credentials.call(targetenv, targetdpc)
end

#executes selection
case user_action
	when '1' #compare models
		source_input.call
		target_input.call
		
		compare = AWDModels.new(sourceenv, sourcedpc)
		results = compare.comparemodels(targetenv, targetdpc)
		
		CSV.open("deploy_service.csv", "w") do |f|
			compare.output.each do |x|
				f << [x]
			end
		end
	when '2' #stage models
		source_input.call
		
		guids = AWDModels.new(sourceenv, sourcedpc)
		stage = guids.getGUIDgrid
		
		#loads the csv file of models to deploy, appends guid and version
		output = []
		CSV.foreach("models.csv") do |x|
		  guid = guids.guid_name.key(x[0]) || "None"
		  vers = guids.guid_vers[guid]
		  type = guids.guid_type[guid]
		  output << guid + "," + vers + "," + type + "," + x[0]
		end

		#overwrites the csv file with the new array containing guid and version
		CSV.open("models.csv", "w") do |f|
		  output.each do |x|
		  f << [x]
		  end
		end
	when '3' #deploy models
		source_input.call
		target_input.call
		
		todeploy = []
		CSV.foreach("models.csv") do |x|
			todeploy << x[0].split(',')
		end
		puts "#{todeploy.count} models ready to deploy."
		
		print 'Ready to deploy? (Y = Deploy, S = Save, C = Cancel):'
		deploy_action = gets.chomp.upcase
		
		case deploy_action
			when 'Y'
				models = AWDModels.new(sourceenv, sourcedpc)
				deploy = models.deploymodels(targetenv, targetdpc, todeploy)
			when 'S'
				models = AWDModels.new(sourceenv, sourcedpc)
				save = models.savemodels(targetenv, targetdpc, todeploy)
			else
				puts 'Deploy cancelled. No models were exported/imported.'
		end
	else
		puts 'Invalid entry'
end