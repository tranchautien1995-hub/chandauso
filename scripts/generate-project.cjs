// Creates a dependency-free, two-target Xcode project. Run with Node 18+.
const fs = require('fs');
const path = require('path');
const root = path.resolve(__dirname, '..');
let serial = 1;
const objects = [];
const id = () => (serial++).toString(16).toUpperCase().padStart(24, '0');
const quote = s => JSON.stringify(s);
const list = xs => '(' + xs.join(', ') + ')';
function add(type, fields, reserved) {
  const key = reserved || id();
  objects.push(`${key} = { isa = ${type}; ${fields} };`);
  return key;
}
const appTarget = id(), extTarget = id(), project = id();
const appProduct = add('PBXFileReference', 'explicitFileType = wrapper.application; path = ChanDauSo.app; sourceTree = BUILT_PRODUCTS_DIR;');
const extProduct = add('PBXFileReference', 'explicitFileType = "wrapper.app-extension"; path = ChanDauSoDirectory.appex; sourceTree = BUILT_PRODUCTS_DIR;');
const sources = {};
for (const file of ['App/ChanDauSoApp.swift','App/ContentView.swift','App/RuleStore.swift','Shared/BlockingRules.swift','Shared/SharedStorage.swift','Extension/CallDirectoryHandler.swift']) {
  sources[file] = add('PBXFileReference', `lastKnownFileType = sourcecode.swift; path = ${quote(file)}; sourceTree = "<group>";`);
}
function phase(files) {
  const buildFiles = files.map(file => add('PBXBuildFile', `fileRef = ${sources[file]};`));
  return add('PBXSourcesBuildPhase', `buildActionMask = 2147483647; files = ${list(buildFiles)}; runOnlyForDeploymentPostprocessing = 0;`);
}
const shared = ['Shared/BlockingRules.swift','Shared/SharedStorage.swift'];
const appSources = phase(['App/ChanDauSoApp.swift','App/ContentView.swift','App/RuleStore.swift',...shared]);
const extSources = phase(['Extension/CallDirectoryHandler.swift',...shared]);
const embedded = add('PBXBuildFile', `fileRef = ${extProduct}; settings = { ATTRIBUTES = (RemoveHeadersOnCopy); };`);
const embedPhase = add('PBXCopyFilesBuildPhase', `buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = (${embedded}); name = "Embed App Extensions"; runOnlyForDeploymentPostprocessing = 0;`);
const proxy = add('PBXContainerItemProxy', `containerPortal = ${project}; proxyType = 1; remoteGlobalIDString = ${extTarget}; remoteInfo = ChanDauSoDirectory;`);
const dependency = add('PBXTargetDependency', `target = ${extTarget}; targetProxy = ${proxy};`);
function configs(settings) {
  const ids = ['Debug','Release'].map(name => add('XCBuildConfiguration', `buildSettings = { ${settings} SWIFT_OPTIMIZATION_LEVEL = ${quote(name === 'Debug' ? '-Onone' : '-O')}; }; name = ${name};`));
  return add('XCConfigurationList', `buildConfigurations = ${list(ids)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;`);
}
const common = 'SDKROOT = iphoneos; IPHONEOS_DEPLOYMENT_TARGET = 15.1; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = 1; CLANG_ENABLE_MODULES = YES; SWIFT_STRICT_CONCURRENCY = minimal;';
const appConfig = configs(`${common} PRODUCT_NAME = ChanDauSo; PRODUCT_BUNDLE_IDENTIFIER = vn.chandauso.local; INFOPLIST_FILE = App/Info.plist; CODE_SIGN_ENTITLEMENTS = App/Entitlements.plist; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks";`);
const extConfig = configs(`${common} PRODUCT_NAME = ChanDauSoDirectory; PRODUCT_BUNDLE_IDENTIFIER = vn.chandauso.local.directory; INFOPLIST_FILE = Extension/Info.plist; CODE_SIGN_ENTITLEMENTS = Extension/Entitlements.plist; APPLICATION_EXTENSION_API_ONLY = YES; SKIP_INSTALL = YES; LD_RUNPATH_SEARCH_PATHS = "$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks";`);
add('PBXNativeTarget', `buildConfigurationList = ${appConfig}; buildPhases = (${appSources}, ${embedPhase}); buildRules = (); dependencies = (${dependency}); name = ChanDauSo; productName = ChanDauSo; productReference = ${appProduct}; productType = "com.apple.product-type.application";`, appTarget);
add('PBXNativeTarget', `buildConfigurationList = ${extConfig}; buildPhases = (${extSources}); buildRules = (); dependencies = (); name = ChanDauSoDirectory; productName = ChanDauSoDirectory; productReference = ${extProduct}; productType = "com.apple.product-type.app-extension";`, extTarget);
const products = add('PBXGroup', `children = (${appProduct}, ${extProduct}); name = Products; sourceTree = "<group>";`);
const mainGroup = add('PBXGroup', `children = ${list([...Object.values(sources), products])}; sourceTree = "<group>";`);
const projectConfigs = configs(common);
add('PBXProject', `attributes = { BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 1600; }; buildConfigurationList = ${projectConfigs}; compatibilityVersion = "Xcode 14.0"; developmentRegion = vi; hasScannedForEncodings = 0; knownRegions = (vi, en, Base); mainGroup = ${mainGroup}; productRefGroup = ${products}; projectDirPath = ""; projectRoot = ""; targets = (${appTarget}, ${extTarget});`, project);
const out = path.join(root, 'ChanDauSo.xcodeproj');
fs.mkdirSync(path.join(out, 'xcshareddata', 'xcschemes'), {recursive:true});
fs.writeFileSync(path.join(out,'project.pbxproj'), `// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n${objects.join('\n')}\n}; rootObject = ${project}; }\n`);
fs.writeFileSync(path.join(out,'xcshareddata','xcschemes','ChanDauSo.xcscheme'), `<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1600" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="${appTarget}" BuildableName="ChanDauSo.app" BlueprintName="ChanDauSo" ReferencedContainer="container:ChanDauSo.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="${appTarget}" BuildableName="ChanDauSo.app" BlueprintName="ChanDauSo" ReferencedContainer="container:ChanDauSo.xcodeproj"/></BuildableProductRunnable></LaunchAction>
<ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>\n`);
console.log('Generated ChanDauSo.xcodeproj');
