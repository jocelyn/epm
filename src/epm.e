note

	description:

		"Eiffel Package Manager"

	copyright: "Copyright (c) 2012, Olivier Ligot and others"
	license: "MIT License"
	date: "$Date$"
	revision: "$Revision$"

class EPM

inherit
	KL_SHARED_ARGUMENTS
	KL_SHARED_EXECUTION_ENVIRONMENT
	KL_SHARED_FILE_SYSTEM
	KL_SHARED_OPERATING_SYSTEM
	SHARED_EJSON

create
	make

feature {NONE} -- Initialization

	make
			-- Run the application with options.
		local
			l_package_converter: JSON_EPM_PACKAGE_CONVERTER
			l_parser: AP_PARSER
			l_commands: DS_HASH_TABLE [PROCEDURE [ANY, TUPLE], STRING]
		do
			eiffel_library_directory := ""
			create l_package_converter.make
			package := l_package_converter.object
			json.add_converter (l_package_converter)
			Arguments.set_program_name ("epm")
			create l_parser.make
			l_parser.set_application_description ("Eiffel Package Manager")
			l_parser.set_parameters_description ("<command> where <command> is one of: install, update")
			l_parser.parse_arguments
			if attached l_parser.parameters as l_parameter and then attached l_parser.help_option as l_help_option then
				if l_parameter.count < 1 then
					l_help_option.display_help (l_parser)
				else
					create l_commands.make (3)
					l_commands.force_last (agent install, "install")
					l_commands.force_last (agent update, "update")
					if attached l_parameter.first as l_first then
						if not l_commands.has (l_first) then
							l_help_option.display_help (l_parser)
						else
							l_commands.item (l_first).call ([])
						end
					end
				end
			end
		end

feature -- Basic operations

	install
			-- Install a package.
		local
			l_dependency, l_dir: STRING
			l_command: DP_SHELL_COMMAND
		do
			check_eiffel_library
			read_package
			if package_read then
				io.put_string ("Installing package " + package.name + " version " + package.version + "...")
				io.put_new_line
				if attached package.dependencies.new_cursor as l_cursor then
					from
						l_cursor.start
					until
						l_cursor.off
					loop
						l_dependency := l_cursor.key
						io.put_string ("Installing dependency " + l_dependency + "...")
						io.put_new_line
						l_dir := File_system.pathname (eiffel_library_directory, l_dependency)
						create l_command.make ("git clone " + l_cursor.item.repository + " " + l_dir)
						l_command.execute
						checkout (l_cursor.item.checkout, l_dir)
						l_cursor.forth
					end
				end
				if attached package.scripts.new_cursor as l_cursor then
					from
						l_cursor.start
					until
						l_cursor.off
					loop
						if l_cursor.key.is_equal ("install") then
							create l_command.make (l_cursor.item)
							l_command.execute
						end
						l_cursor.forth
					end
				end
				io.put_string ("done")
				io.put_new_line
            end
		end

	update
			-- Update a package.
		local
			l_dependency, l_cwd, l_dir: STRING
			l_command: DP_SHELL_COMMAND
		do
			check_eiffel_library
			read_package
			if package_read then
				io.put_string ("Updating package " + package.name + " version " + package.version + "...")
				io.put_new_line
				if attached package.dependencies.new_cursor as l_cursor then
					from
						l_cursor.start
					until
						l_cursor.off
					loop
						l_dependency := l_cursor.key
						io.put_string ("Updating dependency " + l_dependency + "...")
						io.put_new_line
						l_cwd := File_system.cwd
						l_dir := File_system.pathname (eiffel_library_directory, l_dependency)
						File_system.cd (l_dir)
						create l_command.make ("git pull " + l_cursor.item.repository)
						l_command.execute
						File_system.cd (l_cwd)
						checkout (l_cursor.item.checkout, l_dir)
						l_cursor.forth
					end
				end
				io.put_string ("done")
				io.put_new_line
            end
		end

feature {NONE} -- Implementation

	Package_file_name: STRING = "package.json"
			-- Package file name

	Eiffel_library_name: STRING = "EIFFEL_LIBRARY"
			-- Eiffel library environment variable name

	package: EPM_PACKAGE
			-- Package definition

	package_read: BOOLEAN
			-- Has the package been read ?

	eiffel_library_directory: STRING
			-- Eiffel library directory

	Eiffel_library_default_value: STRING
			-- Eiffel library environment variable default value
		do
			if Operating_system.Is_unix then
				Result := "$HOME/eiffel/library"
			else
				Result := "C:\eiffel\library"
			end
		end

	check_eiffel_library
			-- Check that the environment variable `Eiffel_library_name' is defined
			-- and that the directory corresponding to the value of `Eiffel_library_name' exists.
		local
			l_value: STRING
		do
			if attached Execution_environment.variable_value (Eiffel_library_name) as l then
				l_value := l
			else
				Execution_environment.set_variable_value (Eiffel_library_name, Eiffel_library_default_value)
				l_value := Eiffel_library_default_value
			end
			eiffel_library_directory := Execution_environment.interpreted_string (l_value)
			if not File_system.directory_exists (eiffel_library_directory) then
				File_system.recursive_create_directory (eiffel_library_directory)
			end
		end

	read_package
			-- Read the package definition.
		local
			l_file: KL_TEXT_INPUT_FILE
			l_count: INTEGER
			l_parser: JSON_PARSER
		do
			create l_file.make (file_system.pathname (File_system.cwd, Package_file_name))
			l_count := l_file.count
			l_file.open_read
			if l_file.is_open_read then
				l_file.read_string (l_count)
				create l_parser.make_parser (l_file.last_string)
				if attached l_parser.parse as jv and l_parser.is_parsed then
					if attached {EPM_PACKAGE} json.object (jv, "EPM_PACKAGE") as l_package then
						package := l_package
						package_read := True
					end
				else
					io.put_string ("Unable to parse " + l_file.last_string)
                end
			else
				io.put_string ("Unable to open file " + l_file.name)
			end
		end

	checkout (a_checkout, a_dirname: STRING)
		local
			l_cwd: STRING
			l_command: DP_SHELL_COMMAND
		do
			l_cwd := File_system.cwd
			File_system.cd (a_dirname)
			create l_command.make ("git checkout " + a_checkout)
			l_command.execute
			File_system.cd (l_cwd)
		end

end
