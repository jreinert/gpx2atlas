module Gpx2Atlas
  module Util
    module Refinements
      refine Numeric do

        def to_deg
          180.0 * self / Math::PI
        end

        def to_rad
          Math::PI * self / 180.0
        end

      end
    end

    module WGS84

      # Semi-axes of WGS-84 geoidal reference
      A = 6378137.0  # Major semiaxis
      B = 6356752.3  # Minor semiaxis

      def self.earth_radius(lat)
        a_n = A**2 * Math.cos(lat)
        b_n = B**2 * Math.sin(lat)
        a_d = A * Math.cos(lat)
        b_d = B * Math.sin(lat)

        Math.sqrt((a_n**2 + b_n**2) / (a_d**2 + b_d**2))
      end

    end
  end
end
