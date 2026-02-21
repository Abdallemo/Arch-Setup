package main

var packages = []string{
	"git", "curl", "wget", "unzip", "zip", "zsh", "neovim", "npm", "go",
	"ffmpeg", "netcat", "cloc", "speedtest-cli", "mariadb", "reflector",
	"xdg-desktop-portal", "xdg-desktop-portal-kde", "xdg-desktop-portal-gtk",
	"wine", "wine-mono", "wine-gecko", "dolphin", "obs-studio", "base-devel",
	"zed", "lsd", "bottles", "goverlay", "mangohud", "zen-browser-bin",
	"discord", "telegram-desktop", "onlyoffice-bin", "notable-bin", "okular",
	"tldr", "tree", "duf", "glances", "lua", "composer", "php", "r",
	"rstudio-desktop-bin", "sqlc", "dbeaver", "tableplus", "docker",
	"docker-compose", "podman", "podman-compose", "blender", "gimp", "krita",
	"inkscape", "pinta", "vlc", "haruna", "kamoso", "spectacle", "7zip",
	"cpu-x", "cpufetch", "lact", "openrgb", "pavucontrol", "piper",
	"tailscale", "sunshine", "steam", "meld", "kitty", "kdeconnect",
	"downgrade", "zsh-autosuggestions", "zsh-syntax-highlighting",
	"zsh-autocomplete", "fzf", "gcc-fortran", "python-setuptools-reproducible",
	"patool", "obs-cmd", "obs-backgroundremoval", "whisper.cpp", "qemu-full",
	"virt-manager", "audacity", "wl-clipboard", "distrobox", "scrcpy", "adb",
}

var servicesToEnable = []string{
	"mariadb",
	"postgresql",
	"redis",
	"tailscaled",
}

var todos []string
