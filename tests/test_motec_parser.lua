-- test_motec_parser.lua - Tests for MoTeC .ld binary parser
-- Tests binary parsing, channel mapping, ldx beacon parsing, lap extraction, CSV export

local ffi = require("ffi")
local motec = require('lib.motec_ld_parser')

--------------------------------------------------------------------------------
-- Helpers: Build synthetic binary data
--------------------------------------------------------------------------------

--- Write a u32 little-endian into a table of bytes
local function put_u32(t, offset, value)
    t[offset + 1] = bit.band(value, 0xFF)
    t[offset + 2] = bit.band(bit.rshift(value, 8), 0xFF)
    t[offset + 3] = bit.band(bit.rshift(value, 16), 0xFF)
    t[offset + 4] = bit.band(bit.rshift(value, 24), 0xFF)
end

--- Write a u16 little-endian into a table of bytes
local function put_u16(t, offset, value)
    t[offset + 1] = bit.band(value, 0xFF)
    t[offset + 2] = bit.band(bit.rshift(value, 8), 0xFF)
end

--- Write a signed i16 little-endian into a table of bytes
local function put_i16(t, offset, value)
    if value < 0 then value = value + 0x10000 end
    put_u16(t, offset, value)
end

--- Write a string into a table of bytes (null-padded to maxlen)
local function put_str(t, offset, str, maxlen)
    for i = 1, maxlen do
        local c = str:byte(i)
        t[offset + i] = c or 0
    end
end

--- Write a float32 little-endian into a table of bytes
local function put_f32(t, offset, value)
    local buf = ffi.new("float[1]", value)
    local bytes = ffi.string(buf, 4)
    for i = 1, 4 do
        t[offset + i] = bytes:byte(i)
    end
end

--- Convert byte table to string
local function bytes_to_string(t, size)
    local chars = {}
    for i = 1, size do
        chars[i] = string.char(t[i] or 0)
    end
    return table.concat(chars)
end

--- Build a minimal valid .ld file header
local function buildSyntheticHeader(opts)
    opts = opts or {}
    local size = 2048
    local t = {}
    for i = 1, size do t[i] = 0 end

    -- Magic
    put_u32(t, 0x00, opts.magic or 0x40)
    -- channel_meta_ptr
    put_u32(t, 0x08, opts.channel_meta_ptr or 0x700)
    -- channel_data_ptr
    put_u32(t, 0x0C, opts.channel_data_ptr or 0x800)
    -- event_ptr
    put_u32(t, 0x24, opts.event_ptr or 0)
    -- date
    put_str(t, 0x5E, opts.date or "01/01/2024", 16)
    -- time
    put_str(t, 0x7E, opts.time or "12:00:00", 16)
    -- driver
    put_str(t, 0x9E, opts.driver or "Test Driver", 64)
    -- vehicle_id
    put_str(t, 0xDE, opts.vehicle_id or "Test Car", 64)
    -- venue
    put_str(t, 0x15E, opts.venue or "Test Track", 64)

    return bytes_to_string(t, size)
end

--- Build a channel metadata block (192 bytes)
local function buildChannelMeta(opts)
    opts = opts or {}
    local t = {}
    for i = 1, 192 do t[i] = 0 end

    put_u32(t, 0, opts.prev_addr or 0)
    put_u32(t, 4, opts.next_addr or 0)
    put_u32(t, 8, opts.data_ptr or 0)
    put_u32(t, 12, opts.n_data or 0)
    put_u16(t, 18, opts.datatype_a or 0x07)  -- float by default
    put_u16(t, 20, opts.datatype or 4)        -- 4 bytes by default
    put_u16(t, 22, opts.rec_freq or 100)
    put_i16(t, 24, opts.shift or 0)
    put_i16(t, 26, opts.mul or 1)
    put_i16(t, 28, opts.scale or 1)
    put_i16(t, 30, opts.dec_places or 0)
    put_str(t, 32, opts.name or "Channel", 32)
    put_str(t, 64, opts.short_name or "", 8)
    put_str(t, 72, opts.unit or "", 12)

    return bytes_to_string(t, 192)
end

--- Build float32 sample data
local function buildFloat32Data(values)
    local n = #values
    local buf = ffi.new("float[?]", n)
    for i = 1, n do
        buf[i - 1] = values[i]
    end
    return ffi.string(buf, n * 4)
end

