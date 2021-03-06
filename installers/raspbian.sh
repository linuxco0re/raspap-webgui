#!/bin/bash
#
# RaspAP Quick Installer
# Author: @billz <billzimmerman@gmail.com>
# License: GNU General Public License v3.0
#
# Usage:
#
# -y, --yes, --assume-yes
#    Assume "yes" as answer to all prompts and run non-interactively
# c, --cert, --certficate
#    Installs mkcert and generates an SSL certificate for lighttpd
# -o, --openvpn <flag>
#    Used with -y, --yes, sets OpenVPN install option (0=no install)
# -r, --repo, --repository <name>
#    Overrides the default GitHub repo (billz/raspap-webgui)
# -b, --branch <name>
#    Overrides the default git branch (master)
# -h, --help
#    Outputs usage notes and exits
# -v, --version
#    Outputs release info and exits
#
# Depending on options passed to the installer, ONE of the following
# additional shell scripts will be downloaded and sourced:
#
# https://raw.githubusercontent.com/billz/raspap-webgui/master/installers/common.sh
# - or -
# https://raw.githubusercontent.com/billz/raspap-webgui/master/installers/mkcert.sh
#
# You are not obligated to bundle the LICENSE file with your RaspAP projects as long
# as you leave these references intact in the header comments of your source files.

# Set defaults
repo="linuxco0re/raspap-webgui"
branch="master"
assume_yes=0
ovpn_option=1
readonly RASPAP_LATEST=$(curl -s "https://api.github.com/repos/billz/raspap-webgui/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")' )

# Define usage notes
usage=$(cat << EOF
Usage: raspbian.sh [OPTION]\n
-y, --yes, --assume-yes\n\tAssumes "yes" as an answer to all prompts
-c, --cert, --certificate\n\tInstalls an SSL certificate for lighttpd
-o, --openvpn <flag>\n\tUsed with -y, --yes, sets OpenVPN install option (0=no install)
-r, --repo, --repository <name>\n\tOverrides the default GitHub repo (billz/raspap-webgui)
-b, --branch <name>\n\tOverrides the default git branch (master)
-h, --help\n\tOutputs usage notes and exits
-v, --version\n\tOutputs release info and exits\n
EOF
)

# Parse command-line options
while :; do
    case $1 in
        -y|--yes|--assume-yes)
        assume_yes=1
        apt_option="-y"
        ;;
        -o|--openvpn)
        ovpn_option="$2"
        shift
        ;;
        -a|--adblock)
        install_adblock=1
        ;;
        -c|--cert|--certificate)
        install_cert=1
        ;;
        -r|--repo|--repository)
        repo="$2"
        shift
        ;;
        -b|--branch)
        branch="$2"
        shift
        ;;
        -h|--help)
        printf "$usage"
        exit 1
        ;;
        -v|--version)
        printf "RaspAP v${RASPAP_LATEST} - simple AP setup and wifi mangement for the RaspberryPi\n"
        exit 1
	;;
        -*|--*)
        echo "Unknown option: $1"
        printf "$usage"
        exit 1
        ;;
        *)
        break
        ;;
    esac
    shift
done

UPDATE_URL="https://raw.githubusercontent.com/$repo/$branch/"

# Outputs a welcome message
function _display_welcome() {
    raspberry='\033[0;35m'
    green='\033[1;32m'

    echo -e "${raspberry}\n"
    echo -e " 888888ba                              .d888888   888888ba"
    echo -e " 88     8b                            d8     88   88     8b"
    echo -e "a88aaaa8P' .d8888b. .d8888b. 88d888b. 88aaaaa88a a88aaaa8P"
    echo -e " 88    8b. 88    88 Y8ooooo. 88    88 88     88   88"
    echo -e " 88     88 88.  .88       88 88.  .88 88     88   88"
    echo -e " dP     dP  88888P8  88888P  88Y888P  88     88   dP"
    echo -e "                             88"
    echo -e "                             dP       version ${RASPAP_LATEST}"
    echo -e "${green}"
    echo -e "The Quick Installer will guide you through a few easy steps\n\n"
}

# Outputs a RaspAP Install log line
function _install_log() {
    echo -e "\033[1;32mRaspAP Install: $*\033[m"
}

# Outputs a RaspAP Install Error log line and exits with status code 1
function _install_error() {
    echo -e "\033[1;37;41mRaspAP Install Error: $*\033[m"
    exit 1
}

# Outputs a RaspAP Warning line
function _install_warning() {
    echo -e "\033[1;33mWarning: $*\033[m"
}

# Outputs a RaspAP divider
function _install_divider() {
    echo -e "\033[1;32m***************************************************************$*\033[m"
}

function _update_system_packages() {
    _install_log "Updating sources"
    sudo apt-get update || _install_error "Unable to update package list"
}

# Fetch required installer functions
if [ "${install_cert:-}" = 1 ]; then
    source="mkcert"
    wget -q ${UPDATE_URL}installers/${source}.sh -O /tmp/raspap_${source}.sh
    source /tmp/raspap_${source}.sh && rm -f /tmp/raspap_${source}.sh
    _install_certificate || _install_error "Unable to install certificate"
else
    source="common"
    wget -q ${UPDATE_URL}installers/${source}.sh -O /tmp/raspap_${source}.sh
    source /tmp/raspap_${source}.sh && rm -f /tmp/raspap_${source}.sh
    _install_raspap || _install_error "Unable to install RaspAP"
fi

