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

#include <cassert>
#include <iostream>
#include <vector>

using namespace nix;
namespace fs = std::filesystem;

struct CmdCreate : virtual EvalCommand, virtual MixProfile {
  std::string guest_name, hypervisor;

  const std::string set_color_red = "\e[1m\e[31m", reset_color = "\e(B\e[m";

  CmdCreate() {
    expectArg("name", &guest_name);
    addFlag({
        .longName = "type",
        .shortName = 't',
        .description = "hyervisor to configure (default: libvirt)",
        .labels = {"hypervisor"},
        .handler = {&hypervisor},
    });
  }

  std::vector<std::string> prepare_command() {
    if (hypervisor == "libvirt")
      return {
          "virt-install -n " + guest_name,
          "--connect qemu:///system",
          "--os-variant nixos-unstable",
          "--memory 1536",
          "--disk none",
          "--import",
          "--boot kernel=/etc/miniguests/" + guest_name +
              "/kernel,initrd=/etc/miniguests/" + guest_name + "/initrd",
          "--filesystem /nix/store,nix-store,readonly=yes,accessmode=squash",
          "--filesystem /etc/miniguests/" + guest_name +
              "/boot,boot,readonly=yes,accessmode=squash",
      };

    else if (hypervisor == "lxc")
      return {
          "lxc-create " + guest_name,
          "-f extra-config",
          "-t local --",
          "-m @lxc_template@/meta.tar.xz",
          "-f @lxc_template@/rootfs.tar.xz",
      };
    else
      throw Error(2, "unknown hypervisor type");
  }

  void run(ref<Store> store) override {
    if (hypervisor.empty())
      hypervisor = "libvirt";

    auto cmd = prepare_command();

    if (hypervisor == "lxc")
      std::cout << "# " << set_color_red
                << "WARNING: make sure root is uid-mapped, otherwise you might "
                   "experience store corruption in the host!"
                << reset_color << std::endl;
    std::cout << "# Create " << guest_name << " using:" << std::endl;
    for (auto &line : cmd)
      std::cout << line << " \\" << std::endl;
  }

  virtual ~CmdCreate() = default;
};

static auto rCmdCreate = registerCommand<CmdCreate>("create");
