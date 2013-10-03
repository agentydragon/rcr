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
					@segmentation = nil
				end

				def segment
					image = KGR::Data::Image.from_pixmap(pixmap)
					puts "Image loaded, segmenting."
					@segmentation = @segmentator.segment(image)
					puts "Segmented."
					@area.queue_draw_area 0, 0, *@pixmap.size
				end

				def window_height
					128
				end

				def window_width
					window_height * 7
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
					colors = [ [ 65535, 0, 0 ], [ 0, 65535, 0 ], [ 0, 0, 65535 ] ].map { |args| Gdk::Color.new(*args) }

					colors.each { |color| Gdk::Colormap.system.alloc_color(color, false, true) }
					gc = Gdk::GC.new(area.window)

					if @segmentation
						@segmentation.boxes.each_index do |i|
							box = @segmentation.boxes[i]
							color = colors[i % colors.count]
							puts "Printing box #{box.x0} #{box.y0} #{box.x1} #{box.y1}"
							gc.set_foreground color
							area.window.draw_rectangle(gc, false, box.x0, box.y0, box.width, box.height)
						end

						layout = Pango::Layout.new Gdk::Pango.context
						layout.font_description = Pango::FontDescription.new('Sans 14')
						layout.text = "Detected text: #{@segmentation.detected_text(@classifier)}"
						area.window.draw_layout(area.style.fg_gc(Gtk::STATE_NORMAL), 30, window_height + 20, layout)
					end
				end

				def clear_canvas
					puts "clearing canvas"
					@segmentation = nil
					super
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
		end
	end
end