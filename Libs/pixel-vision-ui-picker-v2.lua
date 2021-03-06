--
-- Copyright (c) 2017, Jesse Freeman. All rights reserved.
--
-- Licensed under the Microsoft Public License (MS-PL) License.
-- See LICENSE file in the project root for full license information.
--
-- Contributors
-- --------------------------------------------------------
-- This is the official list of Pixel Vision 8 contributors:
--
-- Jesse Freeman - @JesseFreeman
-- Christina-Antoinette Neofotistou - @CastPixel
-- Christer Kaitila - @McFunkypants
-- Pedro Medeiros - @saint11
-- Shawn Rakowski - @shwany
--

function EditorUI:CreatePicker(rect, itemWidth, itemHeight, total, spriteName, toolTip)

  -- Create the button's default data
  local data = self:CreateData(rect, spriteName, toolTip, forceDraw)

  data.doubleClick = false
  data.doubleClickTime = 0
  data.doubleClickDelay = .45
  data.doubleClickActive = false


  -- Customize the default name by adding Button to it
  data.name = "Picker" .. data.name

  data.total = total

  data.itemWidth = itemWidth
  data.itemHeight = itemHeight
  data.columns = math.floor(data.rect.w / itemWidth)
  data.rows = math.floor(data.rect.h / itemHeight)

  data.overIndex = -1
  data.selected = -1
  data.lastOverIndex = -1 -- TODO do we need this?

  data.borderOffset = 2

  if(data.cachedSpriteData.over ~= nil) then

    local spriteData = data.cachedSpriteData.selectedup

    data.selectedDrawArgs = {spriteData.spriteIDs, 0, 0, spriteData.width, false, false, DrawMode.Sprite, spriteData.colorOffset}

    spriteData = data.cachedSpriteData.over

    data.overDrawArgs = {spriteData.spriteIDs, 0, 0, spriteData.width, false, false, DrawMode.Sprite, spriteData.colorOffset}
  end


  data.onClick = function(tmpData)

    self:PickerClick(tmpData, true, tmpData.doubleClickActive and tmpData.doubleClickTime < tmpData.doubleClickDelay)

    tmpData.doubleClickTime = 0
    tmpData.doubleClickActive = true

  end

  data.onFirstPress = function(tmpData)

    self:PickerPress(tmpData, true)
  end

  return data

end

function EditorUI:ChangePickerTotal(data, value)

  data.total = total


end

function EditorUI:UpdatePicker(data, hitRect)

  -- Make sure we have data to work with and the component isn't disabled, if not return out of the update method
  if(data == nil) then
    return
  end

  -- If the button has data but it's not enabled exit out of the update
  if(data.enabled == false) then

    -- If the button is disabled but still in focus we need to remove focus
    if(data.inFocus == true) then
      self:ClearFocus(data)
    end

    -- See if the button needs to be redrawn.
    self:RedrawPicker(data)

    -- Shouldn't update the button if its disabled
    return

  end

  -- Make sure we don't detect a collision if the mouse is down but not over this button
  if(self.collisionManager.mouseDown and data.inFocus == false) then
    -- See if the button needs to be redrawn.
    self:RedrawPicker(data)
    return
  end

  -- If the hit rect hasn't been overridden, then use the buttons own hit rect
  if(hitRect == nil) then
    hitRect = data.hitRect or data.rect
  end

  local overrideFocus = (data.inFocus == true and self.collisionManager.mouseDown)

  -- Ready to test finer collision if needed
  if(self.collisionManager:MouseInRect(hitRect) == true or overrideFocus) then

    if(data.doubleClick == true) then

      -- If the button wasn't in focus before, reset the timer since it's about to get focus
      if(data.inFocus == false) then
        data.doubleClickTime = 0
        data.doubleClickActive = false
      end

      data.doubleClickTime = data.doubleClickTime + self.timeDelta
      if(data.doubleClickActive and data.doubleClickTime > data.doubleClickDelay) then
        data.doubleClickActive = false
      end
    end

    -- TODO this needs to be more dynamic
    local tmpPos = self:CalculatePickerPosition(data)

    -- print("tmpPos", tmpPos.index, data.total)

    -- Check to see if the mouse is over a valid area
    if(tmpPos.index > - 1 and tmpPos.index < data.total) then

      -- If we are in the collision area, set the focus
      self:SetFocus(data)

      -- calculate the correct button over state
      local state = self.collisionManager.mouseDown and "down" or "over"

      if(data.selected == true) then
        state = "selected" .. state
      end


      if(state == "over") then



        data.tmpX = tmpPos.x
        data.tmpY = tmpPos.y

        data.overIndex = tmpPos.index < data.total and tmpPos.index or - 1

      elseif(state == "down")then
        data.selected = data.overIndex

      elseif(data.overIndex > - 1) then
        data.tmpX = -1
        data.tmpY = -1
        data.overIndex = -1

      end

      -- Check to see if the button is pressed and has an onAction callback
      if(self.collisionManager.mouseReleased == true) then

        -- Click the button
        data.onClick(data)
        data.firstPress = true
      elseif(self.collisionManager.mouseDown) then

        if(data.firstPress ~= false) then

          -- Call the onPress method for the button
          data.onFirstPress(data)

          -- Change the flag so we don't trigger first press again
          data.firstPress = false
        end
      end

    elseif(self.collisionManager.mouseDown == false) then
      data.firstPress = true
      -- If we are not in the button's rect, clear the focus
      self:ClearFocus(data)
      data.overIndex = -1

    end
  else

    if(data.inFocus == true) then

      data.firstPress = true
      -- If we are not in the button's rect, clear the focus
      self:ClearFocus(data)
      data.overIndex = -1
    end


  end

  -- else
  --
  --   -- If the mouse is not over the button, clear the focus for this button
  --   self:ClearFocus(data)
  --
  -- end

  -- Make sure we don't need to redraw the button.
  self:RedrawPicker(data)

