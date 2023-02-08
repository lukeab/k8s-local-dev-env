#!/bin/sh
case "$OSTYPE" in
  darwin*)
    echo -n "/Library/Keychains/System.keychain"
    echo -e "\nMac not supported yet\n"
    exit 1 ;;
  linux*)
    if command -v update-ca-certificates &>/dev/null; then
      echo -n "/usr/local/share/ca-certificates/"
    elif command -v update-ca-trust &>/dev/null; then
      echo -n "/etc/ca-certificates/trust-source/anchors"
    else
      echo -e "\nUnknown/Unsupported ca trust mechanism\n"
      exit 1
    fi ;;
  *)
    echo -e "\nError; unkown OSTYPE; $OSTYPE\n"
    exit 1 ;;
esac

