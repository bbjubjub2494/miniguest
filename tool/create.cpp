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

#include "common.hpp"
#include "manifest.hpp"

#include "build-result.hh"
#include "command.hh"
#include "derived-path.hh"
#include "eval-cache.hh"

#include <iostream>
#include <map>

using namespace nix;
namespace fs = std::filesystem;

namespace miniguest {

struct CmdCreate : virtual EvalCommand, virtual MixProfile {
  std::string guest_name;
  std::optional<std::string> hypervisor;

  const std::string set_color_red = "\e[1m\e[31m", reset_color = "\e(B\e[m";

  std::string description() override {
    return "generate a command to configure the guest in the hypervisor";
  }

  std::string doc() override {
    return R""(miniguest create [-h|--help] [-t|--hypervisor <HYPERVISOR>] <guest-name>
	<guest-name>: name of guest to create
	-h, --help: Prints help
	-t, --hypervisor: hypervisor to configure. Can be one of: 'libvirt' and 'lxc' (default: 'libvirt'))"";
  }

  void display_command(Strings cmd) const {
    std::cout << "# Create " << guest_name << " using:" << std::endl;
    for (auto &line : cmd)
      std::cout << line << " \\\n  ";
    std::cout << std::endl;
  }

  void display_command_libvirt() const {
    Strings cmd{
        "virt-install -n " + guest_name,
        "--connect qemu:///system",
        "--os-variant nixos-unstable",
        "--memory 1536",
        "--disk none",
        "--import",
        "--boot kernel=/etc/miniguests/" + guest_name +
            "/kernel,initrd=/etc/miniguests/" + guest_name + "/initrd",
        "--filesystem /nix/store/,nix-store,readonly=yes,accessmode=squash",
        "--filesystem /etc/miniguests/" + guest_name +
            "/boot/,boot,readonly=yes,accessmode=squash",
    };
    display_command(cmd);
  }

  void display_command_lxc() const {
    Strings cmd = {
        "lxc-create " + guest_name,
        "-f extra-config",
        "-t local --",
        "-m @lxc_template@/meta.tar.xz",
        "-f @lxc_template@/rootfs.tar.xz",
    };
    std::cout << "# " << set_color_red
              << "WARNING: make sure root is uid-mapped, otherwise you might "
                 "experience store corruption in the host!"
              << reset_color << std::endl;
    display_command(cmd);
  }

  struct HypervisorData {
    void (CmdCreate::*display_commmand)() const;
  };

  static const std::map<std::string, HypervisorData> hypervisors;

  static void completeHypervisor(size_t, std::string_view prefix) {
    completionType = ctNormal;
    for (auto [name, _] : hypervisors)
      if (name.size() >= prefix.size() &&
          std::string_view(name.data(), prefix.size()) == prefix)
        completions->add(name);
  }

  CmdCreate() {
    expectArgs({
        .label = "guest-name",
        .handler = {&guest_name},
        .completer = completeGuestName,
    });
    addFlag({
        .longName = "hypervisor",
        .shortName = 't',
        .description = "hypervisor to configure (default: libvirt)",
        .labels = {"hypervisor"},
        .handler = {&hypervisor},
        .completer = &completeHypervisor,
    });
  }

  void run(ref<Store> store) override {
    if (!hypervisor)
      hypervisor = "libvirt";

    if (auto it = hypervisors.find(*hypervisor); it != hypervisors.end()) {
      (this->*it->second.display_commmand)();
    } else
      throw Error(2, "unknown hypervisor type");
  }

  virtual ~CmdCreate() = default;
};

const std::map<std::string, CmdCreate::HypervisorData> CmdCreate::hypervisors{
    {"libvirt", {&CmdCreate::display_command_libvirt}},
    {"lxc", {&CmdCreate::display_command_lxc}},
};

static auto rCmdCreate = registerCommand<CmdCreate>("create");

} // namespace miniguest
