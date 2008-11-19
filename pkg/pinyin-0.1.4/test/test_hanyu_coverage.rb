require 'test/unit'
require 'pinyin.rb'
require 'yaml'

$KCODE='u'

module HanyuCoverage 
  grid=YAML.load(IO.read(File.dirname(__FILE__)+'/../lib/pinyin/data/valid_pinyin.yaml'))
  grid.each do |fname, row|
    row.each do |iname, hanyu|
      eval %[
        class Test_#{hanyu} < Test::Unit::TestCase
          include Pinyin
          def initialize(s)
            super(s)
            @reader = Reader.new(:hanyu, :no_tones)
            @writer = Writer.new(:hanyu, :no_tones)
          end

          def test_parse_#{hanyu}
            assert_equal('#{hanyu}', @writer.unparse(Syllable.new(Initial::#{iname}, Final::#{fname}, Tones::NEUTRAL_TONE)), 'Wrong hanyu for Initial::#{iname}+Final::#{fname}, expected `#{hanyu}` ')
          end

          def test_unparse_#{hanyu}
            ts=*@reader.parse('#{hanyu}')
            assert_not_nil(ts, 'Reader<:hanyu, :no_tone>#parse("#{hanyu}") returned nil')
            assert_equal(Initial::#{iname}, ts.initial, 'Wrong initial for `#{hanyu}`, expected Initial::#{iname}')
            assert_equal(Final::#{fname}, ts.final, 'Wrong final for `#{hanyu}`, expected Final::#{fname}')
          end
        end
      ]
    end
  end

end
