require 'kgr/data/image'
require 'kgr/letter-classifier/neural'
require 'kgr/word-segmentator/default'
require 'kgr/gui/drawing-window'

# TODO: write this tool.
# TODO: "make new sample" button.

module KGR
	module GUI
		class SegmentWord
			class Window < KGR::GUI::DrawingWindow
				def initialize(segmentator, classifier)
					super()
					@segmentator = segmentator
					@classifier = classifier
				end

				def segment
					w, h = pixmap.size
					image = pixmap.get_image 0, 0, w, h

					pixels = (0...window_size).map { |x|
						(0...window_size).map { |y|
							pixel = image.get_pixel(x, y)

							# TODO: universalize!
							b = pixel & 0xFF; pixel >>= 8
							g = pixel & 0xFF; pixel >>= 8
							r = pixel & 0xFF

							[ r, g, b ]
						}
					}

					#@letter = @classify_letter.classify(pixels)
					#@area.queue_draw_area 0, 0, *@pixmap.size
				end

				def add_box_controls(box)
					button = Gtk::Button.new("Segment")
					button.signal_connect "clicked" do
						segment
					end
					box.pack_end(button, false, false)
					button.show
				end

				def title
					"Word segmentator"
				end

				def draw_on_area(area)
					#if @letter
					#	layout = Pango::Layout.new Gdk::Pango.context
					#	layout.font_description = Pango::FontDescription.new('Sans 14')
					#	layout.text = "Detected: #@letter"
					#	area.window.draw_layout(area.style.fg_gc(Gtk::STATE_NORMAL), 30, window_size + 20, layout)
					#end
				end
			end

			def initialize(segmentator_path, classifier_path)
				@segmentator = WordSegmentator::Default.load(segmentator_path)
				@classifier = LetterClassifier::Neural.load(classifier_path)
			end

			def run
				Gtk.init
				KGR::GUI::SegmentWord::Window.new(@segmentator, @classifier)
				Gtk.main
			end

			# pixels: 2D array of R-G-B pixels (0..256)
			#def classify(pixels)
			#	img = Data::Image.from_pixel_block(pixels)
			#	@classifier.classify(img).chr
			#end
		end
	end
end