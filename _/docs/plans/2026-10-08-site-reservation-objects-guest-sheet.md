# Site reservation objects and guest sheet

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Merchants generate named reservation units from the product editor and the Objects tab, and guests book those units from the same sheet on the Flutter preview and the published web page.

**Architecture:** Keep c35 tables and `SiteApi`. Duration and guest-picks stay in `site.product.product_json` (`SiteProductExtras`). Named units are `site.object` rows linked by `product_id`. The guest sheet writes `TxItem.reservations` on the existing guest order. Overlap is checked on put; the unpaid order is the hold. Flutter and `site-guest.v1.js` share one boot JSON contract. Do not port Alpine or CSA `SiteDraft`.

**Tech stack:** Flutter site editor + `guest_site`, Rust `c35_mod_site` / `c35_mod_tx`, static `clients/web/static/site-guest/`, proto `tx.proto` via `._\scripts\protoc.ps1`.

## Global constraints

- Money stays `POST /v1/site/guest-order/put`. No new order table.
- `site_object_id` on `site.tx_item_reservation` is the named unit. Do not reuse `tx_item.obj_id` (that column is `ai.object_normalizer`).
- `0` means system-assigned (no specific unit).
- Half-open window: an existing row overlaps when `start_ts < requested_end AND end_ts > requested_start`.
- Cancelled transactions do not count. State string in SQL is `cancelled`.
- Date picker: `duration_unit` empty or `day` is date-only. `second`, `minute`, `hour`, `week`, `month`, `year` are date plus time.
- Billable quantity = `units * duration_count`. Line total = billable quantity times product price per duration unit.
- Reservation and track-stock are mutually exclusive on the product editor.
- Reservation UI appears only when `SiteEditorCaps.booking` is true.
- Guest copy labels: Mulai, Selesai, Slot Reservasi. Price format stays `Rp` with dot thousands (`formatIdr` already in `site-guest.v1.js`).
- UTF-8 sources. After edits: `._\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.
- Rust builds from `servers/`: `cargo test -p c35_mod_tx` and `cargo test -p c35_mod_site`.
- Dart: `flutter test` on the new test files from `clients/app`.
- Do not commit unless the user asks.
- QR print stays out. Staff calendar assignment stays out. A separate unpaid-hold table stays out.

## File map

| File | Responsibility |
|------|----------------|
| `clients/app/lib/c/site/site_object_batch.dart` | Name prefix + kind/prefix grouping |
| `clients/app/lib/c/site/site_reservation_math.dart` | Shared date math for Flutter |
| `clients/app/lib/widgets/sites/editor/ui_site_product_detail.dart` | Duration, guest-picks, grouped unit tiles |
| `clients/app/lib/widgets/sites/editor/ui_site_objects_editor.dart` | Photo, linked product, add-many, edit dialog |
| `clients/app/lib/widgets/sites/editor/ui_site_object_batch_dialog.dart` | Default 3 digits; kind icons |
| `clients/app/lib/widgets/io/in_site_product.dart` | Reservable-only picker |
| `clients/app/lib/guest_site/guest_site_reservation_sheet.dart` | Guest sheet widget |
| `clients/app/lib/guest_site/guest_site_cart.dart` | Cart lines carry reservation slots |
| `clients/app/lib/guest_site/guest_site_blocks.dart` | Reservable tap opens the sheet |
| `servers/crates/mod_site/src/guest_product.rs` | Boot product fields |
| `servers/crates/mod_site/src/commerce_boot.rs` | `objects[]` when booking is on |
| `servers/crates/mod_site/src/render.rs` | Reserve button instead of the placeholder |
| `servers/crates/mod_site/src/guest_reservation.rs` | Availability query |
| `servers/crates/mod_tx/src/guest_order.rs` | Re-check overlap and set billable qty |
| `servers/crates/wire_http/src/guest_reservation.rs` | `POST /v1/site/guest-reservation/availability` |
| `_/schemas/tx.sql` + `_/schemas/migrations/20261008_tx_item_reservation_object.sql` | `site_object_id` |
| `_/schemas/proto/c35/tx.proto` | `int64 site_object_id = 13` |
| `clients/web/static/site-guest/site-guest.v1.js` + `.css` | Web sheet |
| `_/docs/site-guest-components.md` | Boot fields and sheet rule |

CSA references (read only): `D:\csa_site_published\clients\app\lib\widgets\site\ui_site_products_section.dart` (reservation section ~649–1069), `ui_site_objects_section.dart`, `ui_site_obj_batch_dialog.dart`, `crates/mod_site/src/render/hub.rs` reservation template, `client/site/src/main.ts` `reserve*` methods, `docs/superpowers/specs/2026-07-24-reservation-date-vs-datetime-picker-design.md`.

---

### Task 1: Object grouping helper

**Files:**
- Modify: `clients/app/lib/c/site/site_object_batch.dart`
- Test: `clients/app/test/site_object_batch_test.dart`

**Interfaces:**
- Produces: `siteObjectNamePrefix(String name) -> String`
- Produces: `siteObjectsGroupByKindPrefix(Iterable<SiteObject> objs)` returning a list of records `{String kind, List<({String prefix, List<SiteObject> objs})> prefixes}`
- Kind order: `room`, `table`, `other`, then any other kind. Prefixes sorted alphabetically. Objects keep input order inside a prefix.

- [ ] **Step 1: Write the failing test**

```dart
import 'package:alienai_c35/c/pb/c35/site.pb.dart';
import 'package:alienai_c35/c/site/site_object_batch.dart';
import 'package:flutter_test/flutter_test.dart';

