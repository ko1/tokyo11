class I18nHandler
  attr_reader :page, :languages, :default_lang, :pages

  def initialize(page, payload)
    @page, @languages, @pages =
      page, payload['site']['languages'], payload['site']['pages']

    @default_lang = languages.detect {|l| l['default'] } || @languages.first
  end

  def active_language
    @active_language ||= detect_page_language(page)
  end

  def other_languages
    @other_languages ||= languages.select do |lang|
      lang != active_language
    end.each do |lang|
      lang['url'] = lang['path'] + page.url.gsub("/#{active_language['code']}/", "")
    end
  end

  def active_pages
    pages.select do |_page|
      detect_page_language(_page) == active_language
    end.map(&:to_liquid)
  end

  private

  def detect_page_language(page)
    languages.detect do |lang|
      page.permalink.to_s.start_with?("/#{lang['path']}")
    end || @default_lang
  end
end

Jekyll::Hooks.register :pages, :pre_render do |page, payload|
  i18n_handler = I18nHandler.new(page, payload)

  payload['site']['lang'] = i18n_handler.active_language
  payload['site']['active_pages'] = i18n_handler.active_pages
  payload['site']['other_languages'] = i18n_handler.other_languages
end