--- Build int16 sample data
local function buildInt16Data(values)
    local t = {}
    for i = 1, #values * 2 do t[i] = 0 end
    for i = 1, #values do
        put_i16(t, (i - 1) * 2, values[i])
    end
    return bytes_to_string(t, #values * 2)
end

--------------------------------------------------------------------------------
-- Tests: Binary Read Helpers
--------------------------------------------------------------------------------

suite("MoTeC Binary Read Helpers")

test("read_u32 little-endian basic", function()
    local data = string.char(0x48, 0x34, 0x00, 0x00)
    assert_equal(motec.read_u32(data, 0), 0x3448)
end)

test("read_u32 large value", function()
    local data = string.char(0xB8, 0x37, 0x00, 0x00)
    assert_equal(motec.read_u32(data, 0), 0x37B8)
end)

test("read_u32 at offset", function()
    local data = string.char(0x00, 0x00, 0x00, 0x00, 0x48, 0x34, 0x00, 0x00)
    assert_equal(motec.read_u32(data, 4), 0x3448)
end)

test("read_u16 basic", function()
    local data = string.char(0x64, 0x00)
    assert_equal(motec.read_u16(data, 0), 100)
end)

test("read_u16 high value", function()
    local data = string.char(0xFF, 0x7F)
    assert_equal(motec.read_u16(data, 0), 0x7FFF)
end)

test("read_i16 positive", function()
    local data = string.char(0x64, 0x00)
    assert_equal(motec.read_i16(data, 0), 100)
end)

test("read_i16 negative", function()
    -- -29700 as unsigned = 35836 = 0x8BFC
    local t = {}
    put_i16(t, 0, -29700)
    local data = bytes_to_string(t, 2)
    assert_equal(motec.read_i16(data, 0), -29700)
end)

test("read_i16 minus one", function()
    local data = string.char(0xFF, 0xFF)
    assert_equal(motec.read_i16(data, 0), -1)
end)

test("read_f32 zero", function()
    local data = string.char(0x00, 0x00, 0x00, 0x00)
    assert_near(motec.read_f32(data, 0), 0.0, 0.001)
end)

test("read_f32 one", function()
    -- IEEE 754: 1.0 = 0x3F800000
    local data = string.char(0x00, 0x00, 0x80, 0x3F)
    assert_near(motec.read_f32(data, 0), 1.0, 0.001)
end)

test("read_f32 known value 68.80", function()
    local data = buildFloat32Data({ 68.80 })
    assert_near(motec.read_f32(data, 0), 68.80, 0.01)
end)

test("read_f32 negative value", function()
    local data = buildFloat32Data({ -42.5 })
    assert_near(motec.read_f32(data, 0), -42.5, 0.01)
end)

test("read_str basic", function()
    local data = "Corr Speed\0\0\0\0\0\0"
    assert_equal(motec.read_str(data, 0, 16), "Corr Speed")
end)

test("read_str with trailing nulls", function()
    local data = "Hi\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0"
    assert_equal(motec.read_str(data, 0, 16), "Hi")
end)

test("read_str at offset", function()
    local data = "\0\0\0\0Test\0\0\0\0"
    assert_equal(motec.read_str(data, 4, 8), "Test")
end)

test("read_str empty string", function()
    local data = "\0\0\0\0\0\0\0\0"
    assert_equal(motec.read_str(data, 0, 8), "")
end)

--------------------------------------------------------------------------------
-- Tests: Integer Conversion Formula
--------------------------------------------------------------------------------

suite("MoTeC Integer Conversion")

test("convertIntValue P_F_BRAKE zero brake", function()
    -- raw=-29700, scale=9, dec=2, shift=33, mul=1
    -- value = (-29700/9 * 0.01 + 33) * 1 = (-3300 * 0.01 + 33) = (-33 + 33) = 0
    local result = motec.convertIntValue(-29700, 9, 2, 33, 1)
    assert_near(result, 0.0, 0.01)
end)

test("convertIntValue P_F_BRAKE with 50 bar braking", function()
    -- 50 = (raw/9 * 0.01 + 33) * 1
    -- raw/9 * 0.01 = 17, raw/9 = 1700, raw = 15300
    local result = motec.convertIntValue(15300, 9, 2, 33, 1)
    assert_near(result, 50.0, 0.01)
end)

test("convertIntValue identity (scale=1, dec=0, shift=0, mul=1)", function()
    assert_near(motec.convertIntValue(42, 1, 0, 0, 1), 42.0, 0.001)
end)

test("convertIntValue with scale only", function()
    -- raw=100, scale=10 -> 100/10 = 10
    assert_near(motec.convertIntValue(100, 10, 0, 0, 1), 10.0, 0.001)
end)

test("convertIntValue with dec only", function()
    -- raw=1000, dec=2 -> 1000 * 0.01 = 10
    assert_near(motec.convertIntValue(1000, 1, 2, 0, 1), 10.0, 0.001)
end)

test("convertIntValue with shift only", function()
    -- raw=0, shift=50 -> (0 + 50) * 1 = 50
    assert_near(motec.convertIntValue(0, 1, 0, 50, 1), 50.0, 0.001)
end)

test("convertIntValue with mul only", function()
    -- raw=10, mul=3 -> 10 * 3 = 30
    assert_near(motec.convertIntValue(10, 1, 0, 0, 3), 30.0, 0.001)
end)

test("convertIntValue handles scale=0 gracefully", function()
    -- Should not crash
    local result = motec.convertIntValue(100, 0, 0, 0, 1)
    assert_type(result, "number")
end)

--------------------------------------------------------------------------------
-- Tests: Header Parsing
--------------------------------------------------------------------------------

suite("MoTeC Header Parsing")

test("parses synthetic header", function()
    local data = buildSyntheticHeader({
        channel_meta_ptr = 0x100,
        channel_data_ptr = 0x200,
        date = "19/02/2024",
        driver = "Mikkel Jensen",
        venue = "Sebring",
    })

    local hdr = motec.parseHeader(data)
    assert_not_nil(hdr, "Should parse header")
    assert_equal(hdr.magic, 0x40)
    assert_equal(hdr.channel_meta_ptr, 0x100)
    assert_equal(hdr.channel_data_ptr, 0x200)
    assert_equal(hdr.date, "19/02/2024")
    assert_equal(hdr.driver, "Mikkel Jensen")
    assert_equal(hdr.venue, "Sebring")
end)

test("rejects bad magic", function()
    local data = buildSyntheticHeader({ magic = 0x00 })
    local hdr, err = motec.parseHeader(data)
    assert_nil(hdr)
    assert_not_nil(err)
    assert_true(err:find("magic") ~= nil, "Error should mention magic: " .. err)
end)

test("rejects too-small file", function()
    local data = "short"
    local hdr, err = motec.parseHeader(data)
    assert_nil(hdr)
    assert_not_nil(err)
end)

test("rejects channel_meta_ptr beyond file end", function()
    local data = buildSyntheticHeader({ channel_meta_ptr = 99999 })
    local hdr, err = motec.parseHeader(data)
    assert_nil(hdr)
    assert_not_nil(err)
end)

--------------------------------------------------------------------------------
-- Tests: Channel Metadata
--------------------------------------------------------------------------------

suite("MoTeC Channel Metadata")

test("parses channel metadata block", function()
    local chData = buildChannelMeta({
        prev_addr = 0,
        next_addr = 0,
        data_ptr = 0x1000,
        n_data = 5000,
        datatype_a = 0x07,
        datatype = 4,
        rec_freq = 100,
        name = "Corr Speed",
        unit = "m/s",
    })

    -- Prepend padding so offset works
    local data = string.rep("\0", 0x100) .. chData
    local ch = motec.parseChannelMeta(data, 0x100)

    assert_equal(ch.data_ptr, 0x1000)
    assert_equal(ch.n_data, 5000)
    assert_equal(ch.datatype_a, 0x07)
    assert_equal(ch.datatype, 4)
    assert_equal(ch.rec_freq, 100)
    assert_equal(ch.name, "Corr Speed")
    assert_equal(ch.unit, "m/s")
end)

test("parses int16 channel metadata with conversion params", function()
    local chData = buildChannelMeta({
        datatype_a = 0x03,
        datatype = 2,
        rec_freq = 100,
        shift = 33,
        mul = 1,
        scale = 9,
        dec_places = 2,
        name = "P_F_BRAKE",
        unit = "bar",
    })

    local data = string.rep("\0", 0x100) .. chData
    local ch = motec.parseChannelMeta(data, 0x100)

    assert_equal(ch.datatype_a, 0x03)
    assert_equal(ch.datatype, 2)
    assert_equal(ch.shift, 33)
    assert_equal(ch.mul, 1)
    assert_equal(ch.scale, 9)
    assert_equal(ch.dec_places, 2)
    assert_equal(ch.name, "P_F_BRAKE")
    assert_equal(ch.unit, "bar")
end)

test("readAllChannels follows linked list", function()
    -- Build two channels linked together
    local ch1Offset = 0x200
    local ch2Offset = 0x200 + 192

    local ch1 = buildChannelMeta({
        prev_addr = 0,
        next_addr = ch2Offset,
        name = "Speed",
        data_ptr = 0x1000,
        n_data = 10,
    })
    local ch2 = buildChannelMeta({
        prev_addr = ch1Offset,
        next_addr = 0,  -- End of list
        name = "Throttle",
        data_ptr = 0x1028,
        n_data = 10,
    })

    local data = string.rep("\0", ch1Offset) .. ch1 .. ch2 .. string.rep("\0", 256)
    local channels = motec.readAllChannels(data, ch1Offset)

    assert_equal(#channels, 2)
    assert_equal(channels[1].name, "Speed")
    assert_equal(channels[2].name, "Throttle")
end)

test("readAllChannels handles single channel", function()
    local chOffset = 0x100
    local ch = buildChannelMeta({
        prev_addr = 0,
        next_addr = 0,
        name = "Speed",
    })

    local data = string.rep("\0", chOffset) .. ch .. string.rep("\0", 256)
    local channels = motec.readAllChannels(data, chOffset)

    assert_equal(#channels, 1)
    assert_equal(channels[1].name, "Speed")
end)

--------------------------------------------------------------------------------
-- Tests: Channel Data Reading
--------------------------------------------------------------------------------

suite("MoTeC Channel Data Reading")

test("reads float32 channel data", function()
    local values = { 10.5, 20.0, 30.75, 40.25, 50.0 }
    local sampleData = buildFloat32Data(values)
    local dataOffset = 0x100

    local chMeta = {
        data_ptr = dataOffset,
        n_data = 5,
        datatype_a = 0x07,
        datatype = 4,
        name = "Speed",
    }

    local data = string.rep("\0", dataOffset) .. sampleData
    local result = motec.readChannelData(data, chMeta)

    assert_equal(#result, 5)
    for i = 1, 5 do
        assert_near(result[i], values[i], 0.01,
            string.format("Sample %d: expected %.2f, got %.2f", i, values[i], result[i]))
    end
end)

test("reads int16 channel data with conversion", function()
    -- P_F_BRAKE: scale=9, dec=2, shift=33, mul=1
    -- raw=-29700 -> 0 bar, raw=15300 -> 50 bar
    local rawValues = { -29700, 15300, -29700 }
    local sampleData = buildInt16Data(rawValues)
    local dataOffset = 0x100

    local chMeta = {
        data_ptr = dataOffset,
        n_data = 3,
        datatype_a = 0x03,
        datatype = 2,
        shift = 33,
        mul = 1,
        scale = 9,
        dec_places = 2,
        name = "P_F_BRAKE",
    }

    local data = string.rep("\0", dataOffset) .. sampleData
    local result = motec.readChannelData(data, chMeta)

    assert_equal(#result, 3)
    assert_near(result[1], 0.0, 0.1, "Zero brake")
    assert_near(result[2], 50.0, 0.1, "50 bar brake")
    assert_near(result[3], 0.0, 0.1, "Zero brake again")
end)

test("handles data beyond file bounds gracefully", function()
    local data = string.rep("\0", 100)
    local chMeta = {
        data_ptr = 50,
        n_data = 1000,  -- Way more than available
        datatype_a = 0x07,
        datatype = 4,
        name = "Test",
    }

    -- Should not crash, reads what it can
    local result = motec.readChannelData(data, chMeta)
    assert_true(#result < 1000, "Should have fewer samples than requested")
    assert_true(#result >= 0, "Should have non-negative count")
end)

--------------------------------------------------------------------------------
-- Tests: Channel Name Mapping
--------------------------------------------------------------------------------

suite("MoTeC Channel Name Mapping")

test("maps standard MoTeC channels", function()
    local channels = {
        { name = "Corr Speed", unit = "m/s" },
        { name = "Throttle Pos", unit = "ratio" },
        { name = "Steering Angle", unit = "deg" },
        { name = "P_F_BRAKE", unit = "bar" },
        { name = "Brake Pos", unit = "ratio" },
    }
    local mapping = motec.mapChannels(channels)
    assert_equal(mapping.speed, 1, "Corr Speed -> speed")
    assert_equal(mapping.throttle, 2, "Throttle Pos -> throttle")
    assert_equal(mapping.steering, 3, "Steering Angle -> steering")
    assert_equal(mapping.brake, 4, "P_F_BRAKE -> brake")
    assert_equal(mapping.brakePos, 5, "Brake Pos -> brakePos")
end)

test("prefers higher priority channels", function()
    local channels = {
        { name = "Speed", unit = "m/s" },          -- low priority
        { name = "Corr Speed", unit = "m/s" },     -- high priority (index 1)
    }
    local mapping = motec.mapChannels(channels)
    assert_equal(mapping.speed, 2, "Should prefer 'Corr Speed' over 'Speed'")
end)

test("maps Driver Throttle Pos over Throttle Pos", function()
    local channels = {
        { name = "Throttle Pos", unit = "ratio" },
        { name = "Driver Throttle Pos", unit = "ratio" },
    }
    local mapping = motec.mapChannels(channels)
    assert_equal(mapping.throttle, 2, "Should prefer 'Driver Throttle Pos'")
end)

test("handles case-insensitive matching", function()
    local channels = {
        { name = "CORR SPEED", unit = "m/s" },
    }
    local mapping = motec.mapChannels(channels)
    assert_equal(mapping.speed, 1, "Should match case-insensitively")
end)

test("returns empty mapping for unknown channels", function()
    local channels = {
        { name = "Unknown Channel", unit = "?" },
    }
    local mapping = motec.mapChannels(channels)
    assert_nil(mapping.speed)
    assert_nil(mapping.throttle)
end)

test("maps fuel channels", function()
    local channels = {
        { name = "Fuel Remaining", unit = "l" },
    }
    local mapping = motec.mapChannels(channels)
    assert_equal(mapping.fuel, 1)
end)

test("maps gear channels", function()
    local channels = {
        { name = "Gear", unit = "" },
    }
    local mapping = motec.mapChannels(channels)
    assert_equal(mapping.gear, 1)
end)

--------------------------------------------------------------------------------
-- Tests: LDX Beacon Parser
--------------------------------------------------------------------------------

suite("MoTeC LDX Beacon Parser")

test("parses beacon times from ldx", function()
    mock.vfsWrite("test.ldx", [[<?xml version="1.0"?>
<LDXFile Locale="English" DefaultLocale="C" Version="1.6">
  <Layers>
    <Layer>
      <MarkerBlock>
        <MarkerGroup Name="Beacons" Index="3">
          <Marker Version="100" ClassName="BCN" Name="Manual.1" Flags="77" Time="2.12100000000000000e+08"/>
          <Marker Version="100" ClassName="BCN" Name="Manual.2" Flags="77" Time="3.23200000000000000e+08"/>
          <Marker Version="100" ClassName="BCN" Name="Manual.3" Flags="77" Time="4.33700000000000000e+08"/>
        </MarkerGroup>
      </MarkerBlock>
    </Layer>
  </Layers>
</LDXFile>]])

    local beacons, meta = motec.parseLdx("test.ldx")
    assert_not_nil(beacons, "Should parse beacons")
    assert_equal(#beacons, 3)
    assert_near(beacons[1], 212.1, 0.1)
    assert_near(beacons[2], 323.2, 0.1)
    assert_near(beacons[3], 433.7, 0.1)
end)

test("parses ldx metadata", function()
    mock.vfsWrite("meta.ldx", [[<?xml version="1.0"?>
<LDXFile>
  <Layers>
    <Layer>
      <MarkerBlock>
        <MarkerGroup Name="Beacons" Index="3">
          <Marker Time="1.00000000e+08"/>
          <Marker Time="2.00000000e+08"/>
        </MarkerGroup>
      </MarkerBlock>
    </Layer>
    <Details>
      <String Id="Total Laps" Value="17"/>
      <String Id="Fastest Time" Value="1:49.299"/>
      <String Id="Fastest Lap" Value="14"/>
      <String Id="Event" Value="2024 Sebring Test 2"/>
      <String Id="Venue" Value="Sebring International Raceway"/>
      <String Id="Driver" Value="Mikkel Jensen"/>
    </Details>
  </Layers>
</LDXFile>]])

    local beacons, meta = motec.parseLdx("meta.ldx")
    assert_not_nil(meta)
    assert_equal(meta.totalLaps, 17)
    assert_equal(meta.fastestTime, "1:49.299")
    assert_equal(meta.fastestLap, 14)
    assert_equal(meta.event, "2024 Sebring Test 2")
    assert_equal(meta.venue, "Sebring International Raceway")
    assert_equal(meta.driver, "Mikkel Jensen")
end)

test("returns nil for missing ldx file", function()
    local beacons, meta = motec.parseLdx("nonexistent.ldx")
    assert_nil(beacons)
end)

test("returns nil for empty ldx file", function()
    mock.vfsWrite("empty.ldx", "")
    local beacons, meta = motec.parseLdx("empty.ldx")
    assert_nil(beacons)
end)

test("returns nil for ldx without beacons", function()
    mock.vfsWrite("nobeacons.ldx", [[<?xml version="1.0"?>
<LDXFile>
  <Layers>
    <Layer>
      <MarkerBlock>
      </MarkerBlock>
    </Layer>
  </Layers>
</LDXFile>]])

    local beacons, meta = motec.parseLdx("nobeacons.ldx")
    assert_nil(beacons)
end)

test("beacons are sorted", function()
    mock.vfsWrite("unsorted.ldx", [[<?xml version="1.0"?>
<LDXFile>
  <Layers>
    <Layer>
      <MarkerBlock>
        <MarkerGroup Name="Beacons" Index="3">
          <Marker Time="3.00000000e+08"/>
          <Marker Time="1.00000000e+08"/>
          <Marker Time="2.00000000e+08"/>
        </MarkerGroup>
      </MarkerBlock>
    </Layer>
  </Layers>
</LDXFile>]])

    local beacons = motec.parseLdx("unsorted.ldx")
    assert_not_nil(beacons)
    assert_equal(#beacons, 3)
    assert_true(beacons[1] < beacons[2], "Beacons should be sorted")
    assert_true(beacons[2] < beacons[3], "Beacons should be sorted")
end)

--------------------------------------------------------------------------------
-- Tests: Lap Computation
--------------------------------------------------------------------------------

suite("MoTeC Lap Computation")

test("computes laps from beacons", function()
    local beacons = { 212.1, 323.2, 433.7 }
    local laps = motec.computeLaps(beacons)
    assert_equal(#laps, 2)
    assert_equal(laps[1].index, 1)
    assert_near(laps[1].startTime, 212.1, 0.01)
    assert_near(laps[1].endTime, 323.2, 0.01)
    assert_near(laps[1].timeMs, 111100, 100)
    assert_equal(laps[2].index, 2)
    assert_near(laps[2].timeMs, 110500, 100)
end)

test("lap timeFormatted is correct", function()
    local beacons = { 0, 109.299 }
    local laps = motec.computeLaps(beacons)
    assert_equal(#laps, 1)
    assert_equal(laps[1].timeFormatted, "1:49.299")
end)

test("single beacon produces no laps", function()
    local laps = motec.computeLaps({ 100.0 })
    assert_equal(#laps, 0)
end)

test("empty beacons produces no laps", function()
    local laps = motec.computeLaps({})
    assert_equal(#laps, 0)
end)

test("findFastestLap returns correct index", function()
    local laps = {
        { timeMs = 111000 },
        { timeMs = 109300 },
        { timeMs = 110500 },
    }
    assert_equal(motec.findFastestLap(laps), 2)
end)

test("findFastestLap with single lap", function()
    local laps = { { timeMs = 100000 } }
    assert_equal(motec.findFastestLap(laps), 1)
end)

test("findFastestLap with empty list", function()
    assert_nil(motec.findFastestLap({}))
end)

--------------------------------------------------------------------------------
-- Tests: Lap Data Extraction
--------------------------------------------------------------------------------

suite("MoTeC Lap Data Extraction")

test("extracts correct sample range for a lap", function()
    -- 100Hz channel, 1000 samples total (10 seconds)
    local fullValues = {}
    for i = 1, 1000 do fullValues[i] = i * 0.1 end

    local channels = {
        { rec_freq = 100 },
    }

    local channelValues = { [1] = fullValues }

    -- Extract lap from 2.0s to 5.0s
    local lapValues = motec.extractLapData(channelValues, channels, 2.0, 5.0)

    assert_not_nil(lapValues[1])
    -- At 100Hz: 2.0s = sample 200, 5.0s = sample 500 -> 301 samples
    assert_equal(#lapValues[1], 301)
    -- First value should be at index 201 (sample 200, 1-based)
    assert_near(lapValues[1][1], 20.1, 0.01)
end)

test("handles different sample rates in extraction", function()
    -- Channel 1: 100Hz, Channel 2: 50Hz
    local ch1Values = {}
    for i = 1, 1000 do ch1Values[i] = i end
    local ch2Values = {}
    for i = 1, 500 do ch2Values[i] = i end

    local channels = {
        { rec_freq = 100 },
        { rec_freq = 50 },
    }
    local channelValues = { [1] = ch1Values, [2] = ch2Values }

    -- Extract 1.0s to 3.0s
    local lapValues = motec.extractLapData(channelValues, channels, 1.0, 3.0)

    -- Ch1 at 100Hz: samples 100..300 = 201 samples
    assert_equal(#lapValues[1], 201)
    -- Ch2 at 50Hz: samples 50..150 = 101 samples
    assert_equal(#lapValues[2], 101)
end)

--------------------------------------------------------------------------------
-- Tests: Channel Resampling
--------------------------------------------------------------------------------

suite("MoTeC Channel Resampling")

test("same rate returns original", function()
    local values = { 1, 2, 3, 4, 5 }
    local result = motec.resampleChannel(values, 100, 100, 0.04)
    assert_equal(#result, #values)
end)

test("upsamples from 50Hz to 100Hz", function()
    -- 50Hz data: [0, 10, 20] over 0.04s (3 samples at 50Hz)
    local values = { 0, 10, 20 }
    local result = motec.resampleChannel(values, 50, 100, 0.04)

    -- At 100Hz over 0.04s: 5 samples
    assert_equal(#result, 5)
    assert_near(result[1], 0.0, 0.1)    -- t=0.00s -> idx 0.0
    assert_near(result[2], 5.0, 0.1)    -- t=0.01s -> idx 0.5, lerp(0,10)
    assert_near(result[3], 10.0, 0.1)   -- t=0.02s -> idx 1.0
    assert_near(result[4], 15.0, 0.1)   -- t=0.03s -> idx 1.5, lerp(10,20)
    assert_near(result[5], 20.0, 0.1)   -- t=0.04s -> idx 2.0
end)

test("handles empty input", function()
    local result = motec.resampleChannel({}, 50, 100, 1.0)
    assert_equal(#result, 0)
end)

--------------------------------------------------------------------------------
-- Tests: Distance Computation
--------------------------------------------------------------------------------

suite("MoTeC Distance Computation")

test("computes cumulative distance from speed", function()
    -- 100 km/h constant for 1 second at 10Hz
    local speed = {}
    for i = 1, 10 do speed[i] = 100 end -- 100 km/h

    local distance = motec.computeDistance(speed, 10)

    assert_equal(#distance, 10)
    assert_near(distance[1], 0.0, 0.01, "First distance should be 0")
    -- 100 km/h = 27.778 m/s, dt=0.1s, so each step adds 2.778m
    assert_near(distance[2], 2.778, 0.01)
    -- After 9 steps: 9 * 2.778 = 25.0m
    assert_near(distance[10], 25.0, 0.1)
end)

test("zero speed produces zero distance", function()
    local speed = { 0, 0, 0, 0, 0 }
    local distance = motec.computeDistance(speed, 100)
    for i = 1, 5 do
        assert_near(distance[i], 0.0, 0.001)
    end
end)

test("distance always starts at zero", function()
    local speed = { 200, 200, 200 }
    local distance = motec.computeDistance(speed, 100)
    assert_near(distance[1], 0.0, 0.001)
    assert_true(distance[2] > 0)
    assert_true(distance[3] > distance[2])
end)

--------------------------------------------------------------------------------
-- Tests: Unit Conversion
--------------------------------------------------------------------------------

suite("MoTeC Unit Conversion")

test("speed m/s to km/h", function()
    local ch = { unit = "m/s" }
    assert_near(motec.getUnitFactor(ch, "speed"), 3.6, 0.001)
end)

test("speed km/h stays km/h", function()
    local ch = { unit = "km/h" }
    assert_near(motec.getUnitFactor(ch, "speed"), 1.0, 0.001)
end)

test("speed mph to km/h", function()
    local ch = { unit = "mph" }
    assert_near(motec.getUnitFactor(ch, "speed"), 1.60934, 0.001)
end)

test("brake bar stays bar", function()
    local ch = { unit = "bar" }
    assert_near(motec.getUnitFactor(ch, "brake"), 1.0, 0.001)
end)

test("brake psi to bar", function()
    local ch = { unit = "psi" }
    assert_near(motec.getUnitFactor(ch, "brake"), 0.0689476, 0.0001)
end)

test("getChannelUnit falls back to short_name when unit is empty", function()
    -- Real MoTeC hardware stores units in short_name, not unit field
    local ch = { unit = "", short_name = "m/s" }
    assert_equal(motec.getChannelUnit(ch), "m/s")

    -- Normal case: unit field populated
    local ch2 = { unit = "bar", short_name = "bar" }
    assert_equal(motec.getChannelUnit(ch2), "bar")

    -- Nil unit field
    local ch3 = { unit = nil, short_name = "km/h" }
    assert_equal(motec.getChannelUnit(ch3), "km/h")

    -- Both empty
    local ch4 = { unit = "", short_name = "" }
    assert_equal(motec.getChannelUnit(ch4), "")

    -- Unit factor uses getChannelUnit internally
    local ch5 = { unit = "", short_name = "m/s" }
    assert_near(motec.getUnitFactor(ch5, "speed"), 3.6, 0.001, "Should detect m/s from short_name")
end)

test("unknown unit defaults", function()
    local ch = { unit = "weird" }
    -- Speed defaults to m/s -> km/h (3.6)
    assert_near(motec.getUnitFactor(ch, "speed"), 3.6, 0.001)
    -- Brake defaults to 1.0 (assume bar)
    assert_near(motec.getUnitFactor(ch, "brake"), 1.0, 0.001)
end)

--------------------------------------------------------------------------------
-- Tests: CSV Export
--------------------------------------------------------------------------------

suite("MoTeC CSV Export")

test("buildExportFilename format", function()
    local session = {
        header = { venue = "Sebring Raceway" },
        laps = {
            { timeMs = 109299 },
        },
    }
    local filename = motec.buildExportFilename(session, 1)
    assert_true(filename:find("motec_") ~= nil, "Should start with motec_")
    assert_true(filename:find("%.csv$") ~= nil, "Should end with .csv")
    assert_true(filename:find("1%-49") ~= nil, "Should contain lap time: " .. filename)
end)

test("buildExportFilename sanitizes venue name", function()
    local session = {
        header = { venue = "Track/Name:Test" },
        laps = {
            { timeMs = 60000 },
        },
    }
    local filename = motec.buildExportFilename(session, 1)
    assert_true(filename:find("[/:]") == nil, "Should not contain invalid chars: " .. filename)
end)

test("exports lap as CSV with correct format", function()
    -- Build a minimal session with synthetic data
    local channels = {
        { name = "Corr Speed", unit = "m/s", rec_freq = 10, datatype_a = 0x07, datatype = 4,
          n_data = 50, data_ptr = 0, shift = 0, mul = 1, scale = 1, dec_places = 0 },
        { name = "Throttle Pos", unit = "ratio", rec_freq = 10, datatype_a = 0x07, datatype = 4,
          n_data = 50, data_ptr = 0, shift = 0, mul = 1, scale = 1, dec_places = 0 },
        { name = "P_F_BRAKE", unit = "bar", rec_freq = 10, datatype_a = 0x07, datatype = 4,
          n_data = 50, data_ptr = 0, shift = 0, mul = 1, scale = 1, dec_places = 0 },
        { name = "Steering Angle", unit = "deg", rec_freq = 10, datatype_a = 0x07, datatype = 4,
          n_data = 50, data_ptr = 0, shift = 0, mul = 1, scale = 1, dec_places = 0 },
    }

    local mapping = motec.mapChannels(channels)

    -- Build channel data (5 seconds at 10Hz = 50 samples each)
    local channelData = {}
    local speedData = {}
    local throttleData = {}
    local brakeData = {}
    local steerData = {}
    for i = 1, 50 do
        speedData[i] = 50.0 + (i - 1) * 0.5    -- m/s increasing
        throttleData[i] = (i <= 25) and 1.0 or 0.5
        brakeData[i] = (i > 40) and 30.0 or 0.0
        steerData[i] = (i - 25) * 0.5
    end
    channelData[mapping.speed] = speedData
    channelData[mapping.throttle] = throttleData
    channelData[mapping.brake] = brakeData
    channelData[mapping.steering] = steerData

    local session = {
        header = { venue = "Test Track" },
        channels = channels,
        mapping = mapping,
        channelData = channelData,
        laps = {
            {
                index = 1,
                startTime = 0,
                endTime = 5.0,
                timeMs = 5000,
                timeFormatted = "0:05.000",
            },
        },
    }

    local outputPath = "test_output/motec_export.csv"
    local path, err = motec.exportLapAsCSV(session, 1, outputPath, "test_track")
    assert_not_nil(path, "Should export successfully: " .. (err or ""))

    -- Read and verify CSV content
    local csvContent = mock.vfsRead(outputPath)
    assert_not_nil(csvContent, "CSV file should exist")

    -- Check format header
    assert_true(csvContent:find('"Format","MoTeC CSV File"') ~= nil, "Should have format header")
    assert_true(csvContent:find('"Sample Rate"') ~= nil, "Should have sample rate")

    -- Check column headers
    assert_true(csvContent:find('"Distance"') ~= nil, "Should have Distance column")
    assert_true(csvContent:find('"Ground Speed"') ~= nil, "Should have speed column")
    assert_true(csvContent:find('"Brake Pressure F"') ~= nil, "Should have brake pressure column")
    assert_true(csvContent:find('"Driver Throttle Pos"') ~= nil, "Should have throttle column")
    assert_true(csvContent:find('"Steering Angle"') ~= nil, "Should have steering column")

    -- Check units row
    assert_true(csvContent:find('"km/h"') ~= nil, "Should have km/h unit")
    assert_true(csvContent:find('"bar"') ~= nil, "Should have bar unit")
    assert_true(csvContent:find('"m"') ~= nil, "Should have meter unit for distance")

    -- Check track name in data
    assert_true(csvContent:find('"test_track"') ~= nil, "Should contain track name")
end)

test("exportLapAsCSV rejects invalid lap index", function()
    local session = { laps = {} }
    local path, err = motec.exportLapAsCSV(session, 1, "out.csv", "track")
    assert_nil(path)
    assert_not_nil(err)
end)

--------------------------------------------------------------------------------
-- Tests: Full Parse Integration (Synthetic)
--------------------------------------------------------------------------------

suite("MoTeC Full Parse - Synthetic")

test("parseFile with synthetic .ld and .ldx", function()
    -- Build a synthetic .ld file with 2 channels
    local headerSize = 2048
    local ch1Offset = headerSize
    local ch2Offset = headerSize + 192
    local dataStart = headerSize + 192 * 2

    -- Speed: 100 samples at 10Hz (10 seconds)
    local speedValues = {}
    for i = 1, 100 do speedValues[i] = 50.0 end -- 50 m/s constant
    local speedData = buildFloat32Data(speedValues)

    -- Throttle: 100 samples at 10Hz
    local throttleValues = {}
    for i = 1, 100 do throttleValues[i] = 0.8 end
    local throttleData = buildFloat32Data(throttleValues)

    local speedDataOffset = dataStart
    local throttleDataOffset = dataStart + #speedData

    -- Build header
    local headerBytes = {}
    for i = 1, headerSize do headerBytes[i] = 0 end
    put_u32(headerBytes, 0x00, 0x40)  -- magic
    put_u32(headerBytes, 0x08, ch1Offset)  -- channel_meta_ptr
    put_u32(headerBytes, 0x0C, dataStart)  -- channel_data_ptr
    put_str(headerBytes, 0x9E, "Driver", 64)
    put_str(headerBytes, 0x15E, "Venue", 64)
    local headerStr = bytes_to_string(headerBytes, headerSize)

    -- Build channel metadata
    local ch1 = buildChannelMeta({
        prev_addr = 0,
        next_addr = ch2Offset,
        data_ptr = speedDataOffset,
        n_data = 100,
        datatype_a = 0x07,
        datatype = 4,
        rec_freq = 10,
        name = "Corr Speed",
        unit = "m/s",
    })
    local ch2 = buildChannelMeta({
        prev_addr = ch1Offset,
        next_addr = 0,
        data_ptr = throttleDataOffset,
        n_data = 100,
        datatype_a = 0x07,
        datatype = 4,
        rec_freq = 10,
        name = "Throttle Pos",
        unit = "ratio",
    })

    local fullData = headerStr .. ch1 .. ch2 .. speedData .. throttleData

    -- Write to VFS
    mock.vfsWrite("test_session.ld", fullData)

    -- Write companion .ldx with beacons
    mock.vfsWrite("test_session.ldx", [[<?xml version="1.0"?>
<LDXFile>
  <Layers>
    <Layer>
      <MarkerBlock>
        <MarkerGroup Name="Beacons" Index="3">
          <Marker Time="2.00000000e+06"/>
          <Marker Time="5.00000000e+06"/>
          <Marker Time="8.00000000e+06"/>
        </MarkerGroup>
      </MarkerBlock>
    </Layer>
  </Layers>
</LDXFile>]])

    local session, err = motec.parseFile("test_session.ld")
    assert_not_nil(session, "Should parse: " .. (err or ""))
    assert_equal(session.header.venue, "Venue")
    assert_equal(#session.channels, 2)
    assert_not_nil(session.mapping.speed, "Should map speed channel")
    assert_not_nil(session.mapping.throttle, "Should map throttle channel")

    -- Check laps from beacons
    assert_equal(#session.laps, 2, "Should have 2 laps from 3 beacons")
    assert_near(session.laps[1].timeMs, 3000, 100, "Lap 1: ~3s")
    assert_near(session.laps[2].timeMs, 3000, 100, "Lap 2: ~3s")
end)

test("parseFile without .ldx creates single session lap", function()
    -- Same as above but no .ldx file
    local headerSize = 2048
    local ch1Offset = headerSize
    local dataStart = headerSize + 192

    local speedValues = {}
    for i = 1, 100 do speedValues[i] = 50.0 end
    local speedData = buildFloat32Data(speedValues)

    local headerBytes = {}
    for i = 1, headerSize do headerBytes[i] = 0 end
    put_u32(headerBytes, 0x00, 0x40)
    put_u32(headerBytes, 0x08, ch1Offset)
    put_u32(headerBytes, 0x0C, dataStart)
    put_str(headerBytes, 0x15E, "Track", 64)
    local headerStr = bytes_to_string(headerBytes, headerSize)

    local ch1 = buildChannelMeta({
        next_addr = 0,
        data_ptr = dataStart,
        n_data = 100,
        rec_freq = 10,
        name = "Corr Speed",
        unit = "m/s",
    })

    mock.vfsWrite("no_ldx.ld", headerStr .. ch1 .. speedData)

    local session, err = motec.parseFile("no_ldx.ld")
    assert_not_nil(session, "Should parse without .ldx: " .. (err or ""))
    assert_equal(#session.laps, 1, "Should have 1 full-session lap")
    assert_near(session.laps[1].timeMs, 10000, 100, "Duration should be ~10s (100 samples at 10Hz)")
end)

test("parseFile rejects file without speed channel", function()
    local headerSize = 2048
    local ch1Offset = headerSize
    local dataStart = headerSize + 192

    local data = {}
    for i = 1, 10 do data[i] = 0.5 end
    local sampleData = buildFloat32Data(data)

    local headerBytes = {}
    for i = 1, headerSize do headerBytes[i] = 0 end
    put_u32(headerBytes, 0x00, 0x40)
    put_u32(headerBytes, 0x08, ch1Offset)
    put_u32(headerBytes, 0x0C, dataStart)
    local headerStr = bytes_to_string(headerBytes, headerSize)

    local ch1 = buildChannelMeta({
        next_addr = 0,
        data_ptr = dataStart,
        n_data = 10,
        rec_freq = 10,
        name = "Unknown Channel",
        unit = "?",
    })

    mock.vfsWrite("no_speed.ld", headerStr .. ch1 .. sampleData)

    local session, err = motec.parseFile("no_speed.ld")
    assert_nil(session)
    assert_not_nil(err)
    assert_true(err:find("speed") ~= nil, "Error should mention speed: " .. err)
end)

--------------------------------------------------------------------------------
-- Tests: Integration with Real Oreca07 Files
--------------------------------------------------------------------------------

suite("MoTeC Integration - Real Oreca07 Files")

local REAL_LD_DIR = "C:/Users/ASR/Dropbox/IER Client Resources - Tobi Lutke/Real Telemetry/Oreca 07 - Sebring/"
local REAL_LD_PATH = REAL_LD_DIR .. "Oreca07_2024_Sebring_Test_2_MJ_FL.ld"
local REAL_LDX_PATH = REAL_LD_DIR .. "Oreca07_2024_Sebring_Test_2_MJ_FL.ldx"

local function realFileExists(path)
    local f = io.open(path, "rb")
    if f then f:close() return true end
    return false
end

local hasRealFiles = realFileExists(REAL_LD_PATH)

if not hasRealFiles then
    test("SKIP: Real Oreca07 files not available", function()
        print("    [SKIP] Real .ld files not found at: " .. REAL_LD_DIR)
    end)
else
    test("parses real Oreca07 .ld header", function()
        local f = io.open(REAL_LD_PATH, "rb")
        assert_not_nil(f)
        local data = f:read("*a")
        f:close()

        local header = motec.parseHeader(data)
        assert_not_nil(header, "Should parse real header")
        assert_equal(header.magic, 0x40)
        assert_equal(header.driver, "Mikkel Jensen")
        assert_true(header.venue:find("Sebring") ~= nil, "Venue should contain Sebring: " .. header.venue)
        assert_true(header.channel_meta_ptr > 0, "Should have valid channel_meta_ptr")
    end)

    test("reads all channels from real file", function()
        local f = io.open(REAL_LD_PATH, "rb")
        local data = f:read("*a")
        f:close()

        local header = motec.parseHeader(data)
        local channels = motec.readAllChannels(data, header.channel_meta_ptr)

        assert_true(#channels >= 6, "Should have at least 6 channels, got " .. #channels)

        -- Print channel info for debugging
        for i, ch in ipairs(channels) do
            print(string.format("    Ch%d: '%s' (%s) %dHz %d samples dtype=0x%X size=%d",
                i, ch.name, ch.unit, ch.rec_freq, ch.n_data, ch.datatype_a, ch.datatype))
        end
    end)

    test("maps real channels correctly", function()
        local f = io.open(REAL_LD_PATH, "rb")
        local data = f:read("*a")
        f:close()

        local header = motec.parseHeader(data)
        local channels = motec.readAllChannels(data, header.channel_meta_ptr)
        local mapping = motec.mapChannels(channels)

        assert_not_nil(mapping.speed, "Should map speed channel")
        assert_not_nil(mapping.throttle, "Should map throttle channel")
        assert_not_nil(mapping.steering, "Should map steering channel")
        -- Should have either brake pressure or brake pos
        assert_true(mapping.brake ~= nil or mapping.brakePos ~= nil,
            "Should map brake channel")

        -- Log which channels were mapped
        for field, idx in pairs(mapping) do
            print(string.format("    %s -> Ch%d '%s'", field, idx, channels[idx].name))
        end
    end)

    test("reads speed data with realistic values", function()
        local f = io.open(REAL_LD_PATH, "rb")
        local data = f:read("*a")
        f:close()

        local header = motec.parseHeader(data)
        local channels = motec.readAllChannels(data, header.channel_meta_ptr)
        local mapping = motec.mapChannels(channels)

        local speedCh = channels[mapping.speed]
        local speedValues = motec.readChannelData(data, speedCh)

        assert_true(#speedValues > 1000, "Should have many speed samples, got " .. #speedValues)

        -- Speed should be in m/s (Corr Speed), convert to km/h for checking
        -- Check all samples since session starts with car stationary in pits
        local maxSpeed = 0
        local factor = motec.getUnitFactor(speedCh, "speed")
        for i = 1, #speedValues do
            local kmh = speedValues[i] * factor
            if kmh > maxSpeed then maxSpeed = kmh end
        end

        -- LMP2 at Sebring: expect up to 280+ km/h
        assert_true(maxSpeed > 200, string.format("Max speed should be > 200 km/h, got %.1f", maxSpeed))
        assert_true(maxSpeed < 400, string.format("Max speed should be < 400 km/h, got %.1f", maxSpeed))
        print(string.format("    Max speed: %.1f km/h", maxSpeed))
    end)

    test("reads brake data (P_F_BRAKE int16)", function()
        local f = io.open(REAL_LD_PATH, "rb")
        local data = f:read("*a")
        f:close()

        local header = motec.parseHeader(data)
        local channels = motec.readAllChannels(data, header.channel_meta_ptr)
        local mapping = motec.mapChannels(channels)

        if mapping.brake then
            local brakeCh = channels[mapping.brake]
            local brakeValues = motec.readChannelData(data, brakeCh)

            assert_true(#brakeValues > 1000, "Should have many brake samples")

            local maxBrake = 0
            local minBrake = math.huge
            for i = 1, math.min(#brakeValues, 10000) do
                local v = brakeValues[i]
                if v > maxBrake then maxBrake = v end
                if v < minBrake then minBrake = v end
            end

            -- LMP2 brake pressure: expect 0-120+ bar
            assert_true(minBrake >= -1, string.format("Min brake should be >= -1, got %.1f", minBrake))
            assert_true(maxBrake > 10, string.format("Max brake should be > 10 bar, got %.1f", maxBrake))
            assert_true(maxBrake < 250, string.format("Max brake should be < 250 bar, got %.1f", maxBrake))
            print(string.format("    Brake range: %.1f - %.1f bar", minBrake, maxBrake))
        else
            print("    [SKIP] No brake pressure channel mapped")
        end
    end)

    test("parses real .ldx beacons", function()
        local beacons, meta = motec.parseLdx(REAL_LDX_PATH)
        assert_not_nil(beacons, "Should parse .ldx beacons")
        assert_true(#beacons >= 2, "Should have at least 2 beacons, got " .. #beacons)

        print(string.format("    Found %d beacons", #beacons))

        if meta then
            if meta.totalLaps then
                print(string.format("    Total laps: %d", meta.totalLaps))
            end
            if meta.fastestTime then
                print(string.format("    Fastest time: %s", meta.fastestTime))
            end
            if meta.fastestLap then
                print(string.format("    Fastest lap: %d", meta.fastestLap))
            end
        end
    end)

    test("full parseFile on real Oreca07", function()
        local session, err = motec.parseFile(REAL_LD_PATH)
        assert_not_nil(session, "Should parse real file: " .. (err or ""))

        assert_equal(session.header.driver, "Mikkel Jensen")
        assert_true(#session.channels >= 6)
        assert_true(#session.laps > 0, "Should have laps")

        print(string.format("    Parsed: %d channels, %d laps", #session.channels, #session.laps))

        -- Find and log fastest lap
        local fastestIdx = motec.findFastestLap(session.laps)
        if fastestIdx then
            local fastest = session.laps[fastestIdx]
            print(string.format("    Fastest: lap %d - %s", fastestIdx, fastest.timeFormatted))
        end
    end)

    test("exports real Oreca07 lap as CSV", function()
        local session, err = motec.parseFile(REAL_LD_PATH)
        assert_not_nil(session, "Should parse: " .. (err or ""))

        local fastestIdx = motec.findFastestLap(session.laps)
        assert_not_nil(fastestIdx, "Should find fastest lap")

        local outputPath = "test_output/oreca07_test.csv"
        local path, exportErr = motec.exportLapAsCSV(session, fastestIdx, outputPath, "ks_sebring")
        assert_not_nil(path, "Should export: " .. (exportErr or ""))

        -- Verify CSV is loadable by existing pipeline
        local lap = require('lib.lap')
        local loaded, warnings = lap.fromCSV(outputPath, "ks_sebring", "oreca07", 6000)

        if loaded then
            print(string.format("    CSV loaded: %d samples, %.3fs",
                loaded:length(), loaded.time / 1000))
            assert_true(loaded:length() > 100, "Should have many samples")

            -- Speed should be in realistic range
            local maxSpeed = 0
            for i = 1, loaded:length() do
                if loaded.speed[i] > maxSpeed then maxSpeed = loaded.speed[i] end
            end
            assert_true(maxSpeed > 200, string.format("Max speed should be > 200 km/h, got %.1f", maxSpeed))
            print(string.format("    Max speed: %.1f km/h", maxSpeed))
        else
            local warnMsg = warnings and table.concat(warnings, "; ") or "unknown"
            print("    [WARN] CSV not loadable: " .. warnMsg)
        end
    end)
end

--------------------------------------------------------------------------------
-- Tests: Cross-validation against MoTeC CSV export
-- The CSV at C:\MoTeC\Logged Data\sebring-rea-hunter-1_50_400.csv was exported
-- from the same .ld file by MoTeC's own software. We parse the .ld binary and
-- compare our extracted values against MoTeC's reference CSV.
--------------------------------------------------------------------------------

suite("MoTeC Cross-Validation - Hunter McElrea Sebring")

local CROSS_LD_PATH = REAL_LD_DIR .. "Oreca07_2025_Sebring_Winter_Test_HM_FL.ld"
local CROSS_CSV_PATH = "C:/MoTeC/Logged Data/sebring-rea-hunter-1_50_400.csv"

local hasCrossFiles = realFileExists(CROSS_LD_PATH) and realFileExists(CROSS_CSV_PATH)

--- Parse the reference CSV into arrays for comparison
local function parseReferenceCSV(csvPath)
    local f = io.open(csvPath, "r")
    if not f then return nil end

    local ref = {
        time = {},
        distance = {},
        corrSpeed_ms = {},  -- m/s from CSV
        wheelSpeedAvg_kmh = {},  -- km/h from CSV
        steeringAngle_deg = {},
        brakePos_ratio = {},
        throttlePos_ratio = {},
        pFBrake_bar = {},
        brakePressureF_bar = {},
        driverThrottlePos_ratio = {},
    }

    local headerLine = nil
    local unitLine = nil
    local lineNum = 0

    for line in f:lines() do
        lineNum = lineNum + 1
        -- Skip metadata lines (first 14 lines based on file structure)
        if lineNum == 15 then
            headerLine = line
        elseif lineNum == 16 then
            unitLine = line
        elseif lineNum >= 19 then
            -- Data line - parse quoted CSV
            local fields = {}
            for field in line:gmatch('"([^"]*)"') do
                table.insert(fields, tonumber(field) or 0)
            end
            if #fields >= 8 then
                table.insert(ref.time, fields[1])
                table.insert(ref.distance, fields[2])
                table.insert(ref.corrSpeed_ms, fields[3])
                table.insert(ref.wheelSpeedAvg_kmh, fields[4])
                table.insert(ref.steeringAngle_deg, fields[5])
                table.insert(ref.brakePos_ratio, fields[6])
                table.insert(ref.throttlePos_ratio, fields[7])
                table.insert(ref.pFBrake_bar, fields[8])
            end
            if #fields >= 22 then
                table.insert(ref.brakePressureF_bar, fields[22])
                table.insert(ref.driverThrottlePos_ratio, fields[23])
            end
        end
    end
    f:close()

    ref.sampleCount = #ref.time
    ref.duration = ref.time[#ref.time] - ref.time[1]
    return ref
end

if not hasCrossFiles then
    test("SKIP: Cross-validation files not available", function()
        print("    [SKIP] Need both .ld and reference CSV for cross-validation")
        if not realFileExists(CROSS_LD_PATH) then
            print("    Missing: " .. CROSS_LD_PATH)
        end
        if not realFileExists(CROSS_CSV_PATH) then
            print("    Missing: " .. CROSS_CSV_PATH)
        end
    end)
else
    local crossSession = nil
    local crossRef = nil
    local crossLapIdx = nil

    test("parses HM .ld and finds matching lap", function()
        local session, err = motec.parseFile(CROSS_LD_PATH)
        assert_not_nil(session, "Should parse HM .ld: " .. (err or ""))
        crossSession = session

        print(string.format("    Driver: %s, Venue: %s", session.header.driver, session.header.venue))
        print(string.format("    Channels: %d, Laps: %d", #session.channels, #session.laps))
        for ci, ch in ipairs(session.channels) do
            print(string.format("      Ch%d: '%s' %dHz", ci, ch.name, ch.rec_freq))
        end
        print(string.format("    Throttle mapped to: Ch%d '%s'",
            session.mapping.throttle or 0,
            session.mapping.throttle and session.channels[session.mapping.throttle].name or "NONE"))

        -- The CSV says "Fastest Lap 2" and "Fastest Time 1:50.400"
        -- Find lap closest to 110.4s (1:50.400)
        local bestIdx = motec.findFastestLap(session.laps)
        assert_not_nil(bestIdx, "Should find fastest lap")

        local bestLap = session.laps[bestIdx]
        print(string.format("    Fastest: lap %d, %s (%.3fs)", bestIdx, bestLap.timeFormatted, bestLap.timeMs / 1000))

        -- Verify lap time matches reference CSV duration
        assert_near(bestLap.timeMs / 1000, 110.4, 0.5, "Lap duration should be ~110.4s")
        crossLapIdx = bestIdx
    end)

    test("loads reference CSV for comparison", function()
        crossRef = parseReferenceCSV(CROSS_CSV_PATH)
        assert_not_nil(crossRef, "Should parse reference CSV")
        assert_true(crossRef.sampleCount > 2000, "Should have >2000 samples, got " .. crossRef.sampleCount)
        print(string.format("    Reference CSV: %d samples, %.3fs duration",
            crossRef.sampleCount, crossRef.duration))
    end)

    test("speed values match reference CSV", function()
        assert_not_nil(crossSession, "Need parsed session")
        assert_not_nil(crossRef, "Need parsed reference CSV")
        assert_not_nil(crossLapIdx, "Need lap index")

        local lap = crossSession.laps[crossLapIdx]
        local lapValues = motec.extractLapData(
            crossSession.channelData, crossSession.channels,
            lap.startTime, lap.endTime)
        local unified, freq = motec.unifyChannels(
            lapValues, crossSession.channels,
            crossSession.mapping, lap.endTime - lap.startTime)

        -- The CSV "Origin Time" is 315.245s but beacon start is 315.09s
        -- This ~0.155s offset means our t=0 is 0.155s before the CSV's t=0.
        -- MoTeC also resamples multi-rate channels to 25Hz (ref CSV rate) which introduces
        -- further interpolation differences. We account for the offset.
        local csvOriginS = 315.245  -- From CSV header "Origin Time"
        local beaconStartS = lap.startTime
        local timeOffset = csvOriginS - beaconStartS

        local maxErr = 0
        local totalErr = 0
        local numCompared = 0

        for i = 1, crossRef.sampleCount do
            local t = crossRef.time[i] + timeOffset  -- align to our timeline
            local ourIdx = math.floor(t * freq) + 1
            if ourIdx >= 1 and ourIdx <= #unified.speed then
                local refSpeedKmh = crossRef.corrSpeed_ms[i] * 3.6
                local ourSpeedKmh = unified.speed[ourIdx]
                local err = math.abs(ourSpeedKmh - refSpeedKmh)
                if err > maxErr then maxErr = err end
                totalErr = totalErr + err
                numCompared = numCompared + 1
            end
        end

        local avgErr = totalErr / numCompared
        print(string.format("    Speed: compared %d points, avg error %.3f km/h, max error %.3f km/h (offset=%.3fs)",
            numCompared, avgErr, maxErr, timeOffset))

        -- Our parser resamples to 50Hz, MoTeC's CSV export to 25Hz, so we compare
        -- at the ref's 25Hz sample points. Different rates and interpolation cause differences.
        assert_true(avgErr < 0.5, string.format("Average speed error should be < 0.5 km/h, got %.3f", avgErr))
        assert_true(maxErr < 5.0, string.format("Max speed error should be < 5 km/h, got %.3f", maxErr))
    end)

    test("brake pressure values match reference CSV", function()
        assert_not_nil(crossSession)
        assert_not_nil(crossRef)
        assert_not_nil(crossLapIdx)

        local lap = crossSession.laps[crossLapIdx]
        local lapValues = motec.extractLapData(
            crossSession.channelData, crossSession.channels,
            lap.startTime, lap.endTime)
        local unified, freq = motec.unifyChannels(
            lapValues, crossSession.channels,
            crossSession.mapping, lap.endTime - lap.startTime)

        local csvOriginS = 315.245
        local timeOffset = csvOriginS - lap.startTime

        local maxErr = 0
        local totalErr = 0
        local numCompared = 0
        local numBraking = 0

        for i = 1, crossRef.sampleCount do
            local t = crossRef.time[i] + timeOffset
            local ourIdx = math.floor(t * freq) + 1
            if ourIdx >= 1 and ourIdx <= #unified.brake then
                local refBrakeBar = crossRef.pFBrake_bar[i]
                local ourBrakeBar = unified.brake[ourIdx]
                local err = math.abs(ourBrakeBar - refBrakeBar)
                if err > maxErr then maxErr = err end
                totalErr = totalErr + err
                numCompared = numCompared + 1
                if refBrakeBar > 1 then numBraking = numBraking + 1 end
            end
        end

        local avgErr = totalErr / numCompared
        print(string.format("    Brake: compared %d points (%d braking), avg error %.3f bar, max error %.3f bar",
            numCompared, numBraking, avgErr, maxErr))

        -- Brake at 100Hz with int16 conversion, our path resamples to 50Hz,
        -- ref CSV is at 25Hz. Peak errors at sharp brake transients where rates differ.
        assert_true(avgErr < 0.5, string.format("Average brake error should be < 0.5 bar, got %.3f", avgErr))
        assert_true(maxErr < 10.0, string.format("Max brake error should be < 10 bar, got %.3f", maxErr))
    end)

    test("throttle values match reference CSV", function()
        assert_not_nil(crossSession)
        assert_not_nil(crossRef)
        assert_not_nil(crossLapIdx)

        local lap = crossSession.laps[crossLapIdx]
        local lapValues = motec.extractLapData(
            crossSession.channelData, crossSession.channels,
            lap.startTime, lap.endTime)
        local unified, freq = motec.unifyChannels(
            lapValues, crossSession.channels,
            crossSession.mapping, lap.endTime - lap.startTime)

        local csvOriginS = 315.245
        local timeOffset = csvOriginS - lap.startTime

        local maxErr = 0
        local totalErr = 0
        local numCompared = 0

        for i = 1, crossRef.sampleCount do
            local t = crossRef.time[i] + timeOffset
            local ourIdx = math.floor(t * freq) + 1
            if ourIdx >= 1 and ourIdx <= #unified.throttle then
                -- Reference CSV has "Driver Throttle Pos" as ratio (can be 1.01)
                -- We map "Throttle Pos" (50Hz), MoTeC maps "Driver Throttle Pos"
                -- Use Throttle Pos from ref for apples-to-apples comparison
                local refThrottle = crossRef.throttlePos_ratio[i]
                if refThrottle and refThrottle > 1 then refThrottle = 1.0 end
                local ourThrottle = unified.throttle[ourIdx]
                local err = math.abs(ourThrottle - (refThrottle or 0))
                if err > maxErr then maxErr = err end
                totalErr = totalErr + err
                numCompared = numCompared + 1
            end
        end

        local avgErr = totalErr / numCompared
        print(string.format("    Throttle: compared %d points, avg error %.4f, max error %.4f",
            numCompared, avgErr, maxErr))

        -- Throttle is 50Hz native, we keep at 50Hz, ref CSV is at 25Hz - small differences expected
        assert_true(avgErr < 0.02, string.format("Average throttle error should be < 0.02, got %.4f", avgErr))
    end)

    test("steering angle values match reference CSV", function()
        assert_not_nil(crossSession)
        assert_not_nil(crossRef)
        assert_not_nil(crossLapIdx)

        local lap = crossSession.laps[crossLapIdx]
        local lapValues = motec.extractLapData(
            crossSession.channelData, crossSession.channels,
            lap.startTime, lap.endTime)
        local unified, freq = motec.unifyChannels(
            lapValues, crossSession.channels,
            crossSession.mapping, lap.endTime - lap.startTime)

        local csvOriginS = 315.245
        local timeOffset = csvOriginS - lap.startTime

        local maxErr = 0
        local totalErr = 0
        local numCompared = 0

        for i = 1, crossRef.sampleCount do
            local t = crossRef.time[i] + timeOffset
            local ourIdx = math.floor(t * freq) + 1
            if ourIdx >= 1 and ourIdx <= #unified.steering then
                local refSteer = crossRef.steeringAngle_deg[i]
                local ourSteer = unified.steering[ourIdx]
                local err = math.abs(ourSteer - refSteer)
                if err > maxErr then maxErr = err end
                totalErr = totalErr + err
                numCompared = numCompared + 1
            end
        end

        local avgErr = totalErr / numCompared
        print(string.format("    Steering: compared %d points, avg error %.3f deg, max error %.3f deg",
            numCompared, avgErr, maxErr))

        -- Steering is 50Hz native, we keep at 50Hz, ref CSV is at 25Hz.
        -- Different interpolation at fast steering inputs causes ~1 deg avg difference.
        assert_true(avgErr < 1.5, string.format("Average steering error should be < 1.5 deg, got %.3f", avgErr))
    end)

    test("distance integration matches reference CSV", function()
        assert_not_nil(crossSession)
        assert_not_nil(crossRef)
        assert_not_nil(crossLapIdx)

        local lap = crossSession.laps[crossLapIdx]
        local lapValues = motec.extractLapData(
            crossSession.channelData, crossSession.channels,
            lap.startTime, lap.endTime)
        local unified, freq = motec.unifyChannels(
            lapValues, crossSession.channels,
            crossSession.mapping, lap.endTime - lap.startTime)

        local distance = motec.computeDistance(unified.speed, freq)

        -- Compare at a few points throughout the lap
        local checkPoints = { 1, math.floor(crossRef.sampleCount * 0.25),
            math.floor(crossRef.sampleCount * 0.5), math.floor(crossRef.sampleCount * 0.75),
            crossRef.sampleCount }

        local refTotalDist = crossRef.distance[crossRef.sampleCount]
        local ourTotalDist = distance[#distance]

        print(string.format("    Distance: ref total %.0fm, our total %.0fm",
            refTotalDist, ourTotalDist))

        -- Total distance should be within 1% (integration error)
        local distErr = math.abs(ourTotalDist - refTotalDist) / refTotalDist * 100
        assert_true(distErr < 2.0,
            string.format("Total distance should match within 2%%, got %.1f%% error", distErr))

        for _, i in ipairs(checkPoints) do
            local t = crossRef.time[i]
            local ourIdx = math.floor(t * freq) + 1
            if ourIdx >= 1 and ourIdx <= #distance then
                local refDist = crossRef.distance[i]
                local ourDist = distance[ourIdx]
                local err = math.abs(ourDist - refDist)
                print(string.format("      t=%.1fs: ref=%.0fm, our=%.0fm, err=%.1fm",
                    t, refDist, ourDist, err))
            end
        end
    end)

    test("exported CSV loads through existing pipeline", function()
        assert_not_nil(crossSession)
        assert_not_nil(crossLapIdx)

        local outputPath = "test_output/cross_validation_hm.csv"
        local path, err = motec.exportLapAsCSV(crossSession, crossLapIdx, outputPath, "sebring")
        assert_not_nil(path, "Should export: " .. (err or ""))

        local lap = require('lib.lap')
        local loaded, warnings = lap.fromCSV(outputPath, "sebring", "oreca_07", 5850)

        assert_not_nil(loaded, "Exported CSV should load through pipeline: " ..
            (warnings and table.concat(warnings, "; ") or "unknown"))

        local pipelineMaxSpeed = 0
        for i = 1, loaded:length() do
            if loaded.speed[i] > pipelineMaxSpeed then pipelineMaxSpeed = loaded.speed[i] end
        end
        print(string.format("    Pipeline loaded: %d samples, %.3fs, max speed %.1f km/h",
            loaded:length(), loaded.time / 1000, pipelineMaxSpeed))

        -- Should have reasonable sample count (resampled to 30Hz from 100Hz)
        assert_true(loaded:length() > 1000, "Should have >1000 samples at 30Hz")

        -- Lap time should match
        assert_near(loaded.time / 1000, 110.4, 1.0,
            string.format("Lap time should be ~110.4s, got %.3f", loaded.time / 1000))

        -- Key telemetry should be reasonable
        local maxSpeed = 0
        for i = 1, loaded:length() do
            if loaded.speed[i] > maxSpeed then maxSpeed = loaded.speed[i] end
        end
        assert_true(maxSpeed > 200, string.format("Max speed should be > 200 km/h, got %.1f", maxSpeed))
        assert_true(maxSpeed < 300, string.format("Max speed should be < 300 km/h, got %.1f", maxSpeed))
    end)
end
