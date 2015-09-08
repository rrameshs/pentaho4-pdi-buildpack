install_package() {
	
	local build_dir=$1
	local cache_dir=$2
	
	#check there is exactly one tar file to install
	local tar_count=$(ls -1 ${build_dir}/*.tar.gz | wc -l)
	if [[ ${tar_count} -lt 1 ]]; then
		echo "ERROR: No tar file found - nothing to deploy"
		exit 1
	fi
	if [[ ${tar_count} -gt 1 ]]; then
		echo "ERROR: More than one tar file found - don't know which one to unpack"
		exit 2 
	fi
	
	#extract the tar file into a temp dir
	local tar_name=$(ls ${build_dir}/*.tar.gz)
	local tmp_dir=${cache_dir}/tmp
	mkdir -p ${tmp_dir}
	tar zxf ${tar_name} -C ${tmp_dir}
	rm -f ${tar_name}
	
	#check there is exactly one top-level dir
	local dir_count=$(ls -1 ${tmp_dir} | wc -l)
	if [[ ${dir_count} -lt 1 ]]; then
		echo "ERROR: Tar file is empty - nothing to deploy"
		exit 3
	fi
	if [[ ${dir_count} -gt 1 ]]; then
		echo "ERROR: Tar file contained more than one directory - don't know which one to use"
		exit 4
	fi
	
	echo "Moving extracted package into place"
	mv ${tmp_dir}/*/* ${build_dir}
	rm -rf ${tmp_dir}
}

