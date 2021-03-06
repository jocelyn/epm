note
	description: "Git pull command."
	author: "Olivier Ligot"
	date: "$Date$"
	revision: "$Revision$"

class
	GIT_PULL_COMMAND

inherit
	GIT_COMMAND

create
	make

feature {NONE} -- Initialization

	make
		do
			initialize
		end

feature -- Access

	name: STRING = "pull"
			-- Git subcommand name

end
