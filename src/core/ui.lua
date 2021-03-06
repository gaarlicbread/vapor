local ui = {}

ui.images = {}

ui.nogame = love.graphics.newImage("assets/nogame.png")
ui.overlay = love.graphics.newImage("assets/overlay.png")

ui.headerindex = selectindex or 0

ui.snap = 0.01
ui.changespeed = 10
ui.buttonwidth = 210

ui.gameselect_w = (settings.gameshow)*settings.padding
ui.gameselect_h = (settings.gameshow+1)*settings.padding

ui.conditions = {}
ui.conditions.all = function(g) return true end
ui.conditions.favorites = function(g)
  return settings.data.games[g.id].favorite
end
ui.conditions.downloaded = function(g)
  return love.filesystem.exists(vapor.fname(g,g.stable)..".sha1")
end

ui.sorts = {}
ui.sorts.new = function(a,b)
  return a.stable > b.stable
end

function ui.create_list(condition,sort,limit)

  local list = loveframes.Create("columnlist")

  list.OnRowSelected = function(parent, row, data)
    for gi,gv in pairs(remote.data.games) do
      if data[1] == gv.name then
        selectindex = gi
      end
    end
  end

  return ui.update_list(list,condition,sort,limit)
  
end

function ui.update_list(list,condition,sort,limit)

  list:Clear()
  local copy

  if sort then
    copy = {}
    for _,v in pairs(remote.data.games) do
      table.insert(copy,v)
    end
    table.sort(copy,sort)
  end

  local count = 0
  for gi,gv in pairs(copy or remote.data.games) do
    if condition(gv) then
      list:AddRow(gv.name)
      count = count + 1
      if limit and count >= limit then
        return list
      end
    end
  end

  return list
end

function ui.update_ui()
  local gameobj = remote.data.games[selectindex]
  ui.mainbutton:SetVisible(selectindex~=nil)
  ui.progressbar:SetVisible(selectindex~=nil)
  if gameobj then
    local fn = vapor.fname(gameobj,gameobj.stable)
    if vapor.currently_downloading[fn] then
      ui.mainbutton:SetText("Downloading ...")
      ui.mainbutton.icon = icons.downloading[math.floor(downloader.dt*10)%4+1]
      ui.mainbutton_tooltip:SetText("Your game is downloading.")
      ui.progressbar:SetText("33%")
      if ui.progressbar:GetValue() ~= 1 then
        ui.progressbar:SetValue(1)
      end
    elseif vapor.currently_hashing[fn] then
      ui.mainbutton:SetText("Hashing ...")
      ui.mainbutton.icon = icons.hash[math.floor(hasher.dt*10)%4+1]
      ui.mainbutton_tooltip:SetText("Your game is hashing.")
      ui.progressbar:SetText("66%")
      if ui.progressbar:GetValue() ~= 2 then
        ui.progressbar:SetValue(2)
      end
    elseif gameobj.invalid then
      ui.mainbutton:SetText("Error")
      ui.mainbutton.icon = icons.delete
      ui.mainbutton_tooltip:SetText("There has been an error. Click to delete this game.")
      ui.progressbar:SetText("0%")
      if ui.progressbar:GetValue() ~= 0 then
        ui.progressbar:SetValue(0)
      end
    elseif love.filesystem.exists(fn) then
      ui.mainbutton:SetText("Play")
      ui.mainbutton.icon = icons.play
      ui.mainbutton_tooltip:SetText("This game is ready to play.")
      ui.progressbar:SetText("100%")
      if ui.progressbar:GetValue() ~= 3 then
        ui.progressbar:SetValue(3)
      end
    else
      ui.mainbutton:SetText("Download")
      ui.mainbutton.icon = icons.view
      ui.mainbutton_tooltip:SetText("Download this game now.")
      ui.progressbar:SetText("0%")
      if ui.progressbar:GetValue() ~= 0 then
        ui.progressbar:SetValue(0)
      end
    end

    if ui.conditions.favorites(gameobj) then
      ui.buttons.favorite:SetImage(icons.favorite)
    else
      ui.buttons.favorite:SetImage(icons.favorite_off)
    end

    if ui.conditions.downloaded(gameobj) then
      ui.buttons.delete:SetImage(icons.delete)
    else
      ui.buttons.delete:SetImage(icons.delete_off)
    end

    if gameobj.website then
      ui.buttons.visitwebsite:SetImage(icons.website)
    else
      ui.buttons.visitwebsite:SetImage(icons.website_off)
    end

  else
    ui.mainbutton.icon = icons.download
  end
