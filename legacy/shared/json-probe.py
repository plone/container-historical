# JSON capability probe, run through the image's own script runner:
#   docker run --rm <image> run /json-probe.py
#
# Used by shared/smoke-test.sh. It must be run through `zopectl run` (tarball
# era) or `bin/instance run` (buildout era) rather than the bare interpreter:
# [V 2026-08-27] 3.3 gets simplejson from an EGG in the buildout-cache, which
# only those runners put on sys.path, while 1.0-3.2 get it from site-packages,
# which both see. Probing "$PYTHON" directly would therefore report 3.3 as
# broken while it is in fact fine -- and, worse, would not be testing the way
# anybody actually runs an extraction script.
#
# The runners do NOT reliably propagate a script's exit status (the same reason
# docker-entrypoint*.sh captures output instead of trusting `||`), so success is
# signalled by printing a marker the caller greps for. A traceback prints no
# marker and therefore fails the gate.
try:
    import simplejson as mod
except ImportError:
    # 2.6+ only; every image below 4.0 must satisfy the import above.
    import json as mod

payload = {"b": 2, "a": [1, 2.5, None, True], "s": "plain"}

encoded = mod.dumps(payload, sort_keys=True)
assert encoded.startswith('{"a"'), encoded
assert mod.loads(encoded) == payload, encoded

# Non-ASCII has to survive as unicode: Plone content is full of it, and a
# codec-level break would otherwise only surface on real data.
#
# [V 2026-10-08] The probe also runs on Python 3 (Plone 5.2), where the text
# type is `str` and print is a function. The single-argument print(...) below
# is valid in every Python from 2.3 on.
try:
    text_type = unicode
except NameError:
    text_type = str
text = mod.loads('{"k": "\\u00e7\\u00e3o"}')["k"]
assert isinstance(text, text_type), repr(text)
assert len(text) == 3, repr(text)
assert mod.loads(mod.dumps({"k": text}))["k"] == text, repr(text)

print("JSON-GATE-OK %s %s" % (
    mod.__name__, getattr(mod, "__version__", "stdlib")))
