# frozen_string_literal: true

module CappuccinoHelper
  VIEW_WALK_JS = <<~JS
    function cappViews(pred) {
      var acc  = [];
      var app  = objj_msgSend(objj_getClass("CPApplication"), "sharedApplication");
      var wins = objj_msgSend(app, "windows");
      var nWin = objj_msgSend(wins, "count");
      function walk(view) {
        if (!view || !view.isa) return;
        try { if (pred(view)) acc.push(view); } catch (e) {}
        var subs = objj_msgSend(view, "subviews");
        if (!subs) return;
        var n = objj_msgSend(subs, "count");
        for (var i = 0; i < n; i++) walk(objj_msgSend(subs, "objectAtIndex:", i));
      }
      for (var w = 0; w < nWin; w++) {
        walk(objj_msgSend(objj_msgSend(wins, "objectAtIndex:", w), "contentView"));
      }
      return acc;
    }
    function cappIsKind(view, className) {
      return objj_msgSend(view, "isKindOfClass:", objj_getClass(className));
    }
  JS

  def wait_for_cappuccino(wait: Capybara.default_max_wait_time)
    poll("wait_for_cappuccino", wait) do
      page.evaluate_script(<<~JS)
        (function() {
          if (typeof objj_getClass !== "function") return false;
          var cls = objj_getClass("CPApplication");
          if (!cls) return false;
          var app = objj_msgSend(cls, "sharedApplication");
          return !!app && objj_msgSend(objj_msgSend(app, "windows"), "count") > 0;
        })();
      JS
    end
  end

  def cappuccino_text_values
    page.evaluate_script(<<~JS)
      (function() {
        #{VIEW_WALK_JS}
        return cappViews(function(v) { return cappIsKind(v, "CPTextField"); })
          .map(function(v) { return String(objj_msgSend(v, "stringValue")); });
      })();
    JS
  end

  def wait_for_cappuccino_text(text, wait: Capybara.default_max_wait_time)
    poll("wait_for_cappuccino_text(#{text.inspect})", wait) do
      cappuccino_text_values.include?(text)
    end
  end

  def cappuccino_button_visible?(title)
    page.evaluate_script(<<~JS, title)
      (function(wanted) {
        #{VIEW_WALK_JS}
        return cappViews(function(v) {
          return cappIsKind(v, "CPButton") &&
                 objj_msgSend(v, "title") == wanted &&
                 !objj_msgSend(v, "isHiddenOrHasHiddenAncestor");
        }).length > 0;
      })(arguments[0]);
    JS
  end

  def wait_for_cappuccino_button(title, wait: Capybara.default_max_wait_time)
    poll("wait_for_cappuccino_button(#{title.inspect})", wait) do
      cappuccino_button_visible?(title)
    end
  end

  def click_cappuccino_button(title)
    result = page.execute_script(<<~JS, title)
      return (function(wanted) {
        #{VIEW_WALK_JS}
        var buttons = cappViews(function(v) {
          return cappIsKind(v, "CPButton") && objj_msgSend(v, "title") == wanted;
        });
        if (buttons.length == 0) return "no CPButton titled '" + wanted + "'";
        var target = objj_msgSend(buttons[0], "target");
        var action = objj_msgSend(buttons[0], "action");
        if (!target || !action) return "button has no target/action";
        objj_msgSend(target, action, buttons[0]);
        return "ok";
      })(arguments[0]);
    JS
    raise "click_cappuccino_button(#{title.inspect}): #{result}" unless result == 'ok'
  end

  def cappuccino_main_menu_titles
    page.evaluate_script(<<~JS)
      (function() {
        var app   = objj_msgSend(objj_getClass("CPApplication"), "sharedApplication");
        var menu  = objj_msgSend(app, "mainMenu");
        if (!menu) return [];
        var items = objj_msgSend(menu, "itemArray");
        var out   = [];
        for (var i = 0; i < objj_msgSend(items, "count"); i++) {
          out.push(String(objj_msgSend(objj_msgSend(items, "objectAtIndex:", i), "title")));
        }
        return out;
      })();
    JS
  end

  def cappuccino_menu_bar_visible?
    page.evaluate_script('objj_msgSend(objj_getClass("CPMenu"), "menuBarVisible") ? true : false;')
  end

  private

  def poll(what, wait)
    deadline = Time.now + wait
    loop do
      return true if yield
      raise "#{what}: not satisfied after #{wait}s" if Time.now > deadline

      sleep 0.1
    end
  end
end
