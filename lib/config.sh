reconfigure_app() {
	
	local build_dir=$1	
	local bp_dir=$2	

	# move kettle.properties to .kettle dir	
	echo "Moving kettle.properties"
	mkdir ${build_dir}/.kettle
	mv ${build_dir}/kettle.properties ${build_dir}/.kettle/kettle.properties
	
	# move helper file to config dir
	if [[ -f ${build_dir}/hlpr_call_entry_points_friendly_names.csv ]]; then
		echo "Moving hlpr_call_entry_points_friendly_names.csv"
		mv -f ${build_dir}/hlpr_call_entry_points_friendly_names.csv ${build_dir}/config/hlpr_call_entry_points_friendly_names.csv
	fi
	
	# delete any ETL_DIR setting and create a new entry pointing to the home dir
	echo "Setting ETL_DIR"
	sed ${build_dir}/.kettle/kettle.properties -i.bak -e '/ETL_DIR/d' -e '$aETL_DIR=/home/stackato/app'
	
	# delete any PDI_DIR setting and create a new entry pointing to the home dir
	echo "Setting PDI_DIR"
	sed ${build_dir}/.kettle/kettle.properties -i.bak -e '/PDI_DIR/d' -e '$aPDI_DIR=/home/stackato/app/.pdi-buildpack/pentaho'
	
	# add .profile.d script to set environment
	echo "Setting environment"
	mkdir -p ${build_dir}/.profile.d
	cp ${bp_dir}/profile/setenv.sh ${build_dir}/.profile.d/
	
	#edit pentaho env script to source .profile.d
	echo "Updating set-pentaho-env script"
	sed ${build_dir}/.pdi-buildpack/pentaho/data-integration/set-pentaho-env.sh -i.bak -e '/setPentahoEnv/i . ~/.profile.d/setenv.sh'
	
	# copy web proc script
	cp ${bp_dir}/lib/web_proc.sh ${build_dir}
	chmod u+x ${build_dir}/web_proc.sh
}