public class TranslateWindow : Gtk.ApplicationWindow {


    private Yandex.TranslationService service;
    private Yandex.DictionaryService _dictService;

    private GlobalSettings global = GlobalSettings.instance();

    private Gtk.Box _headerPane;                                 // Header layout

    private Gtk.HeaderBar _leftHeader;
    private Gtk.Button changeButton;
    private Gtk.ComboBox leftLangCombo;
    private Gtk.ComboBox rightLangCombo;
    private Gtk.ListStore langStore;
    private Gtk.ToggleButton voiceButton;
    private Gtk.ToggleButton dictButton;
    private Gtk.ToggleButton settingsButton;

    private Gtk.Separator _headerSeparator;
    private Gtk.HeaderBar _rightHeader;
    private Gtk.Entry _wordInput;
    private Gtk.Button _searchWordButton;

    private Gtk.Box _contentBox;
    private Gtk.Box _leftBox;
    private Gtk.Separator _contentSeparator;
    private Gtk.TextView topText;
    private Gtk.TextView bottomText;
    private Gtk.Label topLabelLen;
    private Gtk.Label topLabelLang;
    private Gtk.Label bottomLabelLang;

    private Gtk.Box _rightBox;
    private Gtk.TextView _dictText;
    private Gtk.TextTag _headerTag;
    private Gtk.TextTag _normalTag;
    private Gtk.Label _dictLangLabel;

    private static int DEFAULT_WIDTH = 0;
    private static int DEFAULT_HEIGHT = 640;

    private const int MAX_CHARS = 500;                                 // Max size of translating text

    private Language[] langs;

    private string leftLang;
    private string rightLang;
    
    private string _cssStyle = """
    GtkWindow
    {
        border-color: #333333;
        border-style: solid;
        border-width: 1px;
    }
    """;

