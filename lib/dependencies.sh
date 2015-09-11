install_dependencies() {
	
	local build_dir=$1
	local cache_dir=$2	
	local bp_dir=$3
		
	# load dependencies properties
	source ${bp_dir}/config/dependencies.properties
	
	# install Java
	local jdk_dir=${build_dir}/.pdi-buildpack/open_jdk_jre
	install_dependency $bp_dir $cache_dir $jdk_url $jdk_dir
			
	# install Pentaho PDI	
	local pdi_dir=${build_dir}/.pdi-buildpack/pdi"
	install_dependency $bp_dir $cache_dir $pdi_url $pdi_dir	

	# install Liquibase
	local liquibase_dir=${build_dir}/.pdi-buildpack/liquibase"
	install_dependency $bp_dir $cache_dir $liquibase_url $liquibase_dir
	
	# copy postgres jdbc driver from pdi to liquibase
	cp ${pdi_dir}/data-integration/libext/JDBC/postgresql-*.jar ${liquibase_dir}/lib
}

install_dependency() {

	local bp_dir=$1
	local cache_dir=$2
	local pkg_url=$3
	local pkg_dir=$4
	
	echo "Installing ${pkg_url} to ${pkg_dir}"
	
	# get the package, either from buildpack or url
	local pkg_file=${pkg_url##*/}
	if [[ -f ${bp_dir}/dependencies/${pkg_file} ]]; then
		cp ${bp_dir}/dependencies/${pkg_file} ${cache_dir}/${pkg_file}
	else
		curl -s -L ${pkg_url} > ${cache_dir}/${pkg_file}
	fi				
	
	# unpack it into the target dir
	mkdir -p ${pkg_dir}
	tar xzf ${cache_dir}/${pkg_file} -C ${pkg_dir}
}
