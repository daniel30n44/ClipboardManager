#!/usr/bin/env python3
"""生成 Xcode project.pbxproj 文件 — 重写版"""

import uuid
import os

def hex24():
    return uuid.uuid4().hex[:24].upper()

# ============================================================
# 预生成 UUID
# ============================================================
PID      = hex24()  # Project
MGID     = hex24()  # Main Group
PGID     = hex24()  # Products Group
SGID     = hex24()  # Source root group (ClipboardManager)
MODG     = hex24()  # Models group
SVCG     = hex24()  # Services group
VWG      = hex24()  # Views group
MBG      = hex24()  # MenuBar group
MWG      = hex24()  # MainWindow group
SETG     = hex24()  # Settings group
UTG      = hex24()  # Utils group
ASG      = hex24()  # Assets group
TID      = hex24()  # Target
SPH      = hex24()  # Sources build phase
FPH      = hex24()  # Frameworks build phase
RPH      = hex24()  # Resources build phase
PDC      = hex24()  # Project Debug Config
PRC      = hex24()  # Project Release Config
TDC      = hex24()  # Target Debug Config
TRC      = hex24()  # Target Release Config
PCL      = hex24()  # Project Config List
TCL      = hex24()  # Target Config List
PREF     = hex24()  # Product Reference

# 源文件
src = {
    "HistoryClipboardApp.swift": hex24(),
    "Models/ClipboardItem.swift": hex24(),
    "Services/DataStore.swift": hex24(),
    "Services/ClipboardMonitor.swift": hex24(),
    "Services/PasteService.swift": hex24(),
    "Views/MenuBar/MenuBarView.swift": hex24(),
    "Views/MainWindow/MainWindowView.swift": hex24(),
    "Views/MainWindow/ClipboardCard.swift": hex24(),
    "Views/MainWindow/SearchBar.swift": hex24(),
    "Views/Settings/SettingsView.swift": hex24(),
    "Utils/Color+Hex.swift": hex24(),
    "Utils/DateFormatter+Extensions.swift": hex24(),
    "Utils/LocalizationService.swift": hex24(),
}

res = {
    "Assets.xcassets": hex24(),
    "Info.plist": hex24(),
    "ClipboardManager.entitlements": hex24(),
}

# Build file refs
src_bf = {p: hex24() for p in src}
res_bf = {p: hex24() for p in res}

# ============================================================
# 辅助函数
# ============================================================
def file_ref(uuid_, path, name=None, ftype=None, tree='"<group>"'):
    n = name or os.path.basename(path)
    ft = f'lastKnownFileType = {ftype}; ' if ftype else ''
    return f'\t\t{uuid_} /* {n} */ = {{isa = PBXFileReference; {ft}name = "{n}"; path = "{path}"; sourceTree = {tree}; }};'

def build_file(uuid_, file_ref_id, fname):
    return f'\t\t{uuid_} /* {fname} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {fname} */; }};'

def group(uuid_, name, children, path=None, tree='"<group>"'):
    c = ', '.join(children)
    p = f'path = "{path}"; ' if path else ''
    return f'\t\t{uuid_} /* {name} */ = {{isa = PBXGroup; children = ({c}); {p}sourceTree = {tree}; }};'

def build_phase(uuid_, ptype, files):
    fs = ', '.join(files)
    return f'\t\t{uuid_} /* {ptype} */ = {{isa = PBX{ptype}; buildActionMask = 2147483647; files = ({fs}); runOnlyForDeploymentPostprocessing = 0; }};'

def build_config(uuid_, name, settings, base_ref=None):
    slines = ';\n\t\t\t\t'.join(f'{k} = {v}' for k, v in settings.items())
    br = f'baseConfigurationReference = {base_ref}; ' if base_ref else ''
    return f'\t\t{uuid_} /* {name} */ = {{isa = XCBuildConfiguration; {br}buildSettings = {{\n\t\t\t\t{slines};\n\t\t\t}}; name = "{name}"; }};'

def config_list(uuid_, configs, default=None):
    c = ', '.join(configs)
    d = f'defaultConfigurationName = "{default}"; ' if default else ''
    return f'\t\t{uuid_} /* Build configuration list */ = {{isa = XCConfigurationList; {d}buildConfigurations = ({c}); }};'

def esc(v):
    """合理转义字符串值"""
    return v.replace('\\', '\\\\').replace('"', '\\"')

# ============================================================
# 构建
# ============================================================
lines = []

# -- PBXBuildFile --
lines.append("/* Begin PBXBuildFile section */")
for path, bf_id in src_bf.items():
    fname = os.path.basename(path)
    lines.append(build_file(bf_id, src[path], fname))
# 资源文件（除了 entitlements）
for path, bf_id in res_bf.items():
    if 'entitlements' in path:
        continue
    fname = os.path.basename(path)
    lines.append(f'\t\t{bf_id} /* {fname} in Resources */ = {{isa = PBXBuildFile; fileRef = {res[path]} /* {fname} */; }};')