SiteObject obj(String name, String kind) => SiteObject()
  ..name = name
  ..kind = kind;

void main() {
  test('prefix strips a trailing number', () {
    expect(siteObjectNamePrefix('Villa 01'), 'Villa');
    expect(siteObjectNamePrefix('Table-12'), 'Table');
    expect(siteObjectNamePrefix('Lobby'), 'Lobby');
    expect(siteObjectNamePrefix('  '), 'Other');
  });

  test('groups kind then prefix', () {
    final groups = siteObjectsGroupByKindPrefix([
      obj('Villa 2', siteObjectKindRoom),
      obj('Meja 1', siteObjectKindTable),
      obj('Villa 1', siteObjectKindRoom),
    ]);
    expect(groups.map((g) => g.kind).toList(), [siteObjectKindRoom, siteObjectKindTable]);
    expect(groups.first.prefixes.single.prefix, 'Villa');
    expect(groups.first.prefixes.single.objs.map((o) => o.name).toList(), ['Villa 2', 'Villa 1']);
  });
}
```

- [ ] **Step 2: Run** `flutter test test/site_object_batch_test.dart` from `clients/app`. Expected: fail, function missing.
- [ ] **Step 3: Implement** the two functions beside `siteObjectBatchPreview`. Prefix regex: `^(.*?)[\s_-]*\d+\s*$`. Empty trimmed name returns `Other`.
- [ ] **Step 4: Re-run the test.** Expected: pass.
- [ ] **Step 5: UTF-8 check** `._\scripts\dev\check_utf8_sources.ps1 -Changed -Fix`.

### Task 2: Persist the chosen unit

**Files:**
- Modify: `_/schemas/tx.sql` (`site.tx_item_reservation` column list)
- Create: `_/schemas/migrations/20261008_tx_item_reservation_object.sql`
- Modify: `_/schemas/proto/c35/tx.proto` `TxItemReservation`
- Modify: `servers/crates/mod_tx/src/persist.rs`, `load.rs`, `rows.rs`, `tx_json.rs`
- Generated by `._\scripts\protoc.ps1`

**Interfaces:**
- Produces: `TxItemReservation.site_object_id` (`int64`, field 13). `0` = no specific unit.
- JSON key: `site_object_id` on each reservation object in `tx_json.rs` both directions.

- [ ] **Step 1: Schema**

In the `CREATE TABLE site.tx_item_reservation` column list add:

```sql
site_object_id      BIGINT NOT NULL DEFAULT 0,
```

Migration file:

```sql
ALTER TABLE site.tx_item_reservation
    ADD COLUMN IF NOT EXISTS site_object_id BIGINT NOT NULL DEFAULT 0;
