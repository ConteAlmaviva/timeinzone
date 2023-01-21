_addon.author   = 'Almavivaconte';
_addon.name     = 'TimeInZone';
_addon.version  = '0.0.1';

require 'common'
require 'math'

local base_timestamp = os.time(os.date("!*t"));
local visibility = true;
local bc_timestamp = 0;
local in_bc = false;
local checked_for_bc = false;
local has_zoned = false;

local default_config =
{
    font =
    {
        family      = 'Consolas',
        size        = 7,
        color       = 0xFFFFFFFF,
        position    = { 640, 360 },
        bgcolor     = 0x80000000,
        bgvisible   = true
    },
};

local TimeInZone_config = default_config;

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

ashita.register_event('render', function()

    local f = AshitaCore:GetFontManager():Get('__TimeInZone_addon');
    
    local current_timestamp = os.time(os.date("!*t"));
    
    local myBuffs = AshitaCore:GetDataManager():GetPlayer():GetBuffs();
    
    local label_string = "Time in Zone";
    if not has_zoned then
        label_string = "Time since addon loaded";
    end
    local time_diff = current_timestamp - base_timestamp;
    local timeString = string.format("%s: %02d:%02d:%02d", label_string, math.floor(time_diff/3600), math.floor(time_diff/60)%60, time_diff%60);
    
    if not in_bc then 
        for k,v in pairs(myBuffs) do
            if v == 254 then
                in_bc = true;
                if not checked_for_bc then
                    bc_timestamp = os.time(os.date("!*t"));
                    checked_for_bc = true;
                end
            end
        end
    end
    
    if in_bc then
        time_diff = current_timestamp - bc_timestamp;
        label_string = "Time in BCNM";
        in_bc = false;
        checked_for_bc = false;
        for k,v in pairs(myBuffs) do
            if v == 254 then
                in_bc = true;
            end
        end
        timeString = string.format("%s: %02d:%02d:%02d", label_string, math.floor(time_diff/3600), math.floor(time_diff/60)%60, time_diff%60);
    end
    
    if(base_timestamp == 0) then
        f:SetVisibility(false);
    else
        f:SetText(timeString);
        f:SetVisibility(visibility);
    end
    return;
end);

ashita.register_event('load', function()
    -- Attempt to load the configuration..
    TimeInZone_config = ashita.settings.load_merged(_addon.path .. 'settings/settings.json', default_config);

    -- Create our font object..
    local f = AshitaCore:GetFontManager():Create('__TimeInZone_addon');
    f:SetColor(TimeInZone_config.font.color);
    f:SetFontFamily(TimeInZone_config.font.family);
    f:SetFontHeight(TimeInZone_config.font.size);
    f:SetBold(true);
    f:SetPositionX(TimeInZone_config.font.position[1]);
    f:SetPositionY(TimeInZone_config.font.position[2]);
    f:SetVisibility(true);
    f:GetBackground():SetColor(TimeInZone_config.font.bgcolor);
    f:GetBackground():SetVisibility(TimeInZone_config.font.bgvisible);
end);

ashita.register_event('unload', function()
    -- Get the font object..
    local f = AshitaCore:GetFontManager():Get('__TimeInZone_addon');
    -- Update the configuration position..
    TimeInZone_config.font.position = { f:GetPositionX(), f:GetPositionY() };

    -- Save the configuration file..
    ashita.settings.save(_addon.path .. '/settings/settings.json', TimeInZone_config);

    -- Delete the font object..
    AshitaCore:GetFontManager():Delete('__TimeInZone_addon');
end);


ashita.register_event('incoming_packet', function(id, size, data, modified, blocked)
    
    if (id == 0x00A) then
        base_timestamp = os.time(os.date("!*t"));
        has_zoned = true;
    end
    
    return false;
    
end);

ashita.register_event('command', function(command, ntype)
    -- Ensure we should handle this command..
    local args = command:args();
    if (args[1] ~= '/timeinzone') then
        return false;
    end
    if(args[2] == 'reset' or args[2] == 'start') then
        base_timestamp = os.time(os.date("!*t"));
        return true;
    end
    if(args[2] == 'show') then
        visibility = not visibility;
        return true;
    end
    if(args[2] == 'test') then
        base_timestamp = tonumber(args[3]);
        return true;
    end
    return false;
end);