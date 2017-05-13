module App::ConstGetters
  def installers; App::Installers; end
  def google; App::Google; end
  def screen_width; TermInfo.screen_width; end
  def google_hit; App::Google::Hit; end  
  def browser; App::Browser; end
  def angel_list; App::Career::JobSearchEngine::AngelList; end
  def crunchbase; App::Career::JobSearchEngine::Crunchbase; end
end