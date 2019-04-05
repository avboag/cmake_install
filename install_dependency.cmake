set(dependencies "${CMAKE_BINARY_DIR}/dependencies" CACHE STRING "location of dependencies")

function(install_pkg src_location target_location)
	cmake_parse_arguments(installation "" "command;cmake_options" "" ${ARGN})

	if (NOT DEFINED installation_command)
		set(installation_command "mkdir build_dir && cd build_dir &&
			cmake .. -DCMAKE_INSTALL_PREFIX=\"$target_location\" ${installation_cmake_options} && make install"}
	endif()

	execute_process(
		COMMAND bash -c "${depend_installation_command}"
		WORKING_DIRECTORY "${src_location}"
	)
endfunction()

function(download fetch_address dependency_download_location)
    cmake_parse_arguments(dependency "no_cmake" "private_key;commit;path_suffix" "search_paths" ${ARGN})

	execute_process(COMMAND mkdir -p "${dependency_download_location}")

    if ("${fetch_address}" MATCHES "\\.tar\\.gz$")
        execute_process(COMMAND mkdir -p "${dependency_location}")
        execute_process(COMMAND bash -c "wget -qO- '${fetch_address}' | tar xvz #strip-components=1 -C '${dependency_location}'")
    else()
        if (DEFINED dependency_private_key)
            find_package(Git 2.3 QUIET)
            if (Git_FOUND)
                execute_process(COMMAND bash -c
					"GIT_SSH_COMMAND='ssh -i ${dependency_private_key}' '${GIT_EXECUTABLE}' clone '${fetch_address}' '${dependency_download_location}'")
            else()
				find_package(Git REQUIRED)
                execute_process(COMMAND bash -c "echo \"#!/usr/bin/env bash\nssh -i ${dependency_private_key} \\\"\\\$\@\\\"\" > ssh_; chmod +x ssh_")
                execute_process(COMMAND bash -c "GIT_SSH=./ssh_ \"${GIT_EXECUTABLE}\" clone \"${fetch_address}\" \"${dependency_download_location}\"")
            endif()
        else()
			find_package(Git REQUIRED)
            execute_process(COMMAND "${GIT_EXECUTABLE}" clone "${fetch_address}" "${dependency_location}")
        endif()
    endif()
endfunction()

macro(add_project_dependency fetch_address name)
    cmake_parse_arguments(dependency "no_cmake" "private_key;commit;config_path_suffix" "" ${ARGN})

	set(dependency_download_location "${CMAKE_BINARY_DIR}/downloads/${name}")
    set(dependency_location "${dependencies}/${name}")

	find_package(${name})

	if (NOT DEFINED ${name}_found)
    	download(${ARGV})

        if (DEFINED dependency_commit)
            execute_process(COMMAND ${GIT_EXECUTABLE} checkout "${dependency_commit}")
        endif()

    	if (NOT DEFINED dependency_path_suffix)
    	    set(dependency_path_suffix "")
    	endif()

	    if (NOT DEFINED dependency_config_path_suffix)
			set(dependency_config_path_suffix cmake)
	    endif()

		depend("${dependency_download_location}/${dependency_path_suffix}" "${dependency_location}")

    	if (${dependency_no_cmake})
            set(${name}_root "${dependency_location}")
    	else()
	        find_package(${name} PATHS "${dependency_location}/${dependency_path_suffix}/${dependency_config_path_suffix}" REQUIRED)
        endif()
    endif()
endmacro()