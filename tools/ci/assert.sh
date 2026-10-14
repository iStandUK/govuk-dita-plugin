# Negative assertions for the run: blocks of .github/workflows/build.yml,
# sourced by each step that needs them:
#
#   . "$GITHUB_WORKSPACE/tools/ci/assert.sh"
#
# bash -e ignores a command whose status is inverted with "!", so a plain
# "! grep" can never fail a step (#209); negative checks go through this.

# absent GREP-ARGS...: grep must find no match. A missing or unreadable file
# fails the step too, because grep's status 2 would otherwise read as "no
# match" and pass a check against output that was never written.
absent() {
  local rc=0
  grep "$@" || rc=$?
  case $rc in
    0) echo "unexpected match: $*"; exit 1 ;;
    1) ;;
    *) echo "grep failed (status $rc): $*"; exit 1 ;;
  esac
}
