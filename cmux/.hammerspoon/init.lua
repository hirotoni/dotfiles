hs.hotkey.bind({"alt"}, "space", function()
  local app = hs.application.find("cmux")
  if app and app:isRunning() and #app:allWindows() > 0 then
    if app:isFrontmost() then
      app:hide()
    else
      app:activate()
    end
  else
    hs.application.open("cmux")
  end
end)