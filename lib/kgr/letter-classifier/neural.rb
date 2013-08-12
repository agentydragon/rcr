require 'yaml'

require 'kgr/classifier/neural'

require 'kgr/data/image'
require 'kgr/data/integer_raw_dataset'
require 'fileutils'

module KGR
	module LetterClassifier
		class Neural
			def self.convert_data_for_eblearn(source_dir, target_dir)
				indexes = {}

				Dir["#{source_dir}/*"].each do |sample_dir|
					desc = YAML.load_file(File.join(sample_dir, "data.yml"))

					# Create list of letter codes contained in the file.
					letters = []
					desc["segments"].each do |segment|
						letters += (segment["first"]..segment["last"]).to_a.map(&:ord)
					end

					image = Data::Image.load(File.join(sample_dir, "data.png"))

					data = image.crop_by_columns(letters.count, desc["cell_height"])

					# cell_index = 1

					# Make it so that the data is indexed by letter.
					data.each_index do |index|
						letter = letters[index].chr

						images = data[index]

						images.each do |img|
							indexes[letter] ||= 0
							FileUtils.mkdir_p(File.join(target_dir, letter))
							path = File.join(target_dir, letter, "#{indexes[letter]}.png")
							indexes[letter] += 1

							img.save(path)
						end
					end
				end
			end

			def self.prepare_data(source_dir, target_file)
				data_by_letter = {}

				Dir["#{source_dir}/*"].each do |sample_dir|
					desc = YAML.load_file(File.join(sample_dir, "data.yml"))

					# Create list of letter codes contained in the file.
					letters = []
					desc["segments"].each do |segment|
						letters += (segment["first"]..segment["last"]).to_a.map(&:ord)
					end

					image = Data::Image.load(File.join(sample_dir, "data.png"))

					data = image.crop_by_columns(letters.count, desc["cell_height"])

					# cell_index = 1

					# Make it so that the data is indexed by letter.
					data.each_index do |index|
						letter = letters[index]
						unless data_by_letter.key?(letter)
							data_by_letter[letter] = []
						end

						images = data[index]

						# ci = cell_index
						data_by_letter[letter] += images.map { |img|
							cell_data = NeuralNet.image_to_input(img)
							# img.save("pristine_#{ci}.png")
							# ci += 1

							cell_data
						}

						0.times { |mutation|
							# ci = cell_index
							data_by_letter[letter] += images.map { |img|
								mutated = img.mutate
								cell_data = NeuralNet.image_to_input(mutated)
								# mutated.save("mutated_#{ci}_#{mutation}.png")
								# ci += 1

								cell_data
							}
						}

						# cell_index = ci
					end
				end

				dataset = Data::IntegerRawDataset.new(data_by_letter)
				dataset.save(target_file)
			end

			def self.data_inputs_size(data)
				# p data.keys.first
				inputs = data[data.keys.first]
				# puts "inputs first: #{inputs.first.inspect}"
				size = inputs.first.size
				size
			end

			def train(dataset_file)
				puts "Training neural net for letters"

				data = {}
				
				# TODO: Pridej normalizaci kontrastu. Pridej dalsi parametry?
				data = Data::IntegerRawDataset.load(dataset_file, KGR::Data::NeuralNetInput)

				# Restrict keys to A..Z
				keys = data.keys
				#allowed = Set.new(('0'..'9').to_a + ('A'..'Z').to_a)
				allowed = ('A'..'Z').to_a
				for k in keys
					unless allowed.include?(k.chr)
						data.delete k
					end
				end

				num_inputs = self.class.data_inputs_size(data)
				puts "num_inputs: #{num_inputs}"
				@classifier = Classifier::Neural.create(num_inputs: num_inputs, hidden_neurons: [ 14*14, 9*9 ], classes: allowed.to_a.map(&:ord))
				@classifier.train(data, generations: 100)
			end

			def save(filename)
				@classifier.save(filename)
			end

			def initialize(classifier = nil)
				@classifier = classifier
			end

			def self.load(filename)
				self.new(Classifier::Neural.load(filename))		
			end

			def classify(image)
				result = @classifier.classify(NeuralNet.image_to_input(image).data)
				# filename = "#{result.chr}-#{Time.now.to_i}.png"
				# image.save(filename)
				result
			end

			def classify_with_score(image)
				result = @classifier.classify_with_score(NeuralNet.image_to_input(image).data)
				# filename = "#{result.chr}-#{Time.now.to_i}.png"
				# image.save(filename)
				result
			end
		end
	end
end
