const fs = require('fs');
const path = require('path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const read = f => fs.readFileSync(path.join(root, f), 'utf8');
const pbx = read('ChanDauSo.xcodeproj/project.pbxproj');
const ids = [...pbx.matchAll(/^([A-F0-9]{24}) = /gm)].map(x => x[1]);
assert.equal(new Set(ids).size, ids.length, 'Unique project object IDs');
for (const ref of pbx.matchAll(/\b[A-F0-9]{24}\b/g)) assert(ids.includes(ref[0]), 'Resolved PBX reference ' + ref[0]);
assert.equal((pbx.match(/isa = PBXNativeTarget/g) || []).length, 2);
for (const file of pbx.matchAll(/path = "([^"\n]+\.swift)"/g)) assert(fs.existsSync(path.join(root, file[1])));
for (const file of ['Shared/BlockingRules.swift', 'Shared/SharedStorage.swift']) {
  const ref = pbx.split('\n').find(line => line.includes(`path = "${file}"`)).slice(0,24);
  assert.equal(pbx.split('\n').filter(line => line.includes('isa = PBXBuildFile') && line.includes(ref)).length, 2);
}
for (const target of ['App','Extension']) {
  assert(read(`${target}/Entitlements.plist`).includes('group.vn.chandauso.local'));
  assert(pbx.includes(`INFOPLIST_FILE = ${target}/Info.plist`));
}
assert(read('Shared/SharedStorage.swift').includes('group.vn.chandauso.local'));
assert(read('Shared/SharedStorage.swift').includes('vn.chandauso.local.directory'));
assert(read('Extension/Info.plist').includes('com.apple.callkit.call-directory'));
assert(read('scripts/build-ipa.sh').includes('codesign --verify --deep --strict'));
assert(read('.github/workflows/build-ipa.yml').includes('bash scripts/build-ipa.sh'));
console.log('PASS: project references, both targets, shared sources, App Group, extension registration and packaging structure.');
