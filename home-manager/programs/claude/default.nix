# Links the private half of the config into place.
#
# These are OUT-OF-STORE symlinks: they point at the working tree of
# ~/private-dotfiles, not at a copy in the nix store. That is deliberate and the
# same choice as DOOMDIR in common.nix — this is config that gets edited and
# re-tried constantly, and a rebuild between the edit and finding out whether it
# worked would make that miserable.
#
# Directories are linked WHOLE wherever we own the whole directory, so adding a
# skill file, an agent, or a script under ~/loop needs no rebuild at all. Nix
# cannot do better than this: enumerating a directory it does not own
# (builtins.readDir, or home.file's recursive = true) means reading outside the
# flake, which a pure evaluation refuses. Whole-directory links are the only way
# to get folder granularity.
#
# A rebuild is therefore needed only when a whole new *directory* appears.
# Adding a command, a skill, an agent or a loop script does not need one.
#
# Nothing private is in this file — only paths.
{ config, lib, ... }:

let
  private = "${config.home.homeDirectory}/private-dotfiles";

  # private-dotfiles/home mirrors $HOME exactly, so a path is its own mapping.
  link = p: {
    name = p;
    value.source = config.lib.file.mkOutOfStoreSymlink "${private}/home/${p}";
  };

  # Directories we own outright.
  #
  # Owning these whole means every skill, agent and command must live in
  # private-dotfiles. Nix cannot also drop a store-backed bundle into a directory
  # that is itself a symlink — you get one or the other.
  #
  # .claude/skills also holds quint-studio-operator, which Quint Studio copies in
  # and re-syncs itself. That still works — Studio writes through the symlink —
  # and private-dotfiles gitignores it, since it is generated rather than authored.
  #
  # That used to matter: five command bundles here came from the `agentic` flake
  # and from quint-studio. All five had already been garbage-collected, and
  # nothing in this config could rebuild them, which is exactly the failure mode
  # this module exists to end. If you want such a bundle back, link it from a
  # working tree inside private-dotfiles rather than from /nix/store — a working
  # tree is never collected. See private-dotfiles/README.md.
  dirs = [
    ".claude/skills"
    ".claude/agents"
    ".claude/commands"
    "loop"
  ];
in
{
  home.file = lib.listToAttrs (map link dirs);

  # A missing clone would leave every link above dangling, which shows up as a
  # slash-command that appears in the menu and then fails. Checked at activation
  # rather than at evaluation, where a pure flake cannot look outside itself.
  home.activation.checkPrivateDotfiles =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -d "${private}" ]; then
        echo ""
        echo "  WARNING: ${private} is not cloned."
        echo "  The Claude skills, commands and ~/loop all just linked to nothing."
        echo "    git clone <private-dotfiles> ${private}"
        echo ""
      fi
    '';
}
