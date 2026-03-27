class MokoGrammarService
  # Dynamically transform text to "Moko-style"
  def self.mokofize(text)
    return text if text.blank?
    
    # 1. Simple replacements
    moko_text = text.gsub("です", "でもこ")
                    .gsub("ます", "ますもこ")
                    .gsub("だね", "だもこね")
                    .gsub("だよ", "だもこよ")
    
    # 2. Add random suffix if not already present
    unless moko_text.match?(/(もこ|🐾)[！？。]$/)
      suffixes = ["もこ！", "もこ？", "🐾", "もこもこ！"]
      moko_text += " " + suffixes.sample
    end
    
    moko_text
  end
end
