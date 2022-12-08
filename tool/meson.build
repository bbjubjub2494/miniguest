project('miniguest', 'cpp',
  version : '0.2.1',
  default_options : ['warning_level=1',
                     'cpp_std=c++17'])

add_project_arguments('-DSYSTEM="x86_64-linux"', language: 'cpp')  # TODO


# Nix dependency
nixlibs = [
  dependency('boost'), # transitive
  dependency('nlohmann_json'), # transitive

  dependency('nix-main'),
  dependency('nix-expr'),
  dependency('nix-cmd'),
  dependency('nix-store'),
]

nix_exe = dependency('nix-cmd').get_pkgconfig_variable('prefix')+'/bin/nix'
add_project_arguments('-Wno-non-virtual-dtor', language: 'cpp')  # present in Nix headers
add_project_arguments('-DHAVE_BOEHMGC=1', language: 'cpp')  # affects Nix headers
add_project_arguments('-DNIX_EXE="'+nix_exe+'"', language: 'cpp')


src = [
  'main.cpp',
  'install.cpp',
  'remove.cpp',
  'upgrade.cpp',
  'create.cpp',
  'common.cpp',
]
exe = executable('miniguest', src,
  dependencies : nixlibs,
  install : true)

install_subdir('misc/bash-completion', install_dir: 'share')
install_subdir('misc/fish', install_dir: 'share')
install_subdir('misc/zsh', install_dir: 'share')

test('basic', exe)
