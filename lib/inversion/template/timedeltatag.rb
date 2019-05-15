# -*- ruby -*-
# frozen_string_literal: true
# vim: set noet nosta sw=4 ts=4 :

require 'uri'
require 'time'
require 'date'

require 'inversion/template' unless defined?( Inversion::Template )
require 'inversion/template/attrtag'


# Inversion time delta tag.
#
# This tag is a derivative of the 'attr' tag that transforms the results of its method call
# to a Time object (if it isn't already), and then generates an English description of
# the different between it and the current time.
#
# == Syntax
#
#   Updated <?timedelta entry.update_date ?>.
#
class Inversion::Template::TimeDeltaTag < Inversion::Template::AttrTag

	# Approximate Time Constants (in seconds)
	unless defined?( MINUTES )
		MINUTES = 60
		HOURS   = 60  * MINUTES
		DAYS    = 24  * HOURS
		WEEKS   = 7   * DAYS
		MONTHS  = 30  * DAYS
		YEARS   = 365.25 * DAYS
	end


	######
	public
	######

	### Render the tag.
	def render( renderstate )
		val = super( renderstate )
		time = nil
		omit_decorator = false

		if val.respond_to?( :key )
			val, omit_decorator = val.values_at( :time, :omit_decorator )
		end

		if val.respond_to?( :to_time )
			time = val.to_time
		elsif val.is_a?( Numeric )
			time = Time.at( val )
		else
			time = Time.parse( val.to_s )
		end

		now = Time.now
		if now > time
			seconds = now - time
			period = timeperiod( seconds )
			period += ' ago' unless omit_decorator
			return period
		else
			seconds = time - now
			period = timeperiod( seconds )
			period += ' from now' unless omit_decorator
			return period
		end
	end


	#######
	private
	#######

	### Return a string describing +seconds+ as an approximate interval of time.
	def timeperiod( seconds )
		return case
			when seconds < MINUTES - 5
				'less than a minute'
			when seconds < 50 * MINUTES
				if seconds <= 89
					"a minute"
				else
					"%d minutes" % [ (seconds.to_f / MINUTES).ceil ]
				end
			when seconds < 90 * MINUTES
				'about an hour'
			when seconds < 18 * HOURS
				"%d hours" % [ (seconds.to_f / HOURS).ceil ]
			when seconds < 30 * HOURS
				'about a day'
			when seconds < WEEKS
				"%d days" % [ (seconds.to_f / DAYS).ceil ]
			when seconds < 2 * WEEKS
				'about a week'
			when seconds < 3 * MONTHS
				"%d weeks" % [ (seconds.to_f / WEEKS).ceil ]
			when seconds < 18 * MONTHS
				"%d months" % [ (seconds.to_f / MONTHS).ceil ]
			else
				"%d years" % [ (seconds.to_f / YEARS).ceil ]
			end
	end

end # class Inversion::Template::TimeDeltaTag

