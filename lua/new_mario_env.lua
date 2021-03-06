luanet.load_assembly "System"

---- TCP CONFIGURATION
local Encoder = luanet.import_type "System.Text.Encoding"
local TcpClient = luanet.import_type("System.Net.Sockets.TcpClient")
local IO = luanet.import_type "System.IO.Path"

mySocket = TcpClient("localhost", 36296)
stream = mySocket:GetStream()
sMessage = "myMessage"
rMessage = "receivedData"
current_action = 0

function sendMsg()
  local message = Encoder.UTF8:GetBytes(sMessage)
  stream:Write(message, 0, string.len(sMessage))
  --console.log("sent: " .. sMessage)
end

function recvData()
  local buffer = "0000000000000000000000000" -- we should actually just receive a value to steer
  local byteBuffer = Encoder.UTF8:GetBytes(buffer)
  local bytesSent = stream:Read(byteBuffer, 0, string.len(buffer))
  local receivedMessage = Encoder.UTF8:GetString(byteBuffer)
  return string.sub(receivedMessage, 1, bytesSent)
end

function getTMPDir()
  return IO.GetTempPath()
end

BOX_CENTER_X, BOX_CENTER_Y = 160, 215
BOX_WIDTH, BOX_HEIGHT = 100, 4
SLIDER_WIDTH, SLIDER_HIEGHT = 4, 16
function draw_info()
  gui.drawBox(BOX_CENTER_X - BOX_WIDTH / 2, BOX_CENTER_Y - BOX_HEIGHT / 2,
              BOX_CENTER_X + BOX_WIDTH / 2, BOX_CENTER_Y + BOX_HEIGHT / 2,
              none, 0x60FFFFFF)
  gui.drawBox(BOX_CENTER_X + current_action*(BOX_WIDTH / 2) - SLIDER_WIDTH / 2, BOX_CENTER_Y - SLIDER_HIEGHT / 2,
              BOX_CENTER_X + current_action*(BOX_WIDTH / 2) + SLIDER_WIDTH / 2, BOX_CENTER_Y + SLIDER_HIEGHT / 2,
              none, 0xFFFF0000)
end

---- END TCP CONFIGURATION

---- SOME OTHER GLOBALS
USE_CLIPBOARD = true -- Use the clipboard to send screenshots to the predict server.
--[[ How many frames to wait before sending a new prediction request. If you're using a file, you
may want to consider adding some frames here. ]]--
WAIT_FRAMES = 1
USE_MAPPING = true -- Whether or not to use input remapping.
savestate.loadslot(2)
savestate.saveslot(2) -- save current slot for reset purposes
local util = require("util")
local SCREENSHOT_FILE = getTMPDir() .. 'predict-screenshot2.png' -- where to save screenshot

--- reinforcement variables
local new_progress = util.readProgress()
local old_progress = 0
local reward = 0

function request_prediction()
  new_progress = util.readProgress()
  reward = new_progress - old_progress
  if USE_CLIPBOARD then
    client.screenshottoclipboard()
    sMessage = "MESSAGE screenshot_clip_reward_" .. reward .. "_done_False \n"
  else
    client.screenshot(SCREENSHOT_FILE)
    sMessage = "MESSAGE screenshot_" .. SCREENSHOT_FILE .. "_reward_" .. reward .. "_done_False \n"
    --outgoing_message = "PREDICT:" .. SCREENSHOT_FILE .. "\n"
  end
end


while util.readProgress() < 3 do -- 3 means 3 laps
  -- Process the outgoing message.
  request_prediction()
  sendMsg()
  --- Process incoming message
  rMessage = recvData()

  if string.find(rMessage, "RESET") ~= nil then
    console.log('Reset game - LOADING SLOT 2 Which we saved at the beginning')
    savestate.loadslot(2)
    client.unpause()
  elseif string.find(rMessage, "PREDICTIONERROR") == nil then
    current_action = tonumber(rMessage)
    --console.log('current action: ' .. current_action)
    for i=1, WAIT_FRAMES do
      --console.log('wait frame')
      joypad.set({["P1 A"] = true})
      joypad.setanalog({["P1 X Axis"] = util.convertSteerToJoystick(current_action) })
      draw_info()
      emu.frameadvance()
    end
  else
    print("Prediction error...")
  end

end
