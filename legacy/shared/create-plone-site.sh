#!/bin/sh
# Create a Plone site on a RUNNING instance, whatever the era.
#
# Usage: create-plone-site.sh <base-url> [site-id] [user] [password]
#   e.g. create-plone-site.sh http://localhost:8080 Plone admin admin
#
# Two callers, one implementation:
#   shared/smoke-test.sh   — the CI gate's optional site-creation stretch
#   shared/seed-demo-site.sh — the build step behind the -demo images
# They must not drift: a demo image whose site was made differently from the
# one the gate exercises would be tested by proxy and not in fact.
#
# Everything here is DISCOVERED from the live ZMI, never recalled — none of
# these names is stable across the series.
set -eu

BASE_URL="${1:?usage: create-plone-site.sh <base-url> [site-id] [user] [password]}"
SITE_ID="${2:-Plone}"
ADMIN_USER="${3:-admin}"
ADMIN_PASS="${4:-admin}"

AUTH="${ADMIN_USER}:${ADMIN_PASS}"
BASE="${BASE_URL}/manage_addProduct/CMFPlone"

# [V 2026-08-20] Plone 4 changed BOTH steps again:
#   1.0      /manage_main links CMFPlone/addSite            -> manage_addSite
#   2.0/2.1  /manage_main links CMFPlone/addSite            -> manage_addSite
#   2.5-3.3  /manage_main links CMFPlone/addPloneSiteForm   -> addPloneSite
#   4.0+     /manage_main offers CMFPlone/zmi_constructor as a <select>
#            OPTION (not a link), which redirects to @@plone-addsite
# so the pattern must allow zmi_constructor, and the page must be fetched
# with -L because 4.x redirects before showing the form.
FORM_NAME="${SMOKE_SITE_FACTORY:-}"
if [ -z "${FORM_NAME}" ]; then
    FORM_NAME=$(curl -sf -u "${AUTH}" "${BASE_URL}/manage_main" |
        grep -oE 'manage_addProduct/CMFPlone/(add[A-Za-z]*|zmi_constructor)' |
        sed 's|.*/||' | sort -u | head -1)
fi
if [ -z "${FORM_NAME}" ]; then
    echo "FAIL: no CMFPlone site factory linked from /manage_main" >&2
    exit 1
fi

ADD_FORM=$(curl -sfL -u "${AUTH}" "${BASE}/${FORM_NAME}") || ADD_FORM=""
FACTORY=$(printf '%s' "${ADD_FORM}" |
    grep -oE '<form[^>]*action="[^"]*"' |
    sed -E 's|.*action="([^"]*)".*|\1|' | head -1)
if [ -z "${FACTORY}" ]; then
    echo "FAIL: could not read the form action from ${FORM_NAME}" >&2
    exit 1
fi
echo "discovered site factory: ${FORM_NAME} -> ${FACTORY}"

# [V 2026-08-20] Plone 1.0.6 needs `custom_policy`, and 2.x does not.
# Its ZMI factory defaults the argument to '' —
#   CMFPlone/Portal.py:289  custom_policy='',
# and CustomizationPolicy.py is what calls _setProperty('left_slots', ...),
# so a site created without it is accepted (the POST still 302s) and then
# 500s on every render with `AttributeError: left_slots`. Plone 2.0.5 and
# 2.1.4 take the same argument but default it to 'Default Plone', which is
# why they never needed it here. Rather than branch on a version, discover
# whether the add-form offers the control; 'Default Plone' is the label
# registered by CustomizationPolicy.py:12 in both eras.
HAS_POLICY=$(printf '%s' "${ADD_FORM}" | grep -c 'name="custom_policy"' || true)

# The form action is relative pre-4 and absolute in 4.x.
case "${FACTORY}" in
    http*) POST_URL="${FACTORY}" ;;
    *)     POST_URL="${BASE}/${FACTORY}" ;;
esac

echo "creating Plone site '${SITE_ID}'..."

# The field names differ across the same boundary, and posting the wrong set
# is not harmless: Zope maps form fields onto the constructor's arguments, so
# an unexpected one raises TypeError rather than being ignored. Branch on the
# discovered action rather than on a version number.
#
# Zope answers a successful create with a 302 back to the ZMI.
POST_OK=0
if expr "${FACTORY}" : '.*plone-addsite' > /dev/null; then
    # [V 2026-08-21] @@plone-addsite installs the GenericSetup extension
    # profiles named by `extension_ids:list`, and the ones every site is meant
    # to get are carried as *hidden* inputs which the browser posts back
    # without the operator ever seeing them. In 4.0, 4.1 and 4.2 those are
    # plonetheme.classic:default and plonetheme.sunburst:default. Posting the
    # form without them is accepted — the create still 302s — and produces a
    # site with neither theme installed: portal_skins stays on the bare
    # "Plone Default" skin and Sunburst, the default look of Plone 4, never
    # appears. Discover them from the form rather than naming them here, so a
    # version forcing a different set is followed rather than second-guessed.
    #
    # Document order is preserved (awk, not `sort -u`): the profiles are
    # applied in the order posted and the last one to set a default skin wins,
    # which is how Sunburst beats Classic in the browser.
    FORCED_PROFILES=$(printf '%s' "${ADD_FORM}" |
        grep -oE '<input[^>]*>' |
        grep 'name="extension_ids:list"' |
        grep 'type="hidden"' |
        sed -E 's|.*value="([^"]*)".*|\1|' |
        awk '!seen[$0]++')

    set -- \
        --data-urlencode "site_id=${SITE_ID}" \
        --data-urlencode "title=${SITE_TITLE:-Smoke Test Site}" \
        --data-urlencode "default_language=en" \
        --data-urlencode "form.submitted:boolean=1" \
        --data-urlencode "setup_content:boolean=1"
    for PROFILE in ${FORCED_PROFILES}; do
        echo "add-form forces extension profile: ${PROFILE}"
        set -- "$@" --data-urlencode "extension_ids:list=${PROFILE}"
    done

    curl -sf -o /dev/null -u "${AUTH}" -X POST "${POST_URL}" "$@" || POST_OK=1
