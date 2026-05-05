#!/usr/bin/env ruby
# setup_extensions.rb
#
# Adds two new targets to sportsmeal.xcodeproj:
#
#   1. SportsMealWidget   (iOS Widget Extension)        BK.sportsmeal.SportsMealWidget
#   2. SportsMealWatch    (watchOS companion app)       BK.sportsmeal.watchkitapp
#
# And wires them into the main `sportsmeal` iOS app via:
#   - "Embed Foundation Extensions" build phase  (for the widget)
#   - "Embed Watch Content" build phase          (for the watch app)
#
# Source files come from the existing on-disk folders SportsMealWidget/ and
# SportsMealWatch/ via Xcode 16's PBXFileSystemSynchronizedRootGroup, matching
# how the main app target already references its sources.
#
# Safe to re-run: skips targets/phases that already exist.
#
# Backup of project.pbxproj was taken to project.pbxproj.backup-pre-extensions
# before this script. To revert: `git checkout sportsmeal.xcodeproj`.

require 'xcodeproj'

PROJECT_PATH = 'sportsmeal.xcodeproj'
TEAM_ID      = '5767MTQ2K3'        # Read from existing main target
APP_GROUP    = 'group.com.bukmax.sportsmeal'
HOST_BUNDLE  = 'BK.sportsmeal'

proj = Xcodeproj::Project.open(PROJECT_PATH)
main = proj.targets.find { |t| t.name == 'sportsmeal' } or abort 'Main target not found'

# ---------------------------------------------------------------------------
# Helper: apply settings shared by every build configuration of a target.
# ---------------------------------------------------------------------------
def configure(target, settings)
  target.build_configurations.each do |cfg|
    cfg.build_settings.merge!(settings)
    # Strip warnings on Debug only
    if cfg.name == 'Release'
      cfg.build_settings['SWIFT_OPTIMIZATION_LEVEL']        = '-O'
      cfg.build_settings['SWIFT_COMPILATION_MODE']          = 'wholemodule'
    else
      cfg.build_settings['SWIFT_OPTIMIZATION_LEVEL']        = '-Onone'
      cfg.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = 'DEBUG'
    end
  end
end

# ---------------------------------------------------------------------------
# Helper: add a synchronized root group (Xcode 16 file-system sync) for the
# given on-disk folder path and attach it to the given target.
# ---------------------------------------------------------------------------
def add_sync_group(proj, target, folder_path)
  existing = proj.main_group.children.find do |c|
    c.is_a?(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup) &&
      c.path == folder_path
  end
  group = existing || begin
    g = proj.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
    g.source_tree = '<group>'
    g.path        = folder_path
    # display_name is auto-derived from path; PBXFileSystemSynchronizedRootGroup
    # has no `name` attribute (unlike regular PBXGroup).
    proj.main_group << g
    g
  end

  # Attach to target if not already
  unless target.file_system_synchronized_groups.include?(group)
    target.file_system_synchronized_groups << group
  end
  group
end

# ===========================================================================
# 1. Widget Extension target
# ===========================================================================
widget_name   = 'SportsMealWidget'
widget_bundle = "#{HOST_BUNDLE}.#{widget_name}"

widget = proj.targets.find { |t| t.name == widget_name }
if widget
  puts "[skip] Widget target '#{widget_name}' already exists"
else
  puts "[add ] Widget target '#{widget_name}'"
  widget = proj.new_target(
    :app_extension,    # productType = com.apple.product-type.app-extension
    widget_name,
    :ios,
    '18.2',            # IPHONEOS_DEPLOYMENT_TARGET
    nil,               # product group (auto)
    :swift             # language
  )

  configure(widget, {
    'PRODUCT_BUNDLE_IDENTIFIER'           => widget_bundle,
    'PRODUCT_NAME'                        => '$(TARGET_NAME)',
    'SWIFT_VERSION'                       => '5.0',
    'DEVELOPMENT_TEAM'                    => TEAM_ID,
    'CODE_SIGN_STYLE'                     => 'Automatic',
    'CODE_SIGN_ENTITLEMENTS'              => 'SportsMealWidgetExtension.entitlements',
    'MARKETING_VERSION'                   => '1.0',
    'CURRENT_PROJECT_VERSION'             => '1',
    'GENERATE_INFOPLIST_FILE'             => 'YES',
    'TARGETED_DEVICE_FAMILY'              => '1,2',
    'IPHONEOS_DEPLOYMENT_TARGET'          => '18.2',
    'SKIP_INSTALL'                        => 'YES',                       # required for embedded extensions
    'INFOPLIST_KEY_CFBundleDisplayName'   => 'SportsMeal Widget',
    'INFOPLIST_KEY_NSHumanReadableCopyright' => '',
    # Modern WidgetKit extensions need NSExtensionPointIdentifier in Info.plist.
    # Xcode 15+ supports this top-level INFOPLIST_KEY shortcut.
    'INFOPLIST_KEY_NSExtensionPointIdentifier' => 'com.apple.widgetkit-extension',
  })

  add_sync_group(proj, widget, 'SportsMealWidget')
