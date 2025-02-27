require "jipcode/version"
require "jipcode/address_locator"
require 'csv'
require 'yaml'

module Jipcode
  DATA_PATH = "#{File.dirname(__FILE__)}/../zipcode".freeze
  ZIPCODE_PATH = "#{DATA_PATH}/latest".freeze
  PREVIOUS_PATH = "#{DATA_PATH}/previous".freeze

  PREFECTURE_CODE = YAML.load_file("#{File.dirname(__FILE__)}/../prefecture_code.yml").freeze

  autoload :JapanPost, "jipcode/japan_post"
  autoload :AddressLocator, "jipcode/address_locator"

  def locate(zipcode, opt={})
    # 数字7桁以外の入力は受け付けない
    return [] unless zipcode&.match?(/\A\d{7}?\z/)

    # 上3桁にマッチするファイルが存在しなければ該当なし
    path = "#{ZIPCODE_PATH}/#{zipcode[0..2]}.csv"
    return [] unless File.exist?(path)

    addresses_array = CSV.read(path).select { |address| address[0] == zipcode }

    if opt.empty?
      # optが空の場合、直接basic_address_fromを呼んで不要な判定を避ける。
      addresses_array.map { |address_param| basic_address_from(address_param) }
    else
      addresses_array.map { |address_param| extended_address_from(address_param, opt) }
    end
  end

  def basic_address_from(address_param)
    {
      zipcode:         address_param[0],
      prefecture:      address_param[1],
      city:            address_param[2],
      town:            address_param[3],
      prefecture_kana: address_param[4],
      city_kana:       address_param[5],
      town_kana:       address_param[6],
    }
  end

  def extended_address_from(address_param, opt={})
    address = basic_address_from(address_param)
    address[:prefecture_code] = PREFECTURE_CODE.invert[address_param[1]] if opt[:prefecture_code]
    address
  end

  module_function :locate, :basic_address_from, :extended_address_from
end
