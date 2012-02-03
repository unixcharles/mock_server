test:
	bundle exec ruby spec/record_spec.rb
	bundle exec ruby spec/playback_spec.rb

.PHONY: test
