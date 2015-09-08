install_dependencies() {
	
	local build_dir=$1
	local cache_dir=$2	
	
	# create buildpack dir
	mkdir -p ${build_dir}/.pdi-buildpack
	
	# install Java
	local jdk_url="https://download.run.pivotal.io/openjdk/precise/x86_64/openjdk-1.8.0_60.tar.gz"
	echo "Installing ${jdk_url} to ${build_dir}/.pdi-buildpack/open_jdk_jre"
	curl -s ${jdk_url} > ${cache_dir}/openjdk-1.8.0_60.tar.gz
	mkdir ${build_dir}/.pdi-buildpack/open_jdk_jre
	tar xzf ${cache_dir}/openjdk-1.8.0_60.tar.gz -C ${build_dir}/.pdi-buildpack/open_jdk_jre
		
	# install Liquibase
	local liquibase_url="https://github.com/liquibase/liquibase/releases/download/liquibase-parent-3.4.1/liquibase-3.4.1-bin.tar.gz"
	echo "Installing ${liquibase_url} to ${build_dir}/.pdi-buildpack/liquibase"
	curl -s -L ${liquibase_url} > ${cache_dir}/liquibase-3.4.1-bin.tar.gz
	mkdir ${build_dir}/.pdi-buildpack/liquibase
	tar xzf ${cache_dir}/liquibase-3.4.1-bin.tar.gz -C ${build_dir}/.pdi-buildpack/liquibase
	
	# install Pentaho PDI
	# http://downloads.sourceforge.net/project/pentaho/Data%20Integration/4.4.0-stable/pdi-ce-4.4.0-stable.tar.gz
	local pdi_url="https://s3-eu-west-1.amazonaws.com/voxgenbi/pdi-ce-4.4.0-stable.tar.gz"
	echo "Installing ${pdi_url} to ${build_dir}/.pdi-buildpack/pdi"	
	curl -s -L  ${pdi_url} > ${cache_dir}/pdi-ce-4.4.0-stable.tar.gz
	mkdir ${build_dir}/.pdi-buildpack/pdi
	tar xzf ${cache_dir}/pdi-ce-4.4.0-stable.tar.gz -C ${build_dir}/.pdi-buildpack/pdi	
}
