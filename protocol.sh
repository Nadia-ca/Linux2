# Copyright (C) 2019  Roberto Metere and Peter Carmichael, Newcastle Upon Tyne, UK
# Copyright (C) 2021  Charles Morisset, Newcastle Upon Tyne, UK
# All rights reserved.
#
# Redistribution and use of this script, with or without modification, is
# permitted provided that the following conditions are met:
#
# 1. Redistributions of this script must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
#  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
#  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
#  EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
#  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
#  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
#  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
#  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
#  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# DESCRIPTION
#
# This web service implements the following protocol
#
#   A -> S: A,B
#   S -> A: {#K,{K}KBS}KAS
#   A -> B: {K}KBS,{#s}K
#

WEBSERVICE_TO_HACK="http://10.0.0.5/compleke/bxL9yvDn"

# You have the following key KES with the server
KES="1788279208104052375212791311701435195696"
# ---------------------------------------------------------------------

function sanitise_b64() {
  echo ${1//+/%2b}
}
# ---------------------------------------------------------------------

function get_b64_output() {
  echo $1 | cut -d ':' -f 2 | awk '{print $1}'
}
# ---------------------------------------------------------------------

function injectB() {
  PAYLOAD=$(get_b64_output "$1")
  
  # ----------------------------------------------------------
  # Manipulation of the payload to send to S in the first step
  # ----------------------------------------------------------
  
  # We need to sanitise the "+" of base64 before sending it
  echo $(sanitise_b64 "$PAYLOAD")
}
# ---------------------------------------------------------------------

function injectA() {
  PAYLOAD=$(get_b64_output "$1")
  
  # -----------------------------------------------------------
  # Manipulation of the payload to send to A in the second step
  # -----------------------------------------------------------
  
  # We need to sanitise the "+" of base64 before sending it
  echo $(sanitise_b64 "$PAYLOAD")
}
# ---------------------------------------------------------------------

function protocol() {
  # Run the protocol
  step1=$(wget -q -O - "$WEBSERVICE_TO_HACK/A.php?step=1")
  echo "$step1"
  step2=$(wget -q -O - "$WEBSERVICE_TO_HACK/S.php?step=2&data=$(injectB "$step1")")
  echo "$step2"
  step3=$(wget -q -O - "$WEBSERVICE_TO_HACK/A.php?step=3&data=$(injectA "$step2")")
  echo "$step3"
  printf "\n$(wget -q -O - "$WEBSERVICE_TO_HACK/B.php?step=4&data=$(injectB "$step3")")\n"
}
# ---------------------------------------------------------------------

# Run the protocol
protocol

