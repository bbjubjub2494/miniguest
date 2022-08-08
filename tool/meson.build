project('miniguest', 'cpp',
  version : '0.2',
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
add_project_arguments('-Wno-non-virtual-dtor', language: 'cpp')  # present in Nix headers


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

test('basic', exe)