end

# ===========================================================================
# 2. watchOS App target
# ===========================================================================
watch_name   = 'SportsMealWatch'
watch_bundle = "#{HOST_BUNDLE}.watchkitapp"

watch = proj.targets.find { |t| t.name == watch_name }
if watch
  puts "[skip] Watch target '#{watch_name}' already exists"
else
  puts "[add ] Watch target '#{watch_name}'"
  watch = proj.new_target(
    :application,      # productType = com.apple.product-type.application
    watch_name,
    :watchos,
    '11.0',
    nil,
    :swift
  )

  configure(watch, {
    'PRODUCT_BUNDLE_IDENTIFIER'                       => watch_bundle,
    'PRODUCT_NAME'                                    => '$(TARGET_NAME)',
    'SWIFT_VERSION'                                   => '5.0',
    'DEVELOPMENT_TEAM'                                => TEAM_ID,
    'CODE_SIGN_STYLE'                                 => 'Automatic',
    'MARKETING_VERSION'                               => '1.0',
    'CURRENT_PROJECT_VERSION'                         => '1',
    'GENERATE_INFOPLIST_FILE'                         => 'YES',
    'TARGETED_DEVICE_FAMILY'                          => '4',             # watchOS
    'WATCHOS_DEPLOYMENT_TARGET'                       => '11.0',
    'SDKROOT'                                         => 'watchos',
    'SUPPORTS_MACCATALYST'                            => 'NO',
    'SUPPORTED_PLATFORMS'                             => 'watchsimulator watchos',
    # WKApplication keys (modern single-target watchOS apps, watchOS 7+)
    'INFOPLIST_KEY_WKApplication'                     => 'YES',
    'INFOPLIST_KEY_WKCompanionAppBundleIdentifier'    => HOST_BUNDLE,
    'INFOPLIST_KEY_CFBundleDisplayName'               => 'SportsMeal',
    'INFOPLIST_KEY_UILaunchScreen_Generation'         => 'YES',
    'INFOPLIST_KEY_NSHumanReadableCopyright'          => '',
    'INFOPLIST_KEY_WKWatchOnly'                       => 'NO',            # paired companion mode
  })

  add_sync_group(proj, watch, 'SportsMealWatch')
end

# ===========================================================================
# 3. Main iOS app: add embed-extensions and embed-watch-content build phases
# ===========================================================================

# 3a. Embed Foundation Extensions (for Widget) ------------------------------
embed_ext = main.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' }
if embed_ext.nil?
  puts "[add ] 'Embed Foundation Extensions' phase on main target"
  embed_ext = main.new_copy_files_build_phase('Embed Foundation Extensions')
  embed_ext.symbol_dst_subfolder_spec = :plug_ins   # dstSubfolderSpec = 13
  embed_ext.dst_path                  = ''
else
  puts "[skip] 'Embed Foundation Extensions' phase already on main target"
end

unless embed_ext.files_references.include?(widget.product_reference)
  build_file = embed_ext.add_file_reference(widget.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  puts "       linked widget.appex into Embed Foundation Extensions"
end

# Make the main app depend on the widget so it gets built first
unless main.dependencies.any? { |d| d.target == widget }
  main.add_dependency(widget)
  puts "       added build dependency: main -> widget"
end

# 3b. Embed Watch Content (for Watch app) -----------------------------------
embed_watch = main.copy_files_build_phases.find { |p| p.name == 'Embed Watch Content' }
if embed_watch.nil?
  puts "[add ] 'Embed Watch Content' phase on main target"
  embed_watch = main.new_copy_files_build_phase('Embed Watch Content')
  # No symbol for "Wrapper/Watch" in the gem; set raw value 16 with custom dst path
  embed_watch.dst_subfolder_spec = '16'
  embed_watch.dst_path           = '$(CONTENTS_FOLDER_PATH)/Watch'
else
  puts "[skip] 'Embed Watch Content' phase already on main target"
end

unless embed_watch.files_references.include?(watch.product_reference)
  build_file = embed_watch.add_file_reference(watch.product_reference)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  puts "       linked watch app into Embed Watch Content"
end

unless main.dependencies.any? { |d| d.target == watch }
  main.add_dependency(watch)
  puts "       added build dependency: main -> watch"
end

# ===========================================================================
# Save
# ===========================================================================
proj.save
puts
puts "Done. Targets after save:"
proj.targets.each { |t| puts "  - #{t.name}  (#{t.product_type})" }
