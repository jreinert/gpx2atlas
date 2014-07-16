require "gpx2atlas/version"
require "gpx2atlas/bounding_box"
require "gpx"

module Gpx2Atlas
  include GPX

  def self.coverage_layer(gpx_file, options)
    gpx = GPXFile.new(gpx_file: gpx_file)
    medium_size = {
      width: options[:medium_size][:width] * (1 - options[:overlap][:x]),
      height: options[:medium_size][:height] * (1 - options[:overlap][:y])
    }

    bboxes = []
    points = gpx.tracks.first.points.map {|p| [p.lat, p.lon]}

    range = 0...points.size

    loop do
      bbox, count = BoundingBox.best_fit(points[range],
                                         medium_size: medium_size,
                                         scale: options[:scale])
      bboxes << bbox

      break unless (range.begin...range.end).include?(range.begin + count)

      range = (range.begin + count - 1)...range.end
    end

    result = GPXFile.new
    result.waypoints = bboxes.map do |bbox|
      waypoint = Waypoint.new
      waypoint.lat = bbox.lat_deg
      waypoint.lon = bbox.lon_deg

      waypoint
    end

    result
  end

end
