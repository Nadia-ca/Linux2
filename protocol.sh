

#!/bin/bash


WEBSERVICE_TO_HACK="http://10.0.0.5/complekeiv/DaeQZSBi"
KES="6475516334529504366275482415145716744572"


# ---------------------------------------------------------------------


function sanitise_b64() {

  echo ${1//+/%2b}

}


function desanitise_b64() {

  echo ${1//%2b/+}

}


# ---------------------------------------------------------------------


function get_b64_output() {

  echo $1 | cut -d ':' -f 2 | awk '{print $1}'

}


# ---------------------------------------------------------------------


function injectB() {

  DATA=$(echo $1 | sed 's/<br>/,/g')    

  PAYLOAD="$(echo $DATA | cut -d',' -f1)"

  BPAYLOAD=$(get_b64_output "$PAYLOAD")

  

  echo $(sanitise_b64 "$BPAYLOAD")

}


function injectBF() {

  PAYLOAD=$(get_b64_output "$1")

  echo $(sanitise_b64 "$PAYLOAD")

}


function injectA() {

  DATA=$(echo $1 | sed 's/<br>/,/g')    

  PAYLOAD="$(echo $DATA | cut -d',' -f2)"

  BPAYLOAD=$(get_b64_output "$PAYLOAD")

  

  echo $(sanitise_b64 "$BPAYLOAD")

}


function injectS() {

  PAYLOAD=$(get_b64_output "$1")

  echo $(sanitise_b64 "$PAYLOAD")

}


# ---------------------------------------------------------------------


function protocol() {

  # Run the protocol

  step1=$(wget -q -O - "$WEBSERVICE_TO_HACK/A.php?step=1")

  echo "$step1"


  step2=$(wget -q -O - "$WEBSERVICE_TO_HACK/S.php?step=2&data=$(injectS "QSxF")")

  echo "$step2"


  # Extract S -> B and S -> A from step2

  DATA=$(echo "$step2" | sed 's/<br>/,/g')

  S_B_MESSAGE=$(echo "$DATA" | cut -d',' -f1)

  S_A_MESSAGE=$(echo "$DATA" | cut -d',' -f2)


  # Extract base64 payload from S -> B

  S_B_PAYLOAD=$(get_b64_output "$S_B_MESSAGE")

  S_B_PAYLOAD=$(desanitise_b64 "$S_B_PAYLOAD")


  # Decrypt S -> B using KES

  DECRYPTED_KEY=$(php decrypt.php "$S_B_PAYLOAD" "$KES")


  if [ -z "$DECRYPTED_KEY" ]; then

    echo "Failed to decrypt S -> B message."

    exit 1

  fi


  echo "Decrypted S -> B: $DECRYPTED_KEY"


  # Continue protocol execution

  URL="$WEBSERVICE_TO_HACK/B.php?step=3&data=$(injectB "$step2")"

  step3=$(wget -q -O - --keep-session-cookies --save-cookies cookies.txt $URL)

  echo "$step3"


  URL="$WEBSERVICE_TO_HACK/A.php?step=4&data=$(injectA "$step2")"

  step4=$(wget -q -O - $URL)

  echo "$step4"


  # Extract A -> B message from step4

  A_B_MESSAGE=$(echo "$step4" | grep "A -> B:")


  # Extract base64 payload from A -> B

  A_B_PAYLOAD=$(get_b64_output "$A_B_MESSAGE")

  A_B_PAYLOAD=$(desanitise_b64 "$A_B_PAYLOAD")


  # Decrypt A -> B using the decrypted key from S -> B

  PLAINTEXT=$(php decrypt.php "$A_B_PAYLOAD" "$DECRYPTED_KEY")


  if [ -z "$PLAINTEXT" ]; then

    echo "Failed to decrypt A -> B message."

    exit 1

  fi


  echo "Decrypted A -> B: $PLAINTEXT"


  # Final step

  URL="$WEBSERVICE_TO_HACK/B.php?step=5&data=$(injectBF "$step4")"

  printf "\n$(wget -q -O -  --load-cookies cookies.txt $URL)\n"

}


# ---------------------------------------------------------------------


# Run the protocol

protocol



