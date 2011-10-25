# coding: utf-8

class String
  PINYIN_CACHE={}

  def pretty_tones
    self.gsub('u:','ü').gsub(/[A-Za-züÜ]{1,5}\d/) do |m|
      m.downcase!
      PINYIN_CACHE[m] || PINYIN_CACHE[m]=(Ting.writer(:hanyu, :accents) << Ting.reader(:hanyu, :numbers).parse(m.downcase))
    end
  end

  def bpmf
    self.gsub('u:','ü').scan(/[A-Za-züÜ]{1,5}\d/).map do |m|
      Ting.writer(:zhuyin, :marks) << 
        (Ting.reader(:hanyu, :numbers) << m.downcase)
    end.join(' ')
  end
end
