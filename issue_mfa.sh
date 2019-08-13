#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

USAGE=$(cat <<-END
source ./issue_mfa.sh [AWS_USERNAME] [MFA_TOKEN]
   Issues an aws security token and sets it automatically.
   If added the -v flag it will echos AWS_SECRET_ACCESS_KEY,
   AWS_ACCESS_KEY_ID, AWS_SECURITY_TOKEN, and AWS_SESSION_TOKEN
   as exports you can set in your shell.
   AWS_USERNAME is case-sensitive.
END
)

# safety check for source
# https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "${bold}ERROR:${normal} Check that you are properly sourcing the script"
    echo
    echo "This script should be run as:"
    echo "$ ${bold}source${normal} ./issue_mfa.sh [AWS_USERNAME] [MFA_TOKEN] "
    exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
    echo 'Error: jq is not installed.' >&2
    echo 'Try: brew install jq' >&2
    return 1
fi

if ! [ -x "$(command -v aws)" ]; then
    echo 'Error: aws-cli is not installed.' >&2
    echo 'Try: brew install awscli' >&2
    return 1
fi

if [[ $1 == "-h" ]]; then
    echo "$USAGE"
    return 0
fi

if [[ $# -ne 2 && $# -ne 3 ]]; then
    echo "$USAGE" >&2
    return 1
fi

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SECURITY_TOKEN
unset AWS_SESSION_TOKEN

aws_out="$(aws sts get-session-token --output json --serial-number arn:aws-us-gov:iam::008577686731:mfa/$1 --token-code $2)"

if [ $? -ne 0 ]; then
    echo -e "${bold}ERROR:${normal} Could not set AWS Sessions. Read error above..."

else
    aws_id=$(echo $aws_out | jq -r .Credentials.AccessKeyId)
    aws_secret=$(echo $aws_out | jq -r .Credentials.SecretAccessKey)
    aws_session=$(echo $aws_out | jq -r .Credentials.SessionToken)

    export AWS_ACCESS_KEY_ID=$aws_id
    export AWS_SECRET_ACCESS_KEY=$aws_secret
    export AWS_SECURITY_TOKEN=$aws_session
    export AWS_SESSION_TOKEN=$aws_session

    echo "${bold}AWS Session credentials saved. Will expire in 12 hours${normal}"

    if [[ $3 == "-v" ]]; then
        echo " export AWS_ACCESS_KEY_ID=$aws_id"
        echo " export AWS_SECRET_ACCESS_KEY=$aws_secret"
        echo " export AWS_SECURITY_TOKEN=$aws_session"
        echo " export AWS_SESSION_TOKEN=$aws_session"
    fi
fi