lines.append("/* End PBXBuildFile section */")

# -- PBXFileReference --
lines.append("/* Begin PBXFileReference section */")
# 产品
lines.append(f'\t\t{PREF} /* ClipboardManager.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "ClipboardManager.app"; sourceTree = BUILT_PRODUCTS_DIR; }};')
# 源文件 — path 只需写文件名（因为已在有 path 的 group 内）
for key, fid in src.items():
    fname = os.path.basename(key)
    lines.append(file_ref(fid, fname, ftype="sourcecode.swift"))
# 资源
lines.append(f'\t\t{res["Assets.xcassets"]} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; }};')
lines.append(file_ref(res["Info.plist"], "Info.plist", ftype="text.plist.xml"))
lines.append(file_ref(res["ClipboardManager.entitlements"], "ClipboardManager.entitlements", ftype="text.plist.entitlements"))
lines.append("/* End PBXFileReference section */")

# -- PBXGroup --
lines.append("/* Begin PBXGroup section */")
lines.append(group(PGID, "Products", [PREF]))
lines.append(group(MODG, "Models", [src["Models/ClipboardItem.swift"]], path="Models"))
lines.append(group(SVCG, "Services", [
    src["Services/DataStore.swift"],
    src["Services/ClipboardMonitor.swift"],
    src["Services/PasteService.swift"],
], path="Services"))
lines.append(group(MBG, "MenuBar", [src["Views/MenuBar/MenuBarView.swift"]], path="MenuBar"))
lines.append(group(MWG, "MainWindow", [
    src["Views/MainWindow/MainWindowView.swift"],
    src["Views/MainWindow/ClipboardCard.swift"],
    src["Views/MainWindow/SearchBar.swift"],
], path="MainWindow"))
lines.append(group(SETG, "Settings", [src["Views/Settings/SettingsView.swift"]], path="Settings"))
lines.append(group(VWG, "Views", [MBG, MWG, SETG], path="Views"))
lines.append(group(UTG, "Utils", [
    src["Utils/Color+Hex.swift"],
    src["Utils/DateFormatter+Extensions.swift"],
    src["Utils/LocalizationService.swift"],
], path="Utils"))
lines.append(group(ASG, "Assets.xcassets", [res["Assets.xcassets"]]))
lines.append(group(SGID, "ClipboardManager", [
    src["HistoryClipboardApp.swift"],
    MODG, SVCG, VWG, UTG, ASG,
    res["Info.plist"],
    res["ClipboardManager.entitlements"],
], path="ClipboardManager"))
lines.append(group(MGID, "", [SGID, PGID]))
lines.append("/* End PBXGroup section */")

# -- PBXNativeTarget --
lines.append("/* Begin PBXNativeTarget section */")
lines.append(f'\t\t{TID} /* ClipboardManager */ = {{isa = PBXNativeTarget; buildConfigurationList = {TCL}; buildPhases = ({SPH}, {FPH}, {RPH}); buildRules = (); dependencies = (); name = "ClipboardManager"; productName = "ClipboardManager"; productReference = {PREF}; productType = "com.apple.product-type.application"; }};')
lines.append("/* End PBXNativeTarget section */")

# -- PBXProject --
lines.append("/* Begin PBXProject section */")
lines.append(f'\t\t{PID} /* Project object */ = {{isa = PBXProject; attributes = {{BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 2600; LastUpgradeCheck = 2600; TargetAttributes = {{{TID} = {{CreatedOnToolsVersion = 26.5; }}; }}; }}; buildConfigurationList = {PCL}; compatibilityVersion = "Xcode 14.0"; developmentRegion = "zh-Hans"; hasScannedForEncodings = 0; knownRegions = (zh-Hans, en, Base); mainGroup = {MGID}; productRefGroup = {PGID}; projectDirPath = ""; projectRoot = ""; targets = ({TID}); }};')
lines.append("/* End PBXProject section */")

# -- PBXSourcesBuildPhase --
lines.append("/* Begin PBXSourcesBuildPhase section */")
sfiles = [f'{src_bf[p]} /* {os.path.basename(p)} in Sources */' for p in src]
lines.append(build_phase(SPH, "SourcesBuildPhase", sfiles))
lines.append("/* End PBXSourcesBuildPhase section */")

# -- PBXFrameworksBuildPhase --
lines.append("/* Begin PBXFrameworksBuildPhase section */")
lines.append(build_phase(FPH, "FrameworksBuildPhase", []))
lines.append("/* End PBXFrameworksBuildPhase section */")

# -- PBXResourcesBuildPhase --
lines.append("/* Begin PBXResourcesBuildPhase section */")
lines.append(build_phase(RPH, "ResourcesBuildPhase", [
    f'{res_bf["Assets.xcassets"]} /* Assets.xcassets in Resources */'
]))
lines.append("/* End PBXResourcesBuildPhase section */")

