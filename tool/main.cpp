/* Copyright 2022 Julie Bettens
 *
 * This file is part of the Miniguest companion.
 *
 * The Miniguest companion is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 *
 * Miniguest is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Miniguest.  If not, see <https://www.gnu.org/licenses/>.
 */

#include "command.hh"
#include "common-args.hh"
#include "shared.hh"

using namespace nix;

struct HelpRequested {};

struct MiniguestArgs final : virtual MultiCommand, virtual MixCommonArgs {
  bool showVersion = false;

  MiniguestArgs()
      : MultiCommand(RegisterCommand::getCommandsFor({})),
        MixCommonArgs("miniguest") {
    addFlag({
        .longName = "help",
        .description = "Show usage information.",
        .handler = {[&]() { throw HelpRequested(); }},
    });
  }
};

void main0(int argc, char **argv) {
  initNix();
  initGC();
  MiniguestArgs args;

  settings.experimentalFeatures = {Xp::Flakes};

  try {
    args.parseCmdline(argvToStrings(argc, argv));
  } catch (HelpRequested &_) {
    std::vector<std::string> commandPath;
    MultiCommand *command = &args;
    for (MultiCommand *cmd = &args; cmd && cmd->command;
         cmd = dynamic_cast<MultiCommand *>(&*cmd->command->second)) {
      commandPath.push_back(cmd->command->first);
      command = cmd;
    }
    if (command)
      std::cout << command->doc() << std::endl;
    return;
  }
  if (!args.command)
    throw UsageError("no subcommand specified");

  args.command->second->prepare();
  args.command->second->run();
}

int main(int argc, char **argv) {
  return nix::handleExceptions(argv[0], [=]() { main0(argc, argv); });
}
