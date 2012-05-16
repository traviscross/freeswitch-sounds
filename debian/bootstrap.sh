#!/bin/bash
##### -*- mode:shell-script; indent-tabs-mode:nil; sh-basic-offset:2 -*-
##### Author: Travis Cross <tc@traviscross.com>

base="freeswitch-sounds"
sound="en-us-callie"
path="en/us/callie"
sound_name="US English Callie"
rates="8k:8000 16k:16000 32k:32000 48k:48000"
rates_names=$(echo "$rates" | sed -e 's/:[^ ]*//g')
rates_hz=$(echo "$rates" | sed -e 's/[^ ]*://g')

#### lib

ddir="."
[ -n "${0%/*}" ] && ddir="${0%/*}"
cd $ddir

err () {
  echo "$0 error: $1" >&2
  exit 1
}

xread () {
  local xIFS="$IFS"
  IFS=''
  read $@
  local ret=$?
  IFS="$xIFS"
  return $ret
}

wrap () {
  local fl=true
  echo "$1" | fold -s -w 69 | while xread l; do
    local v="$(echo "$l" | sed -e 's/ *$//g')"
    if $fl; then
      fl=false
      echo "$v"
    else
      echo " $v"
    fi
  done
}

fmt_edit_warning () {
  echo "#### Do not edit!  This file is auto-generated from debian/bootstrap.sh."; echo
}

#### control

list_pkgs () {
  local pkgs=""
  for x in $rates_names; do
    pkgs="$pkgs $base-$sound-$x"
  done
  echo "${pkgs:1}"
}

fmt_depends () {
  local deps=""
  for x in $(list_pkgs); do
    deps="$deps | $x (= \${binary:Version})"
  done
  echo "${deps:3}"
}

fmt_recommends () {
  local recs=""
  for x in $(list_pkgs); do
    recs="$recs, $x (= \${binary:Version})"
  done
  echo "${recs:2}"
}

fmt_provides () {
  local pvds="$base" tmp="${sound%-*}" tb="$base"
  for x in ${tmp//-/ }; do
    tb="$tb-$x"
    pvds="$pvds, $tb"
  done
  echo "$pvds"
}

fmt_provides_full () {
  local pvds="$base" tb="$base"
  for x in ${sound//-/ }; do
    tb="$tb-$x"
    pvds="$pvds, $tb"
  done
  echo "$pvds"
}

fmt_control () {
  fmt_edit_warning
  cat <<EOF
Source: freeswitch-sounds-$sound
Section: comm
Priority: optional
Maintainer: Travis Cross <tc@traviscross.com>
Build-Depends: debhelper (>= 8.0.0)
Standards-Version: 3.9.3
Homepage: http://files.freeswitch.org/

Package: $base-$sound
$(wrap "Provides: $(fmt_provides)")
Architecture: all
Depends: \${misc:Depends},
 $(wrap "$(fmt_depends)")
Recommends:
 $(wrap "$(fmt_recommends)")
Description: $sound_name sounds for FreeSWITCH
 $(wrap "This is a metapackage which depends on the $sound_name sound packages for FreeSWITCH at various sampling rates.")

EOF
 for x in $(list_pkgs); do fmt_pkg_control "$x"; done
}

fmt_pkg_control () {
  local pkg="$1"
  local rate="${1##*-}"
  cat <<EOF
Package: $pkg
$(wrap "Provides: $(fmt_provides_full)")
Architecture: all
Depends: \${misc:Depends}
Description: ${sound_name} sounds for FreeSWITCH at ${rate}Hz
 $(wrap "This package contains the ${sound_name} sounds for FreeSWITCH at a sampling rate of ${rate}Hz.")

EOF
}

gen_control () {
  fmt_control > control
}

#### install

fmt_pkg_install () {
  local rate="$1"
  fmt_edit_warning
  cat <<EOF
/usr/share/freeswitch/sounds/${path}/*/${rate}
EOF
}

gen_install () {
  for x in $rates; do
    local n="${x%%:*}" r="${x##*:}"
    fmt_pkg_install $r > $base-$sound-$n.install
  done
}

#### overrides

fmt_itp_override () {
  local p="$1"
  cat <<EOF
# We're not in Debian (yet) so we don't have an ITP bug to close.
${p}: new-package-should-close-itp-bug

EOF
}

fmt_long_filename_override () {
  local p="$1"
  cat <<EOF
# The long file names are caused by appending the nightly information.
# Since one of these packages will never end up on a Debian CD, the
# related problems with long file names will never come up here.
${p}: package-has-long-file-name *

EOF
}

fmt_pkg_overrides () {
  fmt_edit_warning
  fmt_itp_override "$@"
  fmt_long_filename_override "$@"
}

gen_overrides () {
  for x in $(list_pkgs); do
    fmt_pkg_overrides "$x" > $x.lintian-overrides
  done
}

gen_control
gen_install
gen_overrides

