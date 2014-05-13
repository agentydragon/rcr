require 'rcr/data/image'
require 'rcr/logging'

module RCR
	module Data
		class Imagelike
			include Logging

			def to_image
				log "Converting imagelike of size #{width}x#{height} to image"
				image = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)
				(0...width).map { |x|
					(0...height).map { |y|
						image[x, y] = ChunkyPNG::Color.rgb(*self[x, y])
					}
				}
				log "Converted image filled."
				Image.new(image)
			end
		end
	end
end
