const fs = require("fs");
const p = "D:/c35/clients/app/lib/c/remote/remote_fs_transfer.dart";
let t = fs.readFileSync(p, "utf8");
const importOld = "import 'package:alienai_c35/c/remote/remote_fs_api.dart';\nimport 'package:alienai_c35/c/remote/remote_session.dart';";
const importNew = "import 'package:alienai_c35/c/remote/remote_fs_api.dart';\nimport 'package:alienai_c35/c/remote/remote_fs_picker_staging.dart';\nimport 'package:alienai_c35/c/remote/remote_session.dart';";
if (!t.includes(importOld)) throw new Error("import");
t = t.replace(importOld, importNew);
fs.writeFileSync(p, t);
console.log("ok");
