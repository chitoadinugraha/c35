from pathlib import Path
root = Path(r"D:/c35/_/scripts/deploy/deploy_app")
api = root / "play_billing_monetization_api.dart"
t = api.read_text(encoding="utf-8")
t = t.replace("for (final path in ['/onetimeproducts', '/subscriptions'])", "for (final path in ['/oneTimeProducts', '/subscriptions'])")
api.write_text(t, encoding="utf-8")
sync = root / "play_billing_monetization_sync.dart"
s = sync.read_text(encoding="utf-8")
old = "  final path = '/onetimeproducts/${item.productId}';\n  final existing = await api.getJson(path);"
new = "  final getPath = '/oneTimeProducts/${item.productId}';\n  final patchPath = '/onetimeproducts/${item.productId}';\n  final existing = await api.getJson(getPath);"
if old not in s:
    raise SystemExit("sync pattern not found")
s = s.replace(old, new)
s = s.replace("await patchWithRegionsRetry(api, path, body: body, updateMask: 'purchaseOptions'", "await patchWithRegionsRetry(api, patchPath, body: body, updateMask: 'purchaseOptions'")
sync.write_text(s, encoding="utf-8")
print("ok")