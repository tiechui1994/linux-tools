#!/usr/bin/env bash

sshd_pam() {
    lines=($(grep -n -o -E '^account' /tmp/sshd | grep -o -E '^[[:digit:]]+'))
    declare -i lineno=0
    if [[ ${#lines} -gt 0 ]]; then
        lineno=${lines[-1]}
        lineno+=1
    fi

    echo "lineo $lineno"
    content="auth required pam_google_authenticator.so nullok"

    awk -v content="$content" -v lineno=${lineno} '
    {
       if ( NR == lineno ) {
          print($0)
          print("# Google code")
          print(content)
          print("")
       } else if ( /@include common-auth/ ) {
          print("#", $0)
       } else {
          print($0)
       }
    }' /tmp/sshd > /tmp/sshx
}

sshd_config() {
    awk -v challege=0 -v usepam=0 -v methods=0 '
    {
       if ( /^[#]?[\s]*ChallengeResponseAuthentication/ ) {
          print("ChallengeResponseAuthentication yes")
          challege=1
       } else if ( /^[#]?[\s]*UsePAM/ ) {
          print("UsePAM yes")
          usepam=1
       } else if ( /^[#]?[\s]*AuthenticationMethods/ ) {
          print("AuthenticationMethods publickey,keyboard-interactive")
          methods=1
       } else {
          print($0)
       }
    };
    END {
        print(challege, usepam, methods)
        if ( challege==0 ) {
            print("ChallengeResponseAuthentication yes")
        }
        if ( usepam==0 ) {
            print("UsePAM yes")
        }
        if ( methods==0 ) {
            print("AuthenticationMethods publickey,keyboard-interactive")
        }
    }' /tmp/sshd_config
}

sshd_config