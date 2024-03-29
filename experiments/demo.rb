# -*- ruby -*-
# vim: set noet nosta sw=4 ts=4 :

require 'logger'
require 'ostruct'
require 'inversion'
require 'configurability/config'

class DatabaseError < Exception; end

Encoding.default_external = Encoding::UTF_8

Loggability.level = opts.debug ? :debug : :error
Loggability.format_with( :color ) if $stdin.tty?

config = Configurability::Config.new
config.overboard_url = 'http://failedcompany.spime-thorpe.com/overboard'
config.templates.template_paths = [ File.dirname( __FILE__ ) + '/templates' ]
config.templates.debugging_comments = $DEBUG
config.install

employee = OpenStruct.new
employee.id = 1881
employee.fullname = "James Random"
employee.address = [
	'1213 NE. Winding Road',
	'Syracuse, NY  100213',
]
employee.severance_amount = 12.81

company = OpenStruct.new
company.id = 'a18661'
company.name = 'Widgets R Us'

tracking = OpenStruct.new
tracking.delivery_date = Time.now - 172800 # (48 hours)

layout = Inversion::Template.load( 'demo-layout.tmpl' )
content = Inversion::Template.load( 'demo-content.tmpl' )

content.failed_company = company
content.employee = employee
content.config = config
content.tracking_info = tracking
content.grace_period = "11 days"

layout.content = content
puts layout.render


