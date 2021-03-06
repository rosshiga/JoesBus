#!/usr/bin/env ruby -w
require 'net/https'
require 'yaml'
require 'nokogiri'

module JoesBus
  HEA_API_URL = "api.thebus.org"
  HEA_REQUEST_TYPE_ARRIVALS = "arrivals"
  HEA_REQUEST_TYPE_VEHICLE  = "vehicle"

  CLIENT_ENV = "development"
  APP_ROOT = File.expand_path(File.dirname(__FILE__))
  CONFIG_ROOT = APP_ROOT + "/config"
  
  class Client
    attr_reader :config
    
    class << self
      def slurp_config
        raw_config = File.read "#{CONFIG_ROOT}/config.yml"
        YAML.load(raw_config)[CLIENT_ENV]
      end

      def api_url api_key, request_type, params
        "http://#{HEA_API_URL}/#{request_type}/?key=#{api_key}#{params}"
      end

      def response_for url
        uri = URI.parse url
        http = Net::HTTP.new uri.host, uri.port

        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request request
      end
    end
    
    def initialize(opts={})
      @user_config = self.class.slurp_config || {}
      @config = {}
      @config[:api_key] = opts[:app_token]
      @config[:api_key] ||= @user_config[:hea] ? @user_config[:hea][:api_key] : nil
      if @config[:api_key].nil?
        puts "You really need a TheBus HEA API Key to proceed."
        puts "Apply for one and put it in the config.yml file."
        exit
      end
    end

    def response_for request_type, params
      puts "using api key: #{@config[:api_key]}"
      url = self.class.api_url @config[:api_key], request_type, params
      puts "url is: #{url}"
      response = self.class.response_for url
      { body: response.body,
        code: response.code,
        msg: response.msg }
    end

    def arrivals_at_stop stop_id
      response = response_for HEA_REQUEST_TYPE_ARRIVALS, "&stop=#{stop_id}"
      doc = Nokogiri.XML response[:body]
      doc.xpath("//arrival")
    end

    def vehicles_with_num vehicle_num
      response = response_for HEA_REQUEST_TYPE_VEHICLE, "&num=#{vehicle_num}"
      doc = Nokogiri.XML response[:body]
      doc.xpath("//vehicle")
    end

  end
end
