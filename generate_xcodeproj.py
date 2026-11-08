#!/usr/bin/env python3
import os
import uuid

def gen_id():
    return uuid.uuid4().hex[:24].upper()

def main():
    os.makedirs("Tidy.xcodeproj", exist_ok=True)

    # Collect source files
    source_files = []
    for root, dirs, files in os.walk("Tidy"):
        for f in files:
            if f.endswith(".swift"):
                rel_path = os.path.join(root, f)
                source_files.append((f, rel_path))

    test_files = []
    for root, dirs, files in os.walk("TidyTests"):
        for f in files:
            if f.endswith(".swift"):
                rel_path = os.path.join(root, f)
                test_files.append((f, rel_path))

    # Generate PBX IDs
    proj_id = gen_id()
    main_group_id = gen_id()
    tidy_group_id = gen_id()
    tidy_tests_group_id = gen_id()
    products_group_id = gen_id()

    app_target_id = gen_id()
    app_product_id = gen_id()
    app_sources_id = gen_id()
    app_resources_id = gen_id()
    app_frameworks_id = gen_id()

    test_target_id = gen_id()
    test_product_id = gen_id()
    test_sources_id = gen_id()
    test_frameworks_id = gen_id()

    # Build file mapping
    file_refs = {}
    build_files = {}

    for name, path in source_files:
        f_id = gen_id()
        bf_id = gen_id()
        file_refs[path] = (f_id, name)
        build_files[path] = bf_id

    for name, path in test_files:
        f_id = gen_id()
        bf_id = gen_id()
        file_refs[path] = (f_id, name)
        build_files[path] = bf_id

    # Assets & strings & images
    assets_path = "Tidy/Resources/Assets.xcassets"
    assets_id = gen_id()
    assets_build_id = gen_id()
    file_refs[assets_path] = (assets_id, "Assets.xcassets")
    build_files[assets_path] = assets_build_id

    strings_path = "Tidy/Resources/Localizable.xcstrings"
    strings_id = gen_id()
    strings_build_id = gen_id()
    file_refs[strings_path] = (strings_id, "Localizable.xcstrings")
    build_files[strings_path] = strings_build_id

    icon_light_path = "Tidy/Resources/AppIconLight.png"
    icon_light_build_id = gen_id()
    if os.path.exists(icon_light_path):
        f_id = gen_id()
        file_refs[icon_light_path] = (f_id, "AppIconLight.png")
        build_files[icon_light_path] = icon_light_build_id

    icon_dark_path = "Tidy/Resources/AppIconDark.png"
    icon_dark_build_id = gen_id()
    if os.path.exists(icon_dark_path):
        f_id = gen_id()
        file_refs[icon_dark_path] = (f_id, "AppIconDark.png")
        build_files[icon_dark_path] = icon_dark_build_id

    plist_path = "Tidy/Resources/Info.plist"
    plist_id = gen_id()
    file_refs[plist_path] = (plist_id, "Info.plist")

    entitlements_path = "Tidy/Resources/Tidy.entitlements"
    entitlements_id = gen_id()
    file_refs[entitlements_path] = (entitlements_id, "Tidy.entitlements")

    # Configurations
    app_debug_cfg_id = gen_id()
    app_release_cfg_id = gen_id()
    app_cfg_list_id = gen_id()

    test_debug_cfg_id = gen_id()
    test_release_cfg_id = gen_id()
    test_cfg_list_id = gen_id()

    proj_debug_cfg_id = gen_id()
    proj_release_cfg_id = gen_id()
    proj_cfg_list_id = gen_id()

    content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
"""
    for path, bf_id in build_files.items():
        f_id, name = file_refs[path]
        content += f"\t\t{bf_id} /* {name} in Sources/Resources */ = {{isa = PBXBuildFile; fileRef = {f_id} /* {name} */; }};\n"

    content += f"""/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t{app_product_id} /* Tidy.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Tidy.app; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{test_product_id} /* TidyTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = TidyTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};
"""

    for path, (f_id, name) in file_refs.items():
        if path.endswith(".swift"):
            content += f"\t\t{f_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{path}\"; sourceTree = SOURCE_ROOT; }};\n"
        elif path.endswith(".xcassets"):
            content += f"\t\t{f_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = \"{path}\"; sourceTree = SOURCE_ROOT; }};\n"
        elif path.endswith(".xcstrings"):
            content += f"\t\t{f_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text.json.xcstrings; path = \"{path}\"; sourceTree = SOURCE_ROOT; }};\n"
        elif path.endswith(".plist"):
            content += f"\t\t{f_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = \"{path}\"; sourceTree = SOURCE_ROOT; }};\n"
        elif path.endswith(".entitlements"):
            content += f"\t\t{f_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = \"{path}\"; sourceTree = SOURCE_ROOT; }};\n"
        elif path.endswith(".png"):
            content += f"\t\t{f_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = image.png; path = \"{path}\"; sourceTree = SOURCE_ROOT; }};\n"

    content += f"""/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{app_frameworks_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{test_frameworks_id} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\t{main_group_id} = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{tidy_group_id} /* Tidy */,