```

- [ ] **Step 2: Proto** add `int64 site_object_id = 13;` on `TxItemReservation`. Run `._\scripts\protoc.ps1` from the repo root.
- [ ] **Step 3: Round-trip** INSERT, SELECT, `tx_item_reservation_from_row`, and `tx_item_from_json` / `tx_item_to_json` include `site_object_id`. Missing JSON defaults to `0`.
- [ ] **Step 4: Test** `cargo test -p c35_mod_tx` from `servers/`. Add a unit test that JSON `{"reservations":[{"site_object_id":101,"qty":1}]}` parses `site_object_id == 101` if `tx_item_from_json` is visible; otherwise test through the public JSON helper that already parses items.
- [ ] **Step 5: UTF-8 check** on the edited `.sql`, `.proto`, `.rs`.

### Task 3: Boot contract

**Files:**
- Modify: `servers/crates/mod_site/src/guest_product.rs`
- Modify: `servers/crates/mod_site/src/commerce_boot.rs`
- Test: `servers/crates/mod_site/tests/` or the crate's existing render/guest tests

**Interfaces:**
- `product_row_json` adds: `can_reserve` (bool), `duration_value` (int, default 1), `duration_unit` (string, default `day`), `reservation_unit_selection` (`guest_picks` or `system`).
- Read those three from `site.product.product_json` the same way `clients/app/lib/c/site/site_product_json.dart` does.
- `commerce_boot_build` adds `objects` when `site_capability_enabled(caps, "booking")`:

```json
{ "id": 1, "name": "", "code": "", "pic": "", "kind": "room", "product_id": 1 }
```

Only rows with `deleted_ts IS NULL`, `is_active = TRUE`, `can_be_reserved = TRUE`. `pic` goes through `pic_url`. When booking is off, `objects` is `[]`. Commerce-disabled boot stays `{ "enabled": false }` with no objects key required.

- [ ] **Step 1: Extend** `guest_product_list` / `guest_product_get` SELECT with `can_reserve` and `product_json`.
- [ ] **Step 2: Parse** product_json with `serde_json`. Invalid JSON yields the defaults above.
- [ ] **Step 3: Query objects** in `commerce_boot.rs`.
- [ ] **Step 4: Test** a pure function for product_json parsing (no DB): `{"duration_unit":"hour","reservation_unit_selection":"guest_picks"}` yields hour + guest_picks; `{}` yields day + system + duration 1.
- [ ] **Step 5:** `cargo test -p c35_mod_site` from `servers/`.

### Task 4: Product editor reservation section

**Files:**
- Modify: `clients/app/lib/widgets/sites/editor/ui_site_product_detail.dart`
- Modify: `clients/app/lib/widgets/sites/editor/ui_site_products_editor.dart`
- Modify: `clients/app/lib/widgets/sites/editor/ui_site_editor_shell.dart` (pass `caps.booking`)
- Modify: `clients/app/lib/c/site/site_product_json.dart` only if a writer helper is missing (`siteProductApplyExtras`)

**Depends on:** Task 1.

**Behavior:**
- Pass `booking` into `UiSiteProductsEditor` then `UiSiteProductDetail`.
- Show the Can reserve switch only when `booking` is true. It lives with catalog options today; keep it, hide it when booking is off.
- Enabling Can reserve while Track stock is on turns Track stock off. Enabling Track stock while Can reserve is on turns Can reserve off. Save both through the existing product put.
- When `canReserve` is true, a **Reservation** section shows:
  - Duration value (int, minimum 1) and a dropdown of `second`, `minute`, `hour`, `day`, `week`, `month`, `year`. Writes `duration_value` / `duration_unit` via extras.
  - Switch “Guest picks a unit”. On writes `reservation_unit_selection` = `guest_picks`; off writes `system`.
- **Reservation units** section uses `siteObjectsGroupByKindPrefix` on objects whose `productId` matches this product. Each prefix is an `ExpansionTile` (initially expanded) of 80px tiles: photo (`pic`, else product pic, else kind icon), name under it. Empty state text: `No units linked to this product. Add rooms, tables, or other bookable units.`
- Tile tap opens the object edit dialog from Task 5.
- **Add units** keeps `showSiteObjectBatchDialog`. After it returns a count > 0, reload objects.
- Enabling Can reserve with zero linked objects still shows the existing “Add reservation units?” dialog.

- [ ] **Step 1:** Thread `booking` from `ui_site_editor_shell.dart` (`_caps.booking`) through the products editor into the detail widget. Default the new parameter to `true` so existing call sites compile.
- [ ] **Step 2:** Implement the section. Persist extras by cloning the product, merging `siteProductExtrasToJsonMap` into the existing `productJson` map (do not drop barcodes or gallery pics).
- [ ] **Step 3:** `flutter analyze` on the touched files via `._\scripts\dev\verify_flutter_app.ps1` if the script is the repo check; otherwise `flutter test` for any product json test that already exists (`site_product_parse` tests must still pass).

### Task 5: Object editor parity

**Files:**
- Modify: `clients/app/lib/widgets/sites/editor/ui_site_objects_editor.dart`
- Modify: `clients/app/lib/widgets/sites/editor/ui_site_object_batch_dialog.dart`
- Modify: `clients/app/lib/widgets/io/in_site_product.dart`

**Depends on:** Task 1 for grouping used by the product tiles. This task can ship the dialog the product tiles call.

**Interfaces:**
- Produces: `Future<void> showSiteObjectEditDialog(BuildContext context, {required SiteApi api, required int siteIid, required SiteObject object, required List<SiteProduct> reservableProducts})`
- On save it calls `api.objectPut`. On delete it calls the existing object delete API used by the editor (search `objectDelete` / `objectDel` on `SiteApi` and use that).

**Behavior:**
- List row: 36px photo (`object.pic`, else linked product pic), name, linked product name as subtitle, reservation icon when `canBeReserved`.
- Detail: photo pick through the same `askMedia` + `casUpload` path as `ui_site_product_detail.dart` `_pickPic`. Clear button when `pic` is non-empty. Product dropdown of products with `canReserve`, plus a None option (`productId = 0`). Code shown as a button that copies to the clipboard.
- Toolbar menu: Add (current single create), Add many. Add many opens a reservable-only product picker, then `showSiteObjectBatchDialog`.
- `in_site_product.dart`: add `reservableOnly` (default false). When true, list only `canReserve` products. Empty copy: `No reservable products`.
- Batch dialog: initial digits controller text `'3'`. Kind dropdown items include the same icons as `_objectKindIcon` (room `Icons.meeting_room_outlined` or `Icons.bed_outlined`, table `Icons.table_restaurant_outlined`, other `Icons.category_outlined`). Keep one icon helper and use it from the list, the form, and the dialog.

- [ ] **Step 1:** Extract the detail form so the dialog and the Objects tab both use it.
- [ ] **Step 2:** Wire Add many and the product picker.
- [ ] **Step 3:** `flutter analyze` the touched library files.

### Task 6: Shared duration math

**Files:**
- Create: `clients/app/lib/c/site/site_reservation_math.dart`
- Test: `clients/app/test/site_reservation_math_test.dart`
- Modify: `clients/web/static/site-guest/site-guest.v1.js` (functions only; sheet UI is Task 9)

**Interfaces (Dart and JS, same names and results):**
- `reservationNeedsTime(unit)` — false for `''` and `'day'`; true otherwise.
- `reservationDurationCount(start, end, unit)` — half-open.
  - `day`: whole calendar days between local dates.
  - `hour` / `minute` / `second`: elapsed time divided by that unit, floor, minimum 0.
  - `week`: floor(dayCount / 7).
  - `month` / `year`: calendar difference (year*12+month, or years). A partial month counts as 0 until the end calendar month is reached.
- `reservationBillable(units, durationCount)` — product, 0 if either side is < 1.
- `reservationEndFromDuration(start, unit, count)` — inverse used by the duration stepper. `day` adds calendar days at the same clock time (midnight when date-only).

- [ ] **Step 1: Dart tests**

```dart
test('day range is half-open nights', () {
  final start = DateTime(2026, 1, 1);
  final end = DateTime(2026, 1, 3);
  expect(reservationDurationCount(start: start, end: end, unit: 'day'), 2);
  expect(reservationBillable(units: 2, durationCount: 2), 4);
});