end

function ui.load()

  -- Button
  ui.mainbutton = loveframes.Create("button")
  ui.mainbutton:SetSize(100,settings.padding)
  ui.mainbutton:SetPos(ui.gameselect_w+settings.padding*3.5,
    settings.heading.h+settings.padding*3)
  ui.mainbutton:SetText("Download")
  ui.mainbutton.OnClick = function(object)
    if remote.data.games[selectindex] then
      vapor.dogame(remote.data.games[selectindex])
    end
  end

  ui.mainbutton_tooltip = loveframes.Create("tooltip")
  ui.mainbutton_tooltip:SetObject(ui.mainbutton)
  ui.mainbutton_tooltip:SetPadding(4)

  -- progress bar

  ui.progressbar = loveframes.Create("progressbar")
  ui.progressbar:SetPos(ui.gameselect_w+settings.padding*4+100,
    settings.heading.h+settings.padding*3)
  ui.progressbar:SetWidth(ui.gameselect_w-settings.padding*4.5+100)
  ui.progressbar:SetHeight(settings.padding)
  ui.progressbar:SetLerp(true)
  ui.progressbar:SetLerpRate(5)
  ui.progressbar:SetMax(3)
  ui.progressbar:SetValue(0)

  -- tabs

  local tabs = loveframes.Create("tabs")
  tabs:SetPos(settings.padding, settings.heading.h+settings.padding)

  tabs:SetSize(ui.gameselect_w,ui.gameselect_h)

  ui.list = {}

  ui.list.all = ui.create_list(ui.conditions.all)
  tabs:AddTab("All",ui.list.all,("All games (%d)"):format(#remote.data.games))

  ui.list.favorites = ui.create_list(ui.conditions.favorites)
  tabs:AddTab("Favorites",ui.list.favorites,"Your favorite games")

  ui.list.downloaded = ui.create_list(ui.conditions.downloaded)
  tabs:AddTab("Downloaded",ui.list.downloaded,"Downloaded games")

  ui.list.new = ui.create_list(ui.conditions.all,ui.sorts.new,7)
  tabs:AddTab("New",ui.list.new,"Recently added games (7)")

  -- buttons

  ui.buttons = {}
  
  local x = ui.gameselect_w+settings.padding*2
  local y = love.graphics.getHeight()-settings.padding*2
  
  ui.buttons.favorite = loveframes.Create("imagebutton")
  ui.buttons.favorite:SetImage(icons.favorite)
  ui.buttons.favorite:SizeToImage()
  ui.buttons.favorite:SetText("")
  ui.buttons.favorite:SetPos(x,y)
  ui.buttons.favorite.OnClick = function(object)
    vapor.favoritegame(selectindex)
    ui.update_ui()
  end
  
  local favorite_tooltip = loveframes.Create("tooltip")
  favorite_tooltip:SetObject(ui.buttons.favorite)
  favorite_tooltip:SetPadding(4)
  favorite_tooltip:SetText("Mark this game as a favorite.")
  
  x = x + settings.padding
  
  ui.buttons.delete = loveframes.Create("imagebutton")
  ui.buttons.delete:SetImage(icons.delete)
  ui.buttons.delete:SizeToImage()
  ui.buttons.delete:SetText("")
  ui.buttons.delete:SetPos(x,y)
  ui.buttons.delete.OnClick = function(object)
    vapor.deletegame(selectindex)
  end

  local delete_tooltip = loveframes.Create("tooltip")
  delete_tooltip:SetObject(ui.buttons.delete)
  delete_tooltip:SetPadding(4)
  delete_tooltip:SetText("Delete this game.")

  x = x + settings.padding

  ui.buttons.visitwebsite = loveframes.Create("imagebutton")
  ui.buttons.visitwebsite:SetImage(icons.website)
  ui.buttons.visitwebsite:SizeToImage()
  ui.buttons.visitwebsite:SetText("")
  ui.buttons.visitwebsite:SetPos(x,y)
  ui.buttons.visitwebsite.OnClick = function(object)
    vapor.visitwebsitegame(selectindex)
    ui.update_ui()
  end
  
  local visitwebsite_tooltip = loveframes.Create("tooltip")
  visitwebsite_tooltip:SetObject(ui.buttons.visitwebsite)
  visitwebsite_tooltip:SetPadding(4)
  visitwebsite_tooltip:SetText("Visit the author's website.")

  ui.update_ui()

end

function ui.update(dt)

  if selectindex then
    if ui.headerindex < selectindex + ui.snap and ui.headerindex > selectindex - ui.snap then
      ui.headerindex = selectindex
    end
    local change = math.abs(ui.headerindex - selectindex)/2 + ui.changespeed
    if ui.headerindex < selectindex then
      ui.headerindex = ui.headerindex + change*dt
    elseif ui.headerindex > selectindex then
      ui.headerindex = ui.headerindex - change*dt
    end
  end
  
  if selectindex then
    for index = selectindex-1,selectindex+1 do
      ui.updatecovers(index)
    end
  end
  
  ui.update_ui()

  if ui.download_change then
    ui.download_change = nil
    ui.list.downloaded = ui.update_list(ui.list.downloaded,ui.conditions.downloaded)
  end

end

function ui.header()

  local centerindex = math.floor(ui.headerindex)
  local percentoffset = ui.headerindex%1*2

  local xoff = (love.graphics.getWidth()-settings.heading.w*(1+percentoffset))/2
  local yoff = 0
  
  local vapor = {name="Vapor"}
  
  for preload = -2,2 do
    love.graphics.setColor(255,255,255,255-191*math.abs(preload))
    local preload_gameobj = remote.data.games[centerindex+preload]
    if preload_gameobj then
      ui.cover(preload_gameobj,xoff+settings.heading.w*preload,yoff,centerindex+preload)
    else
      ui.cover(vapor,xoff+settings.heading.w*preload,yoff)
    end
  end

  love.graphics.setColor(colors.reset)
  
end

-- Based off of Boolsheet's utils.byte_scale from utils.lua
function ui.bytes_human(b)
  local units = {"B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB"}

  local mag
  for i = 1,9 do
    if b >= 1000 then
      b = b / 1000
    else
      mag = i
      break
    end
  end

  return round(b,1).." "..units[mag]
end

function ui.info()

  local x = ui.gameselect_w + settings.padding*2
  local y = settings.heading.h + settings.padding
  local w = love.graphics.getWidth()-x-settings.padding
  local h = love.graphics.getHeight()-y-settings.padding*3
  --love.graphics.rectangle("line",x,y,w,h)
  local gameobj = remote.data.games[selectindex]
  love.graphics.setFont(fonts.title)
  love.graphics.print(gameobj and gameobj.name or "Vapor",x,y)
  love.graphics.setFont(fonts.basic)
  local desc
  if gameobj then
   if gameobj.sizes and gameobj.sizes[gameobj.stable] then
     love.graphics.printf("Size: " .. ui.bytes_human(gameobj.sizes[gameobj.stable]),x,y,w,"right")
   end
   if gameobj.description then
      desc = gameobj.description
    else
      desc = "No description available."
    end
  else
    desc = "Welcome to Vapor."
  end
  love.graphics.printf(desc,x,y+settings.padding*3,w,"left")
  
  if gameobj then
    love.graphics.draw(ui.mainbutton.icon,ui.gameselect_w+settings.padding*2, settings.heading.h+settings.padding*3)
    love.graphics.printf(gameobj.author,x,y+h+settings.padding,w,"right")
    if gameobj.link then
      love.graphics.printf(gameobj.author,x,y+h+settings.padding,w,"right")
    end
  end
end

function ui.cover(gameobj,xoff,yoff,index)
  love.graphics.draw(ui.images[index] or ui.nogame,xoff,yoff)
  love.graphics.draw(ui.overlay,xoff,yoff)
end

function ui.updatecovers(index)
  if not ui.images[index] and remote.data.games[index] then
    local imgn = vapor.imgname(remote.data.games[index])

    if not vapor.currently_downloading[imgn] then
      if love.filesystem.exists(imgn) then
        -- load the image
        local status,img = pcall( function() return love.graphics.newImage(imgn) end )
        if status then -- success!
          ui.images[index] = img
        else -- error!
          print(imgn.." cannot be loaded by love.grapihcs.newImage. Deleting.")
          love.filesystem.remove(imgn)
        end
      else
        -- download it!
        print("downloading " .. imgn)
        vapor.currently_downloading[imgn] = true
        downloader:request(remote.data.games[index].image, async.love_filesystem_sink(imgn), function()
          vapor.currently_downloading[imgn] = nil
        end)
      end
    end
  end
end

return ui
