#!/bin/bash

password=$1
private_key_path=$2

decrypted=$(printf $password | base64 --decode | openssl rsautl -decrypt -inkey $private_key_path)

echo "{\"decrypted_password\": \"$decrypted\"}"
