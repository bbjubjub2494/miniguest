# Copyright 2021 Louis Bettens
#
# This file is part of the Miniguest companion.
#
# The Miniguest companion is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# Miniguest is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Miniguest.  If not, see <https://www.gnu.org/licenses/>.

# ARG_POSITIONAL_SINGLE(command, subcommand to run)
# ARG_TYPE_GROUP_SET(commands, COMMAND, command, [install,create,help])
# ARG_OPTIONAL_SINGLE(guests-dir, , directory containing guests profiles, /etc/miniguests)
# ARG_OPTIONAL_SINGLE(nix, , path to the nix binary, @nixFlakes@/bin/nix)
# ARG_LEFTOVERS(subcommand arguments)
# ARGBASH_GO
