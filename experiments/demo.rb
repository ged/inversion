#!/usr/bin/env ruby

require 'logger'
require 'ostruct'
require 'inversion'
require 'configurability/config'

Inversion.log.level = Logger::DEBUG
Inversion.log.formatter = Inversion::ColorLogFormatter.new( Inversion.logger )
Configurability.logger = Inversion.logger

config = Configurability::Config.new
config.overboard_url = 'http://failedcompany.spime-thorpe.com/overboard'
config.templates.template_paths = [ File.dirname( __FILE__ ) + '/templates' ]
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

layout.content = content
puts layout.render