elif [ "${HAS_POLICY}" -gt 0 ]; then
    echo "add-form offers custom_policy; posting 'Default Plone'"
    curl -sf -o /dev/null -u "${AUTH}" -X POST "${POST_URL}" \
        --data-urlencode "id=${SITE_ID}" \
        --data-urlencode "title=${SITE_TITLE:-Smoke Test Site}" \
        --data-urlencode "create_userfolder=1" \
        --data-urlencode "custom_policy=Default Plone" || POST_OK=1
else
    curl -sf -o /dev/null -u "${AUTH}" -X POST "${POST_URL}" \
        --data-urlencode "id=${SITE_ID}" \
        --data-urlencode "title=${SITE_TITLE:-Smoke Test Site}" \
        --data-urlencode "create_userfolder=1" || POST_OK=1
fi
if [ "${POST_OK}" -ne 0 ]; then
    echo "FAIL: site creation POST was rejected (${POST_URL})" >&2
    exit 1
fi
echo "OK: site creation accepted"

SITE_HTML=$(curl -sf "${BASE_URL}/${SITE_ID}") || {
    echo "FAIL: created site does not render" >&2
    exit 1
}

# Assert it is really Plone, not a Zope error page that happens to be 200.
#
# [V 2026-08-20] The generator meta tag is the strongest marker and every
# version from 2.0 up emits it — but Plone 1.0.6 predates it entirely. Its
# only <meta> is `imagetoolbar`. So fall back to two skin-level markers it
# does emit, `plone_javascripts` and the `plone.css` @import; a Zope error
# page carries neither, so the gate keeps its meaning. Which marker matched
# is printed, so a version silently losing its generator tag is visible in
# the log rather than quietly downgraded.
if printf '%s' "${SITE_HTML}" | grep -q 'name="generator" content="Plone'; then
    SITE_MARKER="generator meta tag"
elif printf '%s' "${SITE_HTML}" | grep -qE 'plone_javascripts|plone\.css'; then
    SITE_MARKER="plone_javascripts/plone.css (pre-2.0: no generator tag)"
else
    echo "FAIL: site root carries no Plone marker at all" >&2
    printf '%s' "${SITE_HTML}" | head -c 400 >&2
    exit 1
fi
echo "OK: site root renders Plone markup via ${SITE_MARKER} ($(printf '%s' "${SITE_HTML}" | wc -c) bytes)"

# [V 2026-08-21] The failure this guards against was silent: a site created
# without the add-form's forced `extension_ids` is a perfectly renderable
# Plone site — every marker above still matches — that simply has no theme.
# So when the form forced a plonetheme profile, assert the theme actually
# landed. `Plone Default` is the bare CMFPlone skin left behind when neither
# plonetheme.classic nor plonetheme.sunburst was installed; a themed 4.x site
# reads `Sunburst Theme`. Derived from what the form forced, not from a
# version number, so pre-4 versions skip this entirely.
#
# The subject is the ADD-FORM, not the profiles we managed to discover in it:
# the regression being guarded against IS a discovery that finds nothing, and
# a guard keyed on `${FORCED_PROFILES}` would go quiet in exactly that case.
# Verified by mutation — neutering the discovery must turn this red.
#
# [V 2026-10-08] Plone 5 forces plonetheme.barceloneta:default, which is a
# Diazo theme rather than a skin: portal_skins/manage_propertiesForm has no
# selected option at all there, so the skin check reads nothing and fails a
# correctly themed site. The theme's resources are served under
# ++theme++barceloneta, so look for that in the rendered page instead.
case "${ADD_FORM:-}" in
    *plonetheme.barceloneta*)
        if ! printf '%s' "${SITE_HTML}" | grep -q '++theme++barceloneta'; then
            echo "FAIL: the add-form forced plonetheme.barceloneta, but the site" >&2
            echo "      does not render through ++theme++barceloneta — the theme" >&2
            echo "      profile was not applied" >&2
            exit 1
        fi
        echo "OK: theme profiles applied — site renders through ++theme++barceloneta"
        ;;
    *plonetheme.*)
        DEFAULT_SKIN=$(curl -sf -u "${AUTH}" \
            "${BASE_URL}/${SITE_ID}/portal_skins/manage_propertiesForm" |
            grep -oE 'option value="[^"]*" selected' |
            sed -E 's|option value="([^"]*)".*|\1|' | head -1)
        if [ -z "${DEFAULT_SKIN}" ] || [ "${DEFAULT_SKIN}" = "Plone Default" ]; then
            echo "FAIL: the add-form forced a plonetheme profile, but the site's" >&2
            echo "      default skin is '${DEFAULT_SKIN:-<unreadable>}' — the theme" >&2
            echo "      profiles were not applied" >&2
            exit 1
        fi
        echo "OK: theme profiles applied — default skin is '${DEFAULT_SKIN}'"
        ;;
esac
