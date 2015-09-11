reconfigure_app() {
	
	local build_dir=$1	
	local bp_dir=$2	

	# move kettle.properties to .kettle dir	
	echo "Moving kettle.properties"
	mkdir ${build_dir}/.kettle
	mv ${build_dir}/kettle.properties ${build_dir}/.kettle/kettle.properties
	
	# delete any ETL_DIR setting and create a new entry pointing to the home dir
	echo "Setting ETL_DIR"
	sed ${build_dir}/.kettle/kettle.properties -i.bak -e '/ETL_DIR/d'
	echo "ETL_DIR=/home/stackato/app" >> ${build_dir}/.kettle/kettle.properties
	
	# delete any PDI_DIR setting and create a new entry pointing to the home dir
	echo "Setting PDI_DIR"
	sed ${build_dir}/.kettle/kettle.properties -i.bak -e '/PDI_DIR/d'
	echo "PDI_DIR=/home/stackato/app/.pdi-buildpack/pdi" >> ${build_dir}/.kettle/kettle.properties	
	
	# add .profile.d script to set environment
	echo "Setting environment"
	mkdir -p ${build_dir}/.profile.d
	cp ${bp_dir}/profile/setenv.sh ${build_dir}/.profile.d/
	
	# add memory spec to profile if specified in kettle.properties
	local pdi_mem=$(grep "PDI_MAX_MEMORY" ${build_dir}/.kettle/kettle.properties | cut -d = -f 2)
	if [[ ! -z "$pdi_mem" ]]; then
		local pdi_java_opts="PENTAHO_DI_JAVA_OPTS=-Xmx${pdi_mem}"
		echo "Setting ${pdi_java_opts}" | indent
		echo "export ${pdi_java_opts}" >> ${build_dir}/.profile.d/setenv.sh
	fi
	
	#edit pentaho env script to source .profile.d
	echo "Updating set-pentaho-env script"
	sed ${build_dir}/.pdi-buildpack/pdi/data-integration/set-pentaho-env.sh -i.bak -e '/setPentahoEnv/i . ~/.profile.d/setenv.sh'
	
	# copy web proc script
	cp ${bp_dir}/lib/web_proc.sh ${build_dir}
	chmod u+x ${build_dir}/web_proc.sh
}