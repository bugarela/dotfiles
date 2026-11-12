import test from "node:test";
import assert from "node:assert/strict";
import { emacsArgs, parsePath } from "../emacs.js";

test("local files open in a local GUI frame, with daemon fallback", () => {
  assert.deepEqual(emacsArgs("/home/gabriela/org/work.org", null),
    ["-n", "-c", "-a", "", "--", "/home/gabriela/org/work.org"]);
});
test("desktop machine names use the SSH alias, not a fixed LAN address", () => {
  for (const machine of ["desktop", "gabriela-nixos", "herdr-desktop"]) {
    assert.equal(emacsArgs("/home/gabriela/org/work.org", machine).at(-1),
      "/ssh:herdr-desktop:/home/gabriela/org/work.org");
  }
});
test("spaces, quotes and shell characters remain one literal argument", () => {
  const path = '/home/gabriela/org/work notes "$(touch nope)".org';
  assert.equal(emacsArgs(path, "desktop").at(-1), `/ssh:herdr-desktop:${path}`);
});
test("other machines can use their SSH host alias", () => {
  assert.equal(emacsArgs("/work.org", "work-server").at(-1), "/ssh:work-server:/work.org");
});
test("reject ambiguous hosts and invalid paths", () => {
  for (const host of ["user@host", "host:22", "host|sudo:root@host", "bad host"]) {
    assert.throws(() => emacsArgs("/work.org", host));
  }
  for (const path of ["relative.org", "/bad\0.org", "/bad\n.org"]) {
    assert.throws(() => emacsArgs(path, "desktop"));
  }
});
test("line and column go before the file", () => {
  assert.deepEqual(emacsArgs("/a.org", "desktop", 12, 3).slice(-2), ["+12:3", "/ssh:herdr-desktop:/a.org"]);
  assert.deepEqual(emacsArgs("/a.org", null, 12).slice(-2), ["+12", "/a.org"]);
});
test("pasted text becomes an absolute path with an optional position", () => {
  const ctx = { cwd: "/home/gabriela/quint", home: "/home/gabriela" };
  assert.deepEqual(parsePath("  '/x/areas explained.org'\n", ctx), { path: "/x/areas explained.org", line: null, col: null });
  assert.deepEqual(parsePath("src/main.rs:42:7:", ctx), { path: "/home/gabriela/quint/src/main.rs", line: 42, col: 7 });
  assert.deepEqual(parsePath("~/org/bell.org:3", ctx), { path: "/home/gabriela/org/bell.org", line: 3, col: null });
  assert.equal(parsePath("file:///tmp/a%20b.org", ctx).path, "/tmp/a b.org");
  assert.equal(parsePath("rel.org", { cwd: null, home: "/h" }).path, "rel.org");
});
