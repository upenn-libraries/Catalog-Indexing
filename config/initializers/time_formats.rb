# frozen_string_literal: true

Time::DATE_FORMATS[:display] = ->(time) { time.in_time_zone.strftime('%F %r') }
