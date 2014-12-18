require 'clndr-rails/engine'
require "clndr-rails/version"
require 'clndr-rails/errors'


require 'momentjs-rails'
require 'jquery-rails'
require 'underscore-rails'

class Clndr

  autoload :Helpers, 'clndr-rails/helpers'
  autoload :Template, 'clndr-rails/templates'
  require 'clndr-rails/config'


  include ActionView::Helpers
  include ActionView::Context
  include ActiveSupport::Inflector


  # return calendar from calendars bean
  def self.get_calendar(calendar)
    clndr = ObjectSpace.each_object(self) {|cal| return cal if cal.name.to_sym == calendar  }
    if clndr.class == Clndr
      clndr
    else
      raise Clndr::Error::CalendarNotFound, "Calndear with name #{scope} not found. Use Clndr.new(:#{scope}) to create them"
    end
  end

  attr_accessor :template, :weak_offset, :days_of_the_weak,:show_adjacent_months, :adjacent_days_change_month, :done_rendering, :events, :constraints
  attr_reader :name



  def initialize(name)
    @name = name.to_s
    @template = @@template
    @weak_offset = @@weak_offset
    @start_with_month =@@start_with_month
    @days_of_the_weak = @@days_of_the_weak
    @click_events = @@click_events.clone
    @targets= @@targets.clone
    @show_adjacent_months= @@show_adjacent_months
    @adjacent_days_change_month = @@adjacent_days_change_month
    @done_rendering = @done_rendering
    @constraints =@@constraints
    @force_six_rows =@@force_six_rows
    @has_multiday= false
    @events =[]
  end

  #   return html of calendar
  def view(args)
    content_tag(:div,nil,args)do
      content_tag(:div,nil,id:"#{@name}-clndr",class:'clearfix')+
      javascript_tag("var #{@name} = $('##{@name}-clndr').clndr({
        #{'template:'+@template+',' if !@template.nil?}
        #{'weekOffset:'+@weak_offset.to_s+',' if @weak_offset}
        #{'startWithMonth:\''+@start_with_month.to_s+'\',' if !@start_with_month.nil?}
        #{'daysOfTheWeek:'+@days_of_the_weak.to_s+',' if !@days_of_the_weak.nil?}
        #{build_from_hash(@click_events,'clickEvents')}
        #{build_from_hash_safety(@targets,'targets')}
        #{'showAdjacentMonths:'+@show_adjacent_months.to_s+',' if !@show_adjacent_months}
        #{'adjacentDaysChangeMonth:'+@adjacent_days_change_month.to_s+',' if @adjacent_days_change_month}
        #{'doneRendering:'+@done_rendering+',' if !@done_rendering.nil?}
        #{'forceSixRows:'+@force_six_rows.to_s+',' if @force_six_rows}
        #{ if @constraints.length >0
             build_from_hash_safety @constraints, 'constraints'
           end}
        #{if @has_multiday
          "multiDayEvents: {
            startDate: 'startDate',
            endDate: 'endDate'
          },"
                   end}
        #{if @events.length > 0
            'events:['+build_events(@events)+']'
          end}
          });")


      end
  end

  # if date is instance of Time convert to "YYYY-MM-DD" формат
  def start_with_month=(date)
    if date.class == Time
      @start_with_month= date.strftime("%F")
    else
      @start_with_month = date
    end
  end

  def click_event
    @click_events
  end

  def target
    @targets
  end

  def add_event(date,title,*other_data)
    date = format_date date
    event = {date: date,title:title}
    event.merge! *other_data
    @events.push event
  end

  def add_multiday_event(start_date,end_date,title,*other_data)
    start_date = format_date start_date
    end_date = format_date end_date
    event = {start_date:start_date,end_date:end_date,title:title}
    event.merge! *other_data
    @has_multiday ||= true
    @events.push event
  end

  private

    def build_from_hash(hash, parametr)
      if hash.length > 0
        "#{parametr}: {#{hash.map{|k,v|"#{k}:#{v},"}.join()}},"
      end
    end

  def build_from_hash_safety(hash, parametr)
    if hash.length > 0
      "#{parametr}: {#{hash.map{|k,v|"#{k}:'#{v}',"}.join()}},"
    end
  end

  def build_events(array_of_events)
    list_of_events=''
    array_of_events.each do |event|
      list_of_events +="{#{'date:\''+event.delete(:date)+'\',' if !event[:date].nil?}
                          #{'startDate: \''+event.delete(:start_date)+'\','+
                            'endDate: \'' + event.delete(:end_date)+'\','if !event[:start_date].nil?}
                          title: '#{event.delete(:title)}',
                          #{event.map{|k,v| "#{k}:'#{v}'"}.join(',')}},"
    end
    list_of_events
  end

  def format_date(date)
    if date.class == Time
      date.strftime("%F")
    elsif date.match(/\d{4}\-\d{2}\-\d{2}/)
      date
    else
      raise Clndr::Error::WrongDateFormat
    end
  end

end