    public TranslateWindow() {
        ApplyCss();
        
        langs = global.getLangs();

        service = new Yandex.TranslationService();
        service.result.connect(onTranslate);

        _dictService = new Yandex.DictionaryService();
        _dictService.result.connect(OnDictResult);

        this.window_position = Gtk.WindowPosition.CENTER;
        this.set_gravity(Gdk.Gravity.CENTER);
        this.set_resizable(false);
        this.set_decorated(true);

        Gdk.RGBA bgColor = Gdk.RGBA();
        bgColor.red = 1;
        bgColor.green = 1;
        bgColor.blue = 1;
        bgColor.alpha = 1;

        _headerPane = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

        // Left header
        _leftHeader = new Gtk.HeaderBar ();
        _leftHeader.set_show_close_button (true);

        leftLangCombo = new Gtk.ComboBox();
        var renderer = new Gtk.CellRendererText ();
        leftLangCombo.pack_start (renderer, true);
        leftLangCombo.add_attribute (renderer, "text", 0);
        leftLangCombo.active = 0;


	    rightLangCombo = new Gtk.ComboBox();
        rightLangCombo.set_margin_right(10);
        rightLangCombo.pack_start (renderer, true);
        rightLangCombo.add_attribute (renderer, "text", 0);
        rightLangCombo.active = 0;

        changeButton = new Gtk.Button();
        changeButton.set_image(Assets.getImage("images/loop.svg"));
        changeButton.set_tooltip_text(_("Switch language"));
        changeButton.clicked.connect(onSwap);

        voiceButton = new Gtk.ToggleButton();
        voiceButton.set_image (Assets.getImage("images/mic.svg"));
        voiceButton.set_tooltip_text(_("Dictation"));

        dictButton = new Gtk.ToggleButton();
        dictButton.set_image (Assets.getImage("images/book.svg"));
        dictButton.set_tooltip_text(_("Dictionary"));
        dictButton.toggled.connect(OnDictToggle);

        settingsButton = new Gtk.ToggleButton();
        settingsButton.set_image (Assets.getImage("images/cog.svg"));
        settingsButton.set_tooltip_text(_("Settings"));

        _leftHeader.pack_start(leftLangCombo);
        _leftHeader.pack_start(changeButton);
        _leftHeader.pack_start(rightLangCombo);
        _leftHeader.set_custom_title(new Gtk.Label(""));
        _leftHeader.pack_start(dictButton);

        // Right dictionary header
        _rightHeader = new Gtk.HeaderBar ();
        _rightHeader.set_show_close_button (false);
        _rightHeader.set_custom_title(new Gtk.Label(""));
        _wordInput = new Gtk.Entry();
        _wordInput.set_size_request(200,20);
        _wordInput.activate.connect(OnDictSearch);
        _searchWordButton = new Gtk.Button();
        _searchWordButton.set_image(Assets.getImage("images/search.svg"));
        _searchWordButton.set_tooltip_text(_("Search"));
        _searchWordButton.clicked.connect(OnDictSearch);

        _rightHeader.pack_start(new Gtk.Label(_("Dictionary")));
        _rightHeader.pack_end(_searchWordButton);
        _rightHeader.pack_end(_wordInput);

        _headerSeparator = new Gtk.Separator(Gtk.Orientation.VERTICAL);

        _headerPane.pack_start (_leftHeader, true, true, 0);
        _headerPane.pack_start (_rightHeader, true, true, 0);

        this.set_titlebar (_headerPane);
        this.set_size_request (DEFAULT_WIDTH, DEFAULT_HEIGHT);
        rightLangCombo.set_size_request (110, 30);
        leftLangCombo.set_size_request (110, 30);

        var fd = new Pango.FontDescription();
        fd.set_size(10000);

        // Content
        _contentBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        _leftBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        _leftBox.expand = true;
        _rightBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        _contentSeparator = new Gtk.Separator(Gtk.Orientation.VERTICAL);
        _contentSeparator.get_style_context().add_class("dark-separator");

        _contentBox.pack_start(_leftBox, false, true);
        _contentBox.pack_start(_contentSeparator, false, false);
        _contentBox.pack_start(_rightBox, true, true);

        var paned = new Gtk.Paned(Gtk.Orientation.VERTICAL);
        paned.override_background_color(Gtk.StateFlags.NORMAL, bgColor);
        _leftBox.pack_start(paned);

        topText = new Gtk.TextView();
        topText.set_margin_left(7);
        topText.set_margin_top(7);
        topText.set_margin_right(7);
        topText.override_font(fd);
        topText.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);
        topText.buffer.changed.connect(onUpdate);
        var topScroll = new Gtk.ScrolledWindow (null, null);
        topScroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        topScroll.add (topText);

        bottomText = new Gtk.TextView();
        bottomText.set_editable(false);
        bottomText.set_margin_top(7);
        bottomText.set_margin_right(7);
        bottomText.set_margin_left(7);
        bottomText.override_font(fd);
        bottomText.set_cursor_visible(false);
        bottomText.set_wrap_mode(Gtk.WrapMode.WORD_CHAR);

        var bottomScroll = new Gtk.ScrolledWindow (null, null);
        bottomScroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        bottomScroll.add (bottomText);

        var topBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        var topLabelBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        topLabelLang = new Gtk.Label("");
        topLabelLang.set_margin_bottom(3);

        topLabelLen = new Gtk.Label("");
        topLabelLen.set_markup(@"<span size=\"small\" color=\"#555555\">0/$MAX_CHARS</span>");
        topLabelLen.set_margin_bottom(3);

        topLabelBox.pack_start(topLabelLang, false, true, 5);
        topLabelBox.pack_end(topLabelLen, false, true, 5);

        topBox.pack_start(topScroll);
        topBox.pack_start(topLabelBox, false, true, 0);

        var bottomBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        var bottomLabelBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        bottomLabelLang = new Gtk.Label("");
        bottomLabelLang.set_margin_bottom(3);
        bottomLabelBox.pack_start(bottomLabelLang, false, true, 5);

        bottomBox.pack_start(bottomScroll);
        bottomBox.pack_start(bottomLabelBox, false, true, 0);

        paned.pack1(topBox, true, true);
        paned.pack2(bottomBox, true, true);

