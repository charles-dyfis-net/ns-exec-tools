#!/bin/bash
# ...actually intended to be sourced; shebang above is for editor use

declare -g -A mid_to_fstype=( )
declare -g -A mid_to_mountsrc=( )
declare -g -A mid_to_options_str=( )
declare -g -A mid_to_pmid=( )
declare -g -A mid_to_relroot=( )
declare -g -A mid_to_sboptions=( )
declare -g -A pmid_to_mids=( )
declare -g -A relroot_to_mid=( )

read_mountinfo() {
	while read -r mid pmid st_dev root root_rel options opt_fields_s; do
		: "mid=$mid" "pmid=$pmid" "st_dev=$st_dev" "root=$root" "root_rel=$root_rel" "options=$options" "opt_fields_s=$opt_fields_s"
		declare -A options=( )
		read -r -a opt_fields <<<"$opt_fields_s"
		set -- "${opt_fields[@]}"
		option_str=" " # allow easier parsing of individual options
		while (( $# )) && [[ $1 != - ]]; do
			option_str+="$1 "
			shift
		done

		if [[ $1 = - ]]; then
			mid_to_fstype[$mid]=$2
			mid_to_mountsrc[$mid]=$3
			mid_to_sboptions[$mid]=$4
		fi

		pmid_to_mids[$pmid]+="$mid "
		mid_to_options_str[$mid]=$option_str
		mid_to_pmid[$mid]=$pmid
		mid_to_relroot[$mid]=$root_rel
		relroot_to_mid[$root_rel]=$mid
	done < /proc/self/mountinfo
}
read_mountinfo

if [[ $DEBUG ]]; then
	declare -p mid_to_fstype
	declare -p mid_to_mountsrc
	declare -p mid_to_options_str
	declare -p mid_to_pmid
	declare -p mid_to_relroot
	declare -p mid_to_sboptions
	declare -p pmid_to_mids
	declare -p relroot_to_mid
fi