# -- XCBuildConfiguration --
lines.append("/* Begin XCBuildConfiguration section */")

# 项目 Debug
lines.append(build_config(PDC, "Debug", {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_CXX_LANGUAGE_STANDARD": '"gnu++20"',
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": "dwarf",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "ENABLE_TESTABILITY": "YES",
    "GCC_DYNAMIC_NO_PIC": "NO",
    "GCC_OPTIMIZATION_LEVEL": "0",
    "GCC_PREPROCESSOR_DEFINITIONS": '("DEBUG=1", "$(inherited)")',
    "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
    "ONLY_ACTIVE_ARCH": "YES",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"DEBUG"',
    "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"',
}))

# 项目 Release
lines.append(build_config(PRC, "Release", {
    "ALWAYS_SEARCH_USER_PATHS": "NO",
    "CLANG_ANALYZER_NONNULL": "YES",
    "CLANG_CXX_LANGUAGE_STANDARD": '"gnu++20"',
    "CLANG_ENABLE_MODULES": "YES",
    "CLANG_ENABLE_OBJC_ARC": "YES",
    "COPY_PHASE_STRIP": "NO",
    "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"',
    "ENABLE_NS_ASSERTIONS": "NO",
    "ENABLE_STRICT_OBJC_MSGSEND": "YES",
    "GCC_OPTIMIZATION_LEVEL": "s",
    "MTL_ENABLE_DEBUG_INFO": "NO",
    "SWIFT_COMPILATION_MODE": "wholemodule",
    "SWIFT_OPTIMIZATION_LEVEL": '"-O"',
    "VALIDATE_PRODUCT": "YES",
}))

target_settings = {
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "CODE_SIGN_ENTITLEMENTS": '"ClipboardManager/ClipboardManager.entitlements"',
    "CODE_SIGN_STYLE": "Automatic",
    "COMBINE_HIDPI_IMAGES": "YES",
    "CURRENT_PROJECT_VERSION": "1",
    "DEVELOPMENT_TEAM": '""',
    "ENABLE_HARDENED_RUNTIME": "YES",
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_FILE": '"ClipboardManager/Info.plist"',
    "INFOPLIST_KEY_LSApplicationCategoryType": '"public.app-category.utilities"',
    "INFOPLIST_KEY_NSHumanReadableCopyright": '"Copyright © 2026. All rights reserved."',
    "LD_RUNPATH_SEARCH_PATHS": '("$(inherited)", "@executable_path/../Frameworks")',
    "MACOSX_DEPLOYMENT_TARGET": "14.0",
    "MARKETING_VERSION": "1.0",
    "PRODUCT_BUNDLE_IDENTIFIER": "com.historyclipboard.app",
    "PRODUCT_NAME": '"$(TARGET_NAME)"',
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SWIFT_VERSION": "6.0",
}

lines.append(build_config(TDC, "Debug", target_settings))
lines.append(build_config(TRC, "Release", target_settings))
lines.append("/* End XCBuildConfiguration section */")

# -- XCConfigurationList --
lines.append("/* Begin XCConfigurationList section */")
lines.append(config_list(PCL, [PDC, PRC], "Release"))
lines.append(config_list(TCL, [TDC, TRC], "Release"))
lines.append("/* End XCConfigurationList section */")

# ============================================================
# 组装输出
# ============================================================
content = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

{chr(10).join(lines)}

\t}};
\trootObject = {PID} /* Project object */;
}}
"""

out = os.path.join(os.path.dirname(__file__), "ClipboardManager.xcodeproj", "project.pbxproj")
with open(out, "w", encoding="utf-8") as f:
    f.write(content)

# 同时生成 scheme 文件
scheme_dir = os.path.join(os.path.dirname(__file__), "ClipboardManager.xcodeproj", "xcshareddata", "xcschemes")
os.makedirs(scheme_dir, exist_ok=True)
scheme_path = os.path.join(scheme_dir, "ClipboardManager.xcscheme")

scheme_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "2600" version = "1.3">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{TID}" BuildableName = "ClipboardManager.app" BlueprintName = "ClipboardManager" ReferencedContainer = "container:ClipboardManager.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{TID}" BuildableName = "ClipboardManager.app" BlueprintName = "ClipboardManager" ReferencedContainer = "container:ClipboardManager.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{TID}" BuildableName = "ClipboardManager.app" BlueprintName = "ClipboardManager" ReferencedContainer = "container:ClipboardManager.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>'''

with open(scheme_path, "w", encoding="utf-8") as f:
    f.write(scheme_content)

print(f"✅ project.pbxproj 已生成")
print(f"✅ xcscheme 已生成")
print(f"   Target ID: {TID}")
print(f"   {len(src)} 源文件 + {len(res)} 资源文件")