        var dictBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        var dictLabelBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var bgColor2 = Gdk.RGBA();
        bgColor.red = 0.9;
        bgColor.green = 0.9;
        bgColor.blue = 0.9;
        bgColor.alpha = 1;
        _dictText = new Gtk.TextView();
        _dictText.set_editable(false);
        _dictText.set_margin_top(7);
        _dictText.set_margin_right(7);
        _dictText.set_margin_left(7);
        _dictText.set_wrap_mode(Gtk.WrapMode.WORD);
        _dictText.set_cursor_visible(false);
        var dictScroll = new Gtk.ScrolledWindow (null, null);
        dictScroll.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        _dictText.override_background_color(Gtk.StateFlags.NORMAL, bgColor2);
        dictScroll.override_background_color(Gtk.StateFlags.NORMAL, bgColor2);
        dictScroll.add (_dictText);

        _dictLangLabel = new Gtk.Label("");
        _dictLangLabel.set_markup(@"<span size=\"small\" color=\"#555555\">en-ru</span>");
        _dictLangLabel.set_margin_bottom(3);
        dictLabelBox.pack_start(_dictLangLabel, false, true, 5);

        dictBox.pack_start(dictScroll);
        dictBox.pack_start(dictLabelBox, false, true, 0);
        _rightBox.pack_start(dictBox);
        _headerTag = _dictText.buffer.create_tag("h", null);
        _headerTag.size_points = 10;
        _headerTag.weight = 700;
        _normalTag = _dictText.buffer.create_tag("n", null);

        this.add(_contentBox);

        populateLangs();
        refreshLangLabels();

        HideDictionary();

