install_dependencies() {
	
	local build_dir=$1
	local cache_dir=$2	
	local bp_dir=$3
	
	# create buildpack dir
	mkdir -p ${build_dir}/.pdi-buildpack
	
	# load dependencies properties
	source ${bp_dir}/config/dependencies.properties
	
	# install Java
	echo "Installing ${jdk_url} to ${build_dir}/.pdi-buildpack/open_jdk_jre"
	curl -s ${jdk_url} > ${cache_dir}/openjdk-1.8.0_60.tar.gz
	mkdir ${build_dir}/.pdi-buildpack/open_jdk_jre
	tar xzf ${cache_dir}/openjdk-1.8.0_60.tar.gz -C ${build_dir}/.pdi-buildpack/open_jdk_jre
			
	# install Pentaho PDI	
	echo "Installing ${pdi_url} to ${build_dir}/.pdi-buildpack/pdi"	
	curl -s -L  ${pdi_url} > ${cache_dir}/pdi-ce-4.4.0-stable.tar.gz
	mkdir ${build_dir}/.pdi-buildpack/pdi
	tar xzf ${cache_dir}/pdi-ce-4.4.0-stable.tar.gz -C ${build_dir}/.pdi-buildpack/pdi	

	# install Liquibase
	echo "Installing ${liquibase_url} to ${build_dir}/.pdi-buildpack/liquibase"
	curl -s -L ${liquibase_url} > ${cache_dir}/liquibase-3.4.1-bin.tar.gz
	mkdir ${build_dir}/.pdi-buildpack/liquibase
	tar xzf ${cache_dir}/liquibase-3.4.1-bin.tar.gz -C ${build_dir}/.pdi-buildpack/liquibase
	
	# copy postgres jdbc driver from pdi to liquibase
	cp ${build_dir}/.pdi-buildpack/pdi/data-integration/libext/JDBC/postgresql-*.jar ${build_dir}/.pdi-buildpack/liquibase/lib

}
