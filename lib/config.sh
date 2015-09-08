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
	echo "ETL_DIR=../../.." >> ${build_dir}/.kettle/kettle.properties
		
	# change location of pentaho to use installed PDI
	echo "Editing scripts to set PDI dir"
	cd ${build_dir}/scripts
	grep -RlZ /opt/pentaho * | xargs -0l sed -i.bak -e 's|/opt/pentaho|~/.pdi-buildpack/pdi|g'
	
	# add .profile.d script to set environment
	echo "Setting environment"
	mkdir -p ${build_dir}/.profile.d
	cp ${bp_dir}/profile/* ${build_dir}/.profile.d/
	
	#edit pentaho env script to source .profile.d
	echo "Updating set-pentaho-env script"
	sed ${build_dir}/.pdi-buildpack/pdi/data-integration/set-pentaho-env.sh -i.bak -e '/setPentahoEnv/i . ~/.profile.d/setenv.sh'
	
	# copy web proc script
	cp ${bp_dir}/lib/web_proc.sh ${build_dir}
	chmod u+x ${build_dir}/web_proc.sh
}