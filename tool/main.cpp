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

namespace miniguest {

struct TopLevelArgs final : virtual MultiCommand, virtual MixCommonArgs {
  TopLevelArgs()
      : MultiCommand(RegisterCommand::getCommandsFor({})),
        MixCommonArgs("miniguest") {
    addFlag({
        .longName = "help",
        .description = "Show usage information.",
        .handler = {[&]() { throw HelpRequested(); }},
    });
  }

  std::string description() override {
    return "Companion tool for Miniguest lightweight NixOS images";
  }

  std::string doc() override {
    std::string doc = "Available subcommands:";
    for (auto [name, cmd] : commands) {
      auto line = "  " + name + ":";
      line.resize(16, ' ');
      line += cmd()->description();
      doc.push_back('\n');
      doc.append(line);
    }
    return doc;
  }
};

void main0(int argc, char **argv) {
  initNix();
  initGC();
  TopLevelArgs args;

  settings.experimentalFeatures = {Xp::Flakes};

  if (argc > 0 && std::string_view(argv[0]) == "__build-remote") {
    execv(NIX_EXE, argv);
  }

  try {
    args.parseCmdline(argvToStrings(argc, argv));
  } catch (HelpRequested &) {
    Args &cmd = args.command ? static_cast<Args &>(*args.command->second)
                             : static_cast<Args &>(args);
    std::cout << cmd.description() << std::endl;
    std::cout << cmd.doc() << std::endl;
    return;
  } catch (UsageError &) {
    if (!completions)
      throw;
  }
  if (completions) {
    switch (completionType) {
    case ctNormal:
      std::cout << "normal\n";
      break;
    case ctFilenames:
      std::cout << "filenames\n";
      break;
    case ctAttrs:
      std::cout << "attrs\n";
      break;
    }
    for (auto &s : *completions)
      std::cout << s.completion << "\t" << s.description << "\n";
    return;
  }
  if (!args.command)
    throw UsageError("no subcommand specified");

  args.command->second->prepare();
  args.command->second->run();
}

} // namespace miniguest

int main(int argc, char **argv) {
  return nix::handleExceptions(argv[0],
                               [=]() { miniguest::main0(argc, argv); });
}