\t\t\t\t{tidy_tests_group_id} /* TidyTests */,
\t\t\t\t{products_group_id} /* Products */,
\t\t\t);
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{products_group_id} /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_product_id} /* Tidy.app */,
\t\t\t\t{test_product_id} /* TidyTests.xctest */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = \"<group>\";
\t\t}};
\t\t{tidy_group_id} /* Tidy */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
"""
    for path, (f_id, name) in file_refs.items():
        if path.startswith("Tidy/"):
            content += f"\t\t\t\t{f_id} /* {name} */,\n"

    content += f"""\t\t\t);
\t\t\tname = Tidy;
\t\t\tsourceTree = SOURCE_ROOT;
\t\t}};
\t\t{tidy_tests_group_id} /* TidyTests */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
"""
    for path, (f_id, name) in file_refs.items():
        if path.startswith("TidyTests/"):
            content += f"\t\t\t\t{f_id} /* {name} */,\n"

    content += f"""\t\t\t);
\t\t\tname = TidyTests;
\t\t\tsourceTree = SOURCE_ROOT;
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{app_target_id} /* Tidy */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {app_cfg_list_id} /* Build configuration list for PBXNativeTarget "Tidy" */;
\t\t\tbuildPhases = (
\t\t\t\t{app_sources_id} /* Sources */,
\t\t\t\t{app_frameworks_id} /* Frameworks */,
\t\t\t\t{app_resources_id} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = Tidy;
\t\t\tproductName = Tidy;
\t\t\tproductReference = {app_product_id} /* Tidy.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
\t\t{test_target_id} /* TidyTests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {test_cfg_list_id} /* Build configuration list for PBXNativeTarget "TidyTests" */;
\t\t\tbuildPhases = (
\t\t\t\t{test_sources_id} /* Sources */,
\t\t\t\t{test_frameworks_id} /* Frameworks */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = TidyTests;
\t\t\tproductName = TidyTests;
\t\t\tproductReference = {test_product_id} /* TidyTests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{proj_id} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{app_target_id} = {{
\t\t\t\t\t\tCreatedOnToolsRevelation = 1;
\t\t\t\t\t}};
\t\t\t\t\t{test_target_id} = {{
\t\t\t\t\t\tCreatedOnToolsRevelation = 1;
\t\t\t\t\t\tTestTargetID = {app_target_id};
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {proj_cfg_list_id} /* Build configuration list for PBXProject "Tidy" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tpl,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = {main_group_id};
\t\t\tproductRefGroup = {products_group_id} /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\t{app_target_id} /* Tidy */,
\t\t\t\t{test_target_id} /* TidyTests */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{app_resources_id} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{assets_build_id} /* Assets.xcassets in Resources */,
\t\t\t\t{strings_build_id} /* Localizable.xcstrings in Resources */,
"""
    if os.path.exists(icon_light_path):
        content += f"\t\t\t\t{icon_light_build_id} /* AppIconLight.png in Resources */,\n"
    if os.path.exists(icon_dark_path):
        content += f"\t\t\t\t{icon_dark_build_id} /* AppIconDark.png in Resources */,\n"

    content += f"""\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{app_sources_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
"""
    for _, path in source_files:
        bf_id = build_files[path]
        f_id, name = file_refs[path]
        content += f"\t\t\t\t{bf_id} /* {name} in Sources */,\n"

    content += f"""\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
\t\t{test_sources_id} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
"""
    for _, path in test_files:
        bf_id = build_files[path]
        f_id, name = file_refs[path]
        content += f"\t\t\t\t{bf_id} /* {name} in Sources */,\n"

    content += f"""\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{proj_debug_cfg_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{proj_release_cfg_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;
\t\t\t\tMACOSX_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = macosx;
\t\t\t\tSWIFT_COMPILATION_MODE = "wholemodule";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tSWIFT_VERSION = 6.0;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{app_debug_cfg_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = Tidy/Resources/Tidy.entitlements;
\t\t\t\tCODE_SIGN_IDENTITY = "-";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tINFOPLIST_FILE = Tidy/Resources/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/../Frameworks",
\t\t\t\t);
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tidy.cleaner;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{app_release_cfg_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = Tidy/Resources/Tidy.entitlements;
\t\t\t\tCODE_SIGN_IDENTITY = "-";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tENABLE_HARDENED_RUNTIME = YES;
\t\t\t\tINFOPLIST_FILE = Tidy/Resources/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/../Frameworks",
\t\t\t\t);
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tidy.cleaner;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\t{test_debug_cfg_id} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tidy.cleanerTests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Tidy.app/Contents/MacOS/Tidy";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{test_release_cfg_id} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCOMBINE_HIDPI_IMAGES = YES;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.tidy.cleanerTests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/Tidy.app/Contents/MacOS/Tidy";
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{proj_cfg_list_id} /* Build configuration list for PBXProject "Tidy" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{proj_debug_cfg_id} /* Debug */,
\t\t\t\t{proj_release_cfg_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{app_cfg_list_id} /* Build configuration list for PBXNativeTarget "Tidy" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{app_debug_cfg_id} /* Debug */,
\t\t\t\t{app_release_cfg_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{test_cfg_list_id} /* Build configuration list for PBXNativeTarget "TidyTests" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{test_debug_cfg_id} /* Debug */,
\t\t\t\t{test_release_cfg_id} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {proj_id} /* Project object */;
}}
"""
    with open("Tidy.xcodeproj/project.pbxproj", "w") as f:
        f.write(content)
    print("Generated Tidy.xcodeproj successfully.")

if __name__ == "__main__":
    main()