end

function EditorUI:CalculatePickerPosition(data)

  local position = 
  {
    x = math.floor((self.collisionManager.mousePos.x - data.rect.x) / data.itemWidth),
    y = math.floor((self.collisionManager.mousePos.y - data.rect.y) / data.itemHeight),

  }

  position.index = math.index(position.x, position.y, data.columns)

  return position

end

function EditorUI:RedrawPicker(data)

  if(data == nil) then
    return
  end

  if(data.selectedDrawArgs ~= nil and data.selected > - 1) then

    self:NewDraw("DrawSprites", data.selectedDrawArgs)

  end


  if(data.overIndex > - 1 and data.overDrawArgs ~= nil) then

    data.overDrawArgs[2] = (data.tmpX * data.itemWidth) + data.rect.x - data.borderOffset
    data.overDrawArgs[3] = (data.tmpY * data.itemHeight) + data.rect.y - data.borderOffset
    self:NewDraw("DrawSprites", data.overDrawArgs)

  end

  -- If the button changes state we need to redraw it to the tilemap
  if(data.invalid == true) then

    -- The default state is up
    local state = "up"

    -- If the button is selected, we will use the selected up state
    if(data.selected == true) then
      state = "selected" .. state
    end

    -- Test to see if the button is disabled. If there is a disabled sprite data, we'll change the state to disabled. By default, always use the up state.
    if(data.enabled == false and data.cachedSpriteData["disabled"] ~= nil and data.selected ~= true) then --_G[spriteName .. "disabled"] ~= nil) then
      state = "disabled"

    end

    self:ResetValidation(data)

  end

end

-- Use this to perform a click action on a button. It's used internally when a mouse click is detected.
function EditorUI:PickerClick(data, callAction, doubleClick)

  if(data.onAction ~= nil and callAction ~= false) then

    -- Trigger the onAction call back and pass in the double click value if the button is set up to use it
    data.onAction(data.selected, doubleClick)

  end

end

function EditorUI:PickerPress(data, callAction)

  data.selected = data.overIndex

  if(data.selectedDrawArgs) then

    data.selectedDrawArgs[2] = (data.tmpX * data.itemWidth) + data.rect.x - data.borderOffset
    data.selectedDrawArgs[3] = (data.tmpY * data.itemHeight) + data.rect.y - data.borderOffset

    -- print("Update pos", data.selectedDrawArgs[2], data.selectedDrawArgs[3], data.selected)
  end

  if(data.onPress ~= nil and callAction ~= false) then

    -- Trigger the onPress
    data.onPress(data.selected)

  end

end

function EditorUI:SelectPicker(data, value, callAction)
  data.selected = value

  -- TODO this is a bit sloppy, it should run through the internal press logic and not duplicate it all here
  local pos = CalculatePosition(value, data.columns)

  data.selectedDrawArgs[2] = (pos.x * data.itemWidth) + data.rect.x - data.borderOffset
  data.selectedDrawArgs[3] = (pos.y * data.itemHeight) + data.rect.y - data.borderOffset

  if(data.onPress ~= nil and callAction ~= false) then

    -- Trigger the onPress
    data.onPress(data.selected)

  end

  self:Invalidate(data)
end

function EditorUI:ClearPickerSelection(data)
  data.selected = -1
  data.overIndex = -1
end
