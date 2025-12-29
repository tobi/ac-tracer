---@meta
---@diagnostic disable: lowercase-global

---@alias ac.DebugCollectMode
---| `ac.DebugCollectMode.Average` @Value: 0.
---| `ac.DebugCollectMode.Minimum` @Value: 1.
---| `ac.DebugCollectMode.Maximum` @Value: 2.
ac.DebugCollectMode = {
  Average = 0, ---@type ac.DebugCollectMode #Value: 0.
  Minimum = 1, ---@type ac.DebugCollectMode #Value: 1.
  Maximum = 2, ---@type ac.DebugCollectMode #Value: 2.
}

---@alias ac.INIFormat
---| `ac.INIFormat.Default` @AC format: no quotes, “[” in value begins a new section, etc.
---| `ac.INIFormat.DefaultAcd` @AC format, but also with support for reading files from `data.acd` (makes difference only for `ac.INIConfig.load()`).
---| `ac.INIFormat.Extended` @Quotes are allowed, comma-separated value turns into multiple values (for vectors and lists), repeated keys replace previous values.
---| `ac.INIFormat.ExtendedIncludes` @Same as CSP, but also with support for INIpp expressions and includes.
ac.INIFormat = {
  Default = 0, ---@type ac.INIFormat #AC format: no quotes, “[” in value begins a new section, etc.
  DefaultAcd = 1, ---@type ac.INIFormat #AC format, but also with support for reading files from `data.acd` (makes difference only for `ac.INIConfig.load()`).
  Extended = 10, ---@type ac.INIFormat #Quotes are allowed, comma-separated value turns into multiple values (for vectors and lists), repeated keys replace previous values.
  ExtendedIncludes = 11, ---@type ac.INIFormat #Same as CSP, but also with support for INIpp expressions and includes.
}

---@alias ac.LightType
---| `ac.LightType.Regular` @Value: 1.
---| `ac.LightType.Line` @Value: 2.
ac.LightType = {
  Regular = 1, ---@type ac.LightType #Value: 1.
  Line = 2, ---@type ac.LightType #Value: 2.
}

---@alias ac.IncludeType
---| `ac.IncludeType.None` @Value: 0.
---| `ac.IncludeType.Car` @Value: 1.
---| `ac.IncludeType.Track` @Value: 2.
ac.IncludeType = {
  None = 0, ---@type ac.IncludeType #Value: 0.
  Car = 1, ---@type ac.IncludeType #Value: 1.
  Track = 2, ---@type ac.IncludeType #Value: 2.
}

---@alias ac.FogAlgorithm
---| `ac.FogAlgorithm.Original` @Value: 0.
---| `ac.FogAlgorithm.New` @Value: 1.
ac.FogAlgorithm = {
  Original = 0, ---@type ac.FogAlgorithm #Value: 0.
  New = 1, ---@type ac.FogAlgorithm #Value: 1.
}

---@alias ac.SurfaceType
---| `ac.SurfaceType.Grass` @Value: 0.
---| `ac.SurfaceType.Dirt` @Value: 1.
---| `ac.SurfaceType.Snow` @-Could also be ice.
---| `ac.SurfaceType.Default` @Value: 255.
ac.SurfaceType = {
  Grass = 0, ---@type ac.SurfaceType #Value: 0.
  Dirt = 1, ---@type ac.SurfaceType #Value: 1.
  Snow = 2, ---@type ac.SurfaceType #-Could also be ice.
  Default = 255, ---@type ac.SurfaceType #Value: 255.
}

---@alias ac.SurfaceExtendedType
---| `ac.SurfaceExtendedType.Base` @Value: 0.
---| `ac.SurfaceExtendedType.ExtraTurf` @Value: 1.
---| `ac.SurfaceExtendedType.Grass` @Value: 2.
---| `ac.SurfaceExtendedType.Gravel` @Value: 3.
---| `ac.SurfaceExtendedType.Kerb` @Value: 4.
---| `ac.SurfaceExtendedType.Old` @Value: 5.
---| `ac.SurfaceExtendedType.Sand` @Value: 6.
---| `ac.SurfaceExtendedType.Ice` @Value: 7.
---| `ac.SurfaceExtendedType.Snow` @Value: 8.
ac.SurfaceExtendedType = {
  Base = 0, ---@type ac.SurfaceExtendedType #Value: 0.
  ExtraTurf = 1, ---@type ac.SurfaceExtendedType #Value: 1.
  Grass = 2, ---@type ac.SurfaceExtendedType #Value: 2.
  Gravel = 3, ---@type ac.SurfaceExtendedType #Value: 3.
  Kerb = 4, ---@type ac.SurfaceExtendedType #Value: 4.
  Old = 5, ---@type ac.SurfaceExtendedType #Value: 5.
  Sand = 6, ---@type ac.SurfaceExtendedType #Value: 6.
  Ice = 7, ---@type ac.SurfaceExtendedType #Value: 7.
  Snow = 8, ---@type ac.SurfaceExtendedType #Value: 8.
}

---@alias ac.ShadowsState
---| `ac.ShadowsState.Off` @Value: 0.
---| `ac.ShadowsState.On` @Value: 1.
---| `ac.ShadowsState.EverythingShadowed` @Value: 2.
ac.ShadowsState = {
  Off = 0, ---@type ac.ShadowsState #Value: 0.
  On = 1, ---@type ac.ShadowsState #Value: 1.
  EverythingShadowed = 2, ---@type ac.ShadowsState #Value: 2.
}

---@alias ac.TextureState
---| `ac.TextureState.Empty` @Value: 0.
---| `ac.TextureState.Loading` @Value: 1.
---| `ac.TextureState.Failed` @Value: 2.
---| `ac.TextureState.Ready` @Value: 3.
ac.TextureState = {
  Empty = 0, ---@type ac.TextureState #Value: 0.
  Loading = 1, ---@type ac.TextureState #Value: 1.
  Failed = 2, ---@type ac.TextureState #Value: 2.
  Ready = 3, ---@type ac.TextureState #Value: 3.
}

---@alias ac.CameraMode
---| `ac.CameraMode.Cockpit` @First person view.
---| `ac.CameraMode.Car` @F6 camera.
---| `ac.CameraMode.Drivable` @Chase/bonnet/bumper/dash cameras.
---| `ac.CameraMode.Track` @Replay camera.
---| `ac.CameraMode.Helicopter` @Moving replay camera.
---| `ac.CameraMode.OnBoardFree` @F5 camera.
---| `ac.CameraMode.Free` @F7 camera.
---| `ac.CameraMode.Deprecated` @Value: 7.
---| `ac.CameraMode.ImageGeneratorCamera` @Value: 8.
---| `ac.CameraMode.Start` @Starting camera.
ac.CameraMode = {
  Cockpit = 0, ---@type ac.CameraMode #First person view.
  Car = 1, ---@type ac.CameraMode #F6 camera.
  Drivable = 2, ---@type ac.CameraMode #Chase/bonnet/bumper/dash cameras.
  Track = 3, ---@type ac.CameraMode #Replay camera.
  Helicopter = 4, ---@type ac.CameraMode #Moving replay camera.
  OnBoardFree = 5, ---@type ac.CameraMode #F5 camera.
  Free = 6, ---@type ac.CameraMode #F7 camera.
  Deprecated = 7, ---@type ac.CameraMode #Value: 7.
  ImageGeneratorCamera = 8, ---@type ac.CameraMode #Value: 8.
  Start = 9, ---@type ac.CameraMode #Starting camera.
}

---@alias ac.DrivableCamera
---| `ac.DrivableCamera.Chase` @Value: 0.
---| `ac.DrivableCamera.Chase2` @Value: 1.
---| `ac.DrivableCamera.Bonnet` @Value: 2.
---| `ac.DrivableCamera.Bumper` @Value: 3.
---| `ac.DrivableCamera.Dash` @Value: 4.
ac.DrivableCamera = {
  Chase = 0, ---@type ac.DrivableCamera #Value: 0.
  Chase2 = 1, ---@type ac.DrivableCamera #Value: 1.
  Bonnet = 2, ---@type ac.DrivableCamera #Value: 2.
  Bumper = 3, ---@type ac.DrivableCamera #Value: 3.
  Dash = 4, ---@type ac.DrivableCamera #Value: 4.
}

---Wheel index (from 0 to 3) or a special value for wheel mask.
---@alias ac.Wheel
---| `ac.Wheel.FrontLeft` @Value: 0.
---| `ac.Wheel.FrontRight` @Value: 1.
---| `ac.Wheel.RearLeft` @Value: 2.
---| `ac.Wheel.RearRight` @Value: 3.
---| `ac.Wheel.Front` @Value: 12.
---| `ac.Wheel.Rear` @Value: 48.
---| `ac.Wheel.Left` @Value: 20.
---| `ac.Wheel.Right` @Value: 40.
---| `ac.Wheel.All` @Value: 60.
ac.Wheel = {
  FrontLeft = 0, ---@type ac.Wheel #Value: 0.
  FrontRight = 1, ---@type ac.Wheel #Value: 1.
  RearLeft = 2, ---@type ac.Wheel #Value: 2.
  RearRight = 3, ---@type ac.Wheel #Value: 3.
  Front = 12, ---@type ac.Wheel #Value: 12.
  Rear = 48, ---@type ac.Wheel #Value: 48.
  Left = 20, ---@type ac.Wheel #Value: 20.
  Right = 40, ---@type ac.Wheel #Value: 40.
  All = 60, ---@type ac.Wheel #Value: 60.
}

---@alias ac.MirrorPieceRole
---| `ac.MirrorPieceRole.None` @Value: 0.
---| `ac.MirrorPieceRole.Top` @Value: 1.
---| `ac.MirrorPieceRole.Left` @Value: 2.
---| `ac.MirrorPieceRole.Right` @Value: 4.
ac.MirrorPieceRole = {
  None = 0, ---@type ac.MirrorPieceRole #Value: 0.
  Top = 1, ---@type ac.MirrorPieceRole #Value: 1.
  Left = 2, ---@type ac.MirrorPieceRole #Value: 2.
  Right = 4, ---@type ac.MirrorPieceRole #Value: 4.
}

---@alias ac.MirrorPieceFlip
---| `ac.MirrorPieceFlip.None` @Value: 0.
---| `ac.MirrorPieceFlip.Horizontal` @Value: 1.
---| `ac.MirrorPieceFlip.Vertical` @Value: 2.
---| `ac.MirrorPieceFlip.Both` @Value: 3.
ac.MirrorPieceFlip = {
  None = 0, ---@type ac.MirrorPieceFlip #Value: 0.
  Horizontal = 1, ---@type ac.MirrorPieceFlip #Value: 1.
  Vertical = 2, ---@type ac.MirrorPieceFlip #Value: 2.
  Both = 3, ---@type ac.MirrorPieceFlip #Value: 3.
}

---@alias ac.MirrorMonitorType
---| `ac.MirrorMonitorType.TN` @Oldschool displays with a lot of color distortion.
---| `ac.MirrorMonitorType.VA` @Medium tier, less color distortion.
---| `ac.MirrorMonitorType.IPS` @Almost no color distortion.
ac.MirrorMonitorType = {
  TN = 0, ---@type ac.MirrorMonitorType #Oldschool displays with a lot of color distortion.
  VA = 2, ---@type ac.MirrorMonitorType #Medium tier, less color distortion.
  IPS = 1, ---@type ac.MirrorMonitorType #Almost no color distortion.
}

---@alias ac.WeatherType
---| `ac.WeatherType.LightThunderstorm` @Value: 0.
---| `ac.WeatherType.Thunderstorm` @Value: 1.
---| `ac.WeatherType.HeavyThunderstorm` @Value: 2.
---| `ac.WeatherType.LightDrizzle` @Value: 3.
---| `ac.WeatherType.Drizzle` @Value: 4.
---| `ac.WeatherType.HeavyDrizzle` @Value: 5.
---| `ac.WeatherType.LightRain` @Value: 6.
---| `ac.WeatherType.Rain` @Value: 7.
---| `ac.WeatherType.HeavyRain` @Value: 8.
---| `ac.WeatherType.LightSnow` @Value: 9.
---| `ac.WeatherType.Snow` @Value: 10.
---| `ac.WeatherType.HeavySnow` @Value: 11.
---| `ac.WeatherType.LightSleet` @Value: 12.
---| `ac.WeatherType.Sleet` @Value: 13.
---| `ac.WeatherType.HeavySleet` @Value: 14.
---| `ac.WeatherType.Clear` @Value: 15.
---| `ac.WeatherType.FewClouds` @Value: 16.
---| `ac.WeatherType.ScatteredClouds` @Value: 17.
---| `ac.WeatherType.BrokenClouds` @Value: 18.
---| `ac.WeatherType.OvercastClouds` @Value: 19.
---| `ac.WeatherType.Fog` @Value: 20.
---| `ac.WeatherType.Mist` @Value: 21.
---| `ac.WeatherType.Smoke` @Value: 22.
---| `ac.WeatherType.Haze` @Value: 23.
---| `ac.WeatherType.Sand` @Value: 24.
---| `ac.WeatherType.Dust` @Value: 25.
---| `ac.WeatherType.Squalls` @Value: 26.
---| `ac.WeatherType.Tornado` @Value: 27.
---| `ac.WeatherType.Hurricane` @Value: 28.
---| `ac.WeatherType.Cold` @Value: 29.
---| `ac.WeatherType.Hot` @Value: 30.
---| `ac.WeatherType.Windy` @Value: 31.
---| `ac.WeatherType.Hail` @Value: 32.
ac.WeatherType = {
  LightThunderstorm = 0, ---@type ac.WeatherType #Value: 0.
  Thunderstorm = 1, ---@type ac.WeatherType #Value: 1.
  HeavyThunderstorm = 2, ---@type ac.WeatherType #Value: 2.
  LightDrizzle = 3, ---@type ac.WeatherType #Value: 3.
  Drizzle = 4, ---@type ac.WeatherType #Value: 4.
  HeavyDrizzle = 5, ---@type ac.WeatherType #Value: 5.
  LightRain = 6, ---@type ac.WeatherType #Value: 6.
  Rain = 7, ---@type ac.WeatherType #Value: 7.
  HeavyRain = 8, ---@type ac.WeatherType #Value: 8.
  LightSnow = 9, ---@type ac.WeatherType #Value: 9.
  Snow = 10, ---@type ac.WeatherType #Value: 10.
  HeavySnow = 11, ---@type ac.WeatherType #Value: 11.
  LightSleet = 12, ---@type ac.WeatherType #Value: 12.
  Sleet = 13, ---@type ac.WeatherType #Value: 13.
  HeavySleet = 14, ---@type ac.WeatherType #Value: 14.
  Clear = 15, ---@type ac.WeatherType #Value: 15.
  FewClouds = 16, ---@type ac.WeatherType #Value: 16.
  ScatteredClouds = 17, ---@type ac.WeatherType #Value: 17.
  BrokenClouds = 18, ---@type ac.WeatherType #Value: 18.
  OvercastClouds = 19, ---@type ac.WeatherType #Value: 19.
  Fog = 20, ---@type ac.WeatherType #Value: 20.
  Mist = 21, ---@type ac.WeatherType #Value: 21.
  Smoke = 22, ---@type ac.WeatherType #Value: 22.
  Haze = 23, ---@type ac.WeatherType #Value: 23.
  Sand = 24, ---@type ac.WeatherType #Value: 24.
  Dust = 25, ---@type ac.WeatherType #Value: 25.
  Squalls = 26, ---@type ac.WeatherType #Value: 26.
  Tornado = 27, ---@type ac.WeatherType #Value: 27.
  Hurricane = 28, ---@type ac.WeatherType #Value: 28.
  Cold = 29, ---@type ac.WeatherType #Value: 29.
  Hot = 30, ---@type ac.WeatherType #Value: 30.
  Windy = 31, ---@type ac.WeatherType #Value: 31.
  Hail = 32, ---@type ac.WeatherType #Value: 32.
}

---@alias ac.TonemapFunction
---| `ac.TonemapFunction.Linear` @Simple linear mapping.
---| `ac.TonemapFunction.LinearClamped` @Linear mapping (LDR clamp).
---| `ac.TonemapFunction.Sensitometric` @Simple simulation of response of film, CCD, etc., recommended.
---| `ac.TonemapFunction.Reinhard` @Reinhard.
---| `ac.TonemapFunction.ReinhardLum` @Saturation retention type Reinhard tone map function.
---| `ac.TonemapFunction.Log` @Tone map function for the logarithmic space.
---| `ac.TonemapFunction.LogLum` @Saturation retention type logarithmic space tone map function.
---| `ac.TonemapFunction.ACES` @ACES.
---| `ac.TonemapFunction.Uchimura` @GT-like by Uchimura.
---| `ac.TonemapFunction.RomBinDaHouse` @Tonemapping by RomBinDaHouse.
---| `ac.TonemapFunction.Lottes` @Tonemapping by Lottes.
---| `ac.TonemapFunction.Uncharted` @Tonemapping used in Uncharted.
---| `ac.TonemapFunction.Unreal` @Tonemapping commonly used in UE.
---| `ac.TonemapFunction.Filmic` @Filmic tonemapping.
---| `ac.TonemapFunction.ReinhardWp` @White-preserving Reinhard.
---| `ac.TonemapFunction.Juicy` @Experimental, better preserving saturation.
---| `ac.TonemapFunction.AgX` @Might be the best one, based on https://iolite-engine.com/blog_posts/minimal_agx_implementation.
ac.TonemapFunction = {
  Linear = 0, ---@type ac.TonemapFunction #Simple linear mapping.
  LinearClamped = 1, ---@type ac.TonemapFunction #Linear mapping (LDR clamp).
  Sensitometric = 2, ---@type ac.TonemapFunction #Simple simulation of response of film, CCD, etc., recommended.
  Reinhard = 3, ---@type ac.TonemapFunction #Reinhard.
  ReinhardLum = 4, ---@type ac.TonemapFunction #Saturation retention type Reinhard tone map function.
  Log = 5, ---@type ac.TonemapFunction #Tone map function for the logarithmic space.
  LogLum = 6, ---@type ac.TonemapFunction #Saturation retention type logarithmic space tone map function.
  ACES = 7, ---@type ac.TonemapFunction #ACES.
  Uchimura = 8, ---@type ac.TonemapFunction #GT-like by Uchimura.
  RomBinDaHouse = 9, ---@type ac.TonemapFunction #Tonemapping by RomBinDaHouse.
  Lottes = 10, ---@type ac.TonemapFunction #Tonemapping by Lottes.
  Uncharted = 11, ---@type ac.TonemapFunction #Tonemapping used in Uncharted.
  Unreal = 12, ---@type ac.TonemapFunction #Tonemapping commonly used in UE.
  Filmic = 13, ---@type ac.TonemapFunction #Filmic tonemapping.
  ReinhardWp = 14, ---@type ac.TonemapFunction #White-preserving Reinhard.
  Juicy = 15, ---@type ac.TonemapFunction #Experimental, better preserving saturation.
  AgX = 16, ---@type ac.TonemapFunction #Might be the best one, based on https://iolite-engine.com/blog_posts/minimal_agx_implementation.
}

---@alias ac.FolderID
---| `ac.FolderID.AppData` @…/AppData.
---| `ac.FolderID.Documents` @…/Documents.
---| `ac.FolderID.Root` @…/SteamApps/common/assettocorsa.
---| `ac.FolderID.Cfg` @…/Documents/Assetto Corsa/cfg.
---| `ac.FolderID.Logs` @…/Documents/Assetto Corsa/logs.
---| `ac.FolderID.Screenshots` @…/Documents/Assetto Corsa/screens.
---| `ac.FolderID.Replays` @…/Documents/Assetto Corsa/replay.
---| `ac.FolderID.ReplaysTemp` @…/Documents/Assetto Corsa/replay/temp.
---| `ac.FolderID.UserSetups` @…/Documents/Assetto Corsa/setups.
---| `ac.FolderID.PPFilters` @…/SteamApps/common/assettocorsa/system/cfg/ppfilters.
---| `ac.FolderID.ContentCars` @…/SteamApps/common/assettocorsa/content/cars.
---| `ac.FolderID.ContentDrivers` @…/SteamApps/common/assettocorsa/content/drivers.
---| `ac.FolderID.ContentTracks` @…/SteamApps/common/assettocorsa/content/tracks.
---| `ac.FolderID.ExtRoot` @…/SteamApps/common/assettocorsa/extension.
---| `ac.FolderID.ExtCfgSys` @…/SteamApps/common/assettocorsa/extension/config.
---| `ac.FolderID.ExtCfgUser` @…/Documents/Assetto Corsa/cfg/extension.
---| `ac.FolderID.ExtTextures` @…/SteamApps/common/assettocorsa/extension/textures.
---| `ac.FolderID.ACApps` @…/SteamApps/common/assettocorsa/apps.
---| `ac.FolderID.ACAppsLua` @…/SteamApps/common/assettocorsa/apps/lua.
---| `ac.FolderID.ACAppsPython` @…/SteamApps/common/assettocorsa/apps/python.
---| `ac.FolderID.ExtCfgState` @…/Documents/Assetto Corsa/cfg/extension/state (changing configs there does not trigger any live reloads).
---| `ac.FolderID.ContentFonts` @…/SteamApps/common/assettocorsa/content/fonts.
---| `ac.FolderID.RaceResults` @…/Documents/Assetto Corsa/out.
---| `ac.FolderID.AppDataLocal` @…/AppData/Local.
---| `ac.FolderID.ExtFonts` @…/SteamApps/common/assettocorsa/extension/fonts.
---| `ac.FolderID.ACDocuments` @…/Documents/Assetto Corsa.
---| `ac.FolderID.ExtLua` @…/SteamApps/common/assettocorsa/extension/lua.
---| `ac.FolderID.ExtCache` @…/SteamApps/common/assettocorsa/cache.
---| `ac.FolderID.AppDataTemp` @…/AppData/Local/Temp.
---| `ac.FolderID.ExtInternal` @…/SteamApps/common/assettocorsa/extension/internal.
---| `ac.FolderID.ScriptOrigin` @Main script directory.
---| `ac.FolderID.ScriptConfig` @…/Documents/Assetto Corsa/cfg/extension/state/lua/<mode>/<script ID>.
---| `ac.FolderID.CurrentTrack` @…/SteamApps/common/assettocorsa/content/tracks/<track ID>.
---| `ac.FolderID.CurrentTrackLayout` @…/SteamApps/common/assettocorsa/content/tracks/<track ID>/<layout ID> (or the same as CurrentTrack if no layout is selected).
---| `ac.FolderID.CurrentTrackLayoutUI` @…/SteamApps/common/assettocorsa/content/tracks/<track ID>/ui/<layout ID> (or just …/ui if no layout is selected).
ac.FolderID = {
  AppData = 0, ---@type ac.FolderID #…/AppData.
  Documents = 1, ---@type ac.FolderID #…/Documents.
  Root = 4, ---@type ac.FolderID #…/SteamApps/common/assettocorsa.
  Cfg = 5, ---@type ac.FolderID #…/Documents/Assetto Corsa/cfg.
  Logs = 7, ---@type ac.FolderID #…/Documents/Assetto Corsa/logs.
  Screenshots = 8, ---@type ac.FolderID #…/Documents/Assetto Corsa/screens.
  Replays = 9, ---@type ac.FolderID #…/Documents/Assetto Corsa/replay.
  ReplaysTemp = 10, ---@type ac.FolderID #…/Documents/Assetto Corsa/replay/temp.
  UserSetups = 11, ---@type ac.FolderID #…/Documents/Assetto Corsa/setups.
  PPFilters = 12, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/system/cfg/ppfilters.
  ContentCars = 13, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/content/cars.
  ContentDrivers = 14, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/content/drivers.
  ContentTracks = 15, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/content/tracks.
  ExtRoot = 16, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/extension.
  ExtCfgSys = 17, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/extension/config.
  ExtCfgUser = 18, ---@type ac.FolderID #…/Documents/Assetto Corsa/cfg/extension.
  ExtTextures = 21, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/extension/textures.
  ACApps = 23, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/apps.
  ACAppsLua = 1029, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/apps/lua.
  ACAppsPython = 24, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/apps/python.
  ExtCfgState = 25, ---@type ac.FolderID #…/Documents/Assetto Corsa/cfg/extension/state (changing configs there does not trigger any live reloads).
  ContentFonts = 26, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/content/fonts.
  RaceResults = 27, ---@type ac.FolderID #…/Documents/Assetto Corsa/out.
  AppDataLocal = 28, ---@type ac.FolderID #…/AppData/Local.
  ExtFonts = 29, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/extension/fonts.
  ACDocuments = 31, ---@type ac.FolderID #…/Documents/Assetto Corsa.
  ExtLua = 32, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/extension/lua.
  ExtCache = 33, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/cache.
  AppDataTemp = 34, ---@type ac.FolderID #…/AppData/Local/Temp.
  ExtInternal = 35, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/extension/internal.
  ScriptOrigin = 1024, ---@type ac.FolderID #Main script directory.
  ScriptConfig = 1025, ---@type ac.FolderID #…/Documents/Assetto Corsa/cfg/extension/state/lua/<mode>/<script ID>.
  CurrentTrack = 1026, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/content/tracks/<track ID>.
  CurrentTrackLayout = 1027, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/content/tracks/<track ID>/<layout ID> (or the same as CurrentTrack if no layout is selected).
  CurrentTrackLayoutUI = 1028, ---@type ac.FolderID #…/SteamApps/common/assettocorsa/content/tracks/<track ID>/ui/<layout ID> (or just …/ui if no layout is selected).
}

---@alias ac.HolidayType
---| `ac.HolidayType.None` @Value: 0.
---| `ac.HolidayType.Generic` @Value: 13.
---| `ac.HolidayType.NewYear` @Value: 1.
---| `ac.HolidayType.Christmas` @Value: 2.
---| `ac.HolidayType.VictoryDay` @Value: 3.
---| `ac.HolidayType.IndependenceDay` @Value: 4.
---| `ac.HolidayType.Halloween` @Value: 5.
---| `ac.HolidayType.JapanFestival` @Value: 6.
---| `ac.HolidayType.ChineseNewYear` @Value: 7.
---| `ac.HolidayType.EidAlAdha` @Value: 8.
---| `ac.HolidayType.GuyFawkesNight` @Value: 9.
---| `ac.HolidayType.StIstvanCelebration` @Value: 10.
---| `ac.HolidayType.CanadaDay` @Value: 11.
---| `ac.HolidayType.VictoriaDay` @Value: 12.
ac.HolidayType = {
  None = 0, ---@type ac.HolidayType #Value: 0.
  Generic = 13, ---@type ac.HolidayType #Value: 13.
  NewYear = 1, ---@type ac.HolidayType #Value: 1.
  Christmas = 2, ---@type ac.HolidayType #Value: 2.
  VictoryDay = 3, ---@type ac.HolidayType #Value: 3.
  IndependenceDay = 4, ---@type ac.HolidayType #Value: 4.
  Halloween = 5, ---@type ac.HolidayType #Value: 5.
  JapanFestival = 6, ---@type ac.HolidayType #Value: 6.
  ChineseNewYear = 7, ---@type ac.HolidayType #Value: 7.
  EidAlAdha = 8, ---@type ac.HolidayType #Value: 8.
  GuyFawkesNight = 9, ---@type ac.HolidayType #Value: 9.
  StIstvanCelebration = 10, ---@type ac.HolidayType #Value: 10.
  CanadaDay = 11, ---@type ac.HolidayType #Value: 11.
  VictoriaDay = 12, ---@type ac.HolidayType #Value: 12.
}

---@alias ac.SkyRegion
---| `ac.SkyRegion.None` @Value: 0.
---| `ac.SkyRegion.Sun` @Value: 1.
---| `ac.SkyRegion.Opposite` @Value: 2.
---| `ac.SkyRegion.All` @Value: 3.
ac.SkyRegion = {
  None = 0, ---@type ac.SkyRegion #Value: 0.
  Sun = 1, ---@type ac.SkyRegion #Value: 1.
  Opposite = 2, ---@type ac.SkyRegion #Value: 2.
  All = 3, ---@type ac.SkyRegion #Value: 3.
}

---@alias ac.SkyFeature
---| `ac.SkyFeature.Sun` @Value: 0.
---| `ac.SkyFeature.Moon` @Value: 1.
---| `ac.SkyFeature.Mercury` @Value: 101.
---| `ac.SkyFeature.Venus` @Value: 102.
---| `ac.SkyFeature.Mars` @Value: 103.
---| `ac.SkyFeature.Jupiter` @Value: 104.
---| `ac.SkyFeature.Saturn` @Value: 105.
---| `ac.SkyFeature.ISS` @Value: 200.
ac.SkyFeature = {
  Sun = 0, ---@type ac.SkyFeature #Value: 0.
  Moon = 1, ---@type ac.SkyFeature #Value: 1.
  Mercury = 101, ---@type ac.SkyFeature #Value: 101.
  Venus = 102, ---@type ac.SkyFeature #Value: 102.
  Mars = 103, ---@type ac.SkyFeature #Value: 103.
  Jupiter = 104, ---@type ac.SkyFeature #Value: 104.
  Saturn = 105, ---@type ac.SkyFeature #Value: 105.
  ISS = 200, ---@type ac.SkyFeature #Value: 200.
}

---@alias ac.UserInputMode
---| `ac.UserInputMode.Wheel` @Value: 0.
---| `ac.UserInputMode.Gamepad` @Value: 1.
---| `ac.UserInputMode.Keyboard` @Value: 2.
ac.UserInputMode = {
  Wheel = 0, ---@type ac.UserInputMode #Value: 0.
  Gamepad = 1, ---@type ac.UserInputMode #Value: 1.
  Keyboard = 2, ---@type ac.UserInputMode #Value: 2.
}

---@alias ac.AudioChannel
---| `ac.AudioChannel.Main` @Value: 'main'.
---| `ac.AudioChannel.Rain` @Value: 'rain'.
---| `ac.AudioChannel.Weather` @Value: 'weather'.
---| `ac.AudioChannel.Track` @Value: 'track'.
---| `ac.AudioChannel.Wipers` @Value: 'wipers'.
---| `ac.AudioChannel.CarComponents` @Value: 'carComponents'.
---| `ac.AudioChannel.Wind` @Value: 'wind'.
---| `ac.AudioChannel.Tyres` @Value: 'tyres'.
---| `ac.AudioChannel.Surfaces` @Value: 'surfaces'.
---| `ac.AudioChannel.Dirt` @Value: 'dirt'.
---| `ac.AudioChannel.Engine` @Value: 'engine'.
---| `ac.AudioChannel.Transmission` @Value: 'transmission'.
---| `ac.AudioChannel.Opponents` @Value: 'opponents'.
ac.AudioChannel = {
  Main = 'main', ---@type ac.AudioChannel #Value: 'main'.
  Rain = 'rain', ---@type ac.AudioChannel #Value: 'rain'.
  Weather = 'weather', ---@type ac.AudioChannel #Value: 'weather'.
  Track = 'track', ---@type ac.AudioChannel #Value: 'track'.
  Wipers = 'wipers', ---@type ac.AudioChannel #Value: 'wipers'.
  CarComponents = 'carComponents', ---@type ac.AudioChannel #Value: 'carComponents'.
  Wind = 'wind', ---@type ac.AudioChannel #Value: 'wind'.
  Tyres = 'tyres', ---@type ac.AudioChannel #Value: 'tyres'.
  Surfaces = 'surfaces', ---@type ac.AudioChannel #Value: 'surfaces'.
  Dirt = 'dirt', ---@type ac.AudioChannel #Value: 'dirt'.
  Engine = 'engine', ---@type ac.AudioChannel #Value: 'engine'.
  Transmission = 'transmission', ---@type ac.AudioChannel #Value: 'transmission'.
  Opponents = 'opponents', ---@type ac.AudioChannel #Value: 'opponents'.
}

---@alias ac.SpawnSet
---| `ac.SpawnSet.Start` @Value: 'START'.
---| `ac.SpawnSet.Pits` @Value: 'PIT'.
---| `ac.SpawnSet.HotlapStart` @Value: 'HOTLAP_START'.
---| `ac.SpawnSet.TimeAttack` @Careful: most tracks might not have that spawn set.
ac.SpawnSet = {
  Start = 'START', ---@type ac.SpawnSet #Value: 'START'.
  Pits = 'PIT', ---@type ac.SpawnSet #Value: 'PIT'.
  HotlapStart = 'HOTLAP_START', ---@type ac.SpawnSet #Value: 'HOTLAP_START'.
  TimeAttack = 'TIME_ATTACK', ---@type ac.SpawnSet #Careful: most tracks might not have that spawn set.
}

---At the moment, most of those flag types are never shown, but more flags will be added later. Also, physics-altering scripts---(like, for example, server scripts) can override flag type and use any flag from this list (and apply their own rules and---penalties when needed)
---@alias ac.FlagType
---| `ac.FlagType.None` @No flag, works.
---| `ac.FlagType.Start` @Works in race, practice or hotlap modes.
---| `ac.FlagType.Caution` @Yellow flag, works.
---| `ac.FlagType.Slippery` @Does not work yet.
---| `ac.FlagType.PitLaneClosed` @Does not work yet.
---| `ac.FlagType.Stop` @Black flag, works.
---| `ac.FlagType.SlowVehicle` @Does not work yet.
---| `ac.FlagType.Ambulance` @Does not work yet.
---| `ac.FlagType.ReturnToPits` @Penalty flag, works.
---| `ac.FlagType.MechanicalFailure` @Does not work yet.
---| `ac.FlagType.Unsportsmanlike` @Does not work yet.
---| `ac.FlagType.StopCancel` @Does not work yet.
---| `ac.FlagType.FasterCar` @Blue flag, works.
---| `ac.FlagType.Finished` @Checkered flag, works.
---| `ac.FlagType.OneLapLeft` @White flag, works.
---| `ac.FlagType.SessionSuspended` @Does not work yet.
---| `ac.FlagType.Code60` @Does not work yet.
ac.FlagType = {
  None = 0, ---@type ac.FlagType #No flag, works.
  Start = 1, ---@type ac.FlagType #Works in race, practice or hotlap modes.
  Caution = 2, ---@type ac.FlagType #Yellow flag, works.
  Slippery = 3, ---@type ac.FlagType #Does not work yet.
  PitLaneClosed = 4, ---@type ac.FlagType #Does not work yet.
  Stop = 5, ---@type ac.FlagType #Black flag, works.
  SlowVehicle = 6, ---@type ac.FlagType #Does not work yet.
  Ambulance = 7, ---@type ac.FlagType #Does not work yet.
  ReturnToPits = 8, ---@type ac.FlagType #Penalty flag, works.
  MechanicalFailure = 9, ---@type ac.FlagType #Does not work yet.
  Unsportsmanlike = 10, ---@type ac.FlagType #Does not work yet.
  StopCancel = 11, ---@type ac.FlagType #Does not work yet.
  FasterCar = 12, ---@type ac.FlagType #Blue flag, works.
  Finished = 13, ---@type ac.FlagType #Checkered flag, works.
  OneLapLeft = 14, ---@type ac.FlagType #White flag, works.
  SessionSuspended = 15, ---@type ac.FlagType #Does not work yet.
  Code60 = 16, ---@type ac.FlagType #Does not work yet.
}

---@alias ac.InputMethod
---| `ac.InputMethod.Unknown` @Value: 0.
---| `ac.InputMethod.Wheel` @Value: 1.
---| `ac.InputMethod.Gamepad` @Value: 2.
---| `ac.InputMethod.Keyboard` @Value: 3.
---| `ac.InputMethod.AI` @Value: 4.
ac.InputMethod = {
  Unknown = 0, ---@type ac.InputMethod #Value: 0.
  Wheel = 1, ---@type ac.InputMethod #Value: 1.
  Gamepad = 2, ---@type ac.InputMethod #Value: 2.
  Keyboard = 3, ---@type ac.InputMethod #Value: 3.
  AI = 4, ---@type ac.InputMethod #Value: 4.
}

---@alias ac.PenaltyType
---| `ac.PenaltyType.None` @No penalty.
---| `ac.PenaltyType.MandatoryPits` @Parameter: how many laps are left to do mandatory pits.
---| `ac.PenaltyType.TeleportToPits` @Parameter: how many seconds to wait in pits with locked controls.
---| `ac.PenaltyType.SlowDown` @Requires to cut gas for number of seconds in parameter (warning: works only with some race configurations, for example, “Disable gas cut penalty” should not be active in server rules settings).
---| `ac.PenaltyType.BlackFlag` @Adds black flag, no parameter.
---| `ac.PenaltyType.ReleaseBlackFlag` @Removes previously set black flag, no parameter.
ac.PenaltyType = {
  None = 0, ---@type ac.PenaltyType #No penalty.
  MandatoryPits = 1, ---@type ac.PenaltyType #Parameter: how many laps are left to do mandatory pits.
  TeleportToPits = 2, ---@type ac.PenaltyType #Parameter: how many seconds to wait in pits with locked controls.
  SlowDown = 3, ---@type ac.PenaltyType #Requires to cut gas for number of seconds in parameter (warning: works only with some race configurations, for example, “Disable gas cut penalty” should not be active in server rules settings).
  BlackFlag = 4, ---@type ac.PenaltyType #Adds black flag, no parameter.
  ReleaseBlackFlag = 5, ---@type ac.PenaltyType #Removes previously set black flag, no parameter.
}

---@alias ac.ImageFormat
---| `ac.ImageFormat.BMP` @Value: 0.
---| `ac.ImageFormat.JPG` @Value: 1.
---| `ac.ImageFormat.PNG` @Value: 2.
---| `ac.ImageFormat.DDS` @Value: 5.
---| `ac.ImageFormat.ZippedDDS` @DDS in a ZIP file, if used for saving canvas, actual saving happens in a different thread (so, it’s both fast and compact).
ac.ImageFormat = {
  BMP = 0, ---@type ac.ImageFormat #Value: 0.
  JPG = 1, ---@type ac.ImageFormat #Value: 1.
  PNG = 2, ---@type ac.ImageFormat #Value: 2.
  DDS = 5, ---@type ac.ImageFormat #Value: 5.
  ZippedDDS = 6, ---@type ac.ImageFormat #DDS in a ZIP file, if used for saving canvas, actual saving happens in a different thread (so, it’s both fast and compact).
}

---Key indices, pretty much mirrors all those “VK_…” key tables.
---@alias ac.KeyIndex
---| `ac.KeyIndex.LeftButton` @Value: 1.
---| `ac.KeyIndex.RightButton` @Value: 2.
---| `ac.KeyIndex.MiddleButton` @Not contiguous with LeftButton and RightButton.
---| `ac.KeyIndex.XButton1` @Not contiguous with LeftButton and RightButton.
---| `ac.KeyIndex.XButton2` @Not contiguous with LeftButton and RightButton.
---| `ac.KeyIndex.Tab` @Value: 9.
---| `ac.KeyIndex.Return` @Value: 13.
---| `ac.KeyIndex.Shift` @Value: 16.
---| `ac.KeyIndex.Control` @Value: 17.
---| `ac.KeyIndex.Menu` @Aka Alt button.
---| `ac.KeyIndex.Escape` @Value: 27.
---| `ac.KeyIndex.Accept` @Value: 30.
---| `ac.KeyIndex.Space` @Value: 32.
---| `ac.KeyIndex.End` @Value: 35.
---| `ac.KeyIndex.Home` @Value: 36.
---| `ac.KeyIndex.Left` @Arrow ←.
---| `ac.KeyIndex.Up` @Arrow ↑.
---| `ac.KeyIndex.Right` @Arrow →.
---| `ac.KeyIndex.Down` @Arrow ↓.
---| `ac.KeyIndex.Insert` @Value: 45.
---| `ac.KeyIndex.Delete` @Value: 46.
---| `ac.KeyIndex.LeftWin` @Value: 91.
---| `ac.KeyIndex.RightWin` @Value: 92.
---| `ac.KeyIndex.NumPad0` @Value: 96.
---| `ac.KeyIndex.NumPad1` @Value: 97.
---| `ac.KeyIndex.NumPad2` @Value: 98.
---| `ac.KeyIndex.NumPad3` @Value: 99.
---| `ac.KeyIndex.NumPad4` @Value: 100.
---| `ac.KeyIndex.NumPad5` @Value: 101.
---| `ac.KeyIndex.NumPad6` @Value: 102.
---| `ac.KeyIndex.NumPad7` @Value: 103.
---| `ac.KeyIndex.NumPad8` @Value: 104.
---| `ac.KeyIndex.NumPad9` @Value: 105.
---| `ac.KeyIndex.Multiply` @Value: 106.
---| `ac.KeyIndex.Add` @Value: 107.
---| `ac.KeyIndex.Separator` @Value: 108.
---| `ac.KeyIndex.Subtract` @Value: 109.
---| `ac.KeyIndex.Decimal` @Value: 110.
---| `ac.KeyIndex.Divide` @Value: 111.
---| `ac.KeyIndex.F1` @Value: 112.
---| `ac.KeyIndex.F2` @Value: 113.
---| `ac.KeyIndex.F3` @Value: 114.
---| `ac.KeyIndex.F4` @Value: 115.
---| `ac.KeyIndex.F5` @Value: 116.
---| `ac.KeyIndex.F6` @Value: 117.
---| `ac.KeyIndex.F7` @Value: 118.
---| `ac.KeyIndex.F8` @Value: 119.
---| `ac.KeyIndex.F9` @Value: 120.
---| `ac.KeyIndex.F10` @Value: 121.
---| `ac.KeyIndex.F11` @Value: 122.
---| `ac.KeyIndex.F12` @Value: 123.
---| `ac.KeyIndex.NumLock` @Value: 144.
---| `ac.KeyIndex.Scroll` @Value: 145.
---| `ac.KeyIndex.OemNecEqual` @“.
---| `ac.KeyIndex.LeftShift` @Value: 160.
---| `ac.KeyIndex.RightShift` @Value: 161.
---| `ac.KeyIndex.LeftControl` @Value: 162.
---| `ac.KeyIndex.RightControl` @Value: 163.
---| `ac.KeyIndex.LeftMenu` @Aka left Alt button.
---| `ac.KeyIndex.RightMenu` @Aka right Alt button.
---| `ac.KeyIndex.Oem1` @“;:” for US.
---| `ac.KeyIndex.SquareOpenBracket` @Value: 219.
---| `ac.KeyIndex.SquareCloseBracket` @Value: 221.
---| `ac.KeyIndex.D0` @Digit 0.
---| `ac.KeyIndex.D1` @Digit 1.
---| `ac.KeyIndex.D2` @Digit 2.
---| `ac.KeyIndex.D3` @Digit 3.
---| `ac.KeyIndex.D4` @Digit 4.
---| `ac.KeyIndex.D5` @Digit 5.
---| `ac.KeyIndex.D6` @Digit 6.
---| `ac.KeyIndex.D7` @Digit 7.
---| `ac.KeyIndex.D8` @Digit 8.
---| `ac.KeyIndex.D9` @Digit 9.
---| `ac.KeyIndex.A` @Letter A.
---| `ac.KeyIndex.B` @Letter B.
---| `ac.KeyIndex.C` @Letter C.
---| `ac.KeyIndex.D` @Letter D.
---| `ac.KeyIndex.E` @Letter E.
---| `ac.KeyIndex.F` @Letter F.
---| `ac.KeyIndex.G` @Letter G.
---| `ac.KeyIndex.H` @Letter H.
---| `ac.KeyIndex.I` @Letter I.
---| `ac.KeyIndex.J` @Letter J.
---| `ac.KeyIndex.K` @Letter K.
---| `ac.KeyIndex.L` @Letter L.
---| `ac.KeyIndex.M` @Letter M.
---| `ac.KeyIndex.N` @Letter N.
---| `ac.KeyIndex.O` @Letter O.
---| `ac.KeyIndex.P` @Letter P.
---| `ac.KeyIndex.Q` @Letter Q.
---| `ac.KeyIndex.R` @Letter R.
---| `ac.KeyIndex.S` @Letter S.
---| `ac.KeyIndex.T` @Letter T.
---| `ac.KeyIndex.U` @Letter U.
---| `ac.KeyIndex.V` @Letter V.
---| `ac.KeyIndex.W` @Letter W.
---| `ac.KeyIndex.X` @Letter X.
---| `ac.KeyIndex.Y` @Letter Y.
---| `ac.KeyIndex.Z` @Letter Z.
ac.KeyIndex = {
  LeftButton = 1, ---@type ac.KeyIndex #Value: 1.
  RightButton = 2, ---@type ac.KeyIndex #Value: 2.
  Cancel = 3, ---@type ac.KeyIndex #Value: 3.
  MiddleButton = 4, ---@type ac.KeyIndex #Not contiguous with LeftButton and RightButton.
  XButton1 = 5, ---@type ac.KeyIndex #Not contiguous with LeftButton and RightButton.
  XButton2 = 6, ---@type ac.KeyIndex #Not contiguous with LeftButton and RightButton.
  Back = 8, ---@type ac.KeyIndex #Value: 8.
  Tab = 9, ---@type ac.KeyIndex #Value: 9.
  Clear = 12, ---@type ac.KeyIndex #Value: 12.
  Return = 13, ---@type ac.KeyIndex #Value: 13.
  Shift = 16, ---@type ac.KeyIndex #Value: 16.
  Control = 17, ---@type ac.KeyIndex #Value: 17.
  Menu = 18, ---@type ac.KeyIndex #Aka Alt button.
  Pause = 19, ---@type ac.KeyIndex #Value: 19.
  Capital = 20, ---@type ac.KeyIndex #Value: 20.
  Kana = 21, ---@type ac.KeyIndex #Value: 21.
  Hangeul = 21, ---@type ac.KeyIndex #Old name - should be here for compatibility.
  Hangul = 21, ---@type ac.KeyIndex #Value: 21.
  Junja = 23, ---@type ac.KeyIndex #Value: 23.
  Final = 24, ---@type ac.KeyIndex #Value: 24.
  Hanja = 25, ---@type ac.KeyIndex #Value: 25.
  Kanji = 25, ---@type ac.KeyIndex #Value: 25.
  Escape = 27, ---@type ac.KeyIndex #Value: 27.
  Convert = 28, ---@type ac.KeyIndex #Value: 28.
  NonConvert = 29, ---@type ac.KeyIndex #Value: 29.
  Accept = 30, ---@type ac.KeyIndex #Value: 30.
  ModeChange = 31, ---@type ac.KeyIndex #Value: 31.
  Space = 32, ---@type ac.KeyIndex #Value: 32.
  PageUp = 33, ---@type ac.KeyIndex #Value: 33.
  PageDown = 34, ---@type ac.KeyIndex #Value: 34.
  End = 35, ---@type ac.KeyIndex #Value: 35.
  Home = 36, ---@type ac.KeyIndex #Value: 36.
  Left = 37, ---@type ac.KeyIndex #Arrow ←.
  Up = 38, ---@type ac.KeyIndex #Arrow ↑.
  Right = 39, ---@type ac.KeyIndex #Arrow →.
  Down = 40, ---@type ac.KeyIndex #Arrow ↓.
  Select = 41, ---@type ac.KeyIndex #Value: 41.
  Print = 42, ---@type ac.KeyIndex #Value: 42.
  Execute = 43, ---@type ac.KeyIndex #Value: 43.
  Snapshot = 44, ---@type ac.KeyIndex #Value: 44.
  Insert = 45, ---@type ac.KeyIndex #Value: 45.
  Delete = 46, ---@type ac.KeyIndex #Value: 46.
  Help = 47, ---@type ac.KeyIndex #Value: 47.
  LeftWin = 91, ---@type ac.KeyIndex #Value: 91.
  RightWin = 92, ---@type ac.KeyIndex #Value: 92.
  Apps = 93, ---@type ac.KeyIndex #Value: 93.
  Sleep = 95, ---@type ac.KeyIndex #Value: 95.
  NumPad0 = 96, ---@type ac.KeyIndex #Value: 96.
  NumPad1 = 97, ---@type ac.KeyIndex #Value: 97.
  NumPad2 = 98, ---@type ac.KeyIndex #Value: 98.
  NumPad3 = 99, ---@type ac.KeyIndex #Value: 99.
  NumPad4 = 100, ---@type ac.KeyIndex #Value: 100.
  NumPad5 = 101, ---@type ac.KeyIndex #Value: 101.
  NumPad6 = 102, ---@type ac.KeyIndex #Value: 102.
  NumPad7 = 103, ---@type ac.KeyIndex #Value: 103.
  NumPad8 = 104, ---@type ac.KeyIndex #Value: 104.
  NumPad9 = 105, ---@type ac.KeyIndex #Value: 105.
  Multiply = 106, ---@type ac.KeyIndex #Value: 106.
  Add = 107, ---@type ac.KeyIndex #Value: 107.
  Separator = 108, ---@type ac.KeyIndex #Value: 108.
  Subtract = 109, ---@type ac.KeyIndex #Value: 109.
  Decimal = 110, ---@type ac.KeyIndex #Value: 110.
  Divide = 111, ---@type ac.KeyIndex #Value: 111.
  F1 = 112, ---@type ac.KeyIndex #Value: 112.
  F2 = 113, ---@type ac.KeyIndex #Value: 113.
  F3 = 114, ---@type ac.KeyIndex #Value: 114.
  F4 = 115, ---@type ac.KeyIndex #Value: 115.
  F5 = 116, ---@type ac.KeyIndex #Value: 116.
  F6 = 117, ---@type ac.KeyIndex #Value: 117.
  F7 = 118, ---@type ac.KeyIndex #Value: 118.
  F8 = 119, ---@type ac.KeyIndex #Value: 119.
  F9 = 120, ---@type ac.KeyIndex #Value: 120.
  F10 = 121, ---@type ac.KeyIndex #Value: 121.
  F11 = 122, ---@type ac.KeyIndex #Value: 122.
  F12 = 123, ---@type ac.KeyIndex #Value: 123.
  F13 = 124, ---@type ac.KeyIndex #Value: 124.
  F14 = 125, ---@type ac.KeyIndex #Value: 125.
  F15 = 126, ---@type ac.KeyIndex #Value: 126.
  F16 = 127, ---@type ac.KeyIndex #Value: 127.
  F17 = 128, ---@type ac.KeyIndex #Value: 128.
  F18 = 129, ---@type ac.KeyIndex #Value: 129.
  F19 = 130, ---@type ac.KeyIndex #Value: 130.
  F20 = 131, ---@type ac.KeyIndex #Value: 131.
  F21 = 132, ---@type ac.KeyIndex #Value: 132.
  F22 = 133, ---@type ac.KeyIndex #Value: 133.
  F23 = 134, ---@type ac.KeyIndex #Value: 134.
  F24 = 135, ---@type ac.KeyIndex #Value: 135.
  NavigationView = 136, ---@type ac.KeyIndex #Reserved.
  NavigationMenu = 137, ---@type ac.KeyIndex #Reserved.
  NavigationUp = 138, ---@type ac.KeyIndex #Reserved.
  NavigationDown = 139, ---@type ac.KeyIndex #Reserved.
  NavigationLeft = 140, ---@type ac.KeyIndex #Reserved.
  NavigationRight = 141, ---@type ac.KeyIndex #Reserved.
  NavigationAccept = 142, ---@type ac.KeyIndex #Reserved.
  NavigationCancel = 143, ---@type ac.KeyIndex #Reserved.
  NumLock = 144, ---@type ac.KeyIndex #Value: 144.
  Scroll = 145, ---@type ac.KeyIndex #Value: 145.
  OemNecEqual = 146, ---@type ac.KeyIndex #“.
  OemFjJisho = 146, ---@type ac.KeyIndex #“Dictionary” key.
  OemFjMasshou = 147, ---@type ac.KeyIndex #“Unregister word” key.
  OemFjTouroku = 148, ---@type ac.KeyIndex #“Register word” key.
  OemFjLoya = 149, ---@type ac.KeyIndex #“Left OYAYUBI” key.
  OemFjRoya = 150, ---@type ac.KeyIndex #“Right OYAYUBI” key.
  LeftShift = 160, ---@type ac.KeyIndex #Value: 160.
  RightShift = 161, ---@type ac.KeyIndex #Value: 161.
  LeftControl = 162, ---@type ac.KeyIndex #Value: 162.
  RightControl = 163, ---@type ac.KeyIndex #Value: 163.
  LeftMenu = 164, ---@type ac.KeyIndex #Aka left Alt button.
  RightMenu = 165, ---@type ac.KeyIndex #Aka right Alt button.
  BrowserBack = 166, ---@type ac.KeyIndex #Value: 166.
  BrowserForward = 167, ---@type ac.KeyIndex #Value: 167.
  BrowserRefresh = 168, ---@type ac.KeyIndex #Value: 168.
  BrowserStop = 169, ---@type ac.KeyIndex #Value: 169.
  BrowserSearch = 170, ---@type ac.KeyIndex #Value: 170.
  BrowserFavorites = 171, ---@type ac.KeyIndex #Value: 171.
  BrowserHome = 172, ---@type ac.KeyIndex #Value: 172.
  VolumeMute = 173, ---@type ac.KeyIndex #Value: 173.
  VolumeDown = 174, ---@type ac.KeyIndex #Value: 174.
  VolumeUp = 175, ---@type ac.KeyIndex #Value: 175.
  MediaNextTrack = 176, ---@type ac.KeyIndex #Value: 176.
  MediaPrevTrack = 177, ---@type ac.KeyIndex #Value: 177.
  MediaStop = 178, ---@type ac.KeyIndex #Value: 178.
  MediaPlayPause = 179, ---@type ac.KeyIndex #Value: 179.
  LaunchMail = 180, ---@type ac.KeyIndex #Value: 180.
  LaunchMediaSelect = 181, ---@type ac.KeyIndex #Value: 181.
  LaunchApp1 = 182, ---@type ac.KeyIndex #Value: 182.
  LaunchApp2 = 183, ---@type ac.KeyIndex #Value: 183.
  Oem1 = 186, ---@type ac.KeyIndex #“;:” for US.
  OemPlus = 187, ---@type ac.KeyIndex #“+” any country.
  OemComma = 188, ---@type ac.KeyIndex #“,” any country.
  OemMinus = 189, ---@type ac.KeyIndex #“-” any country.
  OemPeriod = 190, ---@type ac.KeyIndex #“.” any country.
  Oem2 = 191, ---@type ac.KeyIndex #“/?” for US.
  Oem3 = 192, ---@type ac.KeyIndex #“`~” for US.
  GamepadA = 195, ---@type ac.KeyIndex #Reserved.
  GamepadB = 196, ---@type ac.KeyIndex #Reserved.
  GamepadX = 197, ---@type ac.KeyIndex #Reserved.
  GamepadY = 198, ---@type ac.KeyIndex #Reserved.
  GamepadRightShoulder = 199, ---@type ac.KeyIndex #Reserved.
  GamepadLeftShoulder = 200, ---@type ac.KeyIndex #Reserved.
  GamepadLeftTrigger = 201, ---@type ac.KeyIndex #Reserved.
  GamepadRightTrigger = 202, ---@type ac.KeyIndex #Reserved.
  GamepadDpadUp = 203, ---@type ac.KeyIndex #Reserved.
  GamepadDpadDown = 204, ---@type ac.KeyIndex #Reserved.
  GamepadDpadLeft = 205, ---@type ac.KeyIndex #Reserved.
  GamepadDpadRight = 206, ---@type ac.KeyIndex #Reserved.
  GamepadMenu = 207, ---@type ac.KeyIndex #Reserved.
  GamepadView = 208, ---@type ac.KeyIndex #Reserved.
  GamepadLeftThumbstickButton = 209, ---@type ac.KeyIndex #Reserved.
  GamepadRightThumbstickButton = 210, ---@type ac.KeyIndex #Reserved.
  GamepadLeftThumbstickUp = 211, ---@type ac.KeyIndex #Reserved.
  GamepadLeftThumbstickDown = 212, ---@type ac.KeyIndex #Reserved.
  GamepadLeftThumbstickRight = 213, ---@type ac.KeyIndex #Reserved.
  GamepadLeftThumbstickLeft = 214, ---@type ac.KeyIndex #Reserved.
  GamepadRightThumbstickUp = 215, ---@type ac.KeyIndex #Reserved.
  GamepadRightThumbstickDown = 216, ---@type ac.KeyIndex #Reserved.
  GamepadRightThumbstickRight = 217, ---@type ac.KeyIndex #Reserved.
  GamepadRightThumbstickLeft = 218, ---@type ac.KeyIndex #Reserved.
  SquareOpenBracket = 219, ---@type ac.KeyIndex #Value: 219.
  SquareCloseBracket = 221, ---@type ac.KeyIndex #Value: 221.
  D0 = 48, ---@type ac.KeyIndex #Digit 0.
  D1 = 49, ---@type ac.KeyIndex #Digit 1.
  D2 = 50, ---@type ac.KeyIndex #Digit 2.
  D3 = 51, ---@type ac.KeyIndex #Digit 3.
  D4 = 52, ---@type ac.KeyIndex #Digit 4.
  D5 = 53, ---@type ac.KeyIndex #Digit 5.
  D6 = 54, ---@type ac.KeyIndex #Digit 6.
  D7 = 55, ---@type ac.KeyIndex #Digit 7.
  D8 = 56, ---@type ac.KeyIndex #Digit 8.
  D9 = 57, ---@type ac.KeyIndex #Digit 9.
  A = 65, ---@type ac.KeyIndex #Letter A.
  B = 66, ---@type ac.KeyIndex #Letter B.
  C = 67, ---@type ac.KeyIndex #Letter C.
  D = 68, ---@type ac.KeyIndex #Letter D.
  E = 69, ---@type ac.KeyIndex #Letter E.
  F = 70, ---@type ac.KeyIndex #Letter F.
  G = 71, ---@type ac.KeyIndex #Letter G.
  H = 72, ---@type ac.KeyIndex #Letter H.
  I = 73, ---@type ac.KeyIndex #Letter I.
  J = 74, ---@type ac.KeyIndex #Letter J.
  K = 75, ---@type ac.KeyIndex #Letter K.
  L = 76, ---@type ac.KeyIndex #Letter L.
  M = 77, ---@type ac.KeyIndex #Letter M.
  N = 78, ---@type ac.KeyIndex #Letter N.
  O = 79, ---@type ac.KeyIndex #Letter O.
  P = 80, ---@type ac.KeyIndex #Letter P.
  Q = 81, ---@type ac.KeyIndex #Letter Q.
  R = 82, ---@type ac.KeyIndex #Letter R.
  S = 83, ---@type ac.KeyIndex #Letter S.
  T = 84, ---@type ac.KeyIndex #Letter T.
  U = 85, ---@type ac.KeyIndex #Letter U.
  V = 86, ---@type ac.KeyIndex #Letter V.
  W = 87, ---@type ac.KeyIndex #Letter W.
  X = 88, ---@type ac.KeyIndex #Letter X.
  Y = 89, ---@type ac.KeyIndex #Letter Y.
  Z = 90, ---@type ac.KeyIndex #Letter Z.
}

---More types might be added later, or at least a `CustomMode` type.
---@alias ac.SessionType
---| `ac.SessionType.Undefined` @Value: 0.
---| `ac.SessionType.Practice` @Value: 1.
---| `ac.SessionType.Qualify` @Value: 2.
---| `ac.SessionType.Race` @Value: 3.
---| `ac.SessionType.Hotlap` @Value: 4.
---| `ac.SessionType.TimeAttack` @Value: 5.
---| `ac.SessionType.Drift` @Value: 6.
---| `ac.SessionType.Drag` @Value: 7.
ac.SessionType = {
  Undefined = 0, ---@type ac.SessionType #Value: 0.
  Practice = 1, ---@type ac.SessionType #Value: 1.
  Qualify = 2, ---@type ac.SessionType #Value: 2.
  Race = 3, ---@type ac.SessionType #Value: 3.
  Hotlap = 4, ---@type ac.SessionType #Value: 4.
  TimeAttack = 5, ---@type ac.SessionType #Value: 5.
  Drift = 6, ---@type ac.SessionType #Value: 6.
  Drag = 7, ---@type ac.SessionType #Value: 7.
}

---@alias ac.SharedNamespace
---| `ac.SharedNamespace.Global` @Value: ''.
---| `ac.SharedNamespace.CarDisplay` @Value: 'car_scriptable_display'.
---| `ac.SharedNamespace.CarScript` @Value: 'car_script'.
---| `ac.SharedNamespace.TrackDisplay` @Value: 'track_scriptable_display'.
---| `ac.SharedNamespace.TrackScript` @Value: 'track_script'.
---| `ac.SharedNamespace.ServerScript` @Value: 'server_script'.
---| `ac.SharedNamespace.Shared` @Value: 'shared'.
ac.SharedNamespace = {
  Global = '', ---@type ac.SharedNamespace #Value: ''.
  CarDisplay = 'car_scriptable_display', ---@type ac.SharedNamespace #Value: 'car_scriptable_display'.
  CarScript = 'car_script', ---@type ac.SharedNamespace #Value: 'car_script'.
  TrackDisplay = 'track_scriptable_display', ---@type ac.SharedNamespace #Value: 'track_scriptable_display'.
  TrackScript = 'track_script', ---@type ac.SharedNamespace #Value: 'track_script'.
  ServerScript = 'server_script', ---@type ac.SharedNamespace #Value: 'server_script'.
  Shared = 'shared', ---@type ac.SharedNamespace #Value: 'shared'.
}

---@alias ac.CompressionType
---| `ac.CompressionType.LZ4` @Fastest compression, great for use in real-time applications. Does not take `level` into account.
---| `ac.CompressionType.Deflate` @Deflate compression.
---| `ac.CompressionType.Zlib` @Zlib compression (deflate with zlib wrapper).
---| `ac.CompressionType.Gzip` @Gzip compression (deflate with gzip wrapper).
ac.CompressionType = {
  LZ4 = 0, ---@type ac.CompressionType #Fastest compression, great for use in real-time applications. Does not take `level` into account.
  Deflate = 1, ---@type ac.CompressionType #Deflate compression.
  Zlib = 2, ---@type ac.CompressionType #Zlib compression (deflate with zlib wrapper).
  Gzip = 3, ---@type ac.CompressionType #Gzip compression (deflate with gzip wrapper).
}

---@alias ac.NationCode
---| `ac.NationCode.Aruba` @Aruba.
---| `ac.NationCode.Afghanistan` @Afghanistan.
---| `ac.NationCode.Angola` @Angola.
---| `ac.NationCode.Anguilla` @Anguilla.
---| `ac.NationCode.Albania` @Albania.
---| `ac.NationCode.Andorra` @Andorra.
---| `ac.NationCode.United` @United.
---| `ac.NationCode.Argentina` @Argentina.
---| `ac.NationCode.Armenia` @Armenia.
---| `ac.NationCode.American` @American.
---| `ac.NationCode.Antarctica` @Antarctica.
---| `ac.NationCode.Antigua` @Antigua.
---| `ac.NationCode.Australia` @Australia.
---| `ac.NationCode.Austria` @Austria.
---| `ac.NationCode.Azerbaijan` @Azerbaijan.
---| `ac.NationCode.Burundi` @Burundi.
---| `ac.NationCode.Belgium` @Belgium.
---| `ac.NationCode.Benin` @Benin.
---| `ac.NationCode.Burkina` @Burkina.
---| `ac.NationCode.Bangladesh` @Bangladesh.
---| `ac.NationCode.Bulgaria` @Bulgaria.
---| `ac.NationCode.Bahrain` @Bahrain.
---| `ac.NationCode.Bahamas` @Bahamas.
---| `ac.NationCode.Bosnia` @Bosnia.
---| `ac.NationCode.Belarus` @Belarus.
---| `ac.NationCode.Belize` @Belize.
---| `ac.NationCode.Bermuda` @Bermuda.
---| `ac.NationCode.Bolivia` @Bolivia.
---| `ac.NationCode.Brazil` @Brazil.
---| `ac.NationCode.Barbados` @Barbados.
---| `ac.NationCode.Brunei` @Brunei.
---| `ac.NationCode.Bhutan` @Bhutan.
---| `ac.NationCode.Botswana` @Botswana.
---| `ac.NationCode.Central` @Central.
---| `ac.NationCode.Canada` @Canada.
---| `ac.NationCode.Cocos` @Cocos.
---| `ac.NationCode.Switzerland` @Switzerland.
---| `ac.NationCode.Chile` @Chile.
---| `ac.NationCode.China` @China.
---| `ac.NationCode.Cote` @Côte.
---| `ac.NationCode.Cameroon` @Cameroon.
---| `ac.NationCode.Congo` @Congo.
---| `ac.NationCode.Cook` @Cook.
---| `ac.NationCode.Colombia` @Colombia.
---| `ac.NationCode.Comoros` @Comoros.
---| `ac.NationCode.Cape` @Cape.
---| `ac.NationCode.Costa` @Costa.
---| `ac.NationCode.Cuba` @Cuba.
---| `ac.NationCode.Cayman` @Cayman.
---| `ac.NationCode.Cyprus` @Cyprus.
---| `ac.NationCode.Czech` @Czech.
---| `ac.NationCode.Germany` @Germany.
---| `ac.NationCode.Djibouti` @Djibouti.
---| `ac.NationCode.Dominica` @Dominica.
---| `ac.NationCode.Denmark` @Denmark.
---| `ac.NationCode.Dominican` @Dominican.
---| `ac.NationCode.Algeria` @Algeria.
---| `ac.NationCode.Ecuador` @Ecuador.
---| `ac.NationCode.Egypt` @Egypt.
---| `ac.NationCode.England` @England.
---| `ac.NationCode.Eritrea` @Eritrea.
---| `ac.NationCode.Western` @Western.
---| `ac.NationCode.Spain` @Spain.
---| `ac.NationCode.Estonia` @Estonia.
---| `ac.NationCode.Ethiopia` @Ethiopia.
---| `ac.NationCode.Finland` @Finland.
---| `ac.NationCode.Fiji` @Fiji.
---| `ac.NationCode.France` @France.
---| `ac.NationCode.Faroe` @Faroe.
---| `ac.NationCode.Micronesia` @Micronesia.
---| `ac.NationCode.Gabon` @Gabon.
---| `ac.NationCode.Great` @Great.
---| `ac.NationCode.Georgia` @Georgia.
---| `ac.NationCode.Guernsey` @Guernsey.
---| `ac.NationCode.Ghana` @Ghana.
---| `ac.NationCode.Gibraltar` @Gibraltar.
---| `ac.NationCode.Guinea` @Guinea.
---| `ac.NationCode.Gambia` @Gambia.
---| `ac.NationCode.Equatorial` @Equatorial.
---| `ac.NationCode.Greece` @Greece.
---| `ac.NationCode.Grenada` @Grenada.
---| `ac.NationCode.Greenland` @Greenland.
---| `ac.NationCode.Guatemala` @Guatemala.
---| `ac.NationCode.Guam` @Guam.
---| `ac.NationCode.Guyana` @Guyana.
---| `ac.NationCode.Hong` @Hong.
---| `ac.NationCode.Honduras` @Honduras.
---| `ac.NationCode.Croatia` @Croatia.
---| `ac.NationCode.Haiti` @Haiti.
---| `ac.NationCode.Hungary` @Hungary.
---| `ac.NationCode.Indonesia` @Indonesia.
---| `ac.NationCode.Isle` @Isle.
---| `ac.NationCode.India` @India.
---| `ac.NationCode.Ireland` @Ireland.
---| `ac.NationCode.Iran` @Iran.
---| `ac.NationCode.Iraq` @Iraq.
---| `ac.NationCode.Iceland` @Iceland.
---| `ac.NationCode.Israel` @Israel.
---| `ac.NationCode.Italy` @Italy.
---| `ac.NationCode.Jamaica` @Jamaica.
---| `ac.NationCode.Jersey` @Jersey.
---| `ac.NationCode.Jordan` @Jordan.
---| `ac.NationCode.Japan` @Japan.
---| `ac.NationCode.Kazakhstan` @Kazakhstan.
---| `ac.NationCode.Kenya` @Kenya.
---| `ac.NationCode.Kyrgyzstan` @Kyrgyzstan.
---| `ac.NationCode.Cambodia` @Cambodia.
---| `ac.NationCode.Kiribati` @Kiribati.
---| `ac.NationCode.Saint` @Saint.
---| `ac.NationCode.South` @South.
---| `ac.NationCode.Kuwait` @Kuwait.
---| `ac.NationCode.Laos` @Laos.
---| `ac.NationCode.Lebanon` @Lebanon.
---| `ac.NationCode.Liberia` @Liberia.
---| `ac.NationCode.Liechtenstein` @Liechtenstein.
---| `ac.NationCode.Sri` @Sri.
---| `ac.NationCode.Lesotho` @Lesotho.
---| `ac.NationCode.Lithuania` @Lithuania.
---| `ac.NationCode.Luxembourg` @Luxembourg.
---| `ac.NationCode.Latvia` @Latvia.
---| `ac.NationCode.Macau` @Macau.
---| `ac.NationCode.Morocco` @Morocco.
---| `ac.NationCode.Monaco` @Monaco.
---| `ac.NationCode.Moldova` @Moldova.
---| `ac.NationCode.Madagascar` @Madagascar.
---| `ac.NationCode.Maldives` @Maldives.
---| `ac.NationCode.Mexico` @Mexico.
---| `ac.NationCode.Marshall` @Marshall.
---| `ac.NationCode.Macedonia` @Macedonia.
---| `ac.NationCode.Mali` @Mali.
---| `ac.NationCode.Malta` @Malta.
---| `ac.NationCode.Myanmar` @Myanmar.
---| `ac.NationCode.Montenegro` @Montenegro.
---| `ac.NationCode.Mongolia` @Mongolia.
---| `ac.NationCode.Mozambique` @Mozambique.
---| `ac.NationCode.Mauritania` @Mauritania.
---| `ac.NationCode.Montserrat` @Montserrat.
---| `ac.NationCode.Martinique` @Martinique.
---| `ac.NationCode.Mauritius` @Mauritius.
---| `ac.NationCode.Malawi` @Malawi.
---| `ac.NationCode.Malaysia` @Malaysia.
---| `ac.NationCode.Namibia` @Namibia.
---| `ac.NationCode.New` @New.
---| `ac.NationCode.Niger` @Niger.
---| `ac.NationCode.Nigeria` @Nigeria.
---| `ac.NationCode.Nicaragua` @Nicaragua.
---| `ac.NationCode.Northern` @Northern.
---| `ac.NationCode.Netherlands` @Netherlands.
---| `ac.NationCode.Norway` @Norway.
---| `ac.NationCode.Nepal` @Nepal.
---| `ac.NationCode.Nauru` @Nauru.
---| `ac.NationCode.Oman` @Oman.
---| `ac.NationCode.Pakistan` @Pakistan.
---| `ac.NationCode.Panama` @Panama.
---| `ac.NationCode.Peru` @Peru.
---| `ac.NationCode.Philippines` @Philippines.
---| `ac.NationCode.Palau` @Palau.
---| `ac.NationCode.Papua` @Papua.
---| `ac.NationCode.Poland` @Poland.
---| `ac.NationCode.Puerto` @Puerto.
---| `ac.NationCode.Portugal` @Portugal.
---| `ac.NationCode.Paraguay` @Paraguay.
---| `ac.NationCode.French` @French.
---| `ac.NationCode.Qatar` @Qatar.
---| `ac.NationCode.Romania` @Romania.
---| `ac.NationCode.Russia` @Russia.
---| `ac.NationCode.Rwanda` @Rwanda.
---| `ac.NationCode.Saudi` @Saudi.
---| `ac.NationCode.Scotland` @Scotland.
---| `ac.NationCode.Sudan` @Sudan.
---| `ac.NationCode.Senegal` @Senegal.
---| `ac.NationCode.Singapore` @Singapore.
---| `ac.NationCode.Solomon` @Solomon.
---| `ac.NationCode.Sierra` @Sierra.
---| `ac.NationCode.El` @El.
---| `ac.NationCode.San` @San.
---| `ac.NationCode.Somalia` @Somalia.
---| `ac.NationCode.Serbia` @Serbia.
---| `ac.NationCode.Sao` @Sao.
---| `ac.NationCode.Suriname` @Suriname.
---| `ac.NationCode.Slovakia` @Slovakia.
---| `ac.NationCode.Slovenia` @Slovenia.
---| `ac.NationCode.Sweden` @Sweden.
---| `ac.NationCode.Swaziland` @Swaziland.
---| `ac.NationCode.Seychelles` @Seychelles.
---| `ac.NationCode.Syria` @Syria.
---| `ac.NationCode.Turks` @Turks.
---| `ac.NationCode.Chad` @Chad.
---| `ac.NationCode.Togo` @Togo.
---| `ac.NationCode.Thailand` @Thailand.
---| `ac.NationCode.Tajikistan` @Tajikistan.
---| `ac.NationCode.Turkmenistan` @Turkmenistan.
---| `ac.NationCode.Timor` @Timor.
---| `ac.NationCode.Tonga` @Tonga.
---| `ac.NationCode.Trinidad` @Trinidad.
---| `ac.NationCode.Tunisia` @Tunisia.
---| `ac.NationCode.Turkey` @Turkey.
---| `ac.NationCode.Tuvalu` @Tuvalu.
---| `ac.NationCode.Taiwan` @Taiwan.
---| `ac.NationCode.Tanzania` @Tanzania.
---| `ac.NationCode.Uganda` @Uganda.
---| `ac.NationCode.Ukraine` @Ukraine.
---| `ac.NationCode.Uruguay` @Uruguay.
---| `ac.NationCode.USA` @USA.
---| `ac.NationCode.Uzbekistan` @Uzbekistan.
---| `ac.NationCode.Venezuela` @Venezuela.
---| `ac.NationCode.British` @British.
---| `ac.NationCode.Virgin` @Virgin.
---| `ac.NationCode.Vietnam` @Vietnam.
---| `ac.NationCode.Vanuatu` @Vanuatu.
---| `ac.NationCode.Wales` @Wales.
---| `ac.NationCode.Samoa` @Samoa.
---| `ac.NationCode.Yemen` @Yemen.
---| `ac.NationCode.Zambia` @Zambia.
---| `ac.NationCode.Zimbabwe` @Zimbabwe.
ac.NationCode = {
  Aruba = 'ABW', ---@type ac.NationCode #Aruba.
  Afghanistan = 'AFG', ---@type ac.NationCode #Afghanistan.
  Angola = 'AGO', ---@type ac.NationCode #Angola.
  Anguilla = 'AIA', ---@type ac.NationCode #Anguilla.
  Albania = 'ALB', ---@type ac.NationCode #Albania.
  Andorra = 'AND', ---@type ac.NationCode #Andorra.
  United = 'ARE', ---@type ac.NationCode #United.
  Argentina = 'ARG', ---@type ac.NationCode #Argentina.
  Armenia = 'ARM', ---@type ac.NationCode #Armenia.
  American = 'ASM', ---@type ac.NationCode #American.
  Antarctica = 'ATA', ---@type ac.NationCode #Antarctica.
  Antigua = 'ATG', ---@type ac.NationCode #Antigua.
  Australia = 'AUS', ---@type ac.NationCode #Australia.
  Austria = 'AUT', ---@type ac.NationCode #Austria.
  Azerbaijan = 'AZE', ---@type ac.NationCode #Azerbaijan.
  Burundi = 'BDI', ---@type ac.NationCode #Burundi.
  Belgium = 'BEL', ---@type ac.NationCode #Belgium.
  Benin = 'BEN', ---@type ac.NationCode #Benin.
  Burkina = 'BFA', ---@type ac.NationCode #Burkina.
  Bangladesh = 'BGD', ---@type ac.NationCode #Bangladesh.
  Bulgaria = 'BGR', ---@type ac.NationCode #Bulgaria.
  Bahrain = 'BHR', ---@type ac.NationCode #Bahrain.
  Bahamas = 'BHS', ---@type ac.NationCode #Bahamas.
  Bosnia = 'BIH', ---@type ac.NationCode #Bosnia.
  Belarus = 'BLR', ---@type ac.NationCode #Belarus.
  Belize = 'BLZ', ---@type ac.NationCode #Belize.
  Bermuda = 'BMU', ---@type ac.NationCode #Bermuda.
  Bolivia = 'BOL', ---@type ac.NationCode #Bolivia.
  Brazil = 'BRA', ---@type ac.NationCode #Brazil.
  Barbados = 'BRB', ---@type ac.NationCode #Barbados.
  Brunei = 'BRN', ---@type ac.NationCode #Brunei.
  Bhutan = 'BTN', ---@type ac.NationCode #Bhutan.
  Botswana = 'BWA', ---@type ac.NationCode #Botswana.
  Central = 'CAF', ---@type ac.NationCode #Central.
  Canada = 'CAN', ---@type ac.NationCode #Canada.
  Cocos = 'CCK', ---@type ac.NationCode #Cocos.
  Switzerland = 'CHE', ---@type ac.NationCode #Switzerland.
  Chile = 'CHL', ---@type ac.NationCode #Chile.
  China = 'CHN', ---@type ac.NationCode #China.
  Cote = 'CIV', ---@type ac.NationCode #Côte.
  Cameroon = 'CMR', ---@type ac.NationCode #Cameroon.
  Congo = 'COG', ---@type ac.NationCode #Congo.
  Cook = 'COK', ---@type ac.NationCode #Cook.
  Colombia = 'COL', ---@type ac.NationCode #Colombia.
  Comoros = 'COM', ---@type ac.NationCode #Comoros.
  Cape = 'CPV', ---@type ac.NationCode #Cape.
  Costa = 'CRI', ---@type ac.NationCode #Costa.
  Cuba = 'CUB', ---@type ac.NationCode #Cuba.
  Cayman = 'CYM', ---@type ac.NationCode #Cayman.
  Cyprus = 'CYP', ---@type ac.NationCode #Cyprus.
  Czech = 'CZE', ---@type ac.NationCode #Czech.
  Germany = 'DEU', ---@type ac.NationCode #Germany.
  Djibouti = 'DJI', ---@type ac.NationCode #Djibouti.
  Dominica = 'DMA', ---@type ac.NationCode #Dominica.
  Denmark = 'DNK', ---@type ac.NationCode #Denmark.
  Dominican = 'DOM', ---@type ac.NationCode #Dominican.
  Algeria = 'DZA', ---@type ac.NationCode #Algeria.
  Ecuador = 'ECU', ---@type ac.NationCode #Ecuador.
  Egypt = 'EGY', ---@type ac.NationCode #Egypt.
  England = 'ENG', ---@type ac.NationCode #England.
  Eritrea = 'ERI', ---@type ac.NationCode #Eritrea.
  Western = 'ESH', ---@type ac.NationCode #Western.
  Spain = 'ESP', ---@type ac.NationCode #Spain.
  Estonia = 'EST', ---@type ac.NationCode #Estonia.
  Ethiopia = 'ETH', ---@type ac.NationCode #Ethiopia.
  Finland = 'FIN', ---@type ac.NationCode #Finland.
  Fiji = 'FJI', ---@type ac.NationCode #Fiji.
  France = 'FRA', ---@type ac.NationCode #France.
  Faroe = 'FRO', ---@type ac.NationCode #Faroe.
  Micronesia = 'FSM', ---@type ac.NationCode #Micronesia.
  Gabon = 'GAB', ---@type ac.NationCode #Gabon.
  Great = 'GBR', ---@type ac.NationCode #Great.
  Georgia = 'GEO', ---@type ac.NationCode #Georgia.
  Guernsey = 'GGY', ---@type ac.NationCode #Guernsey.
  Ghana = 'GHA', ---@type ac.NationCode #Ghana.
  Gibraltar = 'GIB', ---@type ac.NationCode #Gibraltar.
  Guinea = 'GNB', ---@type ac.NationCode #Guinea.
  Gambia = 'GMB', ---@type ac.NationCode #Gambia.
  Equatorial = 'GNQ', ---@type ac.NationCode #Equatorial.
  Greece = 'GRC', ---@type ac.NationCode #Greece.
  Grenada = 'GRD', ---@type ac.NationCode #Grenada.
  Greenland = 'GRL', ---@type ac.NationCode #Greenland.
  Guatemala = 'GTM', ---@type ac.NationCode #Guatemala.
  Guam = 'GUM', ---@type ac.NationCode #Guam.
  Guyana = 'GUY', ---@type ac.NationCode #Guyana.
  Hong = 'HKG', ---@type ac.NationCode #Hong.
  Honduras = 'HND', ---@type ac.NationCode #Honduras.
  Croatia = 'HRV', ---@type ac.NationCode #Croatia.
  Haiti = 'HTI', ---@type ac.NationCode #Haiti.
  Hungary = 'HUN', ---@type ac.NationCode #Hungary.
  Indonesia = 'IDN', ---@type ac.NationCode #Indonesia.
  Isle = 'IMN', ---@type ac.NationCode #Isle.
  India = 'IND', ---@type ac.NationCode #India.
  Ireland = 'IRL', ---@type ac.NationCode #Ireland.
  Iran = 'IRN', ---@type ac.NationCode #Iran.
  Iraq = 'IRQ', ---@type ac.NationCode #Iraq.
  Iceland = 'ISL', ---@type ac.NationCode #Iceland.
  Israel = 'ISR', ---@type ac.NationCode #Israel.
  Italy = 'ITA', ---@type ac.NationCode #Italy.
  Jamaica = 'JAM', ---@type ac.NationCode #Jamaica.
  Jersey = 'JEY', ---@type ac.NationCode #Jersey.
  Jordan = 'JOR', ---@type ac.NationCode #Jordan.
  Japan = 'JPN', ---@type ac.NationCode #Japan.
  Kazakhstan = 'KAZ', ---@type ac.NationCode #Kazakhstan.
  Kenya = 'KEN', ---@type ac.NationCode #Kenya.
  Kyrgyzstan = 'KGZ', ---@type ac.NationCode #Kyrgyzstan.
  Cambodia = 'KHM', ---@type ac.NationCode #Cambodia.
  Kiribati = 'KIR', ---@type ac.NationCode #Kiribati.
  Saint = 'VCT', ---@type ac.NationCode #Saint.
  South = 'ZAF', ---@type ac.NationCode #South.
  Kuwait = 'KWT', ---@type ac.NationCode #Kuwait.
  Laos = 'LAO', ---@type ac.NationCode #Laos.
  Lebanon = 'LBN', ---@type ac.NationCode #Lebanon.
  Liberia = 'LBR', ---@type ac.NationCode #Liberia.
  Liechtenstein = 'LIE', ---@type ac.NationCode #Liechtenstein.
  Sri = 'LKA', ---@type ac.NationCode #Sri.
  Lesotho = 'LSO', ---@type ac.NationCode #Lesotho.
  Lithuania = 'LTU', ---@type ac.NationCode #Lithuania.
  Luxembourg = 'LUX', ---@type ac.NationCode #Luxembourg.
  Latvia = 'LVA', ---@type ac.NationCode #Latvia.
  Macau = 'MAC', ---@type ac.NationCode #Macau.
  Morocco = 'MAR', ---@type ac.NationCode #Morocco.
  Monaco = 'MCO', ---@type ac.NationCode #Monaco.
  Moldova = 'MDA', ---@type ac.NationCode #Moldova.
  Madagascar = 'MDG', ---@type ac.NationCode #Madagascar.
  Maldives = 'MDV', ---@type ac.NationCode #Maldives.
  Mexico = 'MEX', ---@type ac.NationCode #Mexico.
  Marshall = 'MHL', ---@type ac.NationCode #Marshall.
  Macedonia = 'MKD', ---@type ac.NationCode #Macedonia.
  Mali = 'MLI', ---@type ac.NationCode #Mali.
  Malta = 'MLT', ---@type ac.NationCode #Malta.
  Myanmar = 'MMR', ---@type ac.NationCode #Myanmar.
  Montenegro = 'MNE', ---@type ac.NationCode #Montenegro.
  Mongolia = 'MNG', ---@type ac.NationCode #Mongolia.
  Mozambique = 'MOZ', ---@type ac.NationCode #Mozambique.
  Mauritania = 'MRT', ---@type ac.NationCode #Mauritania.
  Montserrat = 'MSR', ---@type ac.NationCode #Montserrat.
  Martinique = 'MTQ', ---@type ac.NationCode #Martinique.
  Mauritius = 'MUS', ---@type ac.NationCode #Mauritius.
  Malawi = 'MWI', ---@type ac.NationCode #Malawi.
  Malaysia = 'MYS', ---@type ac.NationCode #Malaysia.
  Namibia = 'NAM', ---@type ac.NationCode #Namibia.
  New = 'NZL', ---@type ac.NationCode #New.
  Niger = 'NER', ---@type ac.NationCode #Niger.
  Nigeria = 'NGA', ---@type ac.NationCode #Nigeria.
  Nicaragua = 'NIC', ---@type ac.NationCode #Nicaragua.
  Northern = 'NIR', ---@type ac.NationCode #Northern.
  Netherlands = 'NLD', ---@type ac.NationCode #Netherlands.
  Norway = 'NOR', ---@type ac.NationCode #Norway.
  Nepal = 'NPL', ---@type ac.NationCode #Nepal.
  Nauru = 'NRU', ---@type ac.NationCode #Nauru.
  Oman = 'OMN', ---@type ac.NationCode #Oman.
  Pakistan = 'PAK', ---@type ac.NationCode #Pakistan.
  Panama = 'PAN', ---@type ac.NationCode #Panama.
  Peru = 'PER', ---@type ac.NationCode #Peru.
  Philippines = 'PHL', ---@type ac.NationCode #Philippines.
  Palau = 'PLW', ---@type ac.NationCode #Palau.
  Papua = 'PNG', ---@type ac.NationCode #Papua.
  Poland = 'POL', ---@type ac.NationCode #Poland.
  Puerto = 'PRI', ---@type ac.NationCode #Puerto.
  Portugal = 'PRT', ---@type ac.NationCode #Portugal.
  Paraguay = 'PRY', ---@type ac.NationCode #Paraguay.
  French = 'PYF', ---@type ac.NationCode #French.
  Qatar = 'QAT', ---@type ac.NationCode #Qatar.
  Romania = 'ROU', ---@type ac.NationCode #Romania.
  Russia = 'RUS', ---@type ac.NationCode #Russia.
  Rwanda = 'RWA', ---@type ac.NationCode #Rwanda.
  Saudi = 'SAU', ---@type ac.NationCode #Saudi.
  Scotland = 'SCT', ---@type ac.NationCode #Scotland.
  Sudan = 'SDN', ---@type ac.NationCode #Sudan.
  Senegal = 'SEN', ---@type ac.NationCode #Senegal.
  Singapore = 'SGP', ---@type ac.NationCode #Singapore.
  Solomon = 'SLB', ---@type ac.NationCode #Solomon.
  Sierra = 'SLE', ---@type ac.NationCode #Sierra.
  El = 'SLV', ---@type ac.NationCode #El.
  San = 'SMR', ---@type ac.NationCode #San.
  Somalia = 'SOM', ---@type ac.NationCode #Somalia.
  Serbia = 'SRB', ---@type ac.NationCode #Serbia.
  Sao = 'STP', ---@type ac.NationCode #Sao.
  Suriname = 'SUR', ---@type ac.NationCode #Suriname.
  Slovakia = 'SVK', ---@type ac.NationCode #Slovakia.
  Slovenia = 'SVN', ---@type ac.NationCode #Slovenia.
  Sweden = 'SWE', ---@type ac.NationCode #Sweden.
  Swaziland = 'SWZ', ---@type ac.NationCode #Swaziland.
  Seychelles = 'SYC', ---@type ac.NationCode #Seychelles.
  Syria = 'SYR', ---@type ac.NationCode #Syria.
  Turks = 'TCA', ---@type ac.NationCode #Turks.
  Chad = 'TCD', ---@type ac.NationCode #Chad.
  Togo = 'TGO', ---@type ac.NationCode #Togo.
  Thailand = 'THA', ---@type ac.NationCode #Thailand.
  Tajikistan = 'TJK', ---@type ac.NationCode #Tajikistan.
  Turkmenistan = 'TKM', ---@type ac.NationCode #Turkmenistan.
  Timor = 'TLS', ---@type ac.NationCode #Timor.
  Tonga = 'TON', ---@type ac.NationCode #Tonga.
  Trinidad = 'TTO', ---@type ac.NationCode #Trinidad.
  Tunisia = 'TUN', ---@type ac.NationCode #Tunisia.
  Turkey = 'TUR', ---@type ac.NationCode #Turkey.
  Tuvalu = 'TUV', ---@type ac.NationCode #Tuvalu.
  Taiwan = 'TWN', ---@type ac.NationCode #Taiwan.
  Tanzania = 'TZA', ---@type ac.NationCode #Tanzania.
  Uganda = 'UGA', ---@type ac.NationCode #Uganda.
  Ukraine = 'UKR', ---@type ac.NationCode #Ukraine.
  Uruguay = 'URY', ---@type ac.NationCode #Uruguay.
  USA = 'USA', ---@type ac.NationCode #USA.
  Uzbekistan = 'UZB', ---@type ac.NationCode #Uzbekistan.
  Venezuela = 'VEN', ---@type ac.NationCode #Venezuela.
  British = 'VGB', ---@type ac.NationCode #British.
  Virgin = 'VIR', ---@type ac.NationCode #Virgin.
  Vietnam = 'VNM', ---@type ac.NationCode #Vietnam.
  Vanuatu = 'VUT', ---@type ac.NationCode #Vanuatu.
  Wales = 'WLS', ---@type ac.NationCode #Wales.
  Samoa = 'WSM', ---@type ac.NationCode #Samoa.
  Yemen = 'YEM', ---@type ac.NationCode #Yemen.
  Zambia = 'ZMB', ---@type ac.NationCode #Zambia.
  Zimbabwe = 'ZWE', ---@type ac.NationCode #Zimbabwe.
}

---@alias ac.CSPModuleID
---| `ac.CSPModuleID.BrakeDiscFX` @Brake Disc FX.
---| `ac.CSPModuleID.CarInstruments` @Car instruments.
---| `ac.CSPModuleID.ChaserCamera` @Chaser Camera.
---| `ac.CSPModuleID.ChatShortcuts` @Chat shortcuts.
---| `ac.CSPModuleID.ColorfulShadowing` @Colorful shadowing.
---| `ac.CSPModuleID.CustomRenderingModes` @Mode tweaks: custom render modes.
---| `ac.CSPModuleID.DXGITweaks` @DXGI.
---| `ac.CSPModuleID.ExtraFX` @Extra FX.
---| `ac.CSPModuleID.FakeShadowsFX` @Fake Shadows FX.
---| `ac.CSPModuleID.FFBTweaks` @FFB Tweaks.
---| `ac.CSPModuleID.FreerCamera` @Freer Camera.
---| `ac.CSPModuleID.G27Lights` @Logitech G27/29.
---| `ac.CSPModuleID.GamepadFX` @Gamepad FX.
---| `ac.CSPModuleID.General` @General Patch settings.
---| `ac.CSPModuleID.GraphicsAdjustments` @Graphics adjustments.
---| `ac.CSPModuleID.GrassFX` @Grass FX.
---| `ac.CSPModuleID.GUI` @GUI.
---| `ac.CSPModuleID.LightingFX` @Lighting FX.
---| `ac.CSPModuleID.LuaTools` @Lua_tools.
---| `ac.CSPModuleID.MumblePlugin` @Mumble_plugin.
---| `ac.CSPModuleID.Music` @Music.
---| `ac.CSPModuleID.NeckFX` @Neck FX.
---| `ac.CSPModuleID.NewBehaviour` @New AI behavior.
---| `ac.CSPModuleID.NiceScreenshots` @Nice Screenshots.
---| `ac.CSPModuleID.ParticlesFX` @Particles FX.
---| `ac.CSPModuleID.RainFX` @Rain FX.
---| `ac.CSPModuleID.ReflectionsFX` @Reflections FX.
---| `ac.CSPModuleID.ShadowedWheels` @Shadowed wheels.
---| `ac.CSPModuleID.SkidmarksFX` @Skidmarks FX.
---| `ac.CSPModuleID.SmallTweaks` @Small tweaks.
---| `ac.CSPModuleID.SmartMirror` @Smart Mirror.
---| `ac.CSPModuleID.SmartShadows` @Smart Shadows.
---| `ac.CSPModuleID.Spectating` @Spectating.
---| `ac.CSPModuleID.Splashscreen` @New loading screen.
---| `ac.CSPModuleID.SurfacesFX` @Surfaces FX.
---| `ac.CSPModuleID.Taskbar` @Taskbar.
---| `ac.CSPModuleID.TrackAdjustments` @Track adjustments.
---| `ac.CSPModuleID.TripleCustom` @Mode tweaks: Triple.
---| `ac.CSPModuleID.TyresFX` @Tyres FX.
---| `ac.CSPModuleID.VRTweaks` @Mode tweaks: VR.
---| `ac.CSPModuleID.WalkingOut` @Walking_out.
---| `ac.CSPModuleID.WeatherFX` @Weather FX.
---| `ac.CSPModuleID.WindscreenFX` @Windscreen FX.
---| `ac.CSPModuleID.Yebisest` @Yebisest.
ac.CSPModuleID = {
  BrakeDiscFX = 'brakedisc_fx', ---@type ac.CSPModuleID #Brake Disc FX.
  CarInstruments = 'car_instruments', ---@type ac.CSPModuleID #Car instruments.
  ChaserCamera = 'chaser_camera', ---@type ac.CSPModuleID #Chaser Camera.
  ChatShortcuts = 'chat_shortcuts', ---@type ac.CSPModuleID #Chat shortcuts.
  ColorfulShadowing = 'colorful_shadowing', ---@type ac.CSPModuleID #Colorful shadowing.
  CustomRenderingModes = 'custom_rendering_modes', ---@type ac.CSPModuleID #Mode tweaks: custom render modes.
  DXGITweaks = 'dxgi_tweaks', ---@type ac.CSPModuleID #DXGI.
  ExtraFX = 'extra_fx', ---@type ac.CSPModuleID #Extra FX.
  FakeShadowsFX = 'fake_shadows_fx', ---@type ac.CSPModuleID #Fake Shadows FX.
  FFBTweaks = 'ffb_tweaks', ---@type ac.CSPModuleID #FFB Tweaks.
  FreerCamera = 'freer_camera', ---@type ac.CSPModuleID #Freer Camera.
  G27Lights = 'g27_lights', ---@type ac.CSPModuleID #Logitech G27/29.
  GamepadFX = 'gamepad_fx', ---@type ac.CSPModuleID #Gamepad FX.
  General = 'general', ---@type ac.CSPModuleID #General Patch settings.
  GraphicsAdjustments = 'graphics_adjustments', ---@type ac.CSPModuleID #Graphics adjustments.
  GrassFX = 'grass_fx', ---@type ac.CSPModuleID #Grass FX.
  GUI = 'gui', ---@type ac.CSPModuleID #GUI.
  LightingFX = 'lighting_fx', ---@type ac.CSPModuleID #Lighting FX.
  LuaTools = 'lua_tools', ---@type ac.CSPModuleID #Lua_tools.
  MumblePlugin = 'mumble_plugin', ---@type ac.CSPModuleID #Mumble_plugin.
  Music = 'music', ---@type ac.CSPModuleID #Music.
  NeckFX = 'neck', ---@type ac.CSPModuleID #Neck FX.
  NewBehaviour = 'new_behaviour', ---@type ac.CSPModuleID #New AI behavior.
  NiceScreenshots = 'nice_screenshots', ---@type ac.CSPModuleID #Nice Screenshots.
  ParticlesFX = 'particles_fx', ---@type ac.CSPModuleID #Particles FX.
  RainFX = 'rain_fx', ---@type ac.CSPModuleID #Rain FX.
  ReflectionsFX = 'reflections_fx', ---@type ac.CSPModuleID #Reflections FX.
  ShadowedWheels = 'shadowed_wheels', ---@type ac.CSPModuleID #Shadowed wheels.
  SkidmarksFX = 'skidmarks_fx', ---@type ac.CSPModuleID #Skidmarks FX.
  SmallTweaks = 'small_tweaks', ---@type ac.CSPModuleID #Small tweaks.
  SmartMirror = 'smart_mirror', ---@type ac.CSPModuleID #Smart Mirror.
  SmartShadows = 'smart_shadows', ---@type ac.CSPModuleID #Smart Shadows.
  Spectating = 'spectating', ---@type ac.CSPModuleID #Spectating.
  Splashscreen = 'splashscreen', ---@type ac.CSPModuleID #New loading screen.
  SurfacesFX = 'surfaces_fx', ---@type ac.CSPModuleID #Surfaces FX.
  Taskbar = 'taskbar', ---@type ac.CSPModuleID #Taskbar.
  TrackAdjustments = 'track_adjustments', ---@type ac.CSPModuleID #Track adjustments.
  TripleCustom = 'triple_custom', ---@type ac.CSPModuleID #Mode tweaks: Triple.
  TyresFX = 'tyres_fx', ---@type ac.CSPModuleID #Tyres FX.
  VRTweaks = 'vr_tweaks', ---@type ac.CSPModuleID #Mode tweaks: VR.
  WalkingOut = 'walking_out', ---@type ac.CSPModuleID #Walking_out.
  WeatherFX = 'weather_fx', ---@type ac.CSPModuleID #Weather FX.
  WindscreenFX = 'windscreen_fx', ---@type ac.CSPModuleID #Windscreen FX.
  Yebisest = 'yebisest', ---@type ac.CSPModuleID #Yebisest.
}

---@alias ac.ObjectClass
---| `ac.ObjectClass.Any` @Return any scene object. If returned as result from `:class()`, means that there is no object with such index.
---| `ac.ObjectClass.Node` @Regular children-holding objects.
---| `ac.ObjectClass.Model` @Track objects.
---| `ac.ObjectClass.CarNodeSorter` @An object holding cars.
---| `ac.ObjectClass.NodeBoundingSphere` @A wrapper for each car, skipping rendering if whole thing is not in frustum.
---| `ac.ObjectClass.IdealLine` @Ideal line.
---| `ac.ObjectClass.ParticleSystem` @Particle systems (don’t do much with ParticlesFX active).
---| `ac.ObjectClass.StaticParticleSystem` @Usually used for spectators.
---| `ac.ObjectClass.DisplayNode` @Display nodes for car dashboards.
---| `ac.ObjectClass.TextNode` @3D text nodes for car dashboards.
---| `ac.ObjectClass.CSPNode` @CSP nodes, for example fake shadow nodes.
---| `ac.ObjectClass.Renderable` @Refers to meshes and skinned meshes together.
---| `ac.ObjectClass.Mesh` @Regular meshes.
---| `ac.ObjectClass.SkinnedMesh` @Skinned meshes.
---| `ac.ObjectClass.SkidmarkBuffer` @Objects with skidmarks (don’t do much with SkidmarksFX active).
ac.ObjectClass = {
  Any = 0, ---@type ac.ObjectClass #Return any scene object. If returned as result from `:class()`, means that there is no object with such index.
  Node = 1, ---@type ac.ObjectClass #Regular children-holding objects.
  Model = 2, ---@type ac.ObjectClass #Track objects.
  CarNodeSorter = 3, ---@type ac.ObjectClass #An object holding cars.
  NodeBoundingSphere = 4, ---@type ac.ObjectClass #A wrapper for each car, skipping rendering if whole thing is not in frustum.
  IdealLine = 7, ---@type ac.ObjectClass #Ideal line.
  ParticleSystem = 8, ---@type ac.ObjectClass #Particle systems (don’t do much with ParticlesFX active).
  StaticParticleSystem = 9, ---@type ac.ObjectClass #Usually used for spectators.
  DisplayNode = 10, ---@type ac.ObjectClass #Display nodes for car dashboards.
  TextNode = 11, ---@type ac.ObjectClass #3D text nodes for car dashboards.
  CSPNode = 12, ---@type ac.ObjectClass #CSP nodes, for example fake shadow nodes.
  Renderable = 13, ---@type ac.ObjectClass #Refers to meshes and skinned meshes together.
  Mesh = 15, ---@type ac.ObjectClass #Regular meshes.
  SkinnedMesh = 16, ---@type ac.ObjectClass #Skinned meshes.
  SkidmarkBuffer = 17, ---@type ac.ObjectClass #Objects with skidmarks (don’t do much with SkidmarksFX active).
}

---@alias ac.GamepadButton
---| `ac.GamepadButton.DPadUp` @Value: 0x1.
---| `ac.GamepadButton.DPadDown` @Value: 0x2.
---| `ac.GamepadButton.DPadLeft` @Value: 0x4.
---| `ac.GamepadButton.DPadRight` @Value: 0x8.
---| `ac.GamepadButton.Start` @Value: 0x10.
---| `ac.GamepadButton.Back` @Value: 0x20.
---| `ac.GamepadButton.LeftThumb` @Value: 0x40.
---| `ac.GamepadButton.RightThumb` @Value: 0x80.
---| `ac.GamepadButton.LeftShoulder` @Value: 0x100.
---| `ac.GamepadButton.RightShoulder` @Value: 0x200.
---| `ac.GamepadButton.L2` @Only for DualShock and Nintendo (ZL) gamepads.
---| `ac.GamepadButton.R2` @Only for DualShock and Nintendo (ZR) gamepads.
---| `ac.GamepadButton.A` @Value: 0x1000.
---| `ac.GamepadButton.B` @Value: 0x2000.
---| `ac.GamepadButton.X` @Value: 0x4000.
---| `ac.GamepadButton.Y` @Value: 0x8000.
---| `ac.GamepadButton.PlayStation` @Only for DualShock, DualSense and Nintendo (Home button) gamepads.
---| `ac.GamepadButton.Microphone` @Only for DualSense and Nintendo (SL button) gamepads.
---| `ac.GamepadButton.Pad` @Only for DualShock, DualSense and Nintendo (Capture button) gamepads.
---| `ac.GamepadButton.Extra` @Only for Nintendo (SR button) gamepads.
ac.GamepadButton = {
  DPadUp = 0x1, ---@type ac.GamepadButton #Value: 0x1.
  DPadDown = 0x2, ---@type ac.GamepadButton #Value: 0x2.
  DPadLeft = 0x4, ---@type ac.GamepadButton #Value: 0x4.
  DPadRight = 0x8, ---@type ac.GamepadButton #Value: 0x8.
  Start = 0x10, ---@type ac.GamepadButton #Value: 0x10.
  Back = 0x20, ---@type ac.GamepadButton #Value: 0x20.
  LeftThumb = 0x40, ---@type ac.GamepadButton #Value: 0x40.
  RightThumb = 0x80, ---@type ac.GamepadButton #Value: 0x80.
  LeftShoulder = 0x100, ---@type ac.GamepadButton #Value: 0x100.
  RightShoulder = 0x200, ---@type ac.GamepadButton #Value: 0x200.
  L2 = 0x400, ---@type ac.GamepadButton #Only for DualShock and Nintendo (ZL) gamepads.
  R2 = 0x800, ---@type ac.GamepadButton #Only for DualShock and Nintendo (ZR) gamepads.
  A = 0x1000, ---@type ac.GamepadButton #Value: 0x1000.
  B = 0x2000, ---@type ac.GamepadButton #Value: 0x2000.
  X = 0x4000, ---@type ac.GamepadButton #Value: 0x4000.
  Y = 0x8000, ---@type ac.GamepadButton #Value: 0x8000.
  PlayStation = 0x10000, ---@type ac.GamepadButton #Only for DualShock, DualSense and Nintendo (Home button) gamepads.
  Microphone = 0x20000, ---@type ac.GamepadButton #Only for DualSense and Nintendo (SL button) gamepads.
  Pad = 0x40000, ---@type ac.GamepadButton #Only for DualShock, DualSense and Nintendo (Capture button) gamepads.
  Extra = 0x80000, ---@type ac.GamepadButton #Only for Nintendo (SR button) gamepads.
}

---@alias ac.GamepadAxis
---| `ac.GamepadAxis.LeftTrigger` @Value: 0.
---| `ac.GamepadAxis.RightTrigger` @Value: 1.
---| `ac.GamepadAxis.LeftThumbX` @Value: 2.
---| `ac.GamepadAxis.LeftThumbY` @Value: 3.
---| `ac.GamepadAxis.RightThumbX` @Value: 4.
---| `ac.GamepadAxis.RightThumbY` @Value: 5.
ac.GamepadAxis = {
  LeftTrigger = 0, ---@type ac.GamepadAxis #Value: 0.
  RightTrigger = 1, ---@type ac.GamepadAxis #Value: 1.
  LeftThumbX = 2, ---@type ac.GamepadAxis #Value: 2.
  LeftThumbY = 3, ---@type ac.GamepadAxis #Value: 3.
  RightThumbX = 4, ---@type ac.GamepadAxis #Value: 4.
  RightThumbY = 5, ---@type ac.GamepadAxis #Value: 5.
}

---@alias ac.GamepadType
---| `ac.GamepadType.None` @No gamepad in that slot.
---| `ac.GamepadType.XBox` @Regular XBox gamepad.
---| `ac.GamepadType.DualSense` @DualSense gamepad.
---| `ac.GamepadType.DualShock` @DualShock gamepad (can also be one of Nintendo gamepads; use `ac.getDualShock(…).type` to check).
ac.GamepadType = {
  None = 0, ---@type ac.GamepadType #No gamepad in that slot.
  XBox = 1, ---@type ac.GamepadType #Regular XBox gamepad.
  DualSense = 2, ---@type ac.GamepadType #DualSense gamepad.
  DualShock = 3, ---@type ac.GamepadType #DualShock gamepad (can also be one of Nintendo gamepads; use `ac.getDualShock(…).type` to check).
}

---Due to compatibility issues DualShock and Nintendo devices are combined in an alternative API area separately from DualSense.
---@alias ac.GamepadDualShockType
---| `ac.GamepadDualShockType.JoyConLeft` @Left Joy-Con.
---| `ac.GamepadDualShockType.JoyConRight` @Right Joy-Con.
---| `ac.GamepadDualShockType.SwitchPro` @Switch Pro Controller.
---| `ac.GamepadDualShockType.DualShock` @DualShock 4.
---| `ac.GamepadDualShockType.DualSense` @DualSense (can appear here if controller is configured to launch in DualShock mode in CM controls settings).
ac.GamepadDualShockType = {
  JoyConLeft = 1, ---@type ac.GamepadDualShockType #Left Joy-Con.
  JoyConRight = 2, ---@type ac.GamepadDualShockType #Right Joy-Con.
  SwitchPro = 3, ---@type ac.GamepadDualShockType #Switch Pro Controller.
  DualShock = 4, ---@type ac.GamepadDualShockType #DualShock 4.
  DualSense = 5, ---@type ac.GamepadDualShockType #DualSense (can appear here if controller is configured to launch in DualShock mode in CM controls settings).
}

---@alias os.DialogFlags
---| `os.DialogFlags.None` @Value: 0.
---| `os.DialogFlags.OverwritePrompt` @When saving a file, prompt before overwriting an existing file of the same name. This is a default value for the Save dialog.
---| `os.DialogFlags.StrictFileTypes` @In the Save dialog, only allow the user to choose a file that has one of the file name extensions specified through IFileDialog::SetFileTypes.
---| `os.DialogFlags.NoChangeDir` @Don't change the current working directory.
---| `os.DialogFlags.PickFolders` @Present an Open dialog that offers a choice of folders rather than files.
---| `os.DialogFlags.ForceFileSystem` @Ensures that returned items are file system items (SFGAO_FILESYSTEM). Note that this does not apply to items returned by IFileDialog::GetCurrentSelection.
---| `os.DialogFlags.AllNonStorageItems` @Enables the user to choose any item in the Shell namespace, not just those with SFGAO_STREAM or SFAGO_FILESYSTEM attributes. This flag cannot be combined with FOS_FORCEFILESYSTEM.
---| `os.DialogFlags.NoValidate` @Do not check for situations that would prevent an application from opening the selected file, such as sharing violations or access denied errors.
---| `os.DialogFlags.AllowMultiselect` @Enables the user to select multiple items in the open dialog. Note that when this flag is set, the IFileOpenDialog interface must be used to retrieve those items.
---| `os.DialogFlags.PathMustExist` @The item returned must be in an existing folder. This is a default value.
---| `os.DialogFlags.FileMustExist` @The item returned must exist. This is a default value for the Open dialog.
---| `os.DialogFlags.CreatePrompt` @Prompt for creation if the item returned in the save dialog does not exist. Note that this does not actually create the item.
---| `os.DialogFlags.ShareAware` @In the case of a sharing violation when an application is opening a file, call the application back through OnShareViolation for guidance. This flag is overridden by FOS_NOVALIDATE.
---| `os.DialogFlags.NoReadonlyReturn` @Do not return read-only items. This is a default value for the Save dialog.
---| `os.DialogFlags.NoTestFileCreate` @Do not test whether creation of the item as specified in the Save dialog will be successful. If this flag is not set, the calling application must handle errors, such as denial of access, discovered when the item is created.
---| `os.DialogFlags.HideMRUPlaces` @Hide the list of places from which the user has recently opened or saved items. This value is not supported as of Windows 7.
---| `os.DialogFlags.HidePinnedPlaces` @Hide items shown by default in the view's navigation pane. This flag is often used in conjunction with the IFileDialog::AddPlace method, to hide standard locations and replace them with custom locations.\n\nWindows 7 and later. Hide all of the standard namespace locations (such as Favorites, Libraries, Computer, and Network) shown in the navigation pane.\n\nWindows Vista. Hide the contents of the Favorite Links tree in the navigation pane. Note that the category itself is still displayed, but shown as empty.
---| `os.DialogFlags.NoDereferenceLinks` @Shortcuts should not be treated as their target items. This allows an application to open a .lnk file rather than what that file is a shortcut to.
---| `os.DialogFlags.OkButtonNeedsInteraction` @The OK button will be disabled until the user navigates the view or edits the filename (if applicable). Note: Disabling of the OK button does not prevent the dialog from being submitted by the Enter key.
---| `os.DialogFlags.DontAddToRecent` @Do not add the item being opened or saved to the recent documents list (SHAddToRecentDocs).
---| `os.DialogFlags.ForceShowHidden` @Include hidden and system items.
---| `os.DialogFlags.DefaultNoMiniMode` @Indicates to the Save As dialog box that it should open in expanded mode. Expanded mode is the mode that is set and unset by clicking the button in the lower-left corner of the Save As dialog box that switches between Browse Folders and Hide Folders when clicked. This value is not supported as of Windows 7.
---| `os.DialogFlags.ForcePreviewPaneOn` @Indicates to the Open dialog box that the preview pane should always be displayed.
---| `os.DialogFlags.SupportStreamableItems` @Indicates that the caller is opening a file as a stream (BHID_Stream), so there is no need to download that file.
os.DialogFlags = {
  None = 0, ---@type os.DialogFlags #Value: 0.
  OverwritePrompt = 2, ---@type os.DialogFlags #When saving a file, prompt before overwriting an existing file of the same name. This is a default value for the Save dialog.
  StrictFileTypes = 4, ---@type os.DialogFlags #In the Save dialog, only allow the user to choose a file that has one of the file name extensions specified through IFileDialog::SetFileTypes.
  NoChangeDir = 8, ---@type os.DialogFlags #Don't change the current working directory.
  PickFolders = 32, ---@type os.DialogFlags #Present an Open dialog that offers a choice of folders rather than files.
  ForceFileSystem = 64, ---@type os.DialogFlags #Ensures that returned items are file system items (SFGAO_FILESYSTEM). Note that this does not apply to items returned by IFileDialog::GetCurrentSelection.
  AllNonStorageItems = 128, ---@type os.DialogFlags #Enables the user to choose any item in the Shell namespace, not just those with SFGAO_STREAM or SFAGO_FILESYSTEM attributes. This flag cannot be combined with FOS_FORCEFILESYSTEM.
  NoValidate = 256, ---@type os.DialogFlags #Do not check for situations that would prevent an application from opening the selected file, such as sharing violations or access denied errors.
  AllowMultiselect = 512, ---@type os.DialogFlags #Enables the user to select multiple items in the open dialog. Note that when this flag is set, the IFileOpenDialog interface must be used to retrieve those items.
  PathMustExist = 2048, ---@type os.DialogFlags #The item returned must be in an existing folder. This is a default value.
  FileMustExist = 4096, ---@type os.DialogFlags #The item returned must exist. This is a default value for the Open dialog.
  CreatePrompt = 8192, ---@type os.DialogFlags #Prompt for creation if the item returned in the save dialog does not exist. Note that this does not actually create the item.
  ShareAware = 16384, ---@type os.DialogFlags #In the case of a sharing violation when an application is opening a file, call the application back through OnShareViolation for guidance. This flag is overridden by FOS_NOVALIDATE.
  NoReadonlyReturn = 32768, ---@type os.DialogFlags #Do not return read-only items. This is a default value for the Save dialog.
  NoTestFileCreate = 65536, ---@type os.DialogFlags #Do not test whether creation of the item as specified in the Save dialog will be successful. If this flag is not set, the calling application must handle errors, such as denial of access, discovered when the item is created.
  HideMRUPlaces = 131072, ---@type os.DialogFlags #Hide the list of places from which the user has recently opened or saved items. This value is not supported as of Windows 7.
  HidePinnedPlaces = 262144, ---@type os.DialogFlags #Hide items shown by default in the view's navigation pane. This flag is often used in conjunction with the IFileDialog::AddPlace method, to hide standard locations and replace them with custom locations.\n\nWindows 7 and later. Hide all of the standard namespace locations (such as Favorites, Libraries, Computer, and Network) shown in the navigation pane.\n\nWindows Vista. Hide the contents of the Favorite Links tree in the navigation pane. Note that the category itself is still displayed, but shown as empty.
  NoDereferenceLinks = 1048576, ---@type os.DialogFlags #Shortcuts should not be treated as their target items. This allows an application to open a .lnk file rather than what that file is a shortcut to.
  OkButtonNeedsInteraction = 2097152, ---@type os.DialogFlags #The OK button will be disabled until the user navigates the view or edits the filename (if applicable). Note: Disabling of the OK button does not prevent the dialog from being submitted by the Enter key.
  DontAddToRecent = 33554432, ---@type os.DialogFlags #Do not add the item being opened or saved to the recent documents list (SHAddToRecentDocs).
  ForceShowHidden = 268435456, ---@type os.DialogFlags #Include hidden and system items.
  DefaultNoMiniMode = 536870912, ---@type os.DialogFlags #Indicates to the Save As dialog box that it should open in expanded mode. Expanded mode is the mode that is set and unset by clicking the button in the lower-left corner of the Save As dialog box that switches between Browse Folders and Hide Folders when clicked. This value is not supported as of Windows 7.
  ForcePreviewPaneOn = 1073741824, ---@type os.DialogFlags #Indicates to the Open dialog box that the preview pane should always be displayed.
  SupportStreamableItems = 2147483648, ---@type os.DialogFlags #Indicates that the caller is opening a file as a stream (BHID_Stream), so there is no need to download that file.
}

---@alias ac.TurningLights
---| `ac.TurningLights.None` @Value: 0.
---| `ac.TurningLights.Left` @Value: 1.
---| `ac.TurningLights.Right` @Value: 2.
---| `ac.TurningLights.Hazards` @Value: 3.
ac.TurningLights = {
  None = 0, ---@type ac.TurningLights #Value: 0.
  Left = 1, ---@type ac.TurningLights #Value: 1.
  Right = 2, ---@type ac.TurningLights #Value: 2.
  Hazards = 3, ---@type ac.TurningLights #Value: 3.
}

---@alias ac.CarAudioEventID
---| `ac.CarAudioEventID.EngineExt` @Value: 0.
---| `ac.CarAudioEventID.EngineInt` @Value: 1.
---| `ac.CarAudioEventID.GearExt` @Value: 2.
---| `ac.CarAudioEventID.GearInt` @Value: 3.
---| `ac.CarAudioEventID.Bodywork` @Value: 4.
---| `ac.CarAudioEventID.Wind` @Value: 5.
---| `ac.CarAudioEventID.Dirt` @Value: 6.
---| `ac.CarAudioEventID.Downshift` @Value: 7.
---| `ac.CarAudioEventID.Horn` @Value: 8.
---| `ac.CarAudioEventID.GearGrind` @Value: 9.
---| `ac.CarAudioEventID.BackfireExt` @Value: 10.
---| `ac.CarAudioEventID.BackfireInt` @Value: 11.
---| `ac.CarAudioEventID.TractionControlExt` @Value: 12.
---| `ac.CarAudioEventID.TractionControlInt` @Value: 13.
---| `ac.CarAudioEventID.Transmission` @Value: 14.
---| `ac.CarAudioEventID.Limiter` @Value: 15.
---| `ac.CarAudioEventID.Turbo` @Value: 16.
---| `ac.CarAudioEventID.WheelLF` @Add 0-based index to this value for Nth wheel.
---| `ac.CarAudioEventID.WheelRF` @Value: 21.
---| `ac.CarAudioEventID.WheelLR` @Value: 22.
---| `ac.CarAudioEventID.WheelRR` @Value: 23.
---| `ac.CarAudioEventID.SkidIntLF` @Add 0-based index to this value for Nth wheel.
---| `ac.CarAudioEventID.SkidIntRF` @Value: 31.
---| `ac.CarAudioEventID.SkidIntLR` @Value: 32.
---| `ac.CarAudioEventID.SkidIntRR` @Value: 33.
---| `ac.CarAudioEventID.SkidExtLF` @Add 0-based index to this value for Nth wheel.
---| `ac.CarAudioEventID.SkidExtRF` @Value: 41.
---| `ac.CarAudioEventID.SkidExtLR` @Value: 42.
---| `ac.CarAudioEventID.SkidExtRR` @Value: 43.
ac.CarAudioEventID = {
  EngineExt = 0, ---@type ac.CarAudioEventID #Value: 0.
  EngineInt = 1, ---@type ac.CarAudioEventID #Value: 1.
  GearExt = 2, ---@type ac.CarAudioEventID #Value: 2.
  GearInt = 3, ---@type ac.CarAudioEventID #Value: 3.
  Bodywork = 4, ---@type ac.CarAudioEventID #Value: 4.
  Wind = 5, ---@type ac.CarAudioEventID #Value: 5.
  Dirt = 6, ---@type ac.CarAudioEventID #Value: 6.
  Downshift = 7, ---@type ac.CarAudioEventID #Value: 7.
  Horn = 8, ---@type ac.CarAudioEventID #Value: 8.
  GearGrind = 9, ---@type ac.CarAudioEventID #Value: 9.
  BackfireExt = 10, ---@type ac.CarAudioEventID #Value: 10.
  BackfireInt = 11, ---@type ac.CarAudioEventID #Value: 11.
  TractionControlExt = 12, ---@type ac.CarAudioEventID #Value: 12.
  TractionControlInt = 13, ---@type ac.CarAudioEventID #Value: 13.
  Transmission = 14, ---@type ac.CarAudioEventID #Value: 14.
  Limiter = 15, ---@type ac.CarAudioEventID #Value: 15.
  Turbo = 16, ---@type ac.CarAudioEventID #Value: 16.
  WheelLF = 20, ---@type ac.CarAudioEventID #Add 0-based index to this value for Nth wheel.
  WheelRF = 21, ---@type ac.CarAudioEventID #Value: 21.
  WheelLR = 22, ---@type ac.CarAudioEventID #Value: 22.
  WheelRR = 23, ---@type ac.CarAudioEventID #Value: 23.
  SkidIntLF = 30, ---@type ac.CarAudioEventID #Add 0-based index to this value for Nth wheel.
  SkidIntRF = 31, ---@type ac.CarAudioEventID #Value: 31.
  SkidIntLR = 32, ---@type ac.CarAudioEventID #Value: 32.
  SkidIntRR = 33, ---@type ac.CarAudioEventID #Value: 33.
  SkidExtLF = 40, ---@type ac.CarAudioEventID #Add 0-based index to this value for Nth wheel.
  SkidExtRF = 41, ---@type ac.CarAudioEventID #Value: 41.
  SkidExtLR = 42, ---@type ac.CarAudioEventID #Value: 42.
  SkidExtRR = 43, ---@type ac.CarAudioEventID #Value: 43.
}

---Flags specifying when to start calling the `update()` next time. Different conditions be combined with `bit.bor()`.---If your script only needs to, for example, reset a certain thing when car resets, don’t forget to call---`ac.pauseScriptUntil()` again once you’re done.------Other functions (such as `script.reset()` for car physics script), callbacks, timers or event listeners will still be---called. You can cancel out pause by calling `ac.pauseScriptUntil(ac.ScriptResumeCondition.NoPause)` from there.------Currently only available to car scripts, both display/extension and physics (since the major performance issue with Lua---is mostly when there are dozens or hundreds of cars all running even some lightweight Lua scripts, which is admittedly---a rare case).
---@alias ac.ScriptResumeCondition
---| `ac.ScriptResumeCondition.Resume` @Disable pause, keep calling `update()` as usual.
---| `ac.ScriptResumeCondition.None` @Do not resume script ever.
---| `ac.ScriptResumeCondition.Pitlane` @Resume script once car arrives in pitlane.
---| `ac.ScriptResumeCondition.Pits` @Resume script when car gets in pits.
---| `ac.ScriptResumeCondition.Reset` @Pause until car resets.
---| `ac.ScriptResumeCondition.Extra` @Pause until extra switch is used.
---| `ac.ScriptResumeCondition.MeshInteraction` @Pause until there is a change mesh could have been touched.
---| `ac.ScriptResumeCondition.Collision` @Pause until car had a contact with something (added in CSP 0.2.8, won’t work for remote cars for now).
ac.ScriptResumeCondition = {
  Resume = -1, ---@type ac.ScriptResumeCondition #Disable pause, keep calling `update()` as usual.
  None = 0x0, ---@type ac.ScriptResumeCondition #Do not resume script ever.
  Pitlane = 0x1, ---@type ac.ScriptResumeCondition #Resume script once car arrives in pitlane.
  Pits = 0x2, ---@type ac.ScriptResumeCondition #Resume script when car gets in pits.
  Reset = 0x4, ---@type ac.ScriptResumeCondition #Pause until car resets.
  Extra = 0x8, ---@type ac.ScriptResumeCondition #Pause until extra switch is used.
  MeshInteraction = 0x10, ---@type ac.ScriptResumeCondition #Pause until there is a change mesh could have been touched.
  Collision = 0x20, ---@type ac.ScriptResumeCondition #Pause until car had a contact with something (added in CSP 0.2.8, won’t work for remote cars for now).
}

---Key indices, pretty much mirrors all those “VK_…” key tables.
---@alias ui.KeyIndex
---| `ui.KeyIndex.LeftButton` @Value: 1.
---| `ui.KeyIndex.RightButton` @Value: 2.
---| `ui.KeyIndex.MiddleButton` @Not contiguous with LeftButton and RightButton.
---| `ui.KeyIndex.XButton1` @Not contiguous with LeftButton and RightButton.
---| `ui.KeyIndex.XButton2` @Not contiguous with LeftButton and RightButton.
---| `ui.KeyIndex.Tab` @Value: 9.
---| `ui.KeyIndex.Return` @Value: 13.
---| `ui.KeyIndex.Shift` @Value: 16.
---| `ui.KeyIndex.Control` @Value: 17.
---| `ui.KeyIndex.Menu` @Aka Alt button.
---| `ui.KeyIndex.Escape` @Value: 27.
---| `ui.KeyIndex.Accept` @Value: 30.
---| `ui.KeyIndex.Space` @Value: 32.
---| `ui.KeyIndex.End` @Value: 35.
---| `ui.KeyIndex.Home` @Value: 36.
---| `ui.KeyIndex.Left` @Arrow ←.
---| `ui.KeyIndex.Up` @Arrow ↑.
---| `ui.KeyIndex.Right` @Arrow →.
---| `ui.KeyIndex.Down` @Arrow ↓.
---| `ui.KeyIndex.Insert` @Value: 45.
---| `ui.KeyIndex.Delete` @Value: 46.
---| `ui.KeyIndex.LeftWin` @Value: 91.
---| `ui.KeyIndex.RightWin` @Value: 92.
---| `ui.KeyIndex.NumPad0` @Value: 96.
---| `ui.KeyIndex.NumPad1` @Value: 97.
---| `ui.KeyIndex.NumPad2` @Value: 98.
---| `ui.KeyIndex.NumPad3` @Value: 99.
---| `ui.KeyIndex.NumPad4` @Value: 100.
---| `ui.KeyIndex.NumPad5` @Value: 101.
---| `ui.KeyIndex.NumPad6` @Value: 102.
---| `ui.KeyIndex.NumPad7` @Value: 103.
---| `ui.KeyIndex.NumPad8` @Value: 104.
---| `ui.KeyIndex.NumPad9` @Value: 105.
---| `ui.KeyIndex.Multiply` @Value: 106.
---| `ui.KeyIndex.Add` @Value: 107.
---| `ui.KeyIndex.Separator` @Value: 108.
---| `ui.KeyIndex.Subtract` @Value: 109.
---| `ui.KeyIndex.Decimal` @Value: 110.
---| `ui.KeyIndex.Divide` @Value: 111.
---| `ui.KeyIndex.F1` @Value: 112.
---| `ui.KeyIndex.F2` @Value: 113.
---| `ui.KeyIndex.F3` @Value: 114.
---| `ui.KeyIndex.F4` @Value: 115.
---| `ui.KeyIndex.F5` @Value: 116.
---| `ui.KeyIndex.F6` @Value: 117.
---| `ui.KeyIndex.F7` @Value: 118.
---| `ui.KeyIndex.F8` @Value: 119.
---| `ui.KeyIndex.F9` @Value: 120.
---| `ui.KeyIndex.F10` @Value: 121.
---| `ui.KeyIndex.F11` @Value: 122.
---| `ui.KeyIndex.F12` @Value: 123.
---| `ui.KeyIndex.NumLock` @Value: 144.
---| `ui.KeyIndex.Scroll` @Value: 145.
---| `ui.KeyIndex.OemNecEqual` @“.
---| `ui.KeyIndex.LeftShift` @Value: 160.
---| `ui.KeyIndex.RightShift` @Value: 161.
---| `ui.KeyIndex.LeftControl` @Value: 162.
---| `ui.KeyIndex.RightControl` @Value: 163.
---| `ui.KeyIndex.LeftMenu` @Aka left Alt button.
---| `ui.KeyIndex.RightMenu` @Aka right Alt button.
---| `ui.KeyIndex.Oem1` @“;:” for US.
---| `ui.KeyIndex.SquareOpenBracket` @Value: 219.
---| `ui.KeyIndex.SquareCloseBracket` @Value: 221.
---| `ui.KeyIndex.D0` @Digit 0.
---| `ui.KeyIndex.D1` @Digit 1.
---| `ui.KeyIndex.D2` @Digit 2.
---| `ui.KeyIndex.D3` @Digit 3.
---| `ui.KeyIndex.D4` @Digit 4.
---| `ui.KeyIndex.D5` @Digit 5.
---| `ui.KeyIndex.D6` @Digit 6.
---| `ui.KeyIndex.D7` @Digit 7.
---| `ui.KeyIndex.D8` @Digit 8.
---| `ui.KeyIndex.D9` @Digit 9.
---| `ui.KeyIndex.A` @Letter A.
---| `ui.KeyIndex.B` @Letter B.
---| `ui.KeyIndex.C` @Letter C.
---| `ui.KeyIndex.D` @Letter D.
---| `ui.KeyIndex.E` @Letter E.
---| `ui.KeyIndex.F` @Letter F.
---| `ui.KeyIndex.G` @Letter G.
---| `ui.KeyIndex.H` @Letter H.
---| `ui.KeyIndex.I` @Letter I.
---| `ui.KeyIndex.J` @Letter J.
---| `ui.KeyIndex.K` @Letter K.
---| `ui.KeyIndex.L` @Letter L.
---| `ui.KeyIndex.M` @Letter M.
---| `ui.KeyIndex.N` @Letter N.
---| `ui.KeyIndex.O` @Letter O.
---| `ui.KeyIndex.P` @Letter P.
---| `ui.KeyIndex.Q` @Letter Q.
---| `ui.KeyIndex.R` @Letter R.
---| `ui.KeyIndex.S` @Letter S.
---| `ui.KeyIndex.T` @Letter T.
---| `ui.KeyIndex.U` @Letter U.
---| `ui.KeyIndex.V` @Letter V.
---| `ui.KeyIndex.W` @Letter W.
---| `ui.KeyIndex.X` @Letter X.
---| `ui.KeyIndex.Y` @Letter Y.
---| `ui.KeyIndex.Z` @Letter Z.
ui.KeyIndex = {
  LeftButton = 1, ---@type ui.KeyIndex #Value: 1.
  RightButton = 2, ---@type ui.KeyIndex #Value: 2.
  Cancel = 3, ---@type ui.KeyIndex #Value: 3.
  MiddleButton = 4, ---@type ui.KeyIndex #Not contiguous with LeftButton and RightButton.
  XButton1 = 5, ---@type ui.KeyIndex #Not contiguous with LeftButton and RightButton.
  XButton2 = 6, ---@type ui.KeyIndex #Not contiguous with LeftButton and RightButton.
  Back = 8, ---@type ui.KeyIndex #Value: 8.
  Tab = 9, ---@type ui.KeyIndex #Value: 9.
  Clear = 12, ---@type ui.KeyIndex #Value: 12.
  Return = 13, ---@type ui.KeyIndex #Value: 13.
  Shift = 16, ---@type ui.KeyIndex #Value: 16.
  Control = 17, ---@type ui.KeyIndex #Value: 17.
  Menu = 18, ---@type ui.KeyIndex #Aka Alt button.
  Pause = 19, ---@type ui.KeyIndex #Value: 19.
  Capital = 20, ---@type ui.KeyIndex #Value: 20.
  Kana = 21, ---@type ui.KeyIndex #Value: 21.
  Hangeul = 21, ---@type ui.KeyIndex #Old name - should be here for compatibility.
  Hangul = 21, ---@type ui.KeyIndex #Value: 21.
  Junja = 23, ---@type ui.KeyIndex #Value: 23.
  Final = 24, ---@type ui.KeyIndex #Value: 24.
  Hanja = 25, ---@type ui.KeyIndex #Value: 25.
  Kanji = 25, ---@type ui.KeyIndex #Value: 25.
  Escape = 27, ---@type ui.KeyIndex #Value: 27.
  Convert = 28, ---@type ui.KeyIndex #Value: 28.
  NonConvert = 29, ---@type ui.KeyIndex #Value: 29.
  Accept = 30, ---@type ui.KeyIndex #Value: 30.
  ModeChange = 31, ---@type ui.KeyIndex #Value: 31.
  Space = 32, ---@type ui.KeyIndex #Value: 32.
  Prior = 33, ---@type ui.KeyIndex #Value: 33.
  Next = 34, ---@type ui.KeyIndex #Value: 34.
  End = 35, ---@type ui.KeyIndex #Value: 35.
  Home = 36, ---@type ui.KeyIndex #Value: 36.
  Left = 37, ---@type ui.KeyIndex #Arrow ←.
  Up = 38, ---@type ui.KeyIndex #Arrow ↑.
  Right = 39, ---@type ui.KeyIndex #Arrow →.
  Down = 40, ---@type ui.KeyIndex #Arrow ↓.
  Select = 41, ---@type ui.KeyIndex #Value: 41.
  Print = 42, ---@type ui.KeyIndex #Value: 42.
  Execute = 43, ---@type ui.KeyIndex #Value: 43.
  Snapshot = 44, ---@type ui.KeyIndex #Value: 44.
  Insert = 45, ---@type ui.KeyIndex #Value: 45.
  Delete = 46, ---@type ui.KeyIndex #Value: 46.
  Help = 47, ---@type ui.KeyIndex #Value: 47.
  LeftWin = 91, ---@type ui.KeyIndex #Value: 91.
  RightWin = 92, ---@type ui.KeyIndex #Value: 92.
  Apps = 93, ---@type ui.KeyIndex #Value: 93.
  Sleep = 95, ---@type ui.KeyIndex #Value: 95.
  NumPad0 = 96, ---@type ui.KeyIndex #Value: 96.
  NumPad1 = 97, ---@type ui.KeyIndex #Value: 97.
  NumPad2 = 98, ---@type ui.KeyIndex #Value: 98.
  NumPad3 = 99, ---@type ui.KeyIndex #Value: 99.
  NumPad4 = 100, ---@type ui.KeyIndex #Value: 100.
  NumPad5 = 101, ---@type ui.KeyIndex #Value: 101.
  NumPad6 = 102, ---@type ui.KeyIndex #Value: 102.
  NumPad7 = 103, ---@type ui.KeyIndex #Value: 103.
  NumPad8 = 104, ---@type ui.KeyIndex #Value: 104.
  NumPad9 = 105, ---@type ui.KeyIndex #Value: 105.
  Multiply = 106, ---@type ui.KeyIndex #Value: 106.
  Add = 107, ---@type ui.KeyIndex #Value: 107.
  Separator = 108, ---@type ui.KeyIndex #Value: 108.
  Subtract = 109, ---@type ui.KeyIndex #Value: 109.
  Decimal = 110, ---@type ui.KeyIndex #Value: 110.
  Divide = 111, ---@type ui.KeyIndex #Value: 111.
  F1 = 112, ---@type ui.KeyIndex #Value: 112.
  F2 = 113, ---@type ui.KeyIndex #Value: 113.
  F3 = 114, ---@type ui.KeyIndex #Value: 114.
  F4 = 115, ---@type ui.KeyIndex #Value: 115.
  F5 = 116, ---@type ui.KeyIndex #Value: 116.
  F6 = 117, ---@type ui.KeyIndex #Value: 117.
  F7 = 118, ---@type ui.KeyIndex #Value: 118.
  F8 = 119, ---@type ui.KeyIndex #Value: 119.
  F9 = 120, ---@type ui.KeyIndex #Value: 120.
  F10 = 121, ---@type ui.KeyIndex #Value: 121.
  F11 = 122, ---@type ui.KeyIndex #Value: 122.
  F12 = 123, ---@type ui.KeyIndex #Value: 123.
  F13 = 124, ---@type ui.KeyIndex #Value: 124.
  F14 = 125, ---@type ui.KeyIndex #Value: 125.
  F15 = 126, ---@type ui.KeyIndex #Value: 126.
  F16 = 127, ---@type ui.KeyIndex #Value: 127.
  F17 = 128, ---@type ui.KeyIndex #Value: 128.
  F18 = 129, ---@type ui.KeyIndex #Value: 129.
  F19 = 130, ---@type ui.KeyIndex #Value: 130.
  F20 = 131, ---@type ui.KeyIndex #Value: 131.
  F21 = 132, ---@type ui.KeyIndex #Value: 132.
  F22 = 133, ---@type ui.KeyIndex #Value: 133.
  F23 = 134, ---@type ui.KeyIndex #Value: 134.
  F24 = 135, ---@type ui.KeyIndex #Value: 135.
  NavigationView = 136, ---@type ui.KeyIndex #Reserved.
  NavigationMenu = 137, ---@type ui.KeyIndex #Reserved.
  NavigationUp = 138, ---@type ui.KeyIndex #Reserved.
  NavigationDown = 139, ---@type ui.KeyIndex #Reserved.
  NavigationLeft = 140, ---@type ui.KeyIndex #Reserved.
  NavigationRight = 141, ---@type ui.KeyIndex #Reserved.
  NavigationAccept = 142, ---@type ui.KeyIndex #Reserved.
  NavigationCancel = 143, ---@type ui.KeyIndex #Reserved.
  NumLock = 144, ---@type ui.KeyIndex #Value: 144.
  Scroll = 145, ---@type ui.KeyIndex #Value: 145.
  OemNecEqual = 146, ---@type ui.KeyIndex #“.
  OemFjJisho = 146, ---@type ui.KeyIndex #“Dictionary” key.
  OemFjMasshou = 147, ---@type ui.KeyIndex #“Unregister word” key.
  OemFjTouroku = 148, ---@type ui.KeyIndex #“Register word” key.
  OemFjLoya = 149, ---@type ui.KeyIndex #“Left OYAYUBI” key.
  OemFjRoya = 150, ---@type ui.KeyIndex #“Right OYAYUBI” key.
  LeftShift = 160, ---@type ui.KeyIndex #Value: 160.
  RightShift = 161, ---@type ui.KeyIndex #Value: 161.
  LeftControl = 162, ---@type ui.KeyIndex #Value: 162.
  RightControl = 163, ---@type ui.KeyIndex #Value: 163.
  LeftMenu = 164, ---@type ui.KeyIndex #Aka left Alt button.
  RightMenu = 165, ---@type ui.KeyIndex #Aka right Alt button.
  BrowserBack = 166, ---@type ui.KeyIndex #Value: 166.
  BrowserForward = 167, ---@type ui.KeyIndex #Value: 167.
  BrowserRefresh = 168, ---@type ui.KeyIndex #Value: 168.
  BrowserStop = 169, ---@type ui.KeyIndex #Value: 169.
  BrowserSearch = 170, ---@type ui.KeyIndex #Value: 170.
  BrowserFavorites = 171, ---@type ui.KeyIndex #Value: 171.
  BrowserHome = 172, ---@type ui.KeyIndex #Value: 172.
  VolumeMute = 173, ---@type ui.KeyIndex #Value: 173.
  VolumeDown = 174, ---@type ui.KeyIndex #Value: 174.
  VolumeUp = 175, ---@type ui.KeyIndex #Value: 175.
  MediaNextTrack = 176, ---@type ui.KeyIndex #Value: 176.
  MediaPrevTrack = 177, ---@type ui.KeyIndex #Value: 177.
  MediaStop = 178, ---@type ui.KeyIndex #Value: 178.
  MediaPlayPause = 179, ---@type ui.KeyIndex #Value: 179.
  LaunchMail = 180, ---@type ui.KeyIndex #Value: 180.
  LaunchMediaSelect = 181, ---@type ui.KeyIndex #Value: 181.
  LaunchApp1 = 182, ---@type ui.KeyIndex #Value: 182.
  LaunchApp2 = 183, ---@type ui.KeyIndex #Value: 183.
  Oem1 = 186, ---@type ui.KeyIndex #“;:” for US.
  OemPlus = 187, ---@type ui.KeyIndex #“+” any country.
  OemComma = 188, ---@type ui.KeyIndex #“,” any country.
  OemMinus = 189, ---@type ui.KeyIndex #“-” any country.
  OemPeriod = 190, ---@type ui.KeyIndex #“.” any country.
  Oem2 = 191, ---@type ui.KeyIndex #“/?” for US.
  Oem3 = 192, ---@type ui.KeyIndex #“`~” for US.
  GamepadA = 195, ---@type ui.KeyIndex #Reserved.
  GamepadB = 196, ---@type ui.KeyIndex #Reserved.
  GamepadX = 197, ---@type ui.KeyIndex #Reserved.
  GamepadY = 198, ---@type ui.KeyIndex #Reserved.
  GamepadRightShoulder = 199, ---@type ui.KeyIndex #Reserved.
  GamepadLeftShoulder = 200, ---@type ui.KeyIndex #Reserved.
  GamepadLeftTrigger = 201, ---@type ui.KeyIndex #Reserved.
  GamepadRightTrigger = 202, ---@type ui.KeyIndex #Reserved.
  GamepadDpadUp = 203, ---@type ui.KeyIndex #Reserved.
  GamepadDpadDown = 204, ---@type ui.KeyIndex #Reserved.
  GamepadDpadLeft = 205, ---@type ui.KeyIndex #Reserved.
  GamepadDpadRight = 206, ---@type ui.KeyIndex #Reserved.
  GamepadMenu = 207, ---@type ui.KeyIndex #Reserved.
  GamepadView = 208, ---@type ui.KeyIndex #Reserved.
  GamepadLeftThumbstickButton = 209, ---@type ui.KeyIndex #Reserved.
  GamepadRightThumbstickButton = 210, ---@type ui.KeyIndex #Reserved.
  GamepadLeftThumbstickUp = 211, ---@type ui.KeyIndex #Reserved.
  GamepadLeftThumbstickDown = 212, ---@type ui.KeyIndex #Reserved.
  GamepadLeftThumbstickRight = 213, ---@type ui.KeyIndex #Reserved.
  GamepadLeftThumbstickLeft = 214, ---@type ui.KeyIndex #Reserved.
  GamepadRightThumbstickUp = 215, ---@type ui.KeyIndex #Reserved.
  GamepadRightThumbstickDown = 216, ---@type ui.KeyIndex #Reserved.
  GamepadRightThumbstickRight = 217, ---@type ui.KeyIndex #Reserved.
  GamepadRightThumbstickLeft = 218, ---@type ui.KeyIndex #Reserved.
  SquareOpenBracket = 219, ---@type ui.KeyIndex #Value: 219.
  SquareCloseBracket = 221, ---@type ui.KeyIndex #Value: 221.
  D0 = 48, ---@type ui.KeyIndex #Digit 0.
  D1 = 49, ---@type ui.KeyIndex #Digit 1.
  D2 = 50, ---@type ui.KeyIndex #Digit 2.
  D3 = 51, ---@type ui.KeyIndex #Digit 3.
  D4 = 52, ---@type ui.KeyIndex #Digit 4.
  D5 = 53, ---@type ui.KeyIndex #Digit 5.
  D6 = 54, ---@type ui.KeyIndex #Digit 6.
  D7 = 55, ---@type ui.KeyIndex #Digit 7.
  D8 = 56, ---@type ui.KeyIndex #Digit 8.
  D9 = 57, ---@type ui.KeyIndex #Digit 9.
  A = 65, ---@type ui.KeyIndex #Letter A.
  B = 66, ---@type ui.KeyIndex #Letter B.
  C = 67, ---@type ui.KeyIndex #Letter C.
  D = 68, ---@type ui.KeyIndex #Letter D.
  E = 69, ---@type ui.KeyIndex #Letter E.
  F = 70, ---@type ui.KeyIndex #Letter F.
  G = 71, ---@type ui.KeyIndex #Letter G.
  H = 72, ---@type ui.KeyIndex #Letter H.
  I = 73, ---@type ui.KeyIndex #Letter I.
  J = 74, ---@type ui.KeyIndex #Letter J.
  K = 75, ---@type ui.KeyIndex #Letter K.
  L = 76, ---@type ui.KeyIndex #Letter L.
  M = 77, ---@type ui.KeyIndex #Letter M.
  N = 78, ---@type ui.KeyIndex #Letter N.
  O = 79, ---@type ui.KeyIndex #Letter O.
  P = 80, ---@type ui.KeyIndex #Letter P.
  Q = 81, ---@type ui.KeyIndex #Letter Q.
  R = 82, ---@type ui.KeyIndex #Letter R.
  S = 83, ---@type ui.KeyIndex #Letter S.
  T = 84, ---@type ui.KeyIndex #Letter T.
  U = 85, ---@type ui.KeyIndex #Letter U.
  V = 86, ---@type ui.KeyIndex #Letter V.
  W = 87, ---@type ui.KeyIndex #Letter W.
  X = 88, ---@type ui.KeyIndex #Letter X.
  Y = 89, ---@type ui.KeyIndex #Letter Y.
  Z = 90, ---@type ui.KeyIndex #Letter Z.
}

---@alias ac.VAODebugMode
---| `ac.VAODebugMode.Active` @Value: 1.
---| `ac.VAODebugMode.Inactive` @Value: 3.
---| `ac.VAODebugMode.VAOOnly` @Value: 4.
---| `ac.VAODebugMode.ShowNormals` @Value: 5.
ac.VAODebugMode = {
  Active = 1, ---@type ac.VAODebugMode #Value: 1.
  Inactive = 3, ---@type ac.VAODebugMode #Value: 3.
  VAOOnly = 4, ---@type ac.VAODebugMode #Value: 4.
  ShowNormals = 5, ---@type ac.VAODebugMode #Value: 5.
}

--[[ common/common.lua ]]

---Path to a folder with currently running script.
---@type string
__dirname = nil

---A filename, either absolute or relative. If relative, will be resolved against AC root folder. Use `os.setCurrentFolder()` to change current folder.
---@alias path string

---Could be either a string, a number or a boolean value (will be converted into string).
---String can store any binary data including zero bytes. Could also be an FFI struct and it will
---be processed as its binary form.
---@alias binary string|number|boolean

---Could be either a string, a number, a boolean value or a table (without circular references or any non-serializable
---items). Will be serialized here and deserialized in a different script. String can store any binary data including zero bytes.
---@alias serializable string|number|boolean|table|nil

---Main CSP namespace.
ac = {}

---FFI-accelerated list, acts like a regular list (consequent items, size and capacity, automatically growing, etc.)
---Doesn’t store nil values to act more like a Lua table.
---
---Few notes:
---• Use `:get()` and `:set()` to access elements instead of square brakets;
---• Indices are 1-based;
---• For fastest access to individual elements use `.raw` field: it’s a raw pointer, so use 0-based indices there and
---make sure not to access things outside of list size.
---
---For slightly better performance it might be benefitial to preallocate memory with `list:reserve(expectedSizeOrABitMore)`.
---@class ac.GenericList
---@field raw any @Raw pointer for fastest unchecked access with 0-based indices. Use very carefully!
local _ac_genericList = {}

---Return an element at given index.
---@param index integer @1-based index.
---@return any
function _ac_genericList:get(index) end

---Sets an element at given index.
---@param index integer @1-based index.
---@param value any 
function _ac_genericList:set(index, value) end

---Number of items in the list.
---@return integer
function _ac_genericList:size() end

---Size of list in bytes (not capacity, for that use `list:capacityBytes()`).
---@return integer
function _ac_genericList:sizeBytes() end

---Checks if list is empty.
---@return boolean
function _ac_genericList:isEmpty() end

---Capacity of the list.
---@return integer
function _ac_genericList:capacity() end

---Size of list in bytes (capacity).
---@return integer
function _ac_genericList:capacityBytes() end

---Makes sure list can fit `newSize` of elements without reallocating memory.
---@param newSize integer
---@return integer
function _ac_genericList:reserve(newSize) end

---If capacity is greater than current size, reallocates a smaller bit of memory and moves data there.
function _ac_genericList:shrinkToFit() end

---Removes all elements.
function _ac_genericList:clear() end

---Creates a new list with the same contents as the existing one.
---@return ac.GenericList
function _ac_genericList:clone() end
---Custom FFI namespace. Be very careful around here.
---@class ffilibex
---@field C nil @Avoid using functions directly.
ffi = {}

---@param def     string
---@param params? any
function ffi.cdef(def, params, ...) end

---@param ct  ffi.ct*
---@param obj any
---@return boolean
---@nodiscard
function ffi.istype(ct, obj) end

---@param ptr  any
---@param len? integer
---@return string
function ffi.string(ptr, len) end

---@param ct      ffi.ct*
---@param params? any
---@return ffi.ctype*
---@nodiscard
function ffi.typeof(ct, params, ...) end

---@param ct   ffi.ct*
---@param init any
---@return ffi.cdata*
---@nodiscard
function ffi.cast(ct, init) end

---@param ct        ffi.ct*
---@param metatable table
---@return ffi.ctype*
function ffi.metatype(ct, metatable) end

---@param cdata     ffi.cdata*
---@param finalizer? function
---@return ffi.cdata*
function ffi.gc(cdata, finalizer) end

---@param destination any
---@param data any|string
---@param size integer?
function ffi.copy(destination, data, size) end

---Namespace only available for background workers. Use `ac.startBackgroundWorker()` to start a background worker.
worker = {}

---Input data passed to a worker during launch.
---@type nil|boolean|number|string|table
worker.input = nil

---Input data passed to a worker during launch.
---@type nil|boolean|number|string|table
worker.input = nil

---Available only in background worker scripts. Sleep function pauses execution for a certain time. 
---Before unpaused, any callbacks (such as `setTimeout()`, `setInterval()` and
---other custom enqueued callbacks) will be called. This is the only way for those callbacks to fire in a background worker. Note:
---if parent thread is closed, `worker.sleep()` won’t return back and instead script will be unloaded, this way worker can be reloaded
---as well.
---
---If your worker does a lot of async operations, consider using `worker.wait()` instead, setting resulting value with `worker.result`.
---Or maybe not even use anything at all: for basic (non-repeating) callbacks, timers and intervals script will continue running until
---all the postponed actions are complete (updating once every 100 ms).
---@param time number @Time in seconds to pause worker by.
function worker.sleep(time) end

---Wait for `worker.result` value to be set. Stops the worker once `worker.result` value has been provided (or any `error()` has been raised).
---Works the best if your worker uses a lot of async operations. 
---@param time number? @Time in seconds for timeout. Default value: 60. Feel free to pass something like `math.huge` if you don’t need timeout for some reason.
function worker.wait(time) end

---Resulting value used when using `worker.wait()`.
---@type nil|boolean|number|string|table
worker.result = nil

--[[ common/class.lua ]]

---@alias ClassDefinition {__name: string}
---@alias ClassMixin {included: fun(classDefinition: ClassDefinition)}

---A base class. Note: all classes are inheriting from this one even if they’re not using
---`ClassBase` as a parent class explicitly.
ClassBase = {}

---Checks if object is an instance of a class created by `class()` function.
---@param obj any|nil @Any table, vector, nil, anything.
---@return boolean @True if type of `obj` is `ClassBase` or any class inheriting from it.
function ClassBase.isInstanceOf(obj) end

---Checks if ClassBase is a subsclass of a class created by `class()` function. It wouldn’t be, function is here just for
---keeping things even.
---@param classDefinition ClassDefinition @Class created by `class()` function.
---@return boolean @Always false.
function ClassBase:isSubclassOf(classDefinition) end

---Creates a new class. Pretty much the same as calling `class()` (all classes are inheriting from `ClassBase` anyway).
---@return ClassDefinition @New class definition
function ClassBase:subclass(...) end

---Adds a mixin to all subsequently created classes. Use it early in case you want to add a method or some data to all of your objects.
---If `mixin` has a property `included`, it would be called each time new class is created with a reference to the newly created class.
---@param mixin ClassMixin
function ClassBase:include(mixin) end

---Define this function and it would be called each time a new class without a parent (or `ClassBase` for parent) is created.
---@param classDefinition ClassDefinition
function ClassBase:subclassed(classDefinition) end

---A base class for objects with pooling. Note: all classes created with `class.Pool` flag are inheriting from this one even if they’re not using
---`ClassPool` as a parent class explicitly.
ClassPool = {}

---Checks if object is an instance of a class with pooling active.
---@param obj any|nil @Any table, vector, nil, anything.
---@return boolean @True if type of `obj` is `ClassPool` or any class inheriting from it.
function ClassPool.isInstanceOf(obj) end

---Checks if ClassPool is a subsclass of a class created by `class()` function. It wouldn’t be unless you’re passing `ClassBase`, function is here just for
---keeping things even.
---@param classDefinition ClassBase @Class created by `class()` function.
---@return boolean @True if you’ve passed ClassBase here.
function ClassPool:isSubclassOf(classDefinition) end

---Creates a new class with pooling. Pretty much the same as calling `class(class.Pool, ...)` (all classes with `class.Pool` are 
---inheriting from `ClassPool` anyway).
---@return ClassDefinition @New class definition
function ClassPool:subclass(...) end

---Adds a mixin to subsequently created classes with pooling. Use it early in case you want to add a method or some data to all of your objects that use pooling.
---If `mixin` has a property `included`, it would be called each time new class with pooling is created with a reference to the newly created class.
---@param mixin ClassMixin
function ClassPool:include(mixin) end

---Define this function and it would be called each time a new pooling class without a parent (or `ClassPool` for parent) is created.
---@param classDefinition ClassDefinition
function ClassPool:subclassed(classDefinition) end

---A base class. Note: all classes are inheriting from this one even if they’re not using
---`ClassBase` as a parent class explicitly. You might still want to put it in EmmyDoc comment to get hints for functions like `YourClass.isInstanceOf()`.
---@class ClassBase
local _classBase = {}

---Checks if object is an instance of this class. Can be used either as `obj:isInstanceOf(YourClass)` or, as a safer alternative,
---`YourClass.isInstanceOf(obj)` — this one would work even if `obj` is nil, a number, a vector, anything like that. And in all of those
---cases, of course, it would return `false`.
---@param classDefinition ClassDefinition @Used with `obj:isInstanceOf(YourClass)` variant.
---@return boolean @True if argument is an instance of this class.
---@overload fun(): boolean
function _classBase:isInstanceOf(classDefinition) end

---Class method. Checks if class itself is a child class of a different class (or a child of a child, etc). 
---Can be used as `YourClass:isInstanceOf(YourOtherClass)`.
---@param classDefinition ClassDefinition @Class created by `class()` function.
---@return boolean @True if this class is a child of another class (or a child of a child, etc).
function _classBase:isSubclassOf(classDefinition) end

---Class method. Includes mixin, adding new methods to a preexising class. If mixin has a property `included`, it will be called
---with an argument referencing a class mixin is being added to. Can be used as `YourClass:include({ newMethod = function(self, arg) end })`.
---@param mixin ClassMixin @Any mixin.
function _classBase:include(mixin) end

---Class method. Creates a new child class.
---@return ClassDefinition @New class definition
function _classBase:subclass(...) end

---Class method. Called when a new child class is created using this class as a parent one. Redefine this function for
---your class if you need some advanced processing, like adding new methods to a child class.
---@param classDefinition ClassDefinition @New class definition
function _classBase:subclassed(classDefinition) end

---A base class for objects with pooling. Doesn’t add anything, but you can add it as a parent class
---so that `recycled()` would be documented.
---@class ClassPool : ClassBase
local _classPool = {}

---Called when object is about to get recycled.
---@return boolean @Return false if this object should not be recycled and instead destroyed as usual.
function _classPool:recycled() end

---Create a new class. Example:
---
---```
---local MyClass = class('MyClass')        -- class declaration
---
---function MyClass:initialize(arg1, arg2) -- constructor
---  self.myField = arg1 + arg2            -- field
---end
---
---function MyClass:doMyThing()            -- method
---  print(self.myField)
---end
---
---local instance = MyClass(1, 2)          -- creating instance of a class
---instance:doMyThing()                    -- calling a method
---```
---
---Whole thing is very similar to [middleclass](https://github.com/kikito/middleclass), but it’s a different
---implementation that should be somewhat faster. Main differences:
---
---1. Class name is stored in `YourClass.__name` instead of `YourClass.name`.
---
---2. There is no `.static` subtable, all static fields and methods are instead stored in main class
---   table and thus are available as instance fields and methods as well (that’s why `YourClass.name` was
---   renamed to `YourClass.__name`, to avoid possible confusion with a common field name). It’s a bit
---   messier, especially with class methods such as `:subclass()`, but it has some advantages as well:
---   objects creation is faster, and it’s more EmmyLua-friendly (both of which is what it’s all about).
---
---3. Overloaded `__tostring`, `__len` and `__call` are inherited, but not other operators.
---
---4. Method `YourClass.allocate()` works differently here and is used to create a simple table which will be
---   passed to `setmetatable()`. This can help with performance if objects are created often.
---
---Everything else should work the same, including inheritance and mixins. As for performance, some simple
---tests show up to 30% faster objects creation and 40% less memory used for objects with two fields when
---using `YourClass.allocate()` method instead of `YourClass:initialize()` (that alone gives about 15% increase in speed
---when creating an object with two fields):
---
---```
---function YourClass.allocate(arg1, arg2)  -- notice . instead of :
---  return { myField = arg1 + arg2 }     -- also notice, methods are not available at this stage
---end
---```
---
---Other differences (new features rather than something breaking compatibility) and important notes:
---
---1. Function `class()` takes string for class name, another class to act like a parent,
---   allocate and initialize functions and flags. Everything is optional and can go in any order (with one caveat:
---   allocate function should go before initialize function unless you’re using `class.Pool`). Generally there is no
---   benefit in passing allocate and initialize functions here though.
---
---2. With flag `class.NoInitialize` constructor would not look for `YourClass:initialize()` method to call at all,
---   instead using only `YourClass.allocate()`. Might speed things up a bit further.
---
---3. If you’re creating new instances really often, there is a `class.Pool` flag. It would disable the use of
---   `YourClass.allocate()`, but instead allow to reuse unused objects by using `class.recycle(object)`. Recycled objects
---   would end up in a pool of objects to be reused next time an instance would need to be created. Of course, it
---   introduces a whole new type of errors (imagine storing a reference to a recycled item somewhere not knowing it was
---   recycled and now represents something else entirely), so please be careful.
---
---   Note 1: Method `class.recycle()` can be used with nils or non-recycle, no need to have extra checks before calling it.
--- 
---   Note 2: Instances of child classes won’t end up in parent class pool. For such arrangements, consider adding pooling
---           flag to all of child classes where appropriate.
---
---4. Before recycling, method `YourClass:recycled()` will be called. Good time to recycle any inner elements. Also,
---   return `false` from it and object would not be recycled at all.
---
---5. To check type, `YourClass.isInstanceOf(item)` can also be used. Notice that it’s a static method, no “:” here.
---
---All classes are considered children classes of `ClassBase`, that one is mostly for EmmyLua to pick up methods like 
---`YourClass.isInstanceOf(object)`. If you’re creating your own class and want to use such methods, just add `: ClassBase`
---to its EmmyLua annotation. And objects with pooling are children of `ClassPool` which is a child of `ClassBase`. Note: 
---to speed things up, those classes aren’t fully real, but you can access them and their methods and even call things like
---`ClassBase:include()`. Please read documentation for those functions before using them though, just to check.
---@param name string @Class name.
---@param parentClass ClassBase @Parent class.
---@param flags nil|integer|`class.NoInitialize`|`class.Pool`|`class.Minimal` @Flags.
---@overload fun(name: string, flags: nil|integer|`class.NoInitialize`|`class.Pool`|`class.Minimal`)  @Regular parent-less class with some flags
---@overload fun(name: string, allocateFn: function|`function() return {} end, class.NoInitialize`)    @Inline allocate function for slightly faster creation
---@overload fun(name: string, initializeFn: `function (self) end, class.Pool`)               @With pooling for best memory reuse
---@overload fun(allocateFn: `function() return {} end, class.NoInitialize + class.Minimal`)  @Most minimal version
---@return ClassDefinition @New class definition
function class(name, parentClass, flags) end

class = {}

---Skip initialization function completely. Might slightly speed up object creation.
class.NoInitialize = 1

---Reuse recycled objects instead of creating new ones. Disables `.allocate()` and switches to `:initialize()`,
---but performance gain from not having to allocate new tables is worth it. Don’t forget to recycle unused elements
---with `class.recycle(item)`.
class.Pool = 2

---Minimal version of a class, skips creation of all static methods and default to-string operators.
---
---To use with either pooling or no-initialize setup, pass two flags separated by a comma, or just sum them together
---(would work only if values are powers of two and you’re not summing together the same flag twice). Or, use
---`bit.bor(flag1, flag2)`, courtesy of LuaJIT and its BitOp extension.
class.Minimal = 4

---Recycle an item to its pool, to speed up creation and reduce work for GC. Requires class to be created with
---`class.Pool` flag.
---
---This method has protection from double recycling, recycling nils or non-recycleable items, so don’t worry about it.
---@param item ClassPool|nil
function class.recycle(item) end

---A trick to get `class()` to work with EmmyLua annotations nicely. Call `class.emmy(YourClass, YourClass.initialize)`
---or `class.emmy(YourClass, YourClass.allocate)` (whatever you’re using) and it would give you a constructor function.
---Then, use it for local reference or as a return value from module. For best results add annotations to function you’re
---passing here, such as return value or argument types.
---
---In reality is simply returns the class back and ignores second argument, but because of this definition EmmyLua thinks
---it got the constructor.
---@generic T1
---@generic T2
---@param classFn T1
---@param constructorFn T2
---@return T1|T2
function class.emmy(classFn, constructorFn) return constructorFn end

---@return string?
function ac.getPatchVersion() end

---Increments with every CSP build.
---@return integer
function ac.getPatchVersionCode() end

---Load and parse INIpp configuration file (supports includes and such), return it as JSON. Deprecated, use `ac.INIConfig.load()` instead.
---@deprecated
---@param iniFilename string
---@param includeDirs string|nil @Newline separated path to folders to search for included files in. Default value: `nil`.
---@return string?
function ac.loadINIppFile(iniFilename, includeDirs) end

---Returns name of MGUK delivery program. If there is no such car or program, returns `nil`.
---@param carIndex integer @0-based car index.
---@param programIndex integer? @0-based program index (if negative, name of currently selected program will be returned. Default value: -1.
---@return string?
function ac.getMGUKDeliveryName(carIndex, programIndex) end

---Get short name of a tyre set, either currently selected or with certain index. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@param compoundIndex integer? @0-based tyre set index, if set to -1, short name of currently selected tyre set will be returned. Default value: -1.
---@return string?
function ac.getTyresName(carIndex, compoundIndex) end

---Get 0-based index of a tyres set with a given short name, or -1 if there is no such tyres set (or such car).
---@param carIndex integer @0-based car index.
---@param tyresShortName string @Short tyres set name (usually a couple of symbols long).
---@return integer
function ac.getTyresIndex(carIndex, tyresShortName) end

---Returns long name of a tyre set with certain index. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@param compoundIndex integer? @0-based tyre set index, if set to -1, short name of currently selected tyre set will be returned. Default value: -1.
---@param includePostfix boolean? @Set to `false` to skip short name postfix. Default value: `true`.
---@return string?
function ac.getTyresLongName(carIndex, compoundIndex, includePostfix) end

---Get car ID (name of its folder) of a certain car. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@return string?
function ac.getCarID(carIndex) end

---Get car name (from its JSON file) of a certain car. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@param includeYearPostfix boolean? @Set to `true` to add a year postfix. Default value: `false`.
---@return string?
function ac.getCarName(carIndex, includeYearPostfix) end

---Get selected skin ID of (name of skin’s folder) of a certain car. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@return string?
function ac.getCarSkinID(carIndex) end

---Get name of a manufacturer of a certain car. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@return string?
function ac.getCarBrand(carIndex) end

---Get name of manufactoring country of a certain car. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@return string?
function ac.getCarCountry(carIndex) end

---Refers to AI spline.
---@return boolean
function ac.hasTrackSpline() end

---Finds nearest point on track AI spline (fast_lane) and returns its normalized position. If there is no track spline, returns -1.
---@param v vec3
---@return number
function ac.worldCoordinateToTrackProgress(v) end

---Returns distance from AI spline to left and right track boundaries.
---@param v number @Lap progress from 0 to 1.
---@return vec2 @X for left side, Y for right side.
function ac.getTrackAISplineSides(v) end

---@param v number
---@param linear boolean? @Use linear interpolation. Default value: `false`.
---@return vec3
function ac.trackProgressToWorldCoordinate(v, linear) end

---@param v number
---@param r vec3
---@param linear boolean? @Use linear interpolation. Default value: `false`.
function ac.trackProgressToWorldCoordinateTo(v, r, linear) end

---Converts world coordinates into track coordinates. Track coordinates:
--- - X for normalized position (0 — right in the middle, -1 — left side of the track, 1 — right size);
--- - Y for height above track in meters;
--- - Z for track progress.
---@param v vec3
---@return vec3
function ac.worldCoordinateToTrack(v) end

---Converts track coordinates into world coordinates. Track coordinates:
--- - X for normalized position (0 — right in the middle, -1 — left side of the track, 1 — right size);
--- - Y for height above track in meters;
--- - Z for track progress.
---@param v vec3
---@return vec3
function ac.trackCoordinateToWorld(v) end

---Returns track world coordinates in degrees.
---@param worldPos vec3|nil @Added in 0.2.8. If set, function returns coordinates of this point instead. Default value: `nil`.
---@return vec2 @X for latitude, Y for longitude.
function ac.getTrackCoordinatesDeg(worldPos) end

---Returns timezone offset for the track in seconds.
---@param time number? @If set, returns timezone for given timestamp (DST might differ). Default value: `nil`.
---@return vec2 @X for base offset, Y for summer time offset.
function ac.getTrackTimezoneBaseDst(time) end

---Name of a sector.
---@param trackProgress number @Track position from 0 to 1.
---@return string
function ac.getTrackSectorName(trackProgress) end

---Returns directory of the script.
---@return string
function ac.dirname() end

---If `fileName` is not an absolute path, looks for a file in script directory, then relative to CSP folder,
---then relative to AC root folder. If anything is found, returns an absolute path to found file, otherwise
---returns input parameter. If such a filename is not allowed, or `fileName` is `nil`, returns an empty string.
---@param fileName string @File name relative to script folder, or CSP folder, or AC root folder.
---@return path
function ac.findFile(fileName) end

---Returns full path to one of known folders. Some folders might not exist, make sure to create them before writing.
---@param folderID ac.FolderID|string @Could also be a system GUID in “{XX…}” form.
---@return string @Returns empty string if there is no match.
function ac.getFolder(folderID) end

---Turns time in milliseconds into common lap time presentation, like 00:00.123. If minutes exceed 60,
---hours will also be added, but only if `allow_hours` is `true` (default is `false`).
---@param time number @Time in milliseconds.
---@param allowHours boolean? @Set to `true` to add hours as well. If `false` (default value), instead it would produce 99:99.999. If `true`, milliseconds will use two digits instead of three. Default value: `false`.
---@return string
function ac.lapTimeToString(time, allowHours) end

---Returns country name based on nation code (three symbols for country ID).
---@param nationCode ac.NationCode
---@return string
function ac.getCountryName(nationCode) end

---Can be used to access files in “data.acd” and, for example, read car specs.
---@param filename string
---@return string
function ac.readDataFile(filename) end

---Parse INIpp configuration file, return it as JSON. Deprecated, use `ac.INIConfig.parse()` instead.
---@deprecated
---@param iniData string
---@return string
function ac.parseINIppFile(iniData) end

---Use `ac.getTrackID()` instead.
---@deprecated
---@return string
function ac.getTrackId() end

---Returns track ID (name of its folder).
---@return string
function ac.getTrackID() end

---Returns track layout ID (name of layout folder, without name of track folder), or empty string if there is no layout.
---@return string
function ac.getTrackLayout() end

---Returns full track ID (name of track folder and layout folder joined by some string, or just name of track folder if there is no layout).
---@param separator string? @Default value: '-'.
---@return string
function ac.getTrackFullID(separator) end

---Returns track name (as set in its JSON file).
---@return string
function ac.getTrackName() end

---Given name, returns a path like …/assettocorsa/content/tracks/[track ID]/data/[name], taking into account layout as well.
---@param fileName string
---@return string
function ac.getTrackDataFilename(fileName) end

---Get car tags. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@return string[]|nil
function ac.getCarTags(carIndex) end

---A key unique for each individual PC (uses serial numbers of processor and motherboard).
---Use `ac.uniqueMachineKeyAsync()` instead.
---@deprecated
---@return string
function ac.uniqueMachineKey() end

---A key unique for each individual PC (uses serial numbers of processor and motherboard). Asynchronous version. Returned value is in binary,
---use something like `ac.encodeBase64()` to encode data in readable format.
---@param callback fun(err: string?, response: string?)
function ac.uniqueMachineKeyAsync(callback) end

---Returns squared distance to main camera. In splitscreen mode, returns smallest distance between to cameras. In the future, might be altered by
---more entities, such as additional OBS cameras. Useful if you have a detail level changing with distance.
---@param pos vec3
---@return number
function ac.distanceToRenderSquared(pos) end

---Returns distance to main camera. In splitscreen mode, returns smallest distance between to cameras. In the future, might be altered by
---more entities, such as additional OBS cameras. Useful if you have a detail level changing with distance.
---@param pos vec3
---@return number
function ac.distanceToRender(pos) end

---Returns `true` if position is closer to main camera than the threshold. In splitscreen mode, considers secondary camera. In the future, might be altered by
---more entities, such as additional OBS cameras. Useful if you have a detail level changing with distance.
---@param pos vec3
---@param distance number
---@return boolean
function ac.closerToRenderThan(pos, distance) end

---Encodes float into FP16 format and returns it as uint16.
---@param v number
---@return integer
function ac.encodeHalf(v) end

---Encodes two floats from a vector into FP16 format and returns it as uint32.
---@param v number|vec2
---@return integer
function ac.encodeHalf2(v) end

---Decodes float from FP16 format (represented as uint16) and returns a regular number.
---@param v integer
---@return number
function ac.decodeHalf(v) end

---Decodes two floats from FP16 format (represented as uint32) and returns a vector.
---@param v integer
---@return vec2
function ac.decodeHalf2(v) end

---Computes SHA-256 checksum for given binary data. Very secure, but might be slow with large amounts of data. Data string can contain zero bytes.
---@param data binary
---@return string?
function ac.checksumSHA256(data) end

---Computes 64-bit xxHash checksum for given binary data. Very fast, not that great for encryption purposes.
---Use `bit.tohex()` to turn result into a hex representation. Data string can contain zero bytes.
---@param data binary
---@return integer
function ac.checksumXXH(data) end

---Compresses data. First byte of resulting data is compression type, next four are uncompressed data size, rest is compressed data
---itself. If data is failed to compress, returns `nil`. Data string can contain zero bytes.
---@param data binary
---@param type ac.CompressionType
---@param level integer? @Higher level means better, but slower compression. Maximum value: 12. Default value: 9.
---@return string?
function ac.compress(data, type, level) end

---Decompresses data. First byte of input data is compression type, next four are uncompressed data size. If data is damaged, returns `nil`.
---Data string can contain zero bytes.
---@param data binary
---@return string?
function ac.decompress(data) end

---Encodes data in base64 format. Data string can contain zero bytes.
---@param data binary
---@param trimResult boolean? @If `true`, ending “=” will be trimmed. Default value: `false`.
---@return string?
function ac.encodeBase64(data, trimResult) end

---Decodes data from base64 format (ending “=” are not needed).
---@param data string
---@return string?
function ac.decodeBase64(data) end

---Converts string from UTF-8 to UTF-16 format (two symbols per character). All strings Lua operates with regularly are consired UTF-8. UTF-16 strings
---can’t be used in any CSP API unless documentation states that function can take strings containing zeroes.
---@param data string
---@return string?
function ac.utf8To16(data) end

---Converts string from UTF-16 (two symbols per character) to common Lua UTF-8. All strings Lua operates with regularly are consired UTF-8. UTF-16 strings
---can’t be used in any CSP API unless documentation states that function can take strings containing zeroes. Data string can contain zero bytes.
---@param data binary
---@return string?
function ac.utf16To8(data) end

---Given an FFI struct, returns bytes with its content. Resulting string may contain zeroes.
---@param data binary
---@return string?
function ac.structBytes(data) end

function ac.memoryBarrier() end

---Simple helper to measure time and analyze performance. Call `ac.perfBegin('someKey')` to start counting time and
--- `ac.perfEnd('someKey')` to stop. Measured time will be shown in Lua App Debug app in CSP (moving average across all
--- perfBegin/perfEnd calls). Note: keys on perfBegin() and perfEnd() should match.
---@param value string
function ac.perfBegin(value) end

---Simple helper to measure time and analyze performance. Call `ac.perfBegin('someKey')` to start counting time and
--- `ac.perfEnd('someKey')` to stop. Measured time will be shown in Lua App Debug app in CSP (moving average across all
--- perfBegin/perfEnd calls). Note: keys on perfBegin() and perfEnd() should match.
---@param value string
function ac.perfEnd(value) end

---Unlike `ac.perfBegin('someKey')/ac.perfEnd('someKey')`, `ac.perfFrameBegin(0)/ac.perfFrameEnd(0)` will accumulate time
--- between calls as frame progresses and then use the whole sum for moving average. This makes it suitable for measuring
--- how much time in a frame repeatedly ran bit of code takes. To keep performance as high as possible (considering that
--- it could be ran in a loop), it uses integer keys instead of strings.
---@param value integer
function ac.perfFrameBegin(value) end

---Unlike `ac.perfBegin('someKey')/ac.perfEnd('someKey')`, `ac.perfFrameBegin(0)/ac.perfFrameEnd(0)` will accumulate time
--- between calls as frame progresses and then use the whole sum for moving average. This makes it suitable for measuring
--- how much time in a frame repeatedly ran bit of code takes. To keep performance as high as possible (considering that
--- it could be ran in a loop), it uses integer keys instead of strings.
---@param value integer
function ac.perfFrameEnd(value) end

---@return vec3
function ac.getCameraPosition() end

---@return vec3
function ac.getCameraUp() end

---@return vec3
function ac.getCameraSide() end

---@return vec3
function ac.getCameraForward() end

---This vector is pointing backwards! Only kept for compatibility. For proper one, use `ac.getCameraForward()`.
---@deprecated
---@return vec3
function ac.getCameraDirection() end

---Value in degrees.
---@return number
function ac.getCameraFOV() end

---@param r vec3 @Destination.
function ac.getCameraPositionTo(r) end

---@param r vec3 @Destination.
function ac.getCameraUpTo(r) end

---@param r vec3 @Destination.
function ac.getCameraSideTo(r) end

---@param r vec3 @Destination.
function ac.getCameraForwardTo(r) end

---@param r vec3 @Destination.
function ac.getCameraDirectionTo(r) end

---Returns camera position in car coordinates system.
---@return vec3
function ac.getCameraPositionRelativeToCar() end

---Returns compass angle for given directory.
---@param dir vec3
---@return number @Angle from 0 to 360 (0/360 for north, 90 for east, etc.)
function ac.getCompassAngle(dir) end

---Value in degrees.
---@return number
function ac.getSunAngle() end

---Value in degrees.
---@return number
function ac.getSunPitchAngle() end

---Value in degrees.
---@return number
function ac.getSunHeadingAngle() end

---Returns true if camera is focused on interior (interior audio is playing).
---@return boolean
function ac.isInteriorView() end

---@return boolean
function ac.isInReplayMode() end

---@param filename string
---@param outputFilename string
function ac.compressTexture(filename, outputFilename) end

---Returns precalculated sound speed in m/s taking into account humidity, altitude, pressure, etc.
---@return number
function ac.getSoundSpeedMs() end

---Returns air pressure in kPa.
---@param p vec3
---@return number
function ac.getAirPressure(p) end

---Returns air humidity in 0…1 range. Currently doesn’t use position parameter, but it might change later.
---@param p vec3
---@return number
function ac.getAirHumidity(p) end

---Returns string with last error thrown by this script, or `nil` if there wasn’t an error. Use it in case you would want to set some nicer error reporting.
---@return string?
function ac.getLastError() end

---Returns audio volume for given channel, value from 0 to 1. If channel is not recognized, returns `fallbackValue` if specified, unless (since 0.2.4) you specify key in a
---`'your.namespace/Readable name'` format: this will register a new volume level and show it in Audio Volume app for sessions where value was
---accessed or set.
---@param audioChannelKey ac.AudioChannel
---@param carIndex integer? @If set and a Kunos car-related channel (`'dirt'`, `'engine'`, `'opponents'`, `'surfaces'`, `'transmission'`, `'tyres'`, `'wind'`) is used, returns a car-specific multiplier (1 by default). Default value: -1.
---@param fallbackValue number? @Default value: -1.
---@return number @Value from 0 to 1, or -1 if there is no such channel.
function ac.getAudioVolume(audioChannelKey, carIndex, fallbackValue) end

---Returns name of output audio device.
---@return string
function ac.getAudioOutputDevice() end

---Consider using `ac.getCar(carIndex).speedKmh` instead.
---@param carIndex integer @0-based car index.
---@return number
function ac.getCarSpeedKmh(carIndex) end

---Returns 'R', 'N', number of engaged gear or value set by `ac.setGearLabel()` if used (for implementing automatic gearboxes).
---If your code is displaying current gear, this might be a preferable choice.
---@param carIndex integer @0-based car index.
---@return string?
function ac.getCarGearLabel(carIndex) end

---Returns approximate Y coordinate of ground, calculated by using depth from reflection cubemap. Does not have a performance impact (that value
--- will be calculated anyway for CSP to run.
---@return number
function ac.getGroundYApproximation() end

---Returns current delta time associated with UI (so values are non-zero if sim or replay are paused).
---@return number @Seconds.
function ac.getDeltaT() end

---Returns current delta time associated with simulation (so values are zero if sim or replay are paused).
---@return number @Seconds.
function ac.getGameDeltaT() end

---Returns delta time for current script. If script only runs every N frames (like car display scripts by default),
---this value will be greater than regular `dt` from simulation state.
---@return number
function ac.getScriptDeltaT() end

---Returns current time multiplier.
---@return number
function ac.getConditionsTimeScale() end

---Returns name of current PP filter with “.ini”.
---@return string?
function ac.getPpFilter() end

---Value is in m/s.
---@return vec3
function ac.getWindVelocity() end

---Value is in m/s.
---@param r vec3 @Destination.
function ac.getWindVelocityTo(r) end

---@return boolean
function ac.isWeatherFxActive() end

---Distance and turn angle (in degrees) for the upcoming turn. If failed to compute, both would be -1. If car is facing wrong way, turn angle is either
---180° or -180° depending on where steering wheel of a car is.
---@param carIndex integer? @Default value: 0.
---@return vec2
function ac.getTrackUpcomingTurn(carIndex) end

---Get full driver name of a driver of a certain car. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@return string?
function ac.getDriverName(carIndex) end

---Get three character nation code of a driver of a certain car. Nation code is a three-letter uppercase country identifier. If nationality is not set, a value from JSON
---is returned. If it’s missing there, a fallback “ITA” is returned. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@return string?
function ac.getDriverNationCode(carIndex) end

---Get full nationality of a driver of a certain car. Usually, it’s a full country name. If nationality is not set, a value from JSON
---is returned. If it’s missing there, a fallback “Italy” is returned. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@return string?
function ac.getDriverNationality(carIndex) end

---Get name of a team of a driver of a certain car. Team names can be configured in entry list online. If nationality is not set, a value from JSON
---is returned. If it’s missing there, an empty string is returned. If there is no such car, returns `nil`.
---@param carIndex integer @0-based car index.
---@return string?
function ac.getDriverTeam(carIndex) end

---Get number of a driver of a certain car. If number is set in skin JSON, it will be returned, otherwise it’s a unique 1-based number.
---If there is no car with such index, 0 is returned.
---@param carIndex integer @0-based car index.
---@return integer
function ac.getDriverNumber(carIndex) end

---Returns `true` if a certain driver is using custom icon. Use `'carN::special::driver'` as image filename to draw it (when not custom,
---will give you a livery icon or a fallback dark image).
---@param carIndex integer @0-based car index.
---@return boolean
function ac.isCustomIconSet(carIndex) end

---Get session name for a session with given index. Use `ac.getSim()` to check number of sessions and more information about them.
---If there is no such session, returns `nil`.
---@param sessionIndex integer
---@return string?
function ac.getSessionName(sessionIndex) end

---Is keyboard button being held.
---@param keyIndex ui.KeyIndex
---@return boolean
function ac.isKeyDown(keyIndex) end

---Is keyboard button just moved from not held to held in the last graphics frame (or, for physics scripts since 0.2.7, physics frame).
---Still, if you’re working on car physics script, consider using `ac.ControlButton()` instead for better customization. If your script is skipping frames
---(such as car display scripts), this might not work as expected, as the frame the button has changed the state in could be skipped.
---@param keyIndex ui.KeyIndex
---@return boolean
function ac.isKeyPressed(keyIndex) end

---Is keyboard button just moved from held to not held in the last graphics frame (or, for physics scripts since 0.2.7, physics frame).
---If you’re working on car physics script, consider using `ac.ControlButton()` instead for better customization. If your script is skipping frames
---(such as car display scripts), this might not work as expected, as the frame the button has changed the state in could be skipped.
---@param keyIndex ui.KeyIndex
---@return boolean
function ac.isKeyReleased(keyIndex) end

---Can be called from anywhere. Checks if given point is within main camera frustum (or several, in triple screen mode) or not. For checking if something
---is within current camera instead, try `render.isVisible()`.
---@param pos vec3
---@param radius number
---@param gSpace boolean? @Pass `false` if your coordinates are in world-space rather than with origin shift applied (in most cases, you need to use `false`, this argument is added for backwards compatibility. Default value: `true`.
---@param includeFarPlane boolean? @Pass `false` to ignore far plane. Default value: `true`.
---@return boolean @Checks visibility with frustum culling.
function ac.isVisibleInMainCamera(pos, radius, gSpace, includeFarPlane) end

---Returns steering input from -1 to 1.
---@return number
function ac.getControllerSteerValue() end

---Is gas input pressed (pedal, gamepad axis, keyboard button but not mouse button).
---@return boolean
function ac.isControllerGasPressed() end

---Is gear up input pressed (pedal, gamepad button, keyboard button).
---@return boolean
function ac.isControllerGearUpPressed() end

---Is gear down input pressed (pedal, gamepad button, keyboard button).
---@return boolean
function ac.isControllerGearDownPressed() end

---Get session spawn set (`'START'`, `'PIT'`, `'HOTLAP_START'`, `'TIME_ATTACK'`, etc.) for a session with given index. Use `ac.getSim()`
---to check number of sessions and more information about them. If there is no such session, returns `nil`.
---@param sessionIndex integer
---@return string?
function ac.getSessionSpawnSet(sessionIndex) end

---Forces driver head to be visible even with cockpit camera.
---@param carIndex integer
---@param force boolean? @Default value: `true`.
function ac.forceVisibleHeadNodes(carIndex, force) end

---Checks if a certain gamepad button is pressed.
---@param gamepadIndex integer @0-based index, from 0 to 7 (first four are regular gamepads, second four are Dual Shock controllers).
---@param gamepadButtonID ac.GamepadButton
---@return boolean
function ac.isGamepadButtonPressed(gamepadIndex, gamepadButtonID) end

---Returns value of a certain gamepad axis.
---@param gamepadIndex integer @0-based index, from 0 to 7 (first four are regular gamepads, second four are Dual Shock controllers).
---@param gamepadAxisID ac.GamepadAxis
---@return number
function ac.getGamepadAxisValue(gamepadIndex, gamepadAxisID) end

---Returns number of DirectInput devices (ignore misleading name).
---@return integer
function ac.getJoystickCount() end

---Returns name of a DirectInput device (ignore misleading name). If there is no such device, returns `nil`.
---@param joystick integer @0-based index.
---@return string?
function ac.getJoystickName(joystick) end

---Returns instance GUID of a DirectInput device (ignore misleading name). If there is no such device, returns `nil`.
---@param joystick integer @0-based index.
---@return string?
function ac.getJoystickInstanceGUID(joystick) end

---Returns product GUID of a DirectInput device (ignore misleading name). If there is no such device, returns `nil`.
---@param joystick integer @0-based index.
---@return string?
function ac.getJoystickProductGUID(joystick) end

---Returns index of a DirectInput device by its instance GUID, or `nil` if there is no such device (ignore misleading name).
---@param guid string
---@return integer?
function ac.getJoystickIndexByInstanceGUID(guid) end

---While this function returns accurate number of device axis, consider using 8 instead if you need to iterate over them.
---Actual axis can be somewhere within those 8. For example, if device has a single axis, it could be that you need to access
---axis at index seven to get its value (rest will be zeroes).
---@param joystick integer
---@return integer
function ac.getJoystickAxisCount(joystick) end

---Returns number of buttons of a DirectInput device (ignore misleading name).
---@param joystick integer
---@return integer
function ac.getJoystickButtonsCount(joystick) end

---Returns number of D-pads (aka POVs) of a DirectInput device (ignore misleading name).
---@param joystick integer
---@return integer
function ac.getJoystickDpadsCount(joystick) end

---Checks if a button of a DirectInput device is currently held down (ignore misleading name).
---@param joystick integer
---@param button integer
---@return boolean
function ac.isJoystickButtonPressed(joystick, button) end

---Returns axis value of a DirectInput device (ignore misleading name).
---@param joystick integer
---@param axis integer
---@return number
function ac.getJoystickAxisValue(joystick, axis) end

---Use `ac.getJoystickAxisValue()` instead.
---@deprecated
---@param joystick integer
---@param axis integer
---@return number
function ac.isJoystickAxisValue(joystick, axis) end

---Returns D-pad (aka POV) value of a DirectInput device (ignore misleading name).
---@param joystick integer
---@param dpad integer
---@return integer @If D-pad is not moved, -1, or a value from 0 to 36000 storing the angle (0: up, 9000: right).
function ac.getJoystickDpadValue(joystick, dpad) end

---Use `ac.getJoystickDpadValue()` instead.
---@deprecated
---@param joystick integer
---@param dpad integer
---@return integer
function ac.isJoystickDpadValue(joystick, dpad) end

---Checks current stylus/pen/mouse using RealTimeStylus API (compatible with Windows Ink). Should support things like Wacom tables (if drivers are installed
---and Windows Ink compatibility in options is not disabled).
---
---Note: the moment its called, CSP initializes RealTimeStylus API to monitor pen state until game closes. With that, CSP will also use that data
---for mouse (or pen) pointer interaction with UI in general, especially for IMGUI apps.
---[There is a weird issue in Windows 10](https://answers.microsoft.com/en-us/windows/forum/all/windows-pen-tablet-click-and-drag-lag/9e4cac7d-69a0-4651-87e8-7689ce0d1027)
---where it doesn’t register short click-and-drag events properly expecting a touchscreen gesture. Using RealTimeStylus API for UI in general solves that.
---@return number @Pen pressure from 0 to 1 (if mouse is used, pressure is 1).
function ac.getPenPressure() end

---Returns name of the current online server, or `nil` if it’s not available.
---@return string?
function ac.getServerName() end

---Returns IP address of the current online server, or `nil` if it’s not available.
---@return string?
function ac.getServerIP() end

---Returns HTTP post of the current online server, or -1 if it’s not available.
---@return integer
function ac.getServerPortHTTP() end

---Returns TCP post of the current online server, or -1 if it’s not available.
---@return integer
function ac.getServerPortTCP() end

---Returns UDP post of the current online server, or -1 if it’s not available.
---@return integer
function ac.getServerPortUDP() end

---Returns index of a car with a driver with a certain name, or -1 if there is no such car.
---@param driverName string
---@return integer
function ac.getCarByDriverName(driverName) end

---Returns leaderboard car position, same as Python function with the same name. Does not work online. For an alternative solution,
---get position calculated by CSP via `ac.getCar(N).racePosition`
---@param carIndex integer @0-based car index.
---@return integer @Returns -1 if couldn’t calculate the value.
function ac.getCarLeaderboardPosition(carIndex) end

---Returns real time car position, same as Python function with the same name. Does not work online. For an alternative solution,
---get position calculated by CSP via `ac.getCar(N).racePosition`.
---@param carIndex integer @0-based car index.
---@return integer @Returns -1 if couldn’t calculate the value.
function ac.getCarRealTimeLeaderboardPosition(carIndex) end

---How much of moon area is currently lit up.
---@return number
function ac.getMoonFraction() end

---@return number
function ac.getAltitude() end

---Get direction to a sky feature in world-space (corrected for track heading). If feature is not available, returns a zero vector.
---@param skyFeature ac.SkyFeature
---@param distance number|refnumber|nil @Default value: `nil`.
---@param time number? @If set, it’ll compute direction for the given time instead of the current time. Default value: `nil`.
---@return vec3
function ac.getSkyFeatureDirection(skyFeature, distance, time) end

---Get direction to a star in the sky in world-space (corrected for track heading). If feature is not available, returns a zero vector.
---@param declRad number
---@param rightAscRad number
---@return vec3
function ac.getSkyStarDirection(declRad, rightAscRad) end

---Call this function if your script caused car shape to change and CSP would refresh interior masking, car heightmap and more.
---@param carIndex integer? @Default value: 0.
function ac.refreshCarShape(carIndex) end

---Call this function if your script caused car color to change and CSP would refresh color map for bounced light and more.
---@param carIndex integer? @Default value: 0.
function ac.refreshCarColor(carIndex) end

---Updates state of high-res driver model. Use it before moving driver nodes manually for extra animations: if called,
--- next model update possibly overwriting your custom positioning will be skipped. Also, model update will be enforced
--- so you can blend your custom state.
---
--- Since 0.1.80-preview397, does not apply if HR driver model is currently hidden unless second argument is `true` (in which
--- case it’ll activate driver model for a few frames).
---@param carIndex integer? @For car scripts, always applied to associated car instead. Default value: -1.
---@param forceVisible boolean? @Set to `true` to forcefully switch to HR model for a few frames. Default value: `false`.
function ac.updateDriverModel(carIndex, forceVisible) end

---@param ret mat4x4
---@param carIndex integer
---@return boolean
function ac.getDriverHeadTransformTo(ret, carIndex) end

---Block system messages based on a given regular expression.
---@param regex string @Any message with title or description containing this regex will be discarded.
---@return ac.Disposable
function ac.blockSystemMessages(regex) end

---Sets a callback which will be called when car crosses a certain point on a track. Won’t be triggered if car is in pitlane or recently jumped.
---Time is relative to the same point as `ac.SimState.time`. Tracking happens on physics thread and is interpolated based on car position, so it
---should be precise more than within 3 ms steps.
---@param carIndex integer @0-based car index, or -1 for an event to be called for all cars.
---@param progress number @Track progress from 0 to 1.
---@param callback fun(carIndex: integer, timeMs: number)
---@return ac.Disposable
function ac.onTrackPointCrossed(carIndex, progress, callback) end

---Sets a callback which will be called when a new session starts (or restarts). Doesn’t get triggered at the start of the race (Lua scripts load when
---the first session is already up and running to ensure the overall state of the sim is complete)!
---@param callback fun(sessionIndex: integer, restarted: boolean)
---@return ac.Disposable
function ac.onSessionStart(callback) end

---Sets a callback which will be called when AC resolution changes. Happens when window size changes, or when making a screenshot.
---Note: some scripts, such as WeatherFX style or post-processing script, reload completely when resolution changes, but if they’d call
---this function at any point, they would no longer reload. Instead CSP assumes they can handle resolution changes on their side.
---@param callback fun(newSize: vec2, makingScreenshot: boolean)
---@return ac.Disposable
function ac.onResolutionChange(callback) end

---Sets a callback which will be called when selected tyres change for some car. For car scripts to track changes in their own car, use `car.index` as first argument.
--- Note: for physics scripts this even might come a few frames late, but it shouldn’t be a major issue since tyres changes only happen when car is stationary anyway.
---@param carIndex integer @0-based car index, or -1 for an event to be called for all cars.
---@param callback fun(carIndex: integer, setIndex: integer, shortName: string, longName: string)
---@return ac.Disposable
function ac.onTyresSetChange(carIndex, callback) end

---Sets a callback which will be called when new user connects the server and their car appears (doesn’t do anything outside of online race).
---@param callback fun(connectedCarIndex: integer, connectedSessionID: integer)
---@return ac.Disposable
function ac.onClientConnected(callback) end

---Sets a callback which will be called when a user disconnects (doesn’t do anything outside of online race).
---@param callback fun(connectedCarIndex: integer, connectedSessionID: integer)
---@return ac.Disposable
function ac.onClientDisconnected(callback) end

---Sets a callback which will be called when control settings change live.
---@param callback fun()
---@return ac.Disposable
function ac.onControlSettingsChanged(callback) end

---Sets a callback which will be called when triple screen configuration changes.
---@param callback fun()
---@return ac.Disposable
function ac.onTripleConfigurationChanged(callback) end

---Returns `true` if a Lua app with given ID is loaded and currently active (not countring background services).
---@param appID string
---@return boolean
function ac.isLuaAppRunning(appID) end

---Returns an estimate of optimal braking amount based on current grip level, or -1 if it can’t be computed for a given car.
---@param carIndex integer
---@return number
function ac.getCarOptimalBrakingAmount(carIndex) end

---Returns an estimate of maximum speed for a given gear in km/h, -1 if it can’t be computed for a given car, or 0 if there is no such gear. Returns negative
---speed for the reverse gear.
---@param carIndex integer
---@param gearIndex integer @Gear index, 1 for first gear (same as `ac.getCar().gear`).
---@return number @Returns speed in km/h.
function ac.getCarMaxSpeedWithGear(carIndex, gearIndex) end

---Changes location of script storage. Scripts without I/O access will have “shared-” appended to their relative path and can’t use “.” or slashes in it
---to ensure configs are contained within the directory. Note: before 0.2.4 calls to this function by scripts without I/O access would have no effect.
---@param relativePath string @Path relative to directory with Lua configs. If empty, call won’t have an effect.*/.
---@param prefix string|nil @Optional prefix. Default value: `nil`.
function ac.storageSetPath(relativePath, prefix) end

---Broadcasts a shared event. With shared events, different Lua scripts can exchange messages and data. Make sure to come up with
---a unique name for your events to avoid collisions with other scripts and Lua apps.
---
---Callbacks will be called next time the script is updating.
---
---Note: if your scripts need to exchange data frequently, consider using `ac.connect()` instead, as it allows to establish a typed connection
---with much less overhead.
---@param key string
---@param data serializable
---@return integer @Returns number of listeners to the event with given key.
function ac.broadcastSharedEvent(key, data) end

---Subscribes to a shared event. With shared events, different Lua scripts can exchange messages and data. Make sure to come up with
---a unique name for your events to avoid collisions with other scripts and Lua apps.
---
---Callback will be called next time this script is updating.
---@param key string
---@param callback fun(data: string|number|boolean|nil, senderName: string, senderType: string, senderID: integer)
---@param processPostponed boolean? @Set to `true` to process previously broadcasted and yet non-processed events (up to 40). Default value: `false`.
---@return ac.Disposable
function ac.onSharedEvent(key, callback, processPostponed) end

---@param callback fun(senderName: string, senderType: string, senderID: integer)
---@return ac.Disposable
function ac.onLuaScriptDisposal(callback) end

---@param hand integer @0 for left, 1 for right.
---@param busy boolean|`true`|`false` @Busy hand doesn’t have visual marks and doesn’t interact with UI and car elements.
function ac.setVRHandBusy(hand, busy) end

---@param hand integer @0 for left, 1 for right.
---@param frequency number
---@param amplitude number
---@param duration number? @Duration in seconds. Default value: 0.01.
function ac.setVRHandVibration(hand, frequency, amplitude, duration) end

---@param cspModuleID ac.CSPModuleID
---@return boolean
function ac.isModuleActive(cspModuleID) end

---@return number, number
function ac.getPerformanceCPUAndGPUTime() end

---Returns index of a car in front of other car (within 100 m), or -1 if there is no such car. Broken, not sure why is it even here, kept for compatibility.
---@deprecated.
---@param carMainIndex integer
---@param distance number|refnumber|nil @Default value: `nil`.
---@return integer
function ac.getCarIndexInFront(carMainIndex, distance) end

---Calculates time gap between two cars in seconds. In race sessions uses total driven distance and main car speed, in other sessions simply
---compares best lap times. If main car is ahead of comparing-to car (in front of, or has better lap time for non-race sessions), value will
---be negative.
---
---In the future implementation might change for something more precise.
---@param carMainIndex integer @0-based index.
---@param carComparingToIndex integer @0-based index.
---@return number
function ac.getGapBetweenCars(carMainIndex, carComparingToIndex) end

---Returns audio peak level for the system, for left and right channels. Careful: AC audio is also included, but
---it still might be used to fake some audio visualization.
---@param output boolean? @Set to `false` to monitor peak from a microphone. Note: it would only work if there are other processes actually listening to audio. Default value: `true`.
---@return vec2
function ac.mediaCurrentPeak(output) end

---Set texture key to load encoded textures.
---@param key string? @Key to decode subsequently loading textures.
function ac.setTextureKey(key) end

---Encode texture. To load texture later, first call `ac.setTextureKey()`.
---@param filename string @Input filename.
---@param outputFilename string @Should be inside of AC folder.
---@param key string?
---@param applyLz4Compression boolean?
---@return boolean @Returns `false` if file operations failed.
function ac.encodeTexture(filename, outputFilename, key, applyLz4Compression) end

---Sets a callback which will be called when album cover changes.
---@param callback fun(hasCover: boolean)
---@return ac.Disposable
function ac.onAlbumCoverUpdate(callback) end

---Switches to the next track in currently active music player (by simulating media key press).
function ac.mediaNextTrack() end

---Switches to the previous track in currently active music player (by simulating media key press).
function ac.mediaPreviousTrack() end

---Pauses or unpauses current track in currently active music player (by simulating media key press).
function ac.mediaPlayPause() end

---Returns player’s car setup state.
---@return 'legal'|'illegal'|'validating', string? @Returns car setup state and optional reason for setup to be illegal (might be set by car physics script).
function ac.getCarSetupState() end

---Prints message to AC console.
---@param message string?
---@param withoutPrefix boolean? @Default value: `false`.
function ac.console(message, withoutPrefix) end

---Returns `false` if tyres with this short name are illegal in this race. Note: if all of car tyres are illegal, all of them will be legal.
---@param name string
---@return boolean
function ac.areTyresLegal(name) end

---Show message using AC system messages UI. Pass empty `title` and `description` to hide currently shown message, if any.
---
--- Types:
--- - Default: regular message shown on top in white text.
--- - 'illegal': message about an illegal violation. Can be used to warn driver about a crucial mistake, such as lap time
---being invalidated, or wear plank wear exceeding allowed limit. Doesn’t apply any penalties on its own.
---@param title string
---@param description string
---@param type nil|'illegal' @Optional message type.
---@param time number? @Time to show message for in seconds. Default value: 5.
function ac.setMessage(title, description, type, time) end

---Listen to messages, including the ones shown by `ac.setMessage()` and `ac.setIllegalMessage()`.
---@param callback fun(title: string, description: string, type: nil|'illegal', time: number)
---@return ac.Disposable
function ac.onMessage(callback) end

---Use `ac.setMessage()` instead.
---@deprecated
---@param title string
---@param description string
function ac.setSystemMessage(title, description) end

---Sets given text to the clipboard.
---@param text string
---@return boolean @Returns `false` if failed.
function ac.setClipboardText(text) end

---Sets a callback which will be called when car teleports somewhere or its state gets reset.
---@param carIndex integer @0-based car index, or -1 for an event to be called for all cars.
---@param callback fun(carIndex: integer)
---@return ac.Disposable
function ac.onCarJumped(carIndex, callback) end

---Sets a callback which will be called when car collides with a wall or another car. Note: collisions in AC are usually lasting a few frames,
---but this callback will only be called once when collision starts (or when index of a car this car collided with has changed). Use
---`ac.getCar().collisionDepth` and similar to analyze the collision in detail.
---@param carIndex integer @0-based car index, or -1 for an event to be called for all cars.
---@param callback fun(carIndex: integer)
---@return ac.Disposable
function ac.onCarCollision(carIndex, callback) end

---Sets a callback which will be called when a file changes.
---Not available to scripts without I/O access.
---@param filename path @Full path to a file to monitor.
---@param callback fun() @Callback function.
---@return ac.Disposable
function ac.onFileChanged(filename, callback) end

---Sets a callback which will be called when folder contents change.
---Not available to scripts without I/O access.
---@param folder path @Full path to a directory to monitor.
---@param filter string? @CSP filter (? for any number of any symbols, regex if “`” quotes are used, or a complex query) applied to full file path, or `nil`.
---@param recursive boolean? @If `true`, changes in subfolders are also detected. Default value: `false`.
---@param callback fun(files: string[])
---@return ac.Disposable
function ac.onFolderChanged(folder, filter, recursive, callback) end

---Sets a callback which will be called when config for certain CSP module has changed.
---@param cspModuleID ac.CSPModuleID @ID of a module to monitor.
---@param callback fun() @Callback function.
---@return ac.Disposable
function ac.onCSPConfigChanged(cspModuleID, callback) end

---Sets a callback which will be called when a new screenshot is made.
---@param callback fun()
---@return ac.Disposable
function ac.onScreenshot(callback) end

---Sets a callback which will be called when list of setups changes.
---@param callback fun()
---@return ac.Disposable
function ac.onSetupsListRefresh(callback) end

---Sets a callback which will be called when setup is loaded or saved. Use `ac.INIConfig.currentSetup()` to load the setup.
---@param callback fun(operation: 'load'|'save', filename: string) @Callback function.
---@return ac.Disposable
function ac.onSetupFile(callback) end

---Stops functions like `ac.log()` from logging things into CSP log file, in case you need to log a lot. With it, you
--- can use Lua Debug app to see latest log entries.
---@param value boolean? @Default value: `true`.
function ac.setLogSilent(value) end

---Removes `ac.debug()` entries matching filter.
---@param filter string? @Default value: `?`.
function ac.clearDebug(filter) end

---Returns list of logical drives, each drive in “A:“ format.
---Not available to scripts without I/O access.
---@return string[]
function io.scanDrives() end

---Gets file attributes.
---@param filename path
---@return io.FileAttributes
function io.getAttributes(filename) end

---Gets full filename of the main AC executable (“…/acs.exe” for most cases).
---Not available to scripts without I/O access.
---@return path
function io.getMainExecutable() end

---Reads file content into a string, if such file exists, otherwise returns fallback data or `nil`.
---@param filename path
---@param fallbackData string|nil @Data to return if file could not be read.
---@return string|nil @Returns `nil` if file couldn’t be read and there is no fallback data.
function io.load(filename, fallbackData) end

---Reads file content into a string, if such file exists, otherwise returns fallback data or `nil`. Asynchronous version.
---@param filename path
---@param callback fun(err: string?, response: string?)
function io.loadAsync(filename, callback) end

---Writes data into a file, returns `true` if operation was successful. Data string can contain zero bytes.
---Not available to scripts without I/O access.
---@param filename path
---@param data binary?
---@param ensure boolean? @If set to `true`, file will be saved with a temporary postfix and then moved to target destination, thus ensuring content is stored as-is, without ending up damaged in case there is a sudden power loss or something like that. Default value: `false`.
---@return boolean @Returns `false` if failed to write a file.
function io.save(filename, data, ensure) end

---Writes data into a file from a different thread, returns `true` via callback if operation was successful. Data string can contain zero bytes.
---Not available to scripts without I/O access.
---@param filename path
---@param data binary?
---@param callback fun(err: string?)
---@param ensure boolean? @If set to `true`, file will be saved with a temporary postfix and then moved to target destination, thus ensuring content is stored as-is, without ending up damaged in case there is a sudden power loss or something like that. Default value: `false`.
function io.saveAsync(filename, data, callback, ensure) end

---Checks if file or directory exists. If you need to know specifically if a file or directory exists, use `io.dirExists(filename)` or `io.fileExists(filename)`.
---@param filename path
---@return boolean
function io.exists(filename) end

---Checks if directory exists. If there is a file in its place, it would return `false`.
---@param filename path
---@return boolean
function io.dirExists(filename) end

---Checks if file exists. If there is a directory in its place, it would return `false`.
---@param filename path
---@return boolean
function io.fileExists(filename) end

---Calculates file size in bytes. Returns -1 if there was an error.
---@param filename path
---@return integer
function io.fileSize(filename) end

---Returns creation time as number of seconds since 1970, or -1 if there was an error.
---@param filename path
---@return integer
function io.creationTime(filename) end

---Returns last access time as number of seconds since 1970, or -1 if there was an error.
---@param filename path
---@return integer
function io.lastAccessTime(filename) end

---Returns last write time as number of seconds since 1970, or -1 if there was an error.
---@param filename path
---@return integer
function io.lastWriteTime(filename) end

---Creates new directory, returns `true` if directory was created. If parent directories are missing, they’ll be created as well.
---Not available to scripts without I/O access.
---@param filename path
---@return boolean
function io.createDir(filename) end

---Creates new directory for given filename (as in, take parent path and create directory with it). Returns `true` if directory was created.
---Not available to scripts without I/O access.
---@param filename path
---@return boolean
function io.createFileDir(filename) end

---Returns parent path for given filename.
---@param filename string
---@param level integer? @Default value: 1.
---@return string
function io.getParentPath(filename, level) end

---Returns file name path for given filename.
---@param filename string
---@param noExtension boolean? @Default value: `false`.
---@return string
function io.getFileName(filename, noExtension) end

---Checks if file name is acceptable, returns `true` if there are no prohibited symbols in it (unlike `io.isFileNameAcceptable()`, does not allow slashes).
---@param fileName string
---@return boolean
function io.isFileNameAcceptable(fileName) end

---Checks if full file name is acceptable, returns `true` if there are no prohibited symbols in it (unlike `io.isFileNameAcceptable()`, does allow slashes).
---@param filename string
---@return boolean
function io.isFilePathAcceptable(filename) end

---Moves a file or a directory with all of its contents to a new place, returns `true` if moved successfully. Can be used for moving or renaming things.
---Not available to scripts without I/O access.
---@param existingFilename path
---@param newFilename path
---@param replaceExisting boolean? @Default value: `false`.
---@return boolean
function io.move(existingFilename, newFilename, replaceExisting) end

---Copies a file to a new place, returns `true` if moved successfully.
---Not available to scripts without I/O access.
---@param existingFilename path
---@param newFilename path
---@param failIfExists boolean? @Set to `false` to silently overwrite existing files. Default value: `true`.
---@return boolean
function io.copyFile(existingFilename, newFilename, failIfExists) end

---Deletes a file, returns `true` if file was deleted successfully. To delete empty directory, use `io.deleteDir()`. If you’re operating around important
---files, consider using `io.recycle()` instead.
---Not available to scripts without I/O access.
---@param filename path
---@return boolean
function io.deleteFile(filename) end

---Deletes an empty directory, returns `true` if directory was deleted successfully. To delete a file, use `io.deleteFile()`.
---Not available to scripts without I/O access.
---@param filename path
---@return boolean
function io.deleteDir(filename) end

---Moves file to Windows Recycle Bin, returns `true` if file was moved successfully. Note: this operation is much slower than removing a file with `io.deleteFile()`
---or removing an empty directory with `io.deleteDir()`.
---Not available to scripts without I/O access.
---@param filename path
---@return boolean
function io.recycle(filename) end

---Adds a new entry to a ZIP file. If there is no such ZIP file, new one will be created. If the ZIP file already has an entry with
---the same name, does nothing and returns `false`. Note: for adding multiple or large files use `io.createZipAsync()` instead.
---Not available to scripts without I/O access.
---@param zipFilename path
---@param entryFilename string
---@param data binary?
---@return boolean
function io.saveToZip(zipFilename, entryFilename, data) end

---Loads file from an archive as a string. Archive would remain open for some time to speed up consequent reads. If failed, returns `nil`. Alternatively,
---you can pass ZIP data instead.
---@param zipFilename path
---@param entryFilename string
---@return string
function io.loadFromZip(zipFilename, entryFilename) end

---Extract files from a ZIP file into a given directory. Creates directory if it’s missing.
---Not available to scripts without I/O access.
---@param zipFilename binary?
---@param destination path @Full path to target directory.
---@param filter string? @Optional filter for full entry paths.
---@param callback fun(err: string?)
function io.extractFromZipAsync(zipFilename, destination, filter, callback) end

---Computes SHA-256 checksum of a given file, returns result in a callback.
---@param filename path
---@param callback fun(err: string, checksum: string)
function io.checksumSHA256(filename, callback) end

---Returns list of entry names from a ZIP-file.
---@param zipFilename binary?
---@return string[]
function io.scanZip(zipFilename) end

---Not available to scripts without I/O access.
---@param filename path? @Pass `nil` to instead get the binary data in the callback.
---@param entries table<string, io.ZipEntry> @Keys store entry names (use “/” as separator for creating sub-folders), and values store either binary data or tables in `io.ZipEntry` format.
---@param callback fun(err: string?, response: binary??) @Callback will contain reference to binary data if `filename` is `nil`.
function io.createZipAsync(filename, entries, callback) end

---Not available to scripts without I/O access.
---@return string[]
function io.arrtest1() end

---Not available to scripts without I/O access.
---@return string[]
function io.arrtest2() end

---Returns time in seconds from script start (with high precision).
---@return number @Seconds.
function os.preciseClock() end

---Sets a callback which will be called when CSP itself or a CSP Lua script tries to open an URL. Return `true` if you’re handling URL, so the event would be stopped.
---@param mask string @Regular expression to check URLs against of.
---@param callback fun(url: string): boolean
---@param priority integer? @Smaller values mean script would be the last to get URL (if other scripts wouldn’t intercept it). Default value: 0.
---@return ac.Disposable
function os.onURL(mask, callback, priority) end

---Altered version of regular `os.execute()`: allows to specify timeout and doesn’t show a new window.
--- Note: please consider using `os.runConsoleProcess()` instead: it’s a lot more robust, asynchronous and tweak-able.
---Not available to scripts without I/O access.
---@param cmd string
---@param timeoutMs integer? @Default value: -1.
---@param windowless boolean? @Default value: `true`.
---@return integer
function os.execute(cmd, timeoutMs, windowless) end

---Changes current directory. Any argument `path`, when parsed and found not to be absolute, will be resolved against current directory.
---By default, uses AC root folder. Any change only applies to the current script only. Current path resets when script is reloaded.
---
---Changes behavior of images and assets lookup as well (by default it scans script folder, CSP folder and then root folder looking for a file,
---which might cause some issues and negatively affect performance).
---
--- For scripts without I/O access, only folders script can read from can be used here.
---
--- Note: as of 0.2.6, some API functions might still use AC root folder. This will be fixed in the future, please do not rely on this behavior!
---@param filename path
---@return string
function os.setCurrentFolder(filename) end

---Returns formatted date. Same as `os.date()`, but returned value does not include system timezome.
---@param format string
---@param timestamp integer
---@return string
function os.dateGlobal(format, timestamp) end

---Adds new directory to look for DLL files in. Warning: do not use this thing unless you really need to, and try to avoid adding LuaJIT extensions:
---LuaJIT build might change in the future breaking ABI compatibility.
---Not available to scripts without I/O access.
---@param filename string @If not absolute, considered to be relative to script root folder.
function os.addDLLDirectory(filename) end

---Show a popup message using good old MessageBox. Please do not use it for debugging, instead consider using `ac.log()` and `ac.debug('key', 'value')`
---with in-game Lua Debug App.
---Note: do not rely on this function, most likely it might be removed in the future as obstructing.
---@param msg string
---@param type integer? @Type of MessageBox according to WinAPI. Default value: 0.
---@return integer
function os.showMessage(msg, type) end

---Shows file in Windows Explorer (opens folder with it and selects the file).
---Not available to scripts without I/O access.
---@param filename path
function os.showInExplorer(filename) end

---Opens file or directory in Windows Explorer. If it’s a file, associated program will be launched instead.
---Not available to scripts without I/O access.
---@param directory path
function os.openInExplorer(directory) end

---Tries to find a program associated with a filename. Returns path to it, or `nil` if nothing was found.
---Not available to scripts without I/O access.
---@param filename path
---@return path
function os.findAssociatedExecutable(filename) end

---Opens text file at given line in a default text editor. Supports VS Code, Notepad++, Sublime Text and Atom (they all use different
---arguments for line number.
---Not available to scripts without I/O access.
---@param filename path
---@param line integer
function os.openTextFile(filename, line) end

---Opens URL in default system browser.
---@param url string
---@param invokeListeners boolean? @Default value: `true`.
function os.openURL(url, invokeListeners) end

---@return number
function ac.getRealTrackHeadingAngle() end

---@return number
function ac.getTimeZoneOffset() end

---@return number
function ac.getTimeZoneDstOffset() end

---@return number
function ac.getTimeZoneBaseOffset() end

---Returns original weather conditions without any filtering or sanity checks. For a faster and more filtered data check `ac.getSim().weatherConditions`.
---@return ac.ConditionsSet
function ac.getConditionsSet() end

---Returns original weather conditions without any filtering or sanity checks. For a faster and more filtered data check `ac.getSim().weatherConditions`.
---@param r ac.ConditionsSet
function ac.getConditionsSetTo(r) end

---Returns floading point number of seconds since 1970/01/01 that can be used for driving track animations in such a way that if time multiplier is set to
---0 or above 1, things would still happen at normal speed, although out of sync with the clock. Ensures to keep things online as well. Currently might not
---work that well with replays, futher updates will improve some edge cases.
---
---Note: if time is still being estimated, returns 0, be sure to check for that case.
---@return number
function ac.getTrackDateTime() end

---Use `ac.getSim()` instead
---@deprecated
---@return ac.StateSim
function ac.getSimState() end

---Use `ac.getUI()` instead
---@deprecated
---@return ac.StateUi
function ac.getUiState() end

---Use `ac.getCar()` instead. Here, index starts with 1! With `ac.getCar()` index starts with 0, to match the rest of API functions
---@param index integer @1-based index.
---@return ac.StateCar?
function ac.getCarState(index) end

---Returns reference to a structure with various information about the state of Assetto Corsa. Very cheap to use.
--- This is a new version with shorter name. Updates once per graphics frame.
---@return ac.StateSim
function ac.getSim() end

---Returns reference to a structure with various information about certain session. Very cheap to use. Note: not all data
--- might be available online.
---@param index integer @0-based index.
---@return ac.StateSession?
function ac.getSession(index) end

---Returns reference to a structure with various information about the state of the UI. Very cheap to use.
---This is a new version with shorter name. Updates once per graphics frame.
---
---Note: this information is about AC UI, not about, for example, a dynamic track texture you might be updating.
---@return ac.StateUi
function ac.getUI() end

---Returns data regarding current triple screen configuration. If AC is not launched in triple screen mode, returns `nil` instead.
---@return ac.StateTriple?
function ac.getTripleConfiguration() end

---Returns reference to a structure with VR-related values, like hands and head positions. Very cheap to use.
---
---Note: currently, accurate values are available with Oculus only.
---@return ac.StateVR?
function ac.getVR() end

---Returns reference to a structure with TrackIR-related values. Very cheap to use.
---@return ac.StateTrackir?
function ac.getTrackIR() end

---Returns additional details on physics state of a car. Not available in replays or for remote cars.
---
---Updates once a frame at graphics rate. If you’re writing a physics script, consider using something else if you need
---to access current state, this thing might be a few physics frames late.
---
---Note: index starts with 0. Make sure to check result for `nil` if you’re accessing a car that might not be there. First car
---with index 0 is always there.
---@param index integer @0-based index.
---@return ac.StateCarPhysics?
function ac.getCarPhysics(index) end

---Returns extras of PS5 DualSense gamepad, such as accelerometer, gyroscope or battery state. Accelerometer and gyroscope values might be different from values reported by `ac.getDualShock()` for different controllers in the same orientation.
---Note: if you’re writing a car script, first argument will be ignored and instead the effect would be applied to gamepad controlling the car if possible.
---@param gamepadIndex integer @0-based index, from 4 to 7 (first four are regular gamepads, second four are Dual Shock controllers).
---@return ac.StateDualsense?
function ac.getDualSense(gamepadIndex) end

---Returns a structure with state of PS5 DualSense LEDs, change it to alter its state. Changes remain for some time, keep calling it for continuos adjustments.
---Note: if you’re writing a car script, first argument will be ignored and instead the effect would be applied to gamepad controlling the car if possible.
---@param gamepadIndex integer @0-based index, from 4 to 7 (first four are regular gamepads, second four are Dual Shock controllers).
---@param priority number? @If multiple scripts try to set LEDs at the same time, the call with highest priority will be applied. Default value: 0.
---@param holdFor number? @Time to keep the changes for in seconds. Default value: 0.5.
---@return ac.StateDualsenseOutput? @Returns `nil` if there is no applicable controller, make sure to check for it.
function ac.setDualSense(gamepadIndex, priority, holdFor) end

---Returns extras of PS4 DualShock gamepad (or Nintendo gamepads), such as accelerometer, gyroscope or battery state. Accelerometer and gyroscope values might be different from values reported by `ac.getDualSense()` for different controllers in the same orientation.
---Note: if you’re writing a car script, first argument will be ignored and instead the effect would be applied to gamepad controlling the car if possible.
---@param gamepadIndex integer @0-based index, from 4 to 7 (first four are regular gamepads, second four are Dual Shock controllers).
---@return ac.StateDualshock?
function ac.getDualShock(gamepadIndex) end

---Returns a structure with state of PS4 DualShock (or Nintendo) LEDs, change it to alter its state. Changes remain for some time, keep calling it for continuos adjustments.
---Note: if you’re writing a car script, first argument will be ignored and instead the effect would be applied to gamepad controlling the car if possible.
---@param gamepadIndex integer @0-based index, from 4 to 7 (first four are regular gamepads, second four are Dual Shock controllers).
---@param priority number? @If multiple scripts try to set LEDs at the same time, the call with highest priority will be applied. Default value: 0.
---@param holdFor number? @Time to keep the changes for in seconds. Default value: 0.5.
---@return ac.StateDualshockOutput? @Returns `nil` if there is no applicable controller, make sure to check for it.
function ac.setDualShock(gamepadIndex, priority, holdFor) end

---Returns a structure with state of Xbox One gamepad, change it to alter its state. Changes remain for some time, keep calling it for continuos adjustments.
---Note: if you’re writing a car script, first argument will be ignored and instead the effect would be applied to gamepad controlling the car if possible.
---@param gamepadIndex integer @0-based index, from 0 to 3.
---@param priority number? @If multiple scripts try to set LEDs at the same time, the call with highest priority will be applied. Default value: 0.
---@param holdFor number? @Time to keep the changes for in seconds. Default value: 0.5.
---@return ac.StateXboxOutput? @Returns `nil` if there is no applicable controller, make sure to check for it.
function ac.setXbox(gamepadIndex, priority, holdFor) end

---Returns velocity (in world coordinates) of a car point. If there is no such car or physics currently available, returns vector with zeroes.
---@param carIndex integer @0-based car index.
---@param position vec3 @Point of force application.
---@param posLocal boolean|`true`|`false` @If `true`, position is treated like position relative to car coordinates, otherwise as world position.
---@return vec3
function physics.getPointVelocity(carIndex, position, posLocal) end

---@param carIndex integer @0-based car index.
---@param corner integer @0-based wheel index.
---@return number
function physics.getExtendedSuspensionTravel(carIndex, corner) end

---@param carIndex integer @0-based car index.
---@param corner integer @0-based wheel index.
---@return number
function physics.getExtendedDamperTravel(carIndex, corner) end
---@class ac.StateWheel : ClassBase
---@field tyreRadius number @Tyre radius in meters.
---@field tyreWidth number @Tyre width in meters.
---@field rimRadius number @Rim radius in meters (older cars might not have it).
---@field tyreDirty number @Dirt levels for tyres, four values, from 0 to 1.
---@field tyreWear number @Tyre wear, from 0 to 1.
---@field tyreVirtualKM number @Driven distance for each tyre in km (resets when tyres change, not an actual distance, rate of change depends on wear multiplier).
---@field tyreGrain number
---@field tyreBlister number
---@field tyreFlatSpot number
---@field tyreStaticPressure number @Static tyre pressure.
---@field tyrePressure number @Dynamic tyre pressure.
---@field temperatureMultiplier number
---@field tyreCoreTemperature number @Core tyre temperature, in °C.
---@field tyreInsideTemperature number @Inside tyre temperature, in °C.
---@field tyreMiddleTemperature number @Middle tyre temperature, in °C.
---@field tyreOutsideTemperature number @Outside tyre temperature, in °C.
---@field tyreOptimumTemperature number @Optimum tyre temperature, in °C.
---@field brakeTemperature number @Brakes temperature, in °C, or 0 if it’s not available (for most cars).
---@field discTemperature number
---@field angularSpeed number
---@field slip number
---@field slipAngle number @Angle between the desired direction and the actual direction of the vehicle, in degrees.
---@field slipRatio number
---@field ndSlip number
---@field load number @Tyre load in N (warning: does not have correct values for remote cars online or in replays, use `.loadK` if you want a rough but stable estimation instead)
---@field loadK number
---@field speedDifference number @Difference in speed between tyre and ground surface in contact point.
---@field camber number @Camber angle in degrees.
---@field toeIn number @Toe angle in degrees.
---@field suspensionDamage number
---@field suspensionTravel number
---@field tyreLoadedRadius number
---@field waterThickness number @Water thickness in meters.
---@field dx number
---@field dy number
---@field mz number @Self aligning torque.
---@field fx number
---@field fy number
---@field contactNormal vec3 @Normal of a contact point surface.
---@field contactPoint vec3 @Contact point position in world coordinates.
---@field position vec3 @Wheel position in world coordinates.
---@field look vec3 @Wheel (SUSP_…) heading vector.
---@field up vec3 @Wheel (SUSP_…) vector directed updwards.
---@field outside vec3 @Points outside of car (to the left of tyre for left tyres, to the right for right).
---@field velocity vec3
---@field transform mat4x4 @Wheel (SUSP_…) transformation.
---@field transformWheel mat4x4 @Wheel (WHEEL_…) transformation.
---@field surfaceDirt number @Dirt additive coefficient of the surface below the wheel.
---@field surfaceSectorID integer @Sector ID of the surface below the wheel.
---@field surfaceSectionIndex integer @Index of section in “surfaces.ini” corresponding with surface the wheel is on, or -1 if it’s not available
---@field surfaceGrip number @Grip of the surface below the wheel.
---@field surfaceDamping number @Damping of the surface below the wheel.
---@field surfaceGranularity number @Damping of the surface below the wheel.
---@field surfaceVibrationGain number @Vibration gain of the surface below the wheel.
---@field surfaceVibrationLength number @Vibration length of the surface below the wheel.
---@field surfacePitlane boolean @If surface below the wheel is in pitlane.
---@field surfaceValidTrack boolean @If surface below the wheel is valid track.
---@field isBlown boolean
---@field isHot boolean
---@field isSpecialSurface boolean @Do not play skids audio if this value is `true`.
---@field surfaceType ac.SurfaceType @Basic type hint used for visuals.
---@field surfaceExtendedType ac.SurfaceExtendedType @Extended type hint, more types will be added later.

---@class ac.StateCar : ClassBase
---@field mass number @Car mass in kg.
---@field graphicsOffset vec3 @Graphics offset from car.ini
---@field graphicsPitchRotation number @Graphics pitch rotation in radians from car.ini
---@field graphicsToPhysicsTransform mat4x4 @Graphics-to-physics transform based on graphics offset and pitch rotation from car.ini
---@field physicsToGraphicsTransform mat4x4 @Physics-to-graphics transform based on graphics offset and pitch rotation from car.ini
---@field steerLock number @Maximum steering wheel angle in degrees.
---@field maxFuel number @Maximum amount of fuel in liters.
---@field exposureOutside number @Outboard exposure from car.ini
---@field exposureInside number @Onboard exposure from car.ini
---@field shakeMultiplier number @SHAKE_MUL value from car.ini
---@field headlightsColor rgb
---@field customCarColor rgb @Custom car color selected online, or `math.nan` if color is the default one
---@field aabbCenter vec3 @Center of AABB (calculated from LOD D or collider mesh).
---@field aabbSize vec3 @Size of AABB in meters (calculated from LOD D or collider mesh).
---@field index integer @0-based (0 for first car).
---@field gearCount integer @Excluding neutral and reverse. Physics-only (see `ac.CarState.physicsAvailable`)
---@field turboCount integer @Physics-only (see `ac.CarState.physicsAvailable`)
---@field tractionType integer @0 for rwd, 1 for fwd, 2 for awd, 3 for new awd, -1 for N/A. Physics-only (see `ac.CarState.physicsAvailable`)
---@field enginePosition integer @0 for unspecified, 1 for front, 2 for rear, 3 for mid. Physics-only (see `ac.CarState.physicsAvailable`)
---@field brakesBiasLimitDown number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field brakesBiasLimitUp number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field brakesBiasStep number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field maxRelativePlankWear number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field year integer @Manufactoring year.
---@field hShifter boolean @True if car has H-shifter in its physics data.
---@field adjustableTurbo boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field brakesCockpitBias boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field extendedPhysics boolean @True if extended car physics is active.
---@field isRacingCar boolean @True for racing cars (cars with class different from “road” or “street”).
---@field isRallyCar boolean @Car counts as a rally car if it has a corresponding tag or “rally” in its name.
---@field isDriftCar boolean @Car counts as a drift car if it has a corresponding tag or “drift” in its name.
---@field isOpenWheeler boolean @Check is based on car tags.
---@field isEngineDiesel boolean @Check is based on car tags.
---@field isKunosCar boolean @True if car is standard, from Kunos.
---@field prefersImperialUnits boolean @True for cars from UK or USA.
---@field headlightsAreHeadlights boolean @If set to `false`, headlights do something else (like change display mode).
---@field hasLowBeams boolean @If set to `false`, low beams are not present (as in, headlights operate in a single mode).
---@field isLeftHandDrive boolean @If set to `true`, steering wheel is on the left side.
---@field sirenHorn boolean @If set to `true`, horn is working in siren mode (press to toggle).
---@field hasFlashingLights boolean
---@field hasCockpitSwitchForUserSpeedLimiter boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field hasHornAudioEvent boolean
---@field hasAnalogTelltale boolean @Car has max RPM arrow.
---@field tractionControlModes integer @0 if TC is not present. Physics-only (see `ac.CarState.physicsAvailable`)
---@field absModes integer @0 if ABS is not present. Physics-only (see `ac.CarState.physicsAvailable`)
---@field fuelMaps integer
---@field tractionControl2Modes integer
---@field hasEngineBrakeSettings boolean
---@field pitTransform mat4x4 @Transformation of pit position.
---@field timestamp number @Time of last physics state record, in milliseconds (counting from the same point as ac.SimState.time)
---@field transform mat4x4 @Car physics transformation in world space (does not match body transformation! for it, use `bodyTransform`)
---@field bodyTransform mat4x4 @Car visual transformation (the one applied to 3D model).
---@field worldToLocal mat4x4 @Inverse of car visual transformation.
---@field position vec3 @Car position in the world (corresponds to 0 coordinate in its model space).
---@field velocity vec3 @Car velocity in m/s.
---@field acceleration vec3 @G-forces, X for sideways relative to car, Z for forwards/backwards.
---@field angularVelocity vec3
---@field localAngularVelocity vec3
---@field localVelocity vec3
---@field up vec3 @Vector facing upwards (normalized).
---@field look vec3 @Vector facing forward (normalized).
---@field side vec3 @Vector facing sideways (normalized).
---@field driverEyesPosition vec3 @In-car coordinates for driver eyes position (can be changed by user).
---@field groundNormal vec3 @Normal of ground below car.
---@field groundDistance number @Distance of ground below car (defines ground plane together with normal).
---@field gas number @Throttle, from 0 to 1.
---@field brake number @Brake, from 0 to 1.
---@field clutch number @Clutch, from 0 to 1 (1 for pedal fully depressed).
---@field steer number @Angle of steering wheel in degrees.
---@field handbrake number @Handbrake, from 0 to 1.
---@field gear integer @Current gear, 0 for neutral, -1 for reverse. Does not go through 0 on sequential shifts
---@field engagedGear integer @Current gear, 0 for neutral, -1 for reverse. Goes through 0 on sequential shifts
---@field fuel number @Remaining fuel in liters.
---@field rpm number @Engine RPM.
---@field rpmLimiter number @RPM limiter threshold, if exists.
---@field rpmMinimum number @Minimum RPM (or -1 if physics not available).
---@field speedKmh number @Current speed in km/h.
---@field speedMs number @Current speed in m/s.
---@field turboBoost number @Turboboost value, from 0 and upwards.
---@field drivetrainSpeed number @Speed delivered to wheels.
---@field waterTemperature number @Approximation of water temperature in °C done by original AC.
---@field minHeight number @Minimum allowed ride height in meters.
---@field restrictor number @Restrictor.
---@field ballast number @Ballast in kg.
---@field ping integer @Ping in ms (or -1 if not available).
---@field cgHeight number
---@field wheelsOutside integer @Number of wheels outside of allowed area.
---@field engineLifeLeft number @Engine life left (1000 for new engine, breaks at 0).
---@field dirt number @Body dirt level from 0 to 1.
---@field damage number[] @Damage values from 0 to maximum collision speed in km/h for four different zones (fifth one is not really used). 5 items, starts with 0.
---@field gearboxDamage number @Gearbox damage (0 for new gearbox, 1 for non-functional).
---@field nodeIndex integer @Car index if 0 is nearest to camera, 1 is second nearest and so on.
---@field visibleIndex integer @Car index if 0 is nearest to camera and visible in main camera, 1 is second nearest visible and so on. Cars outside of main camera would have 255 here.
---@field activeLOD integer @0-based index of visible LOD.
---@field distanceToCamera number @Distance to camera in meters.
---@field splinePosition number @Position of car along the track, 0 for starting line, 1 for finishing line.
---@field driftPoints number @Drift points (calculated in any racing mode).
---@field driftInstantPoints number @Drift instant points (calculated in any racing mode).
---@field driftComboCounter integer @Drift combo counter (calculated in any racing mode).
---@field collisionDepth number @How deep is current collision, in meters (generally it’s better to use change of car speed to estimate collision intensity though, depth is much less predictable).
---@field collisionPosition vec3 @Coordinates of current collision in car space.
---@field collidedWith integer @0 for track, non-zero for cars.
---@field lapCutsCount integer @Number of lap cuts in current lap. Physics-only (see `ac.CarState.physicsAvailable`)
---@field lastLapCutsCount integer @Number of lap cuts in last lap.
---@field aiLevel number @AI level from 0 to 1 (or -1 if there is no AI).
---@field aiAggression number @AI aggression from 0 to 1 (or -1 if there is no AI).
---@field aiRainTyres number @`True` if currently AI is using rain tyres.
---@field currentSplits integer[] @Time for different splits of current lap, in milliseconds. Items start with 0. To get number of elements, use `#state.currentSplits`.
---@field lastSplits integer[] @Time for different splits of last lap, in milliseconds. Items start with 0. To get number of elements, use `#state.lastSplits`.
---@field bestSplits integer[] @Best splits times (and not splits of best lap), in milliseconds, unlike other split lists, this one is populated with zeroes for sectors without time from the start. Items start with 0. To get number of elements, use `#state.bestSplits`.
---@field bestLapSplits integer[] @Splits times of best lap (not necessarily best split times in itself), in milliseconds. Items start with 0. To get number of elements, use `#state.bestLapSplits`.
---@field wheels ac.StateWheel[] @4 items, starts with 0.
---@field extrapolatedMovement boolean @If set to false and you’re adding objects moving close to cars, use ac.CarState.timestamp to estimate dt in such a way that it would match car physics time
---@field isActive boolean @True if car is currently active (changes to `false` for disconnected cars if server does not have them visible).
---@field isConnected boolean @True if car is currently connected (cars can be disconnected online), or if car is not a remote one.
---@field isRemote boolean @True if car is controlled by another player online.
---@field isAIControlled boolean @True if car is controlled by AI (or that autopilot thing).
---@field isUserControlled boolean @True if car is controlled by user (controls could be disabled completely).
---@field isLapValid boolean @True if current lap is valid. Physics-only (see `ac.CarState.physicsAvailable`)
---@field isLastLapValid boolean @True if last lap is valid.
---@field isCameraOnBoard boolean @True if camera is inside this car.
---@field isInPitlane boolean @True if car is in pits area.
---@field isInPit boolean @True if car is parked in its pit stop place.
---@field isRetired boolean
---@field isEngineLimiterOn boolean
---@field isGearGrinding boolean
---@field hasTurningLights boolean @There could be other components linked to turn signals state, but this variable is about emissives tied to turn signals.
---@field headlightsActive boolean
---@field brakeLightsActive boolean
---@field flashingLightsActive boolean
---@field hornActive boolean
---@field focused boolean
---@field focusedOnInterior boolean
---@field useInternalAudio boolean @If `true`, `…_int` variants of audio events are used.
---@field isHidingLabels boolean @If you’re drawing a map, don’t show cars with this flag on (those would be disconnected cars or, for example, cars acting like traffic). Flag can change during the race
---@field isDriftBonusOn boolean @Drift bonus flag (calculated in any racing mode).
---@field isDriftValid boolean @Is drift valid (calculated in any racing mode).
---@field isRaceFinished boolean @Car has finished the race. Since 0.2.8, non-race sessions are never marked as finished.
---@field isDriverVisible boolean @Driver can be hidden by apps or Lua scripts too.
---@field isDriverDoorOpen boolean
---@field isDriverSeatbeltOn boolean @Same as `SEATBELT` input.
---@field hazardLights boolean
---@field turningLeftLights boolean
---@field turningRightLights boolean
---@field turningLeftOnly boolean
---@field turningRightOnly boolean
---@field lowBeams boolean @`true` if low beams switch is currently active (doesn’t depend on the state of headlights, just on the switch state).
---@field highBeams boolean @`true` if high beams are currently active (either with headlights active, or with high beams flashing).
---@field extraA boolean
---@field extraB boolean
---@field extraC boolean
---@field extraD boolean
---@field extraE boolean
---@field extraF boolean
---@field extraG boolean
---@field extraH boolean
---@field extraI boolean
---@field extraJ boolean
---@field extraK boolean
---@field extraL boolean
---@field extraM boolean
---@field extraN boolean
---@field extraO boolean
---@field extraP boolean
---@field extraQ boolean
---@field extraR boolean
---@field extraS boolean
---@field extraT boolean
---@field kersCharging boolean
---@field turningLightsActivePhase boolean
---@field justJumped boolean @Changes to `true` for a single frame when car jumps.
---@field resetCounter integer @Increases by 1 each time a car resets.
---@field kersCharge number
---@field kersInput number
---@field kersCurrentKJ number
---@field kersMaxKJ number
---@field kersLoad number
---@field distanceDrivenTotalKm number
---@field distanceDrivenSessionKm number
---@field poweredWheelsSpeed number @Can be used for speedometers if they’re not using GPS and instead use powered wheels, value in km/h.
---@field batteryVoltage number
---@field oilPressure number
---@field oilTemperature number
---@field exhaustTemperature number
---@field wiperModes integer @Number of wiper modes, no less than 1 (wipers disabled state counts like a 0th mode, all cars would have that).
---@field wiperMode integer @Stores previous active mode when wipers are disabled, but still have a loop to complete.
---@field wiperSelectedMode integer @Actual selected mode.
---@field wiperSpeed number
---@field wiperProgress number
---@field bodyWetness number @How wet is car exterior, approximation from 0 to 1 (actual wetness is in 2D map).
---@field compass number @Angle of where car is heading, from 0 to 360 (0/360 for north, 90 for east, etc.)
---@field lapTimeMs integer @Time of current lap in milliseconds.
---@field bestLapTimeMs integer @Time of best lap of this session in milliseconds.
---@field previousLapTimeMs integer @Time of last lap in milliseconds.
---@field lapCount integer @Number of completed laps in this session (within connection online), including spoiled laps.
---@field currentSector integer @0-based index of current track split.
---@field previousSectorTime integer @Time of previous split in milliseconds, or 0 if it’s a first split.
---@field racePosition integer @Position of a car in the race, 1 for first, 2 for second, etc.
---@field drivenInRace number @Distance driven in current race in meters (can be used for estimating race position, based on number of completed laps and current lap progress, in practice or qualify session resets each lap).
---@field estimatedLapTimeMs integer @Based on best lap and performance meter (delta of this lap time vs best lap time).
---@field performanceMeter number @Performance meter comparing this lap with best, seconds.
---@field performanceMeterSpeedDifferenceMs number @In AC performance app, there is that red/green bar, it shows this value.
---@field sessionLapCount integer
---@field compoundIndex integer @Index of currently selected tyre compounds.
---@field sessionID integer @Index of a car in an online race (differs from regular car index: sessionID is an index in entry list, but car.index of your car is always zero)
---@field physicsAvailable boolean @Cars in replays, or remote cars online do not have regular physics component running, so some data will be missing. Such fields are marked as physics-only in comments.
---@field speedLimiterInAction boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field absInAction boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field tractionControlInAction boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field hasUserBrakeBias boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field hasCockpitMGUHMode boolean
---@field hasCockpitERSDelivery boolean
---@field hasCockpitERSRecovery boolean
---@field drsPresent boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field drsAvailable boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field drsActive boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field kersPresent boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field kersHasButtonOverride boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field kersButtonPressed boolean @Physics-only (see `ac.CarState.physicsAvailable`)
---@field mguhChargingBatteries boolean
---@field manualPitsSpeedLimiterEnabled boolean @Returns `true` if manual pits speed limiter is currently active. Physics-only (see `ac.CarState.physicsAvailable`)
---@field userSpeedLimiterEnabled boolean @Returns `true` if custom physics speed limiter is currently active. Not the same as pit limiter (or manually operated speed limiter). Physics-only (see `ac.CarState.physicsAvailable`)
---@field autoShift boolean @Returns `true` if automatic shifting is active. Physics-only (see `ac.CarState.physicsAvailable`)
---@field autoClutch boolean @Returns `true` if auto-clutch is active. Physics-only (see `ac.CarState.physicsAvailable`)
---@field mgukDelivery integer @Starts with 0.
---@field mgukDeliveryCount integer
---@field mgukRecovery integer @From 0 to 10 (for 100%).
---@field tractionControlMode integer @0 for disabled TC. Physics-only (see `ac.CarState.physicsAvailable`)
---@field absMode integer @0 for disabled ABS. Physics-only (see `ac.CarState.physicsAvailable`)
---@field engineBrakeSettingsCount integer
---@field currentEngineBrakeSetting integer
---@field fuelPerLap number @Uses original AC fuel estimation. Zero until value is available. Physics-only (see `ac.CarState.physicsAvailable`)
---@field differentialPreload number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field differentialCoast number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field differentialPower number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field awdFrontShare number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field awdCenterLock number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field drivetrainTorque number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field drivetrainPower number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field brakeBias number @Physics-only (see `ac.CarState.physicsAvailable`)
---@field speedLimiter number @Returns pit limiter speed in km/h (80 by default unless session specified different settings) or 0 if no limit is currently active. Physics-only (see `ac.CarState.physicsAvailable`)
---@field turboBoosts number[] @Values per each turbo, up to 8 (if there are less turbos in a car, rest are zeroes). Physics-only (see `ac.CarState.physicsAvailable`) 8 items, starts with 0.
---@field turboWastegates number[] @Values per each turbo, up to 8 (if there are less turbos in a car, rest are zeroes). Physics-only (see `ac.CarState.physicsAvailable`) 8 items, starts with 0.
---@field tractionControl2 number
---@field fuelMap integer @Current fuel map preset.
---@field steerTorque number
---@field ffbSteerAssist number @Value of `STEER_ASSIST` from car.ini. Physics-only (see `ac.CarState.physicsAvailable`)
---@field ffbBase number @Value of `FFMULT` from car.ini. Physics-only (see `ac.CarState.physicsAvailable`)
---@field ffbFinal number
---@field ffbPure number
---@field ffbMultiplier number @For 100% FFB multiplier, this value is set to 1.
---@field aeroLiftFront number @Aero lift coefficient in front.
---@field aeroLiftRear number @Aero lift coefficient in rear.
---@field aeroDrag number @Aero drag coefficient.
---@field caster number @Caster angle in degrees.
---@field rideHeight number[] @0 for front, 1 for rear. 2 items, starts with 0.
---@field p2pStatus integer
---@field p2pActivations integer
---@field altitude number @Altitude in meters above sea level.
---@field ambientOcclusion number @Ambient occlusion value computed from prebaked data from track’s VAO patch. 0 for car fully shadowed (in a tunnel), 1 for car outside. Affected by WeatherFX adjustments.
---@field rawAmbientOcclusion number @Ambient occlusion value computed from prebaked data from track’s VAO patch. 0 for car fully shadowed (in a tunnel), 1 for car outside. Not affected by WeatherFX adjustments.
---@field carCamerasCount integer @Number of F6 cameras.
---@field currentPenaltyType ac.PenaltyType @Current penalty type (set only for user car).
---@field currentPenaltyParameter integer @Parameter of current penalty (role depends on penalty type).
---@field extraIconsCount integer @Extra driver icons set with `ui.UserIconsLayer()`. To draw, use `carN::special::driver::X` texture name.

---@class ac.StateLeaderboardEntry : ClassBase
---@field car ac.StateCar
---@field totalTimeMs integer
---@field bestLapTimeMs integer
---@field laps integer
---@field raceMode boolean
---@field blackFlagged boolean
---@field hasCompletedLastLap boolean

---@class ac.StateSession : ClassBase
---@field type ac.SessionType
---@field laps integer
---@field durationMinutes number
---@field isTimedRace boolean
---@field hasAdditionalLap boolean
---@field startTime number @Starting time in milliseconds (compares with `ac.SimState.time`)
---@field overtimeMs number
---@field forcedPosition integer
---@field leaderCompletedLaps integer
---@field isOver boolean
---@field leaderboard ac.StateLeaderboardEntry[] @Items start with 0. To get number of elements, use `#state.leaderboard`.

---@class ac.StateWheelPhysics : ClassBase
---@field brakeTorque number
---@field handbrakeTorque number
---@field electricTorque number
---@field feedbackTorque number
---@field angularInertia number
---@field shaftVelocity number
---@field shaftInertia number
---@field tyreCarcassTemperature number @Only available with custom physics tyres.
---@field roadTemperature number @Can vary from AC road temperature in shadows if option is enabled.
---@field discCoreTemperature number @Can vary from AC road temperature in shadows if option is enabled.

---@class ac.StateWingPhysics : ClassBase
---@field cd number @Drag coefficient (wing area is already taken into account here).
---@field cl number @Lift coefficient, negative for downforce (wing area is already taken into account here).
---@field aoa number @Angle of attack.
---@field angle number
---@field yawAngle number
---@field groundHeight number

---@class ac.StateCarPhysics : ClassBase
---@field isAvailable boolean
---@field gearRatio number
---@field finalRatio number
---@field airDensity number @Air density affected by slip stream.
---@field awd2MaxTorque number
---@field awd2CurrentLockTorque number
---@field awd2Ramp number
---@field engineInertia number
---@field drivetrainInertia number
---@field drivetrainVelocity number
---@field clutchInertia number
---@field clutchState number
---@field wheels ac.StateWheelPhysics[] @4 items, starts with 0.
---@field scriptControllerInputs number[] @256 items, starts with 0.
---@field gearRatios number[] @Items start with 0. To get number of elements, use `#state.gearRatios`.
---@field wings ac.StateWingPhysics[] @Items start with 0. To get number of elements, use `#state.wings`.

---@class ac.StateSim : ClassBase
---@field windowWidth integer @Width of AC window in pixels (set in AC video settings). Might not be the same as UI screen size if scaling is used.
---@field windowHeight integer @Height of AC window in pixels (set in AC video settings). Might not be the same as UI screen size if scaling is used.
---@field msaaSamples integer @1 for MSAA disabled, 2 for MSAA 2x, 4 for 4x, 8 for 8x.
---@field worldDetailLevel integer @0 for very low, 5 for very high. Set in AC video settings
---@field isFullscreen boolean @A value from AC video settings, does not change live.
---@field isVSyncActive boolean @A value from AC video settings, does not change live.
---@field isPostProcessingActive boolean @True if YEBIS post-processing is active.
---@field isVRMode boolean @True if AC was launched with either Oculus or OpenVR mode (not necessarily successfully connected).
---@field isOculusMode boolean @True if AC was launched with Oculus mode (not necessarily successfully connected).
---@field isOpenVRMode boolean @True if AC was launched with OpenVR mode (not necessarily successfully connected).
---@field isTripleMode boolean @True if AC was launched in triple screen mode.
---@field isCustomVideoMode boolean @True if AC was launched with custom screen mode (fisheye, 360°, splitscreen).
---@field isVRConnected boolean @True if AC runs in either Oculus or OpenVR mode and initialization went successfully.
---@field staticReflections boolean @True if reflection cubemap does not update live and uses custom cubemap.kn5 instead of track model
---@field directMessagingAvailable boolean @True if it’s an online race and server supports TCP exchange of extra data between clients (allows to send online events more frequently).
---@field directUDPMessagingAvailable boolean @True if it’s an online race and server supports UDP exchange of extra data between clients (allows to send UDP online events).
---@field allowTyreBlankets boolean
---@field isReplayOnlyMode boolean @True if AC is ran in replay mode, without any racing.
---@field isOnlineRace boolean @True if it’s an online race.
---@field isShowroomMode boolean @True if AC has been launched in showroom mode.
---@field isPreviewsGenerationMode boolean @True if AC has been launched to generate previews.
---@field freeCameraAllowed boolean @Can be changed in AC video settings.
---@field isPitsSpeedLimiterForced boolean @By default `true`, but servers or offline races can alter session settings and disable this thing.
---@field customAISplinesAllowed boolean @Switches to `false` if `physics.setAISpline()` is not allowed in this session
---@field isFSRActive boolean
---@field isTripleFSRActive boolean
---@field isLinearColorSpaceActive boolean
---@field allowedTyresOut integer
---@field resultScreenTime number @Results screen time in seconds (available online, -1 offline).
---@field raceOverTime number @Race over time in seconds (available online, -1 offline).
---@field mechanicalDamageRate number @In 0…1 range.
---@field tyreConsumptionRate number @In 0…1 range.
---@field fuelConsumptionRate number @In 0…1 range.
---@field gravity number @Negative value (pointing down), -9.81 in pretty much all cases (custom gravity might be enabled though)
---@field inputMode ac.UserInputMode @Input mode selected by user.
---@field windowHandle integer @Main window handle.
---@field currentVAOMode ac.VAODebugMode
---@field neutralSunTrajectoryTimestamp integer @Timestamp for sun trajectory used with seasons disabled.
---@field isMakingScreenshot boolean @If `true`, currently AC is doing an accumulation screenshot. You won’t be able to move camera, grabbed camera will be paused, replay position seeking and more will be postponed, but ideally just don’t do things that could mess up a screenshot in this mode.
---@field time number @Time in milliseconds counting from the start of Assetto Corsa.
---@field gameTime number @Time in seconds counting from the start of Assetto Corsa (same as .time, but divided by 1000, kept for compatibility)
---@field systemTime integer @System timestamp (time in seconds), pretty much the same as os.time()
---@field frame integer @Index of a current render frame.
---@field cameraPosition vec3
---@field cameraPositionDelta vec3 @How much camera has moved since the previous render step.
---@field cameraLook vec3 @Points forward (there was some confusion with older API).
---@field cameraUp vec3
---@field cameraSide vec3
---@field cameraFOV number @Returns current camera FOV in degrees. In VR, always returns 90°
---@field cameraClipNear number @Distance to near clipping plane in meters.
---@field cameraClipFar number @Distance to far clipping plane in meters.
---@field cameraDOFFactor number
---@field cameraDOFFocus number
---@field cameraExposure number
---@field exposureMultiplier number @One controllable by Page Up/Page Down.
---@field carsCount integer @No less than 1: at least a single car would always be present.
---@field closelyFocusedCar integer @0-based index, or -1 if there is no focused car (for example, with track camera or with free camera far from other cars).
---@field focusedCar integer @0-based index, or -1 if there is no focused car, unlike `.closelyFocusedCar` returns index of a car with track camera as well
---@field dt number @Delta time in seconds, 0 when paused, affected by replay slow motion and fast forwarding.
---@field isPaused boolean @If `true`, AC is currently paused.
---@field isInMainMenu boolean @If `true`, main menu is currently active.
---@field isLookingAtSessionResults boolean @If `true`, session results are being shown.
---@field needsDPad boolean @If `true`, D-pad buttons are not used by their main bindings, but instead used by things like Quick Pits menu.
---@field isLive boolean @If `true`, simulation is currently running (not paused and not in replay mode).
---@field isFreeCameraOutside boolean @Set to `true` if camera is either free or orbit (F7/F5) and not inside an interior.
---@field isReplayActive boolean
---@field isFocusedOnInterior boolean @True if camera is currently inside a car.
---@field isTripleScreenAvailable boolean @True if current camera allows for triple screen view.
---@field controlsWithShifter boolean @True if current control scheme is using H-shifter.
---@field isVirtualMirrorActive boolean
---@field hideSteeringWheel boolean @True if hiding steering wheel option is active.
---@field hideArmsInCockpit boolean @True if hiding arms in cockpit option is active.
---@field isVirtualMirrorForced boolean
---@field isWindowForeground boolean @True if AC window is currently active (focused and in front of other windows).
---@field isWeatherFXActive boolean
---@field isVAOPatchLoaded boolean
---@field orbitOnboardCamera boolean @True if F5 camera acts as an orbit camera.
---@field cameraJumped boolean @True if camera has just suddenly moved.
---@field ambientLightingMultiplier number
---@field ambientTemperature number
---@field lightSuggestion number @If WeatherFX style thinks it’s a good time to turn on headlights, this value will increase to 1, otherwise 0.
---@field roadTemperature number
---@field roadGrip number @Current track grip from 0 to 1.
---@field windSpeedKmh number
---@field windVelocityKmh vec2 @Wind velocity relative to game space.
---@field windDirectionDeg number @Wind direction in real world space (taking track heading angle into account).
---@field rainIntensity number
---@field rainWetness number
---@field rainWater number
---@field timeTotalSeconds number @Number of seconds from midnight, not rounded.
---@field timeHours integer @Number of hours from midnight, rounded down.
---@field timeMinutes integer @Number of minutes in current hour, rounded down.
---@field timeSeconds integer @Number of seconds in current minute, rounded down.
---@field timeMultiplier number @Time multiplier set in race conditions.
---@field timestamp integer @Timestamp for in-game time (whole number seconds since 01/01/1970 within current timezone, not in UTC0).
---@field dayOfYear integer @Returns number of current day in the year, from 1 to 366.
---@field raceFlagType ac.FlagType
---@field raceFlagCause integer @0-based index of a car that triggered blue or yellow flag, or -1.
---@field isSessionStarted boolean
---@field isSessionFinished boolean
---@field raceSessionType ac.SessionType @Type of current session.
---@field timeToSessionStart number @Time to session start in milliseconds.
---@field sessionTimeLeft number @Remaining session time in milliseconds.
---@field currentSessionIndex integer @0-based index of current session (`.sessions` store more details about each session)
---@field sessionsCount integer
---@field leaderLapCount integer @Not available in replays yet (returns 0).
---@field trackLengthM number
---@field speedLimitKmh number
---@field fps number
---@field fpsCapped number
---@field physicsLate number
---@field cpuOccupancy integer
---@field cpuTime number
---@field firstPersonCameraFOV number @Current value for first person camera FOV in degrees. Global value, applying for all cars.
---@field cameraMode ac.CameraMode
---@field driveableCameraMode ac.DrivableCamera
---@field carCameraIndex integer @0-based index of currently active car camera (if `.cameraMode` is set to `ac.CameraMode.Car`). To find out how many ofd those cameras there are, use `ac.getCar(sim.focusedCar).carCamerasCount`
---@field trackCamerasSetsCount integer
---@field trackCamerasSet integer @0-based index of currently active track cameras set.
---@field audioMasterVolume number
---@field whiteReferencePoint number @Brightness of objects that would look white on-screen, such as UI in VR or driver name tags. You can also use it as a divider to adjust brightness of virtual mirrors (if you are not using postprocessing for virtual mirrors).
---@field specialEvent boolean @One of those archievment challenges is active.
---@field isTimedRace boolean
---@field penaltiesEnabled boolean
---@field fixedSetup boolean
---@field leaderLastLap boolean
---@field timeRaceEnded boolean
---@field timeRaceLastLap boolean
---@field timeRaceAdditionalLap boolean
---@field idealLineShown boolean
---@field damageDisplayerShown boolean
---@field driverNamesShown boolean
---@field isAdmin boolean @Changes to true if user signs up as admin using that new chat app.
---@field sentAdminCommand boolean @Changes to true once user sends a command starting with “/admin”.
---@field pitsSpeedLimit number @Maximum speed allowed in pits in km/h. Regular value is 80, but servers might change it
---@field pitWindowStartTime number @If non-zero, start of mandatory pit time window (to get current time, use `.time`)
---@field pitWindowEndTime number @If non-zero, end of mandatory pit time window (to get current time, use `.time`)
---@field replayFrameMs number @Time of each replay frame in milliseconds.
---@field timeSinceLastUDPPacket number @Time since last UDP packet in seconds. Returns -1 outside of online session (change in CSP 0.2.7).
---@field replayFrames integer @Number of recorded replay frames.
---@field replayCurrentFrame integer @0-based index of current replay frame.
---@field replayPlaybackRate number @0-based index of current replay frame.
---@field weatherType ac.WeatherType @Current weather type, set by WeatherFX controller or guessed from weather name.
---@field weatherSkyOcclusion number @Estimates sky occlusion based on current weather type.
---@field baseAltitude number @Altitude in meters above sea level associated with Y=0 level.
---@field currentQuickPitPreset integer @0-based index of selected Quick Pits menu preset.
---@field connectedCars integer @Number of currently connected cars.
---@field randomSeed integer @Synced between clients online.
---@field equinoxSunTrajectory boolean @True if sun moves as if current date is 20th of March rather than the actual date (used with seasons disabled).
---@field explicitDateSet boolean @True if explicit date is set (usually activates seasons if their behavior is set to default “automatic”).
---@field lapSplits number[] @Normalized positions of track splits. Items start with 0. To get number of elements, use `#state.lapSplits`.
---@field handshakeServerTime number @Server time of the handshake, in milliseconds.
---@field currentServerTime number @Current server time (synced on all clients), in milliseconds. Resets to 0 when new race session (P/Q/R) starts. 0 in offline races.
---@field currentSessionTime number @Current session time (synced on all clients), in milliseconds. Resets to 0 when new race session (P/Q/R) starts. Not 0 in online sessions. Might be negative before a session start.
---@field skyColor rgb @Sky color.
---@field horizonColor rgb @Horizon color.
---@field fogColor rgb @Fog color.
---@field lightColor rgb @Light (sun or moon) color.
---@field lightDirection vec3 @Light (sun or moon) direction.
---@field weatherConditions ac.ConditionsSet @Weather conditions after a sanity check filter.

---@class ac.StateUi : ClassBase
---@field windowSize vec2 @Size of AC UI window (affected by UI scale).
---@field mousePos vec2 @Mouse position within an AC UI window (affected by UI scale).
---@field dt number @Time between frames in seconds (not affected by pausing or replay speed modifier).
---@field mouseWheel number @Mouse wheel Vertical: 1 unit scrolls about 5 lines text.
---@field isMouseLeftKeyClicked boolean @Left mouse button was just pressed.
---@field isMouseMiddleKeyClicked boolean @Middle mouse button was just pressed.
---@field isMouseRightKeyClicked boolean @Right mouse button was just pressed.
---@field isMouseLeftKeyDoubleClicked boolean @Left mouse button was just double clicked.
---@field isMouseMiddleKeyDoubleClicked boolean @Middle mouse button was just double clicked.
---@field isMouseRightKeyDoubleClicked boolean @Right mouse button was just double clicked.
---@field isMouseLeftKeyDown boolean @Left mouse button is currently held.
---@field isMouseMiddleKeyDown boolean @Middle mouse button is currently held.
---@field isMouseRightKeyDown boolean @Right mouse button is currently held.
---@field ctrlDown boolean @Keyboard modifier pressed: Control.
---@field shiftDown boolean @Keyboard modifier pressed: Shift.
---@field altDown boolean @Keyboard modifier pressed: Alt.
---@field superDown boolean @Keyboard modifier pressed: Cmd/Super/Windows.
---@field wantCaptureMouse boolean @If your script is listening to mouse events, you might need to disable this functionality if this value is `true` — it means mouse is currently captured by some IMGUI element (for example, dragging happens).
---@field wantCaptureKeyboard boolean @If your script is listening to keyboard events, you might need to disable this functionality if this value is `true` — it means keyboard is currently captured by some IMGUI element (for example, user enters text in a text box).
---@field vrController boolean @If true, mouse is currenly controlled by VR controller, so its precision might be lower.
---@field appsHidden boolean @True if apps are hidden by Ctrl+H hotkey, with a GUI module setting, by a Lua script getting exclusive access over it.
---@field uiHidden boolean @True if UI is hidden with a GUI module setting or by a Lua script getting exclusive access over it.
---@field framerate number @UI framerate estimation, in frame per second. Solely for convenience. Rolling average estimation based on IO.DeltaTime over 120 frames
---@field metricsRenderVertices integer @Vertices output during last call to Render().
---@field metricsRenderIndices integer @Indices output during last call to Render() = number of triangles * 3.
---@field metricsRenderWindows integer @Number of visible windows.
---@field metricsActiveWindows integer @Number of active windows.
---@field metricsRenderCommands integer @Number of draw calls.
---@field mouseDelta vec2 @Mouse delta. Note that this is zero if either current or previous position are invalid (-FLT_MAX,-FLT_MAX), so a disappearing/reappearing mouse won't have a huge delta.
---@field uiScale number @UI scale. Usually scripts shouldn’t worry about it, but just in case
---@field accentColor rgbm @Theme-defined accent color.
---@field currentDesktop integer @Current desktop, from 0 to 3.

---@class ac.StateTripleItem : ClassBase
---@field left vec2
---@field right vec2
---@field height number
---@field xFrom number
---@field xTo number
---@field xWidth number

---@class ac.StateTriple : ClassBase
---@field screens ac.StateTripleItem[] @3 items, starts with 0.

---@class ac.StateVRHand : ClassBase
---@field transform mat4x4
---@field triggerIndex number
---@field triggerHand number
---@field thumbstick vec2
---@field active boolean
---@field thumbUp boolean
---@field indexPointing boolean
---@field busy boolean @Set to true if hand is already going something, like grabbing an object. If so, don’t do any more grabbing (and don’t forget to call `ac.setVRHandBusy()` when you do)
---@field openVRButtons integer @OpenVR-specific buttons.
---@field openVRTouches integer @OpenVR-specific touches.
---@field openVRAxis vec2[] @OpenVR-specific touches. 5 items, starts with 0.

---@class ac.StateVR : ClassBase
---@field headTransform mat4x4
---@field headActive boolean
---@field oculusButtons integer @Oculus-specific buttons.
---@field oculusTouches integer @Oculus-specific touches.
---@field activeHand integer @Index of a hand that is actively moving, or -1.
---@field hands ac.StateVRHand[] @2 items, starts with 0.

---@class ac.StateTrackir : ClassBase
---@field position vec3
---@field rotation vec3

---@class ac.StateDualsenseTouch : ClassBase
---@field delta vec2
---@field pos vec2
---@field id integer
---@field down boolean

---@class ac.StateDualsense : ClassBase
---@field accelerometer vec3
---@field gyroscope vec3
---@field battery number
---@field touches ac.StateDualsenseTouch[] @2 items, starts with 0.
---@field batteryCharging boolean
---@field batteryFullyCharged boolean
---@field headphonesConnected boolean
---@field connected boolean

---@class ac.StateDualsenseOutput : ClassBase
---@field lightBar rgbm
---@field microphoneLED integer @0 for disabled, 1 for enabled, 2 for flashing.
---@field playerLEDsBrightness integer @0 for max, 1 for medium, 2 for low.
---@field disableLEDs boolean
---@field playerLEDsFade boolean
---@field playerLEDs boolean[] @5 items, starts with 0.

---@class ac.StateDualshockTouch : ClassBase
---@field delta vec2
---@field pos vec2
---@field id integer
---@field down boolean

---@class ac.StateDualshock : ClassBase
---@field type ac.GamepadDualShockType
---@field deviceColor rgbm @Only for Nintendo devices.
---@field accelerometer vec3
---@field gyroscope vec3
---@field battery number @Might not provide accurate values for some devices.
---@field batteryCharging boolean @Might not provide accurate values for some devices.
---@field batteryFullyCharged boolean @Might not provide accurate values for some devices.
---@field usbConnected boolean @Might not provide accurate values for some devices.
---@field touches ac.StateDualshockTouch[] @2 items, starts with 0.
---@field connected boolean

---@class ac.StateDualshockOutput : ClassBase
---@field lightBar rgbm
---@field playerNumber integer @Player number.

---@class ac.StateXboxOutput : ClassBase
---@field triggerLeft number @Left trigger vibration.
---@field triggerRight number @Right trigger vibration.

---UI namespace for creating custom widgets or drawing dynamic textures using IMGUI. You can use it to draw things on textures and such, not just for UI.
ui = {}

--[[ common/debug.lua ]]

---Displays value in Lua Debug app, great for tracking state of your values live.
---@param key string
---@param value any?
---@overload fun(key: string, value: number, min: number?, max: number?, collect: integer?, collectMode: ac.DebugCollectMode?) @Variant with fixed range for a graph in Lua Debug app. Set `collect` to a value above 1 if you need Lua Debug App to combine a few values so that graph would move slower. Parameter `collectMode` can specify the way in which values will be combined.
function ac.debug(key, value) end

--[[ common/debug.lua ]]

---Prints a message to a CSP log and to Lua App Debug log. To speed things up and only use Lua Debug app, call `ac.setLogSilent()`.
---@param ... string|number|boolean @Values.
function ac.log(...) end

---Prints a warning message to a CSP log and to Lua App Debug log. To speed things up and only use Lua Debug app, call `ac.setLogSilent()`.
---@param ... string|number|boolean @Values.
function ac.warn(...) end

---Prints an error message to a CSP log and to Lua App Debug log. To speed things up and only use Lua Debug app, call `ac.setLogSilent()`.
---@param ... string|number|boolean @Values.
function ac.error(...) end

---For compatibility, acts similar to `ac.log()`.
function print(...) end

--[[ common/common_base.lua ]]

---Disposable thing is something set which you can then un-set. Just call `ac.Disposable` returned
---from a function to cancel out whatever happened there. For example, unsubscribe from an event.
---@alias ac.Disposable fun()

---Calls a function in a safe way, catching errors. If any errors were to occur, `catch` would be
---called with an error message as an argument. In either case (with and without error), if provided,
---`finally` will be called.
---
---Does not raise errors unless errors were thrown by `catch` or `finally`. Before CSP 0.2.5, if `catch`
---throws an error, `finally` wouldn’t be called (fixed in 0.2.5).
---@generic T
---@param fn fun(): T?
---@param catch fun(err: string)|nil @If not set, error won’t propagate anyway.
---@param finally fun()|nil
---@return T|nil
function try(fn, catch, finally) end

---Calls a function and then calls `dispose` function. Note: `dispose` function will be called even if
---there would be an error in `fn` function. But error would not be contained and will propagate.
---
---Any error thrown by `fn()` will be raised and not captured, but `dispose()` will be called either way.
---@generic T
---@param fn fun(): T?
---@param dispose fun()? @CSPs before 0.2.5 require non-nil argument.
---@return T|nil
function using(fn, dispose) end

---Resolves relative path to a Lua module (relative to Lua file you’re running this function from)
---so it would be ready to be passed to `require()` function.
---
---Note: performance might be a problem if you are calling it too much, consider caching the result.
---@param path string
---@return string
function package.relative(path) end

---Resolves relative path to a file (relative to Lua file you’re running this function from)
---so it would be ready to be passed to `io` functions (returns full path).
---
---Note: performance might be a problem if you are calling it too much, consider caching the result.
---@param path string
---@return string
function io.relative(path) end

---Given an FFI struct and a string of data, fills struct with that data. Works only if size of struct matches size of data. Data string can contain zeroes.
---@generic T
---@param destination T @FFI struct (type should be “cdata”).
---@param data binary @String with binary data.
---@return T
function ac.fillStructWithBytes(destination, data) end

---Fills a string of an FFI struct with data up to a certain size. Make sure to not overfill the data.
---@param src string @String to copy.
---@param dst string @A `const char[N]` field of a struct.
---@param size integer @Size of `const char[N]` field (N).
function ac.stringToFFIStruct(src, dst, size) end

---Returns ordered list of data file names (not full paths, just the names) of a certain car. Works for both packed and unpacked cars. If failed,
---returns empty list.
---@param index integer @0-based car index.
---@return string[]
function ac.getCarDataFiles(index) end

---Returns list of car colliders.
---@param index integer @0-based car index.
---@param actualColliders boolean? @Set to `true` to draw actual physics colliders (might differ due to some physics alterations).
---@return {position: vec3, size: vec3}[]
function ac.getCarColliders(index, actualColliders) end

--[[ common/common.lua ]]

---Stores value in session shared Lua/Python storage. This is not a long-term storage, more of a way for
---different scripts to exchange data. Note: if you need to exchange a lot of data between Lua scripts,
---consider using ac.connect instead.
---
---Data string can contain zeroes.
---@param key string
---@param value string|number
function ac.store(key, value) end

---Reads value from session shared Lua/Python storage. This is not a long-term storage, more of a way for
---different scripts to exchange data. Note: if you need to exchange data between Lua scripts,
---use `ac.connect()` instead. And if despite that you need to exchange data between car scripts, make sure to add
---car index to the key.
---@param key string
---@return nil|string|number
function ac.load(key) end

---Adds a callback which might be called when script is unloading. Use it for some state reversion, but
---don’t rely on it too much. For example, if Assetto Corsa would crash or just close rapidly, it would not
---be called. It should be called when scripts reload though.
---@generic T
---@param callback fun(item: T)
---@param item T? @Optional parameter. If provided, will be passed to callback on release, but stored with a weak reference, so it could still be GCed before that (in that case, callback won’t be called at all).
---@return fun() @Call to disable callback.
function ac.onRelease(callback, item) end

---For easy import of scripts from subdirectories. Provide it a name of a directory relative
---to main script folder and it would add that directory to paths it searches for.
---@param dir string
function package.add(dir) end

---Sets a callback which will be called when server welcome message and extended config arrive.
---@param callback fun(message: string, config: ac.INIConfig) @Callback function.
---@return ac.Disposable
function ac.onOnlineWelcome(callback) end

--[[ common/const.lua ]]

---Does nothing, but with preprocessing optimizations inlines value as constant.
---@generic T
---@param value T
---@return T
function const(value) end

--[[ common/ac_matrices.lua ]]

---Creates a new neutral matrix.
---@return mat3x3
function mat3x3.identity() end

---@param row1 vec3? 
---@param row2 vec3? 
---@param row3 vec3? 
---@return mat3x3
function mat3x3(row1, row2, row3) end

---@class mat3x3
---@field row1 vec3
---@field row2 vec3
---@field row3 vec3
local mat3x3 = nil

---@param value mat3x3
---@return mat3x3
function mat3x3:set(value) end

---@return mat3x3
function mat3x3:clone() end

---Creates a new neutral matrix.
---@return mat4x4
function mat4x4.identity() end

---Creates a translation matrix.
---@param offset vec3
---@return mat4x4
function mat4x4.translation(offset) end

---Creates a rotation matrix.
---@param angle number @Angle in radians.
---@param axis vec3
---@return mat4x4
function mat4x4.rotation(angle, axis) end

---Creates a rotation matrix from Euler angles in radians.
---@param head number
---@param pitch number
---@param roll number
---@return mat4x4
function mat4x4.euler(head, pitch, roll) end

---Creates a scaling matrix.
---@param scale vec3
---@return mat4x4
function mat4x4.scaling(scale) end

---Creates a look-at matrix from position and directional vectors. Ensures all vectors are properly normalized.
---@param position vec3
---@param look vec3
---@param up vec3? @Default value: `vec3(0, 1, 0)`.
---@return mat4x4
function mat4x4.look(position, look, up) end

---Creates a perspective matrix.
---@param fovY number @Vertical view angle in radians.
---@param aspect number @Aspect ratio.
---@param zNear number @Near clipping plane.
---@param zFar number @Far clipping plane.
---@return mat4x4
function mat4x4.perspective(fovY, aspect, zNear, zFar) end

---Creates an orthogonal matrix. Might act unexpected with Z values, shifting by range should help.
---@param extentMin vec3
---@param extentMax vec3
---@return mat4x4
function mat4x4.ortho(extentMin, extentMax) end

---@param row1 vec4? 
---@param row2 vec4? 
---@param row3 vec4? 
---@param row4 vec4? 
---@return mat4x4
function mat4x4(row1, row2, row3, row4) end

---@class mat4x4
---@field row1 vec4
---@field row2 vec4
---@field row3 vec4
---@field row4 vec4
---@field position vec3
---@field look vec3
---@field side vec3
---@field up vec3
local mat4x4 = nil

---@param value mat4x4
---@return mat4x4
function mat4x4:set(value) end

---@param destination vec3
---@param vec vec3
---@return vec3
function mat4x4:transformVectorTo(destination, vec) end

---@param vec vec3
---@return vec3
function mat4x4:transformVector(vec) end

---@param destination vec4
---@param vec vec4
---@return vec4
function mat4x4:transformTo(destination, vec) end

---@param vec vec4
---@return vec4
function mat4x4:transform(vec) end

---@param destination vec3
---@param vec vec3
---@return vec3
function mat4x4:transformPointTo(destination, vec) end

---@param vec vec3
---@return vec3
function mat4x4:transformPoint(vec) end

---@return mat4x4
function mat4x4:clone() end

---Creates a new matrix.
---@return mat4x4
function mat4x4:inverse() end

---Modifies current matrix.
---@return mat4x4 @Returns self for easy chaining.
function mat4x4:inverseSelf() end

---Creates a new matrix.
---@return mat4x4
function mat4x4:normalize() end

---Modifies current matrix.
---@return mat4x4 @Returns self for easy chaining.
function mat4x4:normalizeSelf() end

---Creates a new matrix.
---@return mat4x4
function mat4x4:transpose() end

---Modifies current matrix.
---@return mat4x4 @Returns self for easy chaining.
function mat4x4:transposeSelf() end

---Note: unlike vector’s `:mul()`, this one creates a new matrix!
---@param other mat4x4
---@return mat4x4
function mat4x4:mul(other) end

---Modifies current matrix.
---@param other mat4x4
---@return mat4x4 @Returns self for easy chaining.
function mat4x4:mulSelf(other) end

---Writes result into a separate matrix.
---@param destination mat4x4
---@param other mat4x4
---@return mat4x4 @Returns destination matrix.
function mat4x4:mulTo(destination, other) end

--[[ common/math.lua ]]

---Takes value with even 0…1 distribution and remaps it to recreate a distribution
---similar to Gaussian’s one (with k≈0.52, a default value). Lower to make bell more
---compact, use a value above 1 to get some sort of inverse distibution.
---@param x number @Value to adjust.
---@param k number @Bell curvature parameter.
---@return number
function math.gaussianAdjustment(x, k) end

---Builds a list of points arranged in a square with poisson distribution.
---@param size integer @Number of points.
---@param tileMode boolean? @If set to `true`, resulting points would be tilable without breaking poisson distribution.
---@return vec2[]
function math.poissonSamplerSquare(size, tileMode) end

---Builds a list of points arranged in a circle with poisson distribution.
---@param size integer @Number of points.
---@return vec2[]
function math.poissonSamplerCircle(size) end

---Generates a random number in [0, INT32_MAX) range. Can be a good argument for `math.randomseed()`.
---@return integer
function math.randomKey() end

---Generates random number based on a seed.
---@param seed integer|boolean|string @Seed.
---@return number @Random number from 0 to 1.
function math.seededRandom(seed) end

---Rounds number, leaves certain number of decimals.
---@param number number
---@param decimals number? @Default value: 0 (rounding to a whole number).
---@return integer
function math.round(number, decimals) end

---Clamps a number value between `min` and `max`.
---@param value number
---@param min number
---@param max number
---@return number
function math.clampN(value, min, max) end

---Clamps a number value between 0 and 1.
---@param value number
---@return number
function math.saturateN(value) end

---Clamps a copy of a vector between `min` and `max`. To avoid making copies, use `vec:clamp(min, max)`.
---@generic T
---@param value T
---@param min any
---@param max any
---@return T
function math.clampV(value, min, max) end

---Clamps a copy of a vector between 0 and 1. To avoid making copies, use `vec:saturate()`.
---@generic T
---@param value T
---@return T
function math.saturateV(value) end

---Clamps value between `min` and `max`, returning `min` if `x` is below `min` or `max` if `x` is above `max`. Universal version, so might be slower.
---Also, if given a vector or a color, would make a copy of it.
---@generic T
---@param x T
---@param min any
---@param max any
---@return T
function math.clamp(x, min, max) end

---Clamps value between 0 and 1, returning 0 if `x` is below 0 or 1 if `x` is above 1. Universal version, so might be slower.
---Also, if given a vector or a color, would make a copy of it.
---@generic T
---@param x T
---@return T
function math.saturate(x) end

---Returns a sing of a value, or 0 if value is 0.
---@param x number
---@return integer
function math.sign(x) end

---Linear interpolation between `x` and `y` using `mix` (x * (1 - mix) + y * mix).
---@generic T
---@param x T
---@param y T
---@param mix number
---@return T
function math.lerp(x, y, mix) end

---Returns 0 if value is less than v0, returns 1 if it’s more than v1, linear interpolation in-between.
---@param value number
---@param min number
---@param max number
---@return number
function math.lerpInvSat(value, min, max) end

---Returns `newA` if `value` equals to `oldA`, `newB` if `value` is `oldB`, applies linear interpolation for other input values. Doesn’t apply clamping.
---@param value number
---@param oldA number
---@param oldB number
---@param newA number
---@param newB number
---@return number
function math.remap(value, oldA, oldB, newA, newB) end

---Smoothstep operation. More about it in [wiki](https://en.wikipedia.org/wiki/Smoothstep).
---@param x number
---@return number
function math.smoothstep(x) end

---Like a smoothstep operation, but even smoother.
---@param x number
---@return number
function math.smootherstep(x) end

---Creates a copy of a vector and normalizes it. Consider using a method `vec:normalize()` instead when you can change the original vector to save on performanceMeter.
---@generic T
---@param x T
---@return T
function math.normalize(x) end

---Creates a copy of a vector and runs a cross product on it. Consider avoiding making a copy with `vec:cross(otherVec)`.
---@param x vec3
---@return vec3
function math.cross(x, y) end

---Calculates dot product of two vectors.
---@param x vec2|vec3|vec4
---@return number
function math.dot(x, y) end

---Calculates angle between vectors in radians.
---@param x vec2|vec3|vec4
---@return number @Radians.
function math.angle(x, y) end

---Calculates distance between vectors.
---@param x vec2|vec3|vec4
---@return number
function math.distance(x, y) end

---Calculates squared distance between vectors (slightly faster without taking a square root).
---@param x vec2|vec3|vec4
---@return number
function math.distanceSquared(x, y) end

---Creates a copy of a vector and projects it onto a different vector. Consider avoiding making a copy with `vec:project(otherVec)`.
---@generic T
---@param x T
---@return T
function math.project(x, y) end

---Checks if value is not-a-number.
---@param x number
---@return boolean
function math.isnan(x) end

---Checks if value is positive or negative infinity.
---@param x number
---@return boolean
function math.isinf(x) end

---Checks if value is finite (not infinite or nan).
---@param x number
---@return boolean
function math.isfinite(x) end

---@type number
math.nan = 0/0

---@type number
math.tau = math.pi * 2

---@deprecated Use math.isnan instead.
function math.isNaN(x) end

---@deprecated Use math.nan instead.
math.NaN = 0/0

---@param lag number
---@param dt number
---@return number
function math.lagMult(lag, dt) end

---Perlin noise for given input. Returns value within -1…1 range, or outside of it if `octaves` is above 1. If you’re using octaves, make sure `input`
---won’t overflow when being multiplied by two multiple times.
---@param input number|vec2|vec3
---@param octaves integer? @Pass number greater than 1 to generate octave noise instead (sum `octaves` noise functions together increasing input and multiplying amplitude by `persistence` each step). Default value: 1.
---@param persistence number? @Persistance for octave noise. Used only if `octaves` is above 1. Default value: 0.5.
---@return number
function math.perlin(input, octaves, persistence) end

---Roughly convert HDR value to LDR using conversion hints provided by current WeatherFX style. Doesn’t apply nothing like tonemapping or exposure
---correction, simply adjusts for a case where WeatherFX style uses small brightness multiplier or linear color space.
---
---Note: shaders have the same function called `convertHDR()`.
---@generic T: number|rgb|rgbm
---@param input T @Value to convert.
---@param toLDR boolean? @Pass `true` to do the reverse and convert LDR to HDR. Default value: `false`.
---@return T
function math.convertHDR(input, toLDR) end

---@generic T : number|vec2|vec3|vec4
---@param value T
---@param target T
---@param lag number
---@param dt number
---@return T
function math.applyLag(value, target, lag, dt) end

--[[ common/string.lua ]]

---Function won’t work: while CSP tries its best to guarantee API compatibility, ABI compatibility is not a priority at all,
---and the underlying LuaJIT implementation frequently changes and might even be replaced with something else in the future.
---@return nil
function string.dump() return nil end

---Splits string into an array using separator.
---@param self string @String to split.
---@param separator string? @Separator. If empty, string will be split into individual characters. Default value: ` `.
---@param limit integer? @Limit for pieces of string. Once reached, remaining string is put as a list piece.
---@param trimResult boolean? @Set to `true` to trim found strings. Default value: `false`.
---@param skipEmpty boolean? @Set to `false` to keep empty strings. Default value: `true` (for compatibility reasons).
---@param splitByAnyChar boolean? @Set to `true` to split not by a string `separator`, but by any characters in `separator`.
---@return string[]
function string.split(self, separator, limit, trimResult, skipEmpty, splitByAnyChar) end

---Splits string into a bunch of numbers (not in an array). Any symbol that isn’t a valid part of number is considered to be a delimiter. Does not create an array
---to keep things faster. To make it into an array, simply wrap the call in `{}`.
---@param self string @String to split.
---@param limit integer? @Limit for amount of numbers. Once reached, remaining part is ignored.
---@return ... @Numbers
function string.numbers(self, limit) end

---Pack things. For format, see <https://www.lua.org/manual/5.3/manual.html#6.4.2>.
---Use `a` for half-precision floating point value (two bytes).
---@param self string @Format string.
---@return string
function string.pack(self, ...) end

---Measure size of packed things. For format, see <https://www.lua.org/manual/5.3/manual.html#6.4.2>.
---Use `a` for half-precision floating point value (two bytes).
---@param self string @Format string.
---@return integer
function string.packsize(self) end

---Unpack things. For format, see <https://www.lua.org/manual/5.3/manual.html#6.4.2>.
---Use `a` for half-precision floating point value (two bytes).
---@param self string @Format string.
---@return ...
function string.unpack(self) end

---Checks if string starts with an URL or not. Uses flexible parsing scheme so even URLs not starting with
---a scheme could be found.
---@param self string @Target string.
---@param offset integer? @Starting search index, 1-based.
---@return integer? @Returns length of URL, or `nil` if string is not an URL.
function string.urlCheck(self, offset) end

---Finds next URL in a string. Uses flexible parsing scheme so even URLs not starting with
---a scheme could be found.
---@param self string @Target string.
---@param offset integer? @Starting search index, 1-based.
---@return integer? @First returned value is 1-based index of URL start.
---@return integer? @Second returned value is 1-based index of URL end (both arguments can be passed to `string.sub()` to cut out the URL).
function string.urlNext(self, offset) end

---Works like string.find with plain mode, but ignores case.
---@param self string @String to find `needle` in.
---@param needle string @String to find.
---@param index integer? @Starting search index. Default value: `1`.
---@return integer? @1-based index of a first match, or `nil` if nothing has been found.
function string.findIgnoreCase(self, needle, index) end

---Searches and replaces all the substrings.
---@param self string @String to find `replacee` and replace with `replacer` in.
---@param replacee string @String to find.
---@param replacer string? @String to replace. Default value: ``.
---@param limit integer? @Maximum number of found strings to replace. Default value: `math.huge`.
---@param ignoreCase boolean? @Option for case-incensitive search. Default value: `false`.
---@return string, integer @Second value returned is for the number of replacements.
function string.replace(self, replacee, replacer, limit, ignoreCase) end

---Returns UTF8 string for a corresponding code point.
---@param codePoint integer
---@return string
function string.codePointToUTF8(codePoint) end

---Returns unicode codepoint and length in bytes from a point in a string. Throws an error with invalid UTF-8.
---@param self string @String to get a codepoint from
---@param start integer @Index (starts with 1, if below counts from the end).
---@return integer? @Symbol codepoint (or `nil` if there is no symbol with given index).
---@return integer @Symbol length (or `nil` if there is no symbol with given index).
function string.codePointAt(self, start) end

---Looks for a next emoji in the string. If next emoji is complex, all the symbols will be processed and returned as a single byte sequence. Uses 15th version
---with data from Emoji Keyboard/Display Test Data for UTS #51.
---Not working properly for CSP versions below v0.2.3-preview50.
---@param self string @String to search emojis in.
---@param start integer @Index (starts with 1, if below counts from the end).
---@return integer? @Returns 1-based starting index of an emojis, or `nil` if no emojis have been found.
---@return integer? @Returns 1-based ending index, or `nil` if no emojis have been found.
function string.nextEmoji(self, start) end

---Encodes URL argument.
---@param self string
---@param plusForSpaces boolean? @Use `'+'` for space symbol (works for URLs, but if a regular URL encoding is needed, might be getting in a way). Default value: `true`.
---@return string
function string.urlEncode(self, plusForSpaces) end

---Checks if the beginning of a string matches another string. If string to match is longer than the first one, always returns `false`.
---@param self string @String to check the beginning of.
---@param another string @String to match.
---@param offset integer? @Optional offset for the matching beginning. Default value: `0`.
---@return boolean
function string.startsWith(self, another, offset) end

---Checks if the end of a string matches another string. If string to match is longer than the first one, always returns `false`.
---@param self string @String to check the end of.
---@param another string @String to match.
---@param offset integer? @Optional offset for the matching end. Default value: `0`.
---@return boolean
function string.endsWith(self, another, offset) end

---Compares string alphanumerically.
---@param self string @First string.
---@param another string @Second string.
---@return integer @Returns positive number if first string is larger than second one, or 0 if strings are equal.
function string.alphanumCompare(self, another) end

---Compares string as versions (splits by dots and uses alphanumerical comparator for each piece).
---@param self string @First version.
---@param another string @Second version.
---@return integer @Returns positive number if first version is newer than second one, or 0 if versions are equal.
function string.versionCompare(self, another) end

---Trims string at beginning and end.
---@param self string @String to trim.
---@param characters string? @Characters to remove. Default value: `'\n\r\t '`.
---@param direction integer? @Direction to trim, 0 for trimming both ends, -1 for trimming beginning only, 1 for trimming the end. Default value: `0`.
---@return string
function string.trim(self, characters, direction) end

---Repeats string a given number of times (`repeat` is a reserved keyword, so here we are).
---@param self string @String to trim.
---@param count integer @Number of times to repeat the string.
---@return string
function string.multiply(self, count) end

---Pads string with symbols from `pad` until it reaches the desired length.
---@param self string @String to trim.
---@param targetLength integer @Desired string length. If shorter than current length, string will be trimmed from the end.
---@param pad string? @String to pad with. If empty, no padding will be performed. If has more than one symbol, will be repeated to fill the space. Default value: ` ` (space).
---@param direction integer? @Direction to pad to, 1 for padding at the end, -1 for padding at the start, 0 for padding from both ends centering string. Default value: `1`.
---@return string
function string.pad(self, targetLength, pad, direction) end

---Similar to `string.find()`: looks for the first match of `pattern` and returns indices, but uses regular expressions.
---
---Note: regular expressions currently are in ECMAScript format, so backtracking is not supported. Also, in most cases they are slower than regular Lua patterns.
---@param self string @String to search in.
---@param pattern string @Regular expression.
---@param init integer? @1-based offset to start searching from. Default value: `1`.
---@param ignoreCase boolean? @Set to `true` to make search case-insensitive. Default value: `false`.
---@return integer? @1-based index of where the match occured, or `nil` if no match has been found.
---@return integer? @1-based index of the ending of found pattern, or `nil` if no match has been found.
---@return ... @Captured elements, if there are any capture groups in the pattern.
---@nodiscard
function string.regfind(self, pattern, init, ignoreCase) end

---Similar to `string.match()`: looks for the first match of `pattern` and returns matches, but uses regular expressions.
---
---Note: regular expressions currently are in ECMAScript format, so backtracking is not supported. Also, in most cases they are slower than regular Lua patterns.
---@param self string @String to search in.
---@param pattern string @Regular expression.
---@param init integer? @1-based offset to start searching from. Default value: `1`.
---@param ignoreCase boolean? @Set to `true` to make search case-insensitive. Default value: `false`.
---@return string @Captured elements if there are any capture groups in the pattern, or the whole captured string otherwise.
---@nodiscard
function string.regmatch(self, pattern, init, ignoreCase) end

---Similar to `string.gmatch()`: iterates over matches of `pattern`, but uses regular expressions.
---
---Note: regular expressions currently are in ECMAScript format, so backtracking is not supported. Also, in most cases they are slower than regular Lua patterns.
---@param self string @String to search in.
---@param pattern string @Regular expression.
---@param ignoreCase boolean? @Set to `true` to make search case-insensitive. Default value: `false`.
---@return fun():string, ... @Iterator with captured elements if there are any capture groups in the pattern, or the whole captured string otherwise.
---@nodiscard
function string.reggmatch(self, pattern, ignoreCase) end

---Similar to `string.gsub()`: replaces all entries of `pattern` with `repl`, but uses regular expressions.
---
---Note: regular expressions currently are in ECMAScript format, so backtracking is not supported. Also, in most cases they are slower than regular Lua patterns.
---@param self string @String to search in.
---@param pattern string @Regular expression.
---@param repl    string|table|function @Replacement value. Used in the same way as with `string.gsub()`, could be a table or a function.
---@param limit integer? @Limit maximum number of replacements. Default value: `math.huge`.
---@param ignoreCase boolean? @Set to `true` to make search case-insensitive. Default value: `false`.
---@return string @String with found entries replaced.
---@nodiscard
function string.reggsub(self, pattern, repl, limit, ignoreCase) end

---Compares a string against CSP-style filter (using “?” for “any characters”).
---@param self string @String to check.
---@param filter string @Filter to check. Surround with `{…}` to use complex queries, for example, `'{ ABC? & ! ?DEF }'`.
---@param init integer? @1-based offset to start searching from. Default value: `1`.
---@return boolean
function string.cspmatch(self, filter, init) end

--[[ common/table.lua ]]

---Merges tables into one big table. Tables can be arrays or dictionaries, if it’s a dictionary same keys from subsequent tables will overwrite previously set keys.
---@generic T
---@param table T
---@vararg table
---@return T
function table.chain(table, ...) end

--[[ common/table.lua ]]

---Checks if table is an array or not. Arrays are tables that only have consequtive numeric keys.
---@param t table|any[]
---@return boolean
function table.isArray(t) end

---Creates a new table with preallocated space for given amount of elements.
---@param arrayElements integer @How many elements the table will have as a sequence.
---@param mapElements integer @How many other elements the table will have.
---@return table
function table.new(arrayElements, mapElements) end

---Cleares table without deallocating space using a fast LuaJIT call. Can work
---with both array and non-array tables.
---@param t table
function table.clear(t) end

---Returns the total number of elements in a given Lua table (i.e. from both the array and hash parts combined).
---@param t table
---@return integer
function table.nkeys(t) end

---Clones table using a fast LuaJIT call.
---@generic T
---@param t T
---@param deep boolean? @Set to `true` for deep cloning. Default value: `false`.
---@return T
function table.clone(t, deep) end

---Removes first item by value, returns true if any item was removed. Can work
---with both array and non-array tables.
---@generic T
---@param t table<any, T>
---@param item T
---@return boolean
function table.removeItem(t, item) end

---Returns an element from table with a given key. If there is no such element, calls callback
---and uses its return value to add a new element and return that. Can work
---with both array and non-array tables.
---@generic T
---@generic TCallbackData
---@param t table<any, T>
---@param key any
---@param callback fun(callbackData: TCallbackData): T
---@param callbackData TCallbackData?
---@return T
function table.getOrCreate(t, key, callback, callbackData) end

---Returns true if table contains an item. Can work with both array and non-array tables.
---@generic T
---@param t table<any, T>
---@param item T
---@return boolean
function table.contains(t, item) end

---Returns a random item from a table. Optional callback works like a filter. Can work
---with both array and non-array tables. Alternatively, optional callback can provide a number
---for a weight of an item.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param filteringCallback nil|fun(item: T, key: TKey, callbackData: TCallbackData): boolean
---@param filteringCallbackData TCallbackData?
---@param randomDevice nil|fun(): number @Optional callback for generating random numbers. Needs to return a value between 0 and 1. If not set, default `math.random` is used.
---@return T
function table.random(t, filteringCallback, filteringCallbackData, randomDevice) end

---Returns a key of a given element, or `nil` if there is no such element in a table. Can work
---with both array and non-array tables.
---@generic T
---@generic TKey
---@param t table<TKey, T>
---@param item T
---@return TKey|nil
function table.indexOf(t, item) end

---Returns true if tables contents are the same.
---@generic TKey
---@param t1 table?
---@param t2 table?
---@param deep boolean? @Default value: `true`.
---@return boolean
function table.same(t1, t2, deep) end

---Joins elements of a table to a string, works with both arrays and non-array tables. Optinal
---toStringCallback parameter can be used for a custom item serialization. All parameters but
---`t` (for actual table) are optional and can be skipped.
---
---Note: it wouldn’t work as fast as `table.concat`, but it would call a `tostring()` (or custom
---serializer callback) for each element.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param itemsJoin string? @Default value: ','.
---@param keyValueJoin string? @Default value: '='.
---@param toStringCallback nil|fun(item: T, key: TKey, callbackData: TCallbackData): string
---@param toStringCallbackData TCallbackData?
---@overload fun(t: table, itemsJoin: string, toStringCallback: fun(item: any, key: any, callbackData: any), toStringCallbackData: any)
---@overload fun(t: table, toStringCallback: fun(item: any, key: any, callbackData: any), toStringCallbackData: any)
---@return TKey|nil
function table.join(t, itemsJoin, keyValueJoin, toStringCallback, toStringCallbackData) end

---Slices array, basically acts like slicing thing in Python.
---@generic T
---@param t T[]
---@param from integer @Starting index.
---@param to integer? @Ending index.
---@param step integer? @Step.
---@return T[]
function table.slice(t, from, to, step) end

---Flips table from back to front, requires an array.
---@generic T
---@param t T[]
---@return T[]
function table.reverse(t) end

---Calls callback function for each of table elements, creates a new table containing all the resulting values.
---Can work with both array and non-array tables. For non-array tables, new table is going to be an array unless
---callback function would return a key as a second return value.
---
---If callback returns two values, second would be used as a key to create a table-like table (not an array-like one).
---
---Note: if callback returns `nil`, value will be skipped, so this function can act as a filtering one too.
---@generic T
---@generic TKey
---@generic TCallbackData
---@generic TReturnKey
---@generic TReturnValue
---@param t table<TKey, T>
---@param callback (fun(item: T, index: TKey, callbackData: TCallbackData): TReturnValue, TReturnKey?)|nil @Mapping callback.
---@param callbackData TCallbackData?
---@return table<TReturnKey, TReturnValue>
function table.map(t, callback, callbackData) end

---Calls callback function for each of table elements, creates a new table containing all the resulting values.
---Can work with both array and non-array tables. For non-array tables, new table is going to be an array unless
---callback function would return a key as a second return value.
---
---If callback returns two values, second would be used as a key to create a table-like table (not an array-like one).
---
---Note: if callback returns `nil`, value will be skipped, so this function can act as a filtering one too.
---@generic T
---@generic TKey
---@generic TCallbackData
---@generic TData
---@param t table<TKey, T>
---@param startingValue TData
---@param callback fun(data: TData, item: T, index: TKey, callbackData: TCallbackData): TData @Reduction callback.
---@param callbackData TCallbackData?
---@return TData
function table.reduce(t, startingValue, callback, callbackData) end

---Creates a new table from all elements for which filtering callback returns true. Can work with both
---array and non-array tables.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param callback fun(item: T, index: TKey, callbackData: TCallbackData): any @Filtering callback.
---@param callbackData TCallbackData?
---@return table<TKey, T>
function table.filter(t, callback, callbackData) end

---Returns true if callback returns non-false value for every element of the table. Can work with both
---array and non-array tables.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param callback fun(item: T, index: TKey, callbackData: TCallbackData): boolean
---@param callbackData TCallbackData?
---@return boolean
function table.every(t, callback, callbackData) end

---Returns true if callback returns non-false value for at least a single element of the table. Can work
---with both array and non-array tables.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param callback fun(item: T, index: TKey, callbackData: TCallbackData): boolean
---@param callbackData TCallbackData?
---@return boolean
function table.some(t, callback, callbackData) end

---Counts number of elements for which callback returns non-false value. Can work
---with both array and non-array tables.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param callback nil|fun(item: T, index: TKey, callbackData: TCallbackData): boolean @If not set, all elements will be counted.
---@param callbackData TCallbackData?
---@return integer
function table.count(t, callback, callbackData) end

---Calls callback for each element, returns sum of returned values. Can work
---with both array and non-array tables. If callback is missing, sums actual values in table.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param callback fun(item: T, index: TKey, callbackData: TCallbackData): boolean
---@param callbackData TCallbackData?
---@return integer
function table.sum(t, callback, callbackData) end

---Returns first element and its key for which callback returns a non-false value. Can work
---with both array and non-array tables. If nothing is found, returns `nil`.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param callback fun(item: T, index: TKey, callbackData: TCallbackData): boolean
---@param callbackData TCallbackData?
---@return T, TKey
function table.findFirst(t, callback, callbackData) end

---Returns first element and its key for which a certain property matches the value. If nothing is
---found, returns `nil`.
---@generic T
---@generic TKey
---@param t table<TKey, T>
---@param key string
---@param value any
---@return T, TKey
function table.findByProperty(t, key, value) end

---Returns an element and its key for which callback would return the highest numerical value. Can work
---with both array and non-array tables. If callback is missing, actual table elements will be compared.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param callback fun(item: T, index: TKey, callbackData: TCallbackData): number
---@param callbackData TCallbackData?
---@return T, TKey
function table.maxEntry(t, callback, callbackData) end

---Returns an element and its key for which callback would return the lowest numerical value. Can work
---with both array and non-array tables. If callback is missing, actual table elements will be compared.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param callback fun(item: T, index: TKey, callbackData: TCallbackData): number
---@param callbackData TCallbackData?
---@return T, TKey
function table.minEntry(t, callback, callbackData) end

---Runs callback for each item in a table. Can work with both array and non-array tables.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param callback fun(item: T, key: TKey, callbackData: TCallbackData)
---@param callbackData TCallbackData?
---@return table
function table.forEach(t, callback, callbackData) end

---Creates a new table with unique elements from original table only. Optionally, a callback
---can be used to provide a key which uniqueness will be checked. Can work with both array
---and non-array tables.
---@generic T
---@generic TKey
---@generic TCallbackData
---@param t table<TKey, T>
---@param callback nil|fun(item: T, key: TKey, callbackData: TCallbackData): any
---@param callbackData TCallbackData?
---@return table<TKey, T>
function table.distinct(t, callback, callbackData) end

---Finds first element for which `testCallback` returns true, returns index of an element before it.
---Elements should be ordered in such a way that there would be no more elements returning false to the right
---of an element returning true.
---
---If `testCallback` returns true for all elements, would return 0. If `testCallback` returns false for all,
---returns index of the latest element.
---@generic T
---@generic TCallbackData
---@param t T[]
---@param testCallback fun(item: T, index: integer, callbackData: TCallbackData): boolean
---@param testCallbackData nil|TCallbackData
---@return integer
---@nodiscard
function table.findLeftOfIndex(t, testCallback, testCallbackData) end

---Similar to JavaScript’s `Object.assign()`, works with tables and arrays, returns first argument (modified).
---@generic T
---@param target T
---@param ... table
---@return T
function table.assign(target, ...) end

---Flattens table similar to JavaScript function with the same name. Requires an array.
---@param t any[]
---@param maxLevel integer? @Default value: 1.
---@return any[]
function table.flatten(t, maxLevel) end

---Creates a new table running in steps from `startingIndex` to `endingIndex`, including `endingIndex`.
---If callback returns two values, second value is used as a key.
---@generic T
---@generic TCallbackData
---@param endingIndex integer?
---@param startingIndex integer
---@param step integer?
---@param callback fun(index: integer, callbackData: TCallbackData): T, integer|string?
---@param callbackData TCallbackData?
---@return T[]
---@overload fun(endingIndex: integer, callback: (fun(index: integer, callbackData: any): any, integer|string?), callbackData: any)
---@overload fun(endingIndex: integer, startingIndex: integer, callback: (fun(index: integer, callbackData: any): any, integer|string?), callbackData: any)
function table.range(endingIndex, startingIndex, step, callback, callbackData) end

---Creates a new table from iterator. Supports iterators returning one or two values (if two values are returned, first is considered the key,
---if not, values are simply added to a list).
---@generic T
---@param iterator fun(...): T
---@return T[]
function table.build(iterator, k, v) end

--[[ common/io.lua ]]

---Structure containing various file or directory attributes, including various flags and dates. All values are precomputed and ready to be used (there is
---no overhead in accessing them once you get the structure).
---@class io.FileAttributes
---@field fileSize integer @File size in bytes.
---@field creationTime integer @File creation time in seconds from 1970.
---@field lastAccessTime integer @File last access time in seconds from 1970.
---@field lastWriteTime integer @File last write time in seconds from 1970.
---@field exists boolean @True if file exists.
---@field isDirectory boolean @True if file is a directory.
---@field isHidden boolean @The file or directory is hidden. It is not included in an ordinary directory listing.
---@field isReadOnly boolean @A file that is read-only. Applications can read the file, but cannot write to it or delete it.
---@field isEncrypted boolean @A file or directory that is encrypted. For a file, all data streams in the file are encrypted. For a directory, encryption is the default for newly created files and subdirectories.
---@field isCompressed boolean @A file or directory that is compressed. For a file, all of the data in the file is compressed. For a directory, compression is the default for newly created files and subdirectories.
---@field isReparsePoint boolean @A file or directory that has an associated reparse point, or a file that is a symbolic link.
local _fileAttributes = {}

--[[ common/io.lua ]]

---@alias io.ZipEntry {filename: string}|{data: binary}|binary

---Scan directory and call callback function for each of files, passing file name (not full name, but only name of the file) and attributes. If callback function would return
---a non-nil value, iteration will stop and value returned by callback would return from this function. This could be used to
---find a certain file without going through all files in the directory. Optionally, a mask can be used to pre-filter received files
---entries.
---
---If callback function is not provided, it’ll return list of files instead (file names only).
---
---System entries “.” and “..” will not be included in the list of files. Accessing attributes does not add extra cost.
---@generic TCallbackData
---@generic TReturn
---@param directory string @Directory to look for files in. Note: directory is relative to current directory, not to script directory. For AC in general it’s an AC root directory, but do not rely on it, instead use `ac.getFolder(ac.FolderID.Root)`.
---@param mask string? @Mask in a form of usual “*.*”. Default value: '*'.
---@param callback fun(fileName: string, fileAttributes: io.FileAttributes, callbackData: TCallbackData): TReturn? @Callback which will be ran for every file in directory fitting mask until it would return a non-nil value.
---@param callbackData TCallbackData? @Callback data that will be passed to callback as third argument, to avoid creating a capture.
---@return TReturn? @First non-nil value returned by callback.
---@overload fun(directory: string, callback: fun(fileName: string, fileAttributes: io.FileAttributes, callbackData: any), callbackData: any): any
---@overload fun(directory: string, mask: string|nil): string[] @This overload just returns the list
function io.scanDir(directory, mask, callback, callbackData) end

--[[ common/os.lua ]]

---@class os.ConsoleProcessResult
---@field exitCode integer @If process finished successfully, 0. If failed to get the exit code, -1.
---@field stdout string @Contents of stdout stream of ran process.
---@field stderr string @Contents of stderr stream of ran process. Would be set only if `separateStderr` parameter was set to true.

--[[ common/os.lua ]]

---Module with additional functions to help deal with operating system.
os = {}

---Parse date and return a unix timestamp. Uses `std::get_time()` for actual parsing:
---<https://en.cppreference.com/w/cpp/io/manip/get_time>.
---@param date string @String containing date.
---@param format string? @Format string. Default value: `'%Y-%m-%dT%H:%M:%S'`.
---@return integer? @Returns `nil` if failed to parse.
function os.parseDate(date, format) end

---Opens regular Windows file opening dialog, calls callback with either an error or a path to a file selected by user
---(or nil if selection was cancelled). All parameters in `params` table are optional (the whole table too).
---@param params {title: string, defaultFolder: nil|string, folder: string, fileName: string, fileTypes: nil|{ name: string, mask: string }[], addAllFilesFileType: boolean, fileTypeIndex: integer, fileNameLabel: string, okButtonLabel: string, places: string[], flags: os.DialogFlags}|nil|`{defaultFolder = ac.getFolder(ac.FolderID.Root), fileTypes = {{name = 'Images', mask = '*.png;*.jpg;*.jpeg;*.bmp'}}, addAllFilesFileType = true, flags = bit.bor(os.DialogFlags.PathMustExist, os.DialogFlags.FileMustExist)}` "Table with properties:\n- `title` (`string`): Dialog title.\n- `defaultFolder` (`nil|string`): Default folder if there is not a recently used folder value available.\n- `folder` (`string`): Selected folder (unlike `defaultFolder`, overrides recently used folder).\n- `fileName` (`string`): File name that appears in the File name edit box when that dialog box is opened.\n- `fileTypes` (`nil|{ name: string, mask: string }[]`): File types (names and masks).\n- `addAllFilesFileType` (`boolean`): If providing file types, set this to true to automatically add “All Files (*.*)” type at the bottom\n- `fileTypeIndex` (`integer`): File type selected by default (1-based).\n- `fileNameLabel` (`string`): Text of the label next to the file name edit box.\n- `okButtonLabel` (`string`): Text of the Open button.\n- `places` (`string[]`): Additional places to show in the list of locations on the left.\n- `flags` (`os.DialogFlags`): Dialog flags (use `bit.bor()` to combine flags together to avoid errors with adding same flag twice)"
---@param callback fun(err: string, filename: string)
function os.openFileDialog(params, callback) end

---Opens regular Windows file saving dialog, calls callback with either an error or a path to a file selected by user
---(or nil if selection was cancelled). All parameters in `params` table are optional (the whole table too).
---@param params {title: string, defaultFolder: nil|string, defaultExtension: string, folder: string, fileName: string, saveAsItem: string, fileTypes: nil|{ name: string, mask: string }[], addAllFilesFileType: boolean, fileTypeIndex: integer, fileNameLabel: string, okButtonLabel: string, places: string[], flags: os.DialogFlags}|nil|`{defaultFolder = ac.getFolder(ac.FolderID.Root), fileTypes = {{name = 'Images', mask = '*.png;*.jpg;*.jpeg;*.bmp'}}, addAllFilesFileType = true, flags = bit.bor(os.DialogFlags.PathMustExist, os.DialogFlags.OverwritePrompt, os.DialogFlags.NoReadonlyReturn)}` "Table with properties:\n- `title` (`string`): Dialog title.\n- `defaultFolder` (`nil|string`): Default folder if there is not a recently used folder value available.\n- `defaultExtension` (`string`): Sets the default extension to be added to file names, with a dot in front.\n- `folder` (`string`): Selected folder (unlike `defaultFolder`, overrides recently used folder).\n- `fileName` (`string`): File name that appears in the File name edit box when that dialog box is opened.\n- `saveAsItem` (`string`): Ann item to be used as the initial entry in a Save As dialog.\n- `fileTypes` (`nil|{ name: string, mask: string }[]`): File types (names and masks).\n- `addAllFilesFileType` (`boolean`): If providing file types, set this to true to automatically add “All Files (*.*)” type at the bottom\n- `fileTypeIndex` (`integer`): File type selected by default (1-based).\n- `fileNameLabel` (`string`): Text of the label next to the file name edit box.\n- `okButtonLabel` (`string`): Text of the Save button.\n- `places` (`string[]`): Additional places to show in the list of locations on the left.\n- `flags` (`os.DialogFlags`): Dialog flags (use `bit.bor()` to combine flags together to avoid errors with adding same flag twice)"
---@param callback fun(err: string, filename: string)
function os.saveFileDialog(params, callback) end

---Run a console process in background with given arguments, return exit code and output in callback. Launched process will be tied
---to AC process to shut down with AC (works only on Windows 8 and newer).
---@param params {filename: string, arguments: string[], rawArguments: boolean, workingDirectory: string, timeout: integer, environment: table, inheritEnvironment: boolean, stdin: string, separateStderr: boolean, terminateWithScript: boolean, dataCallback: fun(err: boolean, data: string)}|`{ filename = '', arguments = {} }` "Table with properties:\n- `filename` (`string`): Application filename.\n- `arguments` (`string[]`): Arguments (quotes will be added automatically unless `rawArguments` is set to true).\n- `rawArguments` (`boolean`): Set to `true` to disable any arguments processing and pass them as they are, simply joining them with a space symbol.\n- `workingDirectory` (`string`): Working directory.\n- `timeout` (`integer`): Timeout in milliseconds. If above zero, process will be killed after given time has passed.\n- `environment` (`table`): If set to a table, values from that table will be used as environment variables instead of inheriting ones from AC process.\n- `inheritEnvironment` (`boolean`): Set to `true` to inherit AC environment variables before adding custom ones.\n- `stdin` (`string`): Optional data to pass to a process in stdin pipe.\n- `separateStderr` (`boolean`): Store stderr data in a separate string.\n- `terminateWithScript` (`boolean`): Terminate process if this Lua script were to terminate (for example, during reload).\n- `dataCallback` (`fun(err: boolean, data: string)`): If set to a function, data written in stdout and stderr will be passed to the function instead as it arrives."
---@param callback nil|fun(err: string, data: os.ConsoleProcessResult)
function os.runConsoleProcess(params, callback) end

--[[ common/timer.lua ]]

---Runs callback after certain time. Returns cancellation ID.
---Note: all callbacks will be ran before `update()` call,
---and they would only ran when script runs. So if your script is executed each frame and AC runs at 60 FPS, smallest interval
---would be 0.016 s, and anything lower that you’d set would still act like 0.016 s. Also, intervals would only be called once
---per frame.
---@param callback fun()
---@param delay number? @Delay time in seconds. Default value: 0.
---@param uniqueKey any? @Unique key: if set, timer wouldn’t be added unless there is no more active timers with such ID.
---@return integer
function setTimeout(callback, delay, uniqueKey) end

---Repeteadly runs callback after certain time. Returns cancellation ID.
---Note: all callbacks will be ran before `update()` call,
---and they would only ran when script runs. So if your script is executed each frame and AC runs at 60 FPS, smallest interval
---would be 0.016 s, and anything lower that you’d set would still act like 0.016 s. Also, intervals would only be called once
---per frame.
---@param callback fun(): function? @Return `clearInterval` (actual function) to clear interval.
---@param period number? @Period time in seconds. Default value: 0.
---@param uniqueKey any? @Unique key: if set, timer wouldn’t be added unless there is no more active timers with such ID.
---@return integer
function setInterval(callback, period, uniqueKey) end

---Stops timeout.
---@param cancellationID integer @Value earlier retuned by `setTimeout()`. If a non-numerical value is passed (like a `nil`), call is ignored and returns `false`.
---@return boolean @True if timeout with such ID has been found and stopped.
function clearTimeout(cancellationID) end

---Stops interval.
---@param cancellationID integer @Value earlier retuned by `setInterval()`.
---@return boolean @True if interval with such ID has been found and stopped.
function clearInterval(cancellationID) end

--[[ common/ac_extras_ini.lua ]]

---A wrapper for data parsed from an INI files, supports different INI formats. Parsing is done on
---CSP side, rest is on CSP side. Use `:get()` and `:set()` methods to operate values.
---@param format ac.INIFormat 
---@param sections table 
---@return ac.INIConfig
function ac.INIConfig(format, sections) end

---A wrapper for data parsed from an INI files, supports different INI formats. Parsing is done on
---CSP side, rest is on CSP side. Use `:get()` and `:set()` methods to operate values.
---@class ac.INIConfig
---@field sections table<string, table<string, string[]>> @Sections storing actual data.
---@field format ac.INIFormat? @Format used when creating a config. Default value: `ac.INIFormat.Default`.
---@field filename string? @Optional filename for configs loaded from a file.
local _ac_INIConfig = nil

---Get value from parsed INI file. Note: getting vector values creates them anew, so if you’re going to use a value often, consider
---caching it locally.
---@generic T
---@param section string @Section name.
---@param key string @Value key.
---@param defaultValue T @Defines type of value to return, is returned if value is missing. If not set, list of strings is returned.
---@param offset integer? @Optional 1-based offset for data parsed in CSP format (in case value contains several items). Default value: 1.
---@return T
function _ac_INIConfig:get(section, key, defaultValue, offset) end

---Attempts to load a 1D-to-1D LUT from an INI file, supports both inline “(|X=Y|…|)” LUTs and separate files next to configs (only
---for configs loaded by filename or from car data)
---@return ac.DataLUT11? @Returns `nil` if there is no such key or no such file.
function _ac_INIConfig:tryGetLut(section, key) end

---Attempts to load a 2D-to-1D LUT from an INI file, supports both inline “(|X,Y=Z|…|)” LUTs and separate files next to configs (only
---for configs loaded by filename or from car data)
---@return ac.DataLUT21? @Returns `nil` if there is no such key or no such file.
function _ac_INIConfig:tryGet2DLut(section, key) end

---Iterates over sections of INI file with a certain prefix. Order matches order of CSP parsing such data.
---
---Example:
---```
---for index, section in iniConfig:iterate('LIGHT') do
---  print('Color: '..iniConfig:get(section, 'COLOR', 'red'))
---end
---```
---@param prefix string @Prefix for section names.
---@param noPostfixForFirst boolean? @Only for default INI format. If set to `true`, first section would not have “_0” postfix.
---@return fun(): integer?, string? @If you need a list instead of an iterator, use `table.build()`.
function _ac_INIConfig:iterate(prefix, noPostfixForFirst) end

---Iterates over values of INI section with a certain prefix. Order matches order of CSP parsing such data.
---
---Example:
---```
---for index, key in iniConfig:iterateValues('LIGHT_0', 'POSITION', true) do
---  print('Position: '..tostring(iniConfig:get('LIGHT_0', key, vec3())))
---end
---```
---@param prefix string @Prefix for section names.
---@param digitsOnly boolean? @If set to `true`, would only collect keys consisting of a prefix and a number (useful for configs with extra properties).
---@return fun(): integer?, string? @If you need a list instead of an iterator, use `table.build()`.
function _ac_INIConfig:iterateValues(section, prefix, digitsOnly) end

---Takes table with default values and returns a table with values filled from config.
---@generic T
---@param section string @Section name.
---@param defaults T @Table with keys and default values. Keys are the same as INI keys.
---@return T
function _ac_INIConfig:mapSection(section, defaults) end

---Takes table with default values and returns a table with values filled from config.
---@generic T
---@param defaults T @Table with section names and sub-tables with keys and default values. Keys are the same as INI keys.
---@return T
function _ac_INIConfig:mapConfig(defaults) end

---Set an INI value. Pass `nil` as value to remove it.
---@param section string
---@param key string
---@param value string|string[]|number|boolean|nil|vec2|vec3|vec4|rgb|rgbm
---@return ac.INIConfig @Returns itself for chaining several methods together.
function _ac_INIConfig:set(section, key, value) end

---Set an INI value and save file immediately using special old Windows function to edit a single INI value. Compatible only with default
---INI format. Doesn’t provide major peformance improvements, but might be useful if you prefer to keep original formatting as much as possible
---when editing a single value only.
---@param section string
---@param key string
---@param value string|string[]|number|boolean|nil|vec2|vec3|vec4|rgb|rgbm
---@return boolean @Returns `true` if new value is different and config was saved.
function _ac_INIConfig:setAndSave(section, key, value) end

---Serializes data in INI format using format specified on INIConfig creation. You can also use `tostring()` function.
---@return string
function _ac_INIConfig:serialize() end

---Saves contents to a file in INI form.
---@param filename string? @Filename. If filename is not set, saves file with the same name as it was loaded. Updates `filename` field.
---@return ac.INIConfig @Returns itself for chaining several methods together.
function _ac_INIConfig:save(filename) end

--[[ common/ac_extras_ini.lua ]]

---Pass this as a `defaultValue` to `:get()` (or use it as a value in `:mapSection()`) to get either a boolean or, if it’s missing, `nil`.
ac.INIConfig.OptionalBoolean = {}

---Pass this as a `defaultValue` to `:get()` (or use it as a value in `:mapSection()`) to get either a number or, if it’s missing, `nil`.
ac.INIConfig.OptionalNumber = {}

---Pass this as a `defaultValue` to `:get()` (or use it as a value in `:mapSection()`) to get either a string or, if it’s missing, `nil`.
ac.INIConfig.OptionalString = {}

---Pass this as a `defaultValue` to `:get()` (or use it as a value in `:mapSection()`) to get either a list of original values or, if it’s missing, `nil`.
ac.INIConfig.OptionalList = {}

---Parse INI config from a string.
---@param data string @Serialized INI data.
---@param format ac.INIFormat? @Format to parse. Default value: `ac.INIFormat.Default`.
---@param includeFolders ('@cars'|'@tracks'|string)[]? @Optional folders to include files from (only for `ac.INIFormat.ExtendedIncludes` format). Use special values `'@cars'` and `'@tracks'` for car or track configs.
---@return ac.INIConfig
function ac.INIConfig.parse(data, format, includeFolders) end

---Load INI file, optionally with includes.
---@param filename string @INI config filename.
---@param format ac.INIFormat? @Format to parse. Default value: `ac.INIFormat.Default`.
---@param includeFolders ('@cars'|'@tracks'|string)[]? @Optional folders to include files from (only for `ac.INIFormat.ExtendedIncludes` format). If not set, parent folder for config filename is used. Use special values `'@cars'` and `'@tracks'` for car or track configs.
---@return ac.INIConfig
function ac.INIConfig.load(filename, format, includeFolders) end

---Load car data INI file. Supports “data.acd” files as well. Returned files might be tweaked by
---things like custom physics virtual tyres. To get original file, use `ac.INIConfig.load()`.
---
---Returned file can’t be saved.
---@param carIndex number @0-based car index.
---@param fileName string @Car data file name, such as `'tyres.ini'`.
---@return ac.INIConfig
function ac.INIConfig.carData(carIndex, fileName) end

---Load track data INI file. Can be used by track scripts which might not always  have access to those files directly.
---
---Returned file can’t be saved.
---@param fileName string @Car data file name, such as `'tyres.ini'`.
---@return ac.INIConfig
function ac.INIConfig.trackData(fileName) end

---Returns CSP config for a car. Might be slow: some of those configs are huge. Make sure to cache the resulting value if you need to reuse it.
---
---Returned file can’t be saved.
---@param carIndex number @0-based car index.
---@return ac.INIConfig
function ac.INIConfig.carConfig(carIndex) end

---Returns CSP config for a track. Might be slow: some of those configs are huge. Make sure to cache the resulting value if you need to reuse it.
---
---Returned file can’t be saved.
---@return ac.INIConfig
function ac.INIConfig.trackConfig() end

---Returns config with extra online options, the ones that can be set with Content Manager.
---
---Returned file can’t be saved.
---@return ac.INIConfig|nil @If not an online session, returns `nil`.
function ac.INIConfig.onlineExtras() end

---Returns race config (`cfg/race.ini`). Password and online GUID won’t be included.
---
---Returned file can’t be saved.
---@return ac.INIConfig
function ac.INIConfig.raceConfig() end

---Returns video config (`cfg/video.ini`).
---
---Returned file can’t be saved.
---@return ac.INIConfig
function ac.INIConfig.videoConfig() end

---Returns controls config (`cfg/controls.ini`).
---
---Returned file can’t be saved.
---@return ac.INIConfig
function ac.INIConfig.controlsConfig() end

---Returns current setup INI file (either previously loaded or saved). Any changes in actual setup in pits won’t be reflected in the returned
---data unless file was saved.
---
---Returned file can be saved. Use `ac.onSetupFile()` to listen to data changes and either read extra data from setup file, or change the contents after file has been saved.
---@return ac.INIConfig
function ac.INIConfig.currentSetup() end

---Load config of a CSP module by its name.
---@param cspModuleID ac.CSPModuleID @Name of a CSP module.
---@return ac.INIConfig
function ac.INIConfig.cspModule(cspModuleID) end

---Load config of the current Lua script (“settings.ini” in script directory and settings overriden by user, meant to be customizable with Content Manager).
---@return ac.INIConfig
function ac.INIConfig.scriptSettings() end

---Serializes data in INI format using format specified on INIConfig creation. You can also use `tostring()` function.
---@return string
function _ac_INIConfig:serialize() end

---Saves contents to a file in INI form.
---@param filename string? @Filename. If filename is not set, saves file with the same name as it was loaded. Updates `filename` field.
---@return ac.INIConfig @Returns itself for chaining several methods together.
function _ac_INIConfig:save(filename) end

--[[ common/ac_extras_datalut.lua ]]

---Creates a new empty 1D-to-1D LUT. Use `ac.DataLUT11:add(input, output)` to fill it with data.
---@return ac.DataLUT11
function ac.DataLUT11() end

---Parse 1D-to-1D LUT from a string in “(|Input1=Output1|Input2=Output2|…|)” format.
---@param data string @Serialized LUT data.
---@return ac.DataLUT11
function ac.DataLUT11.parse(data) end

---Load 1D-to-1D LUT file.
---@param filename string @LUT filename.
---@return ac.DataLUT11
function ac.DataLUT11.load(filename) end

---Load car data 1D-to-1D LUT file. Supports “data.acd” files as well.
---@param carIndex number @0-based car index.
---@param fileName string @Car data file name, such as `'power.lut'`.
---@return ac.DataLUT11
function ac.DataLUT11.carData(carIndex, fileName) end

---Creates a new empty 2D-to-1D LUT. Use `ac.DataLUT21:add(input, output)` to fill it with data.
---@return ac.DataLUT21
function ac.DataLUT21() end

---Parse 2D-to-1D LUT from a string in “(|X1,Y1=Output1|X2,Y2=Output2|…|)” format.
---@param data string @Serialized LUT data.
---@return ac.DataLUT21
function ac.DataLUT21.parse(data) end

---Load 2D-to-1D LUT file.
---@param filename string @LUT filename.
---@return ac.DataLUT21
function ac.DataLUT21.load(filename) end

---Load car data 2D-to-1D LUT file. Supports “data.acd” files as well.
---@param carIndex number @0-based car index.
---@param fileName string @Car data file name, such as `'speed_throttle.2dlut'`.
---@return ac.DataLUT21
function ac.DataLUT21.carData(carIndex, fileName) end

--[[ common/ac_extras_datalut.lua ]]

---Simple 1D-to-1D lookup table wrapper, helps to deal with all those “.lut“ files in car data.
---@class ac.DataLUT11
---@field useCubicInterpolation boolean @Set to `true` to use cubic interpolation. Default value: `false` (linear interpolation).
---@field extrapolate boolean @Set to `true` to extrapolate if requested value is outside of the data available.
local _ac_DataLUT11 = nil

---Add a new value to LUT.
---@param input number
---@param output number
---@return ac.DataLUT11 @Returns self for easy chaining.
function _ac_DataLUT11:add(input, output) end

---Returns data boundaries.
---@return vec2 @Minimum input and output.
---@return vec2 @Maximum input and output.
function _ac_DataLUT11:bounds() end

---Computes a LUT value using either linear or cubic interpolation (set field `ac.DataLUT11.useCubicInterpolation` to
---`true` to use cubic interpolation).
---@param input number
---@return number
function _ac_DataLUT11:get(input) end

---Returns input value of a certain point of a LUT, or `math.nan` if there is no such point.
---@param index number @0-based index.
---@return number
function _ac_DataLUT11:getPointInput(index) end

---Returns output value of a certain point of a LUT, or `math.nan` if there is no such point.
---@param index number @0-based index.
---@return number
function _ac_DataLUT11:getPointOutput(index) end

---Convert LUT into a string, either in a short (inlined, for an INI config) or long (for a separate file) format.
---@param longFormat boolean? @Set to `true` to use long format. Default value: `false`.
---@return string
function _ac_DataLUT11:serialize(longFormat) end

---Simple 2D-to-1D lookup table wrapper, helps to deal with all those “.2dlut“ files in car data. Tables can miss some values,
---such areas will be further interpolated.
---@class ac.DataLUT21
---@field useBicubicInterpolation boolean @Set to `true` to use bicubic interpolation. Default value: `false` (bilinear interpolation).
local _ac_DataLUT21 = nil

---Returns data boundaries.
---@return vec3 @Minimum input (X, Y) and output (Z).
---@return vec3 @Maximum input (X, Y) and output (Z).
function _ac_DataLUT21:bounds() end

---Add a new value to a 2D LUT.
---@param input vec2
---@param output number
---@return ac.DataLUT21 @Returns self for easy chaining.
function _ac_DataLUT21:add(input, output) end

---Computes a LUT value using either bilinear or bicubic interpolation (set field `ac.DataLUT21.useBicubicInterpolation` to
---`true` to use bicubic interpolation).
---@param input vec2
---@return number
function _ac_DataLUT21:get(input) end

---Convert LUT into a string in a short (inlined, for an INI config) format.
---@return string
function _ac_DataLUT21:serialize() end

--[[ common/ac_extras_connect.lua ]]

---Creates a new shared structure to quickly exchange data between different Lua scripts within a session. Example:
---```
---local sharedData = ac.connect{
---  ac.StructItem.key('myChannel'),        -- optional, to avoid collisions
---  someString = ac.StructItem.string(24), -- 24 is for capacity
---  someInt = ac.StructItem.int(),
---  someDouble = ac.StructItem.double(),
---  someVec = ac.StructItem.vec3()
---}
---```
---
---Note: to connect two scripts, both of them chould use `ac.connect()` and pass exactly the same layouts. Also, consider using more
---specific names to avoid possible unwanted collisions. For example, instead of using `value = ac.StructItem.int()` which might be
---used somewhere else, use `weatherBrightnessValue = ac.StructItem.int()`. Or, simply add `ac.StructItem.key('myUniqueKey')`.
---
---For safety reasons, car scripts can only connect to other car scripts, and track scripts can only connect to other track scripts.
---@generic T
---@param layout T @A table containing fields of structure and their types. Use `ac.StructItem` methods to select types. Alternatively, you can pass a string for the body of the structure here, but be careful with it.
---@param keepLive boolean? @Set to true to keep structure even if any references were removed or script was unloaded.
---@param namespace nil|ac.SharedNamespace @Optional namespace stopping scripts of certain types to access data of scripts with different types. For more details check `ac.SharedNamespace` documentation.
---@return T
function ac.connect(layout, keepLive, namespace) end

---Create a new struct from a given layout. Could be used in calls like `ac.structBytes()` and `ac.fillStructWithBytes()`. Each call defines and creates a new struct, so don’t
---call them each frame, I believe LuaJIT doesn’t do garbage collection on struct definitions.
---@generic T
---@param layout T
---@param compact boolean?
---@return T
---@return integer @Structure size.
---@return string @Structure name.
function ac.StructItem.combine(layout, compact) end

--[[ common/ac_struct_item.lua ]]

---Helper to define structures in a safe and secure manner. Create a new table and use values returned
---by these methods as values and pass it to `ac.connect()` or `ac.registerOnlineMessageType()`.
---
---Few notes:
---- Don’t worry about order, elements will be reordered automatically (also, if using associative table
---  in Lua, order would not be strictly defined anyway);
---- If you want to make sure to avoid possible collisions (those functions use format of layout for identifying
---  structures and establishing connections), use `ac.StructItem.key('myOwnUniqueThing')`;
---- If you want to save space (for example, with online messages), there are virtual types `.norm…` and `.unorm…`
---  which would give you floating point values from -1 to 1 (or for 0 to 1 for .unorm… variants), but use 8-bit
---  and 16-bit values for storing, they could help. Also make sure to limit capacity of your strings as much as
---  possible;
---- When accessing string, its checksum will be calculated and compared with checksum of previously accessed value,
---  thus avoiding creating new entities when unnecessary. While it helps with GC, it could incur some overhead
---  on accessing values, so if you need to access string numerous times (let’s say, in a loop), consider copying
---  a reference to it locally.
ac.StructItem = {}

---Adds a key to a structure to ensure its uniqueness. Consider using something like “yourUsername.yourContentID” or something
---like that for a key, so that your data would not interfere with data from Lua scripts written by other developers. Note:
---if you’re exchanging data between physics and graphics thread in your car, you might have to append `car.index` to there as
---well so that different cars would have either own data things.
---@return nil
function ac.StructItem.key(key) end

---Enables explicit ordering for your structures.
---By default, CSP will reorder fields in your structures for optimal data packing. Because all scripts written in Lua share the same algorithm,
---it’s all fine and good, but if you want for your script to exchange data with other programs, explicit order would work much better.
---@param alignment integer? @Optional override for alignment of child structures.
---@param packing integer? @Optional overrider for packing of fields.
---@return nil
function ac.StructItem.explicit(alignment, packing) end

---@return number
function ac.StructItem.half() end

---@return number
function ac.StructItem.float() end

---@return number
function ac.StructItem.double() end

---@return number
function ac.StructItem.norm8() end

---@return number
function ac.StructItem.unorm8() end

---@return number
function ac.StructItem.norm16() end

---@return number
function ac.StructItem.unorm16() end

---@return integer
function ac.StructItem.int16() end

---@return integer
function ac.StructItem.uint16() end

---@return integer
function ac.StructItem.int32() end

---@return integer
function ac.StructItem.uint32() end

---@return integer
function ac.StructItem.int64() end

---@return integer
function ac.StructItem.uint64() end

---@return boolean
function ac.StructItem.boolean() end

---Same as `ac.StructItem.int8()`.
---@return integer
function ac.StructItem.char() end

---Same as `ac.StructItem.uint8()`.
---@return integer
function ac.StructItem.byte() end

---@return integer
function ac.StructItem.int8() end

---@return integer
function ac.StructItem.uint8() end

---@return vec2
function ac.StructItem.vec2() end

---@return vec3
function ac.StructItem.vec3() end

---@return vec4
function ac.StructItem.vec4() end

---@return rgb
function ac.StructItem.rgb() end

---@return rgbm
function ac.StructItem.rgbm() end

---@return hsv
function ac.StructItem.hsv() end

---@return quat
function ac.StructItem.quat() end

---@generic T
---@param elementType T
---@param size integer
---@return T[]
function ac.StructItem.array(elementType, size) end

---@generic T
---@param fields T
---@return T
function ac.StructItem.struct(fields) end

---@param capacity integer? @Maximum string capacity. Default value: 32.
---@return string
function ac.StructItem.string(capacity) end

---@return mat3x3
function ac.StructItem.mat3x3() end

---@return mat4x4
function ac.StructItem.mat4x4() end

---Matrix packed to 6, 9 or 12 bytes (depending on settings).
---
---Note: to update value you need to use assignment operator (`.field = newValue`), altering matrix of this property with methods like
---`:mulSelf()` only changes unpacked value on your side, but not the actual structure value.
---@param compactPosition boolean? @If `true`, position is packed into 3 bytes, otherwise it will take 6 bytes. Default value: `false`.
---@param compactRotation boolean? @If `true`, rotation is packed into 3 bytes, otherwise it will take 6 bytes. Default value: `false`.
---@param rangeFrom number|vec3? @Minimal expected position. Pass it together with `rangeTo` to encode position data more efficiently.
---@param rangeTo number|vec3? @Maximum expected position. Pass it together with `rangeFrom` to encode position data more efficiently.
---@return mat4x4
function ac.StructItem.transform(compactPosition, compactRotation, rangeFrom, rangeTo) end

--[[ common/ac_extras_hashspace.lua ]]

---@param cellSize number @Should be about twice as large as your largest entity.
---@return ac.HashSpace
function ac.HashSpace(cellSize) end

--[[ common/ac_extras_numlut.lua ]]

---@param data string @String with LUT data, in a format similar to AC LUT formats. Please note: rows must be ordered for efficient binary search.
---@param hsvColumns integer[] @1-based indices of columns storing HSV data. Such columns, of course, will be interpolated differently (for example, mixing hues 350 and 20 would produce 10).
---@return ac.Lut
function ac.Lut(data, hsvColumns) end

---@type ac.Lut
ac.LutCpp = ac.Lut

---Creates new ac.LuaJit instance. Deprecated and broken, use `ac.Lut` instead.
---@deprecated
---@param data any
---@param hsvRows integer[] @ 1-based indices of columns (not rows) storing HSV values in them.
---@return table
function ac.LutJit:new(o, data, hsvRows) end

--[[ common/ac_extras_onlineevent.lua ]]

---Creates a new type of online event to exchange between scripts running on different clients in an online
---race. Example:
---```
---local chatMessageEvent = ac.OnlineEvent({
---  -- message structure layout:
---  message = ac.StructItem.string(50),
---  mood = ac.StructItem.float(),
---}, function (sender, data)
---  -- got a message from other client (or ourselves; in such case `sender.index` would be 0):
---  ac.debug('Got message: from', sender and sender.index or -1)
---  ac.debug('Got message: text', data.message)
---  ac.debug('Got message: mood', data.mood)
---end)
---
----- sending a new message:
---chatMessageEvent{ message = 'hello world', mood = 5 }
---```
---
---Note: to exchange messages between two scripts, both of them chould use `ac.OnlineEvent()` and pass exactly the same layouts. Also, consider using more
---specific names to avoid possible unwanted collisions. For example, instead of using `value = ac.StructItem.int()` which might be
---used somewhere else, use `mySpecificValue = ac.StructItem.int()`. Or, simply add `ac.StructItem.key('myUniqueKey')`.
---
---For safety reasons, car scripts can only exchange messages with other car scripts, and track scripts can only exchange messages with other track scripts.
---Your own messages will arrive to you as well unless you were to use `target` with ID different from your session ID, you might need to filter out those
---messages.
---
---If the server is not a custom AC Server (use `ac.getSim().directMessagingAvailable` to check), but the original implementation, following restrictions apply:
---- Each message should be smaller than 175 bytes.
---- At least 200 ms should pass between sending messages.
---- UDP messages are not available (those require `ac.getSim().directUDPMessagingAvailable` flag).
---- Don’t use this system to exchange data too often: it uses chat messages to transfer data, so it’s far from optimal.
---@generic T
---@param layout T @A table containing fields of structure and their types. Use `ac.StructItem` methods to select types. Alternatively, you can pass a string for the body of the structure here, but be careful with it.
---@param callback fun(sender: ac.StateCar|nil, message: T) @Callback that will be called when a new message of this type is received. Note: it would be called even if message was sent from this script. Use `sender` to check message origin: if it’s `nil`, message has come from the server, if its `.index` is 0, message has come from this client (and possibly this script).
---@param namespace nil|ac.SharedNamespace @Optional namespace stopping scripts of certain types to access data of scripts with different types. For more details check `ac.SharedNamespace` documentation.
---@param udp nil|boolean|{range: number} @Pass `true` to use UDP messages (available for Lua apps and online scripts only). Use `ac.getSim().directUDPMessagingAvailable` to check if you could use `udp` flag before hand. Note: enabling this option means `repeatForNewConnections` parameter will be ignored. Alternatively, pass a table with advanced UDP settings.
---@param params {processPostponed: boolean?}? @Extra params. Set `processPostponed` to process previously received TCP messages (up to 256, callback will be called in the next frame for all messages from first to last).
---@return fun(message: T?, repeatForNewConnections: nil|boolean, target: nil|integer): boolean @Function for sending new messages of newly created type. Pass a new table to set fields of a new message. If any field is missing, it would be set to the default zero state. Set `repeatForNewConnections` to `true` if this message should be re-sent later for newly connected cars (good if you’re announcing a change of state, like, for example, a custom car paint color). If after setting it to `true` a function would be called again without `repeatForNewConnections` set to `true`, further re-sending will be deactivated. Function returns `true` if message has been sent successfully, or `false` otherwise (for example, if rate limits were exceeded). Note: `repeatForNewConnections` is ignored for `udp` events. Parameter `target` can be used to specify session ID of a car that needs to receive the message. Use negative number to send message to everybody, or `255` to send it to the server (expecting some plugin to pick the message up). CSP builds before 2506 ignore messages with configured `target` parameter.
---@return fun(): T @This function returns the actual data pointer to which you could write arguments directly without having to create a new table, might be useful if you need to send a lot of messages (be careful though, there are all sorts of limits with the original AC server implementation). Call this function once, save the returned reference, and each time you need to send a new message fill it with required data and call the first function with `nil` as `message`.
function ac.OnlineEvent(layout, callback, namespace, udp, params) end

--[[ common/ac_extras_connectmmf.lua ]]

---Opens shared memory file for reading. Do not attempt to modify any of its contents: doing so pretty much always would result in Assetto Corsa
---just straight up crashing.
---@generic T
---@param filename string @Shared memory file filename (without “Local\” bit).
---@param layout T @String for the body of the structure.
---@param persist boolean? @Keep file alive even after the script stopped or the variable was cleared by garbage collector. Default value: `false`.
---@return T
---@overload fun(filename: string, layout: string, persist: boolean?): any
function ac.readMemoryMappedFile(filename, layout, persist) end

---Opens shared memory file for writing. Note: if the file would exist at the moment of opening (for example, created before by a different
---Lua script, or by a separate process), it would retain its current state, but if it’s a new file, it’ll be initialized with all zeroes.
---@generic T
---@param filename string @Shared memory file filename (without “Local\” bit).
---@param layout T @String for the body of the structure.
---@param persist boolean? @Keep file alive even after the script stopped or the variable was cleared by garbage collector. Default value: `false`.
---@return T
---@overload fun(filename: string, layout: string, persist: boolean?): any
function ac.writeMemoryMappedFile(filename, layout, persist) end

---Forcefully closes memory mapped file opened either for reading or writing without waiting for GC to pick it up.
function ac.disposeMemoryMappedFile(reference) end

--[[ common/ac_general_utils.lua ]]

---Estimates lap time and sector times for main car using AC function originally used by Time Attack mode. Could be
---helpful in creating custom time attack modes. Uses “ideal_line.ai” from “track folder/data”, so might not work
---well with mods. If that file is missing, returns nil.
---@return {lapTimeMs: integer, sectorTimesMs: integer[]}|nil @Returns table with times in milliseconds, or `nil` if  “ideal_lane.ai” is missing.
function ac.evaluateLapTime() end

--[[ common/ac_social.lua ]]

---Faster way to deal with driver tags. Any request of unsupported fields will return `false` for further extendability.
---Scripts with access to I/O can also alter fields.
---@param driverName string 
---@return ac.DriverTags
function ac.DriverTags(driverName) end

---Faster way to deal with driver tags. Any request of unsupported fields will return `false` for further extendability.
---Scripts with access to I/O can also alter fields.
---@class ac.DriverTags
---@field color rgbm @User name color. Could be derived from custom color set via `ac.DriverTags` (or `ac.setDriverChatNameColor()`), turns reddish if driver is muted, or uses custom driver tag from CM if any is set, or turns greenish if driver is marked as a friend (in CSP or CM). For the player entry it will always be yellow.
---@field friend boolean @Friend tag, uses CSP and CM databases.
---@field muted boolean @Muted tag, if set messages in chat will be hidden.
local _ac_DriverTags = nil
function ac.DriverTags(driverName) end

---Checks if a user is tagged as a friend. Uses CSP and CM databases. Deprecated, use `ac.DriverTags` instead.
---@deprecated
---@param driverName string @Driver name.
---@return boolean
function ac.isTaggedAsFriend(driverName) end

---Tags user as a friend (or removes the tag if `false` is passed). Deprecated, use `ac.DriverTags` instead.
---@deprecated
---@param driverName string @Driver name.
---@param isFriend boolean? @Default value: `true`.
function ac.tagAsFriend(driverName, isFriend) end

--[[ common/ac_music.lua ]]

---Information about currently playing track. Use function `ac.currentlyPlaying()` to get
---a reference to it.
---
---To draw album cover, pass `ac.MusicData` as an argument to something like `ui.image()`.
---@class ac.MusicData
---@field isPlaying boolean @If `true`, music is currently playing.
---@field hasCover boolean @If `true`, album cover is present.
---@field title string @Name of currently playing track.
---@field album string @Name of currently playing album (if not available, an empty string).
---@field artist string @Name of currently playing artist (if not available, an empty string).
---@field sourceID string @Source ID from where track is coming from. To draw an icon for it, pass it as Icon24 ID. You can check if there is an icon using `ui.isKnownIcon24(playing.sourceID)`.
---@field albumTracksCount integer @Number of tracks in current album, or 0 if value is not available.
---@field trackNumber integer @1-based track number in current album, or 0 if value is not available.
---@field trackDuration integer @Track duration in seconds, or -1 if value is not available.
---@field trackPosition integer @Track position in seconds, or -1 if value is not available.
local _musicData = {}

--[[ common/ac_music.lua ]]

---Syncs information about currently playing music and returns a table with details. Takes data from
---Windows 10 Media API, or from other sources configured in Music module of CSP.
---@return ac.MusicData
function ac.currentlyPlaying() end

--[[ common/ac_weatherconditions.lua ]]

---State of the track surface.
---@param sessionStart number "From 0 to 100."
---@param sessionTransfer number "From 0 to 100."
---@param randomness number 
---@param lapGain number 
---@return ac.TrackConditions
function ac.TrackConditions(sessionStart, sessionTransfer, randomness, lapGain) end

---State of the track surface.
---@class ac.TrackConditions
---@field sessionStart number @From 0 to 100.
---@field sessionTransfer number @From 0 to 100.
---@field randomness number
---@field lapGain number
local _ac_TrackConditions = nil

---@param ambient number "Temperature in C°."
---@param road number "Temperature in C°."
---@return ac.TemperatureParams
function ac.TemperatureParams(ambient, road) end

---@class ac.TemperatureParams
---@field ambient number @Temperature in C°.
---@field road number @Temperature in C°.
local _ac_TemperatureParams = nil

---@param direction number "Direction in degrees."
---@param speedFrom number "Speed in km/h."
---@param speedTo number "Speed in km/h."
---@return ac.WindParams
function ac.WindParams(direction, speedFrom, speedTo) end

---@class ac.WindParams
---@field direction number @Direction in degrees.
---@field speedFrom number @Speed in km/h.
---@field speedTo number @Speed in km/h.
local _ac_WindParams = nil

---@return ac.ConditionsSet
function ac.ConditionsSet() end

---@class ac.ConditionsSet
---@field currentType ac.WeatherType
---@field upcomingType ac.WeatherType
---@field temperatures ac.TemperatureParams
---@field trackState ac.TrackConditions
---@field wind ac.WindParams
---@field transition number @From 0 to 1 (if you’re doing linear transition, better to apply `math.smoothstep()` function to this value).
---@field humidity number @From 0 to 1, 1 for 100% humidity.
---@field pressure number @Pressure In pascals.
---@field variableA number @Custom value for extra data to exchange between controller and implementation (please remember that controller can be swapped with a different one).
---@field variableB number @Custom value for extra data to exchange between controller and implementation (please remember that controller can be swapped with a different one).
---@field variableC number @Custom value for extra data to exchange between controller and implementation (please remember that controller can be swapped with a different one).
---@field rainIntensity number @From 0 to 1, 0.5 for a good heavy-ish rain, everything above is for more absurd thunderstorms.
---@field rainWetness number @From 0 to 1, quickly goes to 1 as rain starts pouring, quickly goes to 0 when rain stops.
---@field rainWater number @Amount of puddles, should slowly move towards rainIntensity value.
local _ac_ConditionsSet = nil

--[[ common/ac_state.lua ]]

---Returns reference to a structure with various information about the state of a car. Very cheap to use.
---This is a new version with shorter name and 0-based indexing (to match other API functions).
---
---Updates once per graphics frame. You can use it in physics scripts to access things such as tyre radius, but
---for anything live there please look for specialized physics-rate updating values.
---
---Note: index starts with 0. Make sure to check result for `nil` if you’re accessing a car that might not be there. First car
---with index 0 is always there.
---@param index integer @0-based index.
---@return ac.StateCar?
function ac.getCar(index) end

---Returns Nth closest to camera car (pass 0 to get an ID of the nearest car). Inactive cars don’t count, so the number of cars
---here might be smaller than total number of cars in the race.
---@param index integer @0-based index.
---@return ac.StateCar?
function ac.getCar.ordered(index) end

---Returns Nth car in the race leaderboard (uses lap times in practice and qualify sessions). Pass 0 to get the top one.
---@param index integer @0-based index.
---@return ac.StateCar?
function ac.getCar.leaderboard(index) end

---Returns Nth car in server entry list. Pass 0 to get the first one. In offline races returns `nil`.
---@param index integer @0-based index.
---@return ac.StateCar?
function ac.getCar.serverSlot(index) end

---Iterates over all the cars from one with 0th index to the last one. Use in a for-loop. To get a Nth car, use `ac.getCar()`.
---
---Example:
---```
---for i, c in ac.iterateCars() do
---  ac.debug(i, car.position)
---end
---```
---@return fun(): integer, ac.StateCar @Iterator to be used in a loop (1-based index and car state)
function ac.iterateCars() end

---Iterates over active cars (excluding disconnected ones online) from nearest to furthest. Use in a for-loop. To get a Nth car, use `ac.getCar.ordered()`.
---
---Example:
---```
---for i, c in ac.iterateCars.ordered() do
---  ac.debug(i, car.position)
---end
---```
---@param inverse boolean? @Set to `true` to iterate in inverse order (available since 0.2.5).
---@return fun(): integer, ac.StateCar @Iterator to be used in a loop (1-based index and car state)
function ac.iterateCars.ordered(inverse) end

---Iterates over cars from first to last in the race leaderboard (uses lap times in practice and qualify sessions). Use in a for-loop. To get a Nth car, use `ac.getCar.leaderboard()`.
---
---Example:
---```
---for i, c in ac.iterateCars.leaderboard() do
---  ac.debug(i, car.position)
---end
---```
---@return fun(): integer, ac.StateCar @Iterator to be used in a loop (1-based index and car state)
function ac.iterateCars.leaderboard() end

---Iterates over cars based on their `sessionID` (index of a session slot). Use in a for-loop. To get a Nth car, use `ac.getCar.serverSlot()`. In offline races
---returns an empty iterator.
---
---Example:
---```
---for i, c in ac.iterateCars.leaderboard() do
---  ac.debug(i, car.position)
---end
---```
---@return fun(): integer, ac.StateCar @Iterator to be used in a loop (1-based index and car state)
function ac.iterateCars.serverSlots() end

--[[ common/ac_state.lua ]]

---@class ac.StateCar
local _ac_StateCar = nil

---@return string
function _ac_StateCar:skin() end

---@return string
function _ac_StateCar:tyresName() end

---@return string
function _ac_StateCar:tyresLongName() end

---@return string
function _ac_StateCar:id() end

---@return string
function _ac_StateCar:name() end

---@return string
function _ac_StateCar:brand() end

---@return string
function _ac_StateCar:country() end

---@return string
function _ac_StateCar:driverName() end

---@return string
function _ac_StateCar:driverNationCode() end

---@return string
function _ac_StateCar:driverNationality() end

---@return string
function _ac_StateCar:driverTeam() end

---@return string
function _ac_StateCar:driverNumber() end

--[[ common/ac_storage.lua ]]

---@class ac.StoredValue
local _ac_StoredValue = {}

---@return string|number|boolean|vec2|vec3|vec4|rgb|rgbm
function _ac_StoredValue:get() end

---@param value string|number|boolean|vec2|vec3|vec4|rgb|rgbm
function _ac_StoredValue:set(value) end

---Storage function. Easiest way to use is to pass it a table with default values — it would give you a table back
---which would load values on reads and save values on writes. Values have to be either strings, numbers, booleans,
---vectors or colors. Example:
---```
---local storedValues = ac.storage{
---  someKey = 15,
---  someStringValue = 20
---}
---storedValues.someKey = 20
---```
---Alternatively, you can use it as a function which would take a key and a default value and return you an
---`ac.StoredValue` wrapper with methods `:get()` and `:set(newValue)`:
---```
---local stored = ac.storage('someKey', 15)
---stored:get()
---stored:set(20)
---```
---Or, just access it directly in `localStorage` style of JavaScript. Similar to JavaScript, this way you can only store
---strings:
---```
---ac.storage.key = 'value'
---ac.debug('loaded', ac.storage.key)
---```
---Data will be saved in “Documents\Assetto Corsa\cfg\extension\state\lua”, in corresponding subfolder. Actual writing
---will happen a few seconds after new value was pushed, and only if value was changed, so feel free to use this function
---to write things often.
---@generic T
---@param layout T
---@param keyPrefix string|nil @Optional parameter for adding a prefix to keys.
---@return T
---@overload fun(key: string, value: string|number|boolean|vec2|vec3|vec4|rgb|rgbm): ac.StoredValue
function ac.storage(layout, keyPrefix) end

--[[ common/ac_storage.lua ]]

---Checks if storage table created by `ac.storage(table)` has a certain key or not.
---@param storage any
---@param key string
---@return boolean
function ac.storageHasKey(storage, key) end

---Returns `true` if any storage value has changed since the previous call.
---@return boolean
function ac.storageChanged() end

--[[ common/ac_configs.lua ]]

---@class ac.ConfigProvider
local _ac_ConfigProvider = {}

---@param section string
---@param key string
---@param defaultValue boolean|nil
---@return boolean
function _ac_ConfigProvider.bool(section, key, defaultValue) end

---@param section string
---@param key string
---@param defaultValue number
---@return number
function _ac_ConfigProvider.number(section, key, defaultValue) end

---@param section string
---@param key string
---@param defaultValue string|nil
---@return string
function _ac_ConfigProvider.string(section, key, defaultValue) end

---@param section string
---@param key string
---@param defaultValue rgb|nil
---@return rgb
function _ac_ConfigProvider.rgb(section, key, defaultValue) end

---@param section string
---@param key string
---@param defaultValue rgbm|nil
---@return rgbm
function _ac_ConfigProvider.rgbm(section, key, defaultValue) end

---@param section string
---@param key string
---@param defaultValue vec2|nil
---@return vec2
function _ac_ConfigProvider.vec2(section, key, defaultValue) end
---@param section string
---@param key string
---@param defaultValue vec3|nil
---@return vec3
function _ac_ConfigProvider.vec3(section, key, defaultValue) end

---@param section string
---@param key string
---@param defaultValue vec4|nil
---@return vec4
function _ac_ConfigProvider.vec4(section, key, defaultValue) end

---Reads a value from the config of currently loaded track. To use it, you need to specify `defaultValue` value, it would be used to determine
---the type of the value you need (and would be returned if value in config is missing).
---
---Alternatively, if called without arguments, returns ac.ConfigProvider which then can be used to access
---values in a typed manner. For it, `defaultValue` is optional.
---@generic T
---@param section string @Section name in config (the one in square brackets).
---@param key string @Config key (value before “=” sign).
---@param defaultValue T @Value that’s returned as a result if value is missing. Also determines the type needed.
---@return T
---@overload fun(): ac.ConfigProvider
function ac.getTrackConfig(section, key, defaultValue) end

---Reads a value from the config of a car. To use it, you need to specify `defaultValue` value, it would be used to determine
---the type of the value you need (and would be returned if value in config is missing).
---
---Alternatively, if called with car index only, returns ac.ConfigProvider which then can be used to access
---values in a typed manner. For it, `defaultValue` is optional.
---@generic T
---@param carIndex integer @0-based car index.
---@param section string @Section name in config (the one in square brackets).
---@param key string @Config key (value before “=” sign).
---@param defaultValue T @Value that’s returned as a result if value is missing. Also determines the type needed.
---@return T
---@overload fun(carIndex: integer): ac.ConfigProvider
function ac.getCarConfig(carIndex, section, key, defaultValue) end

--[[ common/ac_reftypes.lua ]]

---Stores a boolean value and can be used as a reference to it.
---@param value boolean "Stored value."
---@return refbool
function refbool(value) end

---Stores a boolean value and can be used as a reference to it.
---@class refbool
---@field value boolean @Stored value.
local refbool = nil

---@return boolean
function refbool.isrefbool(x) end

---For easier use with UI controls.
---@param newValue boolean|`true`|`false`
---@return refbool
function refbool:set(newValue) end

---Stores a numerical value and can be used as a reference to it.
---@param value number "Stored value."
---@return refnumber
function refnumber(value) end

---Stores a numerical value and can be used as a reference to it.
---@class refnumber
---@field value number @Stored value.
local refnumber = nil

---@return boolean
function refnumber.isrefnumber(x) end

---For easier use with UI controls.
---@param newValue number
---@return refnumber
function refnumber:set(newValue) end

--[[ common/ac_dualsense.lua ]]

---Return table with gamepad indices for keys and 0-based indices of associated cars for values.
---@return table<integer, integer>
function ac.getDualSenseControllers() end

--[[ common/ac_dualshock.lua ]]

---Return table with gamepad indices for keys and 0-based indices of associated cars for values.
---@return table<integer, integer>
function ac.getDualShockControllers() end

--[[ common/ac_web.lua ]]

---@class WebResponse
---@field status integer
---@field headers table<string, string>
---@field body string
local _webResponse = {}

---Two possible ways to present payload: either as a string with data, or a table with a key `'filename'`.
---Second way can be used as a shortcut for `io.loadAsync()` (it loads data asyncronously).
---Data string can contain zeroes.
---@alias WebPayload string|{filename: string}

--[[ common/ac_web.lua ]]

---Web module.
web = {}

---Configures timeouts in milliseconds for the following web requests. If you’re sure in your server, consider lowering timeouts so that
---in a case of a missing internet connection it wouldn’t take forever to determine the issue. Parameters will be passed to `WinHttpSetTimeouts()`
---function (https://learn.microsoft.com/en-us/windows/win32/api/winhttp/nf-winhttp-winhttpsettimeouts).
---@param resolve integer? @Time in milliseconds for DNS resolve, 0 to disable timeout. Default value: 4000 ms.
---@param connect integer? @Time in milliseconds for establishing connection. Default value: 10000 ms.
---@param send integer? @Time in milliseconds for sending data. Default value: 30000 ms.
---@param receive integer? @Time in milliseconds for receiving data. Default value: 30000 ms.
function web.timeouts(resolve, connect, send, receive) end

---Sends a GET HTTP or HTTPS request. Note: you can only have two requests running at once, mostly to make sure
---a faulty script wouldn’t spam a remote server or overload internet connection (that’s how I lost access
---to one of my API tokens for some time, accidentally sending a request each frame).
---@param url string @URL.
---@param headers table<string, string|number|boolean>? @Optional headers. Use special `[':headers-only'] = true` header if you only need to load headers (for servers without proper support of HEAD method).
---@param callback fun(err: string, response: WebResponse)
---@overload fun(url: string, callback: fun(err: string, response: WebResponse))
function web.get(url, headers, callback) end

---Sends a POST HTTP or HTTPS request. Note: you can only have two requests running at once, mostly to make sure
---a faulty script wouldn’t spam a remote server or overload internet connection (that’s how I lost access
---to one of my API tokens for some time, accidentally sending a request each frame).
---@param url string @URL.
---@param headers table<string, string|number|boolean>? @Optional headers. Use special `[':headers-only'] = true` header if you only need to load headers (for servers without proper support of HEAD method).
---@param data WebPayload? @Optional data.
---@param callback fun(err: string, response: WebResponse)
---@overload fun(url: string, data: string, callback: fun(err: string, response: WebResponse))
---@overload fun(url: string, callback: fun(err: string, response: WebResponse))
function web.post(url, headers, data, callback) end

---Sends a custom HTTP or HTTPS request. Note: you can only have two requests running at once, mostly to make sure
---a faulty script wouldn’t spam a remote server or overload internet connection (that’s how I lost access
---to one of my API tokens for some time, accidentally sending a request each frame).
---@param method "'GET'"|"'POST'"|"'PUT'"|"'HEAD'"|"'DELETE'"|"'PATCH'"|"'OPTIONS'" @HTTP method.
---@param url string @URL.
---@param headers table<string, string|number|boolean>? @Optional headers. Use special `[':headers-only'] = true` header if you only need to load headers (for servers without proper support of HEAD method).
---@param data WebPayload? @Optional data.
---@param callback fun(err: string, response: WebResponse)
---@overload fun(method: string, url: string, data: string, callback: fun(err: string, response: WebResponse))
---@overload fun(method: string, url: string, callback: fun(err: string, response: WebResponse))
function web.request(method, url, headers, data, callback) end

---@alias web.SocketParams {onError: nil|fun(err: string), onClose: nil|fun(reason: string?), encoding: nil|'binary'|'utf8'|'json'|'lson', reconnect: boolean?} ---Use property `reconnect` to automatically try and restore connection a few seconds after it got lost. With it, `onError` might be called multiple times, but `onClose` is only called once connection is closed by calling `web.Socket.close()`.
---@alias web.Socket {close: fun()}|fun(data: binary)

---Open a WebSocket connection.
---@param url string @URL.
---@param headers table<string, string|number|boolean>? @Optional headers.
---@param callback nil|fun(data: binary)
---@param params web.SocketParams?
---@return web.Socket
---@overload fun(url: string, callback: fun(data: binary), params: web.SocketParams): web.Socket
function web.socket(url, headers, callback, params) end

--[[ common/ac_physics_unrestricted.lua ]]

---Physics namespace. Note: most functions here are accessible only if track has expicitly allowed it with its
---extended CSP physics.
---
---To allow scriptable physics, add to surfaces.ini:
---```ini
---[_SCRIPTING_PHYSICS]
---ALLOW_TRACK_SCRIPTS=1    ; choose ones that you need
---ALLOW_DISPLAY_SCRIPTS=1
---ALLOW_NEW_MODE_SCRIPTS=1
---ALLOW_TOOLS=1
---```
---
---And to activate extended physics, use:
---```ini
---[SURFACE_0]
---WAV_PITCH=extended-0
---```
physics = {}

--[[ common/stringify.lua ]]

---Serialize Lua value (table, number, string, etc.) in a Lua table format (similar to how `JSON.stringify` in JavaScript
---generates a thing with JavaScript syntax). Format seems to be called Luaon. Most of Lua entities are supported, including array-like tables, table
---tables and mixed ones. CSP API things, such as vectors or colors, are also supported. For things like threads,
---functions or unknown cdata types instead a placeholder object will be created.
---
---Circular references also result in creating similar objects, for example: `t = {1, 2, 3, t}` would result in
---`{ 1, 2, 3, { type = 'circular reference' } }`.
---
---If any table in given data would have a `__stringify()` function, it would be called as a method (so first argument
---would be the table with `__stringify` itself). If that function would return a string, that string will be used
---instead of regular table serialization. The idea is for classes to define a method like this and output a line of code
---which could be used to create a new instance like this on deserialization. Note: for such like to use a custom function
---like a class constructor, you would either need to register that function with a certain name or provide a table referring
---to it on deserialization. That’s because although deserialization uses `load()` function to parse and run data as Lua code,
---it wouldn’t allow code to access existing functions by default.
---@param obj table|number|string|boolean|nil @Object to serialize.
---@param compact boolean? @If true, resulting string would not have spaces and line breaks, slightly faster and a lot more compact.
---@param depthLimit integer? @Limits how deep serialization would go. Default value: 20.
---@return string @String with input data presented in Lua syntax.
function stringify(obj, compact, depthLimit) end

---Parse a string with Lua table syntax into a Lua object (table, number, string, vector, etc.), can support custom objects as well.
---Only functions from `namespace` can be used (as well as vectors and functions registered earlier with `stringify.register()`),
---so if you’re using custom classes, make sure to either register them earlier or pass them in `namespace` table. Alternatively,
---you can just pass `_G` as `namespace`, but it might be pretty unsecure, so maybe don’t do it.
---
---Would raise an error if failed to parse or if any of initializers would raise an error.
---@param serialized string @Serialized data.
---@param namespace table|nil @Namespace table. Serialized data would be evaluated as Lua code and would have access to it.
---@return table|number|string|boolean|nil
function stringify.parse(serialized, namespace) end

---Parse a string with Lua table syntax into a Lua object (table, number, string, vector, etc.), can support custom objects as well.
---Only functions from `namespace` can be used (as well as vectors and functions registered earlier with `stringify.register()`),
---so if you’re using custom classes, make sure to either register them earlier or pass them in `namespace` table. Alternatively,
---you can just pass `_G` as `namespace`, but it might be pretty unsecure, so maybe don’t do it.
---
---Returns fallback value if failed to parse, or if `serialized` is empty or not set, or if any of initializers would raise an error.
---@generic T
---@param serialized string? @Serialized data.
---@param namespace table|nil @Namespace table. Serialized data would be evaluated as Lua code and would have access to it.
---@param fallback T|nil @Value to return if parsing failed.
---@return T
function stringify.tryParse(serialized, namespace, fallback) end

---Registers a new initializer function with a given name.
---@param name string @Name of an initializer (how serialized data would refer to it).
---@param fn function @Initializer function (returning value for serialized data to use).
---@overload fun(class: ClassDefinition)
function stringify.register(name, fn) end

---Serialization substep. Works similar to `stringify()` itself, but instead of returning string simply adds new terms to
---`out` table. Use it in custom `__stringify` methods for serializing child items if you need the best performance.
---@param out string[] @Output table with words to concatenate later (without any joining string).
---@param ptr integer @Position within `out` table to write next word into. At the very start, when table is empty, it would be 1.
---@param obj any @Item to serialize.
---@param lineBreak string|nil @Line break with some spaces for aligning child items, or `nil` if compact stringify mode is used. One tab is two spaces.
---@param depthLimit integer @Limits how many steps down serialization can go. If 0 or below, no tables would be serialized.
---@return integer @Updated `ptr` value (if one item was added to `out`, should increase by 1).
function stringify.substep(out, ptr, obj, lineBreak, depthLimit) end

---Different serializer, produces binary data instead of human-readable. Faster and with even more compact output, but not human-readable.
---@param obj table|number|string|boolean|nil @Object to serialize.
---@return string @String with input data presented in binary format, so it won’t be readable and will contain zero bytes.
function stringify.binary(obj) end

---Parses binary data prepared with `stringify.binary()`.
---@param serialized string @Serialized data.
---@return table|number|string|boolean|nil
function stringify.binary.parse(serialized) end

---Tries to parse binary data prepared with `stringify.binary()`.
---
---Returns fallback value if failed to parse, or if `serialized` is empty or not set, or if any of initializers would raise an error.
---@generic T
---@param serialized string? @Serialized data.
---@param fallback T|nil @Value to return if parsing failed.
---@return T
function stringify.binary.tryParse(serialized, fallback) end

---A small helper to add as a parent class for EmmyLua to work better.
---@class ClassStringifiable : ClassBase
local _classStringifiable = {}

---Serialize instance of class. Can either return a `string`, or construct it into `out` table and return a new position in it. String itself should be a like of
---Lua code which would reconstruct the object on deserialization. Don’t forget to either register referred function with `stringify.register()` or provide
---a reference to it in `namespace` table with `stringify.parse()`.
---
---Note: to serialize sub-objects, such as constructor arguments, you can use `stringify()` or `stringify.substep()` if you’re using an approach with
---manually constructing `out` table. Alternatively for basic types you can use `string.format()`: “%q” would give you a string in Lua format, so you can use it
---like so:
---```
---function MyClass:__serialize()
---  return string.format('MyClass(%q, %s)', self.stringName, self.numericalCounter)
---end
---```
---@param out string[] @Output table with words to concatenate later (without any joining string).
---@param ptr integer @Position within `out` table to write next word into. At the very start, when table is empty, it would be 1.
---@param obj any @Item to serialize.
---@param lineBreak string|nil @Line break with some spaces for aligning child items, or `nil` if compact stringify mode is used. One tab is two spaces.
---@param depthLimit integer @Limits how many steps down serialization can go. If 0 or below, no tables would be serialized.
---@return integer @Updated `ptr` value (if one item was added to `out`, should increase by 1).
---@overload fun(): string @Simpler version which should work well in 98% of times. Use a more detailed one only if you have a ton of objects and need to improve performance.
function _classStringifiable:__stringify(out, ptr, obj, lineBreak, depthLimit) end

--[[ common/json.lua ]]

---Very basic JSON processing library. Based on json.lua by rxi, but a bit simplified and streamlined.
---In case you need to store and load data within Lua scripts, consider using `stringify()` and 
---`stringify.parse()` instead: it’s faster and more reliable.
JSON = {}

---Serializes a Lua entity (like a table) into a compact JSON.
---@param data table|number|string|boolean|nil
---@return string
function JSON.stringify(data) end

---Parses a compact JSON into a Lua entity. Note: if JSON is damaged, parser won’t throw an error, but
---results might be somewhat unpredictable. It’s an intended behaviour: in 99% of cases JSON parser
---used to exchange data with, for example, API endpoints, will receive correct data, but some of those
---AC JSON files are pretty screwed and often include things like missing commas, comments, etc.
---@param data string?
---@return any
function JSON.parse(data) end

--[[ common/ac_primitive_vec2.d.lua ]]

---Creates new vector. It’s usually faster to create a new item with `vec2(x, y)` directly, but the way LuaJIT works,
---that call only works with two numbers. If you only provide a single number, rest will be set to 0. This call, however, supports
---various calls (which also makes it slightly slower).
---@overload fun(value: vec2): vec2
---@overload fun(tableOfTwo: number[]): vec2
---@overload fun(value: number): vec2
---@overload fun(value: string): vec2
---@param x? number
---@param y? number
---@return vec2
function vec2.new(x, y) end

---Checks if value is vec2 or not.
---@param p any
---@return boolean
function vec2.isvec2(p) end

---Temporary vector. For most cases though, it might be better to define those locally and use those. Less chance of collision.
---@return vec2
function vec2.tmp() end

---Intersects two line segments, one going from `p1` to `p2` and another going from `p3` to `p4`. Returns intersection point or `nil` if there is no intersection.
---@return vec2?
function vec2.intersect(p1, p2, p3, p4) end

---Two-dimensional vector. All operators are overloaded. Note: creating a lot of new vectors can create extra work for garbage collector reducing overall effectiveness.
---Where possible, instead of using mathematical operators consider using methods altering state of already existing vectors. So, instead of:
---```
---someVec = vec2()
---…
---someVec = math.normalize(vec1 + vec2) * 10
---```
---Consider rewriting it like:
---```
---someVec = vec2()
---…
---someVec:set(vec1):add(vec2):normalize():scale(10)
---```
---@param x number? 
---@param y number? 
---@return vec2
function vec2(x, y) end

---Two-dimensional vector. All operators are overloaded. Note: creating a lot of new vectors can create extra work for garbage collector reducing overall effectiveness.
---Where possible, instead of using mathematical operators consider using methods altering state of already existing vectors. So, instead of:
---```
---someVec = vec2()
---…
---someVec = math.normalize(vec1 + vec2) * 10
---```
---Consider rewriting it like:
---```
---someVec = vec2()
---…
---someVec:set(vec1):add(vec2):normalize():scale(10)
---```
---@class vec2
---@field x number
---@field y number
---@operator add(number|vec2): vec2
---@operator sub(number|vec2): vec2
---@operator mul(number|vec2): vec2
---@operator div(number|vec2): vec2
---@operator pow(number|vec2): vec2
---@operator len: number
---@operator unm: vec2
local vec2 = nil

---Makes a copy of a vector.
---@return vec2
function vec2:clone() end

---Unpacks vec2 into two numbers.
---@return number, number
function vec2:unpack() end

---Turns vec2 into a table with two values.
---@return number[]
function vec2:table() end

---Returns reference to vec2 class.
function vec2:type() end

---@param x vec2|number
---@param y number?
---@return vec2 @Returns itself.
function vec2:set(x, y) end

---@param vec vec2
---@param scale number
---@return vec2 @Returns itself.
function vec2:setScaled(vec, scale) end

---@param value1 vec2
---@param value2 vec2
---@param mix number
---@return vec2 @Returns itself.
function vec2:setLerp(value1, value2, mix) end

---Copies its values to a different vector.
---@param out vec2
---@return vec2 @Returns itself.
function vec2:copyTo(out) end

---@param valueToAdd vec2|number
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:add(valueToAdd, out) end

---@param valueToAdd vec2
---@param scale number
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:addScaled(valueToAdd, scale, out) end

---@param valueToSubtract vec2|number
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:sub(valueToSubtract, out) end

---@param valueToMultiplyBy vec2
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:mul(valueToMultiplyBy, out) end

---@param valueToDivideBy vec2
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:div(valueToDivideBy, out) end

---@param exponent vec2|number
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:pow(exponent, out) end

---@param multiplier number
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:scale(multiplier, out) end

---@param otherValue vec2|number
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:min(otherValue, out) end

---@param otherValue vec2|number
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:max(otherValue, out) end

---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:saturate(out) end

---@param min vec2
---@param max vec2
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:clamp(min, max, out) end

---@return number
function vec2:length() end

---@return number
function vec2:lengthSquared() end

---@param otherVector vec2
---@return number
function vec2:distance(otherVector) end

---@param otherVector vec2
---@return number
function vec2:distanceSquared(otherVector) end

---@param otherVector vec2
---@param distanceThreshold number
---@return boolean
function vec2:closerToThan(otherVector, distanceThreshold) end

---@param otherVector vec2
---@return number @Radians.
function vec2:angle(otherVector) end

---@param otherVector vec2
---@return number
function vec2:dot(otherVector) end

---Normalizes itself (unless different `out` is provided).
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:normalize(out) end

---Rewrites own values with values of lerp of itself and other vector (unless different `out` is provided).
---@param otherVector vec2
---@param mix number
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:lerp(otherVector, mix, out) end

---Rewrites own values with values of projection of itself onto another vector (unless different `out` is provided).
---@param otherVector vec2
---@param out vec2|nil @Optional destination argument.
---@return vec2 @Returns itself or out value.
function vec2:project(otherVector, out) end

--[[ common/ac_primitive_vec3.d.lua ]]

---Creates new vector. It’s usually faster to create a new item with `vec3(x, y, z)` directly, but the way LuaJIT works,
---that call only works with three numbers. If you only provide a single number, rest will be set to 0. This call, however, supports
---various calls (which also makes it slightly slower).
---@overload fun(value: vec3): vec3
---@overload fun(tableOfThree: number[]): vec3
---@overload fun(value: number): vec3
---@overload fun(value: string): vec3
---@param x number?
---@param y number?
---@param z number?
---@return vec3
function vec3.new(x, y, z) end

---Checks if value is vec3 or not.
---@param p any
---@return boolean
function vec3.isvec3(p) end

---Temporary vector. For most cases though, it might be better to define those locally and use those. Less chance of collision.
---@return vec3
function vec3.tmp() end

---Three-dimensional vector. All operators are overloaded.
---Note: creating a lot of new vectors can create extra work for garbage collector reducing overall effectiveness.
---Where possible, instead of using mathematical operators consider using methods altering state of already existing vectors. So, instead of:
---```
---someVec = vec3()
---…
---someVec = math.normalize(vec1 + vec2) * 10
---```
---Consider rewriting it like:
---```
---someVec = vec3()
---…
---someVec:set(vec1):add(vec2):normalize():scale(10)
---```
---@param x number? 
---@param y number? 
---@param z number? 
---@return vec3
function vec3(x, y, z) end

---Three-dimensional vector. All operators are overloaded.
---Note: creating a lot of new vectors can create extra work for garbage collector reducing overall effectiveness.
---Where possible, instead of using mathematical operators consider using methods altering state of already existing vectors. So, instead of:
---```
---someVec = vec3()
---…
---someVec = math.normalize(vec1 + vec2) * 10
---```
---Consider rewriting it like:
---```
---someVec = vec3()
---…
---someVec:set(vec1):add(vec2):normalize():scale(10)
---```
---@class vec3
---@field x number
---@field y number
---@field z number
---@operator add(number|vec3): vec3
---@operator sub(number|vec3): vec3
---@operator mul(number|vec3): vec3
---@operator div(number|vec3): vec3
---@operator pow(number|vec3): vec3
---@operator len: number
---@operator unm: vec3
local vec3 = nil

---Makes a copy of a vector.
---@return vec3
function vec3:clone() end

---Unpacks vec3 into three numbers.
---@return number, number, number
function vec3:unpack() end

---Turns vec3 into a table with three values.
---@return number[]
function vec3:table() end

---Returns reference to vec3 class.
function vec3:type() end

---@param x vec3|number
---@param y number?
---@param z number?
---@return vec3 @Returns itself.
function vec3:set(x, y, z) end

---@param vec vec3
---@param scale number
---@return vec3 @Returns itself.
function vec3:setScaled(vec, scale) end

---@param value1 vec3
---@param value2 vec3
---@param mix number
---@return vec3 @Returns itself.
function vec3:setLerp(value1, value2, mix) end

---Sets itself to a normalized result of cross product of value1 and value2.
---@param value1 vec3
---@param value2 vec3
---@return vec3 @Returns itself.
function vec3:setCrossNormalized(value1, value2) end

---Copies its values to a different vector.
---@param out vec3
---@return vec3 @Returns itself.
function vec3:copyTo(out) end

---@param valueToAdd vec3|number
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:add(valueToAdd, out) end

---@param valueToAdd vec3
---@param scale number
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:addScaled(valueToAdd, scale, out) end

---@param valueToSubtract vec3|number
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:sub(valueToSubtract, out) end

---@param valueToMultiplyBy vec3
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:mul(valueToMultiplyBy, out) end

---@param valueToDivideBy vec3
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:div(valueToDivideBy, out) end

---@param exponent vec3|number
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:pow(exponent, out) end

---@param multiplier number
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:scale(multiplier, out) end

---@param otherValue vec3|number
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:min(otherValue, out) end

---@param otherValue vec3|number
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:max(otherValue, out) end

---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:saturate(out) end

---@param min vec3
---@param max vec3
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:clamp(min, max, out) end

---@return number
function vec3:length() end

---@return number
function vec3:lengthSquared() end

---@param otherVector vec3
---@return number
function vec3:distance(otherVector) end

---@param otherVector vec3
---@return number
function vec3:distanceSquared(otherVector) end

---@param otherVector vec3
---@param distanceThreshold number
---@return boolean
function vec3:closerToThan(otherVector, distanceThreshold) end

---@param otherVector vec3
---@return number @Radians.
function vec3:angle(otherVector) end

---@param otherVector vec3
---@return number
function vec3:dot(otherVector) end

---Normalizes itself (unless different `out` is provided).
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:normalize(out) end

---Rewrites own values with values of cross product of itself and other vector (unless different `out` is provided).
---@param otherVector vec3
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:cross(otherVector, out) end

---Rewrites own values with values of lerp of itself and other vector (unless different `out` is provided).
---@param otherVector vec3
---@param mix number
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:lerp(otherVector, mix, out) end

---Rewrites own values with values of projection of itself onto another vector (unless different `out` is provided).
---@param otherVector vec3
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:project(otherVector, out) end

---Rewrites own values with values of itself rotated with quaternion (unless different `out` is provided).
---@param quaternion quat
---@param out vec3|nil @Optional destination argument.
---@return vec3 @Returns itself or out value.
function vec3:rotate(quaternion, out) end

---Returns distance from point to a line. For performance reasons doesn’t do any checks, so be careful with incoming arguments.
---@return number
function vec3:distanceToLine(a, b) end

---Returns squared distance from point to a line. For performance reasons doesn’t do any checks, so be careful with incoming arguments.
---@return number
function vec3:distanceToLineSquared(a, b) end

--[[ common/ac_primitive_vec4.d.lua ]]

---Creates new vector. It’s usually faster to create a new item with `vec4(x, y, z, w)` directly, but the way LuaJIT works,
---that call only works with four numbers. If you only provide a single number, rest will be set to 0. This call, however, supports
---various calls (which also makes it slightly slower).
---@overload fun(value: vec4): vec4
---@overload fun(tableOfFour: number[]): vec4
---@overload fun(value: number): vec4
---@overload fun(value: string): vec4
---@param x number?
---@param y number?
---@param z number?
---@param w number?
---@return vec4
function vec4.new(x, y, z, w) end

---Checks if value is vec4 or not.
---@param p any
---@return boolean
function vec4.isvec4(p) end

---Temporary vector. For most cases though, it might be better to define those locally and use those. Less chance of collision.
---@return vec4
function vec4.tmp() end

---Four-dimensional vector. All operators are also overloaded.
---Note: creating a lot of new vectors can create extra work for garbage collector reducing overall effectiveness.
---Where possible, instead of using mathematical operators consider using methods altering state of already existing vectors. So, instead of:
---```
---someVec = vec4()
---…
---someVec = math.normalize(vec1 + vec2) * 10
---```
---Consider rewriting it like:
---```
---someVec = vec4()
---…
---someVec:set(vec1):add(vec2):normalize():scale(10)
---```
---@param x number? 
---@param y number? 
---@param z number? 
---@param w number? 
---@return vec4
function vec4(x, y, z, w) end

---Four-dimensional vector. All operators are also overloaded.
---Note: creating a lot of new vectors can create extra work for garbage collector reducing overall effectiveness.
---Where possible, instead of using mathematical operators consider using methods altering state of already existing vectors. So, instead of:
---```
---someVec = vec4()
---…
---someVec = math.normalize(vec1 + vec2) * 10
---```
---Consider rewriting it like:
---```
---someVec = vec4()
---…
---someVec:set(vec1):add(vec2):normalize():scale(10)
---```
---@class vec4
---@field x number
---@field y number
---@field z number
---@field w number
---@operator add(number|vec4): vec4
---@operator sub(number|vec4): vec4
---@operator mul(number|vec4): vec4
---@operator div(number|vec4): vec4
---@operator pow(number|vec4): vec4
---@operator len: number
---@operator unm: vec4
local vec4 = nil

---Makes a copy of a vector.
---@return vec4
function vec4:clone() end

---Unpacks vec4 into four numbers.
---@return number, number, number, number
function vec4:unpack() end

---Turns vec4 into a table with four values.
---@return number[]
function vec4:table() end

---Returns reference to vec4 class.
function vec4:type() end

---@param x vec4|number
---@param y number?
---@param z number?
---@param w number?
---@return vec4 @Returns itself.
function vec4:set(x, y, z, w) end

---@param vec vec4
---@param scale number
---@return vec4 @Returns itself.
function vec4:setScaled(vec, scale) end

---@param value1 vec4
---@param value2 vec4
---@param mix number
---@return vec4 @Returns itself.
function vec4:setLerp(value1, value2, mix) end

---Sets itself to a normalized result of cross product of value1 and value2.
---@param value1 vec4
---@param value2 vec4
---@return vec4 @Returns itself.
function vec4:setCrossNormalized(value1, value2) end

---Copies its values to a different vector.
---@param out vec4
---@return vec4 @Returns itself.
function vec4:copyTo(out) end

---@param valueToAdd vec4|number
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:add(valueToAdd, out) end

---@param valueToAdd vec4
---@param scale number
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:addScaled(valueToAdd, scale, out) end

---@param valueToSubtract vec4|number
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:sub(valueToSubtract, out) end

---@param valueToMultiplyBy vec4
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:mul(valueToMultiplyBy, out) end

---@param valueToDivideBy vec4
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:div(valueToDivideBy, out) end

---@param exponent vec4|number
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:pow(exponent, out) end

---@param multiplier number
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:scale(multiplier, out) end

---@param otherValue vec4|number
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:min(otherValue, out) end

---@param otherValue vec4|number
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:max(otherValue, out) end

---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:saturate(out) end

---@param min vec4
---@param max vec4
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:clamp(min, max, out) end

---@return number
function vec4:length() end

---@return number
function vec4:lengthSquared() end

---@param otherVector vec4
---@return number
function vec4:distance(otherVector) end

---@param otherVector vec4
---@return number
function vec4:distanceSquared(otherVector) end

---@param otherVector vec4
---@param distanceThreshold number
---@return boolean
function vec4:closerToThan(otherVector, distanceThreshold) end

---@param otherVector vec4
---@return number @Radians.
function vec4:angle(otherVector) end

---@param otherVector vec4
---@return number
function vec4:dot(otherVector) end

---Normalizes itself (unless different `out` is provided).
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:normalize(out) end

---Rewrites own values with values of lerp of itself and other vector (unless different `out` is provided).
---@param otherVector vec4
---@param mix number
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:lerp(otherVector, mix, out) end

---Rewrites own values with values of projection of itself onto another vector (unless different `out` is provided).
---@param otherVector vec4
---@param out vec4|nil @Optional destination argument.
---@return vec4 @Returns itself or out value.
function vec4:project(otherVector, out) end

--[[ common/ac_primitive_rgb.d.lua ]]

---Creates new instance. It’s usually faster to create a new item with `rgb(r, g, b, mult)` directly, but the way LuaJIT works,
---that call only works with three numbers. If you only provide a single number, rest will be set to 0. This call, however, supports
---various calls (which also makes it slightly slower).
---@overload fun(color: rgb): rgb
---@overload fun(color: rgbm): rgb
---@overload fun(color: hsv): rgb
---@overload fun(color: vec4): rgb
---@overload fun(color: vec3): rgb
---@overload fun(tableOfThree: number[]): rgb
---@overload fun(color: number): rgb
---@overload fun(value: string): rgb
---@param r number?
---@param g number?
---@param b number?
---@return rgb
function rgb.new(r, g, b, m) end

---Checks if value is rgb or not.
---@param p any
---@return boolean
function rgb.isrgb(p) end

---Temporary color. For most cases though, it might be better to define those locally and use those. Less chance of collision.
---@return rgb
function rgb.tmp() end

---Creates color from 0…255 values
---@param r number @From 0 to 255
---@param g number @From 0 to 255
---@param b number @From 0 to 255
---@return rgb
function rgb.from0255(r, g, b, a) end

---Predefined colors. Do not change them unless you want to have some extra fun debugging.
rgb.colors = { transparent = rgb(0, 0, 0), black = rgb(0, 0, 0), silver = rgb(0.75, 0.75, 0.75), gray = rgb(0.5, 0.5, 0.5), white = rgb(1, 1, 1), maroon = rgb(0.5, 0, 0), red = rgb(1, 0, 0), purple = rgb(0.5, 0, 0.5), fuchsia = rgb(1, 0, 1), green = rgb(0, 0.5, 0), lime = rgb(0, 1, 0), olive = rgb(0.5, 0.5, 0), yellow = rgb(1, 1, 0), orange = rgb(1, 0.5, 0), navy = rgb(0, 0, 0.5), blue = rgb(0, 0, 1), teal = rgb(0, 0.5, 0.5), cyan = rgb(0, 0.5, 1), aqua = rgb(0, 1, 1) }

---Three-channel color. All operators are overloaded. White is usually `rgb=1,1,1`.
---@param r number? 
---@param g number? 
---@param b number? 
---@return rgb
function rgb(r, g, b) end

---Three-channel color. All operators are overloaded. White is usually `rgb=1,1,1`.
---@class rgb
---@field r number
---@field g number
---@field b number
---@operator add(number|rgb): rgb
---@operator sub(number|rgb): rgb
---@operator mul(number|rgb): rgb
---@operator div(number|rgb): rgb
---@operator pow(number|rgb): rgb
---@operator len: number
---@operator unm: rgb
local rgb = nil

---Makes a copy of a vector.
---@return rgb
function rgb:clone() end

---Unpacks rgb into three numbers.
---@return rgb, number
function rgb:unpack() end

---Turns rgb into a table with three numbers.
---@return number[]
function rgb:table() end

---Returns reference to rgb class.
function rgb:type() end

---@param r rgb|number
---@param g number?
---@param b number?
---@return rgb @Returns itself.
function rgb:set(r, g, b) end

---@param x rgb
---@param mult number
---@return rgb @Returns itself.
function rgb:setScaled(x, mult) end

---@param value1 rgb
---@param value2 rgb
---@param mix number
---@return rgb @Returns itself.
function rgb:setLerp(value1, value2, mix) end

---@param valueToAdd rgb|number
---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:add(valueToAdd, out) end

---@param valueToAdd rgb
---@param scale number
---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:addScaled(valueToAdd, scale, out) end

---@param valueToSubtract rgb|number
---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:sub(valueToSubtract, out) end

---@param valueToMultiplyBy rgb
---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:mul(valueToMultiplyBy, out) end

---@param valueToDivideBy rgb
---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:div(valueToDivideBy, out) end

---@param exponent rgb|number
---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:pow(exponent, out) end

---@param multiplier number
---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:scale(multiplier, out) end

---@param otherValue rgb|number
---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:min(otherValue, out) end

---@param otherValue rgb|number
---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:max(otherValue, out) end

---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:saturate(out) end

---@param min rgb
---@param max rgb
---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:clamp(min, max, out) end

---Adjusts saturation using a very simple formula.
---@param saturation number
---@param out rgb|nil @Optional destination argument.
---@return rgb @Returns itself or out value.
function rgb:adjustSaturation(saturation, out) end

---Makes sure brightest value does not exceed 1.
---@return rgb @Returns itself.
function rgb:normalize() end

---Returns brightest value (aka V in HSV).
---@return number
function rgb:value() end

---Returns hue.
---@return number
function rgb:hue() end

---Returns saturation.
---@return number
function rgb:saturation() end

---Returns luminance value.
---@return number
function rgb:luminance() end

---Returns rgbm.
---@param mult number? @Default value: 1.
---@return rgbm
function rgb:rgbm(mult) end

---Returns HSV color of rgb*mult.
---@return hsv
function rgb:hsv() end

---Returns rgb*mult turned to vec3.
---@return vec3
function rgb:vec3() end

---Returns string with hex representation and leading “#”.
---@return string
function rgb:hex() end

--[[ common/ac_primitive_hsv.d.lua ]]

---Creates new instance. It’s usually faster to create a new item with `hsv(h, s, v)`.
---@param h number?
---@param s number?
---@param v number?
---@return hsv
function hsv.new(h, s, v) end

---Checks if value is hsv or not.
---@param p any
---@return boolean
function hsv.ishsv(p) end

---Temporary HSV color. For most cases though, it might be better to define those locally and use those. Less chance of collision.
---@return hsv
function hsv.tmp() end

---HSV color (hue, saturation, value). Equality operator is overloaded.
---@param h number? 
---@param s number? 
---@param v number? 
---@return hsv
function hsv(h, s, v) end

---HSV color (hue, saturation, value). Equality operator is overloaded.
---@class hsv
---@field h number
---@field s number
---@field v number
local hsv = nil

---Makes a copy of a vector.
---@return hsv
function hsv:clone() end

---Unpacks hsv into three numbers.
---@return rgb, number
function hsv:unpack() end

---Turns hsv into a table with three numbers.
---@return number[]
function hsv:table() end

---Returns reference to hsv class.
function hsv:type() end

---@param h number
---@param s number
---@param v number
---@return hsv @Returns itself.
function hsv:set(h, s, v) end

---Returns RGB color.
---@return rgb
function hsv:rgb() end

--[[ common/ac_primitive_rgbm.d.lua ]]

---Creates new instance. It’s usually faster to create a new item with `rgbm(r, g, b, mult)` directly, but the way LuaJIT works,
---that call only works with four numbers. If you only provide a single number, rest will be set to 0. This call, however, supports
---various calls (which also makes it slightly slower).
---@overload fun(color: rgbm): rgbm
---@overload fun(color: rgb): rgbm
---@overload fun(color: hsv): rgbm
---@overload fun(color: vec4): rgbm
---@overload fun(color: vec3): rgbm
---@overload fun(tableOfFour: number[]): rgbm
---@overload fun(hexColor: string): rgbm
---@overload fun(colorAlpha: number): rgbm
---@overload fun(color: number, alpha: number): rgbm
---@overload fun(color: rgb, alpha: number): rgbm
---@param r number?
---@param g number?
---@param b number?
---@param m number? @Default value: 1.
---@return rgbm
function rgbm.new(r, g, b, m) end

---Checks if value is rgbm or not.
---@param p any
---@return boolean
function rgbm.isrgbm(p) end

---Temporary vector. For most cases though, it might be better to define those locally and use those. Less chance of collision.
---@return rgbm
function rgbm.tmp() end

---Creates color from 0…255 values
---@param r number @From 0 to 255.
---@param g number @From 0 to 255.
---@param b number @From 0 to 255.
---@param a number? @From 0 to 1. Default value: 1.
---@return rgbm
function rgbm.from0255(r, g, b, a) end

---Predefined colors. Do not change them unless you want to have some extra fun debugging.
rgbm.colors = { transparent = rgbm(0, 0, 0, 0), black = rgbm(0, 0, 0, 1), silver = rgbm(0.75, 0.75, 0.75, 1), gray = rgbm(0.5, 0.5, 0.5, 1), white = rgbm(1, 1, 1, 1), maroon = rgbm(0.5, 0, 0, 1), red = rgbm(1, 0, 0, 1), purple = rgbm(0.5, 0, 0.5, 1), fuchsia = rgbm(1, 0, 1, 1), green = rgbm(0, 0.5, 0, 1), lime = rgbm(0, 1, 0, 1), olive = rgbm(0.5, 0.5, 0, 1), yellow = rgbm(1, 1, 0, 1), orange = rgbm(1, 0.5, 0, 1), navy = rgbm(0, 0, 0.5, 1), blue = rgbm(0, 0, 1, 1), teal = rgbm(0, 0.5, 0.5, 1), cyan = rgbm(0, 0.5, 1, 1), aqua = rgbm(0, 1, 1, 1) }

---Four-channel color. Fourth value, `mult`, can be used for alpha, for brightness, anything like that. All operators are also 
---overloaded. White is usually `rgb=1,1,1`.
---@param r number? 
---@param g number? 
---@param b number? 
---@param mult number? 
---@return rgbm
function rgbm(r, g, b, mult) end

---Four-channel color. Fourth value, `mult`, can be used for alpha, for brightness, anything like that. All operators are also 
---overloaded. White is usually `rgb=1,1,1`.
---@class rgbm
---@field r number
---@field g number
---@field b number
---@field rgb rgb
---@field mult number
---@operator add(number|rgbm): rgbm
---@operator sub(number|rgbm): rgbm
---@operator mul(number|rgbm): rgbm
---@operator div(number|rgbm): rgbm
---@operator pow(number|rgbm): rgbm
---@operator len: number
---@operator unm: rgbm
local rgbm = nil

---Makes a copy of a vector.
---@return rgbm
function rgbm:clone() end

---Unpacks rgbm into rgb and number.
---@return rgb, number
function rgbm:unpack() end

---Turns rgbm into a table with four values.
---@return number[]
function rgbm:table() end

---Returns reference to rgbm class.
function rgbm:type() end

---@param rgb rgbm|rgb
---@param mult number?
---@return rgbm @Returns itself.
function rgbm:set(rgb, mult) end

---@param value1 rgbm
---@param value2 rgbm
---@param mix number
---@return rgbm @Returns itself.
function rgbm:setLerp(value1, value2, mix) end

---@param valueToAdd rgbm|number
---@param out rgbm|nil @Optional destination argument.
---@return rgbm @Returns itself or out value.
function rgbm:add(valueToAdd, out) end

---@param valueToAdd rgbm
---@param scale number
---@param out rgbm|nil @Optional destination argument.
---@return rgbm @Returns itself or out value.
function rgbm:addScaled(valueToAdd, scale, out) end

---@param valueToSubtract rgbm|number
---@param out rgbm|nil @Optional destination argument.
---@return rgbm @Returns itself or out value.
function rgbm:sub(valueToSubtract, out) end

---@param valueToMultiplyBy rgbm
---@param out rgbm|nil @Optional destination argument.
---@return rgbm @Returns itself or out value.
function rgbm:mul(valueToMultiplyBy, out) end

---@param valueToDivideBy rgbm
---@param out rgbm|nil @Optional destination argument.
---@return rgbm @Returns itself or out value.
function rgbm:div(valueToDivideBy, out) end

---@param exponent rgbm|number
---@param out rgbm|nil @Optional destination argument.
---@return rgbm @Returns itself or out value.
function rgbm:pow(exponent, out) end

---@param multiplier number
---@param out rgbm|nil @Optional destination argument.
---@return rgbm @Returns itself or out value.
function rgbm:scale(multiplier, out) end

---@param otherValue rgbm|number
---@param out rgbm|nil @Optional destination argument.
---@return rgbm @Returns itself or out value.
function rgbm:min(otherValue, out) end

---@param otherValue rgbm|number
---@param out rgbm|nil @Optional destination argument.
---@return rgbm @Returns itself or out value.
function rgbm:max(otherValue, out) end

---@param out rgbm|nil @Optional destination argument.
---@return rgbm @Returns itself or out value.
function rgbm:saturate(out) end

---@param min rgbm
---@param max rgbm
---@param out rgbm|nil @Optional destination argument.
---@return rgbm @Returns itself or out value.
function rgbm:clamp(min, max, out) end

---Makes sure brightest value does not exceed 1.
---@return rgbm @Returns itself.
function rgbm:normalize() end

---Returns brightest value.
---@return number
function rgbm:value() end

---Returns luminance value.
---@return number
function rgbm:luminance() end

---Returns color (rgb*mult).
---@return rgb
function rgbm:color() end

---Returns HSV color of rgb*mult.
---@return hsv
function rgbm:hsv() end

---Returns rgb*mult turned to vec3.
---@return vec3
function rgbm:vec3() end

---Returns vec4, where X, Y and Z are RGB values and W is mult.
---@return vec4
function rgbm:vec4() end

---Returns string with hex representation and leading “#”.
---@return string
function rgbm:hex() end

--[[ common/ac_primitive_quat.d.lua ]]

---Creates new quaternion. It’s usually faster to create a new item with `quat(x, y, z, w)` directly, but the way LuaJIT works,
---that call only works with four numbers. If you only provide a single number, rest will be set to 0. This call, however, supports
---various calls (which also makes it slightly slower).
---@overload fun(value: quat): quat
---@overload fun(tableOfFour: number[]): quat
---@overload fun(value: number): quat
---@param x number?
---@param y number?
---@param z number?
---@param w number?
---@return quat
function quat.new(x, y, z, w) end

---Checks if value is quat or not.
---@param p any
---@return boolean
function quat.isquat(p) end

---Creates a new quaternion.
---@param angle number @In radians.
---@param x vec3|number
---@param y number?
---@param z number?
---@return quat
function quat.fromAngleAxis(angle, x, y, z) end

---Creates a new quaternion.
---@param x vec3|number
---@param y number?
---@param z number?
---@return quat
function quat.fromDirection(x, y, z) end

---Creates a new quaternion.
---@param u quat
---@param v quat
---@return quat
function quat.between(u, v) end

---Temporary quaternion. For most cases though, it might be better to define those locally and use those. Less chance of collision.
---@return quat
function quat.tmp() end

---Quaternion. All operators are overloaded.
---@param x number? 
---@param y number? 
---@param z number? 
---@param w number? 
---@return quat
function quat(x, y, z, w) end

---Quaternion. All operators are overloaded.
---@class quat
---@field x number
---@field y number
---@field z number
---@field w number
local quat = nil

---Makes a copy of a quaternion.
---@return quat
function quat:clone() end

---Unpacks quat into four numbers.
---@return number, number, number, number
function quat:unpack() end

---Turns quat into a table with four values.
---@return number[]
function quat:table() end

---Returns reference to quat class.
function quat:type() end

---@param x quat|number
---@param y number?
---@param z number?
---@param w number?
---@return quat @Returns itself.
function quat:set(x, y, z, w) end

---@param angle number @In radians.
---@param x vec3|number
---@param y number?
---@param z number?
---@return quat @Returns itself.
function quat:setAngleAxis(angle, x, y, z) end

---@return number @Angle in radians.
---@return number @Axis, X.
---@return number @Axis, Y.
---@return number @Axis, Z.
function quat:getAngleAxis() end

---@param u quat
---@param v quat
---@return quat @Returns itself.
function quat:setBetween(u, v) end

---@param x vec3|number
---@param y number?
---@param z number?
---@return quat @Returns itself.
function quat:setDirection(x, y, z) end

---@param valueToAdd quat|number
---@param out quat|nil @Optional destination argument.
---@return quat @Returns itself or out value.
function quat:add(valueToAdd, out) end

---@param valueToSubtract quat|number
---@param out quat|nil @Optional destination argument.
---@return quat @Returns itself or out value.
function quat:sub(valueToSubtract, out) end

---@param valueToMultiplyBy quat
---@param out quat|nil @Optional destination argument.
---@return quat @Returns itself or out value.
function quat:mul(valueToMultiplyBy, out) end

---@param multiplier number
---@param out quat|nil @Optional destination argument.
---@return quat @Returns itself or out value.
function quat:scale(multiplier, out) end

---@return number
function quat:length() end

---Normalizes itself (unless different `out` is provided).
---@param out quat|nil @Optional destination argument.
---@return quat @Returns itself or out value.
function quat:normalize(out) end

---Rewrites own values with values of lerp of itself and other quaternion (unless different `out` is provided).
---@param otherVector quat
---@param mix number
---@param out quat|nil @Optional destination argument.
---@return quat @Returns itself or out value.
function quat:lerp(otherVector, mix, out) end

---Rewrites own values with values of slerp of itself and other quaternion (unless different `out` is provided).
---@param otherVector quat
---@param mix number
---@param out quat|nil @Optional destination argument.
---@return quat @Returns itself or out value.
function quat:slerp(otherVector, mix, out) end

--[[ lib_hashspace.lua ]]

---@class ac.HashSpaceItem
local HashSpaceItem = class('HashSpaceItem')

---Returns ID associated with an item.
---@return integer
function HashSpaceItem:id() end

---Moves an item to a position.
---@param pos vec3
function HashSpaceItem:update(pos) end

---Removes item from its space.
function HashSpaceItem:dispose() end

---Simple structure meant to speed up collision detection by arranging items in a grid using hashmap. Cells are arranged horizontally.
---@param cellSize number @Should be about twice as large as your largest entity.
---@return ac.HashSpace
function ac.HashSpace(cellSize) end

---Simple structure meant to speed up collision detection by arranging items in a grid using hashmap. Cells are arranged horizontally.
---@class ac.HashSpace
local _ac_HashSpace = nil

---Iterates items around given position.
---@generic T
---@param pos vec3
---@param callback fun(id: integer, callbackData: T)
---@param callbackData T?
function _ac_HashSpace:iterate(pos, callback, callbackData) end

---Checks if there are any items around given position.
---@param pos vec3
---@return boolean
function _ac_HashSpace:anyAround(pos) end

---Count amount of items around given position.
---@param pos vec3
---@return integer
function _ac_HashSpace:count(pos) end

---Returns raw pointers for given position for manual iteration. Be careful!
---@param pos vec3
---@return any, any
function _ac_HashSpace:rawPointers(pos) end

---Adds a new dynamic item to the grid. Each item gets a new ID.
---@return ac.HashSpaceItem
function _ac_HashSpace:add() end

---Adds a fixed item to the grid, with predetermined ID. Avoid mixing dynamic and fixed items in the same grid.
---@param id integer
---@param pos vec3
function _ac_HashSpace:addFixed(id, pos) end

--[[ lib_numlut.lua ]]

---Meant to quickly interpolate between tables of values, some of them could be colors set in HSV. Example:
---```
---local lut = ac.Lut([[
--- -100 |  0.00,   350,  0.37,  1.00,  3.00,  1.00,  1.00,  3.60,500.00,  0.04
---  -90 |  1.00,    10,  0.37,  1.00,  3.00,  1.00,  1.00,  3.60,500.00,  0.04
---  -20 |  1.00,    10,  0.37,  1.00,  3.00,  1.00,  1.00,  3.60,500.00,  0.04
---]], { 2 })
---assert(lut:calculate(-95)[1] == 0.5)
---```
---@class ac.Lut
---@explicit-contructor ac.Lut
local _ac_Lut = nil

---Interpolate for a given input, return a newly created table. Note: consider using `:calculateTo()` instead to avoid re-creating tables, it would work much more efficiently.
---@param input number
---@return number[]
function _ac_Lut:calculate(input) end

---Interpolate for a given input, write result to a given table.
---@param output number[]
---@param input number
---@return number[] @Same table as was provided in arguments.
function _ac_Lut:calculateTo(output, input) end

--[[ lib_numlut_jit.lua ]]

---Meant to quickly interpolate between tables of values, some of them could be colors set in HSV. Example:
---```
---local lutJit = ac.LutJit:new{ data = {
---  { input = -100, output = {  0.00,   350,  0.37,  1.00,  3.00,  1.00,  1.00,  3.60,500.00,  0.04 } },
---  { input =  -90, output = {  1.00,    10,  0.37,  1.00,  3.00,  1.00,  1.00,  3.60,500.00,  0.04 } },
---  { input =  -20, output = {  1.00,    10,  0.37,  1.00,  3.00,  1.00,  1.00,  3.60,500.00,  0.04 } },
---  }, hsvRows = { 2 }}
---assert(lutJit:calculate(-95)[1] == 1)
---```
---Obsolete. Use `ac.Lut` instead, with faster C++ implementation.
---@class ac.LutJit
---@deprecated
ac.LutJit = {}

---Creates new ac.LuaJit instance. Deprecated, use `ac.Lut` instead.
---@deprecated
---@param data any
---@param hsvRows integer[] @ 1-based indices of columns (not rows) storing HSV values in them.
---@return table
function ac.LutJit:new(o, data, hsvRows) end

---Computes a new value. Deprecated, use `ac.Lut` instead.
---@deprecated
---@param input number
---@return number[]
function ac.LutJit:calculate(input) end

---Computes a new value to a preexisting HSV value. Deprecated, use `ac.Lut` instead.
---@deprecated
---@param output number[]
---@param input number
---@return number[] @Same table as was provided in arguments.
function ac.LutJit:calculateTo(output, input) end

--[[ lib_social.lua ]]

---Checks if a user is tagged as a friend. Uses CSP and CM databases. Deprecated, use `ac.DriverTags` instead.
---@deprecated
---@param driverName string @Driver name.
---@return boolean
function ac.isTaggedAsFriend(driverName) end

---Tags user as a friend (or removes the tag if `false` is passed). Deprecated, use `ac.DriverTags` instead.
---@deprecated
---@param driverName string @Driver name.
---@param isFriend boolean? @Default value: `true`.
function ac.tagAsFriend(driverName, isFriend) end

---Loads a ZIP file from a given URL, unpacks first KN5 from it to a cache folder and returns
---its filename through a callback. If file is already in cache storage, doesn’t do anything and
---simply returns filename to it. After callback is called, that filename could be used to load
---KN5 in the scene.
---
---If there is a VAO patch in a ZIP file, it will be extracted next to KN5.
---
---Note: only valid KN5 files and VAO patches are supported. Heavy caching is applied: if model was
---downloaded once, it would not be re-downloaded (unlike with remote textures where proper HTTP caching
---rules apply). If model was not accessed for a couple of weeks, it’ll be removed.
---
---If you need to download several entities and do something afterwards, it might help to use some
---promise Lua library.
---
---Use `web.loadRemoteAssets()` instead.
---@deprecated
---@param u string @URL to download.
---@param callback fun(err: string, filename: string)
function web.loadRemoteModel(u, callback) end

---Loads a ZIP file from a given URL, unpacks first KsAnim from it to a cache folder and returns
---its filename through a callback. If file is already in cache storage, doesn’t do anything and
---simply returns filename to it. After callback is called, that filename could be used to animate
---objects in the scene. If animation was not accessed for a couple of weeks, it’ll be removed.
---
---If you need to download several entities and do something afterwards, it might help to use some
---promise Lua library.
---
---Use `web.loadRemoteAssets()` instead.
---@deprecated
---@param u string @URL to download.
---@param callback fun(err: string, filename: string)
function web.loadRemoteAnimation(u, callback) end

---Loads a ZIP file from a given URL, unpacks assets from it to a cache folder and returns
---path to the folder in a callback. If files are already in cache storage, doesn’t do anything and
---simply returns the path. After callback is called, you can use path to the folder to get full paths to those assets.
---If assets are not accessed for a couple of weeks, they’ll be removed.
---@param u string @URL to download.
---@param callback fun(err: string, folder: string)
function web.loadRemoteAssets(u, callback) end

---Resolve hostname, return IPv4 via a callback.
---@param url string
---@param callback fun(err: string?, response: string?)
function web.resolveDNS(url, callback) end

---@param key string
---@return string
function web.encryptKey(key) end

---Loads FMOD soundbank. After soundbank is loaded, new audio events can be created which would refer to
---events in the soundbank. If soundbank is missing, new audio events can still be created, but they won’t be
---valid. If second parameter is missing, “GUIDs.txt” in the same folder as soundbank will be loaded. Returns
---true if both files were found properly. Also, if used before audio engine is initialized, it would postpone
---loading until that happens (function returns straight away, and you can create new audio events straight
---away, but they would only become valid after audio initialization is complete).
---@param soundbank string @Path to “.bank” file, could be absolute or relative to Lua script folder.
---@param guids string? @Path to “.txt” file with GUIDs, if missing, “GUIDs.txt” from soundbank folder will be used.
---@return boolean @Returns `true` if both files were found.
function ac.loadSoundbank(soundbank, guids) end

---Checks if audio engine is initialized and ready to work. Until then, all created audio events would return `false`
---in their `:isValid()` methods, it doesn’t mean that there is a problem with soundbank (yet).
---@return boolean
function ac.isAudioReady() end

---Set volume multiplier for audio associated with a certain surface. Returns `false` if there are no events associated with this type of surface.
---@param surfaceWav string
---@param mult number
---@return boolean
function ac.setAudioEventMultiplier(surfaceWav, mult) end

---Audio event is a audio emitter which uses a certain event from one of loaded FMOD soundbanks.
---@class ac.AudioEvent
---@field volume number @Audio volume, from 0 to 1 (can go above too, but clipping might occur). Default value: 1.
---@field pitch number @Audio pitch. Default value: 1.
---@field cameraInteriorMultiplier number @Multiplier for audio volume with interior camera. Default value: 0.25.
---@field cameraExteriorMultiplier number @Multiplier for audio volume with exterior (chase or free, for example) camera. Default value: 1.
---@field cameraTrackMultiplier number @Multiplier for audio volume with track camera (those replay cameras with low FOV). Default value: 1.
---@field inAutoLoopMode number @If set to `true`, aduio event would automatically start when in range of camera and volume is above 0. Default value: `false`.
local _ac_AudioEvent = nil

---Sets audio event orientation.
---@param pos vec3 @Position. If you’re working on a car script, position is relative to car position.
---@param dir vec3|nil @Direction. If missing, forwards vector is used.
---@param up vec3|nil @Vector directed up for full 3D orientation.
---@param vel vec3|nil @Velocity of audio source. If missing, sound is stationary. If you’re working on a car script, velocity is relative to car velocity.
---@return ac.AudioEvent @Returns self for easy chaining.
function _ac_AudioEvent:setPosition(pos, dir, up, vel) end

---Override used volume channel. Use carefully.
---@param channel ac.AudioChannel? @Set to `nil` to reset to default.
---@return self
function _ac_AudioEvent:setVolumeChannel(channel) end

---Deprecated, now all events are alive until `:dispose()` is called.
---@deprecated
function ac.AudioEvent.keepAlive() end

---Set value of an audio event parameter.
---@param name string
---@param value number
---@return ac.AudioEvent @Returns self for easy chaining.
function _ac_AudioEvent:setParam(name, value) end

---Set minimum distance at which attenuation starts.
---@param value number
---@return ac.AudioEvent @Returns self for easy chaining.
function _ac_AudioEvent:setDistanceMin(value) end

---Set maximum distance at which attenuation ends.
---@param value number
---@return ac.AudioEvent @Returns self for easy chaining.
function _ac_AudioEvent:setDistanceMax(value) end

---Set 3D cone settings.
---@param inside number? @Default value: 360.
---@param outside number? @Default value: 360.
---@param outsideVolume number? @Default value: 1.
---@return ac.AudioEvent @Returns self for easy chaining.
function _ac_AudioEvent:setConeSettings(inside, outside, outsideVolume) end

---Set DSP parameter.
---@param dsp integer @0-based index of DSP.
---@param key integer @0-based index of DSP parameter.
---@param value number
---@return ac.AudioEvent @Returns self for easy chaining.
function _ac_AudioEvent:setDSPParameter(dsp, key, value) end

---Returns `true` if event is loaded successfully. If event does not load, make sure soundbank is loaded first, and that event name is correct. If event is loaded
---from a file and finished playing, also returns `false`.
---@return boolean
function _ac_AudioEvent:isValid() end

---Returns `true` if audio event is playing.
---@return boolean
function _ac_AudioEvent:isPlaying() end

---Returns `true` if audio event is paused.
---@return boolean
function _ac_AudioEvent:isPaused() end

---Return `true` if audio event is within hearing range of current listener. Could be a good way to pause some expensive processing
---for distant audio events. Although in general comparing distance with a threshold on Lua side with vectors might be faster (without
---going Lua→CSP→FMOD and back).
---@return boolean
function _ac_AudioEvent:isWithinRange() end

function _ac_AudioEvent:resume() end

---If condition is `true`, start an audio event if it’s stopped, resume it if it’s paused. If condition is false, stop audio event.
---@param condition boolean|`true`|`false`
---@return ac.AudioEvent @Returns self for easy chaining.
function _ac_AudioEvent:resumeIf(condition) end

---Stop audio event.
---@return ac.AudioEvent @Returns self for easy chaining.
function _ac_AudioEvent:stop() end

---Start audio event.
---@return ac.AudioEvent @Returns self for easy chaining.
function _ac_AudioEvent:start() end

---Set timeline position.
---@param time number @Time in seconds.
---@return ac.AudioEvent @Returns self for easy chaining.
function _ac_AudioEvent:seek(time) end

---Get current timeline position in seconds.
---@return number @Returns `-1` if actual position is not available.
function _ac_AudioEvent:getTimelinePosition() end

---Get total duration in seconds for an audio event loaded from a file.
---@return number @Returns `-1` if actual duration is not available.
function _ac_AudioEvent:getDuration() end

---If you need to move audio event often, accessing its matrix directly might be the best way. But you have to be extra careful in
---making sure matrix is always normalized (vectors `side`, `up` and `look` should be othrogonal with lengths of 1), otherwise
---audio might sound strange, with rapid changes in volume.
---@return mat4x4
function _ac_AudioEvent:getTransformationRaw() end

---Stop and remove audio event.
function _ac_AudioEvent:dispose() end

---@param i integer
---@param dir 'input'|'output'|'both'|nil
---@return number, number, number, number
function _ac_AudioEvent:getDSPMetering(i, dir) end
--[[ csp.lua ]]

---Mesh vertex.
---@param pos vec3 
---@param normal vec3 
---@param uv vec2 
---@return ac.MeshVertex
function ac.MeshVertex(pos, normal, uv) end

---Mesh vertex.
---@class ac.MeshVertex
---@field pos vec3
---@field normal vec3
---@field uv vec2
local _ac_MeshVertex = nil

---Creates new mesh vertex.
---@param pos vec3
---@param normal vec3
---@param uv vec2
---@return ac.MeshVertex
function ac.MeshVertex.new(pos, normal, uv) end

---Buffer with mesh vertices. Contains `ac.MeshVertex` items.
---@param size nil|integer|ac.MeshVertex[] "Initial size or initializing values."
---@return ac.VertexBuffer
function ac.VertexBuffer(size) end

---Buffer with mesh vertices. Contains `ac.MeshVertex` items.
---@class ac.VertexBuffer : ac.GenericList
local _ac_VertexBuffer = nil

---@param index integer @1-based index.
---@return ac.MeshVertex
function _ac_VertexBuffer:get(index) end

---@param index integer @1-based index.
---@param vertex ac.MeshVertex
function _ac_VertexBuffer:set(index, vertex) end

---Buffer with mesh indieces. Contains `integer` items (limited by 16 bits for AC to handle).
---@param size nil|integer|integer[] "Initial size or initializing values."
---@return ac.IndicesBuffer
function ac.IndicesBuffer(size) end

---Buffer with mesh indieces. Contains `integer` items (limited by 16 bits for AC to handle).
---@class ac.IndicesBuffer : ac.GenericList
local _ac_IndicesBuffer = nil

---Reference to one or several objects in scene. Works similar to those jQuery things which would refer to one or
---several of webpage elements. Use methods like `ac.findNodes()` to get one. Once you have a reference to some nodes,
---you can load additional KN5s, create new nodes and such in it.
---Note: it might be beneficial in general to prefer methods like `ac.findNodes()` and `ac.findMeshes()` over `ac.findAny()`.
---Should be fewer surprises this way.
---@class ac.SceneReference
local _ac_SceneReference = nil

---Dispose any resources associated with this `ac.SceneReference` and empty it out. Use it if you need to remove a previously
---created node or a loaded KN5.
function _ac_SceneReference:dispose() end

---Set debug outline for meshes in the reference. Outline remains active until explicitly disabled or until reference is released.
---Note: each outlined group adds a render target switch and additional draw calls, so avoid adding it to more than, let’s say,
---ten groups at once (each group can have multiple meshes in it). 
---@param color rgbm? @Outline color. Use `nil` or transparent color to disable outline.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setOutline(color) end

---Set material property. Be careful to match the type (you need the same amount of numeric values). If you’re using boolean,-
---resulting value will be either 1 or 0.
---@param property string|"'ksEmissive'"
---@param value number|vec2|vec3|rgb|vec4|rgbm|boolean
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setMaterialProperty(property, value) end

---Set material texture. Three possible uses:
---
---1. Pass color to create a new solid color texture:
---  ```
---  meshes:setMaterialTexture('txDiffuse', rgbm(1, 0, 0, 1)) -- for red color
---  ```
---2. Pass filename to load a new texture. Be careful, it would load texture syncronously unless it
---  was loaded before:
---  ```
---  meshes:setMaterialTexture('txDiffuse', 'filename.dds')
---  ```
---  Since 0.2.2 nothing will happen if the texture is missing (previously it’ll use black transparent texture).
---3. Pass a table with parameters to draw a texture in a style of scriptable displays. Be careful as to
---  not call it too often, make sure to limit refresh rate unless you really need a quick update. If you’re
---  working on a track script, might also be useful to check if camera is close enough with something like
---  ac.getSim().cameraPosition:closerToThan(display coordinates, some distance)
---  ```
---  meshes:setMaterialTexture('txDiffuse', {
---    textureSize = vec2(1024, 1024), -- although optional, I recommend to set it: skin could replace texture by one with different resolution
---    background = rgbm(1, 0, 0, 1),  -- set to `nil` (or remove) to reuse original texture as background, set to `false` to skip background preparation completely
---    region = {                      -- if not set, whole texture will be repainted
---        from = vec2(200, 300),
---        size = vec2(400, 400)
---    },
---    callback = function (dt)
---      display.rect{ pos = …, size = …, … }
---    end
---  })
---  ```
---@param texture string|"'txDiffuse'"|"'txNormal'"|"'txEmissive'"|"'txMaps'" @Name of a texture slot.
---@param value {callback: fun(dt: number), textureSize: vec2, region: {from: vec2, size: vec2}, background: rgbm|boolean|nil}|`{callback = function (dt)  end, textureSize = vec2(512, 512), region = {from = vec2(0, 0), size = vec2(512, 512)}}`
---@overload fun(texture: string, value: string)
---@overload fun(texture: string, value: rgbm)
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setMaterialTexture(texture, value) end

---Ensures all materials are unique, allowing to alter their textures and material properties without affecting the rest of the scene. Only
---ensures uniqueness relative to the rest of the scene. For example, if it refers to two meshes using the same material, they’ll continue
---to share material, but it would be their own material, separate from the scene.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:ensureUniqueMaterials() end

---Stores current transformation to be restored when `ac.SceneReference` is disposed (for example, when script reloads). Might be a good
---idea to use it first on any nodes you’re going to move, so all of them would get back when script is reloaded (assuming their original 
---transformation is important, like it is with needles, for example).
---@return self @Returns self for easy chaining.
function _ac_SceneReference:storeCurrentTransformation() end

---CSP keeps track of previous world position of each node to do its motion blur. This call would clear that value, so teleported, for
---example, objects wouldn’t have motion blur artifacts for a frame.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:clearMotion() end

---Number of elements in this reference. Alternatively, you can use `#` operator.
---@return integer
function _ac_SceneReference:size() end

---If reference is empty or not.
---@return boolean
function _ac_SceneReference:empty() end

---Find any children that match filter and return a new reference to them.
---@param filter string @Node/mesh filter.
---@return ac.SceneReference @Reference to found scene elements.
function _ac_SceneReference:findAny(filter) end

---Find any child nodes that match filter and return a new reference to them.
---@param filter string @Node filter.
---@return ac.SceneReference @Reference to found nodes.
function _ac_SceneReference:findNodes(filter) end

---Find any child meshes that match filter and return a new reference to them.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found meshes.
function _ac_SceneReference:findMeshes(filter) end

---Find any child skinned meshes that match filter and return a new reference to them.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found skinned meshes.
function _ac_SceneReference:findSkinnedMeshes(filter) end

---Find any child objects of a certain class that match filter and return a new reference to them.
---@param objectClass ac.ObjectClass @Objects class.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found skinned meshes.
function _ac_SceneReference:findByClass(objectClass, filter) end

---Filters current reference and returns new one with objects that match filter only.
---@param filter string @Node/mesh filter.
---@return ac.SceneReference @Reference to found scene elements.
function _ac_SceneReference:filterAny(filter) end

---Filters current reference and returns new one with nodes that match filter only.
---@param filter string @Node filter.
---@return ac.SceneReference @Reference to found nodes.
function _ac_SceneReference:filterNodes(filter) end

---Filters current reference and returns new one with meshes that match filter only.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found meshes.
function _ac_SceneReference:filterMeshes(filter) end

---Filters current reference and returns new one with skinned meshes that match filter only.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found skinned meshes.
function _ac_SceneReference:filterSkinnedMeshes(filter) end

---Filters current reference and returns new one with objects of a certain class that match filter only.
---@param objectClass ac.ObjectClass @Objects class.
---@param filter string @Mesh filter.
---@return ac.SceneReference @Reference to found skinned meshes.
function _ac_SceneReference:filterByClass(objectClass, filter) end

---Create a new node with a given name and attach it as a child.
---@param name string
---@param keepAlive boolean|`true`|`false` @Set to `true` to create a long-lasting node which wouldn’t be removed when script is reloaded.
---@return ac.SceneReference @Newly created node or `nil` if failed
function _ac_SceneReference:createNode(name, keepAlive) end

---Create a new mesh with a given name and attach it as a child. Steals passed vertices and indices to avoid reallocating
---memory, so make sure to use `vertices:clone()` when passing if you want to keep the original data. 
---@param name string
---@param materialName string?
---@param vertices ac.VertexBuffer
---@param indices ac.IndicesBuffer
---@param keepAlive boolean|`true`|`false` @Set to `true` to create a long-lasting node which wouldn’t be removed when script is reloaded.
---@param moveData boolean? @Set to `true` to move vertices and indices data thus saving on reallocating memory. You can use `vertices:clone()` for one of them to retain original array. Default value: `false`.
---@return ac.SceneReference @Newly created mesh or `nil` if failed
function _ac_SceneReference:createMesh(name, materialName, vertices, indices, keepAlive, moveData) end

---Replace mesh vertices dynamically. New number of vertices should match existing one, indices work the same. Can be used for dynamic
---mesh alteration (for example, deformation). Calling it each frame with highly detailed mesh might still affect performance negatively though.
---@param vertices ac.VertexBuffer
---@return self @Returns self for easy chaining.
function _ac_SceneReference:alterVertices(vertices) end

---Get vertices of a first mesh in selection. Makes a copy into an `ac.VertexBuffer`, so it might be expensive to call each frame, but it can be called
---once for those vertices to later be used with `:alterVertices()` method.
---@return ac.VertexBuffer? @Returns `nil` if there are no suitable meshes in selection.
function _ac_SceneReference:getVertices() end

---Create a new bounding sphere node with a given name and attach it as a child. Using those might help with performance: children
---would skip bounding frustum test, and whole node would not get traversed during rendering if it’s not in frustum.
---
---Note: for it to work properly, it’s better to attach it to AC cars node, as that one does expect those bounding sphere nodes
---to be inside of it. You can find it with `ac.findNodes('carsRoot:yes')`.
---@param name string
---@param radius number @Radius in meters.
---@return ac.SceneReference @Can return `nil` if failed.
function _ac_SceneReference:createBoundingSphereNode(name, radius) end

---Load KN5 model and attach it as a child. To use remote models, first load them with `web.loadRemoteModel()`.
---
---Node: The way it actually works, KN5 would be loaded in a pool and then copied here (with sharing
---of resources such as vertex buffers). This generally helps with performance.
---@param filename string|{filename: string, filter: string} @KN5 filename relative to script folder or AC root folder. Since 0.2.5, you can instead pass a table with filename and a filter (for example, `'{ ! renderable:no }'`; note that filter will applied to every node and mesh).
---@return ac.SceneReference @Can return `nil` if failed.
function _ac_SceneReference:loadKN5(filename) end

---Load KN5 LOD model and attach it as a child. Parameter `mainFilename` should refer to the main KN5 with all the textures.
---
---Node: The way it actually works, KN5 would be loaded in a pool and then copied here (with sharing
---of resources such as vertex buffers). This generally helps with performance. Main KN5 would be
---loaded as well, but not shown, and instead kept in a pool.
---@param filename string|{filename: string, filter: string} @KN5 filename relative to script folder or AC root folder. Since 0.2.5, you can instead pass a table with filename and a filter (for example, `'{ ! renderable:no }'`; note that filter will applied to every node and mesh).
---@param mainFilename string @Main KN5 filename relative to script folder or AC root folder.
---@return ac.SceneReference @Can return `nil` if failed.
function _ac_SceneReference:loadKN5LOD(filename, mainFilename) end

---Load KN5 model and attach it as a child asyncronously. To use remote models, first load them with `web.loadRemoteModel()`.
---
---Node: The way it actually works, KN5 would be loaded in a pool and then copied here (with sharing
---of resources such as vertex buffers). This generally helps with performance.
---@param filename string|{filename: string, filter: string} @KN5 filename relative to script folder or AC root folder. Since 0.2.5, you can instead pass a table with filename and a filter (for example, `'{ ! renderable:no }'`; note that filter will applied to every node and mesh).
---@param callback fun(err: string, loaded: ac.SceneReference?) @Callback called once model is loaded.
function _ac_SceneReference:loadKN5Async(filename, callback) end

---Load KN5 model and attach it as a child asyncronously. Parameter `mainFilename` should refer to the main KN5 with all the textures.
---
---Node: The way it actually works, KN5 would be loaded in a pool and then copied here (with sharing
---of resources such as vertex buffers). This generally helps with performance. Main KN5 would be
---loaded as well, but not shown, and instead kept in a pool.
---@param filename string|{filename: string, filter: string} @KN5 filename relative to script folder or AC root folder. Since 0.2.5, you can instead pass a table with filename and a filter (for example, `'{ ! renderable:no }'`; note that filter will applied to every node and mesh).
---@param mainFilename string @Main KN5 filename relative to script folder or AC root folder.
---@param callback fun(err: string, loaded: ac.SceneReference?) @Callback called once model is loaded.
function _ac_SceneReference:loadKN5LODAsync(filename, mainFilename, callback) end

---Loads animation from a file (on first call only), sets animation position. To use remote animations, first load them with `web.loadRemoteAnimation()`.
---@param filename string @Animation filename (”…ksanim”). If set to `nil`, no animation will be applied.
---@param position number? @Animation position from 0 to 1. Default value: 0.
---@param force boolean? @If not set to `true`, animation will be applied only if position is different from position used previously. Default value: `false`.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setAnimation(filename, position, force) end

---@param visible boolean|`true`|`false`
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setVisible(visible) end

---@param shadows boolean|`true`|`false`
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setShadows(shadows) end

---@param exclude boolean|`true`|`false`
---@return self @Returns self for easy chaining.
function _ac_SceneReference:excludeFromCubemap(exclude) end

---@param exclude boolean|`true`|`false`
---@return self @Returns self for easy chaining.
function _ac_SceneReference:excludeFromSecondary(exclude) end

---@param transparent boolean|`true`|`false`
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setTransparent(transparent) end

---@param mode render.BlendMode
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setBlendMode(mode) end

---@param mode render.CullMode
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setCullMode(mode) end

---@param mode render.DepthMode
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setDepthMode(mode) end

---Sets attribute associated with current meshes or nodes. Attributes are stored as strings, but you can access them as numbers with `:getAttibute()` by
---passing number as `defaultValue`. To find meshes with a certain attribute, use “hasAttribute:name” search query.
---@param key string
---@param value number|string|nil @Pass `nil` to remove an attribute.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setAttribute(key, value) end

---Gets an attribute value.
---@param key string
---@param defaultValue number|string|nil @If `nil` is passed, returns string (or `nil` if attribute is not set).
---@return string|number|nil @Type is determined based on type of `defaultValue`.
function _ac_SceneReference:getAttribute(key, defaultValue) end

---Reference:
---- Reduced TAA: 1;
---- Extra TAA: 0.5.
---@param value number
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setMotionStencil(value) end

---Sets position of a node (or nodes).
---
---Note: only nodes can move. If you need to move meshes, find their parent node and move it. If its parent node has more than a single mesh as a child,
---create a new node as a child of that parent and move mesh there.
---@param pos vec3
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setPosition(pos) end

---Sets orientation of a node (or nodes). If vector `up` is not provided, facing up vector will be used.
---
---Note: only nodes can rotate. If you need to rotate meshes, find their parent node and rotate it. If its parent node has more than a single mesh as a child,
---create a new node as a child of that parent and move mesh there.
---@param look vec3
---@param up vec3|nil
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setOrientation(look, up) end

---Replaces orientation of a node (or nodes) with rotational matrix. If you want to just rotate node from its current orientation, use `:rotate()`.
---
---Note: only nodes can rotate. If you need to rotate meshes, find their parent node and rotate it. If its parent node has more than a single mesh as a child,
---create a new node as a child of that parent and move mesh there.
---@param axis vec3
---@param angleRad number
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setRotation(axis, angleRad) end

---Rotates node (or nodes) relative to its current orientation. If you want to completely replace its orientation by rotating matrix, use `:setRotation()`.
---
---Note: only nodes can rotate. If you need to rotate meshes, find their parent node and rotate it. If its parent node has more than a single mesh as a child,
---create a new node as a child of that parent and move mesh there.
---@param axis vec3
---@param angleRad number
---@return self @Returns self for easy chaining.
function _ac_SceneReference:rotate(axis, angleRad) end

---Returns position of a first node relative to its parent.
---@return vec3
function _ac_SceneReference:getPosition() end

---Returns direction a first node is looking towards relative to its parent.
---@return vec3
function _ac_SceneReference:getLook() end

---Returns direction upwards of a first node relative to its parent.
---@return vec3
function _ac_SceneReference:getUp() end

---Returns number of children of all nodes in current scene reference.
---@return integer
function _ac_SceneReference:getChildrenCount() end

---Returns reference to transformation matrix of the first node relative to its parent. If you need to move
---something often, accessing its matrix directly might be the best way. Be careful though, if there
---are no nodes in the list, it would return `nil`.
---@return mat4x4 @Reference to transformation matrix of the first node, or nil. Use `mat4x4:set()` to update its value, or access its rows directly.
function _ac_SceneReference:getTransformationRaw() end

---Returns world transformation matrix of the first node. Do not use it to move node in world space (if you need
---to move in world space, either use `ref:getTransformationRaw():set(worldSpaceTransform:mul(ref:getParent():getWorldTransformationRaw():inverse()))` or
---simply move your node to a node without transformation, like root of dynamic objects). Be careful though, if there
---are no nodes in the list, it would return `nil`.
---@return mat4x4 @Reference to transformation matrix of the first node, or nil. Use `mat4x4:set()` to update its value, or access its rows directly.
function _ac_SceneReference:getWorldTransformationRaw() end

---Returns AABB (minimum and maximum coordinates in vector) of static meshes in current selection. Only regular static meshes
---are taken into account (meshes created when KN5 is exported in track mode).
---@return vec3 @Minimum coordinate.
---@return vec3 @Maximum coordinate.
---@return integer @Number of static meshes in selection.
function _ac_SceneReference:getStaticAABB() end

---Returns AABB (minimum and maximum coordinates in vector) of meshes in current selection in local mesh coordinates. Recalculates
---AABB live, might take some time with high-poly meshes.
---@return vec3 @Minimum coordinate.
---@return vec3 @Maximum coordinate.
---@return integer @Number of static meshes in selection.
function _ac_SceneReference:getLocalAABB() end

---Returns a new scene reference with a child in certain index (assuming current scene reference points to node). If current reference
---contains several nodes, children from all of them at given index will be collected.
---@param index integer? @1-based index of a child. Default value: 1.
---@return ac.SceneReference
function _ac_SceneReference:getChild(index) end

---Returns a new scene reference with first-class children (not children of children) of all nodes in current reference.
---@return ac.SceneReference
function _ac_SceneReference:getChildren() end

---Returns a new scene reference with a parent of an object in current scene reference. If current reference
---contains several objects, parents of all of them will be collected.
---@return ac.SceneReference
function _ac_SceneReference:getParent() end

---Adds nodes and meshes from another scene reference to current scene reference.
---@param sceneRef ac.SceneReference @Scene reference to append.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:append(sceneRef) end

---Removes nodes and meshes from another scene reference from current scene reference.
---@param sceneRef ac.SceneReference @Scene reference to remove.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:subtract(sceneRef) end

---Returns `true` if there is a node from `childSceneRef` somewhere in this node.
---@param childSceneRef ac.SceneReference @Scene reference to remove.
---@return boolean
function _ac_SceneReference:contains(childSceneRef) end

---Clears current scene reference.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:clear() end

---Casts a ray prepared by something like `render.createRay(pos, dir, length)` or `render.createMouseRay()`.
---
---If you need to access a mesh that was hit, set second argument to true:
---```
---local hitDistance, hitMesh = mesh:raycast(render.createRay(pos, dir), true)
---if hitDistance ~= -1 then
---  print(hitMesh:name())
---end
---```
---Alternatively, reuse your own scene reference for better performance if you need to cast
---a lot of rays:
---```
---local hitMesh = ac.emptySceneReference()
---local hitDistance = mesh:raycast(render.createRay(pos, dir), hitMesh)
---if hitDistance ~= -1 then
---  print(hitMesh:name())
---end
---```
---@param ray ray
---@param outSceneRef ac.SceneReference|boolean|nil
---@param outPosRef vec3|nil @Local position (not the world one).
---@param outNormalRef vec3|nil @Local normal.
---@param outUVRef vec2|nil @Texture coordinate.
---@return number @Distance to hit, or -1 if there was no hit.
---@return ac.SceneReference|nil @Reference to a mesh that was hit (same as `outSceneRef`, doubled here for convenience).
function _ac_SceneReference:raycast(ray, outSceneRef, outPosRef, outNormalRef, outUVRef) end

---Get name of an element.
---@param index integer|nil @1-based index of an element to get a name of. Default value: 1.
---@return string @Node or mesh name.
function _ac_SceneReference:name(index) end

---Check if node is currently active.
---@param index integer|nil @1-based index of an element to get a class of. Default value: 1.
---@return boolean
function _ac_SceneReference:isActive(index) end

---Check if mesh is currently visible. For something other than meshes or skinned meshes, always returns `false`.
---@param index integer|nil @1-based index of an element to get a class of. Default value: 1.
---@return boolean
function _ac_SceneReference:isVisible(index) end

---Check if mesh is only for physics and can’t be drawn (physics laserscan meshes are sometimes stored this way). For something other than meshes, always returns `false`.
---@param index integer|nil @1-based index of an element to get a class of. Default value: 1.
---@return boolean
function _ac_SceneReference:isPhysicsOnlyMesh(index) end

---Check if mesh has a transparent flag (such meshes are drawn last). For something other than meshes, always returns `false`.
---@param index integer|nil @1-based index of an element to get a class of. Default value: 1.
---@return boolean
function _ac_SceneReference:isTransparent(index) end

---Check if mesh casts shadows. For something other than meshes, always returns `false`.
---@param index integer|nil @1-based index of an element to get a class of. Default value: 1.
---@return boolean
function _ac_SceneReference:isCastingShadows(index) end

---Get class of an element.
---@param index integer|nil @1-based index of an element to get a class of. Default value: 1.
---@return ac.ObjectClass @Number for class of an object.
function _ac_SceneReference:class(index) end

---Get material name of an element.
---@param index integer|nil @1-based index of an element to get a material name of. Default value: 1.
---@return string @Material name.
function _ac_SceneReference:materialName(index) end

---Get blend mode of an element.
---@param index integer|nil @1-based index of an element. Default value: 1.
---@return render.BlendMode
function _ac_SceneReference:blendMode(index) end

---Get cull mode of an element.
---@param index integer|nil @1-based index of an element. Default value: 1.
---@return render.CullMode
function _ac_SceneReference:cullMode(index) end

---Get depth mode of an element.
---@param index integer|nil @1-based index of an element. Default value: 1.
---@return render.DepthMode
function _ac_SceneReference:depthMode(index) end

---Get shader name of an element.
---@param index integer|nil @1-based index of an element to get a shader name of. Default value: 1.
---@return string @Shader name.
function _ac_SceneReference:shaderName(index) end

---Get number of texture slots of an element.
---@param index integer|nil @1-based index of an element to get number of texture slots of. Default value: 1.
---@return integer @Number of texture slots.
function _ac_SceneReference:getTextureSlotsCount(index) end

---Get number of material properties of an element.
---@param index integer|nil @1-based index of an element to get number of material properties of. Default value: 1.
---@return integer @Number of material properties.
function _ac_SceneReference:getMaterialPropertiesCount(index) end

---Get name of a certain texture slot of an element.
---@param index integer|nil @1-based index of an element to get a name of a certain texture slot of. Default value: 1.
---@param slotIndex integer|nil @1-based index of a texture slot. Default value: 1.
---@return string|nil @Texture slot name (like “txDiffuse” or “txNormal”) or `nil` if there is no such element or property.
function _ac_SceneReference:getTextureSlotName(index, slotIndex) end

---Get name of a certain material property of an element.
---@param index integer|nil @1-based index of an element to get a name of a certain material property of. Default value: 1.
---@param slotIndex integer|nil @1-based index of a material property. Default value: 1.
---@return string|nil @Material property name (like “ksDiffuse” or “ksAmbient”) or `nil` if there is no such element or property.
function _ac_SceneReference:getMaterialPropertyName(index, slotIndex) end

---Get index of a certain texture slot of an element from the name of that slot.
---@param index integer|nil @1-based index of an element to get an index of a texture slot of. Default value: 1.
---@param slotName string|"'txDiffuse'"|"'txNormal'"|"'txEmissive'"|"'txMaps'" @Name of a texture slot.
---@return integer|nil @1-based texture slot index, or `nil` if there is no such property.
---@overload fun(s: ac.SceneReference, slotName: string): integer|nil
function _ac_SceneReference:getTextureSlotIndex(index, slotName) end

---Get index of a certain material property of an element from the name of that property.
---@param index integer|nil @1-based index of an element to get an index of a material property of. Default value: 1.
---@param propertyName string|"'ksDiffuse'"|"'ksAmbient'"|"'ksEmissive'" @Name of material property.
---@return integer|nil @1-based material property index, or `nil` if there is no such property.
---@overload fun(s: ac.SceneReference, propertyName: string): integer|nil
function _ac_SceneReference:getMaterialPropertyIndex(index, propertyName) end

---Get texture filename of a certain texture slot of an element.
---@param index integer|nil @1-based index of an element to get a texture filename of. Default value: 1.
---@param slot string|integer|nil|"'txDiffuse'"|"'txNormal'"|"'txEmissive'"|"'txMaps'" @Texture slot name or a 1-based index of a texture slot. Default value: 1.
---@return string|nil @Texture filename or `nil` if there is no such slot or element.
---@overload fun(s: ac.SceneReference, slot: string): string
function _ac_SceneReference:getTextureSlotFilename(index, slot) end

---Dump shader replacements configs for materials in current selection. Resulting string might be pretty huge. Not all properties are dumped, but more properties might be added later. Some textures are stored as temporary IDs only valid within a session.
---@return string
function _ac_SceneReference:dumpShaderReplacements() end

---@param neck ac.SceneReference
---@param modelName string
---@param carIndex integer
---@return fun(value: number): number, number
function _ac_SceneReference:applyHumanMaterials(neck, modelName, carIndex) end

---Get value of a certain material property of an element.
---@param index integer|nil @1-based index of an element to get a material property of. Default value: 1.
---@param property string|integer|nil|"'ksDiffuse'"|"'ksAmbient'"|"'ksEmissive'" @Material property name or a 1-based index of a material property. Default value: 1.
---@return number|vec2|vec3|vec4|nil @Material property value (type depends on material property type), or `nil` if there is no such element or material property.
---@overload fun(s: ac.SceneReference, property: string): number|vec2|vec3|vec4|nil
function _ac_SceneReference:getMaterialPropertyValue(index, property) end

---Get number of materials in given scene reference (not recursive, only checks meshes and skinned meshes). If same material is used
---for two different meshes, it would only count once. Materials sharing same name can be different (for example, applying “[SHADER_REPLACEMENT_...]”
---via config to some meshes, not materials, forks their materials to not affect other meshes using the same material).
---@return integer @Number of materials.
function _ac_SceneReference:getMaterialsCount() end

---Creates a copy of a scene reference (not copies of nodes or meshes).
---@return ac.SceneReference
function _ac_SceneReference:clone() end

---Get bounding sphere of an element. Works only with meshes or skinned meshes, nodes will return nil.
---@param index integer|nil @1-based index of an element to get a bounding sphere of. Default value: 1.
---@param outVec vec3|nil @Optional vector to use for bounding sphere position, to avoid creating new vector.
---@return vec3|nil @Center of bounding sphere in parent node coordinates, or nil if there is no bounding sphere (if it’s not a mesh or a skinned mesh).
---@return number|nil @Radius of bounding sphere, or nil if there is no bounding sphere (if it’s not a mesh or a skinned mesh).
function _ac_SceneReference:boundingSphere(index, outVec) end

---Applies skin to nodes or meshes (if ran with nodes, will apply skin to all of their children meshes).
---Skin is a table storing texture names and filenames to skin textures. Example:
---```
---local skinDir = ac.getFolder(ac.FolderID.ContentCars) .. '/' .. ac.getCarID(0) .. '/skins/my_skin'
---ac.findNodes('carRoot:0'):applySkin({
---  ['metal_details.dds'] = skinDir .. '/metal_details.dds'
---})
---```
---@param skin table<string, string>
---@return self @Returns self for easy chaining.
function _ac_SceneReference:applySkin(skin) end

---Resets textures to ones from associated KN5 file where possible.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:resetSkin() end

---Change parent of nodes in current reference.
---@param parentSceneRef ac.SceneReference|nil @Set to nil to disconnect node from a scene.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setParent(parentSceneRef) end

---Only applicable to cars added to `carsRoot:yes` node. If flag is set, node will be treated as a car by some specialized code, such as
---`BLIND_SPOT` input of car instruments.
---@param active boolean|`true`|`false`
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setVirtualCarFlag(active) end

---Finds materials in another scene reference that have the same names as materials in a given scene reference,
---and copies them over, so after that both references would share materials. Example use case: if you have LOD A and
---LOD B and LOD A got unique materials (because there are multiple objects sharing same KN5 model), with this function
---it’s possible to sync together materials from LOD A and LOD B by running `lodB:setMaterialsFrom(lodA)`. And because
---materials would not be actually copied, but instead shared, any consequent change of material properly in LOD A would
---be mirrored in LOD B.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setMaterialsFrom(materialSceneRef) end

---Creates a new scene reference with just a single item from the original scene reference.
---Indices are 1-based. By default it would create a new scene reference, if you need to access
---a lot of objects fast, provide your own:
---```
---  local meshes = ac.findMeshes('shader:ksTree')
---  local ref = ac.emptySceneReference()
---  for i = 1, #meshes do
---    meshes:at(i, ref)
---    print(ref:name())  -- note: for this particular case, it would be more optimal to use meshes:name(i) instead
---  end
---```
---@param index integer @1-based index.
---@param outSceneRef ac.SceneReference|nil
---@return ac.SceneReference @Reference to a child, might be empty if there is no such child.
function _ac_SceneReference:at(index, outSceneRef) end

---Returns number of nodes and meshes matching between this and another scene reference. Could be used to quickly find out if a certain element is in a set.
---@param other nil|ac.SceneReference|ac.SceneReference[] @Can be a single scene reference or a table with several of them. 
---@return integer
function _ac_SceneReference:countMatches(other) end

---Creates a new scene reference containing unique elements from both sets.
---@param other nil|ac.SceneReference|ac.SceneReference[] @Can be a single scene reference or a table with several of them.
---@return ac.SceneReference
function _ac_SceneReference:makeUnionWith(other) end

---Creates a new scene reference containing only the elements found in both of original sets.
---@param other nil|ac.SceneReference|ac.SceneReference[] @Can be a single scene reference or a table with several of them. 
---@return ac.SceneReference
function _ac_SceneReference:makeIntersectionWith(other) end

---Creates a new scene reference containing only the elements found in first set, but not in second set.
---@param other nil|ac.SceneReference|ac.SceneReference[] @Can be a single scene reference or a table with several of them. 
---@return ac.SceneReference
function _ac_SceneReference:makeSubtractionWith(other) end

---Create new fake shadow node. Uses the same shading as track fake shadows.
---@param params {points: vec3[], opacity: number, squaredness: vec2}|`{ points = {  }, opacity = 1, squaredness = vec2() }` "@Params for newly created node."
---@return ac.SceneReference @Reference to a newly created object.
function _ac_SceneReference:createFakeShadow(params) end

---Sets fake shadow points if current reference was created with `sceneReference:createFakeShadow()`.
---@param points vec3[] @Four corners.
---@param corners number[] @Four numbers for corner intensity.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setFakeShadowPoints(points, corners) end

---Sets fake shadow squaredness if current reference was created with `sceneReference:createFakeShadow()`.
---@param squaredness vec2 @X is squaredness along one axis, Y is along another.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setFakeShadowSquaredness(squaredness) end

---Sets fake shadow opacity if current reference was created with `sceneReference:createFakeShadow()`.
---@param opacity number @Value from 0 to 1.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:setFakeShadowOpacity(opacity) end

---Applies shader replacements stored in INI config format. Can optionally load included files, so templates
---work as well. If there is no symbol “[” in `data`, applies passed values to all meshes and materials in selection.
---@param data string|ac.INIConfig @Config in INIPP format.
---@param includeType ac.IncludeType? @Include type. If not set, includes will not be resolved, so templates won’t work. Default value: `ac.IncludeType.None`.
---@return self @Returns self for easy chaining.
function _ac_SceneReference:applyShaderReplacements(data, includeType) end

---Projects texture onto a mesh or few meshes, draws result. Use in when updating a dynamic texture, display or an extra canvas.
---Position, and directions are set in world space.
---
---Note: this is not a regular IMGUI drawing call, so most functions, such as shading offsets, transformations or clipping, would 
---not work here.
---
---Tip 1: if you want to draw a new skin for a car and apply AO to it, one way might be to draw it in a canvas and then draw
---original AO texture on top with special shading parameters:
---```
----- drawing rest of skin here
---ui.setShadingOffset(0, 0, 0, -1)
---ui.drawImage('car::EXT_body.dds', 0, ui.windowSize(), rgbm.colors.black)  -- with these shading offset properties, texture
---    -- will be drawn in black with inverse of brightness used for opacity
---ui.resetShadingOffset()
---```
---
---Tip 2: if you want to project things on meshes with certain material, make sure to filter out meshes so that it would only
---affect meshes from LOD A (instead of `ac.findMeshes('material:car_paint')` use `ac.findMeshes('{ material:car_paint & lod:A}')`),
---otherwise there’d be quite a few artifacts. I spent some time like this trying to figure out why results were off.
---@param params {filename: string, pos: vec3, look: vec3, up: vec3, color: rgbm, colorOffset: rgbm, size: vec2, depth: number, skew: vec2, tiling: vec2, doubleSided: boolean, uvOffset: vec2, blendMode: render.BlendMode, mask1: string, mask1UV1: vec2, mask1UV2: vec2, mask1Flags: render.TextureMaskFlags, mask2: string, mask2UV1: vec2, mask2UV2: vec2, mask2Flags: render.TextureMaskFlags}|`{filename = '', pos = vec3(), look = vec3(), up = vec3(0, 1, 0), color = rgbm.colors.white, size = vec2(), depth = 1e9, doubleSided = false}` "Table with properties:\n- `filename` (`string`): Path to a texture, or a texture element (`ui.MediaElement`, `ui.ExtraCanvas`, `ac.GeometryShot`).\n- `pos` (`vec3`): Position from which texture will be projected, in world space.\n- `look` (`vec3`): Direction with which texture will be projected, in world space.\n- `up` (`vec3`): Optional vector directed up, to specify texture rotation.\n- `color` (`rgbm`): Optional color. Default value: `rgbm.colors.white`.\n- `colorOffset` (`rgbm`): Optional color offset. Default value: `rgbm.colors.transparent`.\n- `size` (`vec2`): Size, horizontal and vertical. Default value: `vec2(1, 1)`.\n- `depth` (`number`): Depth: how far from camera projection goes, with a smooth falloff. Default value: 1e9.\n- `skew` (`vec2`): Optional skew. Default value: `vec2(0, 0)`.\n- `tiling` (`vec2`): Optional tiling for horizontal and vertical axis. With 1 tiles normally, with -1 tiles with flipping, other values are currently reserved. Default value: `vec2(0, 0)` (no tiling).\n- `doubleSided` (`boolean`): Set to `true` to draw things on surfaces facing away as well. Default value: `false`.\n- `uvOffset` (`vec2`): Optional UV offset. By default CSP estimates an UV offset such that most triagles would be shown. If mapping is way off though, it might need tweaking (or even repeated calls with different offsets).\n- `blendMode` (`render.BlendMode`): Optional override for blend mode. Default value: `render.BlendMode.BlendAccurate`.\n- `mask1` (`string`): Optional masking texture.\n- `mask1UV1` (`vec2`): Optional masking texture UV coordinates.\n- `mask1UV2` (`vec2`): Optional masking texture UV coordinates.\n- `mask1Flags` (`render.TextureMaskFlags`): Optional masking texture flags.\n- `mask2` (`string`): Optional secondary masking texture.\n- `mask2UV1` (`vec2`): Optional secondary masking texture UV coordinates.\n- `mask2UV2` (`vec2`): Optional secondary masking texture UV coordinates.\n- `mask2Flags` (`render.TextureMaskFlags`): Optional secondary masking texture flags."
---@return self @Returns self for easy chaining.
function _ac_SceneReference:projectTexture(params) end

---Projects shader onto a mesh or few meshes, draws result. Use in when updating a dynamic texture, display or an extra canvas.
---Position, and directions are set in world space. Shader is compiled at first run, which might take a few milliseconds.
---If you’re drawing things continuously, use `async` parameter and shader will be compiled in a separate thread,
---while drawing will be skipped until shader is ready.
---
---You can bind up to 32 textures and pass any number/boolean/vector/color/matrix values to the shader, which makes
---it a very effective tool for any custom drawing you might need to make.      
---
---Example:
---```
---local ray = render.createMouseRay()
---meshes:projectShader({
---  async = true,
---  pos = ray.pos,
---  look = ray.dir,
---  blendMode = render.BlendMode.Opaque,
---  textures = {
---    txInput1 = 'texture.png',  -- any key would work, but it’s easier to have a common prefix like “tx”
---    txInput2 = mediaPlayer,
---    txMissing = false
---  },
---  values = {
---    gValueColor = rgbm(1, 2, 0, 0.5),  -- any key would work, but it’s easier to have a common prefix like “g”
---    gValueNumber = math.random(),
---    gValueVec = vec2(1, 2),
---    gFlag = math.random() > 0.5
---  },
---  shader = [[
---    float4 main(PS_IN pin) { 
---      if (dot(abs(pin.Tex * 2 - 1), 1) > 0.5) return 0;
---      float4 in1 = txInput1.Sample(samAnisotropic, pin.Tex);
---      float4 in2 = txInput2.Sample(samAnisotropic, pin.Tex + gValueVec);
---      return gFlag ? pin.NormalView * in1 + in2 * gValueColor : in2;
---    }
---  ]]
---})
---```
---
---Tip: to simplify and speed things up, it might make sense to move table outside of a function to reuse it from frame
---to frame, simply accessing and updating textures, values and other parameters before call. However, make sure not to
---add new textures and values, otherwise it would require to recompile shader and might lead to VRAM leaks (if you would
---end up having thousands of no more used shaders). If you don’t have a working texture at the time of first creating
---that table, use `false` for missing texture value.
---
---Note: if shader would fail to compile, a C++ exception will be triggered, terminating script completely (to prevent AC 
---from crashing, C++ exceptions halt Lua script that triggered them until script gets a full reload).
---@return boolean @Returns `false` if shader is not yet ready and no drawing occured (happens only if `async` is set to `true`).
---@param params {pos: vec3, look: vec3, up: vec3, size: vec2, withDepth: boolean, expanded: boolean, uvOffset: vec2, blendMode: render.BlendMode, async: boolean, cacheKey: number, defines: table, textures: table, values: table, directValuesExchange: boolean, shader: string}|`{pos = vec3(), look = vec3(), up = vec3(0, 1, 0), size = vec2(), withDepth = true, expanded = true, blendMode = render.BlendMode.BlendAccurate, textures = {}, values = {}, shader = 'float4 main(PS_IN pin) {return float4(pin.Tex.x, pin.Tex.y, 0, 1);}'}` "Table with properties:\n- `pos` (`vec3`): Position from which texture will be projected, in world space.\n- `look` (`vec3`): Direction with which texture will be projected, in world space.\n- `up` (`vec3`): Optional vector directed up, to specify texture rotation.\n- `size` (`vec2`): Size, horizontal and vertical. Default value: `vec2(1, 1)`.\n- `withDepth` (`boolean`): If depth is used, nearest to projection position triagles will have higher priority (in case of overlapping UV), slightly slower, but produces better results (especially with `expanded` set to `true`).\n- `expanded` (`boolean`): Draws each mesh four additional times with small offsets to fill partically covered pixels. More expensive (but less expensive comparing to fixing issue with those half covered pixels with additional draw calls via Lua).\n- `uvOffset` (`vec2`): Optional UV offset. By default CSP estimates an UV offset such that most triagles would be shown. If mapping is way off though, it might need tweaking (or even repeated calls with different offsets).\n- `blendMode` (`render.BlendMode`): Blend mode. Default value: `render.BlendMode.BlendAccurate`.\n- `async` (`boolean`): If set to `true`, drawing won’t occur until shader would be compiled in a different thread.\n- `cacheKey` (`number`): Optional cache key for compiled shader (caching will depend on shader source code, but not on included files, so make sure to change the key if included files have changed).\n- `defines` (`table`): Defines to pass to the shader, either boolean, numerical or string values (don’t forget to wrap complex expressions in brackets). False values won’t appear in code and true will be replaced with 1 so you could use `#ifdef` and `#ifndef` with them.\n- `textures` (`table`): Table with textures to pass to a shader. For textures, anything passable in `ui.image()` can be used (filename, remote URL, media element, extra canvas, etc.). If you don’t have a texture and need to reset bound one, use `false` for a texture value (instead of `nil`)\n- `values` (`table`): Table with values to pass to a shader. Values can be numbers, booleans, vectors, colors or 4×4 matrix. Values will be aligned automatically.\n- `directValuesExchange` (`boolean`): If you’re reusing table between calls instead of recreating it each time and pass `true` as this parameter, `values` table will be swapped with an FFI structure allowing to skip data copying step and achieve the best performance. Note: with this mode, you’ll have to transpose matrices manually.\n- `shader` (`string`): Shader code (format is HLSL, regular DirectX shader); actual code will be added into a template in “assettocorsa/extension/internal/shader-tpl/project.fx” (look into it to see what fields are available)."
function _ac_SceneReference:projectShader(params) end

---@return ac.SceneReference
function ac.emptySceneReference() end

---Creates a new scene reference containing objects (nodes, meshes, etc.) collected with a filter from root node associated with current script. For most scripts it would be an AC root node. For track scripts,
---track root node. For car scripts, car’s root.
---
---Node: for most cases, using `ac.findNodes()`, `ac.findMeshes()` and similar would work better.
---@param s string @Node/mesh filter.
---@return ac.SceneReference
function ac.findAny(s) end

---Creates a new scene reference containing nodes collected with a filter from root node associated with current script. For most scripts it would be an AC root node. For track scripts,
---track root node. For car scripts, car’s root.
---
---Just a reminder, nodes refer to parent objects. Themselves, don’t get rendered, only their children elements (which might be nodes or meshes), but they can move.
---
---Filter is regular stuff, the same as used in INI configs. To use complex filter with commas and operators, wrap it in curly brackets as usual. There are also some special keywords available:
---- `'luaRoot:yes'`: root node associated with current script.
---- `'sceneRoot:yes'`: the most root node (do not add your objects here, they won’t be drawn properly).
---- `'carsRoot:yes'`: node that hosts all the cars. If you want to load custom dynamic objects, especially complex, it’s recommended to load them in bounding sphere and attach here (this node is optimized to render bounding sphere-wrapped objects quickly).
---- `'trackRoot:yes'`: track root node.
---- `'staticRoot:yes'`: node with static geometry (affected by motion blur from original AC).
---- `'dynamicRoot:yes'`: node with dynamic geometry (node affected by motion blur from original AC).
---
---Note: if you’re adding new objects to a car, seach for `'BODYTR'` node. Car root remains stationary and hosts “BODYTR” for main car model and things like wheels and suspension nodes.
---@param s string @Node filter.
---@return ac.SceneReference
function ac.findNodes(s) end

---Creates a new scene reference containing meshes collected with a filter from root node associated with current script. For most scripts it would be an AC root node. For track scripts,
---track root node. For car scripts, car’s root.
---
---Just as a reminder, meshes can’t move. If you want to move a mesh, find its parent node and move it. If parent node has more than a single mesh, you can create a new parent node and move
---mesh found with `ac.findMeshes()` there.
---
---Filter is regular stuff, the same as used in INI configs. To use complex filter with commas and operators, wrap it in curly brackets as usual.
---@param s string @Mesh filter.
---@return ac.SceneReference
function ac.findMeshes(s) end

---Creates a new scene reference containing skinned meshes collected with a filter from root node associated with current script. For most scripts it would be an AC root node. For track scripts,
---track root node. For car scripts, car’s root.
---
---Filter is regular stuff, the same as used in INI configs. To use complex filter with commas and operators, wrap it in curly brackets as usual.
---@param s string @Mesh filter.
---@return ac.SceneReference
function ac.findSkinnedMeshes(s) end

---Creates a new scene reference containing objects of a certain class collected with a filter from root node associated with current script. For most scripts it would be an AC root node. For track scripts,
---track root node. For car scripts, car’s root.
---
---Filter is regular stuff, the same as used in INI configs. To use complex filter with commas and operators, wrap it in curly brackets as usual.
---@param objectClass ac.ObjectClass @Objects class.
---@param s string @Mesh filter.
---@return ac.SceneReference
function ac.findByClass(objectClass, s) end

---@param sceneReference ac.SceneReference|{reference: ac.SceneReference?, opaque: fun()?, transparent: fun()?} @Reference to nodes or meshes to draw, or a table with reference and callbacks for custom drawing.
---@param resolution vec2 @Resolution in pixels. Usually textures with sizes of power of two work the best.
---@param mips integer? @Number of MIPs for a texture. MIPs are downsized versions of main texture used to avoid aliasing. Default value: 1 (no MIPs).
---@param withDepth boolean? @If set to `true`, depth buffer will be available to show as well.
---@param antialiasingMode render.AntialiasingMode? @Antialiasing mode. Default value: `render.AntialiasingMode.None` (disabled).
---@param textureFormat render.TextureFormat? @Texture format. Default value: `render.TextureFormat.R8G8B8A8.UNorm`. Note: antialiasing expects the default format.
---@param flags render.TextureFlags? @Extra flags. Default value: `0`.
---@return ac.GeometryShot
---@overload fun(sceneReference: ac.SceneReference, resolution: vec2|integer, mips: integer, withDepth: boolean, textureFormat: render.TextureFormat)
function ac.GeometryShot(sceneReference, resolution, mips, withDepth, antialiasingMode, textureFormat, flags) end

---This thing allows to draw 3D objects in UI functions (or use them as textures in `ac.SceneReference:setMaterialTexture()`, 
---for example). Prepare a scene reference (might be a bunch of nodes or meshes), create a new `ac.GeometryShot` with that reference,
---call `ac.GeometryShot:update()` with camera parameters and then use resulting shot instead of a texture name.
---
---Each `ac.GeometryShot` holds a GPU texture in R8G8B8A8 format with optional MIPs and additional depth texture in D32 format, so
---don’t create too many of those and use `ac.GeometryShot:dispose()` for shots you no longer need (or just lose them to get garbage
---collected, but it might take more time.
---
---
---@class ac.GeometryShot
local _ac_GeometryShot = nil

---Disposes geometry shot and releases resources.
function _ac_GeometryShot:dispose() end

---Sets geometry shot name for debugging. Shots with set name appear in Lua Debug App, allowing to monitor their state.
---@param name string? @Name to display texture as. If set to `nil` or `false`, name will be reset and texture will be hidden.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setName(name) end

---Updates texture making a shot of referenced geometry with given camera parameters. Camera coordinates are set in world space.
---
---To make orthogonal shot, pass 0 as `fov`.
---@param pos vec3 @Camera position.
---@param look vec3 @Camera direction.
---@param up vec3? @Camera vector facing upwards relative to camera. Default value: `vec3(0, 1, 0)`.
---@param fov number? @FOV in degrees. Default value: 90.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:update(pos, look, up, fov) end

---Updates texture making a shot from a position of a track camera. Pass the index of a car to focus on.
---@param carIndex integer? @0-based car index. Default value: `0`.
---@param camerasSet integer? @0-based cameras set index. Default value: `-1` (use currently selected set).
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:updateWithTrackCamera(carIndex, camerasSet) end

---Returns a texture reference to a depth buffer (only if created with `withDepth` set to `true`), which you can use to draw
---depth buffer with something like `ui.image(shot:depth(), vec2(320, 160))`.
---
---Note: buffer is treated like a single-channel texture so it would show in red, but with `ui.setShadingOffset()` you can draw
---it differently.
---@return string
function _ac_GeometryShot:depth() end

---Clears texture.
---@param col rgbm
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:clear(col) end

---Generates MIPs. Once called, switches texture to manual MIPs generating mode. Note: this operation is not that expensive, but it’s not free.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:mipsUpdate() end

---Forces opaque meshes to show up as white in alpha channel. Disabled by default. Might not work with some exotic materials.
---Since v0.2.3 also applies an extra post-processing pass fixing alpha with YEBIS.
---@param value boolean? @Set to `true` to enable a fix. Default value: `true`.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setOpaqueAlphaFix(value) end

---Enables or disables transparent pass (secondary drawing pass with transparent surfaces). Disabled by default.
---@param value boolean? @Set to `true` to enable transparent pass. Default value: `true`.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setTransparentPass(value) end

---Enables or disables drawing of car fake shadows (applies to any car roots in scene reference; when drawing entire scene
---car shadows will be drawn regardless). Disabled by default.
---@param value boolean? @Set to `true` to enable drawing of car fake shadows. Default value: `true`.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setFakeCarShadows(value) end

---Enables original lighting (stops from switching to neutral lighting active by default). With original lighting,
---methods like `shot:setAmbientColor()` and `shot:setReflectionColor()` would no longer have an effect.
---@param value boolean? @Set to `true` to enable original lighting. Default value: `true`.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setOriginalLighting(value) end

---Enables sky in the shot. By default, sky is not drawn.
---@param value boolean? @Set to `true` to enable sky. Default value: `true`.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setSky(value) end

---Enables particles in the shot. By default, particles are not drawn.
---
---Note: this is not working well currently with post-processing active, drawing HDR colors into LDR texture. 
---Better support for such things is coming a bit later.
---@param value boolean? @Set to `true` to enable particles. Default value: `true`.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setParticles(value) end

---Changes used shaders set. Switch to a set like `render.ShadersType.SampleColor` to access color of surface without any extra effects.
---@param type render.ShadersType? @Type of shaders set to use. Default value: `render.ShadersType.Simplified`.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setShadersType(type) end

---Replaces shadow set with an alternative one. Pretty expensive, use carefully.
---@param type 'area' @Type of shadow set to use.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setAlternativeShadowsSet(type) end

---Changes maximum layer of which meshes to render. 0 is for lowest world detail, 5 for highest.
---@param value integer @Layer value (aka world detail level).
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setMaxLayer(value) end

---Sets clipping planes. If clipping planes are too far apart, Z-fighting might occur. Note: to avoid Z-fighting, increasing
---nearby clipping plane distance helps much more.
---@param near number? @Nearby clipping plane in meters. Default value: 0.05.
---@param far number? @Far clipping plane in meters. Default value: 1000.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setClippingPlanes(near, far) end

---Sets orthogonal parameters.
---@param size vec2
---@param depth number
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setOrthogonalParams(size, depth) end

---Sets clear color to clear texture with before each update. Initial value: `rgbm(0.1, 0.1, 0.1, 0)`.
---@param value rgbm @Clear color from 0 to 1. Initial value: `rgbm(0.1, 0.1, 0.1, 0)`.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setClearColor(value) end

---Sets ambient color used for general lighting.
---@param value rgbm @Ambient color. Initial value: `rgbm(3, 3, 3, 1)`.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setAmbientColor(value) end

---Sets color for reflection gradient.
---@param zenith rgbm @Zenith reflection color. Initial value: `rgbm(1, 1, 1, 1)`.
---@param horizon rgbm @Horizon reflection color. Initial value: `rgbm(0, 0, 0, 1)`.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setReflectionColor(zenith, horizon) end

---Configures geometry shot for the best possible quality for a scene shot, such as including all the geometry (maximum
---world detail), enabling particles, transparent pass, main shaders, etc. If you need something like making a nice shot
---of a scene from a certain point of view, this might be a good shortcut: if more visually improving features will be 
---added in the future, they’ll be included here as well.
---
---Please avoid using it for something like rear view camera or a track display though, they could definitely benefit from
---using simpler shaders or lower level of detail.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setBestSceneShotQuality() end

---Overrides exposure used if antialiasing mode is set to YEBIS value. By default scene exposure is used.
---@param value number? @Exposure used by YEBIS post-processing. Pass `nil` to reset to default behavior.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:setExposure(value) end

---Returns texture resolution (or zeroes if element has been disposed).
---@return vec2
function _ac_GeometryShot:size() end

---Returns number of MIP maps (1 for no MIP maps and it being a regular texture).
---@return integer
function _ac_GeometryShot:mips() end

---Returns view transform used in the last update. Matrix is all zeroes if update was never called.
---@return mat4x4
function _ac_GeometryShot:viewMatrix() end

---Returns projection transform used in the last update. Matrix is all zeroes if update was never called.
---@return mat4x4
function _ac_GeometryShot:projectionMatrix() end

---Returns shared handle to the texture. Shared handle can be used in other scripts with `ui.SharedTexture()`, or, if `crossProcess` flag
---is set to `true`, also accessed by other processes.
---@param crossProcess boolean? @Set to `true` to be able to pass a handle to other processes. Requires `render.TextureFlags.Shared` flag to be set during creation. Default value: `false`.
---@return integer
function _ac_GeometryShot:sharedHandle(crossProcess) end

---Manually applies antialiasing to the texture (works only if it was created with a specific antialiasing mode).
---By default antialiasing is applied automatically, but calling this function switches AA to a manual mode.
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:applyAntialiasing() end

---Saves shot as an image.
---@param filename string @Destination filename.
---@param format ac.ImageFormat? @Texture format (by default guessed based on texture name).
---@return ac.GeometryShot @Returns itself for chaining several methods together.
function _ac_GeometryShot:save(filename, format) end

---Returns image encoded in DDS format. Might be useful if you would need to store an image
---in some custom form (if so, consider compressing it with `ac.compress()`).
---
---Note: you can later use `ui.decodeImage()` to get a string which you can then pass as a texture name
---to any of texture receiving functions. This way, you can load image into a new canvas later: just
---create a new canvas (possibly using `ui.imageSize()` first to get image size) and update it drawing
---imported image to the full size of the canvas.
---@return string|nil @Binary data, or `nil` if binary data export has failed.
function _ac_GeometryShot:encode() end

---Downloads data from GPU to CPU asyncronously (usually takes about 0.15 ms to get the data). Resulting data can be
---used to access colors of individual pixels or upload it back to CPU restoring original state.
---@param callback fun(err: string, data: ui.ExtraCanvasData)
function _ac_GeometryShot:accessData(callback) end
--[[ lib_tracklines.lua ]]

---Easily add new lines on a track. Automatically tries to align with track height, but correct Y coordinate is still very welcome (just use
---the actual track Y coordinate, offsets to avoid clipping issues will be added automatically).
---
---If you want to draw many lines of a flat surface, consider setting `.castStep` to `math.huge` so that raycasts would be mostly skipped. If
---you find API lacking certain things, or performance not being enough, please contact me and I’ll add missing capabilities.
---@class ac.TrackPaint
---@field transform mat4x4 @Transformation matrix.
---@field castStep number @Gap between rays cast against physical surface. Default value: 0.5 (two rays per meter). Set to `math.huge` to disable pretty much all casts if you need to add a ton of things drawn on a flat surface.
---@field paddingSize number @Padding size in meters. Set to 0 to disable thickness entirely (not recommended).
---@field defaultThickness number @Line thickness in meters used if thickness is not specified. Default value: 0.1.
---@field ageFactor number @How aged do lines look. Default value: 0.5.
---@field bulgeFactor number @How thick (vertically) is the paint. At default value, 0.25, it’ll be about 5 mm thick. Helps to see lines from grazing angles. Won’t have an effect if `.paddingSize` is set to 0. Default value: 0.25.
---@field forceRecast boolean @Set to `true` to force surface recast for lines, images and shapes (by default, recast only activates on uneven surfaces).
---@field alignShapes boolean @Set to `false` to disable shapes (such as `:circle()` or `:rect()`) alignment on the surface (they will be projected as if ground is flat, with XZ unchanging).
local _ac_TrackPaint = nil

---Destroy everything and release resources.
function _ac_TrackPaint:release() end

---Reset content, including drawn shapes, textures or shapes being drawn with `:to()`.
---@return self
function _ac_TrackPaint:reset() end

---A shortcut to quickly set `.ageFactor` value (useful if you want to chain multiple calls together).
---@param value number? @Age factor from 0 to 1. Default value: 0.5.
---@return self
function _ac_TrackPaint:age(value) end

---A shortcut to quickly set `.bulgeFactor` value (useful if you want to chain multiple calls together).
---@param value number? @Bulge factor from 0 to 1. Default value: 0.25.
---@return self
function _ac_TrackPaint:bulge(value) end

---A shortcut to quickly set `.paddingSize` value (useful if you want to chain multiple calls together).
---@param value number? @Padding size in meters. Default value: 0.03.
---@return self
function _ac_TrackPaint:padding(value) end

---Quickly add a separate straight line. Does a bit of raycasting and surface alignment depending on current values of `castStep` and `forceRecast`.
---
---Padding (see `.paddingSize`) is added to the line. This means that with large enough padding, line will appear larger.
---@param from vec3 @World position for first point of a line.
---@param to vec3 @World positoon for the last point of a line.
---@param color rgbm? @Line color. Default value: `rgbm.colors.white`.
---@param thickness number? @Thickness in meters. If not set, `.defaultThickness` will be used.
---@return self
function _ac_TrackPaint:line(from, to, color, thickness) end

---Quickly add an image. Does a bit of raycasting and surface alignment depending on current values of `castStep` and `forceRecast`.
---Only four unique textures are allowed per `ac.TrackPaint()` instance. If you need more and the best performance, use atlases and texture coordinates.
---Raises an error if there are too many textures set already.
---
---Size of the resulting image is guaranteed to match input `size` no matter the padding (see `.paddingSize`). This means that with large enough padding,
---image edges will be cut off.
---@param image string @Texture name or image, such as `ui.decodeImage()` output.
---@param pos vec3 @World position of an image.
---@param size number|vec2 @Size in meters.
---@param angle number? @Angle in degrees. Default value: `0`.
---@param color rgbm? @Optional color multiplying the texture color.
---@param uv1 vec2? @Texture coordinates for the top left corner. Should be within 0…1 range. Default value: `vec2(0, 0)`. 
---@param uv2 vec2? @Texture coordinates for the bottom right corner. Should be within 0…1 range. Default value: `vec2(1, 1)`.
---@return self
function _ac_TrackPaint:image(image, pos, size, angle, color, uv1, uv2) end

---For advanced cases, use carefully. All shapes drawn between `:textureStart()` and subsequent `:textureEnd()` calls will get a texture mapped onto them.
---Only four unique textures are allowed per `ac.TrackPaint()` instance. If you need more and the best performance, use atlases and texture coordinates.
---Raises an error if there are too many textures set already.
---@return self
function _ac_TrackPaint:textureStart() end

---For advanced cases, use carefully. All shapes drawn between `:textureStart()` and subsequent `:textureEnd()` calls will get a texture mapped onto them.
---Only four unique textures are allowed per `ac.TrackPaint()` instance. If you need more and the best performance, use atlases and texture coordinates.
---Raises an error if there are too many textures set already.
---@param image string @Texture name or image, such as `ui.decodeImage()` output.
---@param pivot vec3 @World position of top left corner of the texture.
---@param offsetX vec3 @World offset corresponding with horizontal direction of the image.
---@param offsetY vec3 @World offset corresponding with vertical direction of the image.
---@param uv1 vec2? @Texture coordinates for the top left corner. Should be within 0…1 range. Default value: `vec2(0, 0)`. 
---@param uv2 vec2? @Texture coordinates for the bottom right corner. Should be within 0…1 range. Default value: `vec2(1, 1)`.
---@return self
function _ac_TrackPaint:textureEnd(image, pivot, offsetX, offsetY, uv1, uv2) end

---Quickly add text. Does a bit of raycasting and surface alignment.
---Only four unique textures are allowed per `ac.TrackPaint()` instance, and each unique font used here counts as a texture.
---
---Value `.paddingSize` has no effect on this function.
---@param font string @Font name. Refers to font in “content/fonts”, or in the script folder (same logic as with `ui.pushACFont()`).
---@param text string @Text to draw.
---@param pos vec3 @World position of an image.
---@param size number|vec2 @Size in meters. Text will be fit within that area while preserving aspect ratio.
---@param angle number? @Angle in degrees. Default value: `0`.
---@param color rgbm? @Optional color multiplying the texture color.
---@param aspectRatio number? @Optional aspect ratio modifier. Decrease to stretch font vertically. Default value: `0`.
---@return self
function _ac_TrackPaint:text(font, text, pos, size, angle, color, aspectRatio) end

---Call multiple times to generate a list of points, and then turn them into a line or a figure using `:stroke()` or `:fill()`. 
---Doesn’t do anything if position is too close to previously added position.
---@param pos vec3? @Position to move spline to. If `nil`, does nothing.
---@param segments integer? @Explicitly specify number of segments (not recommended, but if you need to draw a complex shape on a flat surface, maybe set it to 1).
---@return self
function _ac_TrackPaint:to(pos, segments) end

---Draw an arc. Connects current position (last call to `:to()`) to the beginning of the arc. Call `:stroke()` or `:fill()` to finish the shape.
---@param center vec3 @Arc’s center.
---@param radius number @Arc radius, must be positive.
---@param startAngle number @The angle at which the arc starts in degrees, measured from the positive x-axis.
---@param endAngle number @The angle at which the arc ends in degrees, measured from the positive x-axis.
---@param anticlockwise boolean? @An optional boolean value. If true, draws the arc counter-clockwise between the start and end angles. Default value: `false` (clockwise).
---@param segments integer? @Segments for the entire circle (similar to `:circle()`).
---@return self
function _ac_TrackPaint:arc(center, radius, startAngle, endAngle, anticlockwise, segments) end

---Draw an arc from the current point to the target point. If `:to()` wasn’t called, it’ll start from 0.
---Call `:stroke()` or `:fill()` to finish the shape.
---
---Mirrors JavaScript’s canvas call: <https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/arcTo>.
---@param point1 vec3 @Arc’s first control point.
---@param point2 vec3 @Arc’s second control point.
---@param radius number? @Arc radius, must be positive. If not set or above maximum reasonable value, will be set to that value.
---@param segments integer? @Segments for the entire circle (similar to `:circle()`).
---@return self
function _ac_TrackPaint:arcTo(point1, point2, radius, segments) end

---Draw a quadratic curve from the current point to the target point. If `:to()` wasn’t called, it’ll start from 0.
---Call `:stroke()` or `:fill()` to finish the shape.
---
---Mirrors JavaScript’s canvas call: <https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/quadraticCurveTo>.
---@param controlPoint vec3 @Control point for the curve.
---@param endPoint vec3 @Final point.
---@param segments integer? @Number of segments. Default value: 20.
---@return self
function _ac_TrackPaint:quadraticCurveTo(controlPoint, endPoint, segments) end

---Draw a bezier curve from the current point to the target point. If `:to()` wasn’t called, it’ll start from 0.
---Call `:stroke()` or `:fill()` to finish the shape.
---
---Mirrors JavaScript’s canvas call: <https://developer.mozilla.org/en-US/docs/Web/API/CanvasRenderingContext2D/bezierCurveTo>.
---@param controlPoint1 vec3
---@param controlPoint2 vec3
---@param endPoint vec3
---@return self
function _ac_TrackPaint:bezierCurveTo(controlPoint1, controlPoint2, endPoint) end

---Turn points added with `:to()` into a line.
---@param closed boolean? @If set to `true`, closes points into a figure. Default value: `false`.
---@param color rgbm? @Line color. Default value: `rgbm.colors.white`.
---@param thickness number? @Thickness in meters. If not set, `.defaultThickness` will be used.
---@return self
function _ac_TrackPaint:stroke(closed, color, thickness) end

---Call this function to configure dash pattern. Pass an array specifying alternating lengths of lines and gaps. Pass `nil` or empty table to disable dashes.
---
---When using, keep in mind `.paddingSize`, it could make lines visually longer.
---@param pattern number[]? @Lengths of dashes and lines in meters. If the number of elements in the array is odd, the elements of the array get copied and concatenated.
---@return self
function _ac_TrackPaint:strokeDash(pattern, colors) end

---Call this function if you want to draw parallel lines when calling `:stroke()` or using shape functions. Up to four parallel lines at once can be drawn. Call it again
---with `nil`, empty table or table containing one element to reset the pattern. Raises an error if you’ll pass more than 8 elements thus trying to draw more than 4 lines at once.
---
---When using, keep in mind `.paddingSize`, it could make lines visually wider.
---@param pattern number[]? @Width of the first line, space between first and second, width of the second line, etc. Total width will be normalized to match stroke width.
---@param colors (rgbm|false)[]? @If set, allows to override colors for specific lines. Pass `false` to keep original color. If `pattern` is empty or defines less than two lines, ignored.
---@param dashes (number[]|false)[]? @If set, overrides dash pattern for specific lanes. The most expensive option to draw (but still faster than repeating calls in Lua).
---@return self
function _ac_TrackPaint:strokePattern(pattern, colors, dashes) end

---Turn points added with `:to()` into a shape. Shape can be concave, but be vary of how points are arranged: algorithm used for triangulating
---a set of points might crash or get stuck with strange cases.
---
---If you want to add a hole to the generated mesh, first add its outline using `:to()`, then call `:fillHole()`, and after that add points to
---the outer area using `:to()` and call `:fill()` to finalize the result.
---
---Sometimes triangulation process can be helped with `:fillHint()`.
---@param color rgbm? @Shape color. Default value: `rgbm.colors.white`.
---@return self
function _ac_TrackPaint:fill(color) end

---Turn points added with `:to()` to a hole for a subsequent `:fill()` call. Note: holes can’t touch outer perimeter. Also, a shape can’t have
---intersecting or touching holes.
---@return self
function _ac_TrackPaint:fillHole() end

---Add a separate vertex to a subsequent `:fill()` call. Could be useful to hint triangulation process.
---@param pos vec3 @Point position.
---@return self
function _ac_TrackPaint:fillHint(pos) end

---Quickly add a circle. If `thickness` is `false` or not set, circle will be filled.
---@param pos vec3 @Circle position.
---@param radius number? @Circle radius in meters. Default value: 1.
---@param thickness boolean|number? @Pass `true` to use `.defaultThickness`. Default value: `false` (filled circle).
---@param color rgbm? @Color. Default value: `rgbm.colors.white`.
---@param segments integer? @Number of segments. Should be between 3 and 100. If not set, guessed based on radius.
---@return self
function _ac_TrackPaint:circle(pos, radius, thickness, color, segments) end

---Quickly add an ellipse. If `thickness` is `false` or not set, ellipse will be filled.
---@param pos vec3 @Ellipse position.
---@param radii vec2 @Ellipse radii in meters.
---@param angle number? @Ellipse orientation. Default value: 0.
---@param thickness boolean|number? @Pass `true` to use `.defaultThickness`. Default value: `false` (filled ellipse).
---@param color rgbm? @Color. Default value: `rgbm.colors.white`.
---@param segments integer? @Number of segments. Should be between 3 and 100. If not set, guessed based on radius.
---@return self
function _ac_TrackPaint:ellipse(pos, radii, angle, thickness, color, segments) end

---Quickly add a rect. If `thickness` is `false` or not set, rect will be filled.
---@param pos vec3 @Rect position.
---@param size vec2 @Rect size in meters.
---@param angle number? @Rect orientation. Default value: 0.
---@param thickness boolean|number? @Pass `true` to use `.defaultThickness`. Default value: `false` (filled rect).
---@param color rgbm? @Color. Default value: `rgbm.colors.white`.
---@param cornerRadius number? @Corner radius. Default value: `0`.
---@return self
function _ac_TrackPaint:rect(pos, size, angle, thickness, color, cornerRadius) end

---Quickly add a triangle. If `thickness` is `false` or not set, triangle will be filled.
---@param pos vec3 @Triangle position.
---@param size vec2 @Triangle size in meters.
---@param angle number? @Triangle orientation. Default value: 0.
---@param thickness boolean|number? @Pass `true` to use `.defaultThickness`. Default value: `false` (filled triangle).
---@param color rgbm? @Color. Default value: `rgbm.colors.white`.
---@return self
function _ac_TrackPaint:triangle(pos, size, angle, thickness, color) end

---Quickly add a triangle. If `thickness` is `false` or not set, triangle will be filled.
---@param pos vec3 @Triangle position.
---@param size vec2 @Triangle size in meters.
---@param angle number? @Triangle orientation. Default value: 0.
---@param thickness boolean|number? @Pass `true` to use `.defaultThickness`. Default value: `false` (filled triangle).
---@param color rgbm? @Color. Default value: `rgbm.colors.white`.
---@param shape1 number? @First shape modifier, from 0 to 1. Default value: `0.5`.
---@param shape2 number? @Second shape modifier, from 0 to 1. Default value: `0.5`.
---@return self
function _ac_TrackPaint:arrow(pos, size, angle, thickness, color, shape1, shape2) end

---Writes additional data to replay. Use `ac.readReplayBlob()` to extract data later in replay mode. Data written this way is not tied to frames.
---Don’t bother compressing data too much: when writing, data will be compressed automatically.
---@param key string @Existing data with the same key will be overwritten.
---@param data binary?
function ac.writeReplayBlob(key, data) end

---Reads additional data from replay if recorded with `ac.writeReplayBlob()`.
---@param key string
---@return binary?
function ac.readReplayBlob(key) end

---Create a new stream for recording data to replays. Write data in returned structure if not in replay mode, read data if in replay mode (use `sim.isReplayActive` to check if you need to write or read the data).
---Few important points:
--- - Each frame should not exceed 256 bytes to keep replay size appropriate. Limit for car scripts is lower, only 32 bytes.
--- - While data will be interpolated between frames during reading, directional vectors won’t be re-normalized.
--- - If two different apps would open a stream with the same layout, they’ll share a replay entry. Since 0.2.8, they’ll also share memory block, making `ac.ReplayStream()` act similar to `ac.connect()`.
--- - Each opened replay stream will persist through the entire AC session to be saved at the end. Currently, the limit is 320 streams per session (before 0.2.8, the limit was 128).
--- - Default values for unitialized frames are zeroes.
--- - Before 0.2.8, if game is launched in replay mode and there is no such data in replay, `ac.ReplayStream()` could return `nil`. Now, it’ll return the data, but it’ll be empty.
--- - Car scripts (both visual and physics) automatically add car ID and index to the key, ensuring uniqueness. Visual scripts can’t create new streams, but can access streams created by physics scripts, making it an effective way to pass data from physics to render, automatically being recorded in replays.
---@generic T
---@param layout T @A table containing fields of structure and their types. Use `ac.StructItem` methods to select types. Unlike other similar functions, here you shouldn’t use string, otherwise data blending won’t work.
---@param callback fun()? @Callback that will be called when replay stops. Use this callback to re-apply data from structure: at the moment of the call it will contain stuff from last recorded frame allowing you to restore the state of a simulation to when replay mode was activated.
---@param frameDivisor integer? @Set to 2 to skip one out of two frames when recording, or 3 to skip two out of three frames. Default value: `1` (no skipping). Reduces replay size.
---@return T @Might return `nil` if there is game is launched in replay mode and there is no such data stored in the replay.
function ac.ReplayStream(layout, callback, frameDivisor) end
--[[ lib_carcameradef.lua ]]

---Stores parameters for a car camera (enabled with F6).
---@class ac.CarCameraParams
---@field transform mat4x4 @Transformation relative to car model. Note: due to some techical reasons direction `.look` is facing backwards.
---@field fov number @Field of view angle in degrees, automatically guessed value: 10.
---@field exposure number @Exposure.
---@field externalSound boolean @Should internal or external audio be used.
---@field index integer @Read-only field with camera index for reference.
---@field carIndex integer @Read-only field with car index for reference.
---@field clipNear number? @Near clip distance in meters. If `nil`, automatically computed value (depends on graphics settings) is used. Being an extension on top of original AC, might be slower to access than other fields. If you want to add a field to “cameras.ini”, use `__EXT_CLIP_NEAR` key. Altering this value might lead CSP to alter far clip value as well.
local _ac_CarCameraParams = nil

---@alias ac.AudioDSP
---| `ac.AudioDSP.Oscillator` @- Generates sine/square/saw/triangle or noise tones.
---| `ac.AudioDSP.LowPass` @- Filters sound using a high quality, resonant lowpass filter algorithm but consumes more CPU time.
---| `ac.AudioDSP.ITLowPass` @- Filters sound using a resonant lowpass filter algorithm that is used in Impulse Tracker, but with limited cutoff range (0 to 8060hz).
---| `ac.AudioDSP.HighPass` @- Filters sound using a resonant highpass filter algorithm.
---| `ac.AudioDSP.Echo` @- Produces an echo on the sound and fades out at the desired rate.
---| `ac.AudioDSP.Fader` @- Pans and scales the volume of a unit.
---| `ac.AudioDSP.Flange` @- Produces a flange effect on the sound.
---| `ac.AudioDSP.Distortion` @- Distorts the sound.
---| `ac.AudioDSP.Normalize` @- Normalizes or amplifies the sound to a certain level.
---| `ac.AudioDSP.Limiter` @- Limits the sound to a certain level.
---| `ac.AudioDSP.ParamEQ` @- Attenuates or amplifies a selected frequency range.
---| `ac.AudioDSP.PitchShift` @- Bends the pitch of a sound without changing the speed of playback.
---| `ac.AudioDSP.Chorus` @- Produces a chorus effect on the sound.
---| `ac.AudioDSP.SFXReverb` @- Implements SFX reverb.
---| `ac.AudioDSP.LowPassSimple` @- Filters sound using a simple lowpass with no resonance, but has flexible cutoff and is fast.
---| `ac.AudioDSP.Delay` @- Produces different delays on individual channels of the sound.
---| `ac.AudioDSP.Tremolo` @- Produces a tremolo / chopper effect on the sound.
---| `ac.AudioDSP.HighPassSimple` @- Filters sound using a simple highpass with no resonance, but has flexible cutoff and is fast.
---| `ac.AudioDSP.Pan` @- Pans the signal, possibly upmixing or downmixing as well.
---| `ac.AudioDSP.ThreeEQ` @- Is a three-band equalizer.
ac.AudioDSP = {
  Oscillator = 'oscillator', ---@type ac.AudioDSP #- Generates sine/square/saw/triangle or noise tones.
  LowPass = 'lowpass', ---@type ac.AudioDSP #- Filters sound using a high quality, resonant lowpass filter algorithm but consumes more CPU time.
  ITLowPass = 'itlowpass', ---@type ac.AudioDSP #- Filters sound using a resonant lowpass filter algorithm that is used in Impulse Tracker, but with limited cutoff range (0 to 8060hz).
  HighPass = 'highpass', ---@type ac.AudioDSP #- Filters sound using a resonant highpass filter algorithm.
  Echo = 'echo', ---@type ac.AudioDSP #- Produces an echo on the sound and fades out at the desired rate.
  Fader = 'fader', ---@type ac.AudioDSP #- Pans and scales the volume of a unit.
  Flange = 'flange', ---@type ac.AudioDSP #- Produces a flange effect on the sound.
  Distortion = 'distortion', ---@type ac.AudioDSP #- Distorts the sound.
  Normalize = 'normalize', ---@type ac.AudioDSP #- Normalizes or amplifies the sound to a certain level.
  Limiter = 'limiter', ---@type ac.AudioDSP #- Limits the sound to a certain level.
  ParamEQ = 'parameq', ---@type ac.AudioDSP #- Attenuates or amplifies a selected frequency range.
  PitchShift = 'pitchshift', ---@type ac.AudioDSP #- Bends the pitch of a sound without changing the speed of playback.
  Chorus = 'chorus', ---@type ac.AudioDSP #- Produces a chorus effect on the sound.
  SFXReverb = 'sfxreverb', ---@type ac.AudioDSP #- Implements SFX reverb.
  LowPassSimple = 'lowpasssimple', ---@type ac.AudioDSP #- Filters sound using a simple lowpass with no resonance, but has flexible cutoff and is fast.
  Delay = 'delay', ---@type ac.AudioDSP #- Produces different delays on individual channels of the sound.
  Tremolo = 'tremolo', ---@type ac.AudioDSP #- Produces a tremolo / chopper effect on the sound.
  HighPassSimple = 'highpasssimple', ---@type ac.AudioDSP #- Filters sound using a simple highpass with no resonance, but has flexible cutoff and is fast.
  Pan = 'pan', ---@type ac.AudioDSP #- Pans the signal, possibly upmixing or downmixing as well.
  ThreeEQ = 'threeeq', ---@type ac.AudioDSP #- Is a three-band equalizer.
}

---@alias render.ProjectFace
---| `render.ProjectFace.Auto` @Use current triple screen face during main rendering pass, or the whole screen during post-processing.
---| `render.ProjectFace.Screen` @`vec2(0, 0)` for the upper left corner of the screen, `vec2(0.5, 0.5)` for the center.
---| `render.ProjectFace.Current` @During main rendering pass, points to currently drawn face.
---| `render.ProjectFace.Left` @Value: 0.
---| `render.ProjectFace.Center` @Value: 1.
---| `render.ProjectFace.Right` @Value: 2.
render.ProjectFace = {
  Auto = -3, ---@type render.ProjectFace #Use current triple screen face during main rendering pass, or the whole screen during post-processing.
  Screen = -2, ---@type render.ProjectFace #`vec2(0, 0)` for the upper left corner of the screen, `vec2(0.5, 0.5)` for the center.
  Current = -1, ---@type render.ProjectFace #During main rendering pass, points to currently drawn face.
  Left = 0, ---@type render.ProjectFace #Value: 0.
  Center = 1, ---@type render.ProjectFace #Value: 1.
  Right = 2, ---@type render.ProjectFace #Value: 2.
}

---@alias render.PassID
---| `render.PassID.None` @No special options.
---| `render.PassID.Main` @Value: 0x1.
---| `render.PassID.Mirror` @Value: 0x2.
---| `render.PassID.CubeMap` @Value: 0x4.
---| `render.PassID.Extras` @Value: 0x8.
---| `render.PassID.All` @Value: 0xf.
render.PassID = {
  None = 0x0, ---@type render.PassID #No special options.
  Main = 0x1, ---@type render.PassID #Value: 0x1.
  Mirror = 0x2, ---@type render.PassID #Value: 0x2.
  CubeMap = 0x4, ---@type render.PassID #Value: 0x4.
  Extras = 0x8, ---@type render.PassID #Value: 0x8.
  All = 0xf, ---@type render.PassID #Value: 0xf.
}

---@alias render.BlendMode
---| `render.BlendMode.Opaque` @Value: 0.
---| `render.BlendMode.AlphaBlend` @Value: 1.
---| `render.BlendMode.AlphaTest` @Value: 2.
---| `render.BlendMode.BlendAdd` @Value: 4.
---| `render.BlendMode.BlendMultiply` @Value: 5.
---| `render.BlendMode.BlendSubtract` @Value: 12.
---| `render.BlendMode.BlendAccurate` @Value: 13.
---| `render.BlendMode.BlendPremultiplied` @Value: 14.
---| `render.BlendMode.OpaqueForced` @Works even in transparent pass.
render.BlendMode = {
  Opaque = 0, ---@type render.BlendMode #Value: 0.
  AlphaBlend = 1, ---@type render.BlendMode #Value: 1.
  AlphaTest = 2, ---@type render.BlendMode #Value: 2.
  BlendAdd = 4, ---@type render.BlendMode #Value: 4.
  BlendMultiply = 5, ---@type render.BlendMode #Value: 5.
  BlendSubtract = 12, ---@type render.BlendMode #Value: 12.
  BlendAccurate = 13, ---@type render.BlendMode #Value: 13.
  BlendPremultiplied = 14, ---@type render.BlendMode #Value: 14.
  OpaqueForced = 27, ---@type render.BlendMode #Works even in transparent pass.
}

---@alias render.CullMode
---| `render.CullMode.Front` @Value: 0.
---| `render.CullMode.Back` @Value: 1.
---| `render.CullMode.None` @Value: 2.
---| `render.CullMode.Wireframe` @Value: 4.
---| `render.CullMode.WireframeAntialised` @Value: 7.
---| `render.CullMode.ShadowsDouble` @Value: 9.
---| `render.CullMode.ShadowsSingle` @Value: 10.
render.CullMode = {
  Front = 0, ---@type render.CullMode #Value: 0.
  Back = 1, ---@type render.CullMode #Value: 1.
  None = 2, ---@type render.CullMode #Value: 2.
  Wireframe = 4, ---@type render.CullMode #Value: 4.
  WireframeAntialised = 7, ---@type render.CullMode #Value: 7.
  ShadowsDouble = 9, ---@type render.CullMode #Value: 9.
  ShadowsSingle = 10, ---@type render.CullMode #Value: 10.
}

---@alias render.DepthMode
---| `render.DepthMode.Normal` @Value: 0.
---| `render.DepthMode.ReadOnly` @Value: 1.
---| `render.DepthMode.Off` @Value: 2.
---| `render.DepthMode.LessEqual` @Value: 3.
---| `render.DepthMode.ReadOnlyLessEqual` @Value: 4.
---| `render.DepthMode.WriteOnly` @Value: 7.
render.DepthMode = {
  Normal = 0, ---@type render.DepthMode #Value: 0.
  ReadOnly = 1, ---@type render.DepthMode #Value: 1.
  Off = 2, ---@type render.DepthMode #Value: 2.
  LessEqual = 3, ---@type render.DepthMode #Value: 3.
  ReadOnlyLessEqual = 4, ---@type render.DepthMode #Value: 4.
  WriteOnly = 7, ---@type render.DepthMode #Value: 7.
}

---@alias render.GLPrimitiveType
---| `render.GLPrimitiveType.Lines` @Value: 0.
---| `render.GLPrimitiveType.LinesStrip` @Value: 1.
---| `render.GLPrimitiveType.Triangles` @Value: 2.
---| `render.GLPrimitiveType.Quads` @Value: 3.
render.GLPrimitiveType = {
  Lines = 0, ---@type render.GLPrimitiveType #Value: 0.
  LinesStrip = 1, ---@type render.GLPrimitiveType #Value: 1.
  Triangles = 2, ---@type render.GLPrimitiveType #Value: 2.
  Quads = 3, ---@type render.GLPrimitiveType #Value: 3.
}

---@alias render.FontAlign
---| `render.FontAlign.Left` @Value: 0.
---| `render.FontAlign.Right` @Value: 1.
---| `render.FontAlign.Center` @Value: 2.
render.FontAlign = {
  Left = 0, ---@type render.FontAlign #Value: 0.
  Right = 1, ---@type render.FontAlign #Value: 1.
  Center = 2, ---@type render.FontAlign #Value: 2.
}

---@alias render.ShadersType
---| `render.ShadersType.Main` @With lights and advanced version of shaders (when possible, consider using SimplifiedWithLights instead).
---| `render.ShadersType.Simplified` @Used by reflections and mirrors, without lights.
---| `render.ShadersType.SimplifiedWithLights` @Used by reflections and mirrors, with lights.
---| `render.ShadersType.Simplest` @The most basic option, without lights.
---| `render.ShadersType.SampleColor` @Get diffuse color as accurate as possible.
---| `render.ShadersType.SampleNormal` @Get surface normal in world space.
---| `render.ShadersType.SampleEmissive` @Get emissive color.
---| `render.ShadersType.Shadows` @@deprecated If you want cool looks, use `Main` instead, this was originally meant to draw shadow maps, but due to some general issues isn’t working as intended, and for actual shadows use `SampleDepth`.
---| `render.ShadersType.SampleDepth` @Efficient option for generating depth map without wasting time on drawing the image, doesn’t update the main color texture (only meshes casting shadows are included).
render.ShadersType = {
  Main = 0, ---@type render.ShadersType #With lights and advanced version of shaders (when possible, consider using SimplifiedWithLights instead).
  Simplified = 13, ---@type render.ShadersType #Used by reflections and mirrors, without lights.
  SimplifiedWithLights = 14, ---@type render.ShadersType #Used by reflections and mirrors, with lights.
  Simplest = 16, ---@type render.ShadersType #The most basic option, without lights.
  SampleColor = 18, ---@type render.ShadersType #Get diffuse color as accurate as possible.
  SampleNormal = 19, ---@type render.ShadersType #Get surface normal in world space.
  SampleEmissive = 20, ---@type render.ShadersType #Get emissive color.
  Shadows = 0, ---@type render.ShadersType #@deprecated If you want cool looks, use `Main` instead, this was originally meant to draw shadow maps, but due to some general issues isn’t working as intended, and for actual shadows use `SampleDepth`.
  SampleDepth = 27, ---@type render.ShadersType #Efficient option for generating depth map without wasting time on drawing the image, doesn’t update the main color texture (only meshes casting shadows are included).
}

---These flags can be combined together with `bit.bor()`.
---@alias render.TextureMaskFlags
---| `render.TextureMaskFlags.Default` @Default: use alpha and red channel as multipliers.
---| `render.TextureMaskFlags.UseColorAverage` @Use average of RGB values.
---| `render.TextureMaskFlags.UseAlpha` @Use alpha of a mask as a multiplier.
---| `render.TextureMaskFlags.UseRed` @Use red channel of a mask as a multiplier.
---| `render.TextureMaskFlags.UseGreen` @Use green channel of a mask as a multiplier.
---| `render.TextureMaskFlags.UseBlue` @Use blue channel of a mask as a multiplier.
---| `render.TextureMaskFlags.UseInvertedAlpha` @Use inverted alpha of a mask as a multiplier.
---| `render.TextureMaskFlags.UseInvertedRed` @Use inverted red channel of a mask as a multiplier.
---| `render.TextureMaskFlags.UseInvertedGreen` @Use inverted green channel of a mask as a multiplier.
---| `render.TextureMaskFlags.UseInvertedBlue` @Use inverted blue channel of a mask as a multiplier.
---| `render.TextureMaskFlags.MixColors` @Use colors of a mask as a multiplier for main colors.
---| `render.TextureMaskFlags.MixInvertedColors` @Use inverted colors of a mask as a multiplier for main colors.
---| `render.TextureMaskFlags.AltUV` @Use alternative UV (for projecting textures onto meshes, uses original mesh UV instead of projection UV).
render.TextureMaskFlags = {
  Default = 0x6, ---@type render.TextureMaskFlags #Default: use alpha and red channel as multipliers.
  UseColorAverage = 0x1, ---@type render.TextureMaskFlags #Use average of RGB values.
  UseAlpha = 0x2, ---@type render.TextureMaskFlags #Use alpha of a mask as a multiplier.
  UseRed = 0x4, ---@type render.TextureMaskFlags #Use red channel of a mask as a multiplier.
  UseGreen = 0x8, ---@type render.TextureMaskFlags #Use green channel of a mask as a multiplier.
  UseBlue = 0x10, ---@type render.TextureMaskFlags #Use blue channel of a mask as a multiplier.
  UseInvertedAlpha = 0x20, ---@type render.TextureMaskFlags #Use inverted alpha of a mask as a multiplier.
  UseInvertedRed = 0x40, ---@type render.TextureMaskFlags #Use inverted red channel of a mask as a multiplier.
  UseInvertedGreen = 0x80, ---@type render.TextureMaskFlags #Use inverted green channel of a mask as a multiplier.
  UseInvertedBlue = 0x100, ---@type render.TextureMaskFlags #Use inverted blue channel of a mask as a multiplier.
  MixColors = 0x200, ---@type render.TextureMaskFlags #Use colors of a mask as a multiplier for main colors.
  MixInvertedColors = 0x400, ---@type render.TextureMaskFlags #Use inverted colors of a mask as a multiplier for main colors.
  AltUV = 0x10000, ---@type render.TextureMaskFlags #Use alternative UV (for projecting textures onto meshes, uses original mesh UV instead of projection UV).
}

---@alias render.AntialiasingMode
---| `render.AntialiasingMode.None` @No antialiasing.
---| `render.AntialiasingMode.FXAA` @Blurry and slower than CMAA.
---| `render.AntialiasingMode.CMAA` @Faster and sharper option comparing to FXAA.
---| `render.AntialiasingMode.ExtraSharpCMAA` @Like CMAA, but even sharper.
---| `render.AntialiasingMode.YEBIS` @Applies YEBIS antialiasing together with the whole filtering HDR→LDR conversion using main PP settings. Note: first run for each resolution can take a lot of time. Each resolution creates its own YEBIS post-processing step, with many different resolutions things might get too expensive.
render.AntialiasingMode = {
  None = 0, ---@type render.AntialiasingMode #No antialiasing.
  FXAA = 101, ---@type render.AntialiasingMode #Blurry and slower than CMAA.
  CMAA = 102, ---@type render.AntialiasingMode #Faster and sharper option comparing to FXAA.
  ExtraSharpCMAA = 103, ---@type render.AntialiasingMode #Like CMAA, but even sharper.
  YEBIS = 104, ---@type render.AntialiasingMode #Applies YEBIS antialiasing together with the whole filtering HDR→LDR conversion using main PP settings. Note: first run for each resolution can take a lot of time. Each resolution creates its own YEBIS post-processing step, with many different resolutions things might get too expensive.
}

---@alias render.TextureFormat
---| `render.TextureFormat.R32G32B32A32.Float` @Value: '2'.
---| `render.TextureFormat.R32G32B32A32.UInt` @Value: '3'.
---| `render.TextureFormat.R32G32B32A32.SInt` @Value: '4'.
---| `render.TextureFormat.R32G32B32.Float` @Value: '6'.
---| `render.TextureFormat.R32G32B32.UInt` @Value: '7'.
---| `render.TextureFormat.R32G32B32.SInt` @Value: '8'.
---| `render.TextureFormat.R32G32.Float` @Value: '16'.
---| `render.TextureFormat.R32G32.UInt` @Value: '17'.
---| `render.TextureFormat.R32G32.SInt` @Value: '18'.
---| `render.TextureFormat.R32.Float` @Value: '41'.
---| `render.TextureFormat.R32.UInt` @Value: '42'.
---| `render.TextureFormat.R32.SInt` @Value: '43'.
---| `render.TextureFormat.R16G16B16A16.Float` @Value: '10'.
---| `render.TextureFormat.R16G16B16A16.UNorm` @Value: '11'.
---| `render.TextureFormat.R16G16B16A16.UInt` @Value: '12'.
---| `render.TextureFormat.R16G16B16A16.SNorm` @Value: '13'.
---| `render.TextureFormat.R16G16B16A16.SInt` @Value: '14'.
---| `render.TextureFormat.R16G16.Float` @Value: '34'.
---| `render.TextureFormat.R16G16.UNorm` @Value: '35'.
---| `render.TextureFormat.R16G16.UInt` @Value: '36'.
---| `render.TextureFormat.R16G16.SNorm` @Value: '37'.
---| `render.TextureFormat.R16G16.SInt` @Value: '38'.
---| `render.TextureFormat.R16.Float` @Value: '54'.
---| `render.TextureFormat.R16.UNorm` @Value: '56'.
---| `render.TextureFormat.R16.UInt` @Value: '57'.
---| `render.TextureFormat.R16.SNorm` @Value: '58'.
---| `render.TextureFormat.R16.SInt` @Value: '59'.
---| `render.TextureFormat.R10G10B10A2.UNorm` @Value: '24'.
---| `render.TextureFormat.R10G10B10A2.UInt` @Value: '25'.
---| `render.TextureFormat.R11G11B10.Float` @Value: '26'.
---| `render.TextureFormat.R8G8B8A8.UNorm` @Value: '28'.
---| `render.TextureFormat.R8G8B8A8.UInt` @Value: '30'.
---| `render.TextureFormat.R8G8B8A8.SNorm` @Value: '31'.
---| `render.TextureFormat.R8G8B8A8.SInt` @Value: '32'.
---| `render.TextureFormat.R8G8.UNorm` @Value: '49'.
---| `render.TextureFormat.R8G8.UInt` @Value: '50'.
---| `render.TextureFormat.R8G8.SNorm` @Value: '51'.
---| `render.TextureFormat.R8G8.SInt` @Value: '52'.
---| `render.TextureFormat.R8.UNorm` @Value: '61'.
---| `render.TextureFormat.R8.UInt` @Value: '62'.
---| `render.TextureFormat.R8.SNorm` @Value: '63'.
---| `render.TextureFormat.R8.SInt` @Value: '64'.
---| `render.TextureFormat.R1.UNorm` @Value: '66'.
render.TextureFormat = {
  R32G32B32A32 = {Float = 2,UInt = 3,SInt = 4}, ---Value: {Float = 2,UInt = 3,SInt = 4}.
  R32G32B32 = {Float = 6,UInt = 7,SInt = 8}, ---Value: {Float = 6,UInt = 7,SInt = 8}.
  R32G32 = {Float = 16,UInt = 17,SInt = 18}, ---Value: {Float = 16,UInt = 17,SInt = 18}.
  R32 = {Float = 41,UInt = 42,SInt = 43}, ---Value: {Float = 41,UInt = 42,SInt = 43}.
  R16G16B16A16 = {Float = 10,UNorm = 11,UInt = 12,SNorm = 13,SInt = 14}, ---Value: {Float = 10,UNorm = 11,UInt = 12,SNorm = 13,SInt = 14}.
  R16G16 = {Float = 34,UNorm = 35,UInt = 36,SNorm = 37,SInt = 38}, ---Value: {Float = 34,UNorm = 35,UInt = 36,SNorm = 37,SInt = 38}.
  R16 = {Float = 54,UNorm = 56,UInt = 57,SNorm = 58,SInt = 59}, ---Value: {Float = 54,UNorm = 56,UInt = 57,SNorm = 58,SInt = 59}.
  R10G10B10A2 = {UNorm = 24,UInt = 25}, ---Value: {UNorm = 24,UInt = 25}.
  R11G11B10 = {Float = 26}, ---Value: {Float = 26}.
  R8G8B8A8 = {UNorm = 28,UInt = 30,SNorm = 31,SInt = 32}, ---Value: {UNorm = 28,UInt = 30,SNorm = 31,SInt = 32}.
  R8G8 = {UNorm = 49,UInt = 50,SNorm = 51,SInt = 52}, ---Value: {UNorm = 49,UInt = 50,SNorm = 51,SInt = 52}.
  R8 = {UNorm = 61,UInt = 62,SNorm = 63,SInt = 64}, ---Value: {UNorm = 61,UInt = 62,SNorm = 63,SInt = 64}.
  R1 = {UNorm = 66}, ---Value: {UNorm = 66}.
}

---@alias render.TextureFlags
---| `render.TextureFlags.None` @Value: 0.
---| `render.TextureFlags.Shared` @Shared texture (D3D11_RESOURCE_MISC_SHARED).
render.TextureFlags = {
  None = 0, ---@type render.TextureFlags #Value: 0.
  Shared = 1, ---@type render.TextureFlags #Shared texture (D3D11_RESOURCE_MISC_SHARED).
}

---@alias ui.ImageFit
---| `ui.ImageFit.Stretch` @Do not preserve aspect ratio (a bit faster too).
---| `ui.ImageFit.Fill` @Preserve aspect ratio, stretch image to fill out the area.
---| `ui.ImageFit.Fit` @Preserve aspect ratio, shrink image leaving blank areas.
ui.ImageFit = {
  Stretch = 0, ---@type ui.ImageFit #Do not preserve aspect ratio (a bit faster too).
  Fill = 1, ---@type ui.ImageFit #Preserve aspect ratio, stretch image to fill out the area.
  Fit = 2, ---@type ui.ImageFit #Preserve aspect ratio, shrink image leaving blank areas.
}

---@alias ui.CornerFlags
---| `ui.CornerFlags.None` @Value: 0.
---| `ui.CornerFlags.TopLeft` @Value: 1.
---| `ui.CornerFlags.TopRight` @Value: 2.
---| `ui.CornerFlags.BottomLeft` @Value: 4.
---| `ui.CornerFlags.BottomRight` @Value: 8.
---| `ui.CornerFlags.Top` @Value: 3.
---| `ui.CornerFlags.Bottom` @Value: 12.
---| `ui.CornerFlags.Left` @Value: 5.
---| `ui.CornerFlags.Right` @Value: 10.
---| `ui.CornerFlags.All` @Value: 15.
ui.CornerFlags = {
  None = 0, ---@type ui.CornerFlags #Value: 0.
  TopLeft = 1, ---@type ui.CornerFlags #Value: 1.
  TopRight = 2, ---@type ui.CornerFlags #Value: 2.
  BottomLeft = 4, ---@type ui.CornerFlags #Value: 4.
  BottomRight = 8, ---@type ui.CornerFlags #Value: 8.
  Top = 3, ---@type ui.CornerFlags #Value: 3.
  Bottom = 12, ---@type ui.CornerFlags #Value: 12.
  Left = 5, ---@type ui.CornerFlags #Value: 5.
  Right = 10, ---@type ui.CornerFlags #Value: 10.
  All = 15, ---@type ui.CornerFlags #Value: 15.
}

---@alias ui.Direction
---| `ui.Direction.None` @Value: -1.
---| `ui.Direction.Left` @Value: 0.
---| `ui.Direction.Right` @Value: 1.
---| `ui.Direction.Up` @Value: 2.
---| `ui.Direction.Down` @Value: 3.
ui.Direction = {
  None = -1, ---@type ui.Direction #Value: -1.
  Left = 0, ---@type ui.Direction #Value: 0.
  Right = 1, ---@type ui.Direction #Value: 1.
  Up = 2, ---@type ui.Direction #Value: 2.
  Down = 3, ---@type ui.Direction #Value: 3.
}

---@alias ui.HoveredFlags
---| `ui.HoveredFlags.None` @Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
---| `ui.HoveredFlags.ChildWindows` @`ac.windowHovered()` only: Return true if any children of the window is hovered.
---| `ui.HoveredFlags.RootWindow` @`ac.windowHovered()` only: Test from root window (top most parent of the current hierarchy).
---| `ui.HoveredFlags.AnyWindow` @`ac.windowHovered()` only: Return true if any window is hovered.
---| `ui.HoveredFlags.AllowWhenBlockedByPopup` @Return true even if a popup window is normally blocking access to this item/window.
---| `ui.HoveredFlags.AllowWhenBlockedByActiveItem` @Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
---| `ui.HoveredFlags.AllowWhenOverlapped` @Return true even if the position is obstructed or overlapped by another window.
---| `ui.HoveredFlags.AllowWhenDisabled` @Return true even if the item is disabled.
---| `ui.HoveredFlags.RectOnly` @Combination of flags: AllowWhenBlockedByPopup | AllowWhenBlockedByActiveItem | AllowWhenOverlapped (use `bit.bor(ui.HoveredFlags.RectOnly, …)` to combine it with other flags safely).
---| `ui.HoveredFlags.RootAndChildWindows` @Combination of flags: RootWindow | ChildWindows (use `bit.bor(ui.HoveredFlags.RootAndChildWindows, …)` to combine it with other flags safely).
ui.HoveredFlags = {
  None = 0, ---@type ui.HoveredFlags #Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
  ChildWindows = 1, ---@type ui.HoveredFlags #`ac.windowHovered()` only: Return true if any children of the window is hovered.
  RootWindow = 2, ---@type ui.HoveredFlags #`ac.windowHovered()` only: Test from root window (top most parent of the current hierarchy).
  AnyWindow = 4, ---@type ui.HoveredFlags #`ac.windowHovered()` only: Return true if any window is hovered.
  AllowWhenBlockedByPopup = 8, ---@type ui.HoveredFlags #Return true even if a popup window is normally blocking access to this item/window.
  AllowWhenBlockedByActiveItem = 32, ---@type ui.HoveredFlags #Return true even if an active item is blocking access to this item/window. Useful for Drag and Drop patterns.
  AllowWhenOverlapped = 64, ---@type ui.HoveredFlags #Return true even if the position is obstructed or overlapped by another window.
  AllowWhenDisabled = 128, ---@type ui.HoveredFlags #Return true even if the item is disabled.
  RectOnly = 104, ---@type ui.HoveredFlags #Combination of flags: AllowWhenBlockedByPopup|AllowWhenBlockedByActiveItem|AllowWhenOverlapped (use `bit.bor(ui.HoveredFlags.RectOnly, …)` to combine it with other flags safely).
  RootAndChildWindows = 3, ---@type ui.HoveredFlags #Combination of flags: RootWindow|ChildWindows (use `bit.bor(ui.HoveredFlags.RootAndChildWindows, …)` to combine it with other flags safely).
}

---@alias ui.FocusedFlags
---| `ui.FocusedFlags.None` @Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
---| `ui.FocusedFlags.ChildWindows` @`ac.windowFocused()` only: Return true if any children of the window is hovered.
---| `ui.FocusedFlags.RootWindow` @`ac.windowFocused()` only: Test from root window (top most parent of the current hierarchy).
---| `ui.FocusedFlags.AnyWindow` @`ac.windowFocused()` only: Return true if any window is hovered.
---| `ui.FocusedFlags.RootAndChildWindows` @Combination of flags: RootWindow | ChildWindows (use `bit.bor(ui.FocusedFlags.RootAndChildWindows, …)` to combine it with other flags safely).
ui.FocusedFlags = {
  None = 0, ---@type ui.FocusedFlags #Return true if directly over the item/window, not obstructed by another window, not obstructed by an active popup or modal blocking inputs under them.
  ChildWindows = 1, ---@type ui.FocusedFlags #`ac.windowFocused()` only: Return true if any children of the window is hovered.
  RootWindow = 2, ---@type ui.FocusedFlags #`ac.windowFocused()` only: Test from root window (top most parent of the current hierarchy).
  AnyWindow = 4, ---@type ui.FocusedFlags #`ac.windowFocused()` only: Return true if any window is hovered.
  RootAndChildWindows = 3, ---@type ui.FocusedFlags #Combination of flags: RootWindow|ChildWindows (use `bit.bor(ui.FocusedFlags.RootAndChildWindows, …)` to combine it with other flags safely).
}

---@alias ui.MouseCursor
---| `ui.MouseCursor.None` @No cursor.
---| `ui.MouseCursor.Arrow` @Default arrow.
---| `ui.MouseCursor.TextInput` @When hovering over `ui.inputText()`, etc.
---| `ui.MouseCursor.ResizeAll` @Unused by default controls.
---| `ui.MouseCursor.ResizeNS` @When hovering over an horizontal border.
---| `ui.MouseCursor.ResizeEW` @When hovering over a vertical border or a column.
---| `ui.MouseCursor.ResizeNESW` @When hovering over the bottom-left corner of a window.
---| `ui.MouseCursor.ResizeNWSE` @When hovering over the bottom-right corner of a window.
---| `ui.MouseCursor.Hand` @Unused by default controls. Use for e.g. hyperlinks.
ui.MouseCursor = {
  None = -1, ---@type ui.MouseCursor #No cursor.
  Arrow = 0, ---@type ui.MouseCursor #Default arrow.
  TextInput = 1, ---@type ui.MouseCursor #When hovering over `ui.inputText()`, etc.
  ResizeAll = 2, ---@type ui.MouseCursor #Unused by default controls.
  ResizeNS = 3, ---@type ui.MouseCursor #When hovering over an horizontal border.
  ResizeEW = 4, ---@type ui.MouseCursor #When hovering over a vertical border or a column.
  ResizeNESW = 5, ---@type ui.MouseCursor #When hovering over the bottom-left corner of a window.
  ResizeNWSE = 6, ---@type ui.MouseCursor #When hovering over the bottom-right corner of a window.
  Hand = 7, ---@type ui.MouseCursor #Unused by default controls. Use for e.g. hyperlinks.
}

---@alias ui.MouseButton
---| `ui.MouseButton.Left` @Value: 0.
---| `ui.MouseButton.Right` @Value: 1.
---| `ui.MouseButton.Middle` @Value: 2.
---| `ui.MouseButton.Extra1` @Value: 3.
---| `ui.MouseButton.Extra2` @Value: 4.
ui.MouseButton = {
  Left = 0, ---@type ui.MouseButton #Value: 0.
  Right = 1, ---@type ui.MouseButton #Value: 1.
  Middle = 2, ---@type ui.MouseButton #Value: 2.
  Extra1 = 3, ---@type ui.MouseButton #Value: 3.
  Extra2 = 4, ---@type ui.MouseButton #Value: 4.
}

---@alias ui.Font
---| `ui.Font.Small` @Value: 1.
---| `ui.Font.Tiny` @Value: 2.
---| `ui.Font.Monospace` @Value: 3.
---| `ui.Font.Main` @Value: 4.
---| `ui.Font.Italic` @Value: 5.
---| `ui.Font.Title` @Value: 6.
---| `ui.Font.Huge` @Value: 7.
---| `ui.Font.SmallItalic` @Value: 8.
ui.Font = {
  Small = 1, ---@type ui.Font #Value: 1.
  Tiny = 2, ---@type ui.Font #Value: 2.
  Monospace = 3, ---@type ui.Font #Value: 3.
  Main = 4, ---@type ui.Font #Value: 4.
  Italic = 5, ---@type ui.Font #Value: 5.
  Title = 6, ---@type ui.Font #Value: 6.
  Huge = 7, ---@type ui.Font #Value: 7.
  SmallItalic = 8, ---@type ui.Font #Value: 8.
}

---@alias ui.Alignment
---| `ui.Alignment.Start` @Value: -1.
---| `ui.Alignment.Center` @Value: 0.
---| `ui.Alignment.End` @Value: 1.
ui.Alignment = {
  Start = -1, ---@type ui.Alignment #Value: -1.
  Center = 0, ---@type ui.Alignment #Value: 0.
  End = 1, ---@type ui.Alignment #Value: 1.
}

---Special codes for keys with certain UI roles.
---@alias ui.Key
---| `ui.Key.Tab` @Value: 0.
---| `ui.Key.Left` @Value: 1.
---| `ui.Key.Right` @Value: 2.
---| `ui.Key.Up` @Value: 3.
---| `ui.Key.Down` @Value: 4.
---| `ui.Key.PageUp` @Value: 5.
---| `ui.Key.PageDown` @Value: 6.
---| `ui.Key.Home` @Value: 7.
---| `ui.Key.End` @Value: 8.
---| `ui.Key.Insert` @Value: 9.
---| `ui.Key.Delete` @Value: 10.
---| `ui.Key.Backspace` @Value: 11.
---| `ui.Key.Space` @Value: 12.
---| `ui.Key.Enter` @Value: 13.
---| `ui.Key.Escape` @Value: 14.
---| `ui.Key.KeyPadEnter` @Value: 15.
---| `ui.Key.A` @Value: 16.
---| `ui.Key.C` @Value: 17.
---| `ui.Key.D` @Value: 18.
---| `ui.Key.S` @Value: 19.
---| `ui.Key.V` @Value: 20.
---| `ui.Key.W` @Value: 21.
---| `ui.Key.X` @Value: 22.
---| `ui.Key.Y` @Value: 23.
---| `ui.Key.Z` @Value: 24.
ui.Key = {
  Tab = 0, ---@type ui.Key #Value: 0.
  Left = 1, ---@type ui.Key #Value: 1.
  Right = 2, ---@type ui.Key #Value: 2.
  Up = 3, ---@type ui.Key #Value: 3.
  Down = 4, ---@type ui.Key #Value: 4.
  PageUp = 5, ---@type ui.Key #Value: 5.
  PageDown = 6, ---@type ui.Key #Value: 6.
  Home = 7, ---@type ui.Key #Value: 7.
  End = 8, ---@type ui.Key #Value: 8.
  Insert = 9, ---@type ui.Key #Value: 9.
  Delete = 10, ---@type ui.Key #Value: 10.
  Backspace = 11, ---@type ui.Key #Value: 11.
  Space = 12, ---@type ui.Key #Value: 12.
  Enter = 13, ---@type ui.Key #Value: 13.
  Escape = 14, ---@type ui.Key #Value: 14.
  KeyPadEnter = 15, ---@type ui.Key #Value: 15.
  A = 16, ---@type ui.Key #Value: 16.
  C = 17, ---@type ui.Key #Value: 17.
  D = 18, ---@type ui.Key #Value: 18.
  S = 19, ---@type ui.Key #Value: 19.
  V = 20, ---@type ui.Key #Value: 20.
  W = 21, ---@type ui.Key #Value: 21.
  X = 22, ---@type ui.Key #Value: 22.
  Y = 23, ---@type ui.Key #Value: 23.
  Z = 24, ---@type ui.Key #Value: 24.
}

---@alias ui.StyleVar
---| `ui.StyleVar.Alpha` @Expects a number.
---| `ui.StyleVar.WindowRounding` @Expects a number.
---| `ui.StyleVar.WindowBorderSize` @Expects a number.
---| `ui.StyleVar.ChildRounding` @Expects a number.
---| `ui.StyleVar.ChildBorderSize` @Expects a number.
---| `ui.StyleVar.PopupRounding` @Expects a number.
---| `ui.StyleVar.PopupBorderSize` @Expects a number.
---| `ui.StyleVar.FrameRounding` @Expects a number.
---| `ui.StyleVar.FrameBorderSize` @Expects a number.
---| `ui.StyleVar.IndentSpacing` @Expects a number.
---| `ui.StyleVar.ScrollbarSize` @Expects a number.
---| `ui.StyleVar.ScrollbarRounding` @Expects a number.
---| `ui.StyleVar.GrabMinSize` @Expects a number.
---| `ui.StyleVar.GrabRounding` @Expects a number.
---| `ui.StyleVar.TabRounding` @Expects a number.
---| `ui.StyleVar.WindowPadding` @Expects a `vec2` value.
---| `ui.StyleVar.WindowMinSize` @Expects a `vec2` value.
---| `ui.StyleVar.WindowTitleAlign` @Expects a `vec2` value.
---| `ui.StyleVar.FramePadding` @Expects a `vec2` value.
---| `ui.StyleVar.ItemSpacing` @Expects a `vec2` value.
---| `ui.StyleVar.ItemInnerSpacing` @Expects a `vec2` value.
---| `ui.StyleVar.ButtonTextAlign` @Expects a `vec2` value.
---| `ui.StyleVar.SelectableTextAlign` @Expects a `vec2` value.
---| `ui.StyleVar.SelectablePadding` @Expects a `vec2` value.
---| `ui.StyleVar.SliderTextAlign` @Expects a `vec2` value. Added in 0.2.8.
ui.StyleVar = {
  Alpha = 0, ---@type ui.StyleVar #Expects a number.
  WindowRounding = 1, ---@type ui.StyleVar #Expects a number.
  WindowBorderSize = 2, ---@type ui.StyleVar #Expects a number.
  ChildRounding = 3, ---@type ui.StyleVar #Expects a number.
  ChildBorderSize = 4, ---@type ui.StyleVar #Expects a number.
  PopupRounding = 5, ---@type ui.StyleVar #Expects a number.
  PopupBorderSize = 6, ---@type ui.StyleVar #Expects a number.
  FrameRounding = 7, ---@type ui.StyleVar #Expects a number.
  FrameBorderSize = 8, ---@type ui.StyleVar #Expects a number.
  IndentSpacing = 9, ---@type ui.StyleVar #Expects a number.
  ScrollbarSize = 10, ---@type ui.StyleVar #Expects a number.
  ScrollbarRounding = 11, ---@type ui.StyleVar #Expects a number.
  GrabMinSize = 12, ---@type ui.StyleVar #Expects a number.
  GrabRounding = 13, ---@type ui.StyleVar #Expects a number.
  TabRounding = 14, ---@type ui.StyleVar #Expects a number.
  WindowPadding = 15, ---@type ui.StyleVar #Expects a `vec2` value.
  WindowMinSize = 16, ---@type ui.StyleVar #Expects a `vec2` value.
  WindowTitleAlign = 17, ---@type ui.StyleVar #Expects a `vec2` value.
  FramePadding = 18, ---@type ui.StyleVar #Expects a `vec2` value.
  ItemSpacing = 19, ---@type ui.StyleVar #Expects a `vec2` value.
  ItemInnerSpacing = 20, ---@type ui.StyleVar #Expects a `vec2` value.
  ButtonTextAlign = 21, ---@type ui.StyleVar #Expects a `vec2` value.
  SelectableTextAlign = 22, ---@type ui.StyleVar #Expects a `vec2` value.
  SelectablePadding = 23, ---@type ui.StyleVar #Expects a `vec2` value.
  SliderTextAlign = 24, ---@type ui.StyleVar #Expects a `vec2` value. Added in 0.2.8.
}

---@alias ui.StyleColor
---| `ui.StyleColor.Text` @Value: 0.
---| `ui.StyleColor.TextDisabled` @Value: 1.
---| `ui.StyleColor.WindowBg` @Value: 2.
---| `ui.StyleColor.ChildBg` @Value: 3.
---| `ui.StyleColor.PopupBg` @Value: 4.
---| `ui.StyleColor.Border` @Value: 5.
---| `ui.StyleColor.BorderShadow` @Value: 6.
---| `ui.StyleColor.FrameBg` @Value: 7.
---| `ui.StyleColor.FrameBgHovered` @Value: 8.
---| `ui.StyleColor.FrameBgActive` @Value: 9.
---| `ui.StyleColor.TitleBg` @Value: 10.
---| `ui.StyleColor.TitleBgActive` @Value: 11.
---| `ui.StyleColor.TitleBgCollapsed` @Value: 12.
---| `ui.StyleColor.MenuBarBg` @Value: 13.
---| `ui.StyleColor.ScrollbarBg` @Value: 14.
---| `ui.StyleColor.ScrollbarGrab` @Value: 15.
---| `ui.StyleColor.ScrollbarGrabHovered` @Value: 16.
---| `ui.StyleColor.ScrollbarGrabActive` @Value: 17.
---| `ui.StyleColor.CheckMark` @Value: 18.
---| `ui.StyleColor.SliderGrab` @Value: 19.
---| `ui.StyleColor.SliderGrabActive` @Value: 20.
---| `ui.StyleColor.Button` @Value: 21.
---| `ui.StyleColor.ButtonHovered` @Value: 22.
---| `ui.StyleColor.ButtonActive` @Value: 23.
---| `ui.StyleColor.Header` @Value: 24.
---| `ui.StyleColor.HeaderHovered` @Value: 25.
---| `ui.StyleColor.HeaderActive` @Value: 26.
---| `ui.StyleColor.Separator` @Value: 27.
---| `ui.StyleColor.SeparatorHovered` @Value: 28.
---| `ui.StyleColor.SeparatorActive` @Value: 29.
---| `ui.StyleColor.ResizeGrip` @Value: 30.
---| `ui.StyleColor.ResizeGripHovered` @Value: 31.
---| `ui.StyleColor.ResizeGripActive` @Value: 32.
---| `ui.StyleColor.Tab` @Value: 33.
---| `ui.StyleColor.TabHovered` @Value: 34.
---| `ui.StyleColor.TabActive` @Value: 35.
---| `ui.StyleColor.TabUnfocused` @Value: 36.
---| `ui.StyleColor.TabUnfocusedActive` @Value: 37.
---| `ui.StyleColor.PlotLines` @Value: 38.
---| `ui.StyleColor.PlotLinesHovered` @Value: 39.
---| `ui.StyleColor.PlotHistogram` @Value: 40.
---| `ui.StyleColor.PlotHistogramHovered` @Value: 41.
---| `ui.StyleColor.TextSelectedBg` @Value: 42.
---| `ui.StyleColor.DragDropTarget` @Value: 43.
---| `ui.StyleColor.NavHighlight` @Value: 44.
---| `ui.StyleColor.NavWindowingHighlight` @Value: 45.
---| `ui.StyleColor.NavWindowingDimBg` @Value: 46.
---| `ui.StyleColor.ModalWindowDimBg` @Value: 47.
---| `ui.StyleColor.TextHovered` @Value: 48.
---| `ui.StyleColor.TextActive` @Value: 49.
ui.StyleColor = {
  Text = 0, ---@type ui.StyleColor #Value: 0.
  TextDisabled = 1, ---@type ui.StyleColor #Value: 1.
  WindowBg = 2, ---@type ui.StyleColor #Value: 2.
  ChildBg = 3, ---@type ui.StyleColor #Value: 3.
  PopupBg = 4, ---@type ui.StyleColor #Value: 4.
  Border = 5, ---@type ui.StyleColor #Value: 5.
  BorderShadow = 6, ---@type ui.StyleColor #Value: 6.
  FrameBg = 7, ---@type ui.StyleColor #Value: 7.
  FrameBgHovered = 8, ---@type ui.StyleColor #Value: 8.
  FrameBgActive = 9, ---@type ui.StyleColor #Value: 9.
  TitleBg = 10, ---@type ui.StyleColor #Value: 10.
  TitleBgActive = 11, ---@type ui.StyleColor #Value: 11.
  TitleBgCollapsed = 12, ---@type ui.StyleColor #Value: 12.
  MenuBarBg = 13, ---@type ui.StyleColor #Value: 13.
  ScrollbarBg = 14, ---@type ui.StyleColor #Value: 14.
  ScrollbarGrab = 15, ---@type ui.StyleColor #Value: 15.
  ScrollbarGrabHovered = 16, ---@type ui.StyleColor #Value: 16.
  ScrollbarGrabActive = 17, ---@type ui.StyleColor #Value: 17.
  CheckMark = 18, ---@type ui.StyleColor #Value: 18.
  SliderGrab = 19, ---@type ui.StyleColor #Value: 19.
  SliderGrabActive = 20, ---@type ui.StyleColor #Value: 20.
  Button = 21, ---@type ui.StyleColor #Value: 21.
  ButtonHovered = 22, ---@type ui.StyleColor #Value: 22.
  ButtonActive = 23, ---@type ui.StyleColor #Value: 23.
  Header = 24, ---@type ui.StyleColor #Value: 24.
  HeaderHovered = 25, ---@type ui.StyleColor #Value: 25.
  HeaderActive = 26, ---@type ui.StyleColor #Value: 26.
  Separator = 27, ---@type ui.StyleColor #Value: 27.
  SeparatorHovered = 28, ---@type ui.StyleColor #Value: 28.
  SeparatorActive = 29, ---@type ui.StyleColor #Value: 29.
  ResizeGrip = 30, ---@type ui.StyleColor #Value: 30.
  ResizeGripHovered = 31, ---@type ui.StyleColor #Value: 31.
  ResizeGripActive = 32, ---@type ui.StyleColor #Value: 32.
  Tab = 33, ---@type ui.StyleColor #Value: 33.
  TabHovered = 34, ---@type ui.StyleColor #Value: 34.
  TabActive = 35, ---@type ui.StyleColor #Value: 35.
  TabUnfocused = 36, ---@type ui.StyleColor #Value: 36.
  TabUnfocusedActive = 37, ---@type ui.StyleColor #Value: 37.
  PlotLines = 38, ---@type ui.StyleColor #Value: 38.
  PlotLinesHovered = 39, ---@type ui.StyleColor #Value: 39.
  PlotHistogram = 40, ---@type ui.StyleColor #Value: 40.
  PlotHistogramHovered = 41, ---@type ui.StyleColor #Value: 41.
  TextSelectedBg = 42, ---@type ui.StyleColor #Value: 42.
  DragDropTarget = 43, ---@type ui.StyleColor #Value: 43.
  NavHighlight = 44, ---@type ui.StyleColor #Value: 44.
  NavWindowingHighlight = 45, ---@type ui.StyleColor #Value: 45.
  NavWindowingDimBg = 46, ---@type ui.StyleColor #Value: 46.
  ModalWindowDimBg = 47, ---@type ui.StyleColor #Value: 47.
  TextHovered = 48, ---@type ui.StyleColor #Value: 48.
  TextActive = 49, ---@type ui.StyleColor #Value: 49.
}

---@alias ui.Icons
---| `ui.Icons.LoadingSpinner` @Value: 'fx:loading'.
---| `ui.Icons.AppWindow` @![Icon](https://acstuff.ru/images/icons_24/app_window.png)
---| `ui.Icons.Apps` @![Icon](https://acstuff.ru/images/icons_24/apps.png)
---| `ui.Icons.ArrowDown` @![Icon](https://acstuff.ru/images/icons_24/arrow_down.png)
---| `ui.Icons.ArrowLeft` @![Icon](https://acstuff.ru/images/icons_24/arrow_left.png)
---| `ui.Icons.ArrowRight` @![Icon](https://acstuff.ru/images/icons_24/arrow_right.png)
---| `ui.Icons.ArrowUp` @![Icon](https://acstuff.ru/images/icons_24/arrow_up.png)
---| `ui.Icons.Attention` @![Icon](https://acstuff.ru/images/icons_24/attention.png)
---| `ui.Icons.Avatar` @![Icon](https://acstuff.ru/images/icons_24/avatar.png)
---| `ui.Icons.Back` @![Icon](https://acstuff.ru/images/icons_24/back.png)
---| `ui.Icons.Backspace` @![Icon](https://acstuff.ru/images/icons_24/backspace.png)
---| `ui.Icons.Ballast` @![Icon](https://acstuff.ru/images/icons_24/ballast.png)
---| `ui.Icons.Ban` @![Icon](https://acstuff.ru/images/icons_24/ban.png)
---| `ui.Icons.Barcode` @![Icon](https://acstuff.ru/images/icons_24/barcode.png)
---| `ui.Icons.Bars` @![Icon](https://acstuff.ru/images/icons_24/bars.png)
---| `ui.Icons.BatteryEmpty` @![Icon](https://acstuff.ru/images/icons_24/battery_empty.png)
---| `ui.Icons.BatteryFull` @![Icon](https://acstuff.ru/images/icons_24/battery_full.png)
---| `ui.Icons.Befriend` @![Icon](https://acstuff.ru/images/icons_24/befriend.png)
---| `ui.Icons.Bell` @![Icon](https://acstuff.ru/images/icons_24/bell.png)
---| `ui.Icons.Binocoulars` @![Icon](https://acstuff.ru/images/icons_24/binocoulars.png)
---| `ui.Icons.Blackboard` @![Icon](https://acstuff.ru/images/icons_24/blackboard.png)
---| `ui.Icons.Bluetooth` @![Icon](https://acstuff.ru/images/icons_24/bluetooth.png)
---| `ui.Icons.Bomb` @![Icon](https://acstuff.ru/images/icons_24/bomb.png)
---| `ui.Icons.Book` @![Icon](https://acstuff.ru/images/icons_24/book.png)
---| `ui.Icons.Bookmark` @![Icon](https://acstuff.ru/images/icons_24/bookmark.png)
---| `ui.Icons.Box` @![Icon](https://acstuff.ru/images/icons_24/box.png)
---| `ui.Icons.Briefcase` @![Icon](https://acstuff.ru/images/icons_24/briefcase.png)
---| `ui.Icons.Bug` @![Icon](https://acstuff.ru/images/icons_24/bug.png)
---| `ui.Icons.Bulb` @![Icon](https://acstuff.ru/images/icons_24/bulb.png)
---| `ui.Icons.Burn` @![Icon](https://acstuff.ru/images/icons_24/burn.png)
---| `ui.Icons.Calculator` @![Icon](https://acstuff.ru/images/icons_24/calculator.png)
---| `ui.Icons.Calendar` @![Icon](https://acstuff.ru/images/icons_24/calendar.png)
---| `ui.Icons.CallBluetooth` @![Icon](https://acstuff.ru/images/icons_24/call_bluetooth.png)
---| `ui.Icons.Call` @![Icon](https://acstuff.ru/images/icons_24/call.png)
---| `ui.Icons.Camera` @![Icon](https://acstuff.ru/images/icons_24/camera.png)
---| `ui.Icons.Cancel` @![Icon](https://acstuff.ru/images/icons_24/cancel.png)
---| `ui.Icons.CarFront` @![Icon](https://acstuff.ru/images/icons_24/car_front.png)
---| `ui.Icons.Cards` @![Icon](https://acstuff.ru/images/icons_24/cards.png)
---| `ui.Icons.Cctv` @![Icon](https://acstuff.ru/images/icons_24/cctv.png)
---| `ui.Icons.Cellphone` @![Icon](https://acstuff.ru/images/icons_24/cellphone.png)
---| `ui.Icons.Chat` @![Icon](https://acstuff.ru/images/icons_24/chat.png)
---| `ui.Icons.Clapperboard` @![Icon](https://acstuff.ru/images/icons_24/clapperboard.png)
---| `ui.Icons.Clip` @![Icon](https://acstuff.ru/images/icons_24/clip.png)
---| `ui.Icons.Clipboard` @![Icon](https://acstuff.ru/images/icons_24/clipboard.png)
---| `ui.Icons.Clock` @![Icon](https://acstuff.ru/images/icons_24/clock.png)
---| `ui.Icons.Cloud` @![Icon](https://acstuff.ru/images/icons_24/cloud.png)
---| `ui.Icons.Code` @![Icon](https://acstuff.ru/images/icons_24/code.png)
---| `ui.Icons.Coffee` @![Icon](https://acstuff.ru/images/icons_24/coffee.png)
---| `ui.Icons.CompassAlt` @![Icon](https://acstuff.ru/images/icons_24/compass_alt.png)
---| `ui.Icons.Compass` @![Icon](https://acstuff.ru/images/icons_24/compass.png)
---| `ui.Icons.Confirm` @![Icon](https://acstuff.ru/images/icons_24/confirm.png)
---| `ui.Icons.Constellation` @![Icon](https://acstuff.ru/images/icons_24/constellation.png)
---| `ui.Icons.Contacts` @![Icon](https://acstuff.ru/images/icons_24/contacts.png)
---| `ui.Icons.Contrast` @![Icon](https://acstuff.ru/images/icons_24/contrast.png)
---| `ui.Icons.Copy` @![Icon](https://acstuff.ru/images/icons_24/copy.png)
---| `ui.Icons.CreditCard` @![Icon](https://acstuff.ru/images/icons_24/credit_card.png)
---| `ui.Icons.Crop` @![Icon](https://acstuff.ru/images/icons_24/crop.png)
---| `ui.Icons.Crosshair` @![Icon](https://acstuff.ru/images/icons_24/crosshair.png)
---| `ui.Icons.Delete` @![Icon](https://acstuff.ru/images/icons_24/delete.png)
---| `ui.Icons.Dice` @![Icon](https://acstuff.ru/images/icons_24/dice.png)
---| `ui.Icons.Directions` @![Icon](https://acstuff.ru/images/icons_24/directions.png)
---| `ui.Icons.Document` @![Icon](https://acstuff.ru/images/icons_24/document.png)
---| `ui.Icons.DollarBill` @![Icon](https://acstuff.ru/images/icons_24/dollar_bill.png)
---| `ui.Icons.DownAlt` @![Icon](https://acstuff.ru/images/icons_24/down_alt.png)
---| `ui.Icons.Down` @![Icon](https://acstuff.ru/images/icons_24/down.png)
---| `ui.Icons.Download` @![Icon](https://acstuff.ru/images/icons_24/download.png)
---| `ui.Icons.Driver` @![Icon](https://acstuff.ru/images/icons_24/driver.png)
---| `ui.Icons.Earth` @![Icon](https://acstuff.ru/images/icons_24/earth.png)
---| `ui.Icons.Edit` @![Icon](https://acstuff.ru/images/icons_24/edit.png)
---| `ui.Icons.Eject` @![Icon](https://acstuff.ru/images/icons_24/eject.png)
---| `ui.Icons.Ellipsis` @![Icon](https://acstuff.ru/images/icons_24/ellipsis.png)
---| `ui.Icons.Enter` @![Icon](https://acstuff.ru/images/icons_24/enter.png)
---| `ui.Icons.Envelope` @![Icon](https://acstuff.ru/images/icons_24/envelope.png)
---| `ui.Icons.Exit` @![Icon](https://acstuff.ru/images/icons_24/exit.png)
---| `ui.Icons.Eye` @![Icon](https://acstuff.ru/images/icons_24/eye.png)
---| `ui.Icons.FastForward` @![Icon](https://acstuff.ru/images/icons_24/fast_forward.png)
---| `ui.Icons.File` @![Icon](https://acstuff.ru/images/icons_24/file.png)
---| `ui.Icons.FilmRoll` @![Icon](https://acstuff.ru/images/icons_24/film_roll.png)
---| `ui.Icons.Film` @![Icon](https://acstuff.ru/images/icons_24/film.png)
---| `ui.Icons.Finish` @![Icon](https://acstuff.ru/images/icons_24/finish.png)
---| `ui.Icons.FireExtinguisher` @![Icon](https://acstuff.ru/images/icons_24/fire_extinguisher.png)
---| `ui.Icons.Fireplace` @![Icon](https://acstuff.ru/images/icons_24/fireplace.png)
---| `ui.Icons.FlagAlt` @![Icon](https://acstuff.ru/images/icons_24/flag_alt.png)
---| `ui.Icons.Flag` @![Icon](https://acstuff.ru/images/icons_24/flag.png)
---| `ui.Icons.FM` @![Icon](https://acstuff.ru/images/icons_24/fm.png)
---| `ui.Icons.Folder` @![Icon](https://acstuff.ru/images/icons_24/folder.png)
---| `ui.Icons.Font` @![Icon](https://acstuff.ru/images/icons_24/font.png)
---| `ui.Icons.Fuel` @![Icon](https://acstuff.ru/images/icons_24/fuel.png)
---| `ui.Icons.Fullscreen` @![Icon](https://acstuff.ru/images/icons_24/fullscreen.png)
---| `ui.Icons.Gamepad` @![Icon](https://acstuff.ru/images/icons_24/gamepad.png)
---| `ui.Icons.Global` @![Icon](https://acstuff.ru/images/icons_24/global.png)
---| `ui.Icons.GlowThick` @![Icon](https://acstuff.ru/images/icons_24/glow_thick.png)
---| `ui.Icons.Glow` @![Icon](https://acstuff.ru/images/icons_24/glow.png)
---| `ui.Icons.GPS` @![Icon](https://acstuff.ru/images/icons_24/gps.png)
---| `ui.Icons.Group` @![Icon](https://acstuff.ru/images/icons_24/group.png)
---| `ui.Icons.HammerAlt` @![Icon](https://acstuff.ru/images/icons_24/hammer_alt.png)
---| `ui.Icons.Hammer` @![Icon](https://acstuff.ru/images/icons_24/hammer.png)
---| `ui.Icons.Hazard` @![Icon](https://acstuff.ru/images/icons_24/hazard.png)
---| `ui.Icons.Headphones` @![Icon](https://acstuff.ru/images/icons_24/headphones.png)
---| `ui.Icons.HeartOutline` @![Icon](https://acstuff.ru/images/icons_24/heart_outline.png)
---| `ui.Icons.Heart` @![Icon](https://acstuff.ru/images/icons_24/heart.png)
---| `ui.Icons.Helmet` @![Icon](https://acstuff.ru/images/icons_24/helmet.png)
---| `ui.Icons.Hide` @![Icon](https://acstuff.ru/images/icons_24/hide.png)
---| `ui.Icons.Home` @![Icon](https://acstuff.ru/images/icons_24/home.png)
---| `ui.Icons.Horizontal` @![Icon](https://acstuff.ru/images/icons_24/horizontal.png)
---| `ui.Icons.Hourglass` @![Icon](https://acstuff.ru/images/icons_24/hourglass.png)
---| `ui.Icons.InboxEmpty` @![Icon](https://acstuff.ru/images/icons_24/inbox_empty.png)
---| `ui.Icons.InboxFull` @![Icon](https://acstuff.ru/images/icons_24/inbox_full.png)
---| `ui.Icons.Info` @![Icon](https://acstuff.ru/images/icons_24/info.png)
---| `ui.Icons.Key` @![Icon](https://acstuff.ru/images/icons_24/key.png)
---| `ui.Icons.Keyboard` @![Icon](https://acstuff.ru/images/icons_24/keyboard.png)
---| `ui.Icons.Kick` @![Icon](https://acstuff.ru/images/icons_24/kick.png)
---| `ui.Icons.Landscape` @![Icon](https://acstuff.ru/images/icons_24/landscape.png)
---| `ui.Icons.Laptop` @![Icon](https://acstuff.ru/images/icons_24/laptop.png)
---| `ui.Icons.Leaderboard` @![Icon](https://acstuff.ru/images/icons_24/leaderboard.png)
---| `ui.Icons.Leave` @![Icon](https://acstuff.ru/images/icons_24/leave.png)
---| `ui.Icons.Lens` @![Icon](https://acstuff.ru/images/icons_24/lens.png)
---| `ui.Icons.Levels` @![Icon](https://acstuff.ru/images/icons_24/levels.png)
---| `ui.Icons.LinkBroken` @![Icon](https://acstuff.ru/images/icons_24/link_broken.png)
---| `ui.Icons.Link` @![Icon](https://acstuff.ru/images/icons_24/link.png)
---| `ui.Icons.ListAlt` @![Icon](https://acstuff.ru/images/icons_24/list_alt.png)
---| `ui.Icons.List` @![Icon](https://acstuff.ru/images/icons_24/list.png)
---| `ui.Icons.Loading` @![Icon](https://acstuff.ru/images/icons_24/loading.png)
---| `ui.Icons.Location` @![Icon](https://acstuff.ru/images/icons_24/location.png)
---| `ui.Icons.Lua` @![Icon](https://acstuff.ru/images/icons_24/lua.png)
---| `ui.Icons.Magnet` @![Icon](https://acstuff.ru/images/icons_24/magnet.png)
---| `ui.Icons.Map` @![Icon](https://acstuff.ru/images/icons_24/map.png)
---| `ui.Icons.Maximize` @![Icon](https://acstuff.ru/images/icons_24/maximize.png)
---| `ui.Icons.Menu` @![Icon](https://acstuff.ru/images/icons_24/menu.png)
---| `ui.Icons.MicrophoneMuted` @![Icon](https://acstuff.ru/images/icons_24/microphone_muted.png)
---| `ui.Icons.Microphone` @![Icon](https://acstuff.ru/images/icons_24/microphone.png)
---| `ui.Icons.Minus` @![Icon](https://acstuff.ru/images/icons_24/minus.png)
---| `ui.Icons.Monitor` @![Icon](https://acstuff.ru/images/icons_24/monitor.png)
---| `ui.Icons.Moon` @![Icon](https://acstuff.ru/images/icons_24/moon.png)
---| `ui.Icons.Mouse` @![Icon](https://acstuff.ru/images/icons_24/mouse.png)
---| `ui.Icons.Music` @![Icon](https://acstuff.ru/images/icons_24/music.png)
---| `ui.Icons.Mute` @![Icon](https://acstuff.ru/images/icons_24/mute.png)
---| `ui.Icons.Navigation` @![Icon](https://acstuff.ru/images/icons_24/navigation.png)
---| `ui.Icons.New` @![Icon](https://acstuff.ru/images/icons_24/new.png)
---| `ui.Icons.Next` @![Icon](https://acstuff.ru/images/icons_24/next.png)
---| `ui.Icons.NotificationsAny` @![Icon](https://acstuff.ru/images/icons_24/notifications_any.png)
---| `ui.Icons.Notifications` @![Icon](https://acstuff.ru/images/icons_24/notifications.png)
---| `ui.Icons.PadlockUnlocked` @![Icon](https://acstuff.ru/images/icons_24/padlock_unlocked.png)
---| `ui.Icons.Padlock` @![Icon](https://acstuff.ru/images/icons_24/padlock.png)
---| `ui.Icons.Palette` @![Icon](https://acstuff.ru/images/icons_24/palette.png)
---| `ui.Icons.Paperclip` @![Icon](https://acstuff.ru/images/icons_24/paperclip.png)
---| `ui.Icons.Paste` @![Icon](https://acstuff.ru/images/icons_24/paste.png)
---| `ui.Icons.Pause` @![Icon](https://acstuff.ru/images/icons_24/pause.png)
---| `ui.Icons.Pedals` @![Icon](https://acstuff.ru/images/icons_24/pedals.png)
---| `ui.Icons.Person` @![Icon](https://acstuff.ru/images/icons_24/person.png)
---| `ui.Icons.Photograph` @![Icon](https://acstuff.ru/images/icons_24/photograph.png)
---| `ui.Icons.Pin` @![Icon](https://acstuff.ru/images/icons_24/pin.png)
---| `ui.Icons.PitStopAlt` @![Icon](https://acstuff.ru/images/icons_24/pit_stop_alt.png)
---| `ui.Icons.PitStop` @![Icon](https://acstuff.ru/images/icons_24/pit_stop.png)
---| `ui.Icons.Pitlane` @![Icon](https://acstuff.ru/images/icons_24/pitlane.png)
---| `ui.Icons.Plane` @![Icon](https://acstuff.ru/images/icons_24/plane.png)
---| `ui.Icons.Play` @![Icon](https://acstuff.ru/images/icons_24/play.png)
---| `ui.Icons.Plug` @![Icon](https://acstuff.ru/images/icons_24/plug.png)
---| `ui.Icons.Plus` @![Icon](https://acstuff.ru/images/icons_24/plus.png)
---| `ui.Icons.Preview` @![Icon](https://acstuff.ru/images/icons_24/preview.png)
---| `ui.Icons.Previous` @![Icon](https://acstuff.ru/images/icons_24/previous.png)
---| `ui.Icons.Print` @![Icon](https://acstuff.ru/images/icons_24/print.png)
---| `ui.Icons.Process` @![Icon](https://acstuff.ru/images/icons_24/process.png)
---| `ui.Icons.Puzzle` @![Icon](https://acstuff.ru/images/icons_24/puzzle.png)
---| `ui.Icons.Python` @![Icon](https://acstuff.ru/images/icons_24/python.png)
---| `ui.Icons.QR` @![Icon](https://acstuff.ru/images/icons_24/qr.png)
---| `ui.Icons.QuestionSign` @![Icon](https://acstuff.ru/images/icons_24/question_sign.png)
---| `ui.Icons.Question` @![Icon](https://acstuff.ru/images/icons_24/question.png)
---| `ui.Icons.Radio` @![Icon](https://acstuff.ru/images/icons_24/radio.png)
---| `ui.Icons.Recognition` @![Icon](https://acstuff.ru/images/icons_24/recognition.png)
---| `ui.Icons.Record` @![Icon](https://acstuff.ru/images/icons_24/record.png)
---| `ui.Icons.Redo` @![Icon](https://acstuff.ru/images/icons_24/redo.png)
---| `ui.Icons.Referee` @![Icon](https://acstuff.ru/images/icons_24/referee.png)
---| `ui.Icons.Repair` @![Icon](https://acstuff.ru/images/icons_24/repair.png)
---| `ui.Icons.Reset` @![Icon](https://acstuff.ru/images/icons_24/reset.png)
---| `ui.Icons.RestartWarning` @![Icon](https://acstuff.ru/images/icons_24/restart_warning.png)
---| `ui.Icons.Restart` @![Icon](https://acstuff.ru/images/icons_24/restart.png)
---| `ui.Icons.Restrictor` @![Icon](https://acstuff.ru/images/icons_24/restrictor.png)
---| `ui.Icons.Resume` @![Icon](https://acstuff.ru/images/icons_24/resume.png)
---| `ui.Icons.Rewind` @![Icon](https://acstuff.ru/images/icons_24/rewind.png)
---| `ui.Icons.Road` @![Icon](https://acstuff.ru/images/icons_24/road.png)
---| `ui.Icons.Rubber` @![Icon](https://acstuff.ru/images/icons_24/rubber.png)
---| `ui.Icons.SatelliteDishLow` @![Icon](https://acstuff.ru/images/icons_24/satellite_dish_low.png)
---| `ui.Icons.SatelliteDishNone` @![Icon](https://acstuff.ru/images/icons_24/satellite_dish_none.png)
---| `ui.Icons.SatelliteDish` @![Icon](https://acstuff.ru/images/icons_24/satellite_dish.png)
---| `ui.Icons.Save` @![Icon](https://acstuff.ru/images/icons_24/save.png)
---| `ui.Icons.Scissors` @![Icon](https://acstuff.ru/images/icons_24/scissors.png)
---| `ui.Icons.Sea` @![Icon](https://acstuff.ru/images/icons_24/sea.png)
---| `ui.Icons.Search` @![Icon](https://acstuff.ru/images/icons_24/search.png)
---| `ui.Icons.Send` @![Icon](https://acstuff.ru/images/icons_24/send.png)
---| `ui.Icons.SettingsAlt` @![Icon](https://acstuff.ru/images/icons_24/settings_alt.png)
---| `ui.Icons.Settings` @![Icon](https://acstuff.ru/images/icons_24/settings.png)
---| `ui.Icons.ShieldWithLock` @![Icon](https://acstuff.ru/images/icons_24/shield_with_lock.png)
---| `ui.Icons.Shield` @![Icon](https://acstuff.ru/images/icons_24/shield.png)
---| `ui.Icons.ShiftActive` @![Icon](https://acstuff.ru/images/icons_24/shift_active.png)
---| `ui.Icons.Shift` @![Icon](https://acstuff.ru/images/icons_24/shift.png)
---| `ui.Icons.Shopping` @![Icon](https://acstuff.ru/images/icons_24/shopping.png)
---| `ui.Icons.Shuffle` @![Icon](https://acstuff.ru/images/icons_24/shuffle.png)
---| `ui.Icons.Skip` @![Icon](https://acstuff.ru/images/icons_24/skip.png)
---| `ui.Icons.Sleep` @![Icon](https://acstuff.ru/images/icons_24/sleep.png)
---| `ui.Icons.Sliders` @![Icon](https://acstuff.ru/images/icons_24/sliders.png)
---| `ui.Icons.SlowMotion` @![Icon](https://acstuff.ru/images/icons_24/slow_motion.png)
---| `ui.Icons.Smile` @![Icon](https://acstuff.ru/images/icons_24/smile.png)
---| `ui.Icons.Spaceship` @![Icon](https://acstuff.ru/images/icons_24/spaceship.png)
---| `ui.Icons.Speaker` @![Icon](https://acstuff.ru/images/icons_24/speaker.png)
---| `ui.Icons.Speedometer` @![Icon](https://acstuff.ru/images/icons_24/speedometer.png)
---| `ui.Icons.Spotify` @![Icon](https://acstuff.ru/images/icons_24/spotify.png)
---| `ui.Icons.SquaresHorizontal` @![Icon](https://acstuff.ru/images/icons_24/squares_horizontal.png)
---| `ui.Icons.SquaresVertical` @![Icon](https://acstuff.ru/images/icons_24/squares_vertical.png)
---| `ui.Icons.StarEmpty` @![Icon](https://acstuff.ru/images/icons_24/star_empty.png)
---| `ui.Icons.StarFull` @![Icon](https://acstuff.ru/images/icons_24/star_full.png)
---| `ui.Icons.StarHalf` @![Icon](https://acstuff.ru/images/icons_24/star_half.png)
---| `ui.Icons.Start` @![Icon](https://acstuff.ru/images/icons_24/start.png)
---| `ui.Icons.Stats` @![Icon](https://acstuff.ru/images/icons_24/stats.png)
---| `ui.Icons.Stay` @![Icon](https://acstuff.ru/images/icons_24/stay.png)
---| `ui.Icons.SteeringWheel` @![Icon](https://acstuff.ru/images/icons_24/steering_wheel.png)
---| `ui.Icons.StopAlt` @![Icon](https://acstuff.ru/images/icons_24/stop_alt.png)
---| `ui.Icons.Stop` @![Icon](https://acstuff.ru/images/icons_24/stop.png)
---| `ui.Icons.Stopwatch` @![Icon](https://acstuff.ru/images/icons_24/stopwatch.png)
---| `ui.Icons.Sweeping` @![Icon](https://acstuff.ru/images/icons_24/sweeping.png)
---| `ui.Icons.Tag` @![Icon](https://acstuff.ru/images/icons_24/tag.png)
---| `ui.Icons.Target` @![Icon](https://acstuff.ru/images/icons_24/target.png)
---| `ui.Icons.Team` @![Icon](https://acstuff.ru/images/icons_24/team.png)
---| `ui.Icons.Teleport` @![Icon](https://acstuff.ru/images/icons_24/teleport.png)
---| `ui.Icons.Tent` @![Icon](https://acstuff.ru/images/icons_24/tent.png)
---| `ui.Icons.Thermometer` @![Icon](https://acstuff.ru/images/icons_24/thermometer.png)
---| `ui.Icons.ThumbDown` @![Icon](https://acstuff.ru/images/icons_24/thumb_down.png)
---| `ui.Icons.ThumbUp` @![Icon](https://acstuff.ru/images/icons_24/thumb_up.png)
---| `ui.Icons.TimeRewind` @![Icon](https://acstuff.ru/images/icons_24/time_rewind.png)
---| `ui.Icons.TopHat` @![Icon](https://acstuff.ru/images/icons_24/top_hat.png)
---| `ui.Icons.TrafficLight` @![Icon](https://acstuff.ru/images/icons_24/traffic_light.png)
---| `ui.Icons.Transmission` @![Icon](https://acstuff.ru/images/icons_24/transmission.png)
---| `ui.Icons.Trash` @![Icon](https://acstuff.ru/images/icons_24/trash.png)
---| `ui.Icons.Treat` @![Icon](https://acstuff.ru/images/icons_24/treat.png)
---| `ui.Icons.Trophy` @![Icon](https://acstuff.ru/images/icons_24/trophy.png)
---| `ui.Icons.TurnSignalLeft` @![Icon](https://acstuff.ru/images/icons_24/turn_signal_left.png)
---| `ui.Icons.TurnSignalRight` @![Icon](https://acstuff.ru/images/icons_24/turn_signal_right.png)
---| `ui.Icons.Tv` @![Icon](https://acstuff.ru/images/icons_24/tv.png)
---| `ui.Icons.Umbrella` @![Icon](https://acstuff.ru/images/icons_24/umbrella.png)
---| `ui.Icons.Undo` @![Icon](https://acstuff.ru/images/icons_24/undo.png)
---| `ui.Icons.UpAlt` @![Icon](https://acstuff.ru/images/icons_24/up_alt.png)
---| `ui.Icons.Up` @![Icon](https://acstuff.ru/images/icons_24/up.png)
---| `ui.Icons.User` @![Icon](https://acstuff.ru/images/icons_24/user.png)
---| `ui.Icons.Verified` @![Icon](https://acstuff.ru/images/icons_24/verified.png)
---| `ui.Icons.VideoCameraAlt` @![Icon](https://acstuff.ru/images/icons_24/video_camera_alt.png)
---| `ui.Icons.VideoCamera` @![Icon](https://acstuff.ru/images/icons_24/video_camera.png)
---| `ui.Icons.VIP` @![Icon](https://acstuff.ru/images/icons_24/vip.png)
---| `ui.Icons.VolumeHigh` @![Icon](https://acstuff.ru/images/icons_24/volume_high.png)
---| `ui.Icons.VolumeLow` @![Icon](https://acstuff.ru/images/icons_24/volume_low.png)
---| `ui.Icons.VolumeMedium` @![Icon](https://acstuff.ru/images/icons_24/volume_medium.png)
---| `ui.Icons.Wallet` @![Icon](https://acstuff.ru/images/icons_24/wallet.png)
---| `ui.Icons.Warning` @![Icon](https://acstuff.ru/images/icons_24/warning.png)
---| `ui.Icons.WeatherClear` @![Icon](https://acstuff.ru/images/icons_24/weather_clear.png)
---| `ui.Icons.WeatherCold` @![Icon](https://acstuff.ru/images/icons_24/weather_cold.png)
---| `ui.Icons.WeatherDrizzle` @![Icon](https://acstuff.ru/images/icons_24/weather_drizzle.png)
---| `ui.Icons.WeatherFewClouds` @![Icon](https://acstuff.ru/images/icons_24/weather_few_clouds.png)
---| `ui.Icons.WeatherFog` @![Icon](https://acstuff.ru/images/icons_24/weather_fog.png)
---| `ui.Icons.WeatherHail` @![Icon](https://acstuff.ru/images/icons_24/weather_hail.png)
---| `ui.Icons.WeatherHot` @![Icon](https://acstuff.ru/images/icons_24/weather_hot.png)
---| `ui.Icons.WeatherHurricane` @![Icon](https://acstuff.ru/images/icons_24/weather_hurricane.png)
---| `ui.Icons.WeatherOvercast` @![Icon](https://acstuff.ru/images/icons_24/weather_overcast.png)
---| `ui.Icons.WeatherRainLight` @![Icon](https://acstuff.ru/images/icons_24/weather_rain_light.png)
---| `ui.Icons.WeatherRain` @![Icon](https://acstuff.ru/images/icons_24/weather_rain.png)
---| `ui.Icons.WeatherSleet` @![Icon](https://acstuff.ru/images/icons_24/weather_sleet.png)
---| `ui.Icons.WeatherSnowLight` @![Icon](https://acstuff.ru/images/icons_24/weather_snow_light.png)
---| `ui.Icons.WeatherSnow` @![Icon](https://acstuff.ru/images/icons_24/weather_snow.png)
---| `ui.Icons.WeatherStormLight` @![Icon](https://acstuff.ru/images/icons_24/weather_storm_light.png)
---| `ui.Icons.WeatherStorm` @![Icon](https://acstuff.ru/images/icons_24/weather_storm.png)
---| `ui.Icons.WeatherTornado` @![Icon](https://acstuff.ru/images/icons_24/weather_tornado.png)
---| `ui.Icons.WeatherWarm` @![Icon](https://acstuff.ru/images/icons_24/weather_warm.png)
---| `ui.Icons.WeatherWindySun` @![Icon](https://acstuff.ru/images/icons_24/weather_windy_sun.png)
---| `ui.Icons.WeatherWindy` @![Icon](https://acstuff.ru/images/icons_24/weather_windy.png)
---| `ui.Icons.Webcam` @![Icon](https://acstuff.ru/images/icons_24/webcam.png)
---| `ui.Icons.Wrench` @![Icon](https://acstuff.ru/images/icons_24/wrench.png)
---| `ui.Icons.YandexMusic` @![Icon](https://acstuff.ru/images/icons_24/yandex_music.png)
---| `ui.Icons.YoutubeSolid` @![Icon](https://acstuff.ru/images/icons_24/youtube_solid.png)
---| `ui.Icons.Youtube` @![Icon](https://acstuff.ru/images/icons_24/youtube.png)
---| `ui.Icons.ZoomIn` @![Icon](https://acstuff.ru/images/icons_24/zoom_in.png)
---| `ui.Icons.ZoomOut` @![Icon](https://acstuff.ru/images/icons_24/zoom_out.png)
ui.Icons = {
  LoadingSpinner = 'fx:loading', ---@type ui.Icons #Value: 'fx:loading'.
  AppWindow = 'APP_WINDOW', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/app_window.png)
  Apps = 'APPS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/apps.png)
  ArrowDown = 'ARROW_DOWN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/arrow_down.png)
  ArrowLeft = 'ARROW_LEFT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/arrow_left.png)
  ArrowRight = 'ARROW_RIGHT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/arrow_right.png)
  ArrowUp = 'ARROW_UP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/arrow_up.png)
  Attention = 'ATTENTION', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/attention.png)
  Avatar = 'AVATAR', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/avatar.png)
  Back = 'BACK', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/back.png)
  Backspace = 'BACKSPACE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/backspace.png)
  Ballast = 'BALLAST', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/ballast.png)
  Ban = 'BAN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/ban.png)
  Barcode = 'BARCODE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/barcode.png)
  Bars = 'BARS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/bars.png)
  BatteryEmpty = 'BATTERY_EMPTY', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/battery_empty.png)
  BatteryFull = 'BATTERY_FULL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/battery_full.png)
  Befriend = 'BEFRIEND', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/befriend.png)
  Bell = 'BELL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/bell.png)
  Binocoulars = 'BINOCOULARS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/binocoulars.png)
  Blackboard = 'BLACKBOARD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/blackboard.png)
  Bluetooth = 'BLUETOOTH', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/bluetooth.png)
  Bomb = 'BOMB', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/bomb.png)
  Book = 'BOOK', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/book.png)
  Bookmark = 'BOOKMARK', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/bookmark.png)
  Box = 'BOX', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/box.png)
  Briefcase = 'BRIEFCASE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/briefcase.png)
  Bug = 'BUG', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/bug.png)
  Bulb = 'BULB', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/bulb.png)
  Burn = 'BURN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/burn.png)
  Calculator = 'CALCULATOR', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/calculator.png)
  Calendar = 'CALENDAR', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/calendar.png)
  CallBluetooth = 'CALL_BLUETOOTH', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/call_bluetooth.png)
  Call = 'CALL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/call.png)
  Camera = 'CAMERA', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/camera.png)
  Cancel = 'CANCEL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/cancel.png)
  CarFront = 'CAR_FRONT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/car_front.png)
  Cards = 'CARDS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/cards.png)
  Cctv = 'CCTV', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/cctv.png)
  Cellphone = 'CELLPHONE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/cellphone.png)
  Chat = 'CHAT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/chat.png)
  Clapperboard = 'CLAPPERBOARD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/clapperboard.png)
  Clip = 'CLIP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/clip.png)
  Clipboard = 'CLIPBOARD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/clipboard.png)
  Clock = 'CLOCK', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/clock.png)
  Cloud = 'CLOUD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/cloud.png)
  Code = 'CODE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/code.png)
  Coffee = 'COFFEE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/coffee.png)
  CompassAlt = 'COMPASS_ALT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/compass_alt.png)
  Compass = 'COMPASS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/compass.png)
  Confirm = 'CONFIRM', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/confirm.png)
  Constellation = 'CONSTELLATION', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/constellation.png)
  Contacts = 'CONTACTS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/contacts.png)
  Contrast = 'CONTRAST', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/contrast.png)
  Copy = 'COPY', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/copy.png)
  CreditCard = 'CREDIT_CARD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/credit_card.png)
  Crop = 'CROP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/crop.png)
  Crosshair = 'CROSSHAIR', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/crosshair.png)
  Delete = 'DELETE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/delete.png)
  Dice = 'DICE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/dice.png)
  Directions = 'DIRECTIONS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/directions.png)
  Document = 'DOCUMENT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/document.png)
  DollarBill = 'DOLLAR_BILL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/dollar_bill.png)
  DownAlt = 'DOWN_ALT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/down_alt.png)
  Down = 'DOWN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/down.png)
  Download = 'DOWNLOAD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/download.png)
  Driver = 'DRIVER', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/driver.png)
  Earth = 'EARTH', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/earth.png)
  Edit = 'EDIT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/edit.png)
  Eject = 'EJECT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/eject.png)
  Ellipsis = 'ELLIPSIS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/ellipsis.png)
  Enter = 'ENTER', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/enter.png)
  Envelope = 'ENVELOPE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/envelope.png)
  Exit = 'EXIT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/exit.png)
  Eye = 'EYE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/eye.png)
  FastForward = 'FAST_FORWARD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/fast_forward.png)
  File = 'FILE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/file.png)
  FilmRoll = 'FILM_ROLL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/film_roll.png)
  Film = 'FILM', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/film.png)
  Finish = 'FINISH', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/finish.png)
  FireExtinguisher = 'FIRE_EXTINGUISHER', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/fire_extinguisher.png)
  Fireplace = 'FIREPLACE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/fireplace.png)
  FlagAlt = 'FLAG_ALT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/flag_alt.png)
  Flag = 'FLAG', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/flag.png)
  FM = 'FM', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/fm.png)
  Folder = 'FOLDER', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/folder.png)
  Font = 'FONT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/font.png)
  Fuel = 'FUEL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/fuel.png)
  Fullscreen = 'FULLSCREEN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/fullscreen.png)
  Gamepad = 'GAMEPAD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/gamepad.png)
  Global = 'GLOBAL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/global.png)
  GlowThick = 'GLOW_THICK', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/glow_thick.png)
  Glow = 'GLOW', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/glow.png)
  GPS = 'GPS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/gps.png)
  Group = 'GROUP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/group.png)
  HammerAlt = 'HAMMER_ALT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/hammer_alt.png)
  Hammer = 'HAMMER', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/hammer.png)
  Hazard = 'HAZARD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/hazard.png)
  Headphones = 'HEADPHONES', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/headphones.png)
  HeartOutline = 'HEART_OUTLINE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/heart_outline.png)
  Heart = 'HEART', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/heart.png)
  Helmet = 'HELMET', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/helmet.png)
  Hide = 'HIDE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/hide.png)
  Home = 'HOME', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/home.png)
  Horizontal = 'HORIZONTAL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/horizontal.png)
  Hourglass = 'HOURGLASS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/hourglass.png)
  InboxEmpty = 'INBOX_EMPTY', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/inbox_empty.png)
  InboxFull = 'INBOX_FULL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/inbox_full.png)
  Info = 'INFO', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/info.png)
  Key = 'KEY', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/key.png)
  Keyboard = 'KEYBOARD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/keyboard.png)
  Kick = 'KICK', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/kick.png)
  Landscape = 'LANDSCAPE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/landscape.png)
  Laptop = 'LAPTOP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/laptop.png)
  Leaderboard = 'LEADERBOARD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/leaderboard.png)
  Leave = 'LEAVE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/leave.png)
  Lens = 'LENS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/lens.png)
  Levels = 'LEVELS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/levels.png)
  LinkBroken = 'LINK_BROKEN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/link_broken.png)
  Link = 'LINK', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/link.png)
  ListAlt = 'LIST_ALT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/list_alt.png)
  List = 'LIST', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/list.png)
  Loading = 'LOADING', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/loading.png)
  Location = 'LOCATION', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/location.png)
  Lua = 'LUA', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/lua.png)
  Magnet = 'MAGNET', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/magnet.png)
  Map = 'MAP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/map.png)
  Maximize = 'MAXIMIZE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/maximize.png)
  Menu = 'MENU', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/menu.png)
  MicrophoneMuted = 'MICROPHONE_MUTED', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/microphone_muted.png)
  Microphone = 'MICROPHONE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/microphone.png)
  Minus = 'MINUS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/minus.png)
  Monitor = 'MONITOR', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/monitor.png)
  Moon = 'MOON', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/moon.png)
  Mouse = 'MOUSE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/mouse.png)
  Music = 'MUSIC', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/music.png)
  Mute = 'MUTE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/mute.png)
  Navigation = 'NAVIGATION', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/navigation.png)
  New = 'NEW', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/new.png)
  Next = 'NEXT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/next.png)
  NotificationsAny = 'NOTIFICATIONS_ANY', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/notifications_any.png)
  Notifications = 'NOTIFICATIONS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/notifications.png)
  PadlockUnlocked = 'PADLOCK_UNLOCKED', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/padlock_unlocked.png)
  Padlock = 'PADLOCK', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/padlock.png)
  Palette = 'PALETTE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/palette.png)
  Paperclip = 'PAPERCLIP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/paperclip.png)
  Paste = 'PASTE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/paste.png)
  Pause = 'PAUSE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/pause.png)
  Pedals = 'PEDALS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/pedals.png)
  Person = 'PERSON', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/person.png)
  Photograph = 'PHOTOGRAPH', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/photograph.png)
  Pin = 'PIN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/pin.png)
  PitStopAlt = 'PIT_STOP_ALT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/pit_stop_alt.png)
  PitStop = 'PIT_STOP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/pit_stop.png)
  Pitlane = 'PITLANE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/pitlane.png)
  Plane = 'PLANE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/plane.png)
  Play = 'PLAY', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/play.png)
  Plug = 'PLUG', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/plug.png)
  Plus = 'PLUS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/plus.png)
  Preview = 'PREVIEW', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/preview.png)
  Previous = 'PREVIOUS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/previous.png)
  Print = 'PRINT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/print.png)
  Process = 'PROCESS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/process.png)
  Puzzle = 'PUZZLE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/puzzle.png)
  Python = 'PYTHON', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/python.png)
  QR = 'QR', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/qr.png)
  QuestionSign = 'QUESTION_SIGN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/question_sign.png)
  Question = 'QUESTION', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/question.png)
  Radio = 'RADIO', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/radio.png)
  Recognition = 'RECOGNITION', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/recognition.png)
  Record = 'RECORD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/record.png)
  Redo = 'REDO', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/redo.png)
  Referee = 'REFEREE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/referee.png)
  Repair = 'REPAIR', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/repair.png)
  Reset = 'RESET', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/reset.png)
  RestartWarning = 'RESTART_WARNING', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/restart_warning.png)
  Restart = 'RESTART', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/restart.png)
  Restrictor = 'RESTRICTOR', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/restrictor.png)
  Resume = 'RESUME', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/resume.png)
  Rewind = 'REWIND', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/rewind.png)
  Road = 'ROAD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/road.png)
  Rubber = 'RUBBER', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/rubber.png)
  SatelliteDishLow = 'SATELLITE_DISH_LOW', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/satellite_dish_low.png)
  SatelliteDishNone = 'SATELLITE_DISH_NONE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/satellite_dish_none.png)
  SatelliteDish = 'SATELLITE_DISH', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/satellite_dish.png)
  Save = 'SAVE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/save.png)
  Scissors = 'SCISSORS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/scissors.png)
  Sea = 'SEA', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/sea.png)
  Search = 'SEARCH', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/search.png)
  Send = 'SEND', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/send.png)
  SettingsAlt = 'SETTINGS_ALT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/settings_alt.png)
  Settings = 'SETTINGS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/settings.png)
  ShieldWithLock = 'SHIELD_WITH_LOCK', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/shield_with_lock.png)
  Shield = 'SHIELD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/shield.png)
  ShiftActive = 'SHIFT_ACTIVE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/shift_active.png)
  Shift = 'SHIFT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/shift.png)
  Shopping = 'SHOPPING', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/shopping.png)
  Shuffle = 'SHUFFLE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/shuffle.png)
  Skip = 'SKIP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/skip.png)
  Sleep = 'SLEEP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/sleep.png)
  Sliders = 'SLIDERS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/sliders.png)
  SlowMotion = 'SLOW_MOTION', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/slow_motion.png)
  Smile = 'SMILE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/smile.png)
  Spaceship = 'SPACESHIP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/spaceship.png)
  Speaker = 'SPEAKER', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/speaker.png)
  Speedometer = 'SPEEDOMETER', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/speedometer.png)
  Spotify = 'SPOTIFY', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/spotify.png)
  SquaresHorizontal = 'SQUARES_HORIZONTAL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/squares_horizontal.png)
  SquaresVertical = 'SQUARES_VERTICAL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/squares_vertical.png)
  StarEmpty = 'STAR_EMPTY', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/star_empty.png)
  StarFull = 'STAR_FULL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/star_full.png)
  StarHalf = 'STAR_HALF', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/star_half.png)
  Start = 'START', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/start.png)
  Stats = 'STATS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/stats.png)
  Stay = 'STAY', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/stay.png)
  SteeringWheel = 'STEERING_WHEEL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/steering_wheel.png)
  StopAlt = 'STOP_ALT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/stop_alt.png)
  Stop = 'STOP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/stop.png)
  Stopwatch = 'STOPWATCH', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/stopwatch.png)
  Sweeping = 'SWEEPING', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/sweeping.png)
  Tag = 'TAG', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/tag.png)
  Target = 'TARGET', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/target.png)
  Team = 'TEAM', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/team.png)
  Teleport = 'TELEPORT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/teleport.png)
  Tent = 'TENT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/tent.png)
  Thermometer = 'THERMOMETER', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/thermometer.png)
  ThumbDown = 'THUMB_DOWN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/thumb_down.png)
  ThumbUp = 'THUMB_UP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/thumb_up.png)
  TimeRewind = 'TIME_REWIND', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/time_rewind.png)
  TopHat = 'TOP_HAT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/top_hat.png)
  TrafficLight = 'TRAFFIC_LIGHT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/traffic_light.png)
  Transmission = 'TRANSMISSION', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/transmission.png)
  Trash = 'TRASH', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/trash.png)
  Treat = 'TREAT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/treat.png)
  Trophy = 'TROPHY', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/trophy.png)
  TurnSignalLeft = 'TURN_SIGNAL_LEFT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/turn_signal_left.png)
  TurnSignalRight = 'TURN_SIGNAL_RIGHT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/turn_signal_right.png)
  Tv = 'TV', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/tv.png)
  Umbrella = 'UMBRELLA', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/umbrella.png)
  Undo = 'UNDO', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/undo.png)
  UpAlt = 'UP_ALT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/up_alt.png)
  Up = 'UP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/up.png)
  User = 'USER', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/user.png)
  Verified = 'VERIFIED', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/verified.png)
  VideoCameraAlt = 'VIDEO_CAMERA_ALT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/video_camera_alt.png)
  VideoCamera = 'VIDEO_CAMERA', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/video_camera.png)
  VIP = 'VIP', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/vip.png)
  VolumeHigh = 'VOLUME_HIGH', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/volume_high.png)
  VolumeLow = 'VOLUME_LOW', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/volume_low.png)
  VolumeMedium = 'VOLUME_MEDIUM', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/volume_medium.png)
  Wallet = 'WALLET', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/wallet.png)
  Warning = 'WARNING', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/warning.png)
  WeatherClear = 'WEATHER_CLEAR', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_clear.png)
  WeatherCold = 'WEATHER_COLD', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_cold.png)
  WeatherDrizzle = 'WEATHER_DRIZZLE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_drizzle.png)
  WeatherFewClouds = 'WEATHER_FEW_CLOUDS', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_few_clouds.png)
  WeatherFog = 'WEATHER_FOG', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_fog.png)
  WeatherHail = 'WEATHER_HAIL', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_hail.png)
  WeatherHot = 'WEATHER_HOT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_hot.png)
  WeatherHurricane = 'WEATHER_HURRICANE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_hurricane.png)
  WeatherOvercast = 'WEATHER_OVERCAST', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_overcast.png)
  WeatherRainLight = 'WEATHER_RAIN_LIGHT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_rain_light.png)
  WeatherRain = 'WEATHER_RAIN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_rain.png)
  WeatherSleet = 'WEATHER_SLEET', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_sleet.png)
  WeatherSnowLight = 'WEATHER_SNOW_LIGHT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_snow_light.png)
  WeatherSnow = 'WEATHER_SNOW', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_snow.png)
  WeatherStormLight = 'WEATHER_STORM_LIGHT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_storm_light.png)
  WeatherStorm = 'WEATHER_STORM', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_storm.png)
  WeatherTornado = 'WEATHER_TORNADO', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_tornado.png)
  WeatherWarm = 'WEATHER_WARM', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_warm.png)
  WeatherWindySun = 'WEATHER_WINDY_SUN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_windy_sun.png)
  WeatherWindy = 'WEATHER_WINDY', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/weather_windy.png)
  Webcam = 'WEBCAM', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/webcam.png)
  Wrench = 'WRENCH', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/wrench.png)
  YandexMusic = 'YANDEX_MUSIC', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/yandex_music.png)
  YoutubeSolid = 'YOUTUBE_SOLID', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/youtube_solid.png)
  Youtube = 'YOUTUBE', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/youtube.png)
  ZoomIn = 'ZOOM_IN', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/zoom_in.png)
  ZoomOut = 'ZOOM_OUT', ---@type ui.Icons #![Icon](https://acstuff.ru/images/icons_24/zoom_out.png)
}

---@alias ui.ButtonFlags
---| `ui.ButtonFlags.None` @No special options.
---| `ui.ButtonFlags.Repeat` @Hold to repeat.
---| `ui.ButtonFlags.PressedOnClickRelease` @Return true on click + release on same item.
---| `ui.ButtonFlags.PressedOnClick` @Return true on click (default requires click+release).
---| `ui.ButtonFlags.PressedOnRelease` @Return true on release (default requires click+release).
---| `ui.ButtonFlags.PressedOnDoubleClick` @Return true on double-click (default requires click+release).
---| `ui.ButtonFlags.FlattenChildren` @Allow interactions even if a child window is overlapping.
---| `ui.ButtonFlags.AllowItemOverlap` @Require previous frame HoveredId to either match id or be null before being usable, use along with SetItemAllowOverlap().
---| `ui.ButtonFlags.DontClosePopups` @Disable automatically closing parent popup on press.
---| `ui.ButtonFlags.Disabled` @Disable interactions.
---| `ui.ButtonFlags.NoKeyModifiers` @Disable interaction if a key modifier is held.
---| `ui.ButtonFlags.PressedOnDragDropHold` @Press when held into while we are drag and dropping another item (used by e.g. tree nodes, collapsing headers).
---| `ui.ButtonFlags.NoNavFocus` @Don’t override navigation focus when activated.
---| `ui.ButtonFlags.NoHoveredOnNav` @Don’t report as hovered when navigated on.
---| `ui.ButtonFlags.Error` @For modern buttons.
---| `ui.ButtonFlags.Confirm` @For modern buttons.
---| `ui.ButtonFlags.Cancel` @For modern buttons.
---| `ui.ButtonFlags.VerticalLayout` @For modern buttons.
---| `ui.ButtonFlags.TextAsIcon` @For modern buttons.
---| `ui.ButtonFlags.Active` @Button is correctly active (checked).
---| `ui.ButtonFlags.Activable` @If not set, _Active would make background brighter.
ui.ButtonFlags = {
  None = 0x0, ---@type ui.ButtonFlags #No special options.
  Repeat = 0x1, ---@type ui.ButtonFlags #Hold to repeat.
  PressedOnClickRelease = 0x2, ---@type ui.ButtonFlags #Return true on click + release on same item.
  PressedOnClick = 0x4, ---@type ui.ButtonFlags #Return true on click (default requires click+release).
  PressedOnRelease = 0x8, ---@type ui.ButtonFlags #Return true on release (default requires click+release).
  PressedOnDoubleClick = 0x10, ---@type ui.ButtonFlags #Return true on double-click (default requires click+release).
  FlattenChildren = 0x20, ---@type ui.ButtonFlags #Allow interactions even if a child window is overlapping.
  AllowItemOverlap = 0x40, ---@type ui.ButtonFlags #Require previous frame HoveredId to either match id or be null before being usable, use along with SetItemAllowOverlap().
  DontClosePopups = 0x80, ---@type ui.ButtonFlags #Disable automatically closing parent popup on press.
  Disabled = 0x100, ---@type ui.ButtonFlags #Disable interactions.
  NoKeyModifiers = 0x400, ---@type ui.ButtonFlags #Disable interaction if a key modifier is held.
  PressedOnDragDropHold = 0x1000, ---@type ui.ButtonFlags #Press when held into while we are drag and dropping another item (used by e.g. tree nodes, collapsing headers).
  NoNavFocus = 0x2000, ---@type ui.ButtonFlags #Don’t override navigation focus when activated.
  NoHoveredOnNav = 0x4000, ---@type ui.ButtonFlags #Don’t report as hovered when navigated on.
  Error = 0x8000, ---@type ui.ButtonFlags #For modern buttons.
  Confirm = 0x10000, ---@type ui.ButtonFlags #For modern buttons.
  Cancel = 0x20000, ---@type ui.ButtonFlags #For modern buttons.
  VerticalLayout = 0x40000, ---@type ui.ButtonFlags #For modern buttons.
  TextAsIcon = 0x80000, ---@type ui.ButtonFlags #For modern buttons.
  Active = 0x100000, ---@type ui.ButtonFlags #Button is correctly active (checked).
  Activable = 0x200000, ---@type ui.ButtonFlags #If not set, _Active would make background brighter.
}

---@alias ui.WindowFlags
---| `ui.WindowFlags.None` @No special options.
---| `ui.WindowFlags.NoTitleBar` @Disable title-bar.
---| `ui.WindowFlags.NoResize` @Disable user resizing with the lower-right grip.
---| `ui.WindowFlags.NoMove` @Disable user moving the window.
---| `ui.WindowFlags.NoScrollbar` @Disable scrollbars (window can still scroll with mouse or programmatically).
---| `ui.WindowFlags.NoScrollWithMouse` @Disable user vertically scrolling with mouse wheel. On child window, mouse wheel will be forwarded to the parent unless NoScrollbar is also set.
---| `ui.WindowFlags.NoCollapse` @Disable user collapsing window by double-clicking on it.
---| `ui.WindowFlags.AlwaysAutoResize` @Resize every window to its content every frame.
---| `ui.WindowFlags.NoBackground` @Disable drawing background and outside border.
---| `ui.WindowFlags.NoSavedSettings` @Never load/save settings in .ini file.
---| `ui.WindowFlags.NoMouseInputs` @Disable catching mouse, hovering test with pass through.
---| `ui.WindowFlags.MenuBar` @Has a menu-bar.
---| `ui.WindowFlags.HorizontalScrollbar` @Allow horizontal scrollbar to appear (off by default).
---| `ui.WindowFlags.NoFocusOnAppearing` @Disable taking focus when transitioning from hidden to visible state.
---| `ui.WindowFlags.NoBringToFrontOnFocus` @Disable bringing window to front when taking focus (e.g. clicking on it or programmatically giving it focus).
---| `ui.WindowFlags.AlwaysVerticalScrollbar` @Always show vertical scrollbar (even if ContentSize.y < Size.y).
---| `ui.WindowFlags.AlwaysHorizontalScrollbar` @Always show horizontal scrollbar (even if ContentSize.x < Size.x).
---| `ui.WindowFlags.AlwaysUseWindowPadding` @Ensure child windows without border uses style.WindowPadding (ignored by default for non-bordered child windows, because more convenient).
---| `ui.WindowFlags.NoNavInputs` @No gamepad/keyboard navigation within the window.
---| `ui.WindowFlags.NoNavFocus` @No focusing toward this window with gamepad/keyboard navigation (e.g. skipped by CTRL+TAB).
---| `ui.WindowFlags.UnsavedDocument` @Append “*” to title without affecting the ID, as a convenience to avoid using the “###” operator.
---| `ui.WindowFlags.NoNav` @Combination of flags: NoNavInputs | NoNavFocus (use `bit.bor(ui.WindowFlags.NoNav, …)` to combine it with other flags safely).
---| `ui.WindowFlags.NoDecoration` @Combination of flags: NoTitleBar | NoResize | NoScrollbar | NoCollapse (use `bit.bor(ui.WindowFlags.NoDecoration, …)` to combine it with other flags safely).
---| `ui.WindowFlags.NoInputs` @Combination of flags: NoMouseInputs | NoNavInputs | NoNavFocus (use `bit.bor(ui.WindowFlags.NoInputs, …)` to combine it with other flags safely).
---| `ui.WindowFlags.BitmapCache` @Cache window contents.
---| `ui.WindowFlags.ThinScrollbar` @Thin scrollbar.
ui.WindowFlags = {
  None = 0x0, ---@type ui.WindowFlags #No special options.
  NoTitleBar = 0x1, ---@type ui.WindowFlags #Disable title-bar.
  NoResize = 0x2, ---@type ui.WindowFlags #Disable user resizing with the lower-right grip.
  NoMove = 0x4, ---@type ui.WindowFlags #Disable user moving the window.
  NoScrollbar = 0x8, ---@type ui.WindowFlags #Disable scrollbars (window can still scroll with mouse or programmatically).
  NoScrollWithMouse = 0x10, ---@type ui.WindowFlags #Disable user vertically scrolling with mouse wheel. On child window, mouse wheel will be forwarded to the parent unless NoScrollbar is also set.
  NoCollapse = 0x20, ---@type ui.WindowFlags #Disable user collapsing window by double-clicking on it.
  AlwaysAutoResize = 0x40, ---@type ui.WindowFlags #Resize every window to its content every frame.
  NoBackground = 0x80, ---@type ui.WindowFlags #Disable drawing background and outside border.
  NoSavedSettings = 0x100, ---@type ui.WindowFlags #Never load/save settings in .ini file.
  NoMouseInputs = 0x200, ---@type ui.WindowFlags #Disable catching mouse, hovering test with pass through.
  MenuBar = 0x400, ---@type ui.WindowFlags #Has a menu-bar.
  HorizontalScrollbar = 0x800, ---@type ui.WindowFlags #Allow horizontal scrollbar to appear (off by default).
  NoFocusOnAppearing = 0x1000, ---@type ui.WindowFlags #Disable taking focus when transitioning from hidden to visible state.
  NoBringToFrontOnFocus = 0x2000, ---@type ui.WindowFlags #Disable bringing window to front when taking focus (e.g. clicking on it or programmatically giving it focus).
  AlwaysVerticalScrollbar = 0x4000, ---@type ui.WindowFlags #Always show vertical scrollbar (even if ContentSize.y < Size.y).
  AlwaysHorizontalScrollbar = 0x8000, ---@type ui.WindowFlags #Always show horizontal scrollbar (even if ContentSize.x < Size.x).
  AlwaysUseWindowPadding = 0x10000, ---@type ui.WindowFlags #Ensure child windows without border uses style.WindowPadding (ignored by default for non-bordered child windows, because more convenient).
  NoNavInputs = 0x40000, ---@type ui.WindowFlags #No gamepad/keyboard navigation within the window.
  NoNavFocus = 0x80000, ---@type ui.WindowFlags #No focusing toward this window with gamepad/keyboard navigation (e.g. skipped by CTRL+TAB).
  UnsavedDocument = 0x100000, ---@type ui.WindowFlags #Append “*” to title without affecting the ID, as a convenience to avoid using the “###” operator.
  NoNav = 0xc0000, ---@type ui.WindowFlags #Combination of flags: NoNavInputs|NoNavFocus (use `bit.bor(ui.WindowFlags.NoNav, …)` to combine it with other flags safely).
  NoDecoration = 0x2b, ---@type ui.WindowFlags #Combination of flags: NoTitleBar|NoResize|NoScrollbar|NoCollapse (use `bit.bor(ui.WindowFlags.NoDecoration, …)` to combine it with other flags safely).
  NoInputs = 0xc0200, ---@type ui.WindowFlags #Combination of flags: NoMouseInputs|NoNavInputs|NoNavFocus (use `bit.bor(ui.WindowFlags.NoInputs, …)` to combine it with other flags safely).
  BitmapCache = 0x40000000, ---@type ui.WindowFlags #Cache window contents.
  ThinScrollbar = 0x80000000, ---@type ui.WindowFlags #Thin scrollbar.
}

---@alias ui.ComboFlags
---| `ui.ComboFlags.None` @No special options.
---| `ui.ComboFlags.PopupAlignLeft` @Align the popup toward the left by default.
---| `ui.ComboFlags.HeightSmall` @Max ~4 items visible. Tip: If you want your combo popup to be a specific size you can use SetNextWindowSizeConstraints() prior to calling BeginCombo().
---| `ui.ComboFlags.HeightRegular` @Max ~8 items visible (default).
---| `ui.ComboFlags.HeightLarge` @Max ~20 items visible.
---| `ui.ComboFlags.HeightLargest` @As many fitting items as possible.
---| `ui.ComboFlags.NoArrowButton` @Display on the preview box without the square arrow button.
---| `ui.ComboFlags.NoPreview` @Display only a square arrow button.
---| `ui.ComboFlags.GoUp` @Dropdown goes up.
---| `ui.ComboFlags.HeightChubby` @Height between regular and large.
ui.ComboFlags = {
  None = 0x0, ---@type ui.ComboFlags #No special options.
  PopupAlignLeft = 0x1, ---@type ui.ComboFlags #Align the popup toward the left by default.
  HeightSmall = 0x2, ---@type ui.ComboFlags #Max ~4 items visible. Tip: If you want your combo popup to be a specific size you can use SetNextWindowSizeConstraints() prior to calling BeginCombo().
  HeightRegular = 0x4, ---@type ui.ComboFlags #Max ~8 items visible (default).
  HeightLarge = 0x8, ---@type ui.ComboFlags #Max ~20 items visible.
  HeightLargest = 0x10, ---@type ui.ComboFlags #As many fitting items as possible.
  NoArrowButton = 0x20, ---@type ui.ComboFlags #Display on the preview box without the square arrow button.
  NoPreview = 0x40, ---@type ui.ComboFlags #Display only a square arrow button.
  GoUp = 0x80, ---@type ui.ComboFlags #Dropdown goes up.
  HeightChubby = 0x100, ---@type ui.ComboFlags #Height between regular and large.
}

---@alias ui.InputTextFlags
---| `ui.InputTextFlags.None` @No special options.
---| `ui.InputTextFlags.CharsDecimal` @Allow “0123456789.+-*/”.
---| `ui.InputTextFlags.CharsHexadecimal` @Allow “0123456789ABCDEFabcdef”.
---| `ui.InputTextFlags.CharsUppercase` @Turn a…z into A…Z.
---| `ui.InputTextFlags.CharsNoBlank` @Filter out spaces, tabs.
---| `ui.InputTextFlags.AutoSelectAll` @Select entire text when first taking mouse focus.
---| `ui.InputTextFlags.AllowTabInput` @Pressing TAB input a '\t' character into the text field.
---| `ui.InputTextFlags.CtrlEnterForNewLine` @In multi-line mode, unfocus with Enter, add new line with Ctrl+Enter (default is opposite: unfocus with Ctrl+Enter, add line with Enter).
---| `ui.InputTextFlags.NoHorizontalScroll` @Disable following the cursor horizontally.
---| `ui.InputTextFlags.AlwaysInsertMode` @Insert mode.
---| `ui.InputTextFlags.ReadOnly` @Read-only mode.
---| `ui.InputTextFlags.Password` @Password mode, display all characters as “*”.
---| `ui.InputTextFlags.NoUndoRedo` @Disable undo/redo. Note that input text owns the text data while active, if you want to provide your own undo/redo stack you need e.g. to call ClearActiveID().
---| `ui.InputTextFlags.CharsScientific` @Allow “0123456789.+-*/eE” (Scientific notation input).
---| `ui.InputTextFlags.Placeholder` @Show label as a placeholder.
---| `ui.InputTextFlags.ClearButton` @Add button erasing text.
---| `ui.InputTextFlags.RetainSelection` @Do not lose selection when Enter is pressed, do not select all with focusing in code.
ui.InputTextFlags = {
  None = 0x0, ---@type ui.InputTextFlags #No special options.
  CharsDecimal = 0x1, ---@type ui.InputTextFlags #Allow “0123456789.+-*/”.
  CharsHexadecimal = 0x2, ---@type ui.InputTextFlags #Allow “0123456789ABCDEFabcdef”.
  CharsUppercase = 0x4, ---@type ui.InputTextFlags #Turn a…z into A…Z.
  CharsNoBlank = 0x8, ---@type ui.InputTextFlags #Filter out spaces, tabs.
  AutoSelectAll = 0x10, ---@type ui.InputTextFlags #Select entire text when first taking mouse focus.
  AllowTabInput = 0x400, ---@type ui.InputTextFlags #Pressing TAB input a '\t' character into the text field.
  CtrlEnterForNewLine = 0x800, ---@type ui.InputTextFlags #In multi-line mode, unfocus with Enter, add new line with Ctrl+Enter (default is opposite: unfocus with Ctrl+Enter, add line with Enter).
  NoHorizontalScroll = 0x1000, ---@type ui.InputTextFlags #Disable following the cursor horizontally.
  AlwaysInsertMode = 0x2000, ---@type ui.InputTextFlags #Insert mode.
  ReadOnly = 0x4000, ---@type ui.InputTextFlags #Read-only mode.
  Password = 0x8000, ---@type ui.InputTextFlags #Password mode, display all characters as “*”.
  NoUndoRedo = 0x10000, ---@type ui.InputTextFlags #Disable undo/redo. Note that input text owns the text data while active, if you want to provide your own undo/redo stack you need e.g. to call ClearActiveID().
  CharsScientific = 0x20000, ---@type ui.InputTextFlags #Allow “0123456789.+-*/eE” (Scientific notation input).
  Placeholder = 0x400000, ---@type ui.InputTextFlags #Show label as a placeholder.
  ClearButton = 0x800000, ---@type ui.InputTextFlags #Add button erasing text.
  RetainSelection = 0x1000000, ---@type ui.InputTextFlags #Do not lose selection when Enter is pressed, do not select all with focusing in code.
}

---@alias ui.SelectableFlags
---| `ui.SelectableFlags.None` @No special options.
---| `ui.SelectableFlags.DontClosePopups` @Clicking this don’t close parent popup window.
---| `ui.SelectableFlags.SpanAllColumns` @Selectable frame can span all columns (text will still fit in current column).
---| `ui.SelectableFlags.AllowDoubleClick` @Generate press events on double clicks too.
---| `ui.SelectableFlags.Disabled` @Cannot be selected, display grayed out text.
---| `ui.SelectableFlags.SpanClipRect` @Span entire left to right current clip rect boundary (use carefully).
ui.SelectableFlags = {
  None = 0x0, ---@type ui.SelectableFlags #No special options.
  DontClosePopups = 0x1, ---@type ui.SelectableFlags #Clicking this don’t close parent popup window.
  SpanAllColumns = 0x2, ---@type ui.SelectableFlags #Selectable frame can span all columns (text will still fit in current column).
  AllowDoubleClick = 0x4, ---@type ui.SelectableFlags #Generate press events on double clicks too.
  Disabled = 0x8, ---@type ui.SelectableFlags #Cannot be selected, display grayed out text.
  SpanClipRect = 0x80, ---@type ui.SelectableFlags #Span entire left to right current clip rect boundary (use carefully).
}

---@alias ui.TabBarFlags
---| `ui.TabBarFlags.None` @No special options.
---| `ui.TabBarFlags.Reorderable` @Allow manually dragging tabs to re-order them + New tabs are appended at the end of list.
---| `ui.TabBarFlags.AutoSelectNewTabs` @Automatically select new tabs when they appear.
---| `ui.TabBarFlags.TabListPopupButton` @Disable buttons to open the tab list popup.
---| `ui.TabBarFlags.NoCloseWithMiddleMouseButton` @Disable behavior of closing tabs with middle mouse button.
---| `ui.TabBarFlags.NoTabListScrollingButtons` @Disable scrolling buttons (apply when fitting policy is FittingPolicyScroll).
---| `ui.TabBarFlags.NoTooltip` @Disable tooltips when hovering a tab.
---| `ui.TabBarFlags.FittingPolicyResizeDown` @Resize tabs when they don’t fit.
---| `ui.TabBarFlags.FittingPolicyScroll` @Add scroll buttons when tabs don’t fit.
---| `ui.TabBarFlags.IntegratedTabs` @Integrates tab bar into a window title (call it first when drawing a window).
---| `ui.TabBarFlags.SaveSelected` @Save selected tab based on tab ID (make sure tab ID is unique).
ui.TabBarFlags = {
  None = 0x0, ---@type ui.TabBarFlags #No special options.
  Reorderable = 0x1, ---@type ui.TabBarFlags #Allow manually dragging tabs to re-order them + New tabs are appended at the end of list.
  AutoSelectNewTabs = 0x2, ---@type ui.TabBarFlags #Automatically select new tabs when they appear.
  TabListPopupButton = 0x4, ---@type ui.TabBarFlags #Disable buttons to open the tab list popup.
  NoCloseWithMiddleMouseButton = 0x8, ---@type ui.TabBarFlags #Disable behavior of closing tabs with middle mouse button.
  NoTabListScrollingButtons = 0x10, ---@type ui.TabBarFlags #Disable scrolling buttons (apply when fitting policy is FittingPolicyScroll).
  NoTooltip = 0x20, ---@type ui.TabBarFlags #Disable tooltips when hovering a tab.
  FittingPolicyResizeDown = 0x40, ---@type ui.TabBarFlags #Resize tabs when they don’t fit.
  FittingPolicyScroll = 0x80, ---@type ui.TabBarFlags #Add scroll buttons when tabs don’t fit.
  IntegratedTabs = 0x8000, ---@type ui.TabBarFlags #Integrates tab bar into a window title (call it first when drawing a window).
  SaveSelected = 0x10000, ---@type ui.TabBarFlags #Save selected tab based on tab ID (make sure tab ID is unique).
}

---@alias ui.TabItemFlags
---| `ui.TabItemFlags.None` @Value: 0.
---| `ui.TabItemFlags.UnsavedDocument` @Append '*' to title without affecting the ID, as a convenience to avoid using the ### operator. Also: tab is selected on closure and closure is deferred by one frame to allow code to undo it without flicker.
---| `ui.TabItemFlags.SetSelected` @Trigger flag to programmatically make the tab selected when calling BeginTabItem().
---| `ui.TabItemFlags.NoCloseWithMiddleMouseButton` @Disable behavior of closing tabs (that are submitted with p_open !
ui.TabItemFlags = {
  None = 0, ---@type ui.TabItemFlags #Value: 0.
  UnsavedDocument = 1, ---@type ui.TabItemFlags #Append '*' to title without affecting the ID, as a convenience to avoid using the ### operator. Also: tab is selected on closure and closure is deferred by one frame to allow code to undo it without flicker.
  SetSelected = 2, ---@type ui.TabItemFlags #Trigger flag to programmatically make the tab selected when calling BeginTabItem().
  NoCloseWithMiddleMouseButton = 4, ---@type ui.TabItemFlags #Disable behavior of closing tabs (that are submitted with p_open !
}

---@alias ui.TreeNodeFlags
---| `ui.TreeNodeFlags.None` @No special options.
---| `ui.TreeNodeFlags.Selected` @Draw as selected.
---| `ui.TreeNodeFlags.Framed` @Full colored frame (e.g. for CollapsingHeader).
---| `ui.TreeNodeFlags.AllowItemOverlap` @Hit testing to allow subsequent widgets to overlap this one.
---| `ui.TreeNodeFlags.NoTreePushOnOpen` @Don’t do a TreePush() when open (e.g. for CollapsingHeader).
---| `ui.TreeNodeFlags.NoAutoOpenOnLog` @Don’t automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes).
---| `ui.TreeNodeFlags.DefaultOpen` @Default node to be open.
---| `ui.TreeNodeFlags.OpenOnDoubleClick` @Need double-click to open node.
---| `ui.TreeNodeFlags.OpenOnArrow` @Only open when clicking on the arrow part. If OpenOnDoubleClick is also set, single-click arrow or double-click all box to open.
---| `ui.TreeNodeFlags.Leaf` @No collapsing, no arrow (use as a convenience for leaf nodes).
---| `ui.TreeNodeFlags.Bullet` @Display a bullet instead of arrow.
---| `ui.TreeNodeFlags.FramePadding` @Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling AlignTextToFramePadding().
---| `ui.TreeNodeFlags.CollapsingHeader` @Combination of flags: Framed | NoTreePushOnOpen | NoAutoOpenOnLog (use `bit.bor(ui.TreeNodeFlags.CollapsingHeader, …)` to combine it with other flags safely).
---| `ui.TreeNodeFlags.NoArrow` @Value: 0x4000.
---| `ui.TreeNodeFlags.SpanClipRect` @Span entire left to right current clip rect boundary (use carefully).
---| `ui.TreeNodeFlags.Animated` @Value: 0xf0000000.
ui.TreeNodeFlags = {
  None = 0x0, ---@type ui.TreeNodeFlags #No special options.
  Selected = 0x1, ---@type ui.TreeNodeFlags #Draw as selected.
  Framed = 0x2, ---@type ui.TreeNodeFlags #Full colored frame (e.g. for CollapsingHeader).
  AllowItemOverlap = 0x4, ---@type ui.TreeNodeFlags #Hit testing to allow subsequent widgets to overlap this one.
  NoTreePushOnOpen = 0x8, ---@type ui.TreeNodeFlags #Don’t do a TreePush() when open (e.g. for CollapsingHeader).
  NoAutoOpenOnLog = 0x10, ---@type ui.TreeNodeFlags #Don’t automatically and temporarily open node when Logging is active (by default logging will automatically open tree nodes).
  DefaultOpen = 0x20, ---@type ui.TreeNodeFlags #Default node to be open.
  OpenOnDoubleClick = 0x40, ---@type ui.TreeNodeFlags #Need double-click to open node.
  OpenOnArrow = 0x80, ---@type ui.TreeNodeFlags #Only open when clicking on the arrow part. If OpenOnDoubleClick is also set, single-click arrow or double-click all box to open.
  Leaf = 0x100, ---@type ui.TreeNodeFlags #No collapsing, no arrow (use as a convenience for leaf nodes).
  Bullet = 0x200, ---@type ui.TreeNodeFlags #Display a bullet instead of arrow.
  FramePadding = 0x400, ---@type ui.TreeNodeFlags #Use FramePadding (even for an unframed text node) to vertically align text baseline to regular widget height. Equivalent to calling AlignTextToFramePadding().
  CollapsingHeader = 0x1a, ---@type ui.TreeNodeFlags #Combination of flags: Framed|NoTreePushOnOpen|NoAutoOpenOnLog (use `bit.bor(ui.TreeNodeFlags.CollapsingHeader, …)` to combine it with other flags safely).
  NoArrow = 0x4000, ---@type ui.TreeNodeFlags #Value: 0x4000.
  SpanClipRect = 0x8000, ---@type ui.TreeNodeFlags #Span entire left to right current clip rect boundary (use carefully).
  Animated = 0xf0000000, ---@type ui.TreeNodeFlags #Value: 0xf0000000.
}

---@alias ui.ColorPickerFlags
---| `ui.ColorPickerFlags.None` @Value: 0.
---| `ui.ColorPickerFlags.NoAlpha` @Ignore Alpha component (will only read 3 components from the input pointer).
---| `ui.ColorPickerFlags.NoPicker` @Disable picker when clicking on colored square.
---| `ui.ColorPickerFlags.NoOptions` @Disable toggling options menu when right-clicking on inputs/small preview.
---| `ui.ColorPickerFlags.NoSmallPreview` @Disable colored square preview next to the inputs. (e.g. to show only the inputs).
---| `ui.ColorPickerFlags.NoInputs` @Disable inputs sliders/text widgets (e.g. to show only the small preview colored square).
---| `ui.ColorPickerFlags.NoTooltip` @Disable tooltip when hovering the preview.
---| `ui.ColorPickerFlags.NoLabel` @Disable display of inline text label (the label is still forwarded to the tooltip and picker).
---| `ui.ColorPickerFlags.NoSidePreview` @Disable bigger color preview on right side of the picker, use small colored square preview instead.
---| `ui.ColorPickerFlags.NoDragDrop` @Disable drag and drop target. ColorButton: disable drag and drop source.
---| `ui.ColorPickerFlags.AlphaBar` @Show vertical alpha bar/gradient in picker.
---| `ui.ColorPickerFlags.AlphaPreview` @Display preview as a transparent color over a checkerboard, instead of opaque.
---| `ui.ColorPickerFlags.AlphaPreviewHalf` @Display half opaque / half checkerboard, instead of opaque.
---| `ui.ColorPickerFlags.DisplayRGB` @Override _display_ type among RGB/HSV/Hex. select any combination using one or more of RGB/HSV/Hex.
---| `ui.ColorPickerFlags.DisplayHSV` @Value: 2097152.
---| `ui.ColorPickerFlags.DisplayHex` @Value: 4194304.
---| `ui.ColorPickerFlags.UInt8` @Display values formatted as 0..255.
---| `ui.ColorPickerFlags.Float` @Display values formatted as 0.0f..1.0f floats instead of 0..255 integers. No round-trip of value via integers.
---| `ui.ColorPickerFlags.PickerHueBar` @Bar for Hue, rectangle for Sat/Value.
---| `ui.ColorPickerFlags.PickerHueWheel` @Wheel for Hue, triangle for Sat/Value.
ui.ColorPickerFlags = {
  None = 0, ---@type ui.ColorPickerFlags #Value: 0.
  NoAlpha = 2, ---@type ui.ColorPickerFlags #Ignore Alpha component (will only read 3 components from the input pointer).
  NoPicker = 4, ---@type ui.ColorPickerFlags #Disable picker when clicking on colored square.
  NoOptions = 8, ---@type ui.ColorPickerFlags #Disable toggling options menu when right-clicking on inputs/small preview.
  NoSmallPreview = 16, ---@type ui.ColorPickerFlags #Disable colored square preview next to the inputs. (e.g. to show only the inputs).
  NoInputs = 32, ---@type ui.ColorPickerFlags #Disable inputs sliders/text widgets (e.g. to show only the small preview colored square).
  NoTooltip = 64, ---@type ui.ColorPickerFlags #Disable tooltip when hovering the preview.
  NoLabel = 128, ---@type ui.ColorPickerFlags #Disable display of inline text label (the label is still forwarded to the tooltip and picker).
  NoSidePreview = 256, ---@type ui.ColorPickerFlags #Disable bigger color preview on right side of the picker, use small colored square preview instead.
  NoDragDrop = 512, ---@type ui.ColorPickerFlags #Disable drag and drop target. ColorButton: disable drag and drop source.
  AlphaBar = 65536, ---@type ui.ColorPickerFlags #Show vertical alpha bar/gradient in picker.
  AlphaPreview = 131072, ---@type ui.ColorPickerFlags #Display preview as a transparent color over a checkerboard, instead of opaque.
  AlphaPreviewHalf = 262144, ---@type ui.ColorPickerFlags #Display half opaque / half checkerboard, instead of opaque.
  DisplayRGB = 1048576, ---@type ui.ColorPickerFlags #Override _display_ type among RGB/HSV/Hex. select any combination using one or more of RGB/HSV/Hex.
  DisplayHSV = 2097152, ---@type ui.ColorPickerFlags #Value: 2097152.
  DisplayHex = 4194304, ---@type ui.ColorPickerFlags #Value: 4194304.
  UInt8 = 8388608, ---@type ui.ColorPickerFlags #Display values formatted as 0..255.
  Float = 16777216, ---@type ui.ColorPickerFlags #Display values formatted as 0.0f..1.0f floats instead of 0..255 integers. No round-trip of value via integers.
  PickerHueBar = 33554432, ---@type ui.ColorPickerFlags #Bar for Hue, rectangle for Sat/Value.
  PickerHueWheel = 67108864, ---@type ui.ColorPickerFlags #Wheel for Hue, triangle for Sat/Value.
}

---@alias ui.OnlineExtraFlags
---| `ui.OnlineExtraFlags.None` @Value: 0.
---| `ui.OnlineExtraFlags.Admin` @Feature will be available only to people signed up as admins with access to admin menu in that new chat app.
---| `ui.OnlineExtraFlags.Tool` @Instead of creating a modal popup blocking rest of UI, a tool would create a small window staying on screen continuously and be able to use rest of UI API there.
ui.OnlineExtraFlags = {
  None = 0, ---@type ui.OnlineExtraFlags #Value: 0.
  Admin = 1, ---@type ui.OnlineExtraFlags #Feature will be available only to people signed up as admins with access to admin menu in that new chat app.
  Tool = 2, ---@type ui.OnlineExtraFlags #Instead of creating a modal popup blocking rest of UI, a tool would create a small window staying on screen continuously and be able to use rest of UI API there.
}

---@alias ui.FileIcon.Style
---| `ui.FileIcon.Style.Small` @Value: 'S'.
---| `ui.FileIcon.Style.Large` @Value: 'L'.
ui.FileIcon.Style = {
  Small = 'S', ---@type ui.FileIcon.Style #Value: 'S'.
  Large = 'L', ---@type ui.FileIcon.Style #Value: 'L'.
}

---@alias ui.DWriteFont.Weight
---| `ui.DWriteFont.Weight.Thin` @- Thin (100).
---| `ui.DWriteFont.Weight.UltraLight` @- Ultra-light (200).
---| `ui.DWriteFont.Weight.Light` @- Light (300).
---| `ui.DWriteFont.Weight.SemiLight` @- Semi-light (350).
---| `ui.DWriteFont.Weight.Regular` @- Regular (400).
---| `ui.DWriteFont.Weight.Medium` @- Medium (500).
---| `ui.DWriteFont.Weight.SemiBold` @- Semi-bold (600).
---| `ui.DWriteFont.Weight.Bold` @- Bold (700).
---| `ui.DWriteFont.Weight.UltraBold` @- Ultra-bold (800).
---| `ui.DWriteFont.Weight.Black` @- Black (900).
---| `ui.DWriteFont.Weight.UltraBlack` @- Ultra-black (950).
ui.DWriteFont.Weight = {
  Thin = 'Thin', ---@type ui.DWriteFont.Weight #- Thin (100).
  UltraLight = 'UltraLight', ---@type ui.DWriteFont.Weight #- Ultra-light (200).
  Light = 'Light', ---@type ui.DWriteFont.Weight #- Light (300).
  SemiLight = 'SemiLight', ---@type ui.DWriteFont.Weight #- Semi-light (350).
  Regular = 'Regular', ---@type ui.DWriteFont.Weight #- Regular (400).
  Medium = 'Medium', ---@type ui.DWriteFont.Weight #- Medium (500).
  SemiBold = 'SemiBold', ---@type ui.DWriteFont.Weight #- Semi-bold (600).
  Bold = 'Bold', ---@type ui.DWriteFont.Weight #- Bold (700).
  UltraBold = 'UltraBold', ---@type ui.DWriteFont.Weight #- Ultra-bold (800).
  Black = 'Black', ---@type ui.DWriteFont.Weight #- Black (900).
  UltraBlack = 'UltraBlack', ---@type ui.DWriteFont.Weight #- Ultra-black (950).
}

---@alias ui.DWriteFont.Style
---| `ui.DWriteFont.Style.Normal` @- Charachers are upright in most fonts.
---| `ui.DWriteFont.Style.Italic` @- In italic style, characters are truly slanted and appear as they were designed.
---| `ui.DWriteFont.Style.Oblique` @- With oblique style characters are artificially slanted.
ui.DWriteFont.Style = {
  Normal = 'Normal', ---@type ui.DWriteFont.Style #- Charachers are upright in most fonts.
  Italic = 'Italic', ---@type ui.DWriteFont.Style #- In italic style, characters are truly slanted and appear as they were designed.
  Oblique = 'Oblique', ---@type ui.DWriteFont.Style #- With oblique style characters are artificially slanted.
}

---@alias ui.DWriteFont.Stretch
---| `ui.DWriteFont.Stretch.UltraCondensed` @Value: 'UltraCondensed'.
---| `ui.DWriteFont.Stretch.ExtraCondensed` @Value: 'ExtraCondensed'.
---| `ui.DWriteFont.Stretch.Condensed` @Value: 'Condensed'.
---| `ui.DWriteFont.Stretch.SemiCondensed` @Value: 'SemiCondensed'.
---| `ui.DWriteFont.Stretch.Medium` @Value: 'Medium'.
---| `ui.DWriteFont.Stretch.SemiExpanded` @Value: 'SemiExpanded'.
---| `ui.DWriteFont.Stretch.Expanded` @Value: 'Expanded'.
---| `ui.DWriteFont.Stretch.ExtraExpanded` @Value: 'ExtraExpanded'.
---| `ui.DWriteFont.Stretch.UltraExpanded` @Value: 'UltraExpanded'.
ui.DWriteFont.Stretch = {
  UltraCondensed = 'UltraCondensed', ---@type ui.DWriteFont.Stretch #Value: 'UltraCondensed'.
  ExtraCondensed = 'ExtraCondensed', ---@type ui.DWriteFont.Stretch #Value: 'ExtraCondensed'.
  Condensed = 'Condensed', ---@type ui.DWriteFont.Stretch #Value: 'Condensed'.
  SemiCondensed = 'SemiCondensed', ---@type ui.DWriteFont.Stretch #Value: 'SemiCondensed'.
  Medium = 'Medium', ---@type ui.DWriteFont.Stretch #Value: 'Medium'.
  SemiExpanded = 'SemiExpanded', ---@type ui.DWriteFont.Stretch #Value: 'SemiExpanded'.
  Expanded = 'Expanded', ---@type ui.DWriteFont.Stretch #Value: 'Expanded'.
  ExtraExpanded = 'ExtraExpanded', ---@type ui.DWriteFont.Stretch #Value: 'ExtraExpanded'.
  UltraExpanded = 'UltraExpanded', ---@type ui.DWriteFont.Stretch #Value: 'UltraExpanded'.
}

---@alias ac.PhysicsDebugLines
---| `ac.PhysicsDebugLines.None` @No special options.
---| `ac.PhysicsDebugLines.Tyres` @Tyres raycasting.
---| `ac.PhysicsDebugLines.WetSkidmarks` @Marks left by tyres reducing grip in rain.
---| `ac.PhysicsDebugLines.Script` @Lines drawn by custom physics script.
---| `ac.PhysicsDebugLines.CosmicBodies` @Outlines for extra bodies of cosmic suspensions.
---| `ac.PhysicsDebugLines.RainLane` @Alternative AI lane for rain.
ac.PhysicsDebugLines = {
  None = 0x0, ---@type ac.PhysicsDebugLines #No special options.
  Tyres = 0x1, ---@type ac.PhysicsDebugLines #Tyres raycasting.
  WetSkidmarks = 0x2, ---@type ac.PhysicsDebugLines #Marks left by tyres reducing grip in rain.
  Script = 0x4, ---@type ac.PhysicsDebugLines #Lines drawn by custom physics script.
  CosmicBodies = 0x8, ---@type ac.PhysicsDebugLines #Outlines for extra bodies of cosmic suspensions.
  RainLane = 0x10000, ---@type ac.PhysicsDebugLines #Alternative AI lane for rain.
}

---@alias ac.LightsDebugMode
---| `ac.LightsDebugMode.None` @No special options.
---| `ac.LightsDebugMode.Outline` @Value: 0x1.
---| `ac.LightsDebugMode.BoundingBox` @Value: 0x2.
---| `ac.LightsDebugMode.BoundingSphere` @Value: 0x4.
---| `ac.LightsDebugMode.Text` @Value: 0x8.
ac.LightsDebugMode = {
  None = 0x0, ---@type ac.LightsDebugMode #No special options.
  Outline = 0x1, ---@type ac.LightsDebugMode #Value: 0x1.
  BoundingBox = 0x2, ---@type ac.LightsDebugMode #Value: 0x2.
  BoundingSphere = 0x4, ---@type ac.LightsDebugMode #Value: 0x4.
  Text = 0x8, ---@type ac.LightsDebugMode #Value: 0x8.
}

---@alias ac.VRSRateMode
---| `ac.VRSRateMode.X0` @Value: 0.
---| `ac.VRSRateMode.X16` @Value: 1.
---| `ac.VRSRateMode.X8` @Value: 2.
---| `ac.VRSRateMode.X4` @Value: 3.
---| `ac.VRSRateMode.X2` @Value: 4.
---| `ac.VRSRateMode.X1` @Value: 5.
---| `ac.VRSRateMode.X1_2X1` @Value: 6.
---| `ac.VRSRateMode.X1_1X2` @Value: 7.
---| `ac.VRSRateMode.X1_2X2` @Value: 8.
---| `ac.VRSRateMode.X1_4X2` @Value: 9.
---| `ac.VRSRateMode.X1_2X4` @Value: 10.
---| `ac.VRSRateMode.X1_4X4` @Value: 11.
ac.VRSRateMode = {
  X0 = 0, ---@type ac.VRSRateMode #Value: 0.
  X16 = 1, ---@type ac.VRSRateMode #Value: 1.
  X8 = 2, ---@type ac.VRSRateMode #Value: 2.
  X4 = 3, ---@type ac.VRSRateMode #Value: 3.
  X2 = 4, ---@type ac.VRSRateMode #Value: 4.
  X1 = 5, ---@type ac.VRSRateMode #Value: 5.
  X1_2X1 = 6, ---@type ac.VRSRateMode #Value: 6.
  X1_1X2 = 7, ---@type ac.VRSRateMode #Value: 7.
  X1_2X2 = 8, ---@type ac.VRSRateMode #Value: 8.
  X1_4X2 = 9, ---@type ac.VRSRateMode #Value: 9.
  X1_2X4 = 10, ---@type ac.VRSRateMode #Value: 10.
  X1_4X4 = 11, ---@type ac.VRSRateMode #Value: 11.
}

---@alias ac.ScreenshotFormat
---| `ac.ScreenshotFormat.Auto` @As configured in AC system settings.
---| `ac.ScreenshotFormat.BMP` @Value: 1.
---| `ac.ScreenshotFormat.JPG` @Value: 2.
---| `ac.ScreenshotFormat.JPEG` @Value: 2.
---| `ac.ScreenshotFormat.PNG` @Value: 3.
---| `ac.ScreenshotFormat.DDS` @Value: 4.
ac.ScreenshotFormat = {
  Auto = 0, ---@type ac.ScreenshotFormat #As configured in AC system settings.
  BMP = 1, ---@type ac.ScreenshotFormat #Value: 1.
  JPG = 2, ---@type ac.ScreenshotFormat #Value: 2.
  JPEG = 2, ---@type ac.ScreenshotFormat #Value: 2.
  PNG = 3, ---@type ac.ScreenshotFormat #Value: 3.
  DDS = 4, ---@type ac.ScreenshotFormat #Value: 4.
}

---@alias ac.SceneTweakFlag
---| `ac.SceneTweakFlag.Default` @Value: 0.
---| `ac.SceneTweakFlag.ForceOn` @Value: 1.
---| `ac.SceneTweakFlag.ForceOff` @Value: 2.
ac.SceneTweakFlag = {
  Default = 0, ---@type ac.SceneTweakFlag #Value: 0.
  ForceOn = 1, ---@type ac.SceneTweakFlag #Value: 1.
  ForceOff = 2, ---@type ac.SceneTweakFlag #Value: 2.
}

---@alias ac.CarControlsInput.Flag
---| `ac.CarControlsInput.Flag.Skip` @Value: -1.
---| `ac.CarControlsInput.Flag.Disable` @Value: 0.
---| `ac.CarControlsInput.Flag.Enable` @Value: 1.
ac.CarControlsInput.Flag = {
  Skip = -1, ---@type ac.CarControlsInput.Flag #Value: -1.
  Disable = 0, ---@type ac.CarControlsInput.Flag #Value: 0.
  Enable = 1, ---@type ac.CarControlsInput.Flag #Value: 1.
}

---If any type restriction is set, binding will be shown as empty if there is no device fitting the restriction bound. If no type---restriction is set, any input device can be bound overriding all previously configured boundaries, or multiple bindings can be added---with a popup menu.
---@alias ui.ControlButtonControlFlags
---| `ui.ControlButtonControlFlags.None` @Value: 0.
---| `ui.ControlButtonControlFlags.Keyboard` @Type restriction: keyboard only.
---| `ui.ControlButtonControlFlags.Gamepad` @Type restriction: gamepad only.
---| `ui.ControlButtonControlFlags.Controllers` @Type restriction: controllers only.
---| `ui.ControlButtonControlFlags.NoKeyboard` @Type restriction: gamepad or controllers depending on input mode.
---| `ui.ControlButtonControlFlags.IgnoreConflicts` @Do not check if anything else in “controls.ini” is already using the input.
---| `ui.ControlButtonControlFlags.SingleEntry` @Don’t show multiple devices if bound, only a single one, remove other devices on bounding.
---| `ui.ControlButtonControlFlags.AlterRealConfig` @Copy changes to original presets with car-specific controls or presets-per-mode active (use it if your button is more of a global one, not relating to currently selected car).
---| `ui.ControlButtonControlFlags.NoDeleteUnbound` @Don’t unbound inputs by hovering button and pressing Delete.
---| `ui.ControlButtonControlFlags.NoContextMenu` @Use this flag if you want to add your own context menu.
---| `ui.ControlButtonControlFlags.NoHoldSwitch` @Don’t draw hold switch even if button should have one.
ui.ControlButtonControlFlags = {
  None = 0, ---@type ui.ControlButtonControlFlags #Value: 0.
  Keyboard = 1, ---@type ui.ControlButtonControlFlags #Type restriction: keyboard only.
  Gamepad = 2, ---@type ui.ControlButtonControlFlags #Type restriction: gamepad only.
  Controllers = 4, ---@type ui.ControlButtonControlFlags #Type restriction: controllers only.
  NoKeyboard = 6, ---@type ui.ControlButtonControlFlags #Type restriction: gamepad or controllers depending on input mode.
  IgnoreConflicts = 16, ---@type ui.ControlButtonControlFlags #Do not check if anything else in “controls.ini” is already using the input.
  SingleEntry = 32, ---@type ui.ControlButtonControlFlags #Don’t show multiple devices if bound, only a single one, remove other devices on bounding.
  AlterRealConfig = 64, ---@type ui.ControlButtonControlFlags #Copy changes to original presets with car-specific controls or presets-per-mode active (use it if your button is more of a global one, not relating to currently selected car).
  NoDeleteUnbound = 128, ---@type ui.ControlButtonControlFlags #Don’t unbound inputs by hovering button and pressing Delete.
  NoContextMenu = 256, ---@type ui.ControlButtonControlFlags #Use this flag if you want to add your own context menu.
  NoHoldSwitch = 512, ---@type ui.ControlButtonControlFlags #Don’t draw hold switch even if button should have one.
}

---FFB (phase 1), FFB (phase 2), damper.
---@return boolean, boolean, boolean
function ac.getFFBTweaksReport() end

---@param value number @Local timestamp, doesn’t have to point to 00:00 time.
function ac.setNeutralSunTrajectoryTimestamp(value) end

---Can be called only within render context (otherwise returns `false`). Checks if given point is within current camera frustum. For checking if something
---is within the main camera instead, try `ac.isVisibleInMainCamera()`.
---@param center vec3
---@param radius number
---@param gSpace boolean? @Pass `false` if your coordinates are in world-space rather than with origin shift applied (in most cases, you need to use `false`, this argument is added for backwards compatibility. Default value: `true`.
---@param includeFarPlane boolean? @Pass `false` to ignore far plane. Default value: `true`.
---@return boolean
function render.isVisible(center, radius, gSpace, includeFarPlane) end

---@param mode render.BlendMode
function render.setBlendMode(mode) end

---@param mode render.CullMode
function render.setCullMode(mode) end

---@param mode render.DepthMode
function render.setDepthMode(mode) end

---@param color rgbm
function render.glSetColor(color) end

---@param primitiveType render.GLPrimitiveType
function render.glBegin(primitiveType) end

---@param v vec3
function render.glVertex(v) end

---@param v vec3
---@param uv number|vec2
function render.glVertexTextured(v, uv) end

---@param filename string
function render.glTexture(filename) end

function render.glEnd() end

---Draws a simple circle othrogonal to `dir` direction using an optimized shader.
---@param pos vec3
---@param dir vec3
---@param radius number
---@param color rgbm? @Default value: `rgbm.colors.white`.
---@param borderColor rgbm|nil @Optional different color to use close to the border. Default value: `nil`.
function render.circle(pos, dir, radius, color, borderColor) end

---Draws a simple rectangle othrogonal to `dir` direction using an optimized shader.
---@param pos vec3
---@param dir vec3
---@param width number
---@param height number
---@param color rgbm? @Default value: `rgbm.colors.white`.
function render.rectangle(pos, dir, width, height, color) end

---Draws a simple quad from four points.
---@param p1 vec3
---@param p2 vec3
---@param p3 vec3
---@param p4 vec3
---@param color rgbm? @Default value: `rgbm.colors.white`.
---@param texture string|nil @Default value: `nil`.
function render.quad(p1, p2, p3, p4, color, texture) end

---@param pos vec3
---@param text string
---@param color rgbm? @Default value: `rgbm.colors.white`.
---@param scale number? @Default value: 1.
---@param align render.FontAlign? @Default value: `render.FontAlign.Center`.
function render.debugText(pos, text, color, scale, align) end

---@param center vec3
---@param radius number
---@param color rgbm? @Default value: `rgbm(3, 0, 0, 1)`.
function render.debugSphere(center, radius, color) end

---@param center vec3
---@param size number
---@param color rgbm? @Default value: `rgbm(3, 0, 0, 1)`.
function render.debugCross(center, size, color) end

---@param center vec3
---@param size vec3
---@param color rgbm? @Default value: `rgbm(3, 0, 0, 1)`.
function render.debugBox(center, size, color) end

---@param center vec3
---@param size number
---@param color rgbm? @Default value: `rgbm(3, 0, 0, 1)`.
function render.debugPoint(center, size, color) end

---@param center vec3
---@param dir vec3
---@param color rgbm? @Default value: `rgbm(3, 0, 0, 1)`.
---@param size number? @Default value: 1.
function render.debugPlane(center, dir, color, size) end

---@param from vec3
---@param to vec3
---@param color rgbm? @Default value: `rgbm(3, 0, 0, 1)`.
---@param colorEnd rgbm|nil @Default value: `nil`.
function render.debugLine(from, to, color, colorEnd) end

---@param from vec3
---@param to vec3
---@param size number? @Default value: -1.
---@param color rgbm? @Default value: `rgbm(3, 0, 0, 1)`.
---@param colorEnd rgbm|nil @Default value: `nil`.
function render.debugArrow(from, to, size, color, colorEnd) end

---@return vec2
function render.getRenderTargetSize() end

---@return boolean
function render.backupRenderTarget() end

---@return boolean
function render.restoreRenderTarget() end

---Called when shadow maps and reflection cubemap are updated, but main render has not started yet. Great time to render any scene-dependant geometry shots.
---@param callback fun()
---@return ac.Disposable
function render.onSceneReady(callback) end

---Called when AC is drawing something.
---
--- Special aspects:
--- - `main.hud.vr`: if first argument is `true`, HUD is rendered after post-processing (or post-processing is disabled), so things you draw have to be in 0…1 space. Return `true` to hide original HUD.
---@param eventName 'main.root.opaque'|'main.track.opaque'|'main.root.transparent'|'main.track.transparent'|'mirror.track.opaque'|'mirror.root.transparent'|'shadow.root'|'main.hud.vr'
---@param callback fun(): boolean?
---@return ac.Disposable
function render.on(eventName, callback) end

---Projects world point onto a screen (taking into account UV scale unless second argument is set to `false`).
---@param pos vec3
---@param faceID render.ProjectFace? @Default value: `render.ProjectFace.Auto`.
---@return vec2 @Returns vector with `inf` for values if point is outside of screen.
function render.projectPoint(pos, faceID) end

---Create a ray going from a given position along given direction.
---@param pos vec3 @Position in world coordinates.
---@param dir vec3 @Normalized direction vector.
---@param length number? @By default, ray doesn’t have a length limit. Default value: -1.
---@return ray
function render.createRay(pos, dir, length) end

---Create a ray going from camera in the direction of mouse position. Helpful if you want to do something like a mouse picker. Doesn’t have a length limit.
---@return ray
function render.createMouseRay() end

---Create a ray going from camera in the direction of an onscreen point. Doesn’t have a length limit.
---@param onscreenPoint number|vec2 @Point onscreen in pixels (don’t forget to multiply by `ac.getUI().uiScale` if you’re using IMGUI coordinates).
---@return ray
function render.createPointRay(onscreenPoint) end

---@return boolean
function render.isPositioningHelperBusy() end

---It’s safer to use `ui.toolWindow()`: a wrapper that would ensure UI wouldn’t break even if Lua script would crash midway for any reason.
---@param windowID string
---@param pos number|vec2
---@param size number|vec2
---@param noPadding boolean? @Default value: `false`.
---@param inputs boolean? @Default value: `false`.
function ui.beginToolWindow(windowID, pos, size, noPadding, inputs) end

function ui.endToolWindow() end

---It’s safer to use `ui.transparentWindow()`: a wrapper that would ensure UI wouldn’t break even if Lua script would crash midway for any reason.
---@param windowID string
---@param pos number|vec2
---@param size number|vec2
---@param noPadding boolean? @Default value: `false`.
---@param inputs boolean? @Default value: `false`.
function ui.beginTransparentWindow(windowID, pos, size, noPadding, inputs) end

function ui.bringWindowToFront() end

function ui.endTransparentWindow() end

---Adds hyperlink effect to the previous item, returns `true` if it’s clicked.
---@param hyperlinkColor rgbm? @Default value: `rgbm(0, 0.5, 1, 1)`.
---@return boolean
function ui.itemHyperlink(hyperlinkColor) end

---@param text string
function ui.text(text) end

---@param text string
---@param hyperlinkColor rgbm? @Default value: `rgbm(0, 0.5, 1, 1)`.
---@return boolean
function ui.textHyperlink(text, hyperlinkColor) end

---@param text string
---@param alignment number|vec2
---@param size number|vec2? @Default value: `vec2(0, 0)`.
---@param ellipsis boolean? @Default value: `false`.
function ui.textAligned(text, alignment, size, ellipsis) end

---@param text string
---@param wrapPos number? @Default value: 0.
function ui.textWrapped(text, wrapPos) end

---@param text string
---@param color rgbm? @Default value: `rgbm.colors.white`.
function ui.textColored(text, color) end

---Display text and label aligned the same way as value and label widgets.
---@param label string
---@param text string
function ui.labelText(label, text) end

---Shortcut for pushing disabled text color, drawing text and popping it back;.
---@param text string
function ui.textDisabled(text) end

---Returns `true` if 24×24 icon with such ID is known.
---@param iconID ui.Icons
---@return boolean
function ui.isKnownIcon24(iconID) end

---Draws an icon, universal function (great for creating customizable components). Icon can be:
---- An 24×24 icon ID set as is;
---- A country code for a small flag with padding to fit a square;
---- An 32×32 icon ID with “32:” prefix;
---- An 64×64 icon ID with “64:” prefix;
---- An 256×256 icon ID with “XL:” prefix;
---- A large rectangular flag with no padding with “XS:” prefix;
---- An emoticon with “em:” prefix;
---- An icon from an atlas: use “at:FILENAME\nX1,Y1,X2,Y2” format, where X… and Y… are UV coordinates (`ui.atlasIconID()` can help with generating those IDs);
---- A regular image: just pass a path as a string (also works with extra canvases, media elements and such).
---@param iconID ui.Icons
---@param size number|vec2
---@param tintCol rgbm? @Default value: `rgbm.colors.white`.
---@param iconSize number|vec2|nil @If set, icon will be this size, but item will be larger (use it if you need to fill an area without stretching an icon). Default value: `nil`.
function ui.icon(iconID, size, tintCol, iconSize) end

---Adds an icon to the previously drawn element.
---@param iconID ui.Icons
---@param size number|vec2 @Size of an icon.
---@param alignment number|vec2 @Alignment of an icon relative to the element.
---@param colorOpt rgbm|nil @If not set, uses text color by default. Default value: `nil`.
---@param padding number|vec2|nil @If not set, uses frame padding by default. Default value: `nil`.
function ui.addIcon(iconID, size, alignment, colorOpt, padding) end

---Draws a 24×24 icon. Use universal `ui.icon()` instead.
---@deprecated
---@param iconID ui.Icons
---@param size number|vec2
---@param tintCol rgbm? @Default value: `rgbm.colors.white`.
function ui.icon24(iconID, size, tintCol) end

---Draws a 32×32 icon. Use universal `ui.icon()` instead.
---@deprecated
---@param iconID ui.Icons
---@param size number|vec2
---@param tintCol rgbm? @Default value: `rgbm.colors.white`.
function ui.icon32(iconID, size, tintCol) end

---Draws a 64×64 icon. Use universal `ui.icon()` instead.
---@deprecated
---@param iconID ui.Icons
---@param size number|vec2
---@param tintCol rgbm? @Default value: `rgbm.colors.white`.
function ui.icon64(iconID, size, tintCol) end

---Draws a flag. Use universal `ui.icon()` instead.
---@deprecated
---@param iconID ui.Icons
---@param size number|vec2
---@param tintCol rgbm? @Default value: `rgbm.colors.white`.
function ui.flag(iconID, size, tintCol) end

---@return vec2
function ui.getCursor() end

---@param v number|vec2
function ui.setCursor(v) end

---@param v number|vec2
function ui.offsetCursor(v) end

---@return number
function ui.getCursorX() end

---@param v number
function ui.setCursorX(v) end

---@return number
function ui.getCursorY() end

---@param v number
function ui.setCursorY(v) end

---@param v number
function ui.offsetCursorX(v) end

---@param v number
function ui.offsetCursorY(v) end

---@param offsetFromStart number? @Default value: 0.
---@param spacing number? @Default value: -1.
function ui.sameLine(offsetFromStart, spacing) end

function ui.backupCursor() end

function ui.restoreCursor() end

---@return number
function ui.getMaxCursorX() end

---@return number
function ui.getMaxCursorY() end

---Set maximum cursor value used for estimating amount of content. Use very carefully.
---@param v number
function ui.setMaxCursorX(v) end

---Set maximum cursor value used for estimating amount of content. Use very carefully.
---@param v number
function ui.setMaxCursorY(v) end

---@param spacing number? @If non-negative, value is used for space between lines instead of regular item spacing from current style. Default value: -1.
function ui.newLine(spacing) end

---Lock horizontal starting position and capture group bounding box into one “item” (so you can use `ui.itemHovered()` or layout primitives such as `ui.sameLine()` on whole group, etc.)
---@param width number? @Default value: 0.
function ui.beginGroup(width) end

---Unlock horizontal starting position and capture the whole group bounding box into one “item” (so you can use `ui.itemHovered()` or layout primitives such as `ui.sameLine()` on whole group, etc.)
function ui.endGroup() end

---@return number
function ui.availableSpaceX() end

---@return number
function ui.availableSpaceY() end

---@return vec2
function ui.availableSpace() end

---Returns image size, or zeroes if image is missing or not yet ready.
---@param imageSource ui.ImageSource @Path to the image, absolute or relative to script folder or AC root. URLs are also accepted.
---@return vec2
function ui.imageSize(imageSource) end

---Imports image from its binary data. Any formats supported by system are supported. Also, new DDS formats are supported as well. Result is cached,
---so subsequent calls don’t take a lot of time. Data string can contain zero bytes.
---
---To clear cached image and free memory, pass returned value to `ui.unloadImage()`.
---@param data binary
---@return string?
function ui.decodeImage(data) end

---Simply draws an image on canvas without adding a new item or progressing cursor. Current cursor position is not taken
---into consideration either. To add an image as an element, use `ui.image()`.
---
---When drawing multiple images, consider combining all of them in a single atlas texture, it would improve performance.
---
---Note: if you’re using asyncronous loading (see `ui.setAsynchronousImagesLoading()`) and want to make sure image is
---ready before drawing, use `ui.isImageReady()`. If image is not yet ready, transparent texture will be used instead.
---@overload fun(imageSource: ui.ImageSource, p1: vec2, p2: vec2, uv1: vec2, uv2: vec2, mode: ui.ImageFit)
---@overload fun(imageSource: ui.ImageSource, p1: vec2, p2: vec2, mode: ui.ImageFit)
---@param imageSource ui.ImageSource @Path to the image, absolute or relative to script folder or AC root. URLs are also accepted.
---@param p1 number|vec2 @Position of upper left corner relative to current working area (scriptable texture or IMGUI window).
---@param p2 number|vec2 @Position of bottom right corner relative to current working area (scriptable texture or IMGUI window).
---@param color rgbm? @Tint of the image, with white it would be drawn as it is. Default value: `rgbm.colors.white`.
---@param uv1 number|vec2? @Texture coordinates for upper left corner. Default value: `vec2(0, 0)`.
---@param uv2 number|vec2? @Texture coordinates for bottom right corner. Default value: `vec2( 1, 1 )`.
---@param mode ui.ImageFit? @Stretch mode. Default value: `ui.ImageFit.Stretch`.
function ui.drawImage(imageSource, p1, p2, color, uv1, uv2, mode) end

---Draws an icon without moving cursor, universal function (great for creating customizable components). Icon can be:
---- An 24×24 icon ID set as is;
---- A country code for a small flag with padding to fit a square;
---- An 32×32 icon ID with “32:” prefix;
---- An 64×64 icon ID with “64:” prefix;
---- An 256×256 icon ID with “XL:” prefix;
---- A large rectangular flag with no padding with “XS:” prefix;
---- An emoticon with “em:” prefix;
---- An icon from an atlas: use “at:FILENAME\nX1,Y1,X2,Y2” format, where X… and Y… are UV coordinates (`ui.atlasIconID()` can help with generating those IDs);
---- A regular image: just pass a path as a string (also works with extra canvases, media elements and such).
---@param iconID ui.Icons
---@param p1 number|vec2 @Position of upper left corner relative to current working area (scriptable texture or IMGUI window).
---@param p2 number|vec2 @Position of bottom right corner relative to current working area (scriptable texture or IMGUI window).
---@param color rgbm? @Default value: `rgbm.colors.white`.
function ui.drawIcon(iconID, p1, p2, color) end

---Draw loading animation spinner. Actual shape might change in the future versions.
---@param p1 number|vec2 @Position of upper left corner relative to current working area (scriptable texture or IMGUI window).
---@param p2 number|vec2 @Position of bottom right corner relative to current working area (scriptable texture or IMGUI window).
---@param color rgbm? @Tint of the animation. Default value: `rgbm.colors.white`.
function ui.drawLoadingSpinner(p1, p2, color) end

---Draws an image with rounded corners on canvas without adding a new item or progressing cursor. Current cursor position is not taken
---into consideration either. To add an image as an element, use `ui.image()`.
---
---When drawing multiple images, consider combining all of them in a single atlas texture, it would improve performance.
---
---Note: if you’re using asyncronous loading (see `ui.setAsynchronousImagesLoading()`) and want to make sure image is
---ready before drawing, use `ui.isImageReady()`. If image is not yet ready, transparent texture will be used instead.
---@overload fun(imageSource: ui.ImageSource, p1: vec2, p2: vec2, uv1: vec2, uv2: vec2, rounding: number, corners: ui.CornerFlags)
---@overload fun(imageSource: ui.ImageSource, p1: vec2, p2: vec2, rounding: number, corners: ui.CornerFlags)
---@param imageSource ui.ImageSource @Path to the image, absolute or relative to script folder or AC root. URLs are also accepted.
---@param p1 number|vec2 @Position of upper left corner relative to current working area (scriptable texture or IMGUI window).
---@param p2 number|vec2 @Position of bottom right corner relative to current working area (scriptable texture or IMGUI window).
---@param color rgbm? @Tint of the image, with white it would be drawn as it is. Default value: `rgbm.colors.white`.
---@param uv1 number|vec2? @Texture coordinates for upper left corner. Default value: `vec2(0, 0)`.
---@param uv2 number|vec2? @Texture coordinates for bottom right corner. Default value: `vec2( 1, 1 )`.
---@param rounding number? @Rounding radius in pixels. Default value: 1.
---@param corners ui.CornerFlags? @Corners to round. Default value: `ui.CornerFlags.All`.
function ui.drawImageRounded(imageSource, p1, p2, color, uv1, uv2, rounding, corners) end

---Draws a custom quad with a texture.
---
---Note: if you’re using asyncronous loading (see `ui.setAsynchronousImagesLoading()`) and want to make sure image is
---ready before drawing, use `ui.isImageReady()`. If image is not yet ready, transparent texture will be used instead.
---@overload fun(imageSource: ui.ImageSource, p1: vec2, p2: vec2, p3: vec2, p4: vec2, uv1: vec2, uv2: vec2, uv3: vec2, uv4: vec2)
---@param imageSource ui.ImageSource @Path to the image, absolute or relative to script folder or AC root. URLs are also accepted.
---@param p1 number|vec2 @Position of first corner relative to current working area (scriptable texture or IMGUI window).
---@param p2 number|vec2 @Position of second corner relative to current working area (scriptable texture or IMGUI window).
---@param p3 number|vec2 @Position of third corner relative to current working area (scriptable texture or IMGUI window).
---@param p4 number|vec2 @Position of fourth corner relative to current working area (scriptable texture or IMGUI window).
---@param color rgbm? @Tint of the image, with white it would be drawn as it is. Default value: `rgbm.colors.white`.
---@param uv1 number|vec2? @Texture coordinates for first corner. Default value: `vec2(0, 0)`.
---@param uv2 number|vec2? @Texture coordinates for second corner. Default value: `vec2( 1, 0 )`.
---@param uv3 number|vec2? @Texture coordinates for third corner. Default value: `vec2( 1, 1 )`.
---@param uv4 number|vec2? @Texture coordinates for fourth corner. Default value: `vec2( 0, 1 )`.
function ui.drawImageQuad(imageSource, p1, p2, p3, p4, color, uv1, uv2, uv3, uv4) end

---@param p1 number|vec2
---@param p2 number|vec2
---@param p3 number|vec2
---@param p4 number|vec2
---@param color rgbm? @Default value: `rgbm.colors.white`.
function ui.drawQuadFilled(p1, p2, p3, p4, color) end

---@param p1 number|vec2
---@param p2 number|vec2
---@param p3 number|vec2
---@param p4 number|vec2
---@param color rgbm? @Default value: `rgbm.colors.white`.
function ui.drawQuad(p1, p2, p3, p4, color) end

---Marks start of texture shading. All geometry drawn between this call and `ui.endTextureShade()` will have texture applied to it.
---
---Note: this feature only works with geometrical shapes, like quads, triangles, circles or things drawn with `ui.path…` functions.
---It can’t be applied to text, for example: text already uses its own texture.
---@param imageSource ui.ImageSource @Path to the image, absolute or relative to script folder or AC root. URLs are also accepted.
function ui.beginTextureShade(imageSource) end

---Finishes texture shading. All geometry drawn between `ui.beginTextureShade()` and this call will have texture applied to it.
--- Note: this feature only works with geometrical shapes, like quads, triangles, circles or things drawn with `ui.path…` functions.
--- It can’t be applied to text, for example: text already uses its own texture.
--- @overload fun(p1: vec2, p2: vec2, clamp: boolean)
---@param p1 number|vec2 @Position within current working area that will get `uv1` texture coordinate.
---@param p2 number|vec2 @Position within current working area that will get `uv2` texture coordinate.
---@param uv1 number|vec2? @Texture coordinate for `p1` position (texture will be interpolated between linearly). Default value: `vec2(0, 0)`.
---@param uv2 number|vec2? @Texture coordinate for `p2` position (texture will be interpolated between linearly). Default value: `vec2( 1, 1 )`.
---@param clamp boolean? @If set to `true`, texture will be clamped to boundaries (if there are vertices outside). Otherwise, texture will be repeated. Default value: `true`.
function ui.endTextureShade(p1, p2, uv1, uv2, clamp) end

function ui.beginGradientShade() end

---@param p1 number|vec2
---@param p2 number|vec2
---@param col1 rgbm? @Default value: `rgbm.colors.white`.
---@param col2 rgbm? @Default value: `rgbm.colors.white`.
---@param useAlpha boolean? @Set to `true` to use alpha of gradient colors as a multiplier to existing alpha. Default value: `false`.
function ui.endGradientShade(p1, p2, col1, col2, useAlpha) end

---@param p1 number|vec2
---@param p2 number|vec2
---@param intersectWithExisting boolean? @Default value: `true`.
function ui.pushClipRect(p1, p2, intersectWithExisting) end

---Pretty much fully disables clipping until next `ui.popClipRect()` call.
function ui.pushClipRectFullScreen() end

---@return boolean
function ui.popClipRect() end

---@param p1 number|vec2
---@param p2 number|vec2
---@param color rgbm
---@param rounding number? @Default value: 0.
---@param roundingFlags ui.CornerFlags? @Default value: `ui.CornerFlags.All`.
---@param thickness number? @Default value: 1.
function ui.drawRect(p1, p2, color, rounding, roundingFlags, thickness) end

---@param p1 number|vec2
---@param p2 number|vec2
---@param color rgbm
---@param rounding number? @Default value: 0.
---@param roundingFlags ui.CornerFlags? @Default value: `ui.CornerFlags.All`.
function ui.drawRectFilled(p1, p2, color, rounding, roundingFlags) end

---@param p1 number|vec2
---@param p2 number|vec2
---@param colorTopLeft rgbm
---@param colorTopRight rgbm
---@param colorBottomRight rgbm
---@param colorBottomLeft rgbm
function ui.drawRectFilledMultiColor(p1, p2, colorTopLeft, colorTopRight, colorBottomRight, colorBottomLeft) end

---To quickly draw series of lines and arcs, add points with `ui.PathLineTo()` and `ui.pathArcTo()`, and then finish with `ui.pathStroke()`.
---To quickly draw horizontal or vertical lines, consider using  `ui.drawSimpleLine()` instead.
---@param p1 number|vec2
---@param p2 number|vec2
---@param color rgbm
---@param thickness number? @Default value: 1.
function ui.drawLine(p1, p2, color, thickness) end

---Draws line without any antialiasing the fastest way, good for horizontal or vertical lines.
---@param p1 number|vec2
---@param p2 number|vec2
---@param color rgbm
---@param thickness number? @Default value: 1.
function ui.drawSimpleLine(p1, p2, color, thickness) end

---To quickly draw series of lines and arcs, add points with `ui.PathLineTo()` and `ui.pathArcTo()`, and then finish with `ui.pathStroke()`.
---@param p1 number|vec2
---@param p2 number|vec2
---@param p3 number|vec2
---@param p4 number|vec2
---@param color rgbm
---@param thickness number? @Default value: 1.
function ui.drawBezierCurve(p1, p2, p3, p4, color, thickness) end

---@param p1 number|vec2
---@param radius number
---@param color rgbm
---@param numSegments integer? @Default value: 12.
---@param thickness number? @Default value: 1.
function ui.drawCircle(p1, radius, color, numSegments, thickness) end

---@param p1 number|vec2
---@param radius number
---@param color rgbm
---@param numSegments integer? @Default value: 12.
function ui.drawCircleFilled(p1, radius, color, numSegments) end

---@param p1 number|vec2
---@param radius number|vec2
---@param color rgbm
---@param numSegments integer? @Default value: 12.
function ui.drawEllipseFilled(p1, radius, color, numSegments) end

---@param p1 number|vec2
---@param p2 number|vec2
---@param p3 number|vec2
---@param color rgbm
---@param thickness number? @Default value: 1.
function ui.drawTriangle(p1, p2, p3, color, thickness) end

---@param p1 number|vec2
---@param p2 number|vec2
---@param p3 number|vec2
---@param color rgbm? @Default value: `rgbm.colors.white`.
function ui.drawTriangleFilled(p1, p2, p3, color) end

---Draws text in given position without advancing cursor or anything like that. Faster option. Returns updated X position.
---@param text string
---@param pos number|vec2
---@param color rgbm? @Default value: `rgbm.colors.white`.
---@return number
function ui.drawText(text, pos, color) end

---Draws TTF text in given position without advancing cursor or anything like that. Faster option.
---@param text string
---@param fontSize number
---@param pos number|vec2
---@param color rgbm? @Default value: `rgbm.colors.white`.
function ui.dwriteDrawText(text, fontSize, pos, color) end

---Draws text in a given rect with clipping and optional alignment without advancing cursor or anything like that. Faster option.
---@param text string
---@param posMin number|vec2
---@param posMax number|vec2
---@param color rgbm? @Default value: `rgbm.colors.white`.
---@param alignment number|vec2? @Default value: `vec2(0, 0)`.
---@param ellipsis boolean? @Default value: `false`.
---@return number
function ui.drawTextClipped(text, posMin, posMax, color, alignment, ellipsis) end

---Draws TTF text in a given rect with clipping and optional alignment without advancing cursor or anything like that. Faster option.
---@param text string
---@param fontSize number
---@param posMin number|vec2
---@param posMax number|vec2
---@param horizontalAligment ui.Alignment? @`ui.Alignment.Start` for left, `ui.Alignment.Center` for middle, `ui.Alignment.End` for right. Default value: `ui.Alignment.Center`.
---@param verticalAlignment ui.Alignment? @`ui.Alignment.Start` for top, `ui.Alignment.Center` for middle, `ui.Alignment.End` for bottom. Default value: `ui.Alignment.Center`.
---@param allowWordWrapping boolean? @Default value: `false`.
---@param color rgbm? @Default value: `rgbm.colors.white`.
function ui.dwriteDrawTextClipped(text, fontSize, posMin, posMax, horizontalAligment, verticalAlignment, allowWordWrapping, color) end

---Clears current path. Not really needed in common scenarios: to start a new path, simply use any of
---path-adding functions such as `ui.pathLineTo()` or `ui.pathArcTo()`, to finish path and draw a shape use
---either `ui.pathFillConvex()` or `ui.pathStroke()` and it would clear path for the next shape automatically.
function ui.pathClear() end

---Adds a line segment to current path.
---Don’t forget to finish shape with either `ui.pathFillConvex()` or `ui.pathStroke()`.
---@param pos number|vec2
function ui.pathLineTo(pos) end

---Adds a line segment to current path, but only if position is different from current path point position.
---Don’t forget to finish shape with either `ui.pathFillConvex()` or `ui.pathStroke()`.
---@param pos number|vec2
function ui.pathLineToMergeDuplicate(pos) end

---@param color rgbm
function ui.pathFillConvex(color) end

---@param color rgbm
---@param closed boolean? @Default value: `false`.
---@param thickness number? @Default value: 1.
function ui.pathStroke(color, closed, thickness) end

---Finishes path and draws it without antialiasing. Faster and with pixelated lines.
---@param color rgbm
---@param closed boolean? @Default value: `false`.
---@param thickness number? @Default value: 1.
function ui.pathSimpleStroke(color, closed, thickness) end

---Finishes path with an alternative antialiasing approach, good for 1 pixel wide lines often changing direction (like a graph).
---@param color rgbm
---@param closed boolean? @Default value: `false`.
---@param thickness number? @Default value: 1.
function ui.pathSmoothStroke(color, closed, thickness) end

---Adds an arc defined by its center, radius and starting and finishing angle to current path.
---Don’t forget to finish shape with either `ui.pathFillConvex()` or `ui.pathStroke()`.
---@param center number|vec2
---@param radius number
---@param angleFrom number
---@param angleTo number
---@param numSegments integer? @Default value: 10.
function ui.pathArcTo(center, radius, angleFrom, angleTo, numSegments) end

---Adds “squished” arc to current path, like an arc of axis-aligned ellipse rather than an arc of a circle.
---Don’t forget to finish shape with either `ui.pathFillConvex()` or `ui.pathStroke()`.
---@param center number|vec2
---@param radius number|vec2
---@param angleFrom number
---@param angleTo number
---@param numSegments integer? @Default value: 10.
function ui.pathUnevenArcTo(center, radius, angleFrom, angleTo, numSegments) end

---Adds arc with radius at the end different from radius at the beginning.
---Don’t forget to finish shape with either `ui.pathFillConvex()` or `ui.pathStroke()`.
---@param center number|vec2
---@param radiusFrom number
---@param radiusTo number
---@param angleFrom number
---@param angleTo number
---@param numSegments integer? @Default value: 10.
function ui.pathVariableArcTo(center, radiusFrom, radiusTo, angleFrom, angleTo, numSegments) end

---Uses precomputed angles for a 12 steps circle.
---@param center number|vec2
---@param radius number
---@param angleMinOf_12 integer
---@param angleMaxOf_12 integer
function ui.pathArcToFast(center, radius, angleMinOf_12, angleMaxOf_12) end

---Adds a bezier curve to current path.
---Don’t forget to finish shape with either `ui.pathFillConvex()` or `ui.pathStroke()`.
---@param p1 number|vec2
---@param p2 number|vec2
---@param p3 number|vec2
---@param numSegments integer? @Default value: 0.
function ui.pathBezierCurveTo(p1, p2, p3, numSegments) end

---@param rectMin number|vec2
---@param rectMax number|vec2
---@param rounding number? @Default value: 0.
---@param roundingCorners ui.CornerFlags? @Default value: `ui.CornerFlags.All`.
function ui.pathRect(rectMin, rectMax, rounding, roundingCorners) end

---Adds a rect to a glowing layer used for styling. All shapes in there are going to be blurred, so just drop something around active element to highlight it.
---@param p1 number|vec2
---@param p2 number|vec2
---@param color rgbm
---@param noClip boolean? @Default value: `false`.
function ui.glowRectFilled(p1, p2, color, noClip) end

---Adds a circle to a glowing layer used for styling. All shapes in there are going to be blurred, so just drop something around active element to highlight it.
---@param p1 number|vec2
---@param radius number
---@param color rgbm
---@param noClip boolean? @Default value: `false`.
function ui.glowCircleFilled(p1, radius, color, noClip) end

---Adds an ellipse to a glowing layer used for styling. All shapes in there are going to be blurred, so just drop something around active element to highlight it.
---@param p1 number|vec2
---@param radius number|vec2
---@param color rgbm
---@param noClip boolean? @Default value: `false`.
function ui.glowEllipseFilled(p1, radius, color, noClip) end

---Returns number of draw command in current IMGUI drawing context. Each command is its own draw call.
---@return integer
function ui.getDrawCommandsCount() end

function ui.beginTextureSaturationAdjustment() end

---@param value number
function ui.endTextureSaturationAdjustment(value) end

function ui.beginPremultipliedAlphaTexture() end

function ui.endPremultipliedAlphaTexture() end

function ui.beginOutline() end

---@param color rgbm
---@param scale number? @Default value: 1.
function ui.endOutline(color, scale) end

function ui.beginSharpening() end

---@param sharpening number? @Default value: 1.
function ui.endSharpening(sharpening) end

function ui.beginMIPBias() end

---@param bias number? @Default value: 0.
---@param useBicubic boolean? @Default value: `false`.
function ui.endMIPBias(bias, useBicubic) end

function ui.beginBlurring() end

---@param blurring number|vec2
function ui.endBlurring(blurring) end

function ui.beginSubtraction() end

function ui.endSubtraction() end

function ui.beginTonemapping() end

---@param gamma number
---@param whitePoint number
---@param lcsAware boolean? @Set to `true` to automatically convert colors from AC HDR to LDR (set `whitePoint` to 0 to disable tonemapping step too). Default value: `false`.
function ui.endTonemapping(gamma, whitePoint, lcsAware) end

---Begins rotation. Call this function before drawing elements you need to rotate, it would track current position in resulting
---vertex buffer and then, upon calling `ui.endRotation()`, would turn all new vertices by specified angle.
function ui.beginRotation() end

---Does actual rotation counterclockwise (or clockwise with negative values; also see note). Call this function after calling
---`ui.beginRotation()` and drawing elements you need to rotate. This version would automatically calculate pivot as middle point
---of drawn elements.
---
---Note: angle of rotation is offset by 90, kept this way for compatibility. Just subtract 90 from `deg` for it to act normal.
---@param deg number @Angle in degrees.
---@param offset number|vec2? @Optional offset. Default value: `vec2(0, 0)`.
function ui.endRotation(deg, offset) end

---Does actual rotation counterclockwise (or clockwise with negative values; also see note). Call this function after calling
---`ui.beginRotation()` and drawing elements you need to rotate. This version uses provided pivot to rotate things around.
---
---Note: angle of rotation is offset by 90, kept this way for compatibility. Just subtract 90 from `deg` for it to act normal.
---@param deg number @Angle in degrees.
---@param pivot number|vec2 @Point around which things would rotate, in window space.
---@param offset number|vec2? @Optional offset. Default value: `vec2(0, 0)`.
function ui.endPivotRotation(deg, pivot, offset) end

---Call this function first to apply any further transformations to subsequently drawn windows.
---
---Be careful with it! While it allows to transform windows around, it doesn’t work all that well when clipping
---gets involved, and it gets involved all the time.
---@param active boolean? @Default value: `true`.
function ui.applyTransformationToWindows(active) end

---Begins scaling. Call this function before drawing elements you need to scale, it would track current position in resulting
---vertex buffer and then, upon calling `ui.endScale()`, would scale all new vertices by specified value.
function ui.beginScale() end

---Does actual scaling. Call this function after calling `ui.beginScale()` and drawing elements you need to scale. This
---version would automatically calculate pivot as middle point of drawn elements.
---@param scale number|vec2 @Scale, could be a 2-dimensional vector or a single number.
function ui.endScale(scale) end

---Does actual scaling. Call this function after calling `ui.beginScale()` and drawing elements you need to scale. This
---version uses provided pivot to scale things around.
---@param scale number|vec2 @Scale, could be a 2-dimensional vector or a single number.
---@param pivot number|vec2 @Point around which things would scale, in window space.
function ui.endPivotScale(scale, pivot) end

---Begins transformation. Call this function before drawing elements you need to scale, it would track current position in resulting
---vertex buffer and then, upon calling `ui.endTransformMatrix()`, would transform all new vertices by specified matrix.
function ui.beginTransformMatrix() end

---Does actual transformation. Call this function after calling `ui.beginTransformMatrix()` and drawing elements you need to scale.
---@param mat mat3x3 @Transformation matrix.
function ui.endTransformMatrix(mat) end

---@param count integer? @Default value: 1.
---@return boolean
function ui.popStyleVar(count) end

---@param varID ui.StyleColor
---@param styleSet integer? @Leave at -1 to get the current color, or set to 0 to get the main style color. Default value: -1.
---@return rgbm
function ui.styleColor(varID, styleSet) end

---@param varID ui.StyleColor
---@param value rgbm
function ui.pushStyleColor(varID, value) end

---@param count integer? @Default value: 1.
---@return boolean
function ui.popStyleColor(count) end

---@param fontType ui.Font
function ui.pushFont(fontType) end

---@return boolean
function ui.popFont() end

function ui.setNextTextBold() end

---@param itemWidth number
function ui.pushItemWidth(itemWidth) end

---@return boolean
function ui.popItemWidth() end

---@param wrapPos number
function ui.pushTextWrapPosition(wrapPos) end

---@return boolean
function ui.popTextWrapPosition() end

---Checks if area is visible (not clipped). Works great if you need to make a list with many elements and don’t want to render elements
---outside of scroll (just make sure to offset cursor instead of drawing them using, of example, `ui.offsetCursorY(itemHeight)`).
---@param size number|vec2
---@return boolean
function ui.areaVisible(size) end

---Checks if area is visible (not clipped). Works great if you need to make a list with many elements and don’t want to render elements
---outside of scroll (just make sure to offset cursor instead of drawing them using, of example, `ui.offsetCursorY(itemHeight)`).
---@param height number
---@return boolean
function ui.areaVisibleY(height) end

---@param p1 number|vec2
---@param p2 number|vec2
---@return boolean
function ui.rectVisible(p1, p2) end

---@param p1 number|vec2
---@param p2 number|vec2
---@param clip boolean? @Default value: `true`.
---@return boolean
function ui.rectHovered(p1, p2, clip) end

---Make last item the default focused item of a window.
function ui.setItemDefaultFocus() end

---Focus keyboard on the next widget. Use positive `offset` to access sub components of a multiple component widget. Use `-1` to access previous widget.
---@param offset integer? @Default value: 0.
function ui.setKeyboardFocusHere(offset) end

---@return number
function ui.getScrollX() end

---@return number
function ui.getScrollY() end

---@return number
function ui.getScrollMaxX() end

---@return number
function ui.getScrollMaxY() end

---@param scrollX number
---@param relative boolean? @Default value: `false`.
---@param smooth boolean? @Default value: `true`.
function ui.setScrollX(scrollX, relative, smooth) end

---@param scrollY number
---@param relative boolean? @Default value: `false`.
---@param smooth boolean? @Default value: `true`.
function ui.setScrollY(scrollY, relative, smooth) end

---Adjust scrolling amount to make last item visible. When using to make a default/current item visible, consider using `ui.setItemDefaultFocus()` instead.
---@param centerXRatio number? @0 for top of last item, 0.5 for vertical center of last item, 1 for bottom of last item. Default value: 0.5.
function ui.setScrollHereX(centerXRatio) end

---Adjust scrolling amount to make last item visible. When using to make a default/current item visible, consider using `ui.setItemDefaultFocus()` instead.
---@param centerYRatio number? @0 for top of last item, 0.5 for vertical center of last item, 1 for bottom of last item. Default value: 0.5.
function ui.setScrollHereY(centerYRatio) end

---Is current window hovered (and typically not blocked by a popup/modal).
---@param flags ui.HoveredFlags? @Default value: `ui.HoveredFlags.None`.
---@return boolean
function ui.windowHovered(flags) end

---Is current window focused (or its root/child, depending on flags).
---@param flags ui.FocusedFlags? @Default value: `ui.FocusedFlags.None`.
---@return boolean
function ui.windowFocused(flags) end

---Is current (root) window being resized by its border.
---@return boolean
function ui.windowResizing() end

---Is current window being scrolled by one of its scroll bars (also applies to thin scrollbars).
---@return boolean
function ui.windowScrolling() end

---Is current window pinned.
---@return boolean
function ui.windowPinned() end

---Returns `true` if mouse currently is either used by one of IMGUI controls (like dragging something) or if it hovers any of windows. If that’s the case and
---your script reacts to clicks on the scene, for example, it’s better to skip that frame.
---@return boolean
function ui.mouseBusy() end

---Did mouse button clicked (went from not down to down).
---@param mouseButton ui.MouseButton? @Default value: `ui.MouseButton.Left`.
---@return boolean
function ui.mouseClicked(mouseButton) end

---Did mouse button double-clicked. A double-click returns `false` in `ui.mouseClicked()`.
---@param mouseButton ui.MouseButton? @Default value: `ui.MouseButton.Left`.
---@return boolean
function ui.mouseDoubleClicked(mouseButton) end

---Did mouse button released (went from down to not down).
---@param mouseButton ui.MouseButton? @Default value: `ui.MouseButton.Left`.
---@return boolean
function ui.mouseReleased(mouseButton) end

---Is mouse button held.
---@param mouseButton ui.MouseButton? @Default value: `ui.MouseButton.Left`.
---@return boolean
function ui.mouseDown(mouseButton) end

---Returns mouse cursor position on a screen. To get mouse position within current window, use `ui.mouseLocalPos()`.
---@return vec2 @Mouse cursor position in pixels, or (-1, -1) if mouse is not available.
function ui.mousePos() end

---Returns mouse cursor position relative to current app/window. To get mouse position within screen window, use `ui.mousePos()`.
---@return vec2 @Mouse cursor position in pixels, or (-1, -1) if mouse is not available.
function ui.mouseLocalPos() end

---Get upper-left bounding rectangle of the last item (window space).
---@return vec2
function ui.itemRectMin() end

---Get lower-right bounding rectangle of the last item (window space).
---@return vec2
function ui.itemRectMax() end

---Time since last frame of current UI context.
---@return number
function ui.deltaTime() end

---Get size of last item.
---@return vec2
function ui.itemRectSize() end

---Returns mouse cursor position delta comparing to previous frame.
---@return vec2
function ui.mouseDelta() end

---Returns mouse wheel movement (1 unit scrolls 5 text lines).
---@return number
function ui.mouseWheel() end

---Returns position of current window in screen-space/texture-space (`ui.beginChild()` returns a new window).
---@return vec2
function ui.windowPos() end

---Returns size of current window.
---@return vec2
function ui.windowSize() end

---Size of contents/scrollable client area (calculated from the extents reach of the cursor) from previous frame. Does not include window decoration or window padding.
---@return vec2
function ui.windowContentSize() end

---Size of contents/scrollable client area explicitly request by the user via `ui.setNextWindowContentSize()`.
---@return vec2
function ui.windowContentExplicitSize() end

---Set next window position.
---@param pos number|vec2
---@param pivot number|vec2|nil @Default value: `nil`.
function ui.setNextWindowPosition(pos, pivot) end

---Set next window position.
---@param size number|vec2
function ui.setNextWindowSize(size) end

---Set next window position.
---@param sizeMin number|vec2|nil @Default value: `nil`.
---@param sizeMax number|vec2|nil @Default value: `nil`.
function ui.setNextWindowSizeConstraints(sizeMin, sizeMax) end

---Set next window content size (scrollable client area, which enforce the range of scrollbars). Not including window decorations (title bar, menu bar, etc.) nor WindowPadding. Set an axis to 0 to leave it automatic. Call before `ui.beginChild()`.
---@param size number|vec2
function ui.setNextWindowContentSize(size) end

---Is key being held.
---@param keyIndex ui.KeyIndex
---@return boolean
function ui.keyboardButtonDown(keyIndex) end

---Was key pressed (went from `not down` to `down`). If `with_repeat` is true, uses configured repeat delay and rate.
---@param keyIndex ui.KeyIndex
---@param withRepeat boolean? @Default value: `true`.
---@return boolean
function ui.keyboardButtonPressed(keyIndex, withRepeat) end

---Was key released (went from `down` to `not down`).
---@param keyIndex ui.KeyIndex
---@return boolean
function ui.keyboardButtonReleased(keyIndex) end

---Simulate key being pressed (affects current IMGUI context only).
---@param keyIndex ui.KeyIndex
---@param down boolean? @Default value: `true`.
function ui.setKeyboardButtonDown(keyIndex, down) end

---Add input character for currently active text input.
---@param keyIndex ui.KeyIndex
function ui.addInputCharacter(keyIndex) end

---Clear input character for currently active text input.
function ui.clearInputCharacters() end

---Provides access to few buttons with certain UI roles.
---@param keyCode ui.Key
---@return boolean
function ui.keyPressed(keyCode) end

---Map a button with certain UI role to regular key index.
---@param keyCode ui.Key
---@return ui.KeyIndex
function ui.getKeyIndex(keyCode) end

---Returns true if Ctrl is pressed, but Shift, Alt and Super/Win are depressed.
---@return boolean
function ui.hotkeyCtrl() end

---Returns true if Alt is pressed, but Ctrl, Shift and Super/Win are depressed.
---@return boolean
function ui.hotkeyAlt() end

---Returns true if Shift is pressed, but Ctrl, Alt and Super/Win are depressed.
---@return boolean
function ui.hotkeyShift() end

---Adds modifiers to how IMGUI renders textures (including icons, any UI element, all texts, so use carefully and don’t forget
---to reset values to default with `ui.resetShadingOffset()` or by passing default arguments or no arguments here). Modifiers
---act like simple multiply-and-add adjustment, first value in pair acts like multiplier, second acts like addition (or subtraction)
---value. First pair affects RGB channels, second is for alpha. There are also special combinations:
---- `brightness` = 0, `offset` = 0, `alphaMult` = 0, `alphaOffset` = 0: use texture RGB for color (multiplied by shape color) and green texture channel for alpha;
---- `brightness` = 0, `offset` = 0, `alphaMult` = 0, `alphaOffset` = 1: use shape color for color and red texture channel for alpha;
---- `brightness` = 0, `offset` = 0, `alphaMult` = 0, `alphaOffset` = -1: use shape color for color and inverse of red texture channel for alpha.
---@param brightness number? @Default value: 1.
---@param offset number? @Default value: 0.
---@param alphaMult number? @Default value: 1.
---@param alphaOffset number? @Default value: 0.
function ui.setShadingOffset(brightness, offset, alphaMult, alphaOffset) end

---Resets texture sampling modifiers.
function ui.resetShadingOffset() end

---Draw text using AC font (which should previously set with `ui.pushACFont()`.
---@param text string
---@param letter number|vec2
---@param marginOffset number? @Default value: 0.
---@param color rgbm? @Default value: `rgbm.colors.white`.
---@param lineSpace number? @Default value: 0.
---@param monospace boolean? @Default value: `true`.
function ui.acText(text, letter, marginOffset, color, lineSpace, monospace) end

---Calculate size of text using AC font (which should previously set with `ui.pushACFont()`.
---@param text string
---@param letter number|vec2
---@param marginOffset number? @Default value: 0.
---@param lineSpace number? @Default value: 0.
---@param monospace boolean? @Default value: `true`.
---@return vec2
function ui.calculateACTextSize(text, letter, marginOffset, lineSpace, monospace) end

---Pushes new AC font on stack. After you finished using it, don’t forget to use `ui.popACFont()`. Fonts will be search for
---in “content/fonts”, as well as in script’s folder.
---@param name string
function ui.pushACFont(name) end

---Pops previously pushed font from stack. Note: font will not be unloaded or anything like that, feel free to use it as much as you need.
function ui.popACFont() end

---Adds new TTF font to the stack to be used for drawing DWrite text later. Fonts are taken from “content/fonts” and “extension/fonts”, but scripts
---can also use their own TTF files. To do so, use `'Font Name:path/to/file.ttf'` or `'Font Name:path/to/directory'`, path can be absolute, relative
---to script folder or AC root folder. Font name can also use styling attributes, such as `Weight=Thin`, `Style=Italic` or `Stretch=Condensed`, listed
---at the end after a “;” like so:
---```
---ui.pushDWriteFont('My Font:myfont.ttf;Weight=Bold;Style=Oblique;Stretch=Expanded')
---```
---To make things simpler, you can also use `ui.DWriteFont` helper, it provides nice methods to set attributes.
---
---If you need to use a standard system font, set “@System” as font path: it would use faster working system fonts collection.
---
---Update: since CSP 0.1.80 it is now possible to use a relative path to a TTF file directly. In this case, first font will be used. Note however that
---if you want to use extended options and such, you’ll still need to use “<font name>:<file name>;<options>” format.
---@param name string|ui.DWriteFont? @Default value: 'Segoe UI'.
function ui.pushDWriteFont(name) end

---Removes latest TTF font from the stack.
function ui.popDWriteFont() end

---Calculate size of text using current IMGUI font.
---@param text string
---@param wrapWidth number? @Set to positive value of pixels to enable text wrapping. Default value: -1.
---@return vec2
function ui.measureText(text, wrapWidth) end

---Calculate size of text using TTF font. Make sure to set a font first using `ui.pushDWriteFont()`.
---@param text string
---@param fontSize number? @Default value: 14.
---@param wrapWidth number? @Set to positive value of pixels to enable text wrapping. Default value: -1.
---@return vec2
function ui.measureDWriteText(text, fontSize, wrapWidth) end

---Draws some text using TTF font with DirectWrite library. Make sure to set a font first using `ui.pushDWriteFont()`.
---@param text string
---@param fontSize number? @Default value: 14.
---@param color rgbm? @Default value: `rgbm.colors.white`.
function ui.dwriteText(text, fontSize, color) end

---Draws some hyperlink using TTF font with DirectWrite library. Make sure to set a font first using `ui.pushDWriteFont()`.
---@param text string
---@param fontSize number? @Default value: 14.
---@param hyperlinkColor rgbm? @Default value: `rgbm(0, 0.5, 1, 1)`.
---@return boolean
function ui.dwriteTextHyperlink(text, fontSize, hyperlinkColor) end

---Draws wrapped text using TTF font with DirectWrite library. Make sure to set a font first using `ui.pushDWriteFont()`.
---@param text string
---@param fontSize number? @Default value: 14.
---@param color rgbm? @Default value: `rgbm.colors.white`.
function ui.dwriteTextWrapped(text, fontSize, color) end

---Draws some aligned text using TTF font with DirectWrite library. Make sure to set a font first using `ui.pushDWriteFont()`.
---@param text string
---@param fontSize number? @Default value: 14.
---@param horizontalAligment ui.Alignment? @`ui.Alignment.Start` for left, `ui.Alignment.Center` for middle, `ui.Alignment.End` for right. Default value: `ui.Alignment.Center`.
---@param verticalAlignment ui.Alignment? @`ui.Alignment.Start` for top, `ui.Alignment.Center` for middle, `ui.Alignment.End` for bottom. Default value: `ui.Alignment.Center`.
---@param size number|vec2? @Set to 0 to use remaining space, set to negative value to use it as margin (positive) from remaining space. Default value: `vec2(0, 0)`.
---@param allowWordWrapping boolean? @Default value: `false`.
---@param color rgbm? @Default value: `rgbm.colors.white`.
function ui.dwriteTextAligned(text, fontSize, horizontalAligment, verticalAlignment, size, allowWordWrapping, color) end

---@return boolean
function ui.popID() end

---@return integer
function ui.getLastID() end

---@return integer
function ui.getActiveID() end

---@return integer
function ui.getFocusID() end

---@return integer
function ui.getHoveredID() end

function ui.clearActiveID() end

---@param id integer
function ui.activateItem(id) end

---Returns a number associated with current context (taking into account `ui.pushID()` calls). Use it to store rarely updating
---UI data, such as, for example, opened tab.
---@param id integer? @Default value: 0.
---@param defaultValue number? @Default value: 0.
---@return number
function ui.loadStoredNumber(id, defaultValue) end

---Returns a boolean value associated with current context (taking into account `ui.pushID()` calls). Use it to store rarely updating
---UI data, such as, for example, opened tab.
---@param id integer? @Default value: 0.
---@param defaultValue boolean? @Default value: `false`.
---@return boolean
function ui.loadStoredBool(id, defaultValue) end

---Stores a number in current context (taking into account `ui.pushID()` calls). Use it to store rarely updating
---UI data, such as, for example, opened tab.
---@param id integer? @Default value: 0.
---@param value number? @Default value: 0.
function ui.storeNumber(id, value) end

---Stores a boolean value in current context (taking into account `ui.pushID()` calls). Use it to store rarely updating
---UI data, such as, for example, opened tab.
---@param id integer? @Default value: 0.
---@param value boolean? @Default value: `false`.
function ui.storeBool(id, value) end

---@param columns integer? @Default value: 1.
---@param border boolean? @Default value: `true`.
---@param id string|nil @Default value: `nil`.
function ui.columns(columns, border, id) end

function ui.nextColumn() end

---@param columnIndex integer
---@param width number
function ui.setColumnWidth(columnIndex, width) end

---@param columnIndex integer
---@return number
function ui.getColumnWidth(columnIndex) end

---Can be used to draw something spanning entire table.
function ui.pushColumnsBackground() end

---@return boolean
function ui.popColumnsBackground() end

---Draws a column label with optional ordering arrow and advances to the next column.
---@param title string
---@param orderDirection integer @1 for arrow pointing down, -1 for arrow pointing up, 0 for no arrow.
---@param alignRight boolean? @Default value: `false`.
---@return boolean @Returns `true` if header was clicked.
function ui.columnSortingHeader(title, orderDirection, alignRight) end

---Copyable text.
---@param label string
function ui.copyable(label) end

function ui.pushDisabled() end

---@return boolean
function ui.popDisabled() end

---Simple button.
--- @overload fun(label: string, flags: ui.ButtonFlags)
---@param label string
---@param size number|vec2? @Default value: `vec2(0, 0)`.
---@param flags ui.ButtonFlags? @Default value: `ui.ButtonFlags.None`.
---@return boolean
function ui.button(label, size, flags) end

---Button with Modern UI style to use in modal dialogs.
---@param label string
---@param size number|vec2
---@param flags ui.ButtonFlags? @Default value: `ui.ButtonFlags.None`.
---@param icon string|nil @Default value: `nil`.
---@param iconSize number? @Default value: 16.
---@param iconBg string|nil @Default value: `nil`.
---@return boolean
function ui.modernButton(label, size, flags, icon, iconSize, iconBg) end

---Very experimental. Better to avoid using, or at least to call first.
---@param accentColor rgbm
---@param brightTheme boolean? @Default value: `false`.
---@param roundedCorners boolean? @Default value: `false`.
---@param bgAlpha number? @Default value: 0.72.
function ui.configureStyle(accentColor, brightTheme, roundedCorners, bgAlpha) end

---Button without frame padding to easily embed within text.
---@param label string
---@return boolean
function ui.smallButton(label) end

---Button behavior without the visuals, frequently useful to build custom behaviors using the public API (along with `ui.itemActive()`, `ui.itemHovered()`, etc.)
---@param label string
---@param size number|vec2
---@param flags ui.ButtonFlags? @Default value: `ui.ButtonFlags.None`.
---@return boolean
function ui.invisibleButton(label, size, flags) end

---Add a dummy item of given size. unlike `ui.invisibleButton()`, dummy won’t take the mouse click or be navigable into.
---@param size number|vec2
function ui.dummy(size) end

---Returns `true` during scrolling.
---@param appearOnHover boolean? @Default value: `false`.
---@return boolean
function ui.thinScrollbarBegin(appearOnHover) end

function ui.thinScrollbarEnd() end

---Square button with an arrow shape.
---@param strID string
---@param dir ui.Direction
---@param size number|vec2? @Default value: `vec2(0, 0)`.
---@param flags ui.ButtonFlags? @Default value: `ui.ButtonFlags.None`.
---@return boolean
function ui.arrowButton(strID, dir, size, flags) end

---Draw a small circle and keep the cursor on the same line.
function ui.bullet() end

---Separator, generally horizontal. Inside a menu bar or in horizontal layout mode, this becomes a vertical separator.
function ui.separator() end

---Checkbox. Pass `refbool` for current value, or just pass a regular `boolean` and switch state yourself if
---function would return `true`.
---```
---if ui.checkbox('My checkbox', myFlag) then
---  myFlag = not myFlag
---end
---```
---@param label string
---@param checked boolean|refbool|nil
---@return boolean @Returns `true` if checkbox was clicked.
function ui.checkbox(label, checked) end

---@param label string
---@param checked boolean|refbool|nil
---@return boolean
function ui.radioButton(label, checked) end

---@param fraction number
---@param size number|vec2? @Default value: `vec2(0, 0)`.
---@param overlay string|nil @Default value: `nil`.
function ui.progressBar(fraction, size, overlay) end

---Mark window resize handle to show some content is hidden due to window size.
---@param active boolean? @Default value: `true`.
function ui.setExtraContentMark(active) end

---Let IMGUI know about some extra content you’re drawing in the title bar to avoid potential conflicts. Pass `math.nan` (or `math.huge`) as first parameter to disable.
---@param marginLeft number? @Default value: 80.
---@param marginRight number? @Default value: 44.
function ui.setTitleBarContentHint(marginLeft, marginRight) end

---Add notification counter (small red circle with a bit of a glow and an optional digit in it).
---@param counter integer? @By default doesn’t show any number. If above 9, “…” will be shown. Default value: -1.
---@param pos number|vec2|nil @If not set, notification counter will be added to the previous element. Default value: `nil`.
---@param noclip boolean? @Set to `true` if your counter ends up clipped. Default value: `false`.
function ui.notificationCounter(counter, pos, noclip) end

---@param width number
function ui.setNextItemWidth(width) end

---@param iconID ui.Icons
---@param color rgbm|nil @If not set, text color will be used. Default value: `nil`.
---@param relativePadding number? @Relative padding from 0 to 1. Default value: 0.
function ui.setNextItemIcon(iconID, color, relativePadding) end

---It’s safer to use `ui.combo()`: a wrapper that would ensure UI wouldn’t break even if Lua script would crash midway for any reason.
---@param label string
---@param previewValue string
---@param flags ui.ComboFlags? @Default value: `ui.ComboFlags.None`.
---@return boolean
function ui.beginCombo(label, previewValue, flags) end

---@param label string
---@param selected boolean|refbool|nil
---@param flags ui.SelectableFlags? @Default value: `ui.SelectableFlags.None`.
---@param size number|vec2? @Default value: `vec2(0, 0)`.
---@return boolean
function ui.selectable(label, selected, flags, size) end

function ui.endCombo() end

---It’s safer to use `ui.childWindow()`: a wrapper that would ensure UI wouldn’t break even if Lua script would crash midway for any reason.
--- Note: you have to call `ui.endChild()` even if `ui.beginChild()` returns `false` (don’t waste time drawing content in that case though).
---@param id string
---@param size number|vec2? @Default value: `vec2(0, 0)`.
---@param border boolean? @Default value: `false`.
---@param flags ui.WindowFlags? @Default value: `ui.WindowFlags.NoBackground`.
---@return boolean
function ui.beginChild(id, size, border, flags) end

function ui.endChild() end

---For use in `ui.onDriverContextMenu()`.
---@param label string
---@param iconID ui.Icons|nil @Default value: `nil`.
---@param selected boolean? @Default value: `false`.
---@param flags ui.SelectableFlags? @Default value: `ui.SelectableFlags.None`.
---@param childItem boolean? @Increases padding. Default value: `false`.
---@return boolean
function ui.modernMenuItem(label, iconID, selected, flags, childItem) end

---It’s safer to use `ui.tabBar()`: a wrapper that would ensure UI wouldn’t break even if Lua script would crash midway for any reason.
---@param id string
---@param flags ui.TabBarFlags? @Default value: `ui.TabBarFlags.None`.
---@return boolean
function ui.beginTabBar(id, flags) end

function ui.endTabBar() end

---It’s safer to use `ui.tabBarItem()`: a wrapper that would ensure UI wouldn’t break even if Lua script would crash midway for any reason.
---@param label string
---@param flags ui.TabItemFlags? @Default value: `ui.TabItemFlags.None`.
---@param opened boolean|refbool|nil|nil @Default value: `nil`.
---@return boolean
function ui.beginTabItem(label, flags, opened) end

function ui.endTabItem() end

---It’s safer to use `ui.treeNode()`: a wrapper that would ensure UI wouldn’t break even if Lua script would crash midway for any reason.
---@param label string
---@param flags ui.TreeNodeFlags? @Default value: `ui.TreeNodeFlags.Framed`.
---@return boolean
function ui.beginTreeNode(label, flags) end

function ui.endTreeNode() end

---It’s safer to use `ui.itemPopup()`: a wrapper that would ensure UI wouldn’t break even if Lua script would crash midway for any reason.
---@param id string
---@param mouseButton ui.MouseButton? @Default value: `ui.MouseButton.Right`.
---@return boolean
function ui.beginPopupContextItem(id, mouseButton) end

---@param label string
---@param selected boolean? @Default value: `false`.
---@param flags ui.SelectableFlags? @Default value: `ui.SelectableFlags.None`.
---@param shortcut string|nil @Default value: `nil`.
---@return boolean
function ui.menuItem(label, selected, flags, shortcut) end

---@param id string
---@param selected boolean? @Default value: `false`.
---@param enabled boolean? @Default value: `true`.
---@param shortcut string|nil @Default value: `nil`.
---@return boolean
function ui.beginMenu(id, selected, enabled, shortcut) end

function ui.endMenu() end

---Base IMGUI popup model for something more custom.
---@param id string
function ui.openPopup(id) end

---Close currently drawn popup.
function ui.closePopup() end

---@param id string
---@param flags ui.WindowFlags? @Default value: `ui.WindowFlags.None`.
---@param padding number|vec2|nil @Default value: `nil`.
---@param opened boolean|refbool|nil|nil @Default value: `nil`.
---@return boolean
function ui.beginPopup(id, flags, padding, opened) end

function ui.endPopup() end

---It’s safer to use `ui.tooltip()`: a wrapper that would ensure UI wouldn’t break even if Lua script would crash midway for any reason. If you
---just need to render some text in a tooltip, use `ui.setTooltip()` instead.
---@param padding number|vec2? @Default value: `vec2(20, 8)`.
function ui.beginTooltip(padding) end

function ui.endTooltip() end

---@param text string
function ui.header(text) end

---@param text string
function ui.bulletText(text) end

---@param tooltip string
function ui.setTooltip(tooltip) end

---Is the last item hovered and usable, aka not blocked by a popup, etc.
---@param flags ui.HoveredFlags? @Default value: `ui.HoveredFlags.None`.
---@return boolean
function ui.itemHovered(flags) end

---Is the last item clicked (e.g. button/node just clicked on), same as `ui.mouseClicked(mouseButton) and ui.itemHovered()`
---@param mouseButton ui.MouseButton? @Default value: `ui.MouseButton.Left`.
---@param buttonBehaviour boolean? @If `true`, triggers on release, but only if click position was also within item. Default value: `false`.
---@return boolean
function ui.itemClicked(mouseButton, buttonBehaviour) end

---Is the last item active (e.g. button being held, text field being edited). This will continuously return true while holding mouse button on an item. Items that don’t interact will always return false)
---@return boolean
function ui.itemActive() end

---Is the last item focused for keyboard/gamepad navigation.
---@return boolean
function ui.itemFocused() end

---Is the last item visible (items may be out of sight because of clipping/scrolling).
---@return boolean
function ui.itemVisible() end

---Did the last item modify its underlying value this frame, or was pressed. This is generally the same as the return value of many widgets.
---@return boolean
function ui.itemEdited() end

---Was the last item just made active (item was previously inactive).
---@return boolean
function ui.itemActivated() end

---Was the last item just made inactive (item was previously active). Useful for Undo/Redo patterns with widgets that requires continuous editing.
---@return boolean
function ui.itemDeactivated() end

---Was the last item just made inactive and made a value change when it was active (e.g. slider moved). Useful for Undo/Redo patterns with widgets that requires continuous editing. Note: you may get false positives (some widgets such as combo/selectable will return true even when clicking an already selected item).
---@return boolean
function ui.itemDeactivatedAfterEdit() end

---Is any item hovered.
---@return boolean
function ui.anyItemHovered() end

---Is any item active.
---@return boolean
function ui.anyItemActive() end

---Is any item focused.
---@return boolean
function ui.anyItemFocused() end

---Get upper-left bounding rectangle of the last item (screen space).
---@deprecated
---@return vec2
function ui.getItemRectMin() end

---Get lower-right bounding rectangle of the last item (screen space).
---@deprecated
---@return vec2
function ui.getItemRectMax() end

---Get size of last item.
---@deprecated
---@return vec2
function ui.getItemRectSize() end

---Allow last item to be overlapped by a subsequent item. sometimes useful with invisible buttons, selectables, etc. to catch unused area.
function ui.setItemAllowOverlap() end

---Was the last item selection (`ui.selectable()`, `ui.treeNode()`, etc.) toggled
---@return boolean
function ui.itemToggledSelection() end

---Unlike `ui.drawImage()`, this one adds an image as an item to current cursor position and moves the cursor. Also allows
---to interact with an image with functions like `ui.itemHovered()`. You can do the same with `ui.drawImage()`, just use
---`ui.getCursor()` for `p1`, `ui.getCursor() + size` for `p2` and `ui.dummy()` for interaction.
---@overload fun(imageSource: ui.ImageSource, size: vec2, color: rgbm, mode: ui.ImageFit)
---@overload fun(imageSource: ui.ImageSource, size: vec2, mode: ui.ImageFit)
---@param imageSource ui.ImageSource @Path to the image, absolute or relative to script folder or AC root. URLs are also accepted.
---@param size number|vec2 @Size of resulting image in pixels.
---@param color rgbm? @Tint of the image, with white it would be drawn as it is. Default value: `rgbm.colors.white`.
---@param borderColor rgbm|nil @Optional 1-pixel wide border around image. Default value: `nil`.
---@param uv1 number|vec2? @Texture coordinates for upper left corner. Default value: `vec2(0, 0)`.
---@param uv2 number|vec2? @Texture coordinates for bottom right corner. Default value: `vec2( 1, 1 )`.
---@param mode ui.ImageFit? @Stretch mode. Default value: `ui.ImageFit.Stretch`.
function ui.image(imageSource, size, color, borderColor, uv1, uv2, mode) end

---Adds a button with an image on it. If image is missing or loading (if it’s remote or asyncronous loading is enabled),
---button would still appear, but without an image.
---
---Note: if image source doesn’t have “##” in it, `color` and `bgColor` are swapped. For compatibility reason things are left as is, please
---use `ui.iconButton()` instead.
---@deprecated
---@overload fun(imageSource: ui.ImageSource, size: vec2, bgColor: rgbm, framePadding: number, mode: ui.ImageFit)
---@overload fun(imageSource: ui.ImageSource, size: vec2, framePadding: number, mode: ui.ImageFit)
---@param imageSource ui.ImageSource @Path to the image, absolute or relative to script folder or AC root. URLs are also accepted. Use `##…` postfix for unique ID if you have multiple buttons with the same filename (or, even better, use `ui.pushID()/ui.popID()`.
---@param size number|vec2 @Size of resulting image in pixels.
---@param bgColor rgbm|nil @Optional background color for the image (transparent if not set). Default value: `nil`.
---@param color rgbm? @Tint of the image, with white it would be drawn as it is. Default value: `rgbm.colors.white`.
---@param uv1 number|vec2? @Texture coordinates for upper left corner. Default value: `vec2(0, 0)`.
---@param uv2 number|vec2? @Texture coordinates for bottom right corner. Default value: `vec2( 1, 1 )`.
---@param framePadding number? @If -1, uses frame padding from style. If 0, there is no padding. If above zero, it’s used as actual padding value. Default value: -1.
---@param mode ui.ImageFit? @Stretch mode. Default value: `ui.ImageFit.Stretch`.
---@return boolean
function ui.imageButton(imageSource, size, bgColor, color, uv1, uv2, framePadding, mode) end

---Adds a button with an image on it. If image is missing or loading (if it’s remote or asyncronous loading is enabled),
---button would still appear, but without an image.
---@overload fun(iconID: ui.ImageSource, size: vec2, color: rgbm, framePadding: number, keepAspectRatio: boolean, flags: ui.ButtonFlags)
---@overload fun(iconID: ui.ImageSource, size: vec2, framePadding: number, keepAspectRatio: boolean, flags: ui.ButtonFlags)
---@param iconID ui.Icons @Icon or path to the image, absolute or relative to script folder or AC root. URLs are also accepted. Use `##…` postfix for unique ID if you have multiple buttons with the same filename (or, even better, use `ui.pushID()/ui.popID()`.
---@param size number|vec2|nil @Size of resulting image in pixels. If not set, default button size will be used. Default value: `nil`.
---@param color rgbm|nil @Tint of the image, with white it would be drawn as it is (text color if not set). Default value: `nil`.
---@param bgColor rgbm|nil @Optional background color for the image (transparent if not set). Default value: `nil`.
---@param framePadding number? @Padding (does not affect button size). If negative, default frame padding from current style is used. Use 0 with defined background color (like `rgbm.colors.transparent`) and `keepAspectRatio` set to `false` to hide the frame and only show the image. Default value: -1.
---@param uv1 number|vec2? @Texture coordinates for upper left corner. Default value: `vec2(0, 0)`.
---@param uv2 number|vec2? @Texture coordinates for bottom right corner. Default value: `vec2( 1, 1 )`.
---@param keepAspectRatio boolean? @Set to `true` to stretch image to fit given size, making sure it would not get distorted. Default value: `true`.
---@param flags ui.ButtonFlags? @Default value: `ui.ButtonFlags.None`.
---@return boolean
function ui.iconButton(iconID, size, color, bgColor, framePadding, uv1, uv2, keepAspectRatio, flags) end

---Returns `true`, if an image is ready to be drawn. If image was not used before, starts its loading.
---
---Note: By default images from local files are loaded syncronously, use `ui.setAsynchronousImagesLoading(true)` function to change this behaviour.
---@param imageSource ui.ImageSource @Path to the image, absolute or relative to script folder or AC root. URLs are also accepted.
---@return boolean
function ui.isImageReady(imageSource) end

---Activates synchronous loading for local images. By default local images are loaded syncronously, but by calling this function
---and passing `true` to it, they would start to load asyncronously from there, reducing possible stutters. Any remote images are loaded
---asyncronously no matter what.
---
---Note: for now, any image ever loaded would remain in RAM and video memory. Try not to load way too many things.
---@param value boolean? @Default value: `true`.
function ui.setAsynchronousImagesLoading(value) end

---Forces CSP to ignore all those HTTP headers and reuse cached versions of remote images.
---@param value boolean? @Default value: `true`.
function ui.setForcedImagesCaching(value) end

---Width of item given pushed settings and current cursor position. NOT necessarily the width of last item unlike most 'Item' functions.
---@return number
function ui.calcItemWidth() end

---Allow focusing using Tab/Shift+Tab, enabled by default but you can disable it for certain widgets.
---@param allowKeyboardFocus boolean|`true`|`false`
function ui.pushAllowKeyboardFocus(allowKeyboardFocus) end

---Removes last `ui.pushAllowKeyboardFocus()` modification.
---@return boolean
function ui.popAllowKeyboardFocus() end

---In repeat mode, button functions return repeated true in a typematic manner.
---Note: you can call `ui.itemActive()` after any button to tell if the button is held in the current frame.
---@param repeatValue boolean|`true`|`false`
function ui.pushButtonRepeat(repeatValue) end

---Removes last `ui.pushButtonRepeat()` modification
---@return boolean
function ui.popButtonRepeat() end

---Move content position toward the right.
---@param indentW number? @If 0, indent spacing from style will be used. Default value: 0.0.
function ui.indent(indentW) end

---Move content position back to the left.
---@param indentW number? @If 0, indent spacing from style will be used. Default value: 0.0.
function ui.unindent(indentW) end

---Initial cursor position in window coordinates.
---@return vec2
function ui.cursorStartPos() end

---Cursor position in absolute screen coordinates (within AC window or its UI in VR, but also affected by UI scale).
---@return vec2
function ui.cursorScreenPos() end

---Cursor position in absolute screen coordinates (within AC window or its UI in VR, but also affected by UI scale).
---@param pos number|vec2
function ui.setCursorScreenPos(pos) end

---Vertically align upcoming text baseline to frame padding so that it will align properly to regularly framed items (call if you have text on a line before a framed item).
function ui.alignTextToFramePadding() end

---Pretty much just font size.
---@return number
function ui.textLineHeight() end

---Returns font size and vertical item spacing (distance in pixels between 2 consecutive lines of text).
---@return number
function ui.textLineHeightWithSpacing() end

---Returns font size and frame padding.
---@return number
function ui.frameHeight() end

---Returns font size, frame padding and vertical item spacing (distance in pixels between 2 consecutive lines of framed widgets).
---@return number
function ui.frameHeightWithSpacing() end

---Get current font size (height in pixels) of current font with current scale applied.
---@return number
function ui.fontSize() end

---Get UV coordinate for a while pixel, useful to draw custom shapes via the ImDrawList API.
---@return vec2
function ui.fontWhitePixelUV() end

---Pushes new alpha value taking into account current style alpha, good for fading elements in case any parent elements could also fade.
---To revert change, use `ui.popStyleVar()`.
---@param alpha number
function ui.pushStyleVarAlpha(alpha) end

---Experimental.
---@param vertical boolean? @Default value: `false`.
---@param alignment number? @Default value: 0.5.
function ui.pushAlignment(vertical, alignment) end

---Experimental.
function ui.popAlignment() end

---Adjust scrolling amount to make given position visible. Generally `ui.cursorStartPos() + offset` to compute a valid position.
---@param localX number
---@param centerXRatio number? @Default value: 0.5.
function ui.setScrollFromPosX(localX, centerXRatio) end

---Adjust scrolling amount to make given position visible. Generally `ui.cursorStartPos() + offset` to compute a valid position.
---@param localY number
---@param centerYRatio number? @Default value: 0.5.
function ui.setScrollFromPosY(localY, centerYRatio) end

---Get current window title.
---@return string?
function ui.windowTitle() end

---Stop frosted effect of semi-transparent IMGUI surfaces for a single frame.
function ui.forceSimplifiedComposition() end

---Allow AC to see mouse events for a frame, even if IMGUI is handling them.
function ui.passthroughIMGUI() end

---Get current window width (shortcut for `ui.windowSize().x`)
---@return number
function ui.windowWidth() end

---Get current window height (shortcut for `ui.windowSize().y`)
---@return number
function ui.windowHeight() end

---If current window just been opened.
---@return boolean
function ui.isWindowAppearing() end

---Is current window collapsed.
---@return boolean
function ui.isWindowCollapsed() end

---Is current window focused (or its root/child, depending on flags).
---@deprecated Use `ui.windowFocused()` instead.
---@param flags ui.FocusedFlags? @Default value: `ui.FocusedFlags.None`.
---@return boolean
function ui.isWindowFocused(flags) end

---Uses provided repeat rate/delay. Return a count, most often 0 or 1, but might be > 1 if RepeatRate is small enough that DeltaTime > RepeatRate
---@param keyIndex ui.KeyIndex
---@param repeatDelay number
---@param rate number
---@return integer
function ui.keyPressedAmount(keyIndex, repeatDelay, rate) end

---Is any mouse button held.
---@return boolean
function ui.isAnyMouseDown() end

---Did mouse button released (went from down to not down).
---@param mouseButton ui.MouseButton? @Default value: `ui.MouseButton.Left`.
---@return boolean
function ui.isMouseReleased(mouseButton) end

---Is mouse dragging. If `lockThreshold` < -1, uses io.MouseDraggingThreshold
---@param mouseButton ui.MouseButton? @Default value: `ui.MouseButton.Left`.
---@param lockThreshold number? @Default value: -1.0.
---@return boolean
function ui.isMouseDragging(mouseButton, lockThreshold) end

---Retrieve backup of mouse position at the time of opening popup we have `ui.beginPopup()` into
---@return vec2
function ui.mousePosOnOpeningCurrentPopup() end

---Return the delta from the initial clicking position while the mouse button is pressed or was just released. This is locked and
---return 0 until the mouse moves past a distance threshold at least once.
---@param mouseButton ui.MouseButton? @Default value: `ui.MouseButton.Left`.
---@param lockThreshold number? @If below zero, default mouse dragging threshold will be used. Default value: -1.0.
---@return vec2
function ui.mouseDragDelta(mouseButton, lockThreshold) end

---Resets mouse drag delta.
---@param mouseButton ui.MouseButton? @Default value: `ui.MouseButton.Left`.
function ui.resetMouseDragDelta(mouseButton) end

---Get cursor type. Cursor type resets in with each new frame
---@return ui.MouseCursor
function ui.mouseCursor() end

---Set cursor type.
---@param type ui.MouseCursor
function ui.setMouseCursor(type) end

---Stops rest of Assetto Corsa from responding to mouse events, also sets `getUI().wantCaptureMouse` flag. Note:
--- if you writing a script reacting to general mouse events, consider checking that flag to make sure IMGUI doesn’t have mouse captured currently.
---@param wantCaptureMouseValue boolean? @Default value: `true`.
function ui.captureMouse(wantCaptureMouseValue) end

---Get text that is currently in clipboard.
---@return string
function ui.getClipboardText() end

---Set new text to clipboard.
---Added by mistake, use `ac.setClipboardText()`.
---@deprecated
---@param text string
function ui.setClipboardText(text) end

---Get global IMGUI time. Incremented by `dt` every frame.
---@return number
function ui.time() end

---Get global IMGUI frame count. Incremented by 1 every frame.
---@return integer
function ui.frameCount() end

---Sets a callback which will be called when main UI IMGUI render is complete (currenly works for window calls of Lua apps).
---@param callback fun()
---@return ac.Disposable
function ui.onUIFinale(callback) end

---Sets a callback for drawing chat UI which will be called first. Anything drawn here will likely be covered by other UI elements. Return `true`
---to stop the rest of UI to be drawn in this frame. Use `mode` passed in your callback to determine the state of the game: chances are you’d need to draw your
---HUD only with `'game'` mode.
---
---New values for `mode` might in theory be added later (or maybe not, hard to tell at this point).
---
---Not available to car and track scripts.
---@param callback fun(mode: 'menu'|'game', readOnlyMode: boolean): boolean?
---@param settingsCallback fun(): boolean?? @Default value: `nil`.
---@return ac.Disposable
function ui.onChat(callback, settingsCallback) end

---Sets a callback for drawing UI which will be called first. Anything drawn here will likely be covered by other UI elements. Return `true`
---to stop the rest of UI to be drawn in this frame (including AC UI). Return `'debug'` to also show Lua Debug app, in case you’d need it
---for development. Use `mode` passed in your callback to determine the state of the game: chances are you’d need to draw your
---HUD only with `'game'` mode.
---
---New values for `mode` might in theory be added later (or maybe not, hard to tell at this point).
---
---Not available to car and track scripts.
---
---Since 0.2.8, return `'finalize'` to allow `ui.popup()` and `ui.onUIFinale()`.
---@param callback fun(mode: 'menu'|'pause'|'results'|'replay'|'game'): 'debug'|'apps'|boolean?
---@return ac.Disposable
function ui.onExclusiveHUD(callback) end

---Open modal popup message with OK and Cancel buttons, return user choice via callback.
---@overload fun(title: string, msg: string, callback: function)
---@param title string
---@param msg string
---@param okText string|nil @Optional label for OK button. Default value: `nil`.
---@param cancelText string|nil @Optional label for cancel button. Default value: `nil`.
---@param okIconID ui.Icons|nil @Optional icon for OK button. Default value: `nil`.
---@param cancelIconID ui.Icons|nil @Optional icon for cancel button. Default value: `nil`.
---@param callback fun(okPressed: boolean)? @Default value: `nil`.
function ui.modalPopup(title, msg, okText, cancelText, okIconID, cancelIconID, callback) end

---Open modal dialog with custom UI. Return `true` from callback when it’s time to close the dialog.
---
--- To match original dialogs use `ui.newLine()` after the message and vertical offset of four pixels before drawing the buttons. For buttons use
--- `ui.modernButton()` with the height of 40 pixels and the gap of 8 pixels.
---@param title string
---@param callback fun(): boolean
---@param autoclose boolean? @Automatically close if clicked outside of dialog. Default value: `false`.
---@param closeCallback fun()? @Default value: `nil`.
function ui.modalDialog(title, callback, autoclose, closeCallback) end

---Open modal popup message with text input, OK and Cancel buttons, return user choice via callback.
---@overload fun(title: string, msg: string, defaultValue: string, callback: function)
---@param title string
---@param msg string
---@param defaultValue string?
---@param okText string? @Optional label for OK button.
---@param cancelText string? @Optional label for cancel button.
---@param okIconID ui.Icons @Optional icon for OK button.
---@param cancelIconID ui.Icons @Optional icon for cancel button.
---@param callback fun(value: string|nil)
function ui.modalPrompt(title, msg, defaultValue, okText, cancelText, okIconID, cancelIconID, callback) end

---Projects world point onto a screen (taking into account UV scale unless second argument is set to `false`).
---@param pos vec3
---@param considerUiScale boolean? @Default value: `true`.
---@return vec2 @Returns vector with `inf` for values if point is outside of screen.
function ui.projectPoint(pos, considerUiScale) end

---If possible, unloads image from memory and VRAM. Doesn’t work with all types of images.
---@param imageSource ui.ImageSource
---@return boolean @Returns `true` if file was unloaded successfully.
function ui.unloadImage(imageSource) end

---Draws 14×14 pixels driver icon (rounded livery or a custom icon if icon is overriden).
---@param carIndex integer @0-based car index.
---@param pos number|vec2
---@param useCustomIcon boolean? @Default value: `true`.
function ui.drawDriverIcon(carIndex, pos, useCustomIcon) end

---Add tooltip with details about a certain driver.
---@param carIndex integer @0-based car index.
function ui.setDriverTooltip(carIndex) end

---Shows context menu for a certain driver. Use `ui.openPopup(id)` to trigger it first.
---@param id string
---@param carIndex integer @0-based car index.
---@return boolean @Returns `false` once popup closes.
function ui.setDriverPopup(id, carIndex) end

---Adds mention of a driver in chat input.
---@param carIndex integer
---@param autofocus boolean? @Default value: `true`.
function ui.mentionDriverInChat(carIndex, autofocus) end

---Returns state of an image (might act strage with special textures, like the ones loaded from DLLs; new return values might be added later).
---@param imageSource string @Path to the image, absolute or relative to script folder or AC root. URLs are also accepted.
---@return 'ready'|'loading'|'missing'
function ui.imageState(imageSource) end

---Shows a hidden app window or few while current script is alive (temporarily removing “HIDDEN” window flag).
---@param appID string
---@param windowFilter string? @Default value: '?'.
---@param visible boolean? @Default value: `true`.
function ac.setAppWindowVisible(appID, windowFilter, visible) end

---Opens a main window of a Lua app (or, if opened, brings it to focus).
---@param appID string
function ac.setAppOpen(appID) end

---Teleports car to certain spawn point, invalidates current lap.
---@param carIndex integer
---@param spawnSet ac.SpawnSet
function physics.teleportCarTo(carIndex, spawnSet) end

---Sets car position and orientation and invalidates current lap time. Car will be aligned on track surface.
---@param carIndex integer
---@param pos vec3
---@param dir vec3
function physics.setCarPosition(carIndex, pos, dir) end

---Sets car velocity and invalidates current lap time.
---@param carIndex integer
---@param velocity vec3
function physics.setCarVelocity(carIndex, velocity) end

---Forces certain gear to engage. Might not work well for user car with H-shifter. Also, invalidates current lap time.
---@param carIndex integer @0-based car index.
---@param gearToEngage integer @-1 for reverse, 0 for neutral, etc.
function physics.engageGear(carIndex, gearToEngage) end

---Sets MGUK delivery mode. Note: for controling user car consider using `ac.setMGUKDelivery()` instead, it’ll work better with HUD and everything.
---@param carIndex integer @0-based car index.
---@param level integer @0-based index.
function physics.setMGUKDelivery(carIndex, level) end

---Sets MGUK recovery mode. Note: for controling user car consider using `ac.setMGUKDelivery()` instead, it’ll work better with HUD and everything.
---@param carIndex integer @0-based car index.
---@param level integer @Value from 0 to 10.
function physics.setMGUKRecovery(carIndex, level) end

---Activates or deactivates gentle stopping.
---@param carIndex integer @0-based car index.
---@param stop boolean? @Default value: `true`.
function physics.setGentleStop(carIndex, stop) end

---Locks user controls for specified time. Use this one instead of `physics.setCarNoInput()` if you only need to stop car temporarily
---and then let user control it back.
---@param time number @Time in seconds; 0 to disable controls locking.
function physics.lockUserControlsFor(time) end

---Locks user car gearbox for specified time. Uses the same logic AC uses for starting line.
---@param time number @Time in seconds; 0 to disable controls locking.
---@param resetGear boolean? @Set to `true` to switch gearbox to neutral as well. Default value: `false`.
function physics.lockUserGearboxFor(time, resetGear) end

---Forces fully engaged brakes for user car for given time. Invalidates lap. Subsequent calls override value set earlier.
---@param time number @Time in seconds; 0 to disable brakes forcing.
---@param brakingIntensity number? @Braking intensity, from 0 to 1. Default value: 1.
function physics.forceUserBrakesFor(time, brakingIntensity) end

---Forces fully engaged throttle pedal for user car for given time. Invalidates lap. Subsequent calls override value set earlier.
---@param time number @Time in seconds; 0 to disable brakes forcing.
---@param throttleIntensity number? @Braking intensity, from 0 to 1. Default value: 1.
function physics.forceUserThrottleFor(time, throttleIntensity) end

---Forces fully engaged clutch pedal for user car for given time. Invalidates lap. Subsequent calls override value set earlier.
---@param time number @Time in seconds; 0 to disable clutch forcing.
---@param clutchValue number? @Clutch value, from 0 to 1 (0 for pedal fully pressed). Default value: 0.
function physics.forceUserClutchFor(time, clutchValue) end

---Forces fully engaged handbrake for user car for given time. Invalidates lap. Subsequent calls override value set earlier.
---@param time number @Time in seconds; 0 to disable handbrake forcing.
---@param handbrakeValue number? @Handbrake value, from 0 to 1. Default value: 1.
function physics.forceUserHandbrakeFor(time, handbrakeValue) end

---Offsets user steering angle.
---@param offset number
function physics.offsetUserSteering(offset) end

---Overrides user steering angle.
---@param value number
---@param share number
function physics.overrideUserSteering(value, share) end

---Overrides steering completely for a certain car.
---@param carIndex integer @0-based car index.
---@param value number @Set to `math.nan` to disable overriding.
function physics.overrideSteering(carIndex, value) end

---Resets car state (repairs damage, resets fuel) and invalidates current lap.
---@param carIndex integer @0-based car index.
---@param fuelMult number? @Default value: 0.5.
function physics.resetCarState(carIndex, fuelMult) end

---Sets car fuel and invalidates current lap.
---@param carIndex integer @0-based car index.
---@param fuelLiters number @Amount of fuel in liters.
function physics.setCarFuel(carIndex, fuelLiters) end

---Disables input for user car, switches car to “parked” state. If it’s meant for game rules and such, try `physics.lockUserControlsFor()` instead.
---@param active boolean? @Default value: `true`.
function physics.setCarNoInput(active) end

---Activates or deactivates autopilot for user car. Invalidates lap.
---@param active boolean? @Default value: `true`.
---@param chooseTyres boolean? @Set to `true` to let AI select appropriate tyres. Default value: `false`.
function physics.setCarAutopilot(active, chooseTyres) end

---Returns state of car controls user input. Works even if user car controls were deactivated or AI is controlling user car.
---@return physics.CarControls
function physics.getCarInputControls() end

---Reduces grip for some tyres of a certain car. Invalidates current lap. Could be used as a cheap way to simulate some things
---like ice.
---@param carIndex integer @0-based car index.
---@param wheels ac.Wheel? @Wheels to affect. Default value: `ac.Wheel.All`.
---@param decrease number? @0 for tyres to act as usual, 1 for tyres to lose all grip. Default value: 0.
function physics.setGripDecrease(carIndex, wheels, decrease) end

---Not recommended to use. Invalidates lap.
---@param carIndex integer @0-based car index.
---@param wheels ac.Wheel? @Wheels to affect. Default value: `ac.Wheel.All`.
---@param aiMultiplier number? @1 for tyres to act as usual. Default value: 1.
function physics.setTyresAIMultiplier(carIndex, wheels, aiMultiplier) end

---Changes air density for a certain car. Invalidates lap.
---@param carIndex integer @0-based car index.
---@param value number @New value to multiply air density with.
function physics.setAirDensityMultiplier(carIndex, value) end

---Resets wear planks. Invalidates lap.
---@deprecated Use `physics.resetColliderWears()` instead, it works the same.
---@param carIndex integer @0-based car index.
function physics.resetWearPlanks(carIndex) end

---Resets a position of track physics objects.
---@param filter string @Name of a physics object (`'AC_POBJECT_…'`), or a filter.
function physics.resetTrackPhysicsObject(filter) end

---Blows up some tyres of a certain car. Does not invalidate current lap.
---@param carIndex integer @0-based car index.
---@param wheels ac.Wheel? @Wheels to affect. Default value: `ac.Wheel.All`.
function physics.blowTyres(carIndex, wheels) end

---Sets tyre blankets and invalidates current lap. If set, they would keep tyres at optimal temperature until car would reach 10 km/h,
---and then they would be removed. If you need to set tyres temperature for a moving car, use `physics.setTyresTemperature()`
---(to get optimal tyre temperature, use `ac.getCar(N).wheels[0].tyreOptimumTemperature`.
---@param carIndex integer @0-based car index.
---@param wheels ac.Wheel? @Wheels to affect. Default value: `ac.Wheel.All`.
---@param blanketActive boolean? @True to set tyre blankets, false to remove. Default value: `true`.
function physics.setTyresBlankets(carIndex, wheels, blanketActive) end

---Sets tyre compounds, circumventing the current setup. Use carefully in very special cases, as a last resort. Might cause physics to explode.
---@param carIndex integer @0-based car index.
---@param wheels ac.Wheel? @Wheels to affect. Default value: `ac.Wheel.All`.
---@param compoundIndex integer? @0-based index. If there is no such compound, does nothing. Default value: 0.
function physics.setTyresCompound(carIndex, wheels, compoundIndex) end

---Sets water temperature. Does not invalidate lap.
---@param carIndex integer @0-based car index.
---@param temperature number? @New tyres temperature in °C. Default value: 25.
function physics.setWaterTemperature(carIndex, temperature) end

---Sets tyres temperature and invalidates current lap. To get optimal tyre temperature, use `ac.getCar(N).wheels[0].tyreOptimumTemperature`.
---@param carIndex integer @0-based car index.
---@param wheels ac.Wheel? @Wheels to affect. Default value: `ac.Wheel.All`.
---@param temperature number? @New tyres temperature in °C. Default value: 25.
---@param destinationFlags integer? @Bit flags specifying destination: 1 for inner part of the surface, 2 for medium, 4 for outer, 8 for the core. Default value: 15.
function physics.setTyresTemperature(carIndex, wheels, temperature, destinationFlags) end

---Sets driven distance used for wear computation.
---@param carIndex integer @0-based car index.
---@param wheels ac.Wheel? @Wheels to affect. Default value: `ac.Wheel.All`.
---@param virtualKm number? @Driven distance. Default value: 0.
function physics.setTyresVirtualKM(carIndex, wheels, virtualKm) end

---Sets damage levels of a given car, invalidates lap if car body state improves.
---@param carIndex integer @0-based car index.
---@param bodyDamage vec4 @Damage for different sides in km/h.
function physics.setCarBodyDamage(carIndex, bodyDamage) end

---Sets damage level of the engine of a given car, invalidates lap if engine state improves.
---@param carIndex integer @0-based car index.
---@param engineLife number @Engine life left (1000 for new engine, breaks at 0).
function physics.setCarEngineLife(carIndex, engineLife) end

---Sets car ballast, invalidates current lap if ballast is negative.
---@param carIndex integer @0-based car index.
---@param ballast number @Ballast in kg.
function physics.setCarBallast(carIndex, ballast) end

---Sets car restrictor. Does not invalidate lap.
---@param carIndex integer @0-based car index.
---@param restrictor number @Restrictor value.
function physics.setCarRestrictor(carIndex, restrictor) end

---Activates or deactivates automatic shifter for a car. Does not invalidate lap.
---@param carIndex integer @0-based car index.
---@param active boolean? @Default value: `true`.
function physics.setCarAutoShifter(carIndex, active) end

---Enables and disables car collisions (wouldn’t affect disabled collisions in pits, more like an extra option to
--- further disable collisions). Invalidates lap.
--- Use `physics.disableCarCollisions()` instead.
---@deprecated
---@param carIndex integer @0-based car index.
---@param disable boolean|`true`|`false` @Set to `true` to disable collisions.
function physics.setCarCollisions(carIndex, disable) end

---Enables and disables car collisions (wouldn’t affect disabled collisions in pits, more like an extra option to
--- further disable collisions). Invalidates lap of the car it’s applied to.
---
--- By default won't affect remote cars (a bug, kept for backwards compatibility). Set third argument (added in 0.2.8) to `true`
--- to change that behavior.
---@param carIndex integer @0-based car index.
---@param disable boolean? @Set to `true` to disable collisions. Default value: `true`.
---@param applyToRemote boolean? @Set to `true` to apply to remote cars as well (added in 0.2.8). Default value: `false`.
function physics.disableCarCollisions(carIndex, disable, applyToRemote) end

---Resets collider wears.
---@param carIndex integer @0-based car index.
function physics.resetColliderWears(carIndex) end

---Allows and disallows car DRS. If DRS is already disallowed by track zones, wouldn’t override it, but allows to add more
--- conditions disallowing DRS further (FIA rules and all that). If DRS is already engaged, it’ll be disengaged. Does not
--- invalidate lap.
---@param carIndex integer @0-based car index.
---@param active boolean|`true`|`false` @Set to `false` to disallow use of DRS.
function physics.allowCarDRS(carIndex, active) end

---If DRS is present and available, activates or deactivates it. Does not invalidate lap.
---@param carIndex integer @0-based car index.
---@param active boolean|`true`|`false` @Set to `true` to activate or to `false` to deactivate DRS.
function physics.setCarDRS(carIndex, active) end

---Sets penalty for user car, invalidates current lap.
---@param penaltyType ac.PenaltyType @Type of penalty to apply.
---@param penaltyParam integer? @Penalty parameter (-1 for default value), actual role depends on penalty type. Default value: -1.
function physics.setCarPenalty(penaltyType, penaltyParam) end

---New Mode scripts can use this function even if the rest of Physics API is not available.
---@param allowedTyresOut integer @Set to a negative value to disable the penalty.
function physics.setAllowedTyresOut(allowedTyresOut) end

---Stops car from sleeping, invalidates current lap.
---@param carIndex integer @0-based car index.
function physics.awakeCar(carIndex) end

---Adds force to a car, invalidates current lap. Note: you have to scale your force by `dt` accordingly.
---@param carIndex integer @0-based car index.
---@param position vec3 @Point of force application.
---@param posLocal boolean|`true`|`false` @If `true`, position is treated like position relative to car coordinates, otherwise as world position.
---@param force vec3 @Force vector in N.
---@param forceLocal boolean|`true`|`false` @If `true`, force is treated like vector relative to car coordinates, otherwise as world vector.
---@param wheelIndex integer? @If set to a 0-based wheel index, force will be added to it (relative values would mean values relative to the wheel hub). Default value: -1.
function physics.addForce(carIndex, position, posLocal, force, forceLocal, wheelIndex) end

---Alters angular speed of a wheel or several. Invalidates current lap.
---@param carIndex integer @0-based car index.
---@param wheels ac.Wheel? @Wheels to affect. Default value: `ac.Wheel.All`.
---@param torque number? @Default value: 0.
function physics.addWheelTorque(carIndex, wheels, torque) end

---Alters angular speed of a wheel or several. Invalidates current lap.
---@param carIndex integer @0-based car index.
---@param wheels ac.Wheel? @Wheels to affect. Default value: `ac.Wheel.All`.
---@param angularVelocity number? @Default value: 0.
function physics.setWheelAngularVelocity(carIndex, wheels, angularVelocity) end

---Marks current lap as spoiled. Works only during the race
---@param carIndex integer
function physics.markLapAsSpoiled(carIndex) end

---Enables engine stalling (if RPM is below idling, torque would be added only if backspace is pressed). Use
---it together with `physics.setEngineRPM()` to shut off the engine.
---@param carIndex integer @0-based car index.
---@param value boolean? @Default value: `true`.
function physics.setEngineStallEnabled(carIndex, value) end

---Sets engine RPM.
---@param carIndex integer @0-based car index.
---@param rpm number
function physics.setEngineRPM(carIndex, rpm) end

---Sets name of a user, announces new name online to other clients. Could be used for some hot driver swapping.
---@param name string @First and last name separated by a space.
---@param nationCode ac.NationCode|nil @3 characters long nation code. If not set, current value is used. Default value: `nil`.
function physics.setDriverName(name, nationCode) end

---Sets name of a user’s team, announces new name online to other clients. Could be used for some hot driver swapping.
---@param team string @Team name.
function physics.setDriverTeam(team) end

---Overrides racing flag. Don’t forget to call `physics.overrideRacingFlag(ac.FlagType.None)` later to revert to original AC
---flag handling.
---@param flag ac.FlagType
function physics.overrideRacingFlag(flag) end

---Prevents car from teleporting to pits no matter what, apart from starting new session, by EMERGENCY_RESET option or with physics API. Make sure
---to release disposable when you no longer need the block.
---@return ac.Disposable
function physics.blockTeleportingToPits() end

---Load a separate Lua script and run it in physics thread. Works similar to `ac.startBackgroundWorker()`, but these workers run at
---333 frames a second and have access to some very limited physics API. Use carefully, make sure to keep scripts as lightweight as
---possible. Good if you want to simulate some continuous force. Make sure to use custom `physics.` methods to access latest physics
---state as well.
---
---Important: use this script to access some limited physics API such as `physics.addForce()`. Sim state (`ac.getSim()`, `ac.getCar()`, etc.)
---still updates at render rate. To access current car positions at physics rate, use `physics.getBodyTransform()`. Be extremely careful with
---these types of scripts: slow code will mess up physics performance!
---
---This type of worker still relies on `script.update()`. Call `worker.terminate()` to stop it. No other `worker` methods are available.
---Use shared structures to exchange data between your main script and a worker.
---@overload fun(script: string, callback: function)
---@param script string @File name (without extension) relative to script directory, or script code.
---@param data serializable @Data to pass to the script (will be available as `__input` value). Use `stringify()` if you need to pass something complex.
---@param callback fun(err: string)
function physics.startPhysicsWorker(script, data, callback) end

---Returns `true` if script can affect physics engine. If not, only `physics.raycastTrack()` is available.
---@return boolean
function physics.allowed() end

---Casts a ray from given position in a certain direction to check if it hits any physics surfaces. Returns distance to a hit,
---or -1 if there wasn’t any. Optionally can return contact point and normal too, if vectors in their place are passed.
---
---Note: smaller rays are faster to cast. Also, rays going straight down are slightly faster as well.
---@param pos vec3
---@param dir vec3
---@param length number
---@param point vec3|nil @Default value: `nil`.
---@param normal vec3|nil @Default value: `nil`.
---@return number
function physics.raycastTrack(pos, dir, length, point, normal) end

---Changes AI level. Use `ac.getCar(carIndex).aiLevel` to get current value.
---@param carIndex integer @0-based car index.
---@param level number @AI level from 0 to 2.
function physics.setAILevel(carIndex, level) end

---Disables input for an AI car, switches car to “parked” state.
---@param carIndex integer @0-based car index.
---@param active boolean? @Default value: `true`.
---@param stall boolean? @Default value: `false`.
function physics.setAINoInput(carIndex, active, stall) end

---Sets name of an AI, announces new name online to other clients. Could be used for some hot driver swapping.
---@param carIndex integer @0-based car index.
---@param name string @First and last name separated by a space.
---@param nationCode ac.NationCode|nil @3 characters long nation code. If not set, current value is used. Default value: `nil`.
function physics.setAIDriverName(carIndex, name, nationCode) end

---Sets name of an AI’s team, announces new name online to other clients. Could be used for some hot driver swapping.
---@param carIndex integer @0-based car index.
---@param team string @Team name.
function physics.setAIDriverTeam(carIndex, team) end

---Changes position of an AI car.
---@param carIndex integer @0-based car index.
---@param pos vec3
---@param dir vec3
function physics.setAICarPosition(carIndex, pos, dir) end

---Changes AI aggression. Use `ac.getCar(carIndex).aiAggression` to get current value.
---@param carIndex integer @0-based car index.
---@param aggression number @AI aggression from 0 to 1.
function physics.setAIAggression(carIndex, aggression) end

---Changes AI `[PHYSICS_HINTS] AERO_HINT` value.
---@param carIndex integer @0-based car index.
---@param value number
function physics.setAIAeroHint(carIndex, value) end

---Changes AI `[TYRES] HINT` value.
---@param carIndex integer @0-based car index.
---@param value number
function physics.setAITyresHint(carIndex, value) end

---Changes AI shifting thresholds. Once called, stops CSP logic altering thresholds dynamically.
---@param carIndex integer @0-based car index.
---@param upshift number
---@param downshift number
function physics.setAIShiftingThresholds(carIndex, upshift, downshift) end

---Changes AI caution, altering the distance it keeps from the car in front of it. Default value: `1`. Experimental.
---@param carIndex integer @0-based car index.
---@param caution number @AI caution from 0 to 16.
function physics.setAICaution(carIndex, caution) end

---Changes AI base lookahead value. Use `ac.INIConfig.carData(carIndex, 'ai.ini'):get('LOOKAHEAD', 'BASE', 12)` to
---load original value first and go from there (don’t re-read it each frame though, it’ll get expensive).
---@param carIndex integer @0-based car index.
---@param value number @New value.
function physics.setAILookaheadBase(carIndex, value) end

---Changes AI gas/brake lookahead value. Use `ac.INIConfig.carData(carIndex, 'ai.ini'):get('LOOKAHEAD', 'GAS_BRAKE_LOOKAHEAD', 10)` to
---load original value first and go from there (don’t re-read it each frame though, it’ll get expensive).
---@param carIndex integer @0-based car index.
---@param value number @New value.
function physics.setAILookaheadGasBrake(carIndex, value) end

---Changes AI brake hint value. Use `ac.INIConfig.carData(carIndex, 'ai.ini'):get('PEDALS', 'BRAKE_HINT', 1)` to
---load original value first and go from there (don’t re-read it each frame though, it’ll get expensive).
---@param carIndex integer @0-based car index.
---@param value number @New value.
function physics.setAIBrakeHint(carIndex, value) end

---Limits AI throttle pedal.
---@param carIndex integer @0-based car index.
---@param limit number @0 for limit gas pedal to 0, 1 to remove limitation.
function physics.setAIThrottleLimit(carIndex, limit) end

---Limits AI top speed. Use `math.huge` (or just 1e9) to remove limitation.
---@param carIndex integer @0-based car index.
---@param limit number @Speed in km/h.
function physics.setAITopSpeed(carIndex, limit) end

---Sets steering multiplier allowing to get cars to drive more straight in some cases.
---@param carIndex integer @0-based car index.
---@param mult number
function physics.setAISteerMultiplier(carIndex, mult) end

---Sets lateral offset along spline, can be used to get cars to drive further to the left or to the right. Actual offset
---will be limited by track width as well.
---@param carIndex integer @0-based car index.
---@param offset number @Offset from -1 (full left) to 1 (full right).
---@param overrideAiAwareness boolean? @Default value: `false`.
function physics.setAISplineOffset(carIndex, offset, overrideAiAwareness) end

---Sets lateral offset along spline, can be used to get cars to drive further to the left or to the right. Actual offset
---will be limited by track width as well.
---@param carIndex integer @0-based car index.
---@param offset number @Offset in meters, negative for left, positive for right.
---@param overrideAiAwareness boolean? @Default value: `false`.
function physics.setAISplineAbsoluteOffset(carIndex, offset, overrideAiAwareness) end

---If not loaded yet, loads new AI spline in background and uses it instead of main API spline. Experimental.
---@param carIndex integer @0-based car index.
---@param filename string @Full path to a spline file.
---@return boolean
function physics.setAISpline(carIndex, filename) end

---Changes extra AI grip (120% by default).
---@param carIndex integer @0-based car index.
---@param value number @Set to 1 for normal grip.
function physics.setExtraAIGrip(carIndex, value) end

---Controls if AI goes to pits or not.
---@param carIndex integer @0-based car index.
---@param value boolean? @Default value: `true`.
function physics.setAIPitStopRequest(carIndex, value) end

---Sets currently selected tyres, resetting damage as well.
---@param carIndex integer @0-based car index.
---@param index integer @0-based tyres index.
function physics.setAITyres(carIndex, index) end

---Triggers brake mistake causing wheels to lock on braking.
---@param carIndex integer @0-based car index.
---@param time number @Mistake time in seconds.
function physics.setAIBrakeMistake(carIndex, time) end

---Triggers traction mistake.
---@param carIndex integer @0-based car index.
---@param time number @Mistake time in seconds.
---@param severity number @Severity, acts like gas pedal multiplier.
function physics.setAITractionMistake(carIndex, time, severity) end

---Hint AIs to put rain tyres on or off, overrides default behaviour.
---@param carIndex integer @0-based car index.
---@param useRainTyres boolean|`true`|`false`
function physics.setAIRainTyres(carIndex, useRainTyres) end

---Refreshes `ac.SimState.isAdmin` flag. Returns `false` if another check is already in progress.
---@return boolean
function ac.checkAdminPrivileges() end

---Checks if server requires a password to join. Asyncronous version. Returns error (via `err` callback parameter) if this is not an online race.
---@param callback fun(err: string, data: boolean)
function ac.checkIfServerRequiresPasswordAsync(callback) end

---Sets or resets custom driver color for CSP chat app.
---@param carIndex integer @0-based car index.
---@param color rgbm|nil @Pass `nil` to reset the color. Default value: `nil`.
function ac.setDriverChatNameColor(carIndex, color) end

---Toggles visibility of car labels.
---@param carIndex integer
---@param hide boolean? @Default value: `true`.
function ac.hideCarLabels(carIndex, hide) end

---Toggles visibility of driver model. Meant to be used for debugging, but could also be used for screenshots, for example.
---@param carIndex integer
---@param isVisible boolean|`true`|`false`
function ac.setDriverVisible(carIndex, isVisible) end

---Sets how much driver mouth is opened. Requires properly configured human surface shader to have an effect.
---@param carIndex integer
---@param amount number @Value from 0 to 1.
function ac.setDriverMouthOpened(carIndex, amount) end

---Toggles driver door animation.
---@param carIndex integer
---@param isOpen boolean|`true`|`false`
---@param instant boolean|`true`|`false`
function ac.setDriverDoorOpen(carIndex, isOpen, instant) end

---Disables car recovery (happens if car is flipped or falling through ground, use if for your mode or logic car might purposely
---end up in strange places and you don’t need that auto-restart).
---@param disable boolean? @Default value: `true`.
function ac.disableCarRecovery(disable) end

---Disables quick pitstop menu.
---@param disable boolean? @Default value: `true`.
function ac.disableQuickMenuPitstop(disable) end

---Sets current camera mode.
---@param mode ac.CameraMode
function ac.setCurrentCamera(mode) end

---Sets current drivable camera mode.
---@param mode ac.DrivableCamera
function ac.setCurrentDrivableCamera(mode) end

---Sets current car camera index.
---@param mode integer @0-based index of car camera.
function ac.setCurrentCarCamera(mode) end

---Sets current track cameras set.
---@param set integer @0-based index of track cameras set (sim state has upper bound).
function ac.setCurrentTrackCamera(set) end

function ac.forceSnow() end

function ac.recenterVR() end

---Focus on a certain car.
---@param index integer @0-based car index.
function ac.focusCar(index) end

---Restart Assetto Corsa (shut it down, but before that, add a flag to “race.ini” telling launcher to restart simulation).
---@param raceIni string|nil @Optional INI data to merge with race.ini. Default value: `nil`.
function ac.restartAssettoCorsa(raceIni) end

---Shutdown Assetto Corsa.
---Not available to scripts without I/O access.
function ac.shutdownAssettoCorsa() end

---Override race score used for leaderboard sorting.
---@param carIndex integer
---@param score number @Pass `math.nan` or `math.huge` to reset to default scoring system.
function ac.setRaceScore(carIndex, score) end

---@param carIndex integer
---@param dirt number @Value from 0 (clean) to 1 (dirty).
function ac.setBodyDirt(carIndex, dirt) end

---Sends a new chat message.
---Not available to scripts without I/O access.
---@param command string?
---@return boolean @Returns `false` if message couldn’t be sent (trying to send too often, or not online).
function ac.sendChatMessage(command) end

---Sets a callback which will be called each time a new chat message arrives. Return `true` from callback to handle chat message
---and stop it from showing in chat apps.
---
---Second argument in callback stores car ID of a car that sent the message, or -1 if message comes from server.
---@param callback fun(message: string, senderCarIndex: integer, senderSessionID: integer): boolean
---@return ac.Disposable
function ac.onChatMessage(callback) end

---@param reverbValue number
function ac.setReverbValue(reverbValue) end

---Might be helpful if you’re moving camera really far away and not grabbing it for some reason. Nice Screenshots module sets it to 10
---when starting to make a screenshot.
---@param multiplier number
function ac.setExtraTrackLODMultiplier(multiplier) end

---Moves free camera to a certain position. Note: if you want to control camera fully, consider grabbing camera instead.
---@param pos vec3
function ac.setCameraPosition(pos) end

---Orients free camera. Note: if you want to control camera fully, consider grabbing camera instead.
---@param look vec3
---@param up vec3? @Default value: `vec3(0, 1, 0)`.
function ac.setCameraDirection(look, up) end

---Sets FOV of a free camera. Note: if you want to control camera fully, consider grabbing camera instead.
---@param fov number @Value in degrees.
function ac.setCameraFOV(fov) end

---Sets exposure of a free camera. Note: if you want to control camera fully, consider grabbing camera instead.
---@param exposure number
function ac.setCameraExposure(exposure) end

---Sets DOF distance of a free camera. Note: if you want to control camera fully, consider grabbing camera instead.
---@param distance number @Value in meters, or 0 to disable DOF.
function ac.setCameraDOF(distance) end

---Sets a callback which will be called when drawing driver context menu. Within, `ui.` functions can be used to add additional information.
---@param callback fun(carIndex: integer)
---@return ac.Disposable
function ui.onDriverContextMenu(callback) end

---Returns `true` if resetting car is allowed in current session, invalidates lap.
---@return boolean
function ac.isCarResetAllowed() end

---Resets car back to the track. Available in few basic modes in offline only (such as practice with a single car), invalidates lap.
function ac.resetCar() end

---Resets car back to the track and moves it a bit back. Available in few basic modes in offline only (such as practice with a single car), invalidates lap.
---@param offset number? @Distance in meters. Default value: `nil`.
function ac.takeAStepBack(offset) end

---Save car state. Saves a lot of stuff, including velocities, momentum, engine and gearbox state, damage levels. Because of that save from one car
---can’t be applied to a different car.
---
--- Library `shared/sim/cars` has few helper methods allowing to deal with saved states.
---@param callback fun(err: string, data: string)
function ac.saveCarStateAsync(callback) end

---Load car state. Available in few basic modes in offline only (such as practice with a single car), invalidates lap.
---@overload fun(data: binary, iterations: integer)
---@param data binary
---@param dataNext binary|nil @Default value: `nil`.
---@param blend number? @Default value: 0.
---@param iterations integer? @Default value: 5.
---@return boolean @Returns false if the feature is not available in the current mode.
function ac.loadCarState(data, dataNext, blend, iterations) end

---Marks current lap done by player as spoiled. Works only during the race
---@param silent boolean? @Do not show lap invalidation message. Default value: `false`.
function ac.markLapAsSpoiled(silent) end

---Works even if collisions are disabled, actually checks collider state live. Don’t use too much.
---@param car0 integer @0-based car index.
---@param car1 integer @0-based car index.
---@return boolean
function ac.areCarsColliding(car0, car1) end

---Hides or shows any apps.
---@param hidden boolean? @Default value: `true`.
function ac.setAppsHidden(hidden) end

---Tries to start the race (pretty much, just to press Start button in pits menu).
---@param instant boolean? @Skip fade-in transition. Default value: `false`.
---@return boolean @Returns `true` if started successfully.
function ac.tryToStart(instant) end

---Pauses or unpauses simulation (if possible; for example, it wouldn’t be paused online with moving car or when displaying results).
---@param active boolean|`true`|`false`
---@return boolean @Returns `true` if paused successfully.
function ac.tryToPause(active) end

---Attempts to restart current session (for offline racing only).
---@return boolean @Returns `true` if restarted successfully.
function ac.tryToRestartSession() end

---Attempts to restart current session (for offline racing only).
---@return boolean @Returns `true` if restarted successfully.
function ac.tryToSkipSession() end

---Attempts to open race menu (only available if car is in pits).
---@param tab nil|'race'|'setup'|'telemetry'|'time'|nil @Default value: `nil`.
---@return boolean @Returns `true` if restarted successfully.
function ac.tryToOpenRaceMenu(tab) end

---Teleports car to pits.
---@return boolean @Returns `true` if teleported successfully.
function ac.tryToTeleportToPits() end

---@param orbit boolean|`true`|`false`
function ac.setOrbitOnboardCamera(orbit) end

---Add fake light to a car (not realistic at all, can be used for something like bringing an attention to a recently
---teleported car with its collisions disabled).
---
--- When script reloads, colors reset if the last cars set for the car were from the script.
---@param carIndex integer @0-based car index.
---@param highlightColor rgb|nil @Pass `nil` to cancel out the highlight. Or, pass a color in 0…1 range. Default value: `nil`.
function ac.highlightCar(carIndex, highlightColor) end

---Runs a sim command usually associated with AC hotkeys, such as “Ideal Line”. Original hotkey logic is applied: for example,
---most commands won’t work if the race is not started. Returns `false` if there is no such command.
---@param command string
---@param shift boolean? @Some commands perform opposite action if shift is held down. Default value: `false`.
---@return boolean
function ac.trySimKeyPressCommand(command, shift) end

---Toggles car visibility.
---@param carIndex integer
---@param active boolean|`true`|`false`
function ac.setCarActive(carIndex, active) end

---Block Escape button from pausing AC for a few frames.
function ac.blockEscapeButton() end

---Similar to `ac.ext_applyTrackConfig()` from CSP Python API, reload a track config live. Works even if live updates are disabled. Use carefully,
---might cause a freeze or crash the game.
---Not available to scripts without I/O access.
---@param targetIndex integer @Set to -1 to apply track config, or to car index to apply a car config.
---@param data string @INI config data.
---@param flags integer? @Bit flags. 1: restore the state of track conditions, set by default. 2: partial mode (do not discard existing config loaded from INI file on a disk), set by default. 4: reload 3D-trees as well, set by default. 8: apply shader replacements from the config to the entire model, not just to meshes loaded from KN5. Use `bit.bor()` to combine flags. Default value: `uint(data_ac_ext_track_adjustments::load_adjustments_flags::default_value)`.
function ac.applyContentConfig(targetIndex, data, flags) end

---Pauses or un-pauses file system monitoring used for live reloading. Might be useful to pause it if you’re about to update a lot of configs, for example. Make sure
---to always re-enable watching afterwards though, or it’ll be re-enabled in a few seconds automatically.
---@param pause boolean|`true`|`false`
function ac.pauseFilesWatching(pause) end

---Enables and disables lights debugging outlines. Parameters can be used to tune which lights would generate those outlines.
---@param filter string
---@param count integer
---@param mode ac.LightsDebugMode
---@param distance number? @Default value: 100.
function ac.debugLights(filter, count, mode, distance) end

---Enables and disables racing line debug view. Racing line is used to keep track of dynamic wetness offset caused by cars drying up the track when driving by.
---@param active boolean? @Default value: `true`.
function ac.debugRainRacingLine(active) end

---Replace track trees with a custom list. Use `listKey` not set in “ext_config.ini” to add new lists. Feel free to call this function each frame if amount of
---data is small. For example, you can have a trees editing tool defining two lists: one rarely updating large list with already added trees and another often updating
---small list with trees being edited now.
---@param listName string @Path to list name, all tree models are loaded relative to it. Use list name already written in track config to override it.
---@param data string|nil @List of trees in that text file format, or `nil` to clear out the list. Default value: `nil`.
---@param alignSurface boolean? @Set to `true` to align trees positions and shading alogn track surface described in track config (very slow). Default value: `false`.
function ac.overrideTrackTrees(listName, data, alignSurface) end

---Enables and disables physics debugging outlines. Pass `1` as `carsMask` to show lines for the first car only, `0` to show lines for all cars
---or set specific bits to 1 for certain cars.
---@param mask ac.PhysicsDebugLines
---@param carsMask integer? @Default value: 1.
function ac.setPhysicsDebugLines(mask, carsMask) end

---@param value number
function ac.setExposureMultiplier(value) end

---Pause frame limiter (both vertical syncing and regular frame limiter). Temporary change, rolls back when script is unloaded.
---@param disable boolean? @Default value: `true`.
function ac.disableFrameLimiter(disable) end

---Checks if a Python app with given name (name of its folder) is currently loaded in-game.
---@param appName string
---@return boolean
function ac.isPythonAppActive(appName) end

---Tries to reload a Python app with given name (name of its folder).
---@param appName string
---@param withoutDisposing boolean? @Default value: `false`.
---@return boolean @Returns `false` if app with this name was not found.
function ac.reloadPythonApp(appName, withoutDisposing) end

---Alter `FFMULT` and `STEER_ASSIST` from car.ini. Original values are available in car state.
---@param carIndex integer
---@param ffbBase number
---@param ffbSteerAssist number? @Kunos use 1 for all of their cars. Default value: 1.
function ac.configureCarForceFeedback(carIndex, ffbBase, ffbSteerAssist) end

---Replace current time entirely. Also alters timezone if new time would have different DST. Note: `time` here is a global timestamp with no timezone correction!
---Can’t be reverted, changes time stored in replay. Affects offline races only. Does not work in replays.
---@param time number
---@param explicitDate boolean? @New state for `ac.StateSim.explicitDateSet` flag. Default value: `true`.
function ac.setWeatherExactUTC0Timestamp(time, explicitDate) end

---Sets current time multiplier used by WeatherFX. Affects offline races only.
---@param multiplier number
function ac.setWeatherTimeMultiplier(multiplier) end

---Adds or subtracts time offset, useful for debugging. Affects offline races only. Offset above 24 hours counts as race date being set, so if it wasn’t set
---in session settings and sun was using an equinox trajectory, it’ll use real trajectory now.
---@param offset number @Offset in seconds.
---@param instant boolean? @Set to `true` to apply change instantly. Default value: `false`.
function ac.setWeatherTimeOffset(offset, instant) end

---Override weather conditions in replay. Can be called each frame for smooth transition.
---@param set ac.ConditionsSet|nil @Pass `nil` to disable override. Default value: `nil`.
function ac.overrideReplayConditions(set) end

---Sets current VAO mode, meant to be used for debugging purposes only.
---@param mode ac.VAODebugMode
function ac.setVAOMode(mode) end

---Gets current VAO mode, meant to be used for debugging purposes only.
--- Use `ac.getSim().currentVAOMode` instead.
---@deprecated
---@return ac.VAODebugMode
function ac.getVAOMode() end

---Override camera CPL settings.
---@param intensity number? @CPL intensity, set to 0 to disable override. Default value: 0.
---@param rotation number? @CPL rotation in degrees from −180° to 180°. Default value: 0.
---@param offset number? @CPL offset in degrees from −90° to 90°. Default value: 0.
---@param iridescenceBoost number? @Boost for glass iridescence effect, from 0 to 3. Default value: 1.
function ac.setCameraCPLSettings(intensity, rotation, offset, iridescenceBoost) end

---Override scene tweaks.
---@return ac.SceneTweaks?
function ac.configureSceneTweaks() end

---Sets audio volume for given channel, value from 0 to 1. If channel is not recognized, does nothing, unless (since 0.2.4) you specify key in a
---`'your.namespace/Readable name'` format: this will register a new volume level and show it in Audio Volume app for sessions where value was
---accessed or set.
---@overload fun(value: number)
---@param audioChannelKey ac.AudioChannel
---@param value number @Value from 0 to 1.
---@param carIndex integer? @If set, applies volume as a multiplier to a specific car (currently supported: `'dirt'`, `'engine'`, `'opponents'`, `'surfaces'`, `'transmission'`, `'tyres'`, `'wind'`). Default value: -1.
function ac.setAudioVolume(audioChannelKey, value, carIndex) end

---Use `ac.setWiperMode()` instead.
---@deprecated
---@param carIndex integer
---@param wiperSpeed integer @Wiper speed index from 0 (disabled) to `ac.StateCar.wiperModes` (excluding).
function ac.setWiperSpeed(carIndex, wiperSpeed) end

---Sets track world coordinates in degrees. Not available online.
---@param coords number|vec2 @X for lattitude, Y for longitude.
---@param headingDeg number? @Heading angle in degrees, optional. Default value: `nil`.
function ac.setTrackCoordinatesDeg(coords, headingDeg) end

---Sets timezone offset for the track in seconds. Not available online. Be careful: unlike with configs, this method does not have any coordinate-related sanity checks.
---@param offset number @Offset in seconds (with DST offset added if necessary).
function ac.setTrackTimezoneOffset(offset) end

---Starts or stops instant replay.
---@param active boolean? @Default value: `true`.
---@param rewindS number? @Default value: 30.
---@return boolean @Returns false if replay is not currently available.
function ac.tryToToggleReplay(active, rewindS) end

---Sets index of a current replay frame.
---@param frameIndex integer
---@param playCounter number @Transition between frames, from 0 to 1.
function ac.setReplayPosition(frameIndex, playCounter) end

---Replace driver model with a custom one asynchronously. For method to work current and new driver models should have common skeleton.
---@param carIndex integer @0-based car index.
---@param data binary? @Use `nil` to restore original model.
---@return boolean @Returns `false` if there is no such car or if another replacement is already taking place.
function ac.replaceDriverModel(carIndex, data) end

---Toggle H-shifter to be active or not. Doesn’t have an effect if AC is not controlled by a wheel. Use `ac.getSim().controlsWithShifter`
---to check the current state.
---@param active boolean|`true`|`false`
---@return boolean
function ac.setHShifterActive(active) end

---Override camera clip planes. Pass distances in meters, or `nil` to disable the override.
---@param nearPlane number?
---@param farPlane number?
function ac.overrideCameraClipPlanes(nearPlane, farPlane) end

---Packs driver model into a replacement package.
---@param destination string
---@param lodAData binary
---@param lodBData binary
---@param configData binary
---@return boolean
function ac.packDriverModel(destination, lodAData, lodBData, configData) end

function ac.refreshVideoSettings() end

---Executes command in AC console.
---@param command string
function ac.consoleExecute(command) end

---Sets a callback which will be called each time a new command is entered in AC console. If callback would return `true`, AC wouldn’t process
---command (return it if your script recognizes command to stop further processing).
---@param callback fun(command: string): boolean
---@return ac.Disposable
function ac.onConsoleInput(callback) end

---Sets a callback which will be called each frame when computing overall audio volume level. Callback returns a number which is used as volume multiplier.
---Use this function to fade out volume for one reason or another.
---@param callback fun(): number
---@return ac.Disposable
function ac.onAudioVolumeCalculation(callback) end

---Reload control settings.
function ac.reloadControlSettings() end

---@return ac.OverlayLeaderboardParams?
function ac.accessOverlayLeaderboardParams() end

---Access car controls overwriting. Easier than simulating inputs with fake gamepads and keypresses.
---@param carIndex integer? @0-based car index (only controls for AIs and user cars can be overriden). Default value: 0.
---@return ac.CarControlsInput?
function ac.overrideCarControls(carIndex) end

---Simulate CSP hotkey (one of ones listed in Patch section of control settings in CM) press for the next few frames. Keep calling regularly if you need to hold down a button.
---@param key string @Section name from “controls.ini”.
---@param frames integer? @Number of frames to keep pressing button for. Default value: 3.
function ac.simulateCustomHotkeyPress(key, frames) end

---@return boolean
function ac.resetVRPose() end

---Changes FFB gain. Unlike `ac.setCarFFB()` in Python apps, this one takes an absolute value, not a relative offset. To get current FFB multiplier,
---use `ac.getCar(0).ffbMultiplier`.
---@param multiplier number @1 for regular 100% FFB gain.
function ac.setFFBMultiplier(multiplier) end

---Use `ac.setFirstPersonCameraFOV()`
---@deprecated.
---@param fovDeg number
function ac.setOnboardCameraFOV(fovDeg) end

---Use `ac.resetFirstPersonCameraFOV()`
---@deprecated.
function ac.resetOnboardCameraFOV() end

---Changes FOV for first person camera. To get current value, use `ac.getSim().firstPersonFOV`.
---@param fovDeg number
function ac.setFirstPersonCameraFOV(fovDeg) end

---Resets FOV for first person camera to 56° (which is a default, but actual value is loaded from “assettocorsa/cfg/camera_onboard.ini”).
---To get current value, use `ac.getSim().firstPersonFOV`.
function ac.resetFirstPersonCameraFOV() end

---Gets onboard camera parameters for a specific car.
---@param carIndex integer
---@return ac.SeatParams
function ac.getOnboardCameraParams(carIndex) end

---Gets default onboard camera parameters for a specific car (loading them from “car.ini” from car data).
---@param carIndex integer
---@return ac.SeatParams
function ac.getOnboardCameraDefaultParams(carIndex) end

---Sets onboard camera parameters for a specific car. Optional saving works for the first car only.
---@param carIndex integer
---@param params ac.SeatParams
---@param save boolean? @If `true`, new values will be saved in “view.ini” in “Documents\AC\cfg\cars” a few seconds after a call, otherwise default camera positioning app will get a “Save needed” label. Default value: `true`.
function ac.setOnboardCameraParams(carIndex, params, save) end

---Returns `true` if current camera parameters need saving (when default camera positioning app shows a “Save needed” label).
---@return boolean
function ac.areOnboardCameraParamsNeedSaving() end

---Applies an edit to AC config, such as “video.ini”, live without actually altering file on a disk. Only a very few values are
---currently supported.
---@param config 'controls.ini'|'video.ini'|'assetto_corsa.ini'|'graphics.ini'|'graphics_adjustments.ini'|'custom_rendering_modes.ini'
---@param data string @Serialized INI data.
function ac.applyLiveConfigEdit(config, data) end

---Runs asyncronously.
---@param filename string|nil @If not set, default path will be used. Default value: `nil`.
---@param format ac.ScreenshotFormat? @Default value: `ac.ScreenshotFormat.Auto`.
---@param callback nil|fun(err: string)? @Default value: `nil`.
function ac.makeScreenshot(filename, format, callback) end

---Returns a binary image JPG data containing stuff on the screen (with HUD and everything). Asynchronous version.
---@param format ac.ScreenshotFormat? @Default value: `ac.ScreenshotFormat.JPG`.
---@param callback fun(err: string, data: binary)? @Default value: `nil`.
function ac.makeSimpleScreenshot(format, callback) end

---Returns `true` if AI spline recorder is present and ready to do some recording.
---@return boolean
function ac.isAISplineRecorderPresent() end

---@return boolean
function ac.isAISplineRecorderActive() end

---@return boolean
function ac.isAISplineRecorderRecordingPitLane() end

---@return integer
function ac.getAISplineRecordedFrames() end

---@param recordPitLane boolean? @Default value: `false`.
function ac.startAISplineRecorder(recordPitLane) end

---@param saveResult boolean|`true`|`false`
---@param callback nil|fun(err: string)
function ac.stopAISplineRecorder(saveResult, callback) end

---@param desktop integer @Desktop index from 0 to 3.
---@return boolean
function ac.setCurrentDesktop(desktop) end

---Use carefully and in limited amount: currently each loaded configuration stays in memory, expects to override controls of an AI driver.
---@param carIndex integer
---@param relativeConfigName string @Config relative to Assetto Corsa user `cfg` folder.
---@return boolean @Returns `true` if applied successfully.
function ac.loadCarControlsConfiguration(carIndex, relativeConfigName) end

---@param active boolean|`true`|`false`
---@param rateOuter ac.VRSRateMode
---@param rateMiddle ac.VRSRateMode
---@param rateInner ac.VRSRateMode
---@param areaOuter number|vec2
---@param areaMiddle number|vec2
---@param areaInner number|vec2
function ac.setVRSConfigurationForVR(active, rateOuter, rateMiddle, rateInner, areaOuter, areaMiddle, areaInner) end

---Returns `false` if gaze is not available.
---@param fov number|vec2 @View angle in degrees (for example, `vec2(110, 110)`.
---@param eyeL number|vec2 @Left eye position from 0 to 1.
---@param eyeR number|vec2 @Right eye position from 0 to 1.
---@return boolean
function ac.setVRSGazeForVR(fov, eyeL, eyeR) end

---Sets custom track condition input.
---@param key string
---@param value number
function ac.setTrackCondition(key, value) end

---Use `ac.setTrackCondition()` instead.
---@deprecated
---@param conditionInput string
---@param value number
function ac.setTrackConditionInput(conditionInput, value) end

---Sets intensity of a heat shimmer zone with a given key. Returns `false` if there is no zone with such key.
---@param key integer
---@param intensity number
---@return boolean
function ac.setHeatShimmerIntensity(key, intensity) end

---Sets intensity of script flames. See docs for exhaust flames configuration on how to set them up.
---@param intensity number
function ac.setScriptFlamesIntensity(intensity) end

---Returns name of a switch, or `nil` if switch name is not available or not named.
---@param index integer @0-based index.
---@return string?
function ac.getExtraSwitchName(index) end

---Mix exterior audio for interior views. If your car has something like rolling down windows, might be a good idea to set it to 1 then.
---@param value number @Value from 0 to 1.
function ac.setExteriorAudioMix(value) end

---Set a custom value for turbo wastegate. Accessible only if turbo is adjustable.
---@param wastegate number
---@param turboIndex integer? @Default value: -1.
function ac.setTurboWastegate(wastegate, turboIndex) end

---Get number of Real Mirror mirrors in a car (for car scripts, associated car, for apps and tools — player’s car). If Real
---Mirrors are disabled or not active for that car, returns -1.
---@return integer
function ac.getRealMirrorCount() end

---@param mirrorIndex integer @0-based mirror index (leftmost mirror is 0, the first one to right of it is 1 and so on).
---@param min vec3
---@param max vec3
---@return boolean
function ac.getRealMirrorAABB(mirrorIndex, min, max) end

---Updates mirror settings for a given Real Mirror mirror (for car scripts, associated car, for apps and tools — player’s car). Easiest way is to use
---it in combination with `ac.getRealMirrorParams()`:
--- ```
--- local params = ac.getRealMirrorParams()
--- params.fov = params.fov + 1
--- ac.setRealMirrorParams(params.fov)
--- ```
---
--- Updated settings will be written onto disk a few seconds after updated values have applied (if they’re different from current values).
---
--- If called before with `userDriven` set to `false`, any subsequent calls with `userDriven` set to `true` will be ignored.
---@param mirrorIndex integer @0-based mirror index (leftmost mirror is 0, the first one to right of it is 1 and so on).
---@param paramsPtr ac.RealMirrorParams @New params to apply.
---@param userDriven boolean? @Set to `false` to not write settings to a disk and instead stop user-driven changes for current session. Default value: `true`.
function ac.setRealMirrorParams(mirrorIndex, paramsPtr, userDriven) end

---Changes behaviour of smoke going off a tyre (won’t affect dust or water splashes). Actual movement of smoke might change with CSP updates.
---@param tyreIndex integer
---@param intensity number @Use `math.nan` to restore original behaviour, or a value from 0 to 1.
---@param thickness number @A value from 0 to 1.
---@param surfaceHeat number? @Values above 0 will get entire surface to emit smoke as well. Default value: 0.
function ac.overrideTyreSmoke(tyreIndex, intensity, thickness, surfaceHeat) end

---Changes label used to display current gear. Label can be up to four symbols long. If label is 2 characters or less, it’ll be stored in a replay as well
---(do any gearboxes have labels longer than that?) Can be useful for creating automatic gearboxes and such: AC widgets will use this label, and other apps can access the label
---using `ac.getCar().gearLabel`.
---@param c string|nil @If empty or `nil`, resets label to default gear label. Default value: `nil`.
function ac.setGearLabel(c) end

---@param mode integer
function ac.setABS(mode) end

---@param mode integer
function ac.setTC(mode) end

---@param turboIndex integer
---@return boolean
function ac.isTurboWastegateAdjustable(turboIndex) end

---@param balance number
function ac.setBrakeBias(balance) end

---@param settingIndex integer
function ac.setEngineBrakeSetting(settingIndex) end

---@param state boolean|`true`|`false`
function ac.setDRS(state) end

---@param state boolean|`true`|`false`
function ac.setKERS(state) end

---@param charging boolean|`true`|`false`
function ac.setMGUHCharging(charging) end

---@param level integer
function ac.setMGUKDelivery(level) end

---@param level integer
function ac.setMGUKRecovery(level) end

function ac.switchToNeutralGear() end

---@param active boolean|`true`|`false`
function ac.setHeadlights(active) end

---Activates flashing lights for a bit.
function ac.flashLights() end

---Sets index of current wiper speed. To get current speed or number of available speeds, check `ac.StateCar`.
---@param wiperMode integer @Wiper mode index from 0 (disabled) to `ac.StateCar.wiperModes` (excluding).
function ac.setWiperMode(wiperMode) end

---@param active boolean|`true`|`false`
function ac.setHighBeams(active) end

---@param active boolean|`true`|`false`
function ac.setDaytimeLights(active) end

---@param threshold number? @Default value: 0.01.
function ac.setBrakingLightsThreshold(threshold) end

---@param mode ac.TurningLights
function ac.setTurningLights(mode) end

---Changes the state of an extra switch. Note: if switch is in hold mode, it’ll reset to its disabled state after a few frames.
--- This function ignores availability checks (but wouldn’t work if the switch has been disabled from car custom physics script).
---@param index integer @0-based index.
---@param value boolean|`true`|`false`
---@return boolean
function ac.setExtraSwitch(index, value) end

---Checks if an extra switch is available.
---@param index integer @0-based index.
---@param availableToCarControl boolean? @Car control scripts can toggle a switch even if it’s not available to user with switch flags unless switch has been disabled by car physics script. Set this parameter to `false` to check if user can toggle the state with a hotkey, or leave it as `true` if you need to verify if the switch hasn’t been disabled by physics. Default value: `true`.
---@return boolean
function ac.isExtraSwitchAvailable(index, availableToCarControl) end

---Changes index of a target car. Target car is used by car controlling API functions which don’t receive car index, such
---as `ac.setDRS()`. Originally those functions were intended for car display scripts and such, but Lua apps can alter non-player
---cars to, for example, control second car in split-screen mode or alter AI behavior.
---
---Note: not all functions and not all cars are available anyway. For example, most functions called for remote cars will not have
---any affect. Also, effect of some functions on AI cars might be cancelled out a few frames lates.
---@param carIndex integer? @0-based car index. Default value: 0.
---@return boolean
function ac.setTargetCar(carIndex) end

---@return vec4
function ac.iconColor() end

---Loads a new app if it was just added. Usually file monitoring should take care of it as well, but in some cases (like with
---symlinks) it might malfunction.
---@param appID string
---@return boolean @Returns `false` if there is no such app or if it’s already loaded.
function ac.noticeNewApp(appID) end

---Tries to unload an app and move its folder to the recycle bin. Use carefully.
---@param appID string
---@return boolean @Returns `false` if there is no such point or it can’t be used as destination at the moment (for example, if there is already another car there).
function ac.uninstallApp(appID) end

---Teleports car to a point defined by a server. Available online and only with servers with custom teleport destinations. Usual restrictions still
---apply. Meant for creating custom UI for that function.
---
---Use `ac.INIConfig.onlineExtras()` to get server config and parse destinations from there.
---@param pointIndex integer @0-based index.
---@return boolean @Returns `false` if there is no such point or it can’t be used as destination at the moment (for example, if there is already another car there).
function ac.teleportToServerPoint(pointIndex) end

---Checks if it’s possible to teleport to a custom server teleport destination. Meant for creating custom UI for that function.
---
---Use `ac.INIConfig.onlineExtras()` to get server config and parse destinations from there.
---@param pointIndex integer @0-based index.
---@return boolean
function ac.canTeleportToServerPoint(pointIndex) end

---Returns `true` if window with given ID is opened.
---@param windowID string
---@return boolean
function ac.isWindowOpen(windowID) end

---Returns `true` if window with given ID is in collapse state.
---@param windowID string
---@return boolean
function ac.isWindowCollapsed(windowID) end

---Changes window size constraints, can be used to update window size live.
---@param windowID string
---@param minSize number|vec2
---@param maxSize number|vec2
function ac.setWindowSizeConstraints(windowID, minSize, maxSize) end

---Returns `true` if window with given ID is pinned.
---@param windowID string
---@return boolean
function ac.isWindowPinned(windowID) end

---Opens or closes a window.
---@param windowID string
---@param opened boolean|`true`|`false`
function ac.setWindowOpen(windowID, opened) end

---Changes window icon. If your icon doesn’t change every frame, use this function instead of a live icon.
---@param windowID string
---@param iconID ui.Icons
function ac.setWindowIcon(windowID, iconID) end

---Sets window title.
---@param windowID string
---@param title string|nil @If `nil`, restores original title. Default value: `nil`.
function ac.setWindowTitle(windowID, title) end

---Sets window background color.
---@param windowID string
---@param color rgbm|nil @If `nil`, restores original color. Default value: `nil`.
---@param darkHeader boolean? @If `true`, window title and control elements will be painted black. Default value: `false`.
function ac.setWindowBackground(windowID, color, darkHeader) end

---Adds notifications counter to a window for something like amount of unread messages. Make sure to set it back to 0 when things have been seen.
---@param windowID string
---@param counter integer
function ac.setWindowNotificationCounter(windowID, counter) end

---If current window fades (has “FADING” flag), this value would store fading value. If background is fully opaque, value is 0.
---@return number
function ac.windowFading() end

---Fully unloads and terminates current app if possible. Execution will continue after this function, unloading will be attempted in the next frame.
---Only apps with no visible windows can be unloaded.
function ac.unloadApp() end

---Forces window with “FADING” flag to fade in even if it’s not currently hovered by a cursor or focused.
function ac.forceFadingIn() end

---@param active boolean|`true`|`false`
function ac.redirectVirtualMirror(active) end

---@param active boolean|`true`|`false`
function ac.redirectDamageDisplayer(active) end

---@param active boolean|`true`|`false`
function ac.redirectFuelWarningIndicator(active) end

---Added in CSP 0.2.7, collects information about spinners in Quick Pitstop menu. Entries are listed in order they’re shown in UI. Each
---entry has `value` storing value set in current preset, as well as `values` storing the list of values for each preset.
---Use `ac.getSim().currentQuickPitPreset` to get the currently selected presets index (0-based).
---@return {name: string, type: 'fuel'|'wing'|'compound'|'pressure'|'repair', min: integer, max: integer, readOnly: boolean, value: integer, values: integer[]}[]
function ac.getPitstopSpinners() end

---Get information about available spinners in setup menu. Names match section names of setup INI files. Value `label` might contain localized setup items. Array `itemValues` is only present for custom CSP setup entries with LUTs.
---@return {name: string, label: string, min: integer, max: integer, step: integer, value: integer, displayMultiplier: number, readOnly: boolean, units: string?, items: string[]?, itemValues: number[]?, defaultValue: integer?, showClicksMode: integer?}[]
function ac.getSetupSpinners() end

---@return boolean
function ac.isSetupAvailableToEdit() end

---@param setupValueID string
---@param fallbackValue integer? @Default value: 0.
---@return integer
function ac.getSetupSpinnerValue(setupValueID, fallbackValue) end

---Returns `false` if there is no such element or it can’t be edited now.
---@param valueName string
---@param value number
---@param presetIndex integer? @0-based preset index (if not set, currently selected preset will be changed.
---@return boolean
function ac.setPitstopSpinnerValue(valueName, value, presetIndex) end

---Change currently selected Quick Pit preset.
---Use `ac.getSim().currentQuickPitPreset` to get the currently selected presets index (0-based).
---@param preset integer @0-based index, from 0 to 2.
---@return boolean @Returns `false` if there is no such preset.
function ac.setCurrentQuickPitPreset(preset) end

---Returns `false` if there is no such element or it can’t be edited now.
---@param setupValueID string
---@param value integer
---@return boolean
function ac.setSetupSpinnerValue(setupValueID, value) end

---Refreshes list of setups. Any listeners set with `ac.onSetupsListRefresh()` will be called as well.
---@return boolean
function ac.refreshSetups() end

---Saves current setup into a file. If successful, refreshes setups list and calls any listeners set with `ac.onSetupsListRefresh()` as well.
---@param setupFilename string @Absolute path, or path relative to “Documents\Assetto Corsa\setups\<car ID>”.
---@return boolean
function ac.saveCurrentSetup(setupFilename) end

---Change currently active setup name used for saving setups.
---@param setupName string
---@param trackID string? @Default value: 'generic'.
---@param changed boolean? @Default value: `false`.
---@return boolean
function ac.setActiveSetupName(setupName, trackID, changed) end

---Loads car setup from a file. Works only from setup menu, and only if setup is not fixed.
---@param setupFilename binary @Absolute path, or path relative to “Documents\Assetto Corsa\setups\<car ID>”. Since CSP v0.1.80-preview459 can also be setup contents.
---@return boolean
function ac.loadSetup(setupFilename) end

---Resets car setup to default values. Works only from setup menu, and only if setup is not fixed.
---@return boolean @Returns `true` if successful.
function ac.resetSetupToDefault() end

---Exports current setup into a string.
---@return string
function ac.stringifyCurrentSetup() end

---Returns information about the current vote, or `nil` if there is not any. Time is in seconds.
---@return {type: 'restart'|'skip'|'kick'|'unknown', voted: boolean, ownVote: boolean, votesTotal: integer, votesYes: integer, votesQuorum: integer, timeTotal: number, timeLeft: number, targetIndex: integer?}?
function ac.getCurrentVoteDetails() end

---Returns `true` if `ac.castVote()` can be called now and it’s not an offline race or a cooldown.
---@return boolean @Returns `true` if successful.
function ac.canCastVote() end

---If `ac.canCastVote()` returns `false` due to cooldown, this option will return time in seconds until the next vote will become available.
---@return number @Returns `true` if successful.
function ac.timeToNextVote() end

---Cast a vote online. Can be used to participate in an existing vote, or to start a new vote. Votes can only be cast once in awhile.
---@param voteType 'restart'|'skip'|'kick'
---@param vote boolean? @`true` for yes, `false` for no. Default value: `true`.
---@param carIndex integer? @For `'kick'`, index of a car to kick. Default value: -1.
---@return boolean @Returns `true` if successful.
function ac.castVote(voteType, vote, carIndex) end

---Move mouse to a certain position.
---@param posPixels number|vec2 @New mouse cursor position in pixels relative to AC window.
function ac.setMousePosition(posPixels) end

---Can be used for simulating mouse clicks.
---@param isDown boolean|`true`|`false`
function ac.setMouseLeftButtonDown(isDown) end

---Can be used for simulating mouse wheel.
---@param scroll number
function ac.setMouseWheel(scroll) end

---Load a separate Lua script and run it in background. Script simply runs once and then the returned value (or an error message if any)
---will be passed to the callback. Loaded script has access only to basic `ac` API, nothing specific like accessing scene or audio, thus
---keeping things safe. Also, there’ll be a new function `os.sleep()` allowing for a script to wait a certain amount of time (in seconds).
---When called, it will also trigger callbacks set by functions like `setTimeout()`, `setInterval()` or `ac.onSharedEvent()`.
---
---You can use this background script do compute something heavy and return, like run a script to sum numbers from 0 to a quadrillon
---or load a bit of important data from a huge file. Alternatively, you can create a script which will keep running with something like
---`while true do … os.sleep(1) end`, awaking once a second to see if there are any new jobs that need doing. Note: to exchange data with
---other scripts (including your main script or other background scripts), you can also use shared events (`ac.broadcastSharedEvent()`,
---`ac.onSharedEvent()`), shared structures (`ac.connect()`) or even memory-mapped files.
---
---Creating a new background worker and initializing a VM for it takes about 10 ms (in different thread, for your main script there won’t
---be any delay at all), so plan accordingly (if you have a ton of jobs taking about 2 ms each, it might be a better option to have a
---single worker take care of them all, but if you have a few jobs each taking a second of time, feel free to create a separate worker
---for each).
---
---Workers won’t be automatically reloaded when their scripts change, but when your main script reloads they’ll be shut and reloaded as
---well. Please note: workers won’t be terminated until the next `os.sleep()` call. If you have a worker doing intense computations, it
---might be a good idea to add `os.sleep(0)` somewhere in its loop from time to time to let other threads do their thing, let callbacks
---through and allow for the whole thing to reload.
---
---Worker threads are created with low priority to ensure they won’t reduce AC performance.
---
---Documentation for worker scripts is available in `ac_background` directory. You might need to plug it to your VS Code configuration
---manually (just add a new line with it in “.vscode/settings.json”).
---@overload fun(script: string, callback: function)
---@param script string @File name (without extension) relative to script directory, or script code.
---@param data serializable|nil @Data to pass to the script (will be available as `__input` value). Use `stringify()` if you need to pass something complex. Default value: `nil`.
---@param callback fun(err: string, data: string|number|boolean)? @Default value: `nil`.
function ac.startBackgroundWorker(script, data, callback) end

---Draw virtual mirror. If Real Mirrors module is active and has its virtual mirrors option enabled, mirror might be drawn in two pieces 
---taking less space width-wise (for cars without middle mirror) or just drawn narrower. If that option is disabled, Real Mirrors will pause.
---
---Use 4:1 for aspect ratio for the mirror to be drawn properly.
---@param p1 vec2
---@param p2 vec2
---@param color rgbm? @Default value: `rgbm.colors.white`.
---@return boolean @Returns `false` if there is no virtual mirror currently available.
function ui.drawVirtualMirror(p1, p2, color) end

---@class ScriptData
---@field update fun(dt: number) @Called each frame. Param `dt` is time since the last call of `.update()` in seconds.
---@single-instance
script = {}

--[[ common/ac_audio.lua ]]

---Create a new audio event from previously loaded soundbank.
---@param event string|{event: string, dsp: ac.AudioDSP[]?} @Event name, for example, `'/cars/lada_revolution/door'` (leading “/” or “event:” prefix are optional).
---@param reverbResponse boolean|`true`|`false` @Set to true if audio event should be affected by reverb in tunnels and such.
---@param useOcclusion boolean? @Set to true if audio event should be affected by walls on configured tracks. Default value: `false`. Car audio events are always occluded if 2D.
---@return ac.AudioEvent
function ac.AudioEvent(event, reverbResponse, useOcclusion) end

---Create a new audio event from a file. Consequent calls with the same parameters would reuse previously loaded audio file.
---Note: if `loop` is set to `false` when used with `filename`, audio event will become invalid once played once. Feel free to dispose the old one
---and create a new audio event.
---@param params {filename: string, stream: {name: string, size: integer}, group: ac.AudioEvent, use3D: boolean, useOcclusion: boolean, loop: boolean, insideConeAngle: number, outsideConeAngle: number, outsideVolume: number, minDistance: number, maxDistance: number, dopplerEffect: number, dsp: ac.AudioDSP[]}|`{filename = '', stream = {name = '', size = 0}, use3D = true, loop = true}` "Table with properties:\n- `filename` (`string`): Audio filename.\n- `stream` (`{name: string, size: integer}`): Audio stream (as an alternative to `filename` for live streaming data using a memory mapped file).\n- `group` (`ac.AudioEvent`): Optional audio event group.\n- `use3D` (`boolean`): Set to `false` to load audio without any 3D effects.\n- `useOcclusion` (`boolean`): Set to `true` to let audio occlude based on track geometry (for configured tracks, 3D audio events only).\n- `loop` (`boolean`): Set to `false` to disable audio looping.\n- `insideConeAngle` (`number`): Angle in degrees at which audio is at 100% volume.\n- `outsideConeAngle` (`number`): Angle in degrees at which audio is at `outsideVolume` volume.\n- `outsideVolume` (`number`): Volume multiplier if listener is outside of the cone.\n- `minDistance` (`number`): Distance at which audio would stop going louder as it approaches listener (default is 1).\n- `maxDistance` (`number`): Distance at which audio would attenuating as it gets further away from listener (default is 10 km).\n- `dopplerEffect` (`number`): Scale for doppler effect.\n- `dsp` (`ac.AudioDSP[]`): IDs of DSPs to add."
---@param reverbResponse boolean|`true`|`false` @Set to true if audio event should be affected by reverb in tunnels and such.
---@return ac.AudioEvent
function ac.AudioEvent.fromFile(params, reverbResponse) end

---Create a new audio event group for audio events created from files.
---@param params {group: ac.AudioEvent, use3D: boolean, useOcclusion: boolean, loop: boolean, insideConeAngle: number, outsideConeAngle: number, outsideVolume: number, minDistance: number, maxDistance: number, dopplerEffect: number, dsp: ac.AudioDSP[]}|`{ use3D = true, loop = true }` "Table with properties:\n- `group` (`ac.AudioEvent`): Optional audio event group.\n- `use3D` (`boolean`): Set to `false` to load audio without any 3D effects.\n- `useOcclusion` (`boolean`): Set to `true` to let audio occlude based on track geometry (for configured tracks, 3D audio events only).\n- `loop` (`boolean`): Set to `false` to disable audio looping.\n- `insideConeAngle` (`number`): Angle in degrees at which audio is at 100% volume.\n- `outsideConeAngle` (`number`): Angle in degrees at which audio is at `outsideVolume` volume.\n- `outsideVolume` (`number`): Volume multiplier if listener is outside of the cone.\n- `minDistance` (`number`): Distance at which audio would stop going louder as it approaches listener (default is 1).\n- `maxDistance` (`number`): Distance at which audio would attenuating as it gets further away from listener (default is 10 km).\n- `dopplerEffect` (`number`): Scale for doppler effect.\n- `dsp` (`ac.AudioDSP[]`): IDs of DSPs to add."
---@param reverbResponse boolean|`true`|`false` @Set to true if audio event should be affected by reverb in tunnels and such.
---@return ac.AudioEvent
function ac.AudioEvent.group(params, reverbResponse) end
---Link audio to a node. Switches `setPosition()` to operate in local coordinates. Also, alters the velocity based on node velocity.
---Since 0.2.8, can also be used to link audio to a car: just pass a car index (as a number) instead.
---@param sceneReference integer|ac.SceneReference? @Set to `nil` to unlink the light source.
---@return self
function _ac_AudioEvent:linkTo(sceneReference) end

--[[ common/ac_light.lua ]]

---Light source on the scene. Starts working immediately after creation. Use `:dispose()` to remove it.
---@param lightType ac.LightType?
---@return ac.LightSource
function ac.LightSource(lightType) end

---Light source on the scene. Starts working immediately after creation. Use `:dispose()` to remove it.
---@class ac.LightSource
---@field lightType ac.LightType @Type of light source.
---@field position vec3 @Light position.
---@field color rgb @Light color, go above 1 to make it brighter.
---@field specularMultiplier number @Specular multiplier. Lights with it set to 0 might be a bit faster to render, especially line lights.
---@field diffuseConcentration number @Diffuse concentration. If set to 1, surfaces facing perpendicular from light source would not get lit. If lower, they’d get more and more lit, and with 0 they’d get fully lit.
---@field singleFrequency number @Increase for single-frequency effect where only surfaces with colors matching that of light source would get illuminated.
---@field range number @Range in meters.
---@field rangeGradientOffset number @Point in range at which light would start to fade, from 0 to 1. Generally lights look better with it set to 0, but if you’re trying to keep range low and light bright, sometimes it helps to be able to increase it.
---@field fadeAt number @Distance in meters at which light fades (at that distance, it would have half of its original intensity).
---@field fadeSmooth number @Distance range in which light fades. Light starts fading at `fadeAt - fadeSmooth/2` and is fully gone at `fadeAt + fadeSmooth/2`.
---@field direction vec3 @Light direction.
---@field spot number @Spot angle in degrees, if set to 0, light works like a point light. Can misbehave if set above 350° (it can be above 180°, but keep in mind, anything above 170° wouldn’t really get any dynamic shadows).
---@field spotSharpness number @Spot sharpness. At 1, edges of spotlight are fully sharp. At 0, only point that is lit to 100% is the one in the center of light spot cone.
---@field linePos vec3 @For line lights, this is a secondary position (first is `position`).
---@field lineColor rgb @For line lights, this is a secondary color (first is `color`).
---@field volumetricLight boolean @Enable volumetric light effect (requires ExtraFX to work).
---@field skipLightMap boolean @Exclude light from bounced light effect of ExtraFX (the one where light bounces from horizontal surfaces around).
---@field affectsCars boolean @If set to `false`, light would not affect cars, can speed things up slightly.
---@field showInReflections boolean @If set to `false`, light would not appear in reflection cubemap speeding things up.
---@field longSpecular number @Controls long specular effect of ExtraFX (requires SSLR), which produces extra long going outside of light range speculars on wet surfaces.
---@field shadows boolean @Use dynamic shadows.
---@field shadowsStatic boolean @Static dynamic shadows exclude any dynamic objects, so they need a much lower refresh rate.
---@field shadowsHalfResolution boolean @Half-resolution dynamic shadows for extra blurriness.
---@field shadowsExtraBlur boolean @Additional shadow blurring.
---@field shadowsSpot number @If your spotlight is too wide and you can’t reduce it, alternatively you can use a lower spot angle for shadows alone. Wouldn’t look that great though sometimes.
---@field shadowsRange number @Range of shadows, by default matches range of light source. Because those are exponential shadow maps, adjusting it might help with visual quality.
---@field shadowsBoost number @Intensity boost for exponential shadow maps.
---@field shadowsExponentialFactor number @Exponential factor for exponential shadow maps.
---@field shadowsClipPlane number @Anything closer than this value would not appear in shadow maps (works like a clipping plane perpendicular to light direction).
---@field shadowsClipSphere number @Anything closer than this value would not appear in shadow maps (works like a clipping sphere around light position).
---@field shadowsCullMode render.CullMode @Culling mode for shadows. With exponential shadow maps it’s better not to do any culling, but just in case.
---@field shadowsOffset vec3 @Offset for shadow map camera position relative to light position. Might not look that pretty, so use with caution.
local _ac_LightSource = nil

---Doesn’t do anything, kept for compatibility.
---@deprecated
function _ac_LightSource:keepAlive() end

---Link light to a node. Switches `position` and `direction` to operate in local coordinates.
---@param sceneReference ac.SceneReference? @Set to `nil` to unlink the light source.
---@return self
function _ac_LightSource:linkTo(sceneReference) end

---Removes light from the scene.
function _ac_LightSource:dispose() end

--[[ common/ac_render.lua ]]

---Affects positioning of debug shapes or meshes drawn next.
---@param pos vec3
---@param look vec3?
---@param up vec3?
---@param applySceneOriginOffset boolean? @Use it if your matrix is in world-space and not in graphics-space. Default value: `false`.
---@overload fun(transform: mat4x4, applySceneOriginOffset: boolean?)
function render.setTransform(pos, look, up, applySceneOriginOffset) end

---Bind texture to a certain slot directly. If you are going to use some shader call with the same texture a lot, it might be
---faster to simply add texture in there with something like `Texture2D txMyTexture : register(t0);` (number after “t” in “register()”)
---is the slot index and bind a texture once using this function.
---@param slot integer @Slot index from 0 to 9.
---@param texture ui.ImageSource
function render.bindTexture(slot, texture) end

---Draws a fullscreen pass with a custom shader. Shader is compiled at first run, which might take a few milliseconds.
---If you’re drawing things continuously, use `async` parameter and shader will be compiled in a separate thread,
---while drawing will be skipped until shader is ready.
---
---You can bind up to 32 textures and pass any number/boolean/vector/color/matrix values to the shader, which makes
---it a very effective tool for any custom drawing you might need to make.
---
---Example:
---```
---render.fullscreenPass({
---  async = true,
---  blendMode = render.BlendMode.BlendAdd,
---  textures = {
---    txInput1 = 'texture.png',  -- any key would work, but it’s easier to have a common prefix like “tx”
---    txInput2 = mediaPlayer,
---    txMissing = false
---  },
---  values = {
---    gValueColor = rgbm(1, 2, 0, 0.5),  -- any key would work, but it’s easier to have a common prefix like “g”
---    gValueNumber = math.random(),
---    gValueVec = vec2(1, 2),
---    gFlag = math.random() > 0.5
---  },
---  shader = [[
---    float4 main(PS_IN pin) {
---      float4 in1 = txInput1.Sample(samAnisotropic, pin.Tex);
---      float4 in2 = txInput2.Sample(samAnisotropic, pin.Tex + gValueVec);
---      return pin.ApplyFog(gFlag ? in1 + in2 * gValueColor : in2);
---    }
---  ]]
---})
---```
---
---Consider wrapping result to `pin.ApplyFog(…)` to automatically apply configured fog.
---
---Tip: to simplify and speed things up, it might make sense to move table outside of a function to reuse it from frame
---to frame, simply accessing and updating textures, values and other parameters before call. However, make sure not to
---add new textures and values, otherwise it would require to recompile shader and might lead to VRAM leaks (if you would
---end up having thousands of no more used shaders). If you don’t have a working texture at the time of first creating
---that table, use `false` for missing texture value.
---
---Note: if shader would fail to compile, a C++ exception will be triggered, terminating script completely (to prevent AC
---from crashing, C++ exceptions halt Lua script that triggered them until script gets a full reload).
---@return boolean @Returns `false` if shader is not yet ready and no drawing occured (happens only if `async` is set to `true`).
---@param params {blendMode: render.BlendMode, depthMode: render.DepthMode, depth: number, async: boolean, cacheKey: number, defines: table, textures: table, values: table, directValuesExchange: boolean, shader: string}|`{blendMode = render.BlendMode.AlphaBlend, depthMode = render.DepthMode.ReadOnlyLessEqual, textures = {}, values = {}, shader = 'float4 main(PS_IN pin) {return float4(pin.Tex.x, pin.Tex.y, 0, 1);}'}` "Table with properties:\n- `blendMode` (`render.BlendMode`): Blend mode. Default value: `render.BlendMode.AlphaBlend`.\n- `depthMode` (`render.DepthMode`): Depth mode. Default value: `render.DepthMode.ReadOnlyLessEqual`.\n- `depth` (`number`): Optional depth in meters, to use hardware-accelerated depth clipping.\n- `async` (`boolean`): If set to `true`, drawing won’t occur until shader would be compiled in a different thread.\n- `cacheKey` (`number`): Optional cache key for compiled shader (caching will depend on shader source code, but not on included files, so make sure to change the key if included files have changed).\n- `defines` (`table`): Defines to pass to the shader, either boolean, numerical or string values (don’t forget to wrap complex expressions in brackets). False values won’t appear in code and true will be replaced with 1 so you could use `#ifdef` and `#ifndef` with them.\n- `textures` (`table`): Table with textures to pass to a shader. For textures, anything passable in `ui.image()` can be used (filename, remote URL, media element, extra canvas, etc.). If you don’t have a texture and need to reset bound one, use `false` for a texture value (instead of `nil`)\n- `values` (`table`): Table with values to pass to a shader. Values can be numbers, booleans, vectors, colors or 4×4 matrix. Values will be aligned automatically.\n- `directValuesExchange` (`boolean`): If you’re reusing table between calls instead of recreating it each time and pass `true` as this parameter, `values` table will be swapped with an FFI structure allowing to skip data copying step and achieve the best performance. Note: with this mode, you’ll have to transpose matrices manually.\n- `shader` (`string`): Shader code (format is HLSL, regular DirectX shader); actual code will be added into a template in “assettocorsa/extension/internal/shader-tpl/fullscreen.fx”."
function render.fullscreenPass(params) end

---Draws a 3D quad with a custom shader. Shader is compiled at first run, which might take a few milliseconds.
---If you’re drawing things continuously, use `async` parameter and shader will be compiled in a separate thread,
---while drawing will be skipped until shader is ready.
---
---You can bind up to 32 textures and pass any number/boolean/vector/color/matrix values to the shader, which makes
---it a very effective tool for any custom drawing you might need to make.
---
---Example:
---```
---render.shaderedQuad({
---  async = true,
---  p1 = vec3(…),
---  p2 = vec3(…),
---  p3 = vec3(…),
---  p4 = vec3(…),
---  textures = {
---    txInput1 = 'texture.png',  -- any key would work, but it’s easier to have a common prefix like “tx”
---    txInput2 = mediaPlayer,
---    txMissing = false
---  },
---  values = {
---    gValueColor = rgbm(1, 2, 0, 0.5),  -- any key would work, but it’s easier to have a common prefix like “g”
---    gValueNumber = math.random(),
---    gValueVec = vec2(1, 2),
---    gFlag = math.random() > 0.5
---  },
---  shader = [[
---    float4 main(PS_IN pin) {
---      float4 in1 = txInput1.Sample(samAnisotropic, pin.Tex);
---      float4 in2 = txInput2.Sample(samAnisotropic, pin.Tex + gValueVec);
---      return pin.ApplyFog(gFlag ? in1 + in2 * gValueColor : in2);
---    }
---  ]]
---})
---```
---
---Consider wrapping result to `pin.ApplyFog(…)` to automatically apply configured fog. To set blend mode and such, use `render.setBlendMode()`.
---
---Tip: to simplify and speed things up, it might make sense to move table outside of a function to reuse it from frame
---to frame, simply accessing and updating textures, values and other parameters before call. However, make sure not to
---add new textures and values, otherwise it would require to recompile shader and might lead to VRAM leaks (if you would
---end up having thousands of no more used shaders). If you don’t have a working texture at the time of first creating
---that table, use `false` for missing texture value.
---
---Note: if shader would fail to compile, a C++ exception will be triggered, terminating script completely (to prevent AC
---from crashing, C++ exceptions halt Lua script that triggered them until script gets a full reload).
---
---Since v0.1.80-preview400 you can now pass `pos: vec3`, `width: number`, `height: number` instead to draw a camera-aligned
---quad. You can also pass optional `up: vec3` to specify upwards direction to keep quad from tilting.
---@return boolean @Returns `false` if shader is not yet ready and no drawing occured (happens only if `async` is set to `true`).
---@param params {p1: vec3, p2: vec3, p3: vec3, p4: vec3, async: boolean, cacheKey: number, defines: table, textures: table, values: table, directValuesExchange: boolean, shader: string}|`{p1 = vec3(0, 0, 0), p2 = vec3(0, 1, 0), p3 = vec3(1, 1, 0), p4 = vec3(1, 0, 0), textures = {}, values = {}, shader = 'float4 main(PS_IN pin) {return float4(pin.Tex.x, pin.Tex.y, 0, 1);}'}` "Table with properties:\n- `async` (`boolean`): If set to `true`, drawing won’t occur until shader would be compiled in a different thread.\n- `cacheKey` (`number`): Optional cache key for compiled shader (caching will depend on shader source code, but not on included files, so make sure to change the key if included files have changed).\n- `defines` (`table`): Defines to pass to the shader, either boolean, numerical or string values (don’t forget to wrap complex expressions in brackets). False values won’t appear in code and true will be replaced with 1 so you could use `#ifdef` and `#ifndef` with them.\n- `textures` (`table`): Table with textures to pass to a shader. For textures, anything passable in `ui.image()` can be used (filename, remote URL, media element, extra canvas, etc.). If you don’t have a texture and need to reset bound one, use `false` for a texture value (instead of `nil`)\n- `values` (`table`): Table with values to pass to a shader. Values can be numbers, booleans, vectors, colors or 4×4 matrix. Values will be aligned automatically.\n- `directValuesExchange` (`boolean`): If you’re reusing table between calls instead of recreating it each time and pass `true` as this parameter, `values` table will be swapped with an FFI structure allowing to skip data copying step and achieve the best performance. Note: with this mode, you’ll have to transpose matrices manually.\n- `shader` (`string`): Shader code (format is HLSL, regular DirectX shader); actual code will be added into a template in “assettocorsa/extension/internal/shader-tpl/quad.fx”."
function render.shaderedQuad(params) end

---Describes a simple mesh with no tangent or extra vertex data, only positions and packed normals.
---@alias ac.SimpleMesh integer|table

---A namespace for working with `ac.SimpleMesh` entities.
ac.SimpleMesh = {}

---Creates a description of a simple mesh with a car shape. Usually is generated from LOD D if present and not too large, otherwise uses collider mesh.
---@param carIndex integer @0-based car index.
---@param includeDriver boolean? @Set to `true` to include simplified driver model as well. Default value: `false`.
---@return ac.SimpleMesh
function ac.SimpleMesh.carShape(carIndex, includeDriver) end

---Creates a description of a simple mesh with a car collider.
---@param carIndex integer @0-based car index.
---@param actualCollider boolean? @Set to `true` to draw actual physics collider (might differ due to some physics alterations).
---@return ac.SimpleMesh
function ac.SimpleMesh.carCollider(carIndex, actualCollider) end

---Creates a description of a simple mesh with a track line.
---@param lineType integer? @0 for ideal line, 1 for pits lane. Default value: 0.
---@param absolute number? @Width in meters. Default value: 10.
---@param relative number? @Width relative to track width. Default value: 0. Final width is a sum of the two.
---@return ac.SimpleMesh
function ac.SimpleMesh.trackLine(lineType, absolute, relative) end

---Draws a 3D mesh with a custom shader. Shader is compiled at first run, which might take a few milliseconds.
---If you’re drawing things continuously, use `async` parameter and shader will be compiled in a separate thread,
---while drawing will be skipped until shader is ready.
---
---To position mesh, first call `render.setTransform()`, or use a parameter `transform = mat4x4()`. Set
---`transform = 'original'` if you want to use original mesh position.
---
---You can bind up to 32 textures and pass any number/boolean/vector/color/matrix values to the shader, which makes
---it a very effective tool for any custom drawing you might need to make.
---
---Example:
---```
---render.mesh({
---  async = true,
---  mesh = ac.findMeshes(…),
---  transform = 'original',
---  textures = {
---    txInput1 = 'texture.png',  -- any key would work, but it’s easier to have a common prefix like “tx”
---    txInput2 = mediaPlayer,
---    txMissing = false
---  },
---  values = {
---    gValueColor = rgbm(1, 2, 0, 0.5),  -- any key would work, but it’s easier to have a common prefix like “g”
---    gValueNumber = math.random(),
---    gValueVec = vec2(1, 2),
---    gFlag = math.random() > 0.5
---  },
---  shader = [[
---    float4 main(PS_IN pin) {
---      float4 in1 = txInput1.Sample(samAnisotropic, pin.Tex);
---      float4 in2 = txInput2.Sample(samAnisotropic, pin.Tex + gValueVec);
---      return pin.ApplyFog(gFlag ? in1 + in2 * gValueColor : in2);
---    }
---  ]]
---})
---```
---
---Consider wrapping result to `pin.ApplyFog(…)` to automatically apply configured fog. To set blend mode and such, use `render.setBlendMode()`.
---
---Tip: to simplify and speed things up, it might make sense to move table outside of a function to reuse it from frame
---to frame, simply accessing and updating textures, values and other parameters before call. However, make sure not to
---add new textures and values, otherwise it would require to recompile shader and might lead to VRAM leaks (if you would
---end up having thousands of no more used shaders). If you don’t have a working texture at the time of first creating
---that table, use `false` for missing texture value.
---
---Note: if shader would fail to compile, a C++ exception will be triggered, terminating script completely (to prevent AC
---from crashing, C++ exceptions halt Lua script that triggered them until script gets a full reload).
---@return boolean @Returns `false` if shader is not yet ready and no drawing occured (happens only if `async` is set to `true`).
---@param params {mesh: ac.SceneReference|ac.SimpleMesh, transform: mat4x4|'original', async: boolean, cacheKey: number, defines: table, textures: table, values: table, directValuesExchange: boolean, shader: string}|`{mesh = ac.SimpleMesh.carCollider(0), textures = {}, values = {}, shader = 'float4 main(PS_IN pin) {return float4(pin.Tex.x, pin.Tex.y, 0, 1);}'}` "Table with properties:\n- `transform` (`mat4x4|'original'`): Optional transform in world space. Does not apply to track spline.\n- `async` (`boolean`): If set to `true`, drawing won’t occur until shader would be compiled in a different thread.\n- `cacheKey` (`number`): Optional cache key for compiled shader (caching will depend on shader source code, but not on included files, so make sure to change the key if included files have changed).\n- `defines` (`table`): Defines to pass to the shader, either boolean, numerical or string values (don’t forget to wrap complex expressions in brackets). False values won’t appear in code and true will be replaced with 1 so you could use `#ifdef` and `#ifndef` with them.\n- `textures` (`table`): Table with textures to pass to a shader. For textures, anything passable in `ui.image()` can be used (filename, remote URL, media element, extra canvas, etc.). If you don’t have a texture and need to reset bound one, use `false` for a texture value (instead of `nil`)\n- `values` (`table`): Table with values to pass to a shader. Values can be numbers, booleans, vectors, colors or 4×4 matrix. Values will be aligned automatically.\n- `directValuesExchange` (`boolean`): If you’re reusing table between calls instead of recreating it each time and pass `true` as this parameter, `values` table will be swapped with an FFI structure allowing to skip data copying step and achieve the best performance. Note: with this mode, you’ll have to transpose matrices manually.\n- `shader` (`string`): Shader code (format is HLSL, regular DirectX shader); actual code will be added into a template in “assettocorsa/extension/internal/shader-tpl/mesh.fx”."
function render.mesh(params) end

---@param key string
---@param drawFn fun()
function render.measure(key, drawFn) end

--[[ common/ac_render_enums.lua ]]

---Render namespace for drawing custom shapes and other stuff like that.
render = {}

--[[ common/ac_ray.lua ]]

---Ray for simple geometric raycasting. Do not create ray manually, instead use `render.createRay(pos, dir, length)` or `render.createMouseRay()`.
---Do not alter direction directly, or, if you do, do not cast it against lines, triangles or meshes, it stores some other precomputed values
---for faster and more accurate raycasting.
---@class ray
---@field pos vec3 @Ray origin.
---@field dir vec3 @Ray direction.
---@field length number @Ray length (used for physics raycasting, shorter rays are faster).
local ray = nil

---Ray/AABB intersection.
---@param min vec3 @AABB min corner.
---@param max vec3 @AABB max corner.
---@return boolean @True if there was an intersection.
function ray:aabb(min, max) end

---Ray/thick line intersection.
---@param from vec3 @Line, starting point.
---@param to vec3 @Line, finishing point.
---@param width number @Line width.
---@return number @Intersection distance, or -1 if there was no intersection.
function ray:line(from, to, width) end

---Ray/plaane intersection.
---@param planePoint vec3
---@param planeNormal vec3
---@return number @Intersection distance, or -1 if there was no intersection.
function ray:plane(planePoint, planeNormal) end

---Ray/triangle intersection.
---@param p1 vec3 @Triangle, point A.
---@param p2 vec3 @Triangle, point B.
---@param p3 vec3 @Triangle, point C.
---@return number @Intersection distance, or -1 if there was no intersection.
function ray:triangle(p1, p2, p3) end

---Ray/sphere intersection.
---@param center vec3 @Sphere, center.
---@param radius number @Sphere, radius.
---@return number @Intersection distance, or -1 if there was no intersection.
function ray:sphere(center, radius) end

---Ray/car collider intersection.
---@param carIndex integer @0-based car index.
---@return number @Intersection distance, or -1 if there was no intersection.
function ray:carCollider(carIndex) end

---Ray/track intersection.
---@return number @Intersection distance, or -1 if there was no intersection.
function ray:track() end

---Ray/scene intersection (both with track and cars).
---@return number @Intersection distance, or -1 if there was no intersection.
function ray:scene() end

---Ray/cars intersection.
---@return number @Intersection distance, or -1 if there was no intersection.
function ray:cars() end

---Ray/physics meshes intersection.
---@param outPosition vec3? @Optional vec3 to which contact point will be written.
---@param outNormal vec3? @Optional vec3 to which contact normal will be written.
---@return number @Intersection distance, or -1 if there was no intersection.
function ray:physics(outPosition, outNormal) end

---Distance between ray and a point.
---@param p vec3 @Point.
---@return number @Distance.
function ray:distance(p) end

--[[ common/ac_positioning_helper.lua ]]

---A helper for moving things around using mouse with XYZ arrows.
---@param params {skipAxis: ('x'|'y'|'z')[], alwaysAligned: boolean?}?
---@return render.PositioningHelper
function render.PositioningHelper(params) end

---@class render.PositioningHelper
local _render_PositioningHelper = nil

function _render_PositioningHelper:__gc() end

---@param pos vec3
---@param forceInactive boolean? @Prevents PositioningHelper from moving. Default value: `false`.
---@return boolean
function _render_PositioningHelper:render(pos, forceInactive) end

---@param pos vec3
---@param look vec3
---@param forceInactive boolean? @Prevents PositioningHelper from moving. Default value: `false`.
---@return boolean
function _render_PositioningHelper:renderAligned(pos, look, forceInactive) end

---@param pos vec3
---@param look vec3
---@param up vec3
---@param forceInactive boolean? @Prevents PositioningHelper from moving. Default value: `false`.
---@return boolean
function _render_PositioningHelper:renderFullyAligned(pos, look, up, forceInactive) end

---@return boolean
function _render_PositioningHelper:anyHighlight() end

---@return boolean
function _render_PositioningHelper:movingInScreenSpace() end

--[[ common/ac_ui.lua ]]

---Something that can be used as a texture, could be a texture filename, web URL, one of special values or an extra canvas, GIF or media player.
---If value starts with “%” and points to an icon in a DLL file, icon will be loaded (for scripts with full IO access only). Special values:
---- `color::X`: solid color texture (X can be three or four numbers or a hex representation).
---- `dynamic::…`: dynamic textures (require Graphics Adjustment to work, not very reliable in general but might work for some extra effects):
----  - `dynamic::screen`: LDR texture with scene contents.
----  - `dynamic::hdr`: HDR texture with scene contents.
----  - `dynamic::depth`: non-linear scene depth.
----  - `dynamic::noise`: general 32×32 noise texture.
---- `carN::…`: texture from a car with index N (0-based index), searches the same way car config would:
---  - `carN::dynamic::X`: car dynamic texture with a given key.
---  - `carN::car::X`: texture “X” from car KN5.
---  - `carN::special::driver`: driver icon (updates live for things like active voice chat).
---  - `carN::special::livery`: livery icon.
---  - `carN::special::theme`: theme image based on car livery color.
---  - Other values will look for an extension texture.
---- `track::…`: texture the track, searches the same way car config would:
---  - `track::track::X`: texture “X” from track KN5.
---  - Other values will look for an extension texture.
---@alias ui.ImageSource ui.ExtraCanvas|ui.SharedTexture|ui.GIFPlayer|ui.MediaPlayer|ac.GeometryShot|string|nil

---Very simple thing for smooth UI animations. Call it with a number for its initial state and it would
---return you a function. Each frame, call this function with your new target value and it would give you
---a smoothly changing numerical value. Unlike functions like `math.applyLag()`, this one is a bit more
---complicated, taking into account velocity as well.
---@param initialValue number @Initial value with which animation will start.
---@param weightMult number? @Weight multiplier for smoother or faster animation. Default value: 1.
---@return fun(target: number): number
function ui.SmoothInterpolation(initialValue, weightMult) end

---Another simple helper for easily creating elements fading in and out. Just pass it a draw callback and
---and initial state (should it be visible or not), and then call returned function every frame passing it
---a boolean to specify if item should be visible or not. Example:
---```
---local timeLeft = 120
---
---local function drawTimeLeft()
---  ui.text(string.format('Time left: %02.0f', math.max(0, timeLeft)))
---  -- keep in mind: when timer would reach 0, block would still be visible for a bit while fading out, so
---  -- that’s why there is that `math.max()` call
---end
---
---local fadingTimer = ui.FadingElement(drawTimeLeft)
---
---function script.update(dt)
---  timeLeft = timeLeft - dt
---  fadingTimer(timeLeft > 0 and timeLeft < 60)  -- only show timer if time left is below 60 seconds
---end
---```
---@param drawCallback fun() @Draw callback. Would only be called if alpha is above 0.2%, so there is no overhead if element is hidden.
---@param initialState boolean? @Should element be visible from the start. Default value: `false`.
---@return fun(state: boolean)
function ui.FadingElement(drawCallback, initialState) end

---@param filename string @Filename of a file to get the icon of. File might not exist, or it could only be a file extension.
---@param specialized boolean? @Set to `true` to try and get the icon for that exact file when possible. Usually just means it’ll look for exact icons of EXE files. Default value: `false`.
---@return ui.FileIcon
ui.FileIcon = function (filename, specialized) end

---Helper for drawing file icons.
---@class ui.FileIcon
local _uiFileIcon = {}

---Set icon style.
---@param style ui.FileIcon.Style
function _uiFileIcon:style(style) end

---@param name string @Name of the font, should be the name you can see when, for example, opening font with Windows Font Viewer (and not the name of the file). If your TTF file has a single font it in, you can use a path to it instead.
---@param dir string|nil @Optionally, path to a directory with TTF files in it. If provided, instead of looking for font in “content/fonts” and “extension/fonts”, CSP will scan given folder. Alternatively you can also use a path to a file here too, if you know for sure which file it’ll be (with TTF, different styles often go in different files).
---@return ui.DWriteFont
ui.DWriteFont = function (name, dir) end

---DirectWrite font name builder. Instead of using it, you can simply provide a string, but this thing might be a nicer way. You can chain its methods too:
---```
---local MyFavouriteFont = ui.DWriteFont('Best Font', './data'):weight(ui.DWriteFont.Weight.Bold):style(ui.DWriteFont.Style.Italic):stretch(ui.DWriteFont.Stretch.Condensed)
---…
---ui.pushFont(MyFavouriteFont)  -- you could also just put font here, but if defined once and reused, it would generate less garbage for GC to clean up.
---ui.dwriteText('Hello world!', 14)
---ui.popFont()
---```
---@class ui.DWriteFont
local _uiDWriteFont = {}

---Set font weight. Bold styles can be emulated even if there isn’t such font face, although quality of real font face would be better.
---@param weight ui.DWriteFont.Weight|integer @Alternatively, could be an integer in 1…999 range.
---@return self
function _uiDWriteFont:weight(weight) end

---Set font style. Italic style can be emulated even if there isn’t such font face, although quality of real font face would be better.
---@param style ui.DWriteFont.Style
---@return self
function _uiDWriteFont:style(style) end

---Set font stretch.
---@param stretch ui.DWriteFont.Stretch
---@return self
function _uiDWriteFont:stretch(stretch) end

---Set a custom axis value (available on Windows 10 Build 20348 or newer, otherwise values will be ignored).
---@param key 'weight'|'width'|'slant'|'opticalSize'|'italic'|string @Font variation table with list of keys is shown on https://fontdrop.info/.
---@param value number
---@return self
---@overload fun(s: ui.DWriteFont, values: {weight: number?, width: number?, slant: number?, opticalSize: number?, italic: number?}): self
function _uiDWriteFont:axis(key, value) end

---Disable font size rounding. Please use carefully: if you would to animate font size, it would quickly generate way too many atlases
---and increase both VRAM consumption and drawing time. If you need to animate font size, consider using `ui.beginScale()`/`ui.endScale()` instead.
---@param allow boolean? @Default value: `true`.
---@return self
function _uiDWriteFont:allowRealSizes(allow) end

---Allow or disallow use of colored emojis. If disabled, default black and white system glyphs will be drawn instead to system capabilities.
---Emoji are enabled by default.
---@param allow boolean? @Default value: `true`.
---@return self
function _uiDWriteFont:allowEmoji(allow) end

--[[ common/ac_ui.lua ]]

---Returns an icon for a given weather type
---@param weatherType ac.WeatherType
---@return ui.Icons
function ui.weatherIcon(weatherType) end

---Push style variable.
---@param varID ui.StyleVar
---@param value number|vec2
function ui.pushStyleVar(varID, value) end

---Push ID (use it if you, for example, have a list of buttons created in a loop).
---@param value number|string
function ui.pushID(value) end

---Text input control. Returns updated string (which would be the input string unless it changed, so no)
---copying there. Second return value would change to `true` when text has changed. Example:
---```
---myText = ui.inputText('Enter something:', myText)
---```
---
---Third value returned is `true` if Enter was pressed while editing text.
---@param label string
---@param str string
---@param flags ui.InputTextFlags?
---@param size vec2? @If specified, text input is multiline.
---@return string
---@return boolean
---@return boolean
function ui.inputText(label, str, flags, size) end

---Color picker control. Returns true if color has changed (as usual with Lua, colors are passed)
---by reference so update value would be put in place of old one automatically.
---@param label string
---@param color rgb|rgbm
---@param flags ui.ColorPickerFlags?
---@return boolean
function ui.colorPicker(label, color, flags) end

---Color button control. Returns true if color has changed (as usual with Lua, colors are passed)
---by reference so update value would be put in place of old one automatically.
---@param label string
---@param color rgb|rgbm
---@param flags ui.ColorPickerFlags?
---@param size vec2?
---@return boolean
function ui.colorButton(label, color, flags, size) end

---Show popup message.
---@param icon ui.Icons
---@param message string
---@param undoCallback fun()|nil @If provided, there’ll be an undo button which, when clicked, will call this callback.
---@return {button: fun(self, icon: ui.Icons, message: string, callback: fun())} @Use `ui.toast():button(icon, title, callback)` if you want to add an extra icon.
function ui.toast(icon, message, undoCallback) end

---Draw a window with transparent background.
---@generic T
---@param id string @Window ID, has to be unique within your script.
---@param pos vec2 @Window position.
---@param size vec2 @Window size.
---@param noPadding boolean? @Disables window padding. Default value: `false`.
---@param inputs boolean? @Enables inputs (buttons and such). Default value: `false`.
---@param content fun(): T? @Window content callback.
---@return T
---@overload fun(id: string, pos: vec2, size: vec2, content: fun())
---@overload fun(id: string, pos: vec2, size: vec2, noPadding: boolean, content: fun())
function ui.transparentWindow(id, pos, size, noPadding, inputs, content) end

---Draw a window with semi-transparent background.
---@generic T
---@param id string @Window ID, has to be unique within your script.
---@param pos vec2 @Window position.
---@param size vec2 @Window size.
---@param noPadding boolean? @Disables window padding. Default value: `false`.
---@param inputs boolean? @Enables inputs (buttons and such). Default value: `false`.
---@param content fun(): T? @Window content callback.
---@return T
---@overload fun(id: string, pos: vec2, size: vec2, content: fun())
---@overload fun(id: string, pos: vec2, size: vec2, noPadding: boolean, content: fun())
function ui.toolWindow(id, pos, size, noPadding, inputs, content) end

---Draw a tooltip with custom content.
---@generic T
---@param padding vec2? @Tooltip padding. Default value: `vec2(20, 8)`.
---@param content fun(): T? @Window content callback.
---@return T
---@overload fun(content: fun())
function ui.tooltip(padding, content) end

---Draw a child window: perfect for clipping content, for scrolling lists, etc. Think of it more like
---a HTML div with overflow set to either scrolling or hidden, for example.
---@generic T
---@param id string @Window ID, has to be unique within given context (like, two sub-windows of the same window should have different IDs).
---@param size vec2 @Window size.
---@param border boolean? @Window border.
---@param flags ui.WindowFlags? @Window flags.
---@param content fun(): T? @Window content callback.
---@return T?
---@overload fun(id: string, size: vec2, border: boolean, content: fun())
---@overload fun(id: string, size: vec2, content: fun())
function ui.childWindow(id, size, border, flags, content) end

---Draw a tree node element: a collapsible block with content inside it (which might include other tree
---nodes). Great for grouping things together. Note: if you need to have a tree node with changing label,
---use label like “your changing label###someUniqueID” for it to work properly. Everything after “###” will
---count as ID and not be shown. Same trick applies to other controls as well, such as tabs, buttons, etc.
---@generic T
---@param label string @Tree node label (which also acts like its ID).
---@param flags ui.TreeNodeFlags? @Tree node flags.
---@param content fun(): T? @Tree node content callback (called only if tree node is expanded).
---@return T?
---@overload fun(label: string, content: fun())
function ui.treeNode(label, flags, content) end

---Draw a section with tabs. Inside, use `ui.tabItem()` to draw actual tabs like so:
---```
---ui.tabBar('someTabBarID', function ()
---  ui.tabItem('Tab 1', function () --[[ Contents of Tab 1 ]] end)
---  ui.tabItem('Tab 2', function () --[[ Contents of Tab 2 ]] end)
---end)
---```
---@generic T
---@param id string @Tab bar ID.
---@param flags ui.TabBarFlags? @Tab bar flags.
---@param content fun(): T? @Individual tabs callback.
---@return T?
---@overload fun(id: string, content: fun())
function ui.tabBar(id, flags, content) end

---Draw a new tab in a tab bar. Note: if you need to have a tab with changing label,
---use label like “your changing label###someUniqueID” for it to work properly. Everything after “###” will
---count as ID and not be shown. Same trick applies to other controls as well, such as tree nodes, buttons, etc.
---```
---ui.tabBar('someTabBarID', function ()
---  ui.tabItem('Tab 1', function () --[[ Contents of Tab 1 ]] end)
---  ui.tabItem('Tab 2', function () --[[ Contents of Tab 2 ]] end)
---end)
---```
---@generic T
---@param label string @Tab label.
---@param flags ui.TabItemFlags? @Tab flags.
---@param content fun(): T? @Tab content callback (called only if tab is selected).
---@param opened refbool? @Pass a `refbool` with `true` value here to show close button. When clicked, value in `refbool` will  be set to `false`.
---@return T
---@overload fun(label: string, content: fun())
function ui.tabItem(label, flags, content, opened) end

---Sets a callback that will be called when image is loaded. If image is already loaded, calls `callback` immediately, before
---exiting the function.
---
---Note: By default images from local files are loaded syncronously, use `ui.setAsynchronousImagesLoading(true)` function to change this behaviour.
---@param imageSource ui.ImageSource @Path to the image, absolute or relative to script folder or AC root. URLs are also accepted.
---@param callback fun() @Callback to call once image is loaded.
function ui.onImageReady(imageSource, callback) end

---Adds context menu to previously drawn item which would open when certain mouse button would be pressed. Once it happens,
---content callback will be called each frame to draw contents of said menu.
---```
---ui.itemPopup(ui.MouseButton.Right, function ()
---  if ui.selectable('Item 1') then --[[ Item 1 was clicked ]] end
---  if ui.selectable('Item 2') then --[[ Item 2 was clicked ]] end
---  ui.separator()
---  if ui.selectable('Item 3') then --[[ Item 3 was clicked ]] end
---  -- Other types of controls would also work
---end)
---```
---@generic T
---@param id string @Context menu ID.
---@param mouseButton ui.MouseButton @Mouse button
---@param content fun(): T? @Menu content callback (called only if menu is opened).
---@return T
---@overload fun(id: string, content: fun())
---@overload fun(mouseButton: ui.MouseButton, content: fun())
---@overload fun(content: fun())
function ui.itemPopup(id, mouseButton, content) end

---Adds a dropdown list (aka combo box). Items are drawn in content callback function, or alternatively
---it can work with a list of strings and an ID of a selected item, returning either ID of selected item and
---boolean with `true` value if it was changed, or if ID is a refnumber, it would just return a boolean value
---for whatever it was changed or not.
---@generic T
---@param label string @Label of the element.
---@param previewValue string? @Preview value.
---@param flags ui.ComboFlags? @Combo box flags.
---@param content fun(): T? @Combo box items callback.
---@return T
---@overload fun(label: string, previewValue: string?, content: fun())
---@overload fun(label: string, selectedIndex: integer, flags: ui.ComboFlags, content: string[]): integer, boolean
---@overload fun(label: string, selectedIndex: refnumber, flags: ui.ComboFlags, content: string[]): boolean
function ui.combo(label, previewValue, flags, content) end

---Adds a slider. For value, either pass `refnumber` and slider would return a single boolean with `true` value
---if it was moved (and storing updated value in passed `refnumber`), or pass a regular number and then
---slider would return number and then a boolean. Example:
---```
----- With refnumber:
---local ref = refnumber(currentValue)
---if ui.slider('Test', ref) then currentValue = ref.value end
---
----- Without refnumber:
---local value, changed = ui.slider('Test', currentValue)
---if changed then currentValue = value end
---
----- Or, of course, if you don’t need to know if it changed (and, you can always use `ui.itemEdited()` as well):
---currentValue = ui.slider('Test', currentValue)
---```
---I personally prefer to hide slider label and instead use its format string to show what’s it for. IMGUI would
---not show symbols after “##”, but use them for ID calculation.
---```
---currentValue = ui.slider('##someSliderID', currentValue, 0, 100, 'Quantity: %.0f')
---```
---By the way, a bit of clarification: “##” would do
---that, but “###” would result in ID where only symbols going after “###” are taken into account. Helps if you
---have a control which label is constantly changing. For example, a tab showing a number of elements or current time.
---
---To enter value with keyboard, hold Ctrl and click on it.
---@param label string @Slider label.
---@param value refnumber|number @Current slider value.
---@param min number? @Default value: 0.
---@param max number? @Default value: 1.
---@param format string|'%.3f'|nil @C-style format string. Default value: `'%.3f'`.
---@param power number|boolean|nil @Power for non-linear slider. Default value: `1` (linear). Pass `true` to enable integer mode instead.
---@return number @Possibly updated slider value.
---@return boolean @True if slider has moved.
---@overload fun(label: string, value: number, min: number, max: number, format: string, power: number): number, boolean
function ui.slider(label, value, min, max, format, power) end

---Draws race flag of a certain type, or in a certain color in its usual position.
---Use it if you want to add a new flag type: this way, if custom UI later would replace flags with
---a different look (or even if it’s just a custom texture mod), it would still work.
---
---Note: if your script can access physics and you need a regular flag, using `physics.overrideRacingFlag()`
---would work better (it would also affect track conditions and such).
---@param color ac.FlagType|rgbm
function ui.drawRaceFlag(color) end

---Draws icon for car state, along with low fuel icon. If more than one icon is visible at once, subsequent ones are drawn
---to the right of previous icon. Settings altering position and opacity of low fuel icon also apply here. Background is
---included by default: simply pass a semi-transparent symbol here.
---@param iconID ui.Icons|fun(iconSize: number) @Might be an icon ID or anything else `ui.icon()` can take, or a function taking icon size.
---@param color rgbm? @Icon tint for background. Default value: `rgbm.colors.white`.
---@param hint string? @Optional hint appearing if mouse is hovering the icon.
function ui.drawCarIcon(iconID, color, hint) end

---Generates ID to use with `ui.icon()` to draw an icon from an atlas.
---@param filename string @Texture filename.
---@param uv1 vec2 @UV coordinates of the upper left corner.
---@param uv2 vec2 @UV coordinates of the bottom right corner.
---@return ui.Icons @Returns an ID to be used as an argument for `ui.icon()` function.
function ui.atlasIconID(filename, uv1, uv2) end

---Generates a table acting like icons atlas.
---@generic T
---@param filename string @Texture filename.
---@param columns integer @Number of columns in the atlas.
---@param rows integer @Number of rows in the atlas.
---@param icons T @Table with icons from left top corner, each icon is a table with 1-based row and column indices.
---@return T
function ui.atlasIcons(filename, columns, rows, icons) end

---Checks if system supports these media players (Microsoft Media Foundation framework was added in Windows 8). If it’s not supported,
---you can still use API, but it would fail to load any video or audio.
---@return boolean
function ui.MediaPlayer.supported() end

---Media player which can load a video and be used as a texture in calls like `ui.drawImage()`, `ui.beginTextureShade()` or `display.image()`. Also, it can load an audio
---file and play it offscreen.
---
---Since 0.1.77, media players can also be used as textures for scene references, like `ac.findMeshes(…):setMaterialTexture()`.
---
---Uses Microsoft Media Foundation framework for video decoding and hardware acceleration, so only supports codecs supported by Windows.
---Instead of asking user to install custom codecs, it might be a better idea to use [ones available by default](https://support.microsoft.com/en-us/windows/codecs-faq-392483a0-b9ac-27c7-0f61-5a7f18d408af).
---
---Usage:
---```
---local player = ui.MediaPlayer()
---player:setSource('myVideo.wmw'):setAutoPlay(true)
---
---function script.update(dt)
---  ui.drawImage(player, vec2(), vec2(400, 200))
---end
---```
---
---When first used, MMF library is loaded and a separate DirectX device is created. Usually this process is pretty much instantaneous,
---but sometimes it might take a few seconds. During that time you can still use media player methods to set source, volume, start playback, etc.
---Some things might act a bit differently though. To make sure library is loaded before use, you can use `ui.MediaPlayer.supportedAsync()` with
---a callback.
---@param source string|nil @URL or a filename. Optional, can be set later with `player:setSource()`.
---@param audioParams {rawOutput: boolean, reverbResponse: boolean, use3D: boolean, useOcclusion: boolean, insideConeAngle: number, outsideConeAngle: number, outsideVolume: number, minDistance: number, maxDistance: number, dopplerEffect: number}|nil|`{ reverbResponse = false, use3D = false }` "Table with properties:\n- `rawOutput` (`boolean`): Set to `true` to output audio directly, without FMOD (won’t respect AC audio device selection or stop when AC is paused).\n- `reverbResponse` (`boolean`): Set to `true` to get audio to react to reverb.\n- `use3D` (`boolean`): Set to `true` to load audio without any 3D effects (if not set, car display scripts have it as `true` by default and update position based on screen position, but only them).\n- `useOcclusion` (`boolean`): Set to `true` to let audio occlude based on track geometry (for configured tracks, 3D audio events only).\n- `insideConeAngle` (`number`): Angle in degrees at which audio is at 100% volume.\n- `outsideConeAngle` (`number`): Angle in degrees at which audio is at `outsideVolume` volume.\n- `outsideVolume` (`number`): Volume multiplier if listener is outside of the cone.\n- `minDistance` (`number`): Distance at which audio would stop going louder as it approaches listener (default is 1).\n- `maxDistance` (`number`): Distance at which audio would attenuating as it gets further away from listener (default is 10 km).\n- `dopplerEffect` (`number`): Scale for doppler effect."
---@return ui.MediaPlayer
function ui.MediaPlayer(source, audioParams) end

---Media player which can load a video and be used as a texture in calls like `ui.drawImage()`, `ui.beginTextureShade()` or `display.image()`. Also, it can load an audio
---file and play it offscreen.
---
---Since 0.1.77, media players can also be used as textures for scene references, like `ac.findMeshes(…):setMaterialTexture()`.
---
---Uses Microsoft Media Foundation framework for video decoding and hardware acceleration, so only supports codecs supported by Windows.
---Instead of asking user to install custom codecs, it might be a better idea to use [ones available by default](https://support.microsoft.com/en-us/windows/codecs-faq-392483a0-b9ac-27c7-0f61-5a7f18d408af).
---
---Usage:
---```
---local player = ui.MediaPlayer()
---player:setSource('myVideo.wmw'):setAutoPlay(true)
---
---function script.update(dt)
---  ui.drawImage(player, vec2(), vec2(400, 200))
---end
---```
---
---When first used, MMF library is loaded and a separate DirectX device is created. Usually this process is pretty much instantaneous,
---but sometimes it might take a few seconds. During that time you can still use media player methods to set source, volume, start playback, etc.
---Some things might act a bit differently though. To make sure library is loaded before use, you can use `ui.MediaPlayer.supportedAsync()` with
---a callback.
---@class ui.MediaPlayer
local _ui_MediaPlayer = nil

---Checks if system supports these media players (Microsoft Media Foundation framework was added in Windows 8). If it’s not supported,
---you can still use API, but it would fail to load any video or audio.
---
---Instead of this one, use `ui.MediaPlayer.supportedAsync()` which wouldn’t cause game to freeze while waiting for MMF to finish
---initializing.
---@deprecated
---@return boolean
function ui.MediaPlayer.supported() end

---Checks if system supports these media players (Microsoft Media Foundation framework was added in Windows 8). If it’s not supported,
---you can still use API, but it would fail to load any video or audio. Runs asyncronously.
---@param callback fun(supported: boolean)
function ui.MediaPlayer.supportedAsync(callback) end

---Get an audio event corresponding with with media player. Disposing this one, as well as playback controls, won’t have any effect.
---(Actually this isn’t real `ac.AudioEvent`, but it should be compatible. Can’t do a real one because underlying FMOD channel might
---change when the source changes.)
---
---For backwards compatibility, these audio events have `cameraInteriorMultiplier` set to `1` by default.
---@return ac.AudioEvent
function _ui_MediaPlayer:audio() end

---Sets file name or URL for video player to play. URL can lead to a remote resource.
---@param url string? @URL or a filename.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:setSource(url) end

---Get video resolution. Would not work right after initialization or `player:setSource()`, first video needs to finish loading.
---@return vec2 @Width and height in pixels.
function _ui_MediaPlayer:resolution() end

---Get current playback position in seconds. Can be changed with `player:setCurrentTime()`.
---@return number
function _ui_MediaPlayer:currentTime() end

---Get video duration in seconds.
---@return number
function _ui_MediaPlayer:duration() end

---Get current video volume in range between 0 and 1. Can be changed with `player:setVolume()`.
---@return number
function _ui_MediaPlayer:volume() end

---Get current video pitch. Can be changed with `player:setPitch()`.
---@return number
function _ui_MediaPlayer:pitch() end

---Get current video audio balance in range between -1 (left channel only) and 1 (right channel only). Can be changed with `player:setBalance()`.
---@return number
function _ui_MediaPlayer:balance() end

---Get current playback speed. Normal speed is 1. Can be changed with `player:setPlaybackRate()`.
---@return number
function _ui_MediaPlayer:playbackRate() end

---Get available time in seconds. If you are streaming a video, it might be a good idea to pause it until there would be enough of time available to play it.
---Note: sometimes might misbehave when combined with jumping to a future point in video.
---@return number
function _ui_MediaPlayer:availableTime() end

---Checks if video is playing now. Can be changed with `player:play()` and `player:pause()`.
---@return boolean
function _ui_MediaPlayer:playing() end

---Checks if video is looping. Can be changed with `player:setLooping()`.
---@return boolean
function _ui_MediaPlayer:looping() end

---Checks if video would be played automatically. Can be changed with `player:setAutoPlay()`.
---@return boolean
function _ui_MediaPlayer:autoPlay() end

---Checks if video is muted. Can be changed with `player:setMuted()`.
---@return boolean
function _ui_MediaPlayer:muted() end

---Checks if video has ended.
---@return boolean
function _ui_MediaPlayer:ended() end

---Checks if video player is seeking currently.
---@return boolean
function _ui_MediaPlayer:seeking() end

---Checks if video is ready. If MMF failed to load the video, it would return `false`.
---@return boolean
function _ui_MediaPlayer:hasVideo() end

---Checks if there is an audio to play.
---@return boolean
function _ui_MediaPlayer:hasAudio() end

---Sets video position.
---@param value number @New video position in seconds.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:setCurrentTime(value) end

---Sets playback speed.
---@param value number? @New speed value from 0 to 1. Default value: 1.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:setPlaybackRate(value) end

---Sets volume.
---@param value number? @New volume value from 0 to 1. Default value: 1.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:setVolume(value) end

---Sets pitch. Available only with FMOD audio.
---@param value number? @New pitch value. Default value: 1.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:setPitch(value) end

---Sets audio balance.
---@param value number? @New balance value from -1 (left channel only) to 1 (right channel only). Default value: 0.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:setBalance(value) end

---Sets muted parameter.
---@param value boolean? @Set to `true` to disable audio.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:setMuted(value) end

---Sets looping parameter.
---@param value boolean? @Set to `true` if video needs to start from beginning when it ends.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:setLooping(value) end

---Sets auto playing parameter.
---@param value boolean? @Set to `true` if video has to be started automatically.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:setAutoPlay(value) end

---Sets MIP maps generation flag. Use it if you want to tie media resource directly to a mesh instead of using it
---in UI or scriptable display.
---
---MIP maps are additional copies of the texture with half resolution, quarter resolution, etc. If in distance, GPUs
---would read those downscaled copies instead of main texture to both avoid aliasing and improve performance.
---@param value boolean? @Set to `true` to generate MIP maps.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:setGenerateMips(value) end

---If you’re using a video element in UI or a scriptable display, this method would not do anything. But if you’re
---tying media to a mesh (with, for example, `ac.findMeshes():setMaterialTexture()`), this method allows to control
---how much time is passed before video is updated to the next frame. Default value: 0.05 s for 20 FPS. Set to 0
---to update video every frame (final framerate would still be limited by frame rate of original video).
---@param period number? @Update period in seconds. Default value: 0.05.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:setUpdatePeriod(period) end

---Links playback rate to simulation speed: pauses when game or replay are paused, slows down with replay slow motion,
---speeds up with replay fast forwarding.
---@param value boolean? @Set to `true` to link playback rate.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:linkToSimulationSpeed(value) end

---Sets media element to be used as texture by calling these functions:
---```
---self:setAutoPlay(true)            -- start playing once video is ready
---self:setMuted(true)               -- without audio (it wouldn’t be proper 3D audio anyway)
---self:setLooping(true)             -- start from the beginning once it ends
---self:setGenerateMips(true)        -- generate MIPs to avoid aliasing in distance
---self:linkToSimulationSpeed(true)  -- pause when game or replay are paused, etc.
---```
---Of course, you can call those functions manually, or call this one and then use any other functions
---to change the behaviour. It’s only a helping shortcut, that’s all.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:useAsTexture() end

---Starts to play a video.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:play() end

---Pauses a video. To fully stop it, use `player:pause():setCurrentTime(0)`.
---@return ui.MediaPlayer @Returns itself for chaining several methods together.
function _ui_MediaPlayer:pause() end

---Some debug information for testing and fixing things.
---@return string
function _ui_MediaPlayer:debugText() end

---@param resolution vec2|integer @Resolution in pixels. Usually textures with sizes of power of two work the best.
---@param mips integer? @Number of MIPs for a texture. MIPs are downsized versions of main texture used to avoid aliasing. Default value: 1 (no MIPs).
---@param antialiasingMode render.AntialiasingMode? @Antialiasing mode. Default value: `render.AntialiasingMode.None` (disabled).
---@param textureFormat render.TextureFormat? @Texture format. Default value: `render.TextureFormat.R8G8B8A8.UNorm`.
---@param flags render.TextureFlags? @Extra flags. Default value: `0`.
---@return ui.ExtraCanvas
---@overload fun(resolution: vec2|integer, mips: integer, textureFormat: render.TextureFormat)
function ui.ExtraCanvas(resolution, mips, antialiasingMode, textureFormat, flags) end

---@alias ui.GaussianBlurKernelSize 7|15|23|35|63|127

---Extra canvases are textures you can use in UI calls instead of filenames or apply as material textures to scene geometry,
---and also edit them live by drawing things into them using “ui…” functions. A few possible use cases as an example:
---- If your app or display uses a complex background or another element, it might be benefitial to draw it into a texture once and then reuse it;
---- If you want to apply some advanced transformations to some graphics, it might work better to use texture;
---- It can also be used to blur some elements by drawing them into a texture and then drawing it blurred.
---
---Note: update happens from a different short-lived UI context, so interactive controls would not work here.
---@class ui.ExtraCanvas
local _ui_ExtraCanvas = nil

---Disposes canvas and releases resources.
function _ui_ExtraCanvas:dispose() end

---Return explicit MIP to use as an image. If called with index of 0, returns texture similar to main one, but only with a single MIP.
---@param index integer @0-based MIP index.
function _ui_ExtraCanvas:mip(index) end

---Sets canvas name for debugging. Canvases with set name appear in Lua Debug App, allowing to monitor their state.
---@param name string? @Name to display texture as. If set to `nil` or `false`, name will be reset and texture will be hidden.
---@return ui.ExtraCanvas @Returns itself for chaining several methods together.
function _ui_ExtraCanvas:setName(name) end

---Updates texture, calling `callback` to draw things with. If you want to do several changes, it would work better to group them in a
---single `canvas:update()` call.
---
---Note: canvas won’t be cleared here, to clear it first, use `canvas:clear()` method.
---@param callback fun(dt: number) @Drawing function. Might not be called if canvas has been disposed or isn’t available for drawing into.
---@return ui.ExtraCanvas @Returns itself for chaining several methods together.
function _ui_ExtraCanvas:update(callback) end

---Updates texture using a shadered quad. Faster than using `:update()` with `ui.renderShader()`:
---no time will be wasted setting up IMGUI pass and preparing all that data, just a single draw call.
---Shader is compiled at first run, which might take a few milliseconds.
---If you’re drawing things continuously, use `async` parameter and shader will be compiled in a separate thread,
---while drawing will be skipped until shader is ready.
---
---You can bind up to 32 textures and pass any number/boolean/vector/color/matrix values to the shader, which makes
---it a very effective tool for any custom drawing you might need to make.
---@return boolean @Returns `false` if shader is not yet ready and no drawing occured (happens only if `async` is set to `true`).
---@param params {p1: vec2, p2: vec2, uv1: vec2, uv2: vec2, mip: integer, blendMode: render.BlendMode, async: boolean, cacheKey: number, defines: table, textures: table, values: table, directValuesExchange: boolean, shader: string}|`{textures = {}, values = {}, shader = 'float4 main(PS_IN pin) {return float4(pin.Tex.x, pin.Tex.y, 0, 1);}'}` "Table with properties:\n- `p1` (`vec2`): Position of upper left corner relative to whole screen or canvas. Default value: `vec2(0, 0)`.\n- `p2` (`vec2`): Position of bottom right corner relative to whole screen or canvas. Default value: size of canvas.\n- `uv1` (`vec2`): Texture coordinates for upper left corner. Default value: `vec2(0, 0)`.\n- `uv2` (`vec2`): Texture coordinates for bottom right corner. Default value: `vec2(1, 1)`.\n- `mip` (`integer`): 0-based index of target MIP layer. Default value: `0`. Use `:mip(index - 1)` as a texture input to access previous MIP view in case you want to generate new MIPs from previous ones. If this parameter is above 0, automatic MIPs generation stops.\n- `blendMode` (`render.BlendMode`): Blend mode. Default value: `render.BlendMode.Opaque`.\n- `async` (`boolean`): If set to `true`, drawing won’t occur until shader would be compiled in a different thread.\n- `cacheKey` (`number`): Optional cache key for compiled shader (caching will depend on shader source code, but not on included files, so make sure to change the key if included files have changed).\n- `defines` (`table`): Defines to pass to the shader, either boolean, numerical or string values (don’t forget to wrap complex expressions in brackets). False values won’t appear in code and true will be replaced with 1 so you could use `#ifdef` and `#ifndef` with them.\n- `textures` (`table`): Table with textures to pass to a shader. For textures, anything passable in `ui.image()` can be used (filename, remote URL, media element, extra canvas, etc.). If you don’t have a texture and need to reset bound one, use `false` for a texture value (instead of `nil`)\n- `values` (`table`): Table with values to pass to a shader. Values can be numbers, booleans, vectors, colors or 4×4 matrix. Values will be aligned automatically.\n- `directValuesExchange` (`boolean`): If you’re reusing table between calls instead of recreating it each time and pass `true` as this parameter, `values` table will be swapped with an FFI structure allowing to skip data copying step and achieve the best performance. Note: with this mode, you’ll have to transpose matrices manually.\n- `shader` (`string`): Shader code (format is HLSL, regular DirectX shader); actual code will be added into a template in “assettocorsa/extension/internal/shader-tpl/ui.fx”."
function _ui_ExtraCanvas:updateWithShader(params) end

---Updates texture using a shader with a fullscreen pass. Faster than using `:update()` with `ui.renderShader()`:
---no time will be wasted setting up IMGUI pass and preparing all that data, just a single draw call.
---Shader is compiled at first run, which might take a few milliseconds.
---If you’re drawing things continuously, use `async` parameter and shader will be compiled in a separate thread,
---while drawing will be skipped until shader is ready.
---
---You can bind up to 32 textures and pass any number/boolean/vector/color/matrix values to the shader, which makes
---it a very effective tool for any custom drawing you might need to make.
---
---Unlike `:updateWithShader()`, this version is single pass stereo-aware and can be used in the middle of
---rendering scene, and has access to camera state and some rendering pipeline textures by default (see “fullscreen.fx” template).
---Use it if you need to prepare an offscreen buffer to apply to the scene.
---@return boolean @Returns `false` if shader is not yet ready and no drawing occured (happens only if `async` is set to `true`).
---@param params {p1: vec2, p2: vec2, uv1: vec2, uv2: vec2, mip: integer, blendMode: render.BlendMode, async: boolean, cacheKey: number, defines: table, textures: table, values: table, directValuesExchange: boolean, shader: string}|`{textures = {}, values = {}, shader = 'float4 main(PS_IN pin) {return float4(pin.Tex.x, pin.Tex.y, 0, 1);}'}` "Table with properties:\n- `p1` (`vec2`): Position of upper left corner relative to whole screen or canvas. Default value: `vec2(0, 0)`.\n- `p2` (`vec2`): Position of bottom right corner relative to whole screen or canvas. Default value: size of canvas.\n- `uv1` (`vec2`): Texture coordinates for upper left corner. Default value: `vec2(0, 0)`.\n- `uv2` (`vec2`): Texture coordinates for bottom right corner. Default value: `vec2(1, 1)`.\n- `mip` (`integer`): 0-based index of target MIP layer. Default value: `0`. Use `:mip(index - 1)` as a texture input to access previous MIP view in case you want to generate new MIPs from previous ones. If this parameter is above 0, automatic MIPs generation stops.\n- `blendMode` (`render.BlendMode`): Blend mode. Default value: `render.BlendMode.Opaque`.\n- `async` (`boolean`): If set to `true`, drawing won’t occur until shader would be compiled in a different thread.\n- `cacheKey` (`number`): Optional cache key for compiled shader (caching will depend on shader source code, but not on included files, so make sure to change the key if included files have changed).\n- `defines` (`table`): Defines to pass to the shader, either boolean, numerical or string values (don’t forget to wrap complex expressions in brackets). False values won’t appear in code and true will be replaced with 1 so you could use `#ifdef` and `#ifndef` with them.\n- `textures` (`table`): Table with textures to pass to a shader. For textures, anything passable in `ui.image()` can be used (filename, remote URL, media element, extra canvas, etc.). If you don’t have a texture and need to reset bound one, use `false` for a texture value (instead of `nil`)\n- `values` (`table`): Table with values to pass to a shader. Values can be numbers, booleans, vectors, colors or 4×4 matrix. Values will be aligned automatically.\n- `directValuesExchange` (`boolean`): If you’re reusing table between calls instead of recreating it each time and pass `true` as this parameter, `values` table will be swapped with an FFI structure allowing to skip data copying step and achieve the best performance. Note: with this mode, you’ll have to transpose matrices manually.\n- `shader` (`string`): Shader code (format is HLSL, regular DirectX shader); actual code will be added into a template in “assettocorsa/extension/internal/shader-tpl/ui.fx”."
function _ui_ExtraCanvas:updateSceneWithShader(params) end

---Clears canvas.
---@param col rgbm? @Default value: `rgbm.colors.transparent`.
---@return ui.ExtraCanvas @Returns itself for chaining several methods together.
function _ui_ExtraCanvas:clear(col) end

---Manually applies antialiasing to the texture (works only if it was created with a specific antialiasing mode).
---By default antialiasing is applied automatically, but calling this function switches AA to a manual mode.
---@return ui.ExtraCanvas @Returns itself for chaining several methods together.
function _ui_ExtraCanvas:applyAntialiasing() end

---Generates MIPs. Once called, switches texture to manual MIPs generating mode. Note: this operation is not that expensive, but it’s not free.
---@return ui.ExtraCanvas @Returns itself for chaining several methods together.
function _ui_ExtraCanvas:mipsUpdate() end

---Overrides exposure used if antialiasing mode is set to YEBIS value. By default scene exposure is used.
---@param value number? @Exposure used by YEBIS post-processing. Pass `nil` to reset to default behavior.
---@return ui.ExtraCanvas @Returns itself for chaining several methods together.
function _ui_ExtraCanvas:setExposure(value) end

---Saves canvas as an image.
---@param filename string @Destination filename.
---@param format ac.ImageFormat|nil @Texture format (by default guessed based on texture name).
---@return ui.ExtraCanvas @Returns itself for chaining several methods together.
function _ui_ExtraCanvas:save(filename, format) end

---Returns image encoded in DDS format. Might be useful if you would need to store an image
---in some custom form (if so, consider compressing it with `ac.compress()`).
---
---Note: you can later use `ui.decodeImage()` to get a string which you can then pass as a texture name
---to any of texture receiving functions. This way, you can load image into a new canvas later: just
---create a new canvas (possibly using `ui.imageSize()` first to get image size) and update it drawing
---imported image to the full size of the canvas.
---@return string|nil @Binary data, or `nil` if binary data export has failed.
function _ui_ExtraCanvas:encode() end

---Returns texture resolution (or zeroes if element has been disposed).
---@return vec2
function _ui_ExtraCanvas:size() end

---Returns number of MIP maps (1 for no MIP maps and it being a regular texture).
---@return integer
function _ui_ExtraCanvas:mips() end

---Returns shared handle to the texture. Shared handle can be used in other scripts with `ui.SharedTexture()`, or, if `crossProcess` flag
---is set to `true`, also accessed by other processes.
---@param crossProcess boolean? @Set to `true` to be able to pass a handle to other processes. Requires `render.TextureFlags.Shared` flag to be set during creation. Default value: `false`.
---@return integer
function _ui_ExtraCanvas:sharedHandle(crossProcess) end

---Clones current canvas.
---@return ui.ExtraCanvas @Returns new canvas.
function _ui_ExtraCanvas:clone() end

---Backup current state of canvas, return a function which can be called to restore original state. Note:
---it clones current canvas texture, so don’t make too many backup copies at once.
---@return fun() @Returns function which will restore original canvas state when called. Function can be called more than once.
function _ui_ExtraCanvas:backup() end

---Copies contents from another canvas, CPU canvas data, image or an icon. Faster than copying by drawing. If source is disposed or missing,
---does not alter the contents of the canvas.
---@param other ui.ExtraCanvas|ui.ExtraCanvasData|ui.Icons @Canvas to copy content from.
---@return ui.ExtraCanvas @Returns itself for chaining several methods together.
function _ui_ExtraCanvas:copyFrom(other) end

---Fills with canvas with blurred version of another texture, applying two optimized gaussian blur passes.
---@param other ui.ImageSource @Canvas to copy content from.
---@param kernelSize ui.GaussianBlurKernelSize? @Kernel size. Default value: 63.
---@return ui.ExtraCanvas @Returns itself for chaining several methods together.
function _ui_ExtraCanvas:gaussianBlurFrom(other, kernelSize) end

---Downloads data from GPU to CPU asyncronously (usually takes about 0.15 ms to get the data). Resulting data can be
---used to access colors of individual pixels or upload it back to CPU restoring original state.
---@param callback fun(err: string, data: ui.ExtraCanvasData)
---@return ui.ExtraCanvas @Returns itself for chaining several methods together.
function _ui_ExtraCanvas:accessData(callback) end

---Contents of `ui.ExtraCanvas` copied to CPU. There, that data can no longer be used to draw things (but it can be uploaded
---back to GPU with `canvas:copyFrom()`), but it can be used to quickly access colors of individual pixels. Unlike `ui.ExtraCanvas`,
---instances of `ui.ExtraCanvasData` consume RAM, not VRAM.
---
---To save RAM while storing several copies of data, you can use `data:compress()` to apply fast LZ4 compression. Note that each time
---you would use data by reading colors of pixels, data would get decompressed automatically. Copying extra data back to canvas with
---`canvas:copyFrom()` works with both compressed and decompressed data (data would be decompressed temporary).
---@class ui.ExtraCanvasData
local _ui_ExtraCanvasData = nil

---Disposes canvas and releases resources.
function _ui_ExtraCanvasData:dispose() end

---Compresses data using LZ4 algorithm if data wasn’t compressed already.
---@return ui.ExtraCanvasData @Returns itself for chaining several methods together.
function _ui_ExtraCanvasData:compress() end

---Returns original texture resolution (or zeroes if data has been disposed).
---@return vec2
function _ui_ExtraCanvasData:size() end

---Returns `true` if data is currently compressed.
---@return boolean
function _ui_ExtraCanvasData:compressed() end

---Returns space taken by data in bytes.
---@return integer
function _ui_ExtraCanvasData:memoryFootprint() end

---Returns numeric value of a pixel of R32FLOAT texture. If coordinates are outside, or data has been disposed, returns zeroes.
---@param x integer @0-based X coordinate.
---@param y integer @0-based Y coordinate.
---@return number @Pixel color from 0 to 1.
---@overload fun(s: ui.ExtraCanvasData, pos: vec2): number
function _ui_ExtraCanvasData:floatValue(x, y) end

---Returns color of a pixel of RGBA8888 texture. If coordinates are outside, or data has been disposed, returns zeroes.
---@param x integer @0-based X coordinate.
---@param y integer @0-based Y coordinate.
---@return rgbm @Pixel color from 0 to 1.
---@overload fun(s: ui.ExtraCanvasData, pos: vec2): rgbm
function _ui_ExtraCanvasData:color(x, y) end

---Writes color of a pixel to a provided `rgbm` value. Same as `data:color()`, but does not create new color values, so should be
---easier on garbage collector and more useful if you need to go through a lot of pixels for some reason.
---@param color rgbm @0-based X coordinate.
---@param x integer @0-based X coordinate.
---@param y integer @0-based Y coordinate.
---@return rgbm @Pixel color from 0 to 1 (same as input `color`).
---@overload fun(s: ui.ExtraCanvasData, color: rgbm, pos: vec2): rgbm
function _ui_ExtraCanvasData:colorTo(color, x, y) end

---Returns a function which returns `true` when keyboard shortcut is pressed.
---@param key {key: ui.KeyIndex, ctrl: boolean, alt: boolean, shift: boolean, super: boolean}|`{ key = ui.KeyIndex.A, ctrl = false }`
---@return fun(withRepeat: boolean|nil): boolean
---@overload fun(key: ui.KeyIndex|integer, ...): function
function ui.shortcut(key, ...) end

---Draws image using custom drawcall (not an IMGUI drawcall). Any transformations and color shifts
---wouldn’t work. But there are some extra shading features available here.
---@param params {filename: string, p1: vec2, p2: vec2, color: rgbm, colorOffset: rgbm, uv1: vec2, uv2: vec2, blendMode: render.BlendMode, mask1: string, mask1UV1: vec2, mask1UV2: vec2, mask1Flags: render.TextureMaskFlags, mask2: string, mask2UV1: vec2, mask2UV2: vec2, mask2Flags: render.TextureMaskFlags}|`{filename = '', p1 = vec2(0, 0), p2 = vec2(1, 1), color = rgbm.colors.white, uv1 = vec2(0, 0), uv2 = vec2(1, 1), blendMode = render.BlendMode.BlendAccurate}` "Table with properties:\n- `filename` (`string`): Path to the image, absolute or relative to script folder or AC root. URLs are also accepted.\n- `p1` (`vec2`): Position of upper left corner relative to whole screen or canvas.\n- `p2` (`vec2`): Position of bottom right corner relative to whole screen or canvas.\n- `color` (`rgbm`): Tint of the image, with white it would be drawn as it is. In this call, can be above 0. Default value: `rgbm.colors.white`.\n- `colorOffset` (`rgbm`): Color offset. Default value: `rgbm.colors.transparent`.\n- `uv1` (`vec2`): Texture coordinates for upper left corner. Default value: `vec2(0, 0)`.\n- `uv2` (`vec2`): Texture coordinates for bottom right corner. Default value: `vec2(1, 1)`.\n- `blendMode` (`render.BlendMode`): Blend mode. Default value: `render.BlendMode.BlendAccurate`.\n- `mask1` (`string`): Optional mask #1, resulting image will be drawn only if mask is non-transparent and with non-zero alpha channel. Default value: `nil`.\n- `mask1UV1` (`vec2`): Texture coordinates for upper left corner of a mask. Default value: `vec2(0, 0)`.\n- `mask1UV2` (`vec2`): Texture coordinates for bottom right corner of a mask. Default value: `vec2(1, 1)`.\n- `mask1Flags` (`render.TextureMaskFlags`): Flags for the first mask. Default value: 6.\n- `mask2` (`string`): Optional mask #2, resulting image will be drawn only if mask is non-transparent and with non-zero alpha channel. Default value: `nil`.\n- `mask2UV1` (`vec2`): Texture coordinates for upper left corner of a mask. Default value: `vec2(0, 0)`.\n- `mask2UV2` (`vec2`): Texture coordinates for bottom right corner of a mask. Default value: `vec2(1, 1)`.\n- `mask2Flags` (`render.TextureMaskFlags`): Flags for the second mask. Default value: 6."
function ui.renderTexture(params) end

---Draws a quad with a custom shader. Shader is compiled at first run, which might take a few milliseconds.
---If you’re drawing things continuously, use `async` parameter and shader will be compiled in a separate thread,
---while drawing will be skipped until shader is ready.
---
---You can bind up to 32 textures and pass any number/boolean/vector/color/matrix values to the shader, which makes
---it a very effective tool for any custom drawing you might need to make.
---
---Example:
---```
---ui.renderShader({
---  async = true,
---  p1 = vec2(),
---  p2 = ui.windowSize(),
---  blendMode = render.BlendMode.BlendAdd,
---  textures = {
---    txInput1 = 'texture.png',  -- any key would work, but it’s easier to have a common prefix like “tx”
---    txInput2 = mediaPlayer,
---    txMissing = false
---  },
---  values = {
---    gValueColor = rgbm(1, 2, 0, 0.5),  -- any key would work, but it’s easier to have a common prefix like “g”
---    gValueNumber = math.random(),
---    gValueVec = vec2(1, 2),
---    gFlag = math.random() > 0.5
---  },
---  shader = [[
---    float4 main(PS_IN pin) {
---      float4 in1 = txInput1.Sample(samAnisotropic, pin.Tex);
---      float4 in2 = txInput2.Sample(samAnisotropic, pin.Tex + gValueVec);
---      return gFlag ? in1 + in2 * gValueColor : in2;
---    }
---  ]]
---})
---```
---
---Tip: to simplify and speed things up, it might make sense to move table outside of a function to reuse it from frame
---to frame, simply accessing and updating textures, values and other parameters before call. However, make sure not to
---add new textures and values, otherwise it would require to recompile shader and might lead to VRAM leaks (if you would
---end up having thousands of no more used shaders). If you don’t have a working texture at the time of first creating
---that table, use `false` for missing texture value.
---
---Note: if shader would fail to compile, a C++ exception will be triggered, terminating script completely (to prevent AC
---from crashing, C++ exceptions halt Lua script that triggered them until script gets a full reload).
---@return boolean @Returns `false` if shader is not yet ready and no drawing occured (happens only if `async` is set to `true`).
---@param params {p1: vec2, p2: vec2, uv1: vec2, uv2: vec2, blendMode: render.BlendMode, async: boolean, cacheKey: number, defines: table, textures: table, values: table, directValuesExchange: boolean, shader: string}|`{p1 = vec2(0, 0), p2 = vec2(1, 1), blendMode = render.BlendMode.BlendAccurate, textures = {}, values = {}, shader = 'float4 main(PS_IN pin) {return float4(pin.Tex.x, pin.Tex.y, 0, 1);}'}` "Table with properties:\n- `p1` (`vec2`): Position of upper left corner relative to whole screen or canvas.\n- `p2` (`vec2`): Position of bottom right corner relative to whole screen or canvas.\n- `uv1` (`vec2`): Texture coordinates for upper left corner. Default value: `vec2(0, 0)`.\n- `uv2` (`vec2`): Texture coordinates for bottom right corner. Default value: `vec2(1, 1)`.\n- `blendMode` (`render.BlendMode`): Blend mode. Default value: `render.BlendMode.BlendAccurate`.\n- `async` (`boolean`): If set to `true`, drawing won’t occur until shader would be compiled in a different thread.\n- `cacheKey` (`number`): Optional cache key for compiled shader (caching will depend on shader source code, but not on included files, so make sure to change the key if included files have changed).\n- `defines` (`table`): Defines to pass to the shader, either boolean, numerical or string values (don’t forget to wrap complex expressions in brackets). False values won’t appear in code and true will be replaced with 1 so you could use `#ifdef` and `#ifndef` with them.\n- `textures` (`table`): Table with textures to pass to a shader. For textures, anything passable in `ui.image()` can be used (filename, remote URL, media element, extra canvas, etc.). If you don’t have a texture and need to reset bound one, use `false` for a texture value (instead of `nil`)\n- `values` (`table`): Table with values to pass to a shader. Values can be numbers, booleans, vectors, colors or 4×4 matrix. Values will be aligned automatically.\n- `directValuesExchange` (`boolean`): If you’re reusing table between calls instead of recreating it each time and pass `true` as this parameter, `values` table will be swapped with an FFI structure allowing to skip data copying step and achieve the best performance. Note: with this mode, you’ll have to transpose matrices manually.\n- `shader` (`string`): Shader code (format is HLSL, regular DirectX shader); actual code will be added into a template in “assettocorsa/extension/internal/shader-tpl/ui.fx”."
function ui.renderShader(params) end

---Begins new group offset horizontally to the right, pushes item width to fill available space. Call `ui.endSubgroup()` when done.
---@param offsetX number? @Default value: 20.
function ui.beginSubgroup(offsetX) end

---Ends group began with `ui.beginSubgroup()`.
function ui.endSubgroup() end

---GIF player can be used to display animated GIFs. Also supports regular and animated WEBP images.
---@param source string|{width: number, height: number, decompress: boolean?} @URL, filename or binary data.
---@return ui.GIFPlayer
function ui.GIFPlayer(source) end

---GIF player can be used to display animated GIFs. Also supports regular and animated WEBP images.
---@class ui.GIFPlayer
---@field keepRunning boolean @By default GIFs stop playing if they are not actively used in rendering. If you need them to keep running in background, set this property to `true`.
local _ui_GIFPlayer = nil

---Get GIF resolution. If GIF is not yet loaded, returns zeroes.
---@return vec2 @Width and height in pixels.
function _ui_GIFPlayer:resolution() end

---Push new bitmap data to a live-updating image.
---@param data binary
---@return boolean @Returns `false` if data doesn’t fit.
function _ui_GIFPlayer:push(data) end

---Rewinds GIF back to beginning.
---@return boolean
function _ui_GIFPlayer:rewind() end

---Checks if GIF is loaded and ready to be drawn.
---@return boolean
function _ui_GIFPlayer:ready() end

---Returns `false` if GIF decoding has failed.
---@return boolean
function _ui_GIFPlayer:valid() end

---@param handle integer @Shared texture handle. Can be either a `D3D11_RESOURCE_MISC_SHARED` handle or a handle from `:sharedHandle()` of an extra canvas.
---@param ntMode nil|integer|boolean? @Set to `true` if the handle is NT handle. Alternatively, set to an integer with source process ID. Default value: `false`. Note: for NT handles it’s better to use the named textures and pass it as a string instead (with the overload).
---@return ui.SharedTexture
---@overload fun(name: string) @Overload using name of a shared NT texture, works a lot better.
function ui.SharedTexture(handle, ntMode) end

---A wrapper for accessing textures shared by other Lua scripts or even by other applications. For the latter, textures need to have `D3D11_RESOURCE_MISC_SHARED` flag and be on the same GPU.
---@class ui.SharedTexture
local _ui_SharedTexture = nil

---Dispose texture and release its view. Call this method if remote texture is being destroyed.
function _ui_SharedTexture:dispose() end

---Sets texture name for debugging. Textures with set name appear in Lua Debug App, allowing to monitor their state.
---@param name string? @Name to display texture as. If set to `nil` or `false`, name will be reset and texture will be hidden.
---@return self @Returns itself for chaining several methods together.
function _ui_SharedTexture:setName(name) end

---Get texture handle used for creating a texture. If texture has failed to load, returns 0. If texture is loaded by name and loaded properly, returns 1.
---@return integer
function _ui_SharedTexture:handle() end

---Get texture resolution. If texture has failed to load, returns zeroes.
---@return vec2 @Width and height in pixels.
function _ui_SharedTexture:resolution() end

---Returns `false` if access to a shared texture has failed.
---@return boolean
function _ui_SharedTexture:valid() end

---Stops rest of Assetto Corsa from responding to keyboard events (key bindings, etc.), also sets `getUI().wantCaptureKeyboard` flag.
---Note: if you writing a script reacting to general keyboard events, consider checking that flag to make sure IMGUI doesn’t have
---keyboard captured currently.
---
---Resulting structure is a good way to access keyboard input data, both the button events and characters being entered.
---@param wantCaptureKeyboard boolean? @Default value: `true`.
---@param wantCaptureText boolean? @Default value: `false`.
---@param globalInput boolean? @Set to `true` to capture input from something like a script display. Default value: `false`.
---@return ui.CapturedKeyboard
function ui.captureKeyboard(wantCaptureKeyboard, wantCaptureText, globalInput) end

---Similar to `ui.invisibleButton()`, but this one can be activated similar to text input and if it is active, will monitor keyboard state.
---@param id string? @Default value: `'nil'`.
---@param size vec2? @Default value: `vec2(0, 0)`.
---@return ui.CapturedKeyboard?
---@return boolean @Set to `true` if area was just activated.
function ui.interactiveArea(id, size) end

---Create a new popup. Function `callback()` will be called each frame to render its content until popup is closed. Pass `title` in parameters to create
---a window instead (you can still call `ui.closePopup()` from the window to close it).
---@param callback fun()
---@param params {onClose: fun()?, position: vec2?, pivot: vec2?, size: vec2|{min: vec2?, max: vec2?, initial: vec2?}?, padding: vec2?, flags: ui.WindowFlags?, backgroundColor: rgbm?, title: string?, parentless: boolean?}?
function ui.popup(callback, params) end

---@class ui.CapturedKeyboard
---@field pressedCount integer @Number of buttons in `.pressed` array.
---@field pressed integer[] @Zero-based array of pressed buttons with direct access (be careful).
---@field repeated integer[] @Zero-based array of flags if pressed buttons are repeated (the same size as `pressed`).
---@field releasedCount integer @Number of buttons in `.released` array.
---@field released integer[] @Zero-based array of released buttons with direct access (be careful).
local _ui_CapturedKeyboard = nil

---Characters being typed. Automatically takes into account keyboard layout, held shift and all that stuff.
---@return string @Empty string if there were no characters.
function _ui_CapturedKeyboard:queue() end

---@return boolean
function _ui_CapturedKeyboard:down(index) end

---@param button ui.KeyIndex?
---@return boolean
function _ui_CapturedKeyboard:hotkeyCtrl(button) end

---@param button ui.KeyIndex?
---@return boolean
function _ui_CapturedKeyboard:hotkeyShift(button) end

---@param button ui.KeyIndex?
---@return boolean
function _ui_CapturedKeyboard:hotkeyAlt(button) end

---@param button ui.KeyIndex?
---@return boolean
function _ui_CapturedKeyboard:hotkeyCtrlShift(button) end

---@param button ui.KeyIndex?
---@return boolean
function _ui_CapturedKeyboard:hotkeyCtrlAlt(button) end

---@param button ui.KeyIndex?
---@return boolean
function _ui_CapturedKeyboard:hotkeyCtrlShiftAlt(button) end

---Creates a new layer with user icons. Use `carN::special::driver` to draw an icon of a driver in a certain car (replace N with 0-based car index).
---@param priority integer @Layer with higher priority will be used.
---@param column number? @Column. If set, extra icons per user can be set. Columns are ordered from lowest to biggest. To get number of icon columns use `ac.getCar().extraIconsCount`. To draw an icon X, use `carN::special::driver::X`. Note: unlike main icons, those extra icons are not drawn in most parts of UI. New CSP UI only draws up to two extra icons per driver.
---@return fun(carIndex: integer, icon: ui.Icons) @Call this function to override actual icons using 0-based car index. Note: car scripts can override icon of their drivers only.
function ui.UserIconsLayer(priority, column) end

---Note: unlike `ui.itemRectMin()` and `ui.itemRectMax()`, this one returns references instead of creating new vectors. Be careful if you
---are to call this function and reuse results after calling it again.
---@return vec2
---@return vec2
function ui.itemRect() end

---Adds a new settings item in settings list in apps.
---@param params {icon: ui.Icons, name: string, size: {default: vec2, min: vec2, max: vec2, automatic: nil|boolean}, id: string, padding: vec2, backgroundColor: rgbm, category: 'settings'|'main'|'developer'|nil, tags: string[]|nil, parent: string, onOpen: fun(), onClose: fun(), onMenu: fun(), onRemove: fun(), keepClosed: boolean}|`{icon = ui.Icons.Settings, name = '', size = {default = vec2(), min = vec2(), max = vec2(), automatic = false}}` "Table with properties:\n- `icon` (`ui.Icons`): Settings icon.\n- `name` (`string`): Name of the settings item (name of a script by default).\n- `size` (`{default: vec2, min: vec2, max: vec2, automatic: nil|boolean}`): Size settings. Default size: `vec2(320, 240)`, default min size: `vec2(40, 20)`.\n- `id` (`string`): If specified, state of a window will be remembered across AC runs or Lua reloads.\n- `padding` (`vec2`): Custom padding for the window.\n- `backgroundColor` (`rgbm`): Custom background color for the window.\n- `category` (`'settings'|'main'|'developer'|nil`): Optionally, this function can be used for simply creating new apps.\n- `tags` (`string[]|nil`): Optional list of tags for search to find the app.\n- `parent` (`string`): ID of a parent window. If set, and parent window is found, `category` will be ignored.\n- `onOpen` (`fun()`): Callback called when the tool is opened.\n- `onClose` (`fun()`): Callback called when the tool is closed.\n- `onMenu` (`fun()`): Callback for extra items in context menu opening from taskbar.\n- `onRemove` (`fun()`): Callback called once when the tool is removed. If set, there will be an item for removing the tool in taskbar context menu.\n- `keepClosed` (`boolean`): Set to `true` to keep app closed even if it was opened before."
---@param callback fun() @Callback function to draw contents of the settings window.
---@return ac.Disposable|fun(command: 'open'|'close'|'toggle'|'opened'|'focus'|string): any
function ui.addSettings(params, callback) end

---@param from integer @1-based index, similar to string.sub().
---@param to integer @1-based index, similar to string.sub().
---@param color rgbm|nil @Default value: `nil`.
---@param bold boolean|nil @Default value: `nil`.
function ui.setNextTextSpanStyle(from, to, color, bold) end

---@param command 'getSelected'|'getText'|'setText'|'keepStateOnEscape'|'suggest'|'selectAll'|'delete'|'undo'|'redo'|'paste'|'copy'|'cut'|''
---@param argument string|number|boolean|nil @Default value: `nil`.
---@param lookActive boolean? @Default value: `true`.
---@return string?
function ui.inputTextCommand(command, argument, lookActive) end

---Draw filled circle (if `angleTo - angleFrom ≥ 2π`) or its sector. Optionally textured.
---@param center vec2 @Center of the circle.
---@param radius number @Circle radius.
---@param angleFrom number @Starting angle in radians.
---@param angleTo number @Ending angle in radians.
---@param color rgb|rgbm? @Color. Default value: `rgbm.colors.white`.
---@param image ui.ImageSource @Optional background image.
function ui.drawPie(center, radius, angleFrom, angleTo, color, image) end

--[[ common/ac_scene.lua ]]

---Sets object transformation to match transformation of a `physics.RigidBody` instance. If this object is within another object with non-identity transformation,
---it will be taken into account.
---
---There is also a method `physics.RigidBody:setTransformationFrom()` doing the opposite (and requiring an inverse of this matrix).
---@param rigidBody physics.RigidBody @Physics entity to sync transformation with.
---@param localTransform mat4x4? @Optional transformation of scene reference nodes relative to the physics entity.
---@return physics.RigidBody @Returns self for easy chaining.
function _ac_SceneReference:setTransformationFrom(rigidBody, localTransform) end

--[[ common/ac_scene.lua ]]

---Collect list of textures in KN5 file.
---@param kn5Filename string
---@param filter string? @Texture names filter. Default value: `'?'`.
---@return string[]? @Returns `nil` if there is no such file, no access to it or the file is damaged.
function ac.collectKN5TextureNames(kn5Filename, filter) end

---Collect list of material properties in KN5 file in a form of shader replacements config.
---@param kn5Filename string
---@param filter string? @Material names filter. Default value: `'?'`.
---@return string[]? @Returns `nil` if there is no such file, no access to it or the file is damaged.
function ac.collectKN5MaterialProperties(kn5Filename, filter) end

--[[ common/ac_display.lua ]]

---Display namespace with helper functions for creating dynamic textures.
display = {}

---Draw a rectangle.
---@param params {pos: vec2, size: vec2, color: rgbm}|`{ pos = vec2(), size = vec2(), color = rgbm.colors.white }` "Table with properties:\n- `pos` (`vec2`): Coordinates of the top left corner in pixels.\n- `size` (`vec2`): Size in pixels.\n- `color` (`rgbm`): Rectangle color."
function display.rect(params) end

---Draw an image.
---
---If you’re drawing a lot of different images, consider combining them into a single atlas and using
---`uvStart`/`uvEnd` to specify the region.
---@param params {image: string, pos: vec2, size: vec2, color: rgbm, uvStart: vec2, uvEnd: vec2}|`{image = '', pos = vec2(), size = vec2(), color = rgbm.colors.white, uvStart = vec2(0, 0), uvEnd = vec2(1, 1)}` "Table with properties:\n- `image` (`string`): Path to image to draw.\n- `pos` (`vec2`): Coordinates of the top left corner in pixels.\n- `size` (`vec2`): Size in pixels.\n- `color` (`rgbm`): Image will be multiplied by this color.\n- `uvStart` (`vec2`): UV coordinates of the top left corner.\n- `uvEnd` (`vec2`): UV coordinates of the bottom right corner."
function display.image(params) end

---Draw text using AC font.
---@param params {text: string, pos: vec2, letter: vec2, font: string, color: rgbm, alignment: number, width: number, spacing: number}|`{text = '', pos = vec2(), letter = vec2(20, 40), font = 'aria', color = rgbm.colors.white, alignment = 0, width = 200, spacing = 0}` "Table with properties:\n- `text` (`string`): Text to draw.\n- `pos` (`vec2`): Coordinates of the top left corner in pixels.\n- `letter` (`vec2`): Size of each letter.\n- `font` (`string`): AC font to draw text with, either from “content/fonts” or from a folder with a script (can refer to a subfolder).\n- `color` (`rgbm`): Text color.\n- `alignment` (`number`): 0 for left, 0.5 for center, 1 for middle, could be anything in-between. Set `width` as well so it would know in what area to align text.\n- `width` (`number`): Required for non-left alignment.\n- `spacing` (`number`): Additional offset between characters, could be either positive or negative."
function display.text(params) end

---Draw simple horizontal bar (like progress bar) consisting of several sections.
---@param params {text: string, pos: vec2, size: vec2, delta: number, activeColor: rgbm, inactiveColor: rgbm, total: integer, active: integer}|`{text = '', pos = vec2(), size = vec2(200, 40), delta = 8, activeColor = rgbm.colors.white, inactiveColor = rgbm.colors.transparent, total = 12, active = 8}` "Table with properties:\n- `text` (`string`): Text to draw.\n- `pos` (`vec2`): Coordinates of the top left corner of the bar in pixels.\n- `size` (`vec2`): Size of the whole bar.\n- `delta` (`number`): Distance between elements.\n- `activeColor` (`rgbm`): Active color.\n- `inactiveColor` (`rgbm`): Inactive color.\n- `total` (`integer`): Total number of sections.\n- `active` (`integer`): Number of active sections."
function display.horizontalBar(params) end

--[[ common/ac_extras_tracklines.lua ]]

---@return ac.TrackPaint
function ac.TrackPaint() end

--[[ common/ac_particles.lua ]]

---Table with different types of emitters.
ac.Particles = {}

---Flame emitter holding specialized settings. Set settings in a table when creating an emitter and/or change them later.
---Use `:emit(position, velocity, amount)` to actually emit flames.
---@param params {color: rgbm, size: number, temperatureMultiplier: number, flameIntensity: number}|`{color = rgbm(0.5, 0.5, 0.5, 0.5), size = 0.2, temperatureMultiplier = 1, flameIntensity = 0}` "Table with properties:\n- `color` (`rgbm`): Flame color multiplier (for red/yellow/blue adjustment use `temperatureMultiplier` instead).\n- `size` (`number`): Particles size. Default value: 0.2.\n- `temperatureMultiplier` (`number`): Temperature multipler to vary base color from red to blue. Default value: 1.\n- `flameIntensity` (`number`): Flame intensity affecting flame look and behaviour. Default value: 0."
---@return ac.Particles.Flame
function ac.Particles.Flame(params) end

---Flame emitter holding specialized settings. Set settings in a table when creating an emitter and/or change them later.
---Use `:emit(position, velocity, amount)` to actually emit flames.
---@class ac.Particles.Flame
---@field color rgbm @Flame color multiplier (for red/yellow/blue adjustment use `temperatureMultiplier` instead).
---@field size number @Particles size. Default value: 0.2.
---@field temperatureMultiplier number @Temperature multipler to vary base color from red to blue. Default value: 1.
---@field flameIntensity number @Flame intensity affecting flame look and behaviour. Default value: 0.
---@field carIndex number @0-based index of a car associated with flame emitter (affects final look).
local _ac_Particles_Flame = nil

---Emits flames from given position with certain velocity.
function _ac_Particles_Flame:emit(position, velocity, amount) end

---Sparks emitter holding specialized settings. Set settings in a table when creating an emitter and/or change them later.
---Use `:emit(position, velocity, amount)` to actually emit sparks.
---@param params {color: rgbm, life: number, size: number, directionSpread: number, positionSpread: number}|`{color = rgbm(0.5, 0.5, 0.5, 0.5), life = 4, size = 0.2, directionSpread = 1, positionSpread = 0.2}` "Table with properties:\n- `color` (`rgbm`): Sparks color.\n- `life` (`number`): Base lifetime. Default value: 4.\n- `size` (`number`): Base size. Default value: 0.2.\n- `directionSpread` (`number`): How much sparks directions vary. Default value: 1.\n- `positionSpread` (`number`): How much sparks position vary. Default value: 0.2."
---@return ac.Particles.Sparks
function ac.Particles.Sparks(params) end

---Sparks emitter holding specialized settings. Set settings in a table when creating an emitter and/or change them later.
---Use `:emit(position, velocity, amount)` to actually emit sparks.
---@class ac.Particles.Sparks
---@field color rgbm @Sparks color.
---@field life number @Base lifetime. Default value: 4.
---@field size number @Base size. Default value: 0.2.
---@field directionSpread number @How much sparks directions vary. Default value: 1.
---@field positionSpread number @How much sparks position vary. Default value: 0.2.
local _ac_Particles_Sparks = nil

---Emits sparks from given position with certain velocity.
function _ac_Particles_Sparks:emit(position, velocity, amount) end

---Smoke flags for emitters.
ac.Particles.SmokeFlags = { FadeIn = 1, DisableCollisions = 256 }

---Smoke emitter holding specialized settings. Set settings in a table when creating an emitter and/or change them later.
---Use `:emit(position, velocity, amount)` to actually emit smoke.
---@param params {color: rgbm, colorConsistency: number, thickness: number, life: number, size: number, spreadK: number, growK: number, targetYVelocity: number}|`{color = rgbm(0.5, 0.5, 0.5, 0.5), colorConsistency = 0.5, thickness = 1, life = 4, size = 0.2, spreadK = 1, growK = 1, targetYVelocity = 0}` "Table with properties:\n- `color` (`rgbm`): Smoke color with values from 0 to 1. Alpha can be used to adjust thickness. Default alpha value: 0.5.\n- `colorConsistency` (`number`): Defines how much color dissipates when smoke expands, from 0 to 1. Default value: 0.5.\n- `thickness` (`number`): How thick is smoke, from 0 to 1. Default value: 1.\n- `life` (`number`): Smoke base lifespan in seconds. Default value: 4.\n- `size` (`number`): Starting particle size in meters. Default value: 0.2.\n- `spreadK` (`number`): How randomized is smoke spawn (mostly, speed and direction). Default value: 1.\n- `growK` (`number`): How fast smoke expands. Default value: 1.\n- `targetYVelocity` (`number`): Neutral vertical velocity. Set above zero for hot gasses and below zero for cold, to collect at the bottom. Default value: 0."
---@return ac.Particles.Smoke
function ac.Particles.Smoke(params) end

---Smoke emitter holding specialized settings. Set settings in a table when creating an emitter and/or change them later.
---Use `:emit(position, velocity, amount)` to actually emit smoke.
---@class ac.Particles.Smoke
---@field color rgbm @Smoke color with values from 0 to 1. Alpha can be used to adjust thickness. Default alpha value: 0.5.
---@field colorConsistency number @Defines how much color dissipates when smoke expands, from 0 to 1. Default value: 0.5.
---@field thickness number @How thick is smoke, from 0 to 1. Default value: 1.
---@field life number @Smoke base lifespan in seconds. Default value: 4.
---@field size number @Starting particle size in meters. Default value: 0.2.
---@field spreadK number @How randomized is smoke spawn (mostly, speed and direction). Default value: 1.
---@field growK number @How fast smoke expands. Default value: 1.
---@field targetYVelocity number @Neutral vertical velocity. Set above zero for hot gasses and below zero for cold, to collect at the bottom. Default value: 0.
---@field flags integer @Emitter flags. Default value: 0.
local _ac_Particles_Smoke = nil

---Emits smoke from given position with certain velocity.
function _ac_Particles_Smoke:emit(position, velocity, amount) end

---Particles detractor pushing smoke (and othe particles later) away. Move it somewhere, set radius
---and velocity and it would affect the smoke.
---
---Note: use carefully, smoke particles can only account for eight detractors at once, and some of them can be set
---by track config. Also, moving cars or exhaust flames push smoke away using the same system.
---@param params {position: vec3, velocity: vec3, radius: number, forceMultiplier: number}|`{ radius = 10, forceMultiplier = 1 }` "Table with properties:\n- `position` (`vec3`): Detractor position.\n- `velocity` (`vec3`): Detractor velocity (main value that is used to push particles; stationary detractors don’t have much effect).\n- `radius` (`number`): Radius of the effect.\n- `forceMultiplier` (`number`): Force multiplier of the effect."
---@return ac.Particles.Detractor
function ac.Particles.Detractor(params) end

---Particles detractor pushing smoke (and othe particles later) away. Move it somewhere, set radius
---and velocity and it would affect the smoke.
---
---Note: use carefully, smoke particles can only account for eight detractors at once, and some of them can be set
---by track config. Also, moving cars or exhaust flames push smoke away using the same system.
---@class ac.Particles.Detractor
---@field position vec3 @Detractor position.
---@field velocity vec3 @Detractor velocity (main value that is used to push particles; stationary detractors don’t have much effect).
---@field radius number @Radius of the effect. Default value: 10.
---@field forceMultiplier number @Force multiplier of the effect. Default value: 1.
local _ac_Particles_Detractor = nil

--[[ common/ac_physics.lua ]]

---State of car controls.
---@class physics.CarControls
---@field gas number @Gas from 0 to 1 (pedal is fully pressed with 1).
---@field brake number @Braking from 0 to 1 (pedal is fully pressed with 1).
---@field steer number @Steering angle from -1 to 1.
---@field clutch number @1 for fully depressed clutch pedal (clutch fully engaged), 0 for pedal fully pressed (and clutch disengaged).
---@field gearUp boolean
---@field gearDown boolean
---@field drs boolean
---@field kers boolean
---@field brakeBalanceUp boolean
---@field brakeBalanceDown boolean
---@field requestedGearIndex integer
---@field isShifterSupported boolean
---@field handbrake number
---@field absUp boolean
---@field absDown boolean
---@field tcUp boolean
---@field tcDown boolean
---@field turboUp boolean
---@field turboDown boolean
---@field engineBrakeUp boolean
---@field engineBrakeDown boolean
---@field mgukDeliveryUp boolean
---@field mgukDeliveryDown boolean
---@field mgukRecoveryUp boolean
---@field mgukRecoveryDown boolean
---@field mguhMode integer
local _carControls = {}

--[[ common/ac_physics.lua ]]

---Represents a physics rigid body. Requires double precision physics engine to work.
---@class physics.RigidBody
local _physics_RigidBody = nil

---Removes rigid body from the world.
function _physics_RigidBody:dispose() end

---Sets collision callback for semidynamic rigid bodies.
---@param callback fun()
---@return physics.RigidBody @Returns self for easy chaining.
function _physics_RigidBody:onCollision(callback) end

---@param transform mat4x4
---@param estimateVelocity boolean? @Default value: `false`.
---@return physics.RigidBody @Returns self for easy chaining.
function _physics_RigidBody:setTransformation(transform, estimateVelocity) end

---@param sceneReference ac.SceneReference
---@param localTransform mat4x4?
---@param estimateVelocity boolean? @Default value: `false`.
---@return physics.RigidBody @Returns self for easy chaining.
function _physics_RigidBody:setTransformationFrom(sceneReference, localTransform, estimateVelocity) end

---@param velocity vec3
---@return physics.RigidBody @Returns self for easy chaining.
function _physics_RigidBody:setVelocity(velocity) end

---@param velocity vec3
---@return physics.RigidBody @Returns self for easy chaining.
function _physics_RigidBody:setAngularVelocity(velocity) end

---@param linear number
---@param angular number
---@param applyToAll boolean|`true`|`false` @Set to `true` to get the function to work properly (added for backwards compatibility).
---@return physics.RigidBody @Returns self for easy chaining.
function _physics_RigidBody:setDamping(linear, angular, applyToAll) end

---@param mass number
---@return physics.RigidBody @Returns self for easy chaining.
function _physics_RigidBody:setMass(mass) end

---@param value boolean|`true`|`false`
---@param switchBackOnContact boolean|`true`|`false`
---@return physics.RigidBody @Returns self for easy chaining.
function _physics_RigidBody:setSemiDynamic(value, switchBackOnContact) end

---@return boolean
function _physics_RigidBody:isSemiDynamic() end

---Stops rigidbody, collider is still working.
---@param value boolean|`true`|`false`
---@return physics.RigidBody @Returns self for easy chaining.
function _physics_RigidBody:setEnabled(value) end

---@return boolean
function _physics_RigidBody:isEnabled() end

---Stops rigidbody and removes collider from the world.
---@param value boolean|`true`|`false`
---@return physics.RigidBody @Returns self for easy chaining.
function _physics_RigidBody:setInWorld(value) end

---@return boolean
function _physics_RigidBody:isInWorld() end

---@return number
function _physics_RigidBody:getSpeedKmh() end

---@return number
function _physics_RigidBody:getAngularSpeed() end

---@return vec3
function _physics_RigidBody:getVelocity() end

---@return vec3
function _physics_RigidBody:getAngularVelocity() end

---@return integer @Wraps to 0 after 255.
function _physics_RigidBody:getLastHitIndex() end

---@return vec3
function _physics_RigidBody:getLastHitPos() end

---@param force vec3
---@param forceLocal boolean|`true`|`false`
---@param pos vec3
---@param posLocal boolean|`true`|`false`
function _physics_RigidBody:addForce(force, forceLocal, pos, posLocal) end

---@param pos vec3
---@return vec3
function _physics_RigidBody:localPosToWorld(pos) end

---@param dir vec3
---@return vec3
function _physics_RigidBody:localDirToWorld(dir) end

---@param pos vec3
---@return vec3
function _physics_RigidBody:worldPosToLocal(pos) end

---@param dir vec3
---@return vec3
function _physics_RigidBody:worldDirToLocal(dir) end

---@param point vec3
---@param pointLocal boolean|`true`|`false`
---@param velocityLocal boolean|`true`|`false`
---@return vec3
function _physics_RigidBody:pointVelocity(point, pointLocal, velocityLocal) end

---@return mat4x4
function _physics_RigidBody:getTransformation() end

---@alias physics.ColliderType {type: string}

---Represents a physics rigid body. Requires double precision physics engine to work.
---@param collider string|{filename: string, filter: string, debug: boolean?, transform: boolean?}|physics.ColliderType[] @Collider KN5 filename (or a table with filename and mesh filter, available since CSP 0.2.5 (set `transform` to `true` to use transform from the KN5); only the first matching mesh will be used, with or without filter), or a table listing geometric colliders (see `physics.Collider`).
---@param mass number @Mass in kg, can be changed later.
---@param cog vec3? @Center of gravity in collider model, can’t be changed later.
---@param semiDynamic boolean? @Semi-dynamic from the start. Default value: `false`.
---@param startsInWorld boolean? @Add to world from the start. Default value: `true`.
---@return physics.RigidBody
function physics.RigidBody(collider, mass, cog, semiDynamic, startsInWorld) end

---Different collider types.
physics.Collider = {}

---Box collider.
---@param size vec3
---@param offset vec3? @Default value: `vec3(0, 0, 0)`.
---@param look vec3? @Default value: `vec3(0, 0, 1)`.
---@param up vec3? @Default value: `vec3(0, 1, 0)`.
---@param debug boolean? @Set to `true` to see an outline. Default value: `false`.
---@return physics.ColliderType
function physics.Collider.Box(size, offset, look, up, debug) end

---Sphere collider.
---@param radius number
---@param offset vec3? @Default value: `vec3(0, 0, 0)`.
---@param debug boolean? @Set to `true` to see an outline. Default value: `false`.
---@return physics.ColliderType
function physics.Collider.Sphere(radius, offset, debug) end

---Capsule collider (like cylinder, but instead of flat caps it has hemispheres and works a bit faster).
---@param length number
---@param radius number
---@param offset vec3? @Default value: `vec3(0, 0, 0)`.
---@param look vec3? @Default value: `vec3(0, 0, 1)`.
---@param debug boolean? @Set to `true` to see an outline. Default value: `false`.
---@return physics.ColliderType
function physics.Collider.Capsule(length, radius, offset, look, debug) end

---Cylinder collider (slower than capsule, consider using capsule where appropriate).
---@param length number
---@param radius number
---@param offset vec3? @Default value: `vec3(0, 0, 0)`.
---@param look vec3? @Default value: `vec3(0, 0, 1)`.
---@param debug boolean? @Set to `true` to see an outline. Default value: `false`.
---@return physics.ColliderType
function physics.Collider.Cylinder(length, radius, offset, look, debug) end

--[[ common/ac_gameplay.lua ]]

---Tries to grabs camera for script to control it. If successfull, returns instance of `ac.GrabbedCamera` which you can then use to
---move camera, rotate it and alter some of its properties like DOF, FOV or exposure. However, if any other scripts are
---controlling camera currently, returns `nil` and a detailed error message with the name of script currently holding camera (with
---the reason to do so if provided) as a second argument.
---@param reason string|nil @Optional comment for the reason for grabbing camera, to simplify possible conflicts resolution.
---@return ac.GrabbedCamera|nil
---@return nil|string
function ac.grabCamera(reason) end

---Camera holder, for scripts to move camera in their own custom way. Obtained by calling `ac.grabCamera()`. When script is done with
---its camera movement, call `:dispose()` to release camera back to Assetto Corsa. If any reference to an instance of active holder
---is lost and `ac.GrabbedCamera` gets garbage collected, camera is also released.
---
---To move camera, access `.transform` property and edit it directly, setting new camera position and orientation vectors. Note:
---although matrix gives you access to `.side` and `.up` vectors, you don’t have to set them explicitly: before applying, matrix
---gets normalized automatically to make sure camera would not end up with a broken matrix.
---
---If you want to transition camera smoothly, use `.ownShare` property. It defaults to 1, but if set to 0.5, for example,
---resulting camera position would be in the middle of camera position set by AC and camera position set by script. If below 1,
---AC would also update camera position based on its current mode, once `.ownShare` reaches 1, CSP would switch current camera mode
---to free camera (switching back to original camera mode once `.ownShare` gets smaller).
---@class ac.GrabbedCamera
---@field transform mat4x4 @Camera transformation which will be applied with the next frame.
---@field transformOriginal mat4x4 @Camera transformation from original AC camera behaviour. Use `.ownShare` to smoothly transition between two, or access it here directly.
---@field fov number @Vertical FOV to be applied next frame, in degrees. Note: it would not affect camera in VR mode.
---@field fovOriginal number @Original camera vertical FOV, in degrees.
---@field dofDistance number @DOF distance to be applied next frame, in meters. Has an effect if `.dofFactor` is above 0. Requires YEBIS to work.
---@field dofDistanceOriginal number @Original camera DOF distance, in degrees.
---@field dofFactor number @DOF factor to be applied next frame. To get DOF to work, set it to 1.
---@field dofFactorOriginal number @Original camera DOF factor.
---@field exposure number @Camera exposure to be applied next frame.
---@field exposureOriginal number @Original camera exposure.
---@field listenerVelocity vec3 @Use this value to change listener velocity used by FMOD.
---@field ownShare number @Value for mixing original and custom camera parameters. Default value: 1. If 0, camera is controlled by Assetto Corsa. If 1, parameters set in `ac.GrabbedCamera` are used. If 0.5, parameters are mixed evenly.
---@field cameraRestoreThreshold number @Camera switches to original mode (for rendering logic) once `ownShare` drops below this value.
local _ac_GrabbedCamera = nil

---Returns `true` if camera holder is currently holding camera and was not disposed.
---@return boolean
function _ac_GrabbedCamera:active() end

---Releases held camera and allows Assetto Corsa to control camera as usual.
function _ac_GrabbedCamera:dispose() end

---Normalizes camera matrix (makes sure all direction vectors are orthogonal and have proper length). No need to call it explicitly:
---camera matrix would undergo normalization before applying anyway. But it could be helpful if you need to access normalized `.side`,
---for example, right after altering `.look`.
function _ac_GrabbedCamera:normalize() end

---Align a certain car in a viewport in a way similar to CM Showroom Preview generation. Returns a vector with camera offset.
---@param carIndex integer
---@param xAlign boolean|`true`|`false`
---@param xOffset number
---@param xOffsetRelative boolean|`true`|`false`
---@param yAlign boolean|`true`|`false`
---@param yOffset number
---@param yOffsetRelative boolean|`true`|`false`
---@return vec3
function _ac_GrabbedCamera:alignCar(carIndex, xAlign, xOffset, xOffsetRelative, yAlign, yOffset, yOffsetRelative) end

---Sets a callback which will be called when drawing driver tooltip card. Within, `ui.` functions can be used to add additional information.
---@param overrideOriginal boolean? @Set to `true` to hide original UI. Use carefully, might create some compatibility issues. Default value: `false`.
---@param callback fun(carIndex: integer) @Callback which will be called each time tooltip is drawn, getting 0-based car index.
---@return ac.Disposable
function ui.onDriverTooltip(overrideOriginal, callback) end

---Sets a callback which will be called when drawing tooltip. If new driver tags are disabled, using this function
---forcefully activates them (since 0.2.4).
---@param overrideOriginal boolean? @Set to `true` to hide original elements. If you want to add something to original layout, please keep it mind it might be changed in the future, and used font can vary as well, so don’t rely on it too much. Default value: `false`.
---@param bgColor rgbm? @Optional background color tint.
---@param callback fun(car: ac.StateCar) @Callback which will be called each time tooltip is drawn, getting 0-based car index.
---@param tweaks {mainSize: number?, mirrorSize: number?, distanceMultiplier: number?, tagSize: vec2?}? @Optional setting tweaks overriding user settings (use only if necessary). Tag size is in pixels, by default it’s 512×64.
---@return ac.Disposable
function ui.onDriverNameTag(overrideOriginal, bgColor, callback, tweaks) end

--[[ common/ac_gameplay_apps.lua ]]

---Collect information about available windows.
---@return {name: string, title: string, position: vec2, size: vec2, visible: boolean, pinned: boolean, collapsed: boolean, layer: integer, layerDuplicate: boolean}[]
function ac.getAppWindows() end

---Looks for a certain window of either an original AC app, a Python or a Lua app. Use `ac.getAppWindows()` to get a list of available apps.
---If found, this wrapper can be used to move or hide an app, or switch it to a different render layer.
---@param windowName string
---@return ac.AppWindowAccessor?
function ac.accessAppWindow(windowName) end

---Wrapper for interacting with any AC app. Might not work as intended with some apps not expecting such intrusion though.
---@class ac.AppWindowAccessor
local _ac_AppWindowAccessor = nil

---Window reference is valid (some references might become invalid if the window is deleted).
---@return boolean
function _ac_AppWindowAccessor:valid() end

---Checks if window is visible.
---@return boolean
function _ac_AppWindowAccessor:visible() end

---Changes visible state of the window.
---@param value boolean? @Default value: `true`.
---@return ac.AppWindowAccessor
function _ac_AppWindowAccessor:setVisible(value) end

---Checks if window is pinned.
---@return boolean
function _ac_AppWindowAccessor:pinned() end

---Changes pinned state of the window. Works with IMGUI apps with CSP v0.2.3-preview62 or newer.
---@param value boolean? @Default value: `true`.
---@return ac.AppWindowAccessor
function _ac_AppWindowAccessor:setPinned(value) end

---Returns window position.
---@return vec2
function _ac_AppWindowAccessor:position() end

---Returns window size (Python apps might draw things to extends exceeding this size).
---@return vec2
function _ac_AppWindowAccessor:size() end

---Moves window to a different position. Works with IMGUI apps with CSP v0.2.3-preview62 or newer.
---@param value vec2
---@return ac.AppWindowAccessor
function _ac_AppWindowAccessor:move(value) end

---Resizes a window. Works with IMGUI apps only.
---@param value vec2
---@return ac.AppWindowAccessor
function _ac_AppWindowAccessor:resize(value) end

---Returns redirect layer, or 0 if redirect is disabled. Redirected apps can be accessed via `dynamic::hud::redirected::N` textures.
---@return integer @0 if redirect is disabled.
function _ac_AppWindowAccessor:redirectLayer() end

---Moves window to a different render layer, or back to existance with `0` passed as `layer`. Windows in separate layers don’t get mouse
---commands (but this wrapper can be used to send fake commands instead).
---@param layer integer? @Default value: `0`.
---@param duplicate boolean? @Set to `true` to clone a window to a different layer instead of moving it there. Be careful: this might break some Python apps. Default value: `false`.
---@return ac.AppWindowAccessor
function _ac_AppWindowAccessor:setRedirectLayer(layer, duplicate) end

---Sends a fake mouse event to a window. Does not work with IMGUI apps or from online scripts.
---@param position vec2
---@return ac.AppWindowAccessor
function _ac_AppWindowAccessor:onMouseMove(position) end

---Sends a fake mouse event to a window. Does not work with IMGUI apps or from online scripts.
---@param position vec2
---@param button ui.MouseButton? @Default value: `ui.MouseButton.Left`.
---@return ac.AppWindowAccessor
function _ac_AppWindowAccessor:onMouseDown(position, button) end

---Sends a fake mouse event to a window. Does not work with IMGUI apps or from online scripts.
---@param position vec2
---@param button ui.MouseButton? @Default value: `ui.MouseButton.Left`.
---@return ac.AppWindowAccessor
function _ac_AppWindowAccessor:onMouseUp(position, button) end

--[[ common/ac_game.lua ]]

---Driver seat parameters.
---@param position vec3 "Driver eyes position. Starting value is taken from “GRAPHICS/DRIVEREYES” from “car.ini”."
---@param pitch number "Pitch angle in degrees. Starting value is taken from “GRAPHICS/ON_BOARD_PITCH_ANGLE” from “car.ini”."
---@param yaw number "Yaw angle in degrees. Starting value is 0."
---@return ac.SeatParams
function ac.SeatParams(position, pitch, yaw) end

---Driver seat parameters.
---@class ac.SeatParams
---@field position vec3 @Driver eyes position. Starting value is taken from “GRAPHICS/DRIVEREYES” from “car.ini”.
---@field pitch number @Pitch angle in degrees. Starting value is taken from “GRAPHICS/ON_BOARD_PITCH_ANGLE” from “car.ini”.
---@field yaw number @Yaw angle in degrees. Starting value is 0.
local _ac_SeatParams = nil

---Driver seat parameters.
---@return ac.SceneTweaks
function ac.SceneTweaks() end

---Driver seat parameters.
---@class ac.SceneTweaks
---@field forceHeadlights ac.SceneTweakFlag
---@field forceBrakeLights ac.SceneTweakFlag
---@field forceHighBeams ac.SceneTweakFlag
---@field timeOffset number
---@field headingAngleOffset number
---@field forceFlames boolean
---@field stationaryRainDrops boolean
---@field disableDamage boolean
---@field disableDirt boolean
local _ac_SceneTweaks = nil

---Returns VRAM stats if available (older versions of Windows won’t provide access to this API). All sizes are in megabytes. Note: values
---provided are for a GPU in general, not for the Assetto Corsa itself.
---@return nil|{budget: number, usage: number, availableForReservation: number, reserved: number}
function ac.getVRAMConsumption() end

---Driver seat parameters.
---@class ac.DriverWeightShift
---@field range number @Maximum range in meters. Read only.
---@field applied number @Applied shift in meters. Read only.
---@field input number @Requested shift in meters. Can be altered.
local _ac_DriverWeightShift = nil

---Access driver weight shift.
---@param carIndex integer @0-based car index.
---@return ac.DriverWeightShift?
function ac.DriverWeightShift(carIndex) end

---A helper structure to simulate some inputs for controlling the car.
---@class ac.CarControlsInput
---@field gearUp boolean @Set to `true` to activate a flag for the next physics step.
---@field gearDown boolean @Set to `true` to activate a flag for the next physics step.
---@field brakeBalanceUp boolean @Set to `true` to activate a flag for the next physics step.
---@field brakeBalanceDown boolean @Set to `true` to activate a flag for the next physics step.
---@field absUp boolean @Set to `true` to activate a flag for the next physics step.
---@field absDown boolean @Set to `true` to activate a flag for the next physics step.
---@field tractionControlUp boolean @Set to `true` to activate a flag for the next physics step.
---@field tractionControlDown boolean @Set to `true` to activate a flag for the next physics step.
---@field turboUp boolean @Set to `true` to activate a flag for the next physics step.
---@field turboDown boolean @Set to `true` to activate a flag for the next physics step.
---@field engineBrakeUp boolean @Set to `true` to activate a flag for the next physics step.
---@field engineBrakeDown boolean @Set to `true` to activate a flag for the next physics step.
---@field mgukDeliveryUp boolean @Set to `true` to activate a flag for the next physics step.
---@field mgukDeliveryDown boolean @Set to `true` to activate a flag for the next physics step.
---@field mgukRecoveryUp boolean @Set to `true` to activate a flag for the next physics step.
---@field mgukRecoveryDown boolean @Set to `true` to activate a flag for the next physics step.
---@field drs boolean @Set to `true` to switch the DRS state in the next physics step.
---@field kers ac.CarControlsInput.Flag @Set to `ac.CarControlsInput.Flag.Skip` to leave the user-selected value be.
---@field mguhMode integer @Set to `-1` to keep existing value, or to a 0-based index of the required MGUH mode.
---@field requestedGearIndex integer @Set to `0` to keep existing gear, to `-1` to engage reverse, or to a positive value to engage a regular gear.
---@field steer number @Value from -1 to 1. Set to `math.huge` to instead leave the original steering value.
---@field gas number @Value from 0 to 1. Final value will be the maximum of original and this.
---@field brake number @Value from 0 to 1. Final value will be the maximum of original and this.
---@field handbrake number @Value from 0 to 1. Final value will be the maximum of original and this.
---@field clutch number @Value from 0 to 1. Final value will be the minimum of original and this (1 is for clutch pedal fully depressed, 0 for pressed).
---@field headlights boolean @Set to `true` to toggle headlights in the next frame (after that, field will be reset).
---@field headlightsFlash boolean @Set to `true` to flash headlights in the next frame (after that, field will be reset).
---@field changeCamera boolean @Set to `true` to change camera in the next frame (after that, field will be reset).
---@field horn boolean @Set to `true` to honk. Reset to `false` when done. Note: with sirens instead of horn, behaviour might be different.
---@field lookLeft boolean @Set to `true` to look left. Reset to `false` when done.
---@field lookRight boolean @Set to `true` to look right. Reset to `false` when done.
---@field lookBack boolean @Set to `true` to look back. Reset to `false` when done.
local _ac_CarControlsInput = nil

---Checks if controls override is active (as in, has been read by AC physics in the last couple of frames).
---@return boolean
function _ac_CarControlsInput:active() end

---A helper structure to simulate some inputs for controlling the car.
---@class ac.OverlayLeaderboardParams
---@field displayMode integer
---@field verticalLayout boolean
local _ac_OverlayLeaderboardParams = nil

--[[ common/ac_track_conditions.lua ]]

---Creates a wrapper to access track condition. If you want to get the value often, consider caching and reusing the wrapper.
---@param expression string @Expression similar to ones config have as CONDITION=… value.
---@param offset number? @Condition offset. Default value: 0.
---@param defaultValue number? @Default value in case referenced condition is missing or parsing failed. Default value: 0.
---@return ac.TrackCondition
function ac.TrackCondition(expression, offset, defaultValue) end

---Returns number of conditions defined on the current track.
---@return integer
function ac.TrackCondition.count() end

---Returns name of a condition with certain index.
---@param index integer @0-based condition index.
---@return string? @Returns `nil` if there is no such condition.
function ac.TrackCondition.name(index) end

---Returns input of a condition with certain index.
---@param index integer @0-based condition index.
---@return string? @Returns `nil` if there is no such condition.
function ac.TrackCondition.input(index) end

---Returns value of a condition with certain index.
---@param index integer @0-based condition index.
---@param offset number? @Optional offset for conditions with variance.
---@return number @Returns `0` if there is no such condition.
function ac.TrackCondition.get(index, offset) end

---Returns RGB value of a condition with certain index.
---@param index integer @0-based condition index.
---@param offset number? @Optional offset for conditions with variance.
---@return rgb @Returns `rgb()` if there is no such condition.
function ac.TrackCondition.getColor(index, offset) end

--[[ common/ac_track_conditions.lua ]]

---Track condition evaluator. Given expression, which might refer to some existing condition, condition input or a complex expression of those,
---computes the resulting value.
---@class ac.TrackCondition
local _ac_TrackCondition = nil

---@param offset number? @Optional offset (in case track condition has a variance).
---@return number
function _ac_TrackCondition:get(offset) end

---@param offset number? @Optional offset (in case track condition has a variance).
---@return rgb
function _ac_TrackCondition:getColor(offset) end

---Returns `true` if there is a condition with value changing live.
---@return boolean
function _ac_TrackCondition:isDynamic() end

---Returns condition input, if any.
---@return string?
function _ac_TrackCondition:input() end

---Returns condition name, if any.
---@return string?
function _ac_TrackCondition:name() end

--[[ common/ac_car_control.lua ]]

---Stores Real Mirror parameters for a real view mirror.
---@return ac.RealMirrorParams
function ac.RealMirrorParams() end

---Stores Real Mirror parameters for a real view mirror.
---@class ac.RealMirrorParams
---@field rotation vec2 @Mirror tilt, X for horizontal and Y for vertical.
---@field fov number @Field of view angle in degrees, automatically guessed value: 10.
---@field aspectMultiplier number @Aspect ratio multiplier.
---@field flip ac.MirrorPieceFlip @Optional texture mapping flip parameter.
---@field isMonitor boolean @Monitor mirrors don’t reflect car they’re in.
---@field useMonitorShader boolean @Monitor shader has brightness that works slightly differently, a bit of color distortion at steep view angles (depends on monitor type) and a pixel grid if viewed really close.
---@field notDrivenByUser boolean @By default, set to `false`. Once `ac.setRealMirrorParams()` with `userDriven` set to `false` is called, switches to `true`. In that case, mirror is controlled by something like a car script, not by a user. Can’t be changed directly.
---@field role ac.MirrorPieceRole @Role of mirror piece. Used by adaptive virtual mirrors.
---@field monitorShaderScale vec2 @Scale of pixels grid for monitor shader. Automatically guessed value: `vec2(600, 150)`. Think of it as display resolution.
---@field monitorShaderSkew number @Skew of pixels grid to align pixels with tilted monitors.
---@field monitorShaderType ac.MirrorMonitorType @Type of monitor shader. By default guessed based on manufacturing year.
---@field monitorBrightness number @Monitor brightness, 1 for regular brightness.
local _ac_RealMirrorParams = nil

---@return ac.RealMirrorParams
function _ac_RealMirrorParams:clone() end

---Returns set of mirror settings for a given Real Mirror mirror (for car scripts, associated car, for apps and tools — player’s car).
---@param mirrorIndex integer @0-based mirror index (leftmost mirror is 0, the first one to right of it is 1 and so on)
---@return ac.RealMirrorParams
function ac.getRealMirrorParams(mirrorIndex) end

---Tweak car audio events live: alter volume, pitch, fading distance, position, transform parameters (same as with `[AUDIO_…]` sections
---in car config file). Additionally, it allows to control extra FMOD event parameters in case you need to add further fidelity. Most functions,
---apart from `ac.CarAudioTweak.parameterTransform()`, are quick enough that you can call them every frame with no issues.
---
---Note: if you’re making something other than a car script, please be careful with these functions, as it might override values configured
---by original car config or a car script. If conflicts will become an issue later on some workaround will be added (possibly a system
---allowing car configs or scripts to block other scripts interfering with its audio configuration).
ac.CarAudioTweak = {}

---Set volume multiplier. Overrides `[AUDIO_VOLUME]` value from car config.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@param value number @New value from 0 to 1 (100%), can go above 1 as well.
function ac.CarAudioTweak.setVolume(eventID, value) end

---Get current volume multiplier set by `[AUDIO_VOLUME]` or a Lua script.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@return number @Returns `math.NaN` if there is no such event.
function ac.CarAudioTweak.getVolume(eventID) end

---Set pitch multiplier. Overrides `[AUDIO_PITCH]` value from car config.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@param value number @New value from 0 to 1 (100%), can go above 1 as well.
function ac.CarAudioTweak.setPitch(eventID, value) end

---Get current pitch multiplier set by `[AUDIO_PITCH]` or a Lua script.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@return number @Returns `math.NaN` if there is no such event.
function ac.CarAudioTweak.getPitch(eventID) end

---Set attenuation start distance (at this distance volume will start decreasing). Overrides `[AUDIO_3D_DISTANCE] …_MIN`
---value from car config.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@param value number @New value in meters, or `-1` to reset to default FMOD value.
function ac.CarAudioTweak.setDistanceMin(eventID, value) end

---Get current attenuation start distance set by audio event properties, `[AUDIO_3D_DISTANCE]` or a Lua script.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@return number @Returns `math.NaN` if there is no such event, or `-1` if value is the default one from FMOD.
function ac.CarAudioTweak.getDistanceMin(eventID) end

---Set attenuation end distance (at this distance volume will stops decreasing, but sound might still be heard, 
---depending on FMOD audio event configuration). Overrides `[AUDIO_3D_DISTANCE] …_MAX` value from car config.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@param value number @New value in meters, or `-1` to reset to default FMOD value.
function ac.CarAudioTweak.setDistanceMax(eventID, value) end

---Get current attenuation end distance set by audio event properties, `[AUDIO_3D_DISTANCE]` or a Lua script.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@return number @Returns `math.NaN` if there is no such event, or `-1` if value is the default one from FMOD.
function ac.CarAudioTweak.getDistanceMax(eventID) end

---Set audio transformation (position and rotation) relative to car. Overrides `[AUDIO_TRANSFORM]` value from car config.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@param value mat4x4 @Transformation matrix (make sure it’s normalized).
function ac.CarAudioTweak.setTransform(eventID, value) end

---Set LUT used for converting parameter values computed by AC into something else. Overrides `[AUDIO_PARAMETER_TRANSFORM]` value from car config.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@param key string @Name of the parameter
---@param value ac.Lut @LUT mapping original input values into custom output values.
function ac.CarAudioTweak.setParameterTransform(eventID, key, value) end

---Set value of an FMOD audio event parameter. Feel free to call it every frame if you want to update it live.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@param key string @Name of the parameter
---@param value number @New value in a range expected by FMOD audio event.
---@param override boolean? @Set to `true` to override a value AC might set, can be useful to tweak something like `rpms` of engine audio.
function ac.CarAudioTweak.setParameter(eventID, key, value, override) end

---Set value of a custom DSP for the audio event. If DSP is missing, create and add it at the front.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@param dsp string @DSP name.
---@param key integer|'enable'|'disable'|'remove'|'wetDry' @Index of DSP parameter, or an action. If `wetDry` is specified, value should be a table with values `prewet`, `postwet` and `dry`.
---@param value number|table|nil @Value.
function ac.CarAudioTweak.setDSP(eventID, dsp, key, value) end

---Get value of an FMOD audio event parameter.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@param key string @Name of the parameter
---@return number @Returns `math.NaN` if there is no such event or parameter.
function ac.CarAudioTweak.getParameter(eventID, key) end

---Replaces entire audio event with a different one.
---@param eventID ac.CarAudioEventID @ID of a target event.
---@param newEventKey string @Key for the new audio event, like `'/cars/accr_mclaren_f1/engine_ext'`.
function ac.CarAudioTweak.replaceAudioEvent(eventID, newEventKey) end

---@param cameraIndex integer @0-based camera index (use `car.carCamerasCount` to get the number of cameras).
---@return ac.CarCameraParams? @Returns `nil` if there is no camera with such index.
function ac.accessCarCamera(cameraIndex) end

--[[ common/ac_car_control_physics.lua ]]

---A helper structure to simulate some inputs for controlling the car.
---@class ac.CarExtraSwitchParams
---@field unavailable boolean @Set to `true` to make a switch inaccessible by user with hotkeys. Car controlling scripts would still be able to alter its state.
---@field holdMode boolean @Set to `true` to get switch to work only if a button is currently held down.
---@field stationaryOnly boolean @Set to `true` to only allow user to change the flag if car is stationary.
---@field neutralGearOnly boolean @Set to `true` to only allow user to change the flag if car is in neutral gear.
---@field requiresBrake boolean @Set to `true` to only allow user to change the flag if brake pedal is fully pressed.
local _ac_CarExtraSwitchParams = nil

---@param index integer @0-based switch index.
---@return ac.CarExtraSwitchParams? @Returns `nil` if there is no switch with such index.
function ac.accessExtraSwitchParams(index) end

--[[ common/ac_extras_binaryinput.lua ]]

---@param id string @Name of a section in “controls.ini”. If you are adding a new input, use something like “your.namespace/Nice Name” (without square brackets or colons) to ensure there won’t be collisions and it would integrate nicely.
---@param defaults {keyboard: nil|{key: ui.KeyIndex?, ctrl: boolean?, shift: boolean?, alt: boolean?}, gamepad: nil|ac.GamepadButton, period: nil|number, hold: nil|boolean}? @Default settings if user has not configured input yet. Parameter `period` can be used to create buttons which would keep reporting as pressed (or call `:onDown()`) while held, can be configured in “controls.ini” as “REPEAT_PERIOD”; by default repeating is disable. Set parameter `hold` to a boolean value and control widget will get a “hold” switch. Buttons configured in “hold” mode return `true` on `:pressed()` when both pressed and released, as well as trigger `:onPressed()` when released too. Note: if `ac.ControlButton()` is called multiple times within a race session, only defaults from the first run will be taken into account (but if subsequent calls will have a “hold” value, button editing widget will still get a “hold” switch).
---@return ac.ControlButton
function ac.ControlButton(id, defaults) end

--[[ common/ac_extras_binaryinput.lua ]]

---A good way to listen to user pressing buttons configured in AC control settings. Handles everything for you automatically, and if you’re working
---on a Lua app has a `:control()` method drawing a button showing current binding and allowing to change it in-game.
---
---Could be used for original AC button bindings, new bindings added by CSP, or even for creating custom bindings. For that, make sure to pass a
---reliably unique ID when creating a control button, maybe even prefixed by your app name.
---
---Note: inputs for car scripts (both display and physics ones) would work only if the car is currently controlled by the user and not in a replay.
---When possible, consider binding to car state instead. If your script runs at lower rate than graphics thread (skipping frames), either use `:down()`
---or, better yet, sign to events, `:pressed()` call might return `false`.
---@class ac.ControlButton
local _ac_ControlButton = nil

---Button is configured.
---@return boolean
function _ac_ControlButton:configured() end

---Button is disabled.
---@return boolean
function _ac_ControlButton:disabled() end

---Button is using hold mode.
---@return boolean
function _ac_ControlButton:holdMode() end

---Button was just pressed. For buttons in hold mode returns `true` on both press and release.
---@return boolean
function _ac_ControlButton:pressed() end

---Button was just released. For buttons in hold mode returns `true` on both press and release.
---@return boolean
function _ac_ControlButton:released() end

---Button is held down. For buttons in hold mode works similar to `:pressed()`.
---@return boolean
function _ac_ControlButton:down() end

---Sets a callback to be called when the button is pressed. For buttons in hold mode calls callback on both presses and releases. If button is held down
---when this method is called, callback will be called the next frame.
---@param callback fun()
---@return ac.Disposable
function _ac_ControlButton:onPressed(callback) end

---Sets a callback to be called when the button is released. For buttons in hold mode calls callback shortly after both presses and releases.
---@param callback fun()
---@return ac.Disposable
function _ac_ControlButton:onReleased(callback) end

---Always active buttons work even if AC is paused or in, for example, pits menu.
---@param value boolean? @Default value: `true`.
---@return ac.ControlButton
function _ac_ControlButton:setAlwaysActive(value) end

---Disabled buttons ignore presses but remember their settings.
---@param value boolean? @Default value: `true`.
---@return ac.ControlButton
function _ac_ControlButton:setDisabled(value) end

---Use within UI function to draw an editing button. Not available for scripts without UI access.
---To change color of pressed button indicator, override `PlotLinesHovered` color.
---@param size vec2? @If not set, or width is 0, uses next item width and regular button height.
---@param flags ui.ControlButtonControlFlags? @Default value: `ac.ControlButtonControlFlags.None`.
---@param emptyLabel string? @Default value: `'Click to assign'`.
---@return boolean
function _ac_ControlButton:control(size, flags, emptyLabel) end

---Returns text for displaying current binding, or `nil` if the button isn’t bound to anything.
---@return string?
function _ac_ControlButton:boundTo() end

--[[ common/ac_extras_yebiscolorcorrection.lua ]]

---Helper entity to set color corrections. Holds up to 200 corrections at once. Call `:reset()` if you want to start over, or just use `ac.setColorCorrection()` the way it’s meant to be used.
---@class ac.ColorCorrection
local _ac_ColorCorrection = nil

---Reset alterations.
---@return self
function _ac_ColorCorrection:reset() end

---Completely desaturate the image.
---@return self
function _ac_ColorCorrection:grayscale() end

---Invert image colors.
---@return self
function _ac_ColorCorrection:negative() end

---Change image saturation.
---@param v number|rgb|rgbm? @Fourth component of rgbm acts as an intensity adjustment. Default value: 1.
---@return self
function _ac_ColorCorrection:saturation(v) end

---Change image brightness (multiplies color by the parameter).
---@param v number|rgb|rgbm? @Fourth component of rgbm acts as an intensity adjustment. Default value: 1.
---@return self
function _ac_ColorCorrection:brightness(v) end

---Change image contrast.
---@param v number|rgb|rgbm? @Fourth component of rgbm acts as an intensity adjustment. Default value: 1.
---@return self
function _ac_ColorCorrection:contrast(v) end

---Change image bias (adds the parameter to color).
---@param v number|rgb|rgbm? @Fourth component of rgbm acts as an intensity adjustment. Default value: 0.
---@return self
function _ac_ColorCorrection:bias(v) end

---Add a fadeout transformation.
---@param v number|rgb|rgbm? @Fourth component of rgbm acts as an intensity adjustment. Default value: 0.
---@return self
function _ac_ColorCorrection:fade(v, effectRatio) end

---Turn image monotone.
---@param v number|rgb|rgbm? @Fourth component of rgbm acts as an intensity adjustment. Default value: 0.
---@param saturation number? @Saturation factor. Default value: 0.
---@param brightness number? @Brightness factor. Default value: 1.
---@return self
function _ac_ColorCorrection:monotone(v, saturation, brightness) end

---Alter hue, saturation and brightness.
---@param hueDegrees number? @Degrees for hue shift. Default value: 0.
---@param saturation number? @Saturation adjustment. Default value: 1.
---@param brightness number? @Brightness adjustment. Default value: 1.
---@param keepLuminance boolean? @Keep image luminance. Default value: `false`.
---@return self
function _ac_ColorCorrection:HSB(hueDegrees, saturation, brightness, keepLuminance) end

---Alter image white balance.
---@param temperatureK number? @Temperature in K. Default value: 6500.
---@param luminance number? @Luminance. Default value: 1.
---@return self
function _ac_ColorCorrection:whiteBalance(temperatureK, luminance) end

---Alter image temperature.
---@param temperatureK number? @Temperature in K. Default value: 6500.
---@param luminance number? @Luminance. Default value: 1.
---@return self
function _ac_ColorCorrection:temperature(temperatureK, luminance) end

---Shift tone to sepia.
---@param v number? @Sepia amount. Default value: 1.
---@return self
function _ac_ColorCorrection:sepia(v) end

---Shift image hue.
---@param hueDegrees number? @Degrees for hue shift. Default value: 0.
---@param keepLuminance boolean? @Keep image luminance. Default value: `false`.
---@return self
function _ac_ColorCorrection:hue(hueDegrees, keepLuminance) end

---YEBIS uses color matrices to quickly adjust HDR (input 0…∞ range) and LDR (output 0…1 range) color. Tweaks such as saturation, brightness and
---contrast configured in YEBIS PP filter, or in video settings, all control those matrices.
---
---This function allows to easily tweak those matrices. Call it, optionally specifying target matrix and priority, and then use methods of returned
---entity to easily tweak the color. Chain methods together to achieve the desired effect:
---```
---ac.setColorCorrection():brightness(3):saturation(2)
---```
---
---Won’t have any effect if YEBIS is disabled, or if WeatherFX style script replaces YEBIS post-processing and doesn’t read
---HDR matrix correctly. For compatibility reasons, if WeatherFX style script doesn’t read LDR color matrix, it will be applied
---afterwards (in CSPs before 0.2.5, there wasn’t a method for WeatherFX style scripts to even access LDR color matrix, and
---Assetto Corsa didn’t alter it at all).
---
---Each time the function is called with the same target and priority parameters, its state will reset. Feel free to call this function every frame
---if you want for adjustments to transition smoothly, or just once if you just want to tweak the colors and forget about it.
---
---Note: you can keep a reference to returned value and tweak it instead, but then you’ll have to call `:reset()` manually. One tweak entity can
---hold up to 40 adjustments, mostly to make sure it’s used correctly. Actual adjustments are very cheap.
---
---Note: some scripts, such as online scripts, can access old API for color corrections, such as `ac.ColorCorrectionBrightness()`.
---Those things are obsolete now, please use this thing instead (with only exception being WeatherFX styles, those could still
---old API since it could be a tiny bit faster overall).
---@param targetLDR boolean? @Set to `true` to alter final LDR image instead of original HDR image. Note: original AC never tweaked LDR color matrix at all. Default value: `false`.
---@param priority integer? @Specifies order of execution. Higher numbers mean corrections will apply first. Can be an integer in -100…100 range. Default value: `0`.
---@return ac.ColorCorrection
function ac.setColorCorrection(targetLDR, priority) end
