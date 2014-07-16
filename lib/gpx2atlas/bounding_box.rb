require 'gpx2atlas/util'

module Gpx2Atlas
  class BoundingBox
    include Util

    using Refinements

    attr_reader :lat_deg, :lon_deg, :lat_min, :lat_max, :lon_min, :lon_max

    def initialize(lat_deg, lon_deg, options = {})
      @lat_deg = lat_deg
      @lon_deg = lon_deg

      lat = @lat_deg.to_rad
      lon = @lon_deg.to_rad

      if options[:medium_size] && options[:scale]
        @width = options[:medium_size][:width] / 1000 * options[:scale]
        @height = options[:medium_size][:height] / 1000 * options[:scale]
      else
        @width = options[:size][:width]
        @height = options[:size][:height]
      end

      radius = WGS84.earth_radius(lat)
      pradius = radius * Math.cos(lat)

      @lat_min = lat - @height / 2.0 / radius
      @lat_max = lat + @height / 2.0 / radius
      @lon_min = lon - @width / 2.0 / pradius
      @lon_max = lon + @width / 2.0 / pradius
    end

    def scale(horizontal, vertical)
      BoundingBox.new(@lat_deg, @lon_deg, size: {
        width: @width * horizontal,
        height: @height * vertical
      })
    end

    def move_percent!(x, y)
      lat_deg_delta = (@lat_max - @lat_min).to_deg * x
      lon_deg_delta = (@lon_max - @lon_min).to_deg * y
      move!(lat_deg_delta, lon_deg_delta)
    end

    def move!(lat_deg_delta, lon_deg_delta)
      new_bbox = BoundingBox.new(@lat_deg + lat_deg_delta,
                                 @lon_deg + lon_deg_delta,
                                 size: {width: @width, height: @height})
      @lat_deg = new_bbox.lat_deg
      @lon_deg = new_bbox.lon_deg
      @lat_min = new_bbox.lat_min
      @lat_max = new_bbox.lat_max
      @lon_min = new_bbox.lon_min
      @lon_max = new_bbox.lon_max

      self
    end

    def move(lat_deg_delta, lon_deg_delta)
      self.dup.move!(lat_deg_delta, lon_deg_delta)
    end

    def move_percent(x, y)
      self.dup.move_percent!(x, y)
    end

    def includes?(lat_deg, lon_deg)
      lat = lat_deg.to_rad
      lon = lon_deg.to_rad

      lat >= @lat_min && lat <= @lat_max && lon >= @lon_min && lon <= @lon_max
    end

    def self.fit(coordinates, options = {})
      result = BoundingBox.new(coordinates.first[0], coordinates.first[1], options)
      last_coord = coordinates.first
      coordinates[1..-1].each_with_index do |(lat_deg, lon_deg), i|
        unless result.includes?(lat_deg, lon_deg)
          lat_deg_delta = lat_deg - last_coord[0]
          lon_deg_delta = lon_deg - last_coord[1]

          new_box = result.move(lat_deg_delta, lon_deg_delta)

          unless coordinates[0..i].all? {|coord| new_box.includes?(coord[0], coord[1])}
            return false
          end

          result = new_box
        end

        last_coord = [lat_deg, lon_deg]
      end

      result
    end

    def self.best_fit(coordinates, options = {})
      max = coordinates.size

      bbox = fit(coordinates[0...max], options)

      until bbox
        max /= 2
        bbox = fit(coordinates[0...max], options)
      end

      while max < coordinates.size
        max += 1
        new_bbox = fit(coordinates[0...max], options)
        new_bbox ? bbox = new_bbox : break
      end

      [bbox, max]
    end

  end
end