        this.destroy.connect(OnWindowDestroy);
    }
    
    // Apply css style
    private void ApplyCss() {
        var provider = new Gtk.CssProvider();
        provider.load_from_data(_cssStyle, _cssStyle.length);
        var screen = get_screen();
        Gtk.StyleContext.add_provider_for_screen(screen, provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);      
    }

    private void OnDictToggle() {
      if (!dictButton.active) {
        HideDictionary();
      } else {
        ShowDictionary();
      }
    }

    private void ShowDictionary() {
      _rightHeader.no_show_all = false;
      _rightHeader.show_all();
      _rightBox.no_show_all = false;
      _rightBox.show_all();
      _contentSeparator.no_show_all = false;
      _contentSeparator.show_all();
    }

    private void HideDictionary() {
      _rightHeader.no_show_all = true;
      _rightHeader.hide();
      _rightBox.no_show_all = true;
      _rightBox.hide();
      _contentSeparator.no_show_all = true;
      _contentSeparator.hide();
    }

    private void populateLangs() {
        langStore = new Gtk.ListStore (2, typeof (string), typeof (string));
		    Gtk.TreeIter iter;

        foreach (var l in langs) {
            langStore.append (out iter);
            langStore.@set (iter, 0, l.name, 1, l.id);
        }

        leftLangCombo.set_model(langStore);
        rightLangCombo.set_model(langStore);

        leftLangCombo.set_id_column(1);
        rightLangCombo.set_id_column(1);

        var leftInd = global.getLangIndex(global.getSourceStartLang());
        var rightInd = global.getLangIndex(global.getDestStartLang());

        leftLangCombo.active = leftInd;
        rightLangCombo.active = rightInd;

        leftLangCombo.changed.connect(onLeftComboChange);
		    rightLangCombo.changed.connect(onRightComboChange);

        leftLang = getLeftId();
        rightLang = getRightId();
    }

    private void ClearDictText() {
      _wordInput.set_text("");
      _dictText.buffer.text = "";
    }

    private void refreshLangLabels() {
        var llang = getLeftLang();
        var rlang = getRightLang();
        topLabelLang.set_markup(@"<span size=\"small\" color=\"#555555\">$llang</span>");
        bottomLabelLang.set_markup(@"<span size=\"small\" color=\"#555555\">$rlang</span>");
        _dictLangLabel.set_markup(@"<span size=\"small\" color=\"#555555\">$llang - $rlang</span>");
    }


    private string getLeftId() {
        Value val;
        Gtk.TreeIter iter;
        leftLangCombo.get_active_iter (out iter);
        langStore.get_value(iter, 1, out val);
        return (string)val;
    }

    private string getLeftLang() {
        Value val;
        Gtk.TreeIter iter;
        leftLangCombo.get_active_iter (out iter);
        langStore.get_value(iter, 0, out val);
        return (string)val;
    }

    private string getRightId() {
        Value val;
        Gtk.TreeIter iter;
        rightLangCombo.get_active_iter (out iter);
        langStore.get_value(iter, 1, out val);
        return (string)val;
    }

    private string getRightLang() {
        Value val;
        Gtk.TreeIter iter;
        rightLangCombo.get_active_iter (out iter);
        langStore.get_value(iter, 0, out val);
        return (string)val;
    }

    private void onLangChange(bool isRight) {
        var leftId = getLeftId();
        var rightId = getRightId();

        var needUpdate = true;

        if (leftId == rightId) {
            needUpdate = false;
            if (isRight) {
                leftLang = rightLang;
                leftLangCombo.set_active_id(rightLang);
            } else {
                rightLang = leftLang;
                rightLangCombo.set_active_id(leftLang);
            }

            topText.buffer.text = bottomText.buffer.text;
        }

        if (needUpdate) {
            leftLang = leftId;
            rightLang = rightId;
            ClearDictText();
            refreshLangLabels();
            onUpdate();
        }
    }

    private void onLeftComboChange() {
        onLangChange(false);
    }

    private void onRightComboChange() {
        onLangChange(true);
    }

    private void onSwap() {
        var id = getLeftId();
        rightLangCombo.set_active_id(id);
    }

    private void onUpdate() {

        if (topText.buffer.text.length < 1) {
            bottomText.buffer.text = "";
            topLabelLen.set_markup(@"<span size=\"small\" color=\"#555555\">0/$MAX_CHARS</span>");
            return;
        }

        if ((leftLang == null) || (rightLang == null))
            return;
        service.update(leftLang, rightLang, topText.buffer.text);
        var len = topText.buffer.text.length;
        if (len > MAX_CHARS) {
            var txt = topText.buffer.text.slice(0, MAX_CHARS);
            topText.buffer.set_text(txt, MAX_CHARS);
            return;
        }
        topLabelLen.set_markup(@"<span size=\"small\" color=\"#555555\">$len/$MAX_CHARS</span>");
    }

    private void onTranslate(string text) {
        if ((text == null) || (text.length < 1))
            return;
        lock (bottomText) {
            bottomText.buffer.text = topText.buffer.text.length > 1 ? text : "";
        }
    }

    // Search in dictionary
    private void OnDictSearch() {
      var text = _wordInput.get_text();
      _dictService.GetWordInfo(text, leftLang, rightLang);
    }

    private void OnDictResult(WordInfo data) {
      _dictText.buffer.text = "";
      Gtk.TextIter iter;
      _dictText.buffer.get_end_iter(out iter);

      foreach (var c in data.WordCategories) {
        string txt = Yandex.DictionaryService.GetSpeechPart(c.Category) + "\n";

        _dictText.buffer.insert_with_tags(ref iter, txt, txt.length, _headerTag, null);
        _dictText.buffer.insert_with_tags(ref iter, "\n", 1, _normalTag, null);

        for (var i =0; i<c.Translations.length;i++) {
          var tr = c.Translations[i];
          txt = @"$(i+1). $(tr.Text)\n";
          _dictText.buffer.insert_with_tags(ref iter, txt, txt.length, _normalTag, null);
        }
        _dictText.buffer.insert_with_tags(ref iter, "\n", 1, _normalTag, null);
      }
    }

    private void OnWindowDestroy() {
      var global = GlobalSettings.instance();
      global.SaveSourceLang(leftLang);
      global.SaveDestLang(rightLang);
      base.destroy();
    }
}
