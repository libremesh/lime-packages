All notable changes to this project will be documented in this file.    

## Unreleased: branch master (2025-05-20)
https://github.com/libremesh/lime-packages/compare/v2024.1-rc1...master

### Full changelog since 2024.1
  - [`8aea25a`](https://github.com/libremesh/lime-packages/commit/8aea25a23871d6c13f85425ad8d511a50ab929d2) - 
      2025-05-22 - 
      Follow-up to #938: Fix README link and improve clusterssh command
      (merge [#1173](https://github.com/libremesh/lime-packages/pull/1173))
  - [`75d1386`](https://github.com/libremesh/lime-packages/commit/75d1386e5022b41cc1c114d96e5c3af3047624d8) - 
      2025-05-20 - 
      Easing libremesh virtualization
      (merge [#938](https://github.com/libremesh/lime-packages/pull/938))
  - [`ca63283`](https://github.com/libremesh/lime-packages/commit/ca6328347b97728b796fa28d243e02f95f7c6616) - 
      2025-01-22 - 
      Scrape device names from board.json
      (merge [#1154](https://github.com/libremesh/lime-packages/pull/1154))
  - [`a1618d0`](https://github.com/libremesh/lime-packages/commit/a1618d0f18e9ca04d32eb419c330aa0361521d2c) - 
      2025-01-22 - 
      Watchping: increase wait time for interface to get up
      (merge [#1158](https://github.com/libremesh/lime-packages/pull/1158))
  - [`5e43aa2`](https://github.com/libremesh/lime-packages/commit/5e43aa248c3f079f2ca316fd61a0b8c1c473c547) - 
      2025-01-22 - 
      network: Do not configure protocols on DSA switch port network devices by default.
      (merge [#1161](https://github.com/libremesh/lime-packages/pull/1161))
  - [`7345673`](https://github.com/libremesh/lime-packages/commit/7345673cef523ad2c8d5787ff1373800dc1a1d7f) - 
      2024-12-31 - 
      Automatically postpone automated reboots by deferable-reboot
      (merge [#1147](https://github.com/libremesh/lime-packages/pull/1147))
  - [`6f307bb`](https://github.com/libremesh/lime-packages/commit/6f307bb6fb2ee09a13080419004f1ed3dcc2345c) - 
      2024-12-27 - 
      network._get_lower do not cause "ls" error when there is no lower
      (merge [#1145](https://github.com/libremesh/lime-packages/pull/1145))
  - [`477ee4b`](https://github.com/libremesh/lime-packages/commit/477ee4b77c9c3741afe45a8af7edf5f10dab4e50) - 
      2024-12-27 - 
      Fixes on ubus-lime-utils
      (merge [#1143](https://github.com/libremesh/lime-packages/pull/1143))
  - [`e65b7f1`](https://github.com/libremesh/lime-packages/commit/e65b7f178eae0012977b8ebcf62e8bae8a652d62) - 
      2024-12-27 - 
      hotplug-initd-observer: Avoid format error when evData.service is empty
      (merge [#1148](https://github.com/libremesh/lime-packages/pull/1148))
  - [`29b5f66`](https://github.com/libremesh/lime-packages/commit/29b5f6663c40b78fe2af922d1af294a1b7d39978) - 
      2024-12-27 - 
      Fix get node status to work with busybox ip command
      (merge [#1159](https://github.com/libremesh/lime-packages/pull/1159))
  - [`51294cc`](https://github.com/libremesh/lime-packages/commit/51294cc806b9237ffd07090b2b76ea1e9dcad72f) - 
      2024-12-27 - 
      Adding "iw phy" to lime-report
      (merge [#1160](https://github.com/libremesh/lime-packages/pull/1160))
  - [`50a4a09`](https://github.com/libremesh/lime-packages/commit/50a4a097ebcfaeb13f04d1a1a5df401ca7892919) - 
      2024-12-08 - 
      fix: typo of ubus-lime-groundrouting; fix multi-arch-build
      (merge [#1153](https://github.com/libremesh/lime-packages/pull/1153))
  - [`e3fedb1`](https://github.com/libremesh/lime-packages/commit/e3fedb1785b5632d110f4539c1b594ec00b08321) - 
      2024-12-08 - 
      changelog: update
      (merge [#1152](https://github.com/libremesh/lime-packages/pull/1152))
  - [`35471b0`](https://github.com/libremesh/lime-packages/commit/35471b0f046132e1848836521900e74f1ed7d9e5) - 
      2024-11-23 - 
      New full documentation for shared-state
      (merge [#1142](https://github.com/libremesh/lime-packages/pull/1142),
      fix [#492](https://github.com/libremesh/lime-packages/issues/492))
  - [`0878431`](https://github.com/libremesh/lime-packages/commit/08784318f4e9fd4269675bd9dbc8ebf6962ce5da) - 
      2024-11-19 - 
      fixed typo ubus-lime-groundrouting in lime-app's Makefile
      (merge [#1141](https://github.com/libremesh/lime-packages/pull/1141))
  - [`88b0846`](https://github.com/libremesh/lime-packages/commit/88b0846b850cfffedd4be76ffa13357a7298cdcc) - 
      2024-11-19 - 
      fix: ci build packages failed
      (merge [#1140](https://github.com/libremesh/lime-packages/pull/1140))
  - [`06609f6`](https://github.com/libremesh/lime-packages/commit/06609f685af2fbf14e6366cce12ce7af27202b9d) - 
      2024-11-17 - 
      Pirania New Release - Issue/1077
      (merge [#1133](https://github.com/libremesh/lime-packages/pull/1133))
  - [`08a3948`](https://github.com/libremesh/lime-packages/commit/08a3948a5a80f6e26318c96227e02466bd09345e) - 
      2024-09-24 - 
      Ensure that wan interface gets configured on DSA devices, where wan could be the name of the interface
      (merge [#1131](https://github.com/libremesh/lime-packages/pull/1131))
  - [`527c1eb`](https://github.com/libremesh/lime-packages/commit/527c1ebc44dcd3bd6edf44087ca645e5989aedeb) - 
      2024-08-28 - 
      Shared-state mesh information packages async implmentation and reference state 
      (merge [#1112](https://github.com/libremesh/lime-packages/pull/1112))
  - [`a3d751c`](https://github.com/libremesh/lime-packages/commit/a3d751c1d3a5842b2104ef9b801c5d47e46440b0) - 
      2024-08-01 - 
      Stop using random-numgen, not needed in recent OpenWrt
      (merge [#1117](https://github.com/libremesh/lime-packages/pull/1117),
      fix [#800](https://github.com/libremesh/lime-packages/issues/800) [#1075](https://github.com/libremesh/lime-packages/issues/1075))
  - [`4bdd010`](https://github.com/libremesh/lime-packages/commit/4bdd010ef8d7182467bb86035e83f922b70d83d5) - 
      2024-06-20 - 
      readme: added network-profiles repository to ImageBuilder instructions
      (merge [#1113](https://github.com/libremesh/lime-packages/pull/1113))
  - [`3ef0a4a`](https://github.com/libremesh/lime-packages/commit/3ef0a4ac2988a6013ed7b7364ff9c94d9c910367) - 
      2024-06-20 - 
      Readme: update OpenWrt version in Docker instructions
      (merge [#1116](https://github.com/libremesh/lime-packages/pull/1116))
  - [`070d518`](https://github.com/libremesh/lime-packages/commit/070d5182b184702030335f17125cf5b18389df34) - 
      2024-06-20 - 
      lime-example: specify that the gateway line in the static proto is optional
      (merge [#1114](https://github.com/libremesh/lime-packages/pull/1114))
  - [`88b4fdd`](https://github.com/libremesh/lime-packages/commit/88b4fdde3e758fafd26bbc60f06a8a63b83b4bdb) - 
      2024-05-30 - 
      shared-state-async bump for late bleach fixup
      (merge [#1111](https://github.com/libremesh/lime-packages/pull/1111))
  - [`58bbd4d`](https://github.com/libremesh/lime-packages/commit/58bbd4debaa9dd9f3e2e42b1196348c207f97e7c) - 
      2024-05-29 - 
      fix broken profiles
      (merge [#1115](https://github.com/libremesh/lime-packages/pull/1115))
  - [`727af91`](https://github.com/libremesh/lime-packages/commit/727af91f23d7fb8d7a598605f2b6e012c0b11c2d) - 
      2024-05-10 - 
      Shared state async intial publish
      (merge [#1104](https://github.com/libremesh/lime-packages/pull/1104))
  - [`f326ad8`](https://github.com/libremesh/lime-packages/commit/f326ad84cddda7f399145e790676e94e2e2fbc32) - 
      2024-04-24 - 
      A few cleanups to packages
      (merge [#1097](https://github.com/libremesh/lime-packages/pull/1097))
  - [`70b08a6`](https://github.com/libremesh/lime-packages/commit/70b08a691c860b55f47f4c0913fa2b472b0d99b5) - 
      2024-04-24 - 
      safe-upgrade: update calibration data partition name
      (merge [#1098](https://github.com/libremesh/lime-packages/pull/1098))
  - [`75f5d50`](https://github.com/libremesh/lime-packages/commit/75f5d508e8308e1ae7a8af047276600e94ded1d1) - 
      2024-04-24 - 
      Adds shared-state rpcd data,error output format and shared-state-async rpcd reimplementation 
      (merge [#1103](https://github.com/libremesh/lime-packages/pull/1103))


## 2024.1 Fantastic Fordwarer (2025-01-22)
https://github.com/libremesh/lime-packages/compare/2024.1...v2024.1    
Release notes: https://libremesh.org/news.html#2025_05_04_libremesh_2024_1_release    
List of commits cherry picked from the branch master

  - [`a9488ae`](https://github.com/libremesh/lime-packages/commit/a9488aeb11b8b0dbee960203278783fac074c99e) - 
      2024-12-10 - 
      network: Get device names from board.json
  - [`c77abb3`](https://github.com/libremesh/lime-packages/commit/c77abb354906250809ebe1b3f4bc4f01f6d2fbfb) - 
      2025-01-05 - 
      network: Do not configure protos on DSA ports...
  - [`0628c9e`](https://github.com/libremesh/lime-packages/commit/0628c9ecb86cc9a380c40f3d17ffd97755478daf) - 
      2024-12-10 - 
      utils: Add optional parameter 'port' to is_dsa()
  - [`5086f13`](https://github.com/libremesh/lime-packages/commit/5086f13624e0a34f2ec5bdede617a8abf540ea18) - 
      2024-12-18 - 
      watchping increase wait time for interface to get up
  - [`b2b3c43`](https://github.com/libremesh/lime-packages/commit/b2b3c43b99ba3a97db3182a0b7e2980282a63403) - 
      2025-01-03 - 
      set 2024.1 release name
  - [`c9a7686`](https://github.com/libremesh/lime-packages/commit/c9a7686766cbace00e2e2080f45f243d74ac3c48) - 
      2024-12-31 - 
      fix typo in package name deferable-reboot -> deferrable-reboot
  - [`bd233d5`](https://github.com/libremesh/lime-packages/commit/bd233d5d239c5c7e690111982770d610565de4e7) - 
      2024-12-31 - 
      deferable-reboot move cron command to file
  - [`8e7e17d`](https://github.com/libremesh/lime-packages/commit/8e7e17d5d78f8e605bc939a84aa7846668da2582) - 
      2024-12-02 - 
      cron deferable-reboot execute at random times
  - [`0225faf`](https://github.com/libremesh/lime-packages/commit/0225faf2433f01cf6e03f6a29c112d35ed83d37d) - 
      2024-12-02 - 
      cron deferable-reboot increase time to delay reboot
  - [`6c67158`](https://github.com/libremesh/lime-packages/commit/6c6715835ac9c726d16752663cbf34c916e42cb4) - 
      2024-11-25 - 
      de-hardcoded the ping target: moved to lime's system section
  - [`46858ad`](https://github.com/libremesh/lime-packages/commit/46858adc24b480cdaf2f6040230d2166e39e9c84) - 
      2024-11-25 - 
      avoid using Google IP, use the one from DNS in lime-defaults
  - [`6ad3870`](https://github.com/libremesh/lime-packages/commit/6ad38700a884118a3f6121860ec1534d51b835ec) - 
      2024-11-25 - 
      file from LibreRouterOS for checking internet connection ...
  - [`3faa223`](https://github.com/libremesh/lime-packages/commit/3faa2235aa8c0ad218801094c27a03e2a9bca79c) - 
      2024-11-23 - 
      network._get_lower do not cause ls error when there is no lower
  - [`a56200d`](https://github.com/libremesh/lime-packages/commit/a56200d462bba0f71835df5813c99e16957c7508) - 
      2024-11-23 - 
      check if client-wwan interface exists before using it
  - [`fd5265c`](https://github.com/libremesh/lime-packages/commit/fd5265c3e8a70f0fc3f1fd1a0c344355075e2ab7) - 
      2024-11-23 - 
      fix if check for non-empty variable
  - [`c663032`](https://github.com/libremesh/lime-packages/commit/c6630322034483659a397b947cfa3ee9612c4c2e) - 
      2024-11-23 - 
      check if watchping exists before using it
  - [`3d90a9b`](https://github.com/libremesh/lime-packages/commit/3d90a9b78148aef535d9a0c96b799a639684a6db) - 
      2024-11-26 - 
      avoid format error when evData.service is empty
  - [`a7aa9d9`](https://github.com/libremesh/lime-packages/commit/a7aa9d9ebd5dfdf850669a5a2d827ecbcb2a484e) - 
      2024-12-23 - 
      fix get node status to work with busybox ip
  - [`71ffb60`](https://github.com/libremesh/lime-packages/commit/71ffb60a48346f131a2ea08c41f160d09ed4dc19) - 
      2024-12-24 - 
      added "iw phy" to lime-report
  - [`ddd5f0a`](https://github.com/libremesh/lime-packages/commit/ddd5f0ae207c7dd9dac818c0f7a6b515144b6f34) - 
      2024-11-19 - 
      fixed typo ubus-lime-groundrouting in lime-app's Makefile
  - [`f066704`](https://github.com/libremesh/lime-packages/commit/f066704bd9e757da6595faccad505ca1c592a7a7) - 
      2024-12-07 - 
      fix: typo of ubus-lime-groundrouting; fix multi-arch-build
  - [`e431fef`](https://github.com/libremesh/lime-packages/commit/e431fef442f4d9fefb255d1046e8cb4ecdb173c0) - 
      2024-11-19 - 
      fix: ci build packages failed
  - [`7b0ea4b`](https://github.com/libremesh/lime-packages/commit/7b0ea4bca6d165e9d4f6d0cc868464fcc0bdfee3) - 
      2024-11-17 - 
      henmohr GSoC Pirania New Release
  - [`aa9161a`](https://github.com/libremesh/lime-packages/commit/aa9161aa35d603df4ab014f4e2b06ad7a6446f87) - 
      2024-09-20 - 
      lime-system ensure that wan interface gets configured
  - [`eb19470`](https://github.com/libremesh/lime-packages/commit/eb19470172ded3be25437ec38fd32ec58b5171e5) - 
      2024-07-05 - 
      removed more unneeded $
  - [`ceefb65`](https://github.com/libremesh/lime-packages/commit/ceefb6558d9777760510afb9b43213f83da51981) - 
      2024-07-05 - 
      removed unneeded $
  - [`787497a`](https://github.com/libremesh/lime-packages/commit/787497aa37753416773bc3c112bceb230c70165f) - 
      2024-06-30 - 
      stop using random-numgen, not needed in recent OpenWrt
  - [`d67326a`](https://github.com/libremesh/lime-packages/commit/d67326a6ed1311955b469a81b875eca4381c5fbc) - 
      2024-03-19 - 
      Fix pirania circular dependencies
  - [`a8ff01d`](https://github.com/libremesh/lime-packages/commit/a8ff01d4d2e570066adc02eb730e0b5c711dd80b) - 
      2024-03-19 - 
      Remove unmaintained broken packages
  - [`5cd8833`](https://github.com/libremesh/lime-packages/commit/5cd8833b84499e484512153eeed407e442cc6de5) - 
      2024-05-13 - 
      shared-state-async version bump
  - [`b58b01f`](https://github.com/libremesh/lime-packages/commit/b58b01f95a89313d5d9940669ccfd03167ca3023) - 
      2024-05-17 - 
      fix broken profiles
  - [`4bc20ed`](https://github.com/libremesh/lime-packages/commit/4bc20ed270e6de1b09a62563b7bb00de6f88b580) - 
      2024-04-03 - 
      update changelog

## 2024.1-rc1 - Release candidate 1 (2024-04-03)

### Full changelog since 2023.1-rc2

  - [`3b2ccf5`](https://github.com/libremesh/lime-packages/commit/3b2ccf5944f10eeefef6d12f005e67b53de01be2) - 
      2024-04-03 - 
      lime-app: update to v0.2.26
      (merge [#1101](https://github.com/libremesh/lime-packages/pull/1101))
  - [`f7ff091`](https://github.com/libremesh/lime-packages/commit/f7ff091a6e5ec908b34ae3f2bdfa157830ca7afe) - 
      2024-03-28 - 
      ci: multi-arch-build: use a different output path
      (merge [#1100](https://github.com/libremesh/lime-packages/pull/1100))
  - [`f5c5285`](https://github.com/libremesh/lime-packages/commit/f5c5285347e4b887d614d7921eeba8f0e0a4ab82) - 
      2024-03-24 - 
      ci: multi-arch-build: run one job at a time
      (merge [#1099](https://github.com/libremesh/lime-packages/pull/1099))
  - [`4be8f34`](https://github.com/libremesh/lime-packages/commit/4be8f3416579c8590d29b010eb6dcb6103046593) - 
      2024-03-19 - 
      lime-utils: implement DSA support for node status
      (merge [#1096](https://github.com/libremesh/lime-packages/pull/1096))
  - [`7bfa124`](https://github.com/libremesh/lime-packages/commit/7bfa124b71addbbd0c59c85d344ec0febdc0775e) - 
      2024-03-19 - 
      ci: multi-arch-build: enable the build of package index + various fixes
      (merge [#1095](https://github.com/libremesh/lime-packages/pull/1095))
  - [`d3d2086`](https://github.com/libremesh/lime-packages/commit/d3d20863306ac8a6e3fefa7051ab63a5554b1890) - 
      2024-03-15 - 
      Shrared state Async ubus interface 
      (merge [#1086](https://github.com/libremesh/lime-packages/pull/1086))
  - [`8d5d7de`](https://github.com/libremesh/lime-packages/commit/8d5d7de7d20cf88c05a7f27c2c45adb523fb70a6) - 
      2024-03-15 - 
      bat_hosts: fixes rpcd error
      (merge [#1094](https://github.com/libremesh/lime-packages/pull/1094),
      partial fix [#1093](https://github.com/libremesh/lime-packages/issues/1093))
  - [`069ac1a`](https://github.com/libremesh/lime-packages/commit/069ac1a8a187a4de00a78734f9527c9caa1cb7c3) - 
      2024-03-12 - 
      links information according to batman protocol
      (merge [#1055](https://github.com/libremesh/lime-packages/pull/1055))
  - [`7b7fcd7`](https://github.com/libremesh/lime-packages/commit/7b7fcd7600b2faafa352e8915c03f5c903cee09f) - 
      2024-03-12 - 
      Links information module for shared state according to babeld 
      (merge [#1056](https://github.com/libremesh/lime-packages/pull/1056))
  - [`f7d279e`](https://github.com/libremesh/lime-packages/commit/f7d279e097a103169bd3caae586b9c7550b3a707) - 
      2024-03-04 - 
      ci: add multi-arch-build.yml;
      (merge [#1091](https://github.com/libremesh/lime-packages/pull/1091))
  - [`90e3301`](https://github.com/libremesh/lime-packages/commit/90e330188543b9f671660eeca9bbb664a69a0e55) - 
      2024-03-04 - 
      ci: rebuild packages via sdk only when a package changes
      (merge [#1089](https://github.com/libremesh/lime-packages/pull/1089))
  - [`4dc7f98`](https://github.com/libremesh/lime-packages/commit/4dc7f984bb46e0d153f53d5764e06d3e29f69e7a) - 
      2024-02-29 - 
      lime-system: rename /lib/upgrade/keep.d/dropbear to /lib/upgrade/keep.d/dropbear-full
      (merge [#1090](https://github.com/libremesh/lime-packages/pull/1090))
  - [`fe00acb`](https://github.com/libremesh/lime-packages/commit/fe00acb5cb96ad433a90ac0d6575a8fa650ec40b) - 
      2024-02-27 - 
      Draft: update changelog
      (merge [#1088](https://github.com/libremesh/lime-packages/pull/1088))
  - [`6992335`](https://github.com/libremesh/lime-packages/commit/699233525486def1c3ac9e7a698eb9d180a7b43f) - 
      2024-02-26 - 
      Add shared-state-async network statistics sharing
      (merge [#1087](https://github.com/libremesh/lime-packages/pull/1087))
  - [`ebf4b7b`](https://github.com/libremesh/lime-packages/commit/ebf4b7be97866644a16e5b73edf48a6d8d2b5210) - 
      2024-02-21 - 
      Fix removing ports from br-lan
      (merge [#1084](https://github.com/libremesh/lime-packages/pull/1084),
      fix [#1083](https://github.com/libremesh/lime-packages/issues/1083))
  - [`63242c2`](https://github.com/libremesh/lime-packages/commit/63242c2fec24d629ac27e705e55e6788465d4ddb) - 
      2024-02-14 - 
      Document how to set ethernet interfaces for mesh only or clients only.
      (merge [#1085](https://github.com/libremesh/lime-packages/pull/1085))
  - [`3aa8c1c`](https://github.com/libremesh/lime-packages/commit/3aa8c1c6adee3ab838850887565b1365c898888e) - 
      2024-02-14 - 
      shared-state-async fix log pollution
      (merge [#1082](https://github.com/libremesh/lime-packages/pull/1082),
      fix [#1081](https://github.com/libremesh/lime-packages/issues/1081))
  - [`8b577bf`](https://github.com/libremesh/lime-packages/commit/8b577bf3d0ffc8974144f00005adb6f327733109) - 
      2024-02-12 - 
      Fix lime-config fail when there is no lower iface
      (merge [#1080](https://github.com/libremesh/lime-packages/pull/1080))
  - [`0c8a915`](https://github.com/libremesh/lime-packages/commit/0c8a915e95c2d5bbf6a7c9225bd012888bdd72b9) - 
      2024-02-08 - 
      Set high metric on anygw prefix route
      (merge [#1079](https://github.com/libremesh/lime-packages/pull/1079),
      fix [#1078](https://github.com/libremesh/lime-packages/issues/1078))
  - [`e322985`](https://github.com/libremesh/lime-packages/commit/e3229857362dced31657dd5c94dd4f46a6221b29) - 
      2024-02-06 - 
      re-implement shared-state from scratch in modern C++ 
      (merge [#1067](https://github.com/libremesh/lime-packages/pull/1067))
  - [`a5eb7d8`](https://github.com/libremesh/lime-packages/commit/a5eb7d888b681e4cab81289949d809ee0e968880) - 
      2024-02-05 - 
      lime-unstuck-wa: Fix module path
      (merge [#1076](https://github.com/libremesh/lime-packages/pull/1076))
  - [`c98578e`](https://github.com/libremesh/lime-packages/commit/c98578e81e338408c8fb62e3a413ff1e807196af) - 
      2024-02-05 - 
      Prevent unnecessary options in wifi-iface
      (merge [#1073](https://github.com/libremesh/lime-packages/pull/1073))
  - [`5053cf0`](https://github.com/libremesh/lime-packages/commit/5053cf0cb46b7f865d9c3917c3b08232c88b66d1) - 
      2024-02-02 - 
      README.md: add info about how to add package feed
      (merge [#1074](https://github.com/libremesh/lime-packages/pull/1074))
  - [`f8d54f2`](https://github.com/libremesh/lime-packages/commit/f8d54f25d5fd005f72c18efbc8f1859f3d1d215f) - 
      2024-01-31 - 
      Readme.md: improve imagebuilder instructions
      (merge [#1072](https://github.com/libremesh/lime-packages/pull/1072))
  - [`0d30e2c`](https://github.com/libremesh/lime-packages/commit/0d30e2c47bc0b989bd8d9c442ed91255b1224756) - 
      2024-01-25 - 
      lime.wireless: Fix wireless.is5Ghz
      (merge [#1071](https://github.com/libremesh/lime-packages/pull/1071),
      fix [#1063](https://github.com/libremesh/lime-packages/issues/1063))
  - [`5a50b6f`](https://github.com/libremesh/lime-packages/commit/5a50b6f8571ec94f171214fc43add787fee0a6fc) - 
      2024-01-10 - 
      lime-docs: update PKG_SOURCE_URL
      (merge [#1053](https://github.com/libremesh/lime-packages/pull/1053))
  - [`361645e`](https://github.com/libremesh/lime-packages/commit/361645ee5c8ca19a0a60cbea5246708049b582cd) - 
      2023-11-01 - 
      Changelog
      (merge [#1062](https://github.com/libremesh/lime-packages/pull/1062))
  - [`d0c498f`](https://github.com/libremesh/lime-packages/commit/d0c498f7fec2512cece194c2da2b4d481a3aec6c) - 
      2023-10-22 - 
      Fix bridge device section confusion
      (merge [#1061](https://github.com/libremesh/lime-packages/pull/1061),
      fix [#1060](https://github.com/libremesh/lime-packages/issues/1060))
  - [`4c51c7e`](https://github.com/libremesh/lime-packages/commit/4c51c7e062c3dff6c5218ee797d5a79c2ad6bc3d) - 
      2023-10-07 - 
      Use SPDX License Identifier to shrink size
      (merge [#1018](https://github.com/libremesh/lime-packages/pull/1018))
  - [`9f8754b`](https://github.com/libremesh/lime-packages/commit/9f8754bc5392393a9c8c40b240b814f5f49c9413) - 
      2023-10-04 - 
      Small cleaning
      (merge [#1037](https://github.com/libremesh/lime-packages/pull/1037))
  - [`4569fec`](https://github.com/libremesh/lime-packages/commit/4569fecca32f06012ce48065ccc7631a0d52a11f) - 
      2023-10-04 - 
      Add new reference state data types to shared state
      (merge [#1042](https://github.com/libremesh/lime-packages/pull/1042))


## 2023.1-rc2 - Release candidate 2 (2023-09-17)

### Full changelog since 2023.1-rc1
  - Fix safe-upgrade bootstrap broken since OpenWrt 19.07 (merge [#1050](https://github.com/libremesh/lime-packages/pull/1050))
  - Add force option to safe-upgrade bootstrap cmd (merge [#1051](https://github.com/libremesh/lime-packages/pull/1051))
  - Default distance setting: increase 10x (merge [#1047](https://github.com/libremesh/lime-packages/pull/1047))
  - add wifi interface name in shared state wifi information module (merge [#1048](https://github.com/libremesh/lime-packages/pull/1048)) 
  - add freq information (merge [#1045](https://github.com/libremesh/lime-packages/pull/1045)) 
  - Enable Node Information Exchange (merge [#1043](https://github.com/libremesh/lime-packages/pull/1043))
  - readme: expanded instructions on ImageBuilder (merge [#1028](https://github.com/libremesh/lime-packages/pull/1028))
  - removed extra info from shared state (merge [#1041](https://github.com/libremesh/lime-packages/pull/1041)) 
  - wifi-unstuck-wa: allow parametrizable values for interval and timeout (merge [#1039](https://github.com/libremesh/lime-packages/pull/1039), fix [#1034](https://github.com/libremesh/lime-packages/issues/1034)) 
  - Shared state ubus (merge [#1040](https://github.com/libremesh/lime-packages/pull/1040))
  - New Shared-State wifi Links information module (merge [#1038](https://github.com/libremesh/lime-packages/pull/1038))

## 2023.1-rc1 - Release candidate 1 (2023-08-05)

### Full changelog
  - Add shared state async node (merge [#1030](https://github.com/libremesh/lime-packages/pull/1030))
  - lime.network.scandevices: fix finding intefaces on dsa devices (merge [#1033](https://github.com/libremesh/lime-packages/pull/1033)) 
  - Unit testing update (merge [#1027](https://github.com/libremesh/lime-packages/pull/1027))
  - various readme improvements (merge [#1015](https://github.com/libremesh/lime-packages/pull/1015))
  - remove old iw/iw-full compatibility check (merge [#1024](https://github.com/libremesh/lime-packages/pull/1024))
  - angw, lime-proto-bmx7: use nft includes instead of init.d scripts (merge [#1021](https://github.com/libremesh/lime-packages/pull/1021))
  - Remove iputils-ping retrocompatibility with OpenWrt 19.07 (merge [#999](https://github.com/libremesh/lime-packages/pull/999), fix [#794](https://github.com/libremesh/lime-packages/issues/794))
  - random-numgen: set PKGARCH:=all (merge [#1017](https://github.com/libremesh/lime-packages/pull/1017))
  - Updated lime-example to follow lime-defaults (merge [#1001](https://github.com/libremesh/lime-packages/pull/1001))
  - Adding the random-numgen command and use it for removing usage of $RANDOM (merge [#991](https://github.com/libremesh/lime-packages/pull/991), fix [#800](https://github.com/libremesh/lime-packages/issues/800))
  - Fix category of shared-state-dnsmasq_servers (merge [#994](https://github.com/libremesh/lime-packages/pull/994))
  - Added a few commands to lime-report (merge [#1005](https://github.com/libremesh/lime-packages/pull/1005))
  - lime-debug added iperf3 and jq (merge [#1011](https://github.com/libremesh/lime-packages/pull/1011))
  - Batman-adv add the orig_interval to the lime-* config files and set a larger default value (merge [#1013](https://github.com/libremesh/lime-packages/pull/1013), fix [#1010](https://github.com/libremesh/lime-packages/issues/1010))
  - Batman-adv allow the user to set the routing_algo (merge [#1014](https://github.com/libremesh/lime-packages/pull/1014))
  - shared-state-dnsmasq_servers correct serversfile option setting (merge [#1004](https://github.com/libremesh/lime-packages/pull/1004), partial fix [#970](https://github.com/libremesh/lime-packages/issues/970))
  - lime-proto-batadv remove retrocompatibility (merge [#1012](https://github.com/libremesh/lime-packages/pull/1012))
  - Fix category of babled-auto-gw-mode (merge [#1006](https://github.com/libremesh/lime-packages/pull/1006), fix [#996](https://github.com/libremesh/lime-packages/issues/996))
  - Move safe reboot to admin protected function (merge [#989](https://github.com/libremesh/lime-packages/pull/989), fix [#909](https://github.com/libremesh/lime-packages/issues/909))
  - Split network.lua's owrt_ifname_parser (merge [#998](https://github.com/libremesh/lime-packages/pull/998))
  - Expose get_loss (merge [#978](https://github.com/libremesh/lime-packages/pull/978))
  - Port libremesh to fw4 and nftables (merge [#990](https://github.com/libremesh/lime-packages/pull/990))
  - shared-state-dnsmasq_servers: new package (merge [#812](https://github.com/libremesh/lime-packages/pull/812))
  - Improve get node status results (merge [#974](https://github.com/libremesh/lime-packages/pull/974))
  - lime-proto-babeld: enable ubus bindings (merge [#987](https://github.com/libremesh/lime-packages/pull/987))
  - ubus-lime-utils place scripts in /etc/udhcpc.user.d/ (merge [#950](https://github.com/libremesh/lime-packages/pull/950), fix [#927](https://github.com/libremesh/lime-packages/issues/927))
  - Replace OpenWrt 19.07 switch config style with OpenWrt 21.02 one in proto-lan and network.lua's device parser (merge [#959](https://github.com/libremesh/lime-packages/pull/959))

## 2020.4 Expansive Emancipation (2023-09-17)

### Full changelog
- default distance setting increase 10x 


## 2020.3 Expansive Emancipation (2023-04-21)

### Release notes
List of notable changes since 2020.1:
- the support for OpenWrt 18.06 has been dropped
- lime-app has been updated from 0.2.9 to 0.2.25
- babeld-auto-gw-mode replaces batman-adv-auto-gw-mode for automatically deactivating gateways with no working internet connection (for network with more than one internet-sharing nodes)
- the wifi configuration has been split in 2ghz and 5ghz bands sections
- many new Prometheus exporters for more detailed monitoring of the nodes' status
- many minor fixes

Thanks to all the people who contributed to the lime-packages repository:
a-gave, Aman, AngiieOG, Brad, Daniel Golle, elián l, Frank95, FreifunkUFO, G10h4ck, gabri94, Germán Ferrero, Gui Iribarren, hiure, Humz, Ilario Gelmetti, itec, Jess, Juli, juliana, leonaard, Luandro, Marcos Gutierrez, meskio, Michael Jones, Micha Stöcker, Mike Russell, nicoechaniz, Nicolás Pace, p4u, PatoGit, Pau Escrich, Paul Spooren, Pedro Mauro, pony1k, radikal, Rohan Sharma, San Piccinini, selankon, valo, Vittorio Cuculo

Specifically, the ones who contributed to the changes from 2020.1 to 2020.3:
a-gave, altergui, aparcar, dangowrt, G10h4ck, germanferrero, ilario, itec78, julianaguerra, luandro, meskio, nicopace, pony1k, RhnSharma, selankon, spiccinini

Also, a priceless contribution came from the LibreMesh users who shared their experience commenting on the open tickets on Github, in the chat and in the mailing list!

### Full changelog
  - adujst lime_release and lime_codename

## 2020.2 Expansive Emancipation (2023-03-20)

### Full changelog
  - Check for /etc/init.d/odhcpd existence before executing (merge [#982](https://github.com/libremesh/lime-packages/pull/982), fix [#954](https://github.com/libremesh/lime-packages/issues/954))
  - shared-state check for babeld file existence before reading it (merge [#983](https://github.com/libremesh/lime-packages/pull/983))
  - check-date-http improve error handling (merge [#981](https://github.com/libremesh/lime-packages/pull/981), fix [#723](https://github.com/libremesh/lime-packages/issues/723))
  - shared-state get neigh avoid outputting empty lines (merge [#984](https://github.com/libremesh/lime-packages/pull/984))
  - dnsmasq move confdir setting for ujail, avoiding to fix batman-adv-auto-gw-mode (merge [#979](https://github.com/libremesh/lime-packages/pull/979), fix [#970](https://github.com/libremesh/lime-packages/issues/970))
  - shared-state-publish_dnsmasq_leases recognize IPv6 when IPv6 leases are present (merge [#975](https://github.com/libremesh/lime-packages/pull/975), fix [#969](https://github.com/libremesh/lime-packages/issues/969))
  - unstuck-wifi: send SIGTERM to iw-processes still running after 5 minutes (merge [#966](https://github.com/libremesh/lime-packages/pull/966), fix [#964](https://github.com/libremesh/lime-packages/issues/964))
  - Add meuno.info to anygw for portuguese acessibility (merge [#973](https://github.com/libremesh/lime-packages/pull/973))
  - Fix/lime utils issue (merge [#963](https://github.com/libremesh/lime-packages/pull/963), fix [#962](https://github.com/libremesh/lime-packages/issues/962)) 
  - lime-app: update title in lime-app (merge [#926](https://github.com/libremesh/lime-packages/pull/926))
  - Fixing some dependencies (merge [#941](https://github.com/libremesh/lime-packages/pull/941))
  - Feature/split lime metrics logic (merge [#937](https://github.com/libremesh/lime-packages/pull/937))
  - Feature/split lime utils logic (merge [#939](https://github.com/libremesh/lime-packages/pull/939))
  - migrate-wifi-bands-cfg check for conf files being existing (merge [#947](https://github.com/libremesh/lime-packages/pull/947), fix [#945](https://github.com/libremesh/lime-packages/issues/945))
  - network.lua use an alternate string if ifname is not found by owrt_device_parser (merge [#948](https://github.com/libremesh/lime-packages/pull/948), fix [#944](https://github.com/libremesh/lime-packages/issues/944))
  - Removal of packages with non-existing dependencies (merge [#943](https://github.com/libremesh/lime-packages/pull/943), fix [#929](https://github.com/libremesh/lime-packages/issues/929))
  - Feature/fbw verbose scanning (merge [#925](https://github.com/libremesh/lime-packages/pull/925))
  - Relax switch vlan filter (merge [#900](https://github.com/libremesh/lime-packages/pull/900))
  - Readme: updated mailing list direction (merge [#931](https://github.com/libremesh/lime-packages/pull/931))
  - shared-state: provide compressed cgi-bin endpoints (merge [#911](https://github.com/libremesh/lime-packages/pull/911))
  - Refactor/fbw new structure (merge [#923](https://github.com/libremesh/lime-packages/pull/923))
  - p-n-e-l: avoid underscore in package names (merge [#922](https://github.com/libremesh/lime-packages/pull/922))
  - pirania: preserve config on upgrade (merge [#921](https://github.com/libremesh/lime-packages/pull/921))
  - Lime app to version v0.2.25 (merge [#918](https://github.com/libremesh/lime-packages/pull/918))
  - Add client hotspot wwan connection handling (merge [#890](https://github.com/libremesh/lime-packages/pull/890))
  - wireless-service: fix ubus enpoint name (merge [#914](https://github.com/libremesh/lime-packages/pull/914))
  - keep.d: add banner.notes (merge [#915](https://github.com/libremesh/lime-packages/pull/915))
  - watchping: change starting value for last_hook_run (merge [#910](https://github.com/libremesh/lime-packages/pull/910))
  - location: fix set() inserting bad data to shared-state (merge [#908](https://github.com/libremesh/lime-packages/pull/908))
  - Pirania new API (merge [#893](https://github.com/libremesh/lime-packages/pull/893))
  - lime-proto-anygw: use the configured domain as a hostrecord (merge [#906](https://github.com/libremesh/lime-packages/pull/906))
  - Allow changing wifi password (merge [#901](https://github.com/libremesh/lime-packages/pull/901))
  - fbw: use a more permisive temporary wifi config (merge [#859](https://github.com/libremesh/lime-packages/pull/859))
  - lime-webui add dependency from luci-compat (merge [#899](https://github.com/libremesh/lime-packages/pull/899))
  - fbw: add optional country config (merge [#843](https://github.com/libremesh/lime-packages/pull/843))
  - Add feature mac-based config file (merge [#883](https://github.com/libremesh/lime-packages/pull/883))
  - Migrate frequency band suffix options to uci sections for each band (merge [#896](https://github.com/libremesh/lime-packages/pull/896))
  - prometheus-node-push-influx: new package (merge [#871](https://github.com/libremesh/lime-packages/pull/871))
  - Pirania rcpd api fixes and improvements (merge [#892](https://github.com/libremesh/lime-packages/pull/892))
  - add tail command to remove first character of the string (merge [#891](https://github.com/libremesh/lime-packages/pull/891), fix [#888](https://github.com/libremesh/lime-packages/issues/888))
  - Add shared state network nodes (merge [#873](https://github.com/libremesh/lime-packages/pull/873), fix [#867](https://github.com/libremesh/lime-packages/issues/867))
  - Refactor Pirania simplifying its code and fixing bugs (merge [#869](https://github.com/libremesh/lime-packages/pull/869))
  - Add shared state multiwriter (merge [#872](https://github.com/libremesh/lime-packages/pull/872), fix [#868](https://github.com/libremesh/lime-packages/pull/868))
  - Fix tmate black screen when joining (merge [#885](https://github.com/libremesh/lime-packages/pull/885))
  - lime-system: flush autogen before modifying it (merge [#882](https://github.com/libremesh/lime-packages/pull/882))
  - lime-location: keep the location settings (merge [#881](https://github.com/libremesh/lime-packages/pull/881))
  - LimeApp updated to v0.2.20 (merge [#880](https://github.com/libremesh/lime-packages/pull/880))
  - lime-utils-admin: add firmware upload acl permission (merge [#879](https://github.com/libremesh/lime-packages/pull/879))
  - Qemu 12 nodes in 4 different clouds (merge [#813](https://github.com/libremesh/lime-packages/pull/813))
  - Pirania cli explanations on README (merge [#865](https://github.com/libremesh/lime-packages/pull/865))
  - LimeApp updated to v0.2.16 (merge [#858](https://github.com/libremesh/lime-packages/pull/858))
  - lime-utils: on upgrade preserve configs by default (merge [#857](https://github.com/libremesh/lime-packages/pull/857))
  - Fix shared state location publisher (merge [#854](https://github.com/libremesh/lime-packages/pull/854))
  - fbw: support community lime-assets (merge [#852](https://github.com/libremesh/lime-packages/pull/852), fix [#846](https://github.com/libremesh/lime-packages/issues/846))
  - shared-state-bat_hosts: mv acl file to the correct directory (merge [#851](https://github.com/libremesh/lime-packages/pull/851), fix [#850](https://github.com/libremesh/lime-packages/issues/850))
  - Fix some missing dependencies (merge [#847](https://github.com/libremesh/lime-packages/pull/847))
  - RFC add babeld-auto-gw-mode (merge [#844](https://github.com/libremesh/lime-packages/pull/844))
  - LimeApp updated to v0.2.15 (merge [#840](https://github.com/libremesh/lime-packages/pull/840))
  - Shared state improvements (merge [#841](https://github.com/libremesh/lime-packages/pull/841))
  - Add ubus-tmate to expose tmate control for terminal sharing (merge [#839](https://github.com/libremesh/lime-packages/pull/839))
  - Refactor libremesh.mk and makefiles (merge [#829](https://github.com/libremesh/lime-packages/pull/829), fix [#825](https://github.com/libremesh/lime-packages/issues/825))
  - Lime proto babeld fixes (merge [#830](https://github.com/libremesh/lime-packages/pull/830))
  - Add unittests with coverage to GitHub-CI (merge [#836](https://github.com/libremesh/lime-packages/pull/836))
  - shared-state: multiple fixes (merge [#823](https://github.com/libremesh/lime-packages/pull/823))
  - lime-proto-batadv change MAC also of wlan interfaces (merge [#820](https://github.com/libremesh/lime-packages/pull/820))
  - Refactor lime location as lib and fix location shared state publishing (merge [#834](https://github.com/libremesh/lime-packages/pull/834))
  - Fix pirania missing dependency on shared-state-pirania (merge [#811](https://github.com/libremesh/lime-packages/pull/811))
  - shared-state: parse babeld.conf interfaces in get_candidates_neigh (merge [#831](https://github.com/libremesh/lime-packages/pull/831))
  - lime-utils: remove debugging print (merge [#832](https://github.com/libremesh/lime-packages/pull/832))
  - Add lua remote debugging instructions (merge [#828](https://github.com/libremesh/lime-packages/pull/828))
  - Update readme (merge [#827](https://github.com/libremesh/lime-packages/pull/827))

## 2020.1 Expansive Emancipation (2020-12-14)

### Release notes
The LibreMesh team is happy to announce a new version of LibreMesh, 2020.1 "ExpansiveEmancipation". 
Three years of work, 882 commits, 23 developers, tons of bug fixes and improvements!

This release is compatible with OpenWrt stable 19.07.5 and old-stable 18.06.9. 
For the time  source-only release so you will need compile it yourself for the devices used by your community using the easy to follow instructions in https://libremesh.org/development.html

#### What's in 2020.1 "Expansive Emancipation"
It is imposible to do a meaninful list of all the changes. A non complete list of the most relevant developments:
* LimeApp: an app to for the maintenance and deploy of community networks targeted to non-technical community members. https://github.com/libremesh/lime-app/
* A new community-oriented configuration system that facilitates collective maintenance of configurations.
* shared-state, a shared database for the network.
* first-boot-wizard, an optional helper to deploy and extend the network that it is well integrated with the LimeApp.
* Pirania, an optional boucher and captive portal solution for community networks https://github.com/libremesh/lime-packages/blob/master/packages/pirania/Readme.md
* Hundreds of fixes and code improvement.

#### Contributors
This release has contributions from communities and individuals from all around the world. Testing, software development, documentation, community building. Thank you all!!

A list of the software developers that contributed to this release was easily gathered from the git history: AngiieOG, Brad, Daniel Golle, FreifunkUFO, German Ferrero, Gioacchino Mazzurco, Gui Iribarren, Ilario Gelmetti, Jess, Luandro, Marcos Gutierrez, Michael Jones, Mike Russell, Nicolás Pace, PatoGit, Pau, Paul Spooren, Pedro Mauro, Santiago Piccinini, Vittorio Cuculo, hiure, radikalbjr, valo.


## 17.06 Dayboot Rely (2017-09-23)

### Release notes
So, this release was meant to be announced many months ago (as the
numbering suggests) but lack of coordination (me, gio, pau) delayed it.
In the meantime, some more fixes and improvements were introduced, and
most importantly, several (unpublished) intermediate "release
candidates" have been running for months now, in different community
networks (QuintanaLibre mainly, thanks to persevering NicoEchaniz, and
other smaller deployments)

Highlights are that ieee80211s is used by default (instead of adhoc)
which breaks "backward" connectivity with previous releases,
as well as changes in vlan tagging policy of bmx6 and batadv (which also
are not backwards compatible by default)
most notably, this vlan change fixes a hard-to-debug mtu shrinking bug
that pestered all releases so far (symptoms were varied and bizarre,
like having timeouts when trying to browse certain https sites,
sometimes, on random devices)
the biggest highlight on the dev side, is that we now use upstream SDK
(thanks to dangowrt for pushing this, and pau for implementing it!)
which brings us much closer to LEDE/OpenWrt and allows reporting
upstream ath9k bugs or such, among other benefits

* generic binaries, meant for testing or setting up temporary networks
  (i.e. when having the default AP SSID = LibreMesh.org is fine)

http://downloads.libremesh.org/dayboot_rely/17.06/targets/

(build is running right now, binaries should be ready tomorrow for sure)

* for custom builds, the recommended tool at this point is lime-sdk

http://libremesh.org/getit.html#cook_your_own_firmware_using_lime_sdk
https://github.com/libremesh/lime-sdk

* chef builds are not available at this point. there are plans to
integrate this release into chef in the future, but no ETA 🙁

Most of the following changelog was accomplished during the 2017/03
hackaton (https://www.youtube.com/watch?v=5UX1FwhIKGY)

Additional source: http://es.wiki.guifi.net/wiki/LibreMesh/Changelog

### Full changelog
Changelog since 16.07 Community Chaos

  * based on LEDE 17.01.2
  * build everything using LEDE SDK, via new lime-sdk cooker (instead of
lime-build)
  * use ieee80211s instead of adhoc
  * reintroduced "firewall" package (to keep closer to upstream)
  * lime-system: fix ieee80211s proto, correctly construct ifnames
  * lime-system: sanitize hostname (transform everything into
alphanumeric and dash)
  * lime-system: new proto static
  * lime-system: new wifi mode client
  * lime-system: set dnsmasq force=1 to ensure dnsmasq never bails out
  * lime-system: explicitly populate /etc/config/lime with calculated values
  * lime-webui: enable i18n, finally webinterface is available in Spanish
  * lime-webui: Major rework by NicoPace, thanks!
    * bmx6 node graph now uses colors in a clever way
    * simple way to add "system notes" that are shown along with
/etc/banner and webui
    * luci-app-lime-location: fix google maps api key
    * new read-only view: switch ports status
    * alert luci-mod-admin users that their changes might get
overwritten by lime-config
    * fix batman-adv status webui
  * new package available to install lighttpd instead of uhttpd (needed
for an upcoming android app)
  * added a lime-sysupgrade command: does a sysupgrade but only
preserving libremesh configuration file
  * added a lime-apply command: basically calls reload_config, but also
applies hostname system-wide without rebooting
  * lime-hwd-ground-routing: ground routing now supports untagged ports too
  * lime-proto-anygw: unique mac based on ap_ssid (using %N1, %N2)
  * lime-proto-anygw: integrate better into /etc/config/dhcp instead of
/etc/dnsmasq.d/
  * lime-proto-wan: allow link-local traffic over wan (useful for local
ping6 and ssh, without global exposure)
  * lime-proto-batadv: set batadv gw_mode=client by default to
counteract rogue DHCP servers
  * lime-proto-bmx6: introduce bmx6_pref_gw option, adds priority (x10)
to a specific bmx6 gateway
  * lime-proto-bmx6: don't tag bmx6 packets over ethernet and so use at
least mtu=1500 everywhere
  * lime-proto-bmx6: avoid autodetected wan interface use vlan for bmx6
  * bmx6: doesn't flood log with some spurious warnings anymore (syslog=0)
  * bmx6: sms plugin now enabled by default
  * bmx6: daemon is now supervised by procd, so it is restarted in case
of crashes
  * bmx6: doesn't "configSync" by default anymore (no more "uci pending
changes" because of auto-gw-mode)
  * new bmx6hosts tool: maintain an /etc/hosts that resolves fd66: <->
hostnames.mesh
  * watchping: convert to procd and add reload triggers
  * safe-reboot: fix, use /overlay/upper instead of /overlay
  * safe-reboot: add "discard" action
  * ath9k: debugged some hangs (interface is deaf) and workaround it,
with new package "smonit"
  * set wifi default "distance" parameter to 1000 metres and make it
configurable through webui
  * alfred: fix bat-hosts facter, check for errors and don't nuke
/etc/bat-hosts in case of failure
  * introduce new lime-basic-noui metapackage
  * new packages separated: lime-docs and lime-docs-minimal
  * various Makefile dependency problems fixed

known bugs:
  * safe-reboot: newly introduced "discard" action is half-baked, avoid
usage until next release:
    It doesn't check whether there's a backup to restore or not -
https://github.com/libremesh/lime-packages/issues/203
    so executing "safe-reboot discard" without having done "safe-reboot"
first, will brick the router.
    (unbricking is possible via failsafe boot, and doing "mount_root &&
firstboot")

In the commit log authors you can see the usual suspects 😉
but happily many new names!
https://github.com/libremesh/lime-packages/graphs/contributors?from=2016-09-08&to=2017-09-23&type=c

and remember it's not only code/commits what matters, so big thanks as
well to everyone participating in mailing lists, maintaining website,
documentation (spread around the web, in many languages!)


## 16.07 Community Chaos (2016-09-08)

### Release notes
Thanks to everyone involved, finally we have an official release!
* generic binaries, meant for testing or setting up temporary networks
   (i.e. when having the default AP SSID = LibreMesh.org is fine)

http://downloads.libremesh.org/community_chaos/16.07/

* customized binaries with chef, meant for stable community networks
   (basically, you can preset a specific AP SSID and other settings
   common to the whole network, and then flash many routers in a row)
   can be generated at:

http://chef.libremesh.org/

### Full changelog 
Changelog since "BiggestBang" 15.09:
  * Now based on OpenWrt Chaos Calmer 15.05.1
  * Removed "firewall" package (which is included by default in vanilla
  OpenWrt/LEDE), since it's not really being used in LibreMesh setup. It
  can always be installed on a case-by-case basis using opkg.
    * there's a new minimal system that runs /etc/firewall.lime on boot
  (if "firewall" is not installed)
  * Removed "odhcpd" since we're not using it at the moment (we use dnsmasq)
  * Removed "odhcp6c" since we're not using it at the moment (we still
  haven't solved how to deal with native IPv6 coming over WAN, i.e.
  propagate a delegated prefix over the mesh in a reasonable way)
  * New default packages: "lime-hwd-openwrt-wan" and "lime-proto-wan".
  This checks if there's a WAN port, and automatically configures as "wan"
  proto (lime-proto-wan). The "wan" proto let's you assign in
  /etc/config/lime, for example, 802.1ad VLANs over the WAN port.
  * New default package: "lime-hwd-ground-routing". Allows you to
  configure 802.1q VLANs on embedded switches, so that you can separate
  specific ports and put
  * New default package: "bmx6-auto-gw-mode", so that when a node detects
  (with watchping) it can ping 8.8.8.8 over WAN port, a bmx6 tunIn is
  created on-the-fly, and Internet is shared to the rest of the clouds.
  * Workaround for an spurious log message caused by BATMAN-Adv ("br-lan:
  received packet on bat0 with own address as source address"): a "dummy0"
  interface is created and added to bat0, with a slightly different MAC
  address
    * https://lists.open-mesh.org/pipermail/b.a.t.m.a.n/2014-March/011839.html
  * New available packages: "lime-proto-bgp", allows to do BGP with bird
  daemon; and "lime-proto-olsr", "-olsr2" and "-olsr6", which add support
  for all versions of OLSR.
  * Some new settings possible in /etc/config/lime-defaults
    * wireless.htmode lets you preset the htmode for any wireless radio
  (or htmode_2ghz and htmode_5ghz for specific bands)
    * wireless.distance is the equivalent, for setting distance (and
  distance_2ghz / _5ghz)
    * system.domain for setting a cloud-wide domain name
  * New "named AP" interface by default: in addition to the shared SSID
  (where clients roam between nodes), there's a new AP with a different,
  unique SSID (it includes the node hostname). This lets people easily
  check with any stock smartphone (not only Android with a special app)
  which nodes are online, nearby, and their respective signal strength.
  Most importantly, it lets them connect to a specific AP and prevent
  roaming, when they need it. Roaming is a nuisance if you're in the
  middle of two nodes, with similar RSSI, but different performance
  (bandwidth to Internet). Finally, it gives users a very easy way to
  reliably access a specific (nearby) node webinterface, simply
  associating to a specific AP and browsing to http://thisnode.info/
  * Fixed all alfred facters (bat-hosts, dnsmasq-distributed-hosts,
  dnsmasq-lease-share), so that they retry the "alfred -r" when it fails
  (i.e. in slave mode)
  * LiMe web interface received love:
    * luci-app-lime-location (Simple Config -> Location) now works
    * Simple Config -> Advanced