test('hour keeps clock time', () {
  final start = DateTime(2026, 1, 1, 14);
  final end = DateTime(2026, 1, 1, 16);
  expect(reservationNeedsTime('hour'), isTrue);
  expect(reservationNeedsTime('day'), isFalse);
  expect(reservationDurationCount(start: start, end: end, unit: 'hour'), 2);
});
```

- [ ] **Step 2: Implement Dart, then mirror the functions at the top of `site-guest.v1.js`.** JS date-only values are `YYYY-MM-DD` (local midnight). Datetime values are `YYYY-MM-DDTHH:mm` with no timezone suffix.
- [ ] **Step 3:** `flutter test test/site_reservation_math_test.dart`.

### Task 7: Availability and order enforcement

**Files:**
- Create: `servers/crates/mod_site/src/guest_reservation.rs`
- Modify: `servers/crates/mod_site/src/lib.rs` (pub use)
- Create: `servers/crates/wire_http/src/guest_reservation.rs`
- Modify: the wire_http router next to `guest_order.rs` routes
- Modify: `servers/crates/mod_tx/src/guest_order.rs`

**Depends on:** Task 2 (`site_object_id`), Task 3 (product_json fields).

**HTTP:** `POST /v1/site/guest-reservation/availability`

Request JSON:

```json
{ "site_iid": 1, "product_id": 2, "start_ts_ms": 0, "end_ts_ms": 0, "units": 1 }
```

Response JSON:

```json
{
  "ok": true,
  "units_available": 3,
  "free_objects": [{ "id": 101, "name": "Villa Melati", "code": "MELATI", "pic": "" }]
}
```

`ok` is false when `units_available < units`. `free_objects` lists reservable `site.object` rows for that product that have no overlapping reservation with `site_object_id` equal to that object. `units_available` is `linked_object_count - overlapping_qty` where overlapping qty sums `qty` on reservations for that product in the window, excluding txs whose state is `cancelled` and rows with `deleted_ts` set. When the product has zero linked objects, `units_available` is 0 and `ok` is false.

**guest_order_put:**
- If an item has reservations, set `item.qty` to the sum of `qty * duration_qty` (duration_qty minimum 1).
- Require `can_reserve` on the product (select it beside `can_sell`). A reservation on a product with `can_reserve = false` returns an error.
- For each reservation, call the same availability function inside the put path before persist. If `site_object_id > 0`, reject when that id is absent from `free_objects`. If `site_object_id == 0`, reject when `units_available < qty`.
- Price stays the catalog price per duration unit. `guest_item_reprice` must not overwrite a positive client price with a different number; it already fills price only when `item.price <= 0`. Keep that. Set price from the catalog when the client sends 0.

- [ ] **Step 1:** Implement the SQL in `guest_reservation.rs` as `guest_reservation_availability(pool, site_iid, product_id, start, end, units) -> Availability`.
- [ ] **Step 2:** Route the POST handler. No auth cookie beyond whatever `guest-order/put` already requires (match that handler).
- [ ] **Step 3:** Call it from `guest_item_reprice` when `item.reservations` is non-empty.
- [ ] **Step 4:** Unit-test the overlap predicate if extracted as a pure function; DB test only if the crate already has a DB test harness. `cargo test -p c35_mod_site` and `cargo test -p c35_mod_tx`.

### Task 8: Flutter guest sheet

**Files:**
- Create: `clients/app/lib/guest_site/guest_site_reservation_sheet.dart`
- Modify: `clients/app/lib/guest_site/guest_site_cart.dart`
- Modify: `clients/app/lib/guest_site/guest_site_blocks.dart`
- Modify: `clients/app/lib/c/site/guest_order_api.dart` if the put body is built there

**Depends on:** Tasks 6 and 7.

**Cart:**
- Extend `GuestSiteCartLine` with `List<GuestReservationSlot> slots`.
- `GuestReservationSlot`: `start` (`DateTime`), `end`, `units`, `durationQty`, `siteObjectId` (0 if none), `objectName`.
- Reservable lines do not merge by product id with a qty increment. Each confirmed sheet replaces or appends one line keyed by product id plus a slot fingerprint.
- Persist slots in the existing SharedPreferences JSON. Old qty-only maps still load as non-reservable lines.
- On checkout, map each slot to a reservation JSON object: `product_id`, `qty` = units, `duration_qty`, `start_ts_ms`, `end_ts_ms`, `site_object_id`, `state` = `pending`. Item `qty` = sum of billable units.

**Sheet UI** (modal bottom sheet, tall):
- Header: pic, name, billable badge, price label `Rp …` for the whole sheet, subtitle `Rp … / {duration_unit}`.
- Add-slot button. Each slot card: unit stepper, duration stepper, Mulai, Selesai.
- `reservationNeedsTime` false: `showDatePicker` only, store local midnight, display `d MMM`.
- `reservationNeedsTime` true: date then `showTimePicker`, display `d MMM, HH:mm`.
- Changing duration recomputes end via `reservationEndFromDuration`. Changing start keeps the previous duration count and recomputes end.
- When boot product `reservation_unit_selection == guest_picks`, show unit tiles from `commerce_boot.objects` filtered to this `product_id`. Tap toggles `siteObjectId`. Dim tiles that availability says are taken for this slot’s window.
- Call `POST /v1/site/guest-reservation/availability` when a slot’s start, end, or units change (debounce 300ms). Show `Unit left: N`.
- Primary button label: `OK · {slot count} · {price}` when billable > 0, otherwise disabled.
- Confirm closes the sheet and adds the cart line.

**Product grid** (`guest_site_blocks.dart` `_productListRow`): if `can_reserve` is true, `onTap` opens the sheet instead of `cart.addProduct`. Read fields from the product map (`can_reserve`, `duration_unit`, `duration_value`, `reservation_unit_selection`). Objects come from boot `commerce_boot.objects`. Thread that list into the block the same way `productRows` is threaded (search `GuestSiteView` / boot parse and add the list).

- [ ] **Step 1:** Cart model + a widget test that a day product from 1 Jan to 3 Jan with 2 units stores billable qty 4 and one reservation with `duration_qty` 2.
- [ ] **Step 2:** Sheet widget.
- [ ] **Step 3:** Wire the product tap. `flutter test` the new test.

### Task 9: Published web sheet

**Files:**
- Modify: `servers/crates/mod_site/src/render.rs` `product_detail_html_render` and the product card HTML in `site-guest` catalog helper if cards are built in JS (`productCardHtml` in `site-guest.v1.js`)
- Modify: `clients/web/static/site-guest/site-guest.v1.js`
- Modify: `clients/web/static/site-guest/site-guest.v1.css`

**Depends on:** Tasks 3, 6, 7.

**Behavior:** Match the Flutter sheet. No Alpine.
- Replace the placeholder div in `product_detail_html_render` with `<button type="button" class="guest-reserve-btn" data-reserve-product="{pid}">Reservasi</button>`. Keep the existing add-to-cart button for products that are not reservable. Reservable products show Reservasi and do not also show `+ Pesan`.
- `productCardHtml` adds `data-can-reserve="1"` when `item.can_reserve` is true. Click opens the sheet instead of `c35GuestCart.add`.
- Sheet markup is created in JS and appended to `document.body`, class `guest-sheet guest-sheet-tall`, attribute `data-guest="reservation"`.
- Inputs: `type="date"` when `reservationNeedsTime` is false, `type="datetime-local"` otherwise.
- Cart in JS stores `slots` on the line and posts them on guest-order put next to the existing item payload. Find the put body in `site-guest.v1.js` and add `reservations`.
- CSS: sheet scrim, card, steppers, seat tiles. Reuse existing guest colors in `site-guest.v1.css`.

- [ ] **Step 1:** Render test or string assert: a reservable product detail contains `guest-reserve-btn` and does not contain `product-reserve-placeholder`.
- [ ] **Step 2:** JS sheet + cart slots.
- [ ] **Step 3:** `cargo test -p c35_mod_site` for the HTML assert.

### Task 10: Docs

**Files:**
- Modify: `_/docs/site-guest-components.md`

- [ ] Add a chrome row: reservation sheet, `data-guest="reservation"`, Flutter `guest_site_reservation_sheet.dart`, web `site-guest.v1.js`, gate `booking`.
- [ ] Document boot `commerce_boot.products[]` reservation fields and `commerce_boot.objects[]`.
- [ ] Document the date-versus-datetime rule and that overlap is enforced on `guest-order/put`.

## Wave order

```
WAVE 1  Task 1, Task 2, Task 3   (parallel; no shared files)
WAVE 2  Task 4, Task 5, Task 6   (parallel after wave 1; Task 4 and 5 both edit batch dialog — Task 5 owns ui_site_object_batch_dialog.dart, Task 4 must not)
WAVE 3  Task 7                   (after Task 2 and Task 3)
WAVE 4  Task 8, Task 9           (parallel after Task 6 and Task 7)
WAVE 5  Task 10                  (after Task 8 and Task 9)
```

Task 4 must not edit `ui_site_object_batch_dialog.dart`. Task 5 owns that file.

## Done when

- A reservable product in the editor shows duration, guest-picks, grouped photo tiles, and Add units (prefix, start, end, digits, kind).
- Objects tab shows photo, linked product, copyable code, and Add many.
- Flutter preview and published HTML open the same sheet; day products are date-only; hour products keep clock time; 2 units times 2 nights bill as 4.
- Guest-picks sends `site_object_id`. A second order for that unit and window is rejected.
- `cargo test -p c35_mod_site`, `cargo test -p c35_mod_tx`, and the new Flutter tests pass.
