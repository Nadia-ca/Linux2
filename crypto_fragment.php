<?php

if ($argc != 3) {

    die("Usage: php decrypt.php <ciphertext> <password>\n");

}


$ciphertext = $argv[1];

$password = $argv[2];


function decrypt($ivHashCiphertext, $password, $ignore_error = false) {

    $data = base64_decode($ivHashCiphertext, TRUE);

    if ($data === FALSE) {

        die("Unable to understand data\n");

    }

    $method = "AES-256-CBC";

    $iv = substr($data, 0, 16);

    $hash = substr($data, 16, 32);

    $ciphertext = substr($data, 48);

    $key = hash('sha256', $password, true);


    if (hash_hmac('sha256', $ciphertext, $key, true) !== $hash) {

        if ($ignore_error) {

            return "";

        } else {

            die("Unable to decrypt\n");

        }

    }


    $plaintext = openssl_decrypt($ciphertext, $method, $key, OPENSSL_RAW_DATA, $iv);

    if ($plaintext === FALSE) {

        die("Decryption failed\n");

    }

    return $plaintext;

}


$plaintext = decrypt($ciphertext, $password);

echo $plaintext;

?>
