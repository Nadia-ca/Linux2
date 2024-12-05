

#!/bin/bash


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

  step2=$(wget -q -O - "$WEBSERVICE_TO_HACK/S.php?step=2&data=$(injectB "QSxF")")

  echo "$step2"

  step3=$(wget -q -O - "$WEBSERVICE_TO_HACK/A.php?step=3&data=$(injectA "$step2")")

  echo "$step3"

  

  # Process the output of A -> B (step 3)

  process_step3 "$step3"

  

  printf "\n$(wget -q -O - "$WEBSERVICE_TO_HACK/B.php?step=4&data=$(injectB "$step3")")\n"

}

# ---------------------------------------------------------------------


function process_step3() {

  step3_output="$1"

  

  # Extract the base64-encoded payload from step3

  payload=$(get_b64_output "$step3_output" | tr -d '\r\n')

  

  # Decode the payload

  decoded_payload=$(echo "$payload" | base64 -d)

  

  # Split the decoded payload into m1 and m2

  IFS=',' read -r m1 m2 <<< "$decoded_payload"

  

  # Decode m1 and m2 from base64

  decoded_m1=$(echo "$m1" | base64 -d)

  decoded_m2=$(echo "$m2" | base64 -d)

  

  # Create temporary files to handle binary data

  tmp_m1_enc=$(mktemp)

  tmp_m2_enc=$(mktemp)

  tmp_m1_dec=$(mktemp)

  tmp_m2_dec=$(mktemp)

  

  # Write decoded_m1 and decoded_m2 to temporary files

  echo -n "$decoded_m1" > "$tmp_m1_enc"

  echo -n "$decoded_m2" > "$tmp_m2_enc"

  

  # Decrypt m1 with KES using PBKDF2

  openssl enc -d -aes-256-cbc -pbkdf2 -in "$tmp_m1_enc" -out "$tmp_m1_dec" -pass pass:"$KES" 2>/dev/null

  

  # Read the decrypted key from m1

  key_m1=$(cat "$tmp_m1_dec")

  

  # Decrypt m2 with the key obtained from decrypted m1

  openssl enc -d -aes-256-cbc -pbkdf2 -in "$tmp_m2_enc" -out "$tmp_m2_dec" -pass pass:"$key_m1" 2>/dev/null

  

  # Read the final decrypted message from m2

  decrypted_m2=$(cat "$tmp_m2_dec")

  

  # Output the decrypted messages

  echo "Decrypted m1: $key_m1"

  echo "Decrypted m2: $decrypted_m2"

  

  # Clean up temporary files

  rm -f "$tmp_m1_enc" "$tmp_m2_enc" "$tmp_m1_dec" "$tmp_m2_dec"

}

# ---------------------------------------------------------------------


# Run the protocol

protocol
