# coding: utf-8

require 'csv'
require 'yaml'

module Ting
  module Conversions
    All=[]

    DATA_DIR=File.dirname(__FILE__)+'/data/'

    #Load various representations for initials and finals
    %w(Initial Final).each do |c|
      klazz=Ting.const_get c
      begin
        CSV.open(DATA_DIR+c.downcase+'.csv', 'r:utf-8').each do |name, *values|
          next if name == "name"
          All << name.to_s unless All.include?(name) || name =~ /standalone/i
          klazz.class_eval {attr_accessor name.to_sym}
          values.each_with_index do |v,i|
            klazz::All[i].send(name+'=', v && v.force_encoding('UTF-8'))
          end
        end
      rescue
        STDERR << "Bad data in #{c.downcase}.csv : #{$!}"
        raise
      end

    end

    #Substitution rules
    @@rules=YAML::load(IO.read(DATA_DIR+'rules.yaml'))

    def self.parse(type, string)
      capitalized = (string.downcase != string && string.downcase.capitalize == string)
      string = string.to_s.downcase
      if (final = Final::All.find {|f| f.respond_to?("#{type}_standalone") && f.send("#{type}_standalone") == string})
        Syllable.new(Initial::Empty, final, nil, capitalized)
      else
        finals = Final::All.dup
        finals.unshift(finals.delete(Final::Uo)) #hack : move Uo to the front
                                                 #otherwise wadegiles parses 'lo' as Le+O rather than Le+Uo
                                                 #probably better to add a hardcoded 'overrule' table for these cases
        Initial.each do |ini|
          finals.each do |fin|
            next if Syllable.illegal?(ini,fin)
            if string == apply_rules(type, (ini.send(type)||'') + (fin.send(type)||''))
              return Syllable.new(ini, fin, nil, capitalized)
            end
          end
        end
        raise "Can't parse `#{string.inspect}'"
      end
    end

    def self.unparse(type, tsyll)
      str = if tsyll.initial.send(type)
              apply_rules(type, tsyll.initial.send(type) + (tsyll.final.send(type) || ''))
            elsif tsyll.final.respond_to?(type.to_s+'_standalone') && standalone = tsyll.final.send(type.to_s+'_standalone')
              standalone
            else
              apply_rules(type, tsyll.final.send(type))
            end
      (tsyll.capitalized? ? str.capitalize : str).force_encoding('UTF-8')
    end

    def self.tokenize(str)
      [].tap do |tokens|
        str,pos = str.dup, 0
        while str && token = str[/[^' ]*/]
          tokens << [token.strip, pos]
          pos += token.length
          str = str[/[' ]+(.*)/, 1]
        end
      end
    end

    private
      def self.apply_rules(type, string)
        string.dup.tap do |s|
          @@rules[type] && @@rules[type].each do |rule|
            s.gsub!(Regexp.new(rule['match']), rule['subst'])
          end
        end
      end

  end
end
