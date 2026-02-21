#!/usr/bin/env bash

setup_config() {
    link_default() { link "$source_dir" "$target_dir"; }

    local folder_name=$1
    local action_func=${2:-link_default}
    local target_dir="$HOME/.config/$folder_name"
    local source_dir="$ROOT_DIR/dotfiles/$folder_name"

    if [ ! -d "$target_dir" ]; then
    log "Setting up $folder_name..."
    $action_func
    else
    log "$folder_name already exists."
    read -p "$(log "Do you want to replace it? (y/n) ")" -n 1 -r
    echo

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Replacing existing $folder_name..."
        rm -rf "$target_dir"
        $action_func
    else
        log "Skipping $folder_name..."
    fi
    fi
}

davinci-distrobox-setup(){
    #version 20.3.2
    echo ""
    log "setting up davinici"
    local container=davinci-fedora
    safe_run distrobox-create --name "$container" --image fedora:42 --yes

    safe_run distrobox enter "$container" -- sudo dnf install alsa-plugins-pulseaudio libxcrypt-compat xcb-util-renderutil xcb-util-wm \
    pulseaudio-libs xcb-util xcb-util-image xcb-util-keysyms libxkbcommon-x11 libXrandr \
    libXtst mesa-libGLU mtdev libSM libXcursor libXi libXinerama libxkbcommon libglvnd-egl \
    libglvnd-glx libglvnd-opengl libICE librsvg2 libSM libX11 libXcursor libXext libXfixes \
    libXi libXinerama libxkbcommon libxkbcommon-x11 libXrandr libXrender libXtst libXxf86vm \
    mesa-libGLU mtdev pulseaudio-libs xcb-util alsa-lib apr apr-util fontconfig freetype \
    libglvnd fuse-libs xcb-util-cursor zlib  rocm-opencl -y

    mkdir -p "$HOME/.local/share/icons"
    mkdir -p "$HOME/.local/share/applications"

    actions_todo+=(
        "'for davinic resolve download v20.3.2;'"
        "distrobox enter $container"
        "run: DaVinci_Resolve_20.3.2_Linux.run from the downloaded one"
        "sudo mkdir /opt/resolve/libs/disabled-libraries"
        "sudo mv /opt/resolve/libs/libglib-2.0.so* /opt/resolve/libs/disabled-libraries/"
        "sudo mv /opt/resolve/libs/libgio-2.0.so* /opt/resolve/libs/disabled-libraries/"
        "sudo mv /opt/resolve/libs/libgmodule-2.0.so* /opt/resolve/libs/disabled-libraries/"
    )

    cp $ROOT_DIR/dotfiles/davinci_conf/davinci-resolve.png $HOME/.local/share/icons/davinci-resolve.png
    cp $ROOT_DIR/dotfiles/davinci_conf/resolve.desktop  $HOME/.local/share/applications/resolve.desktop

    sed -i "s|Icon=.*|Icon=$HOME/.local/share/icons/davinci-resolve.png|" "$HOME/.local/share/applications/resolve.desktop"
    update-desktop-database ~/.local/share/applications

}

link $ROOT_DIR/dotfiles/.zshrc $HOME/.zshrc
mkdir -p ~/.config/zsh_scripts
link $ROOT_DIR/dotfiles/common.sh $HOME/.config/zsh_scripts/common.sh
link $ROOT_DIR/helper.sh $HOME/.config/zsh_scripts/helper.sh


setup_nvim_repo() {
  git clone https://github.com/Abdallemo/neovim-setup.git "$HOME/.config/nvim"
}
setup_pg_service() {
    cp -r $ROOT_DIR/dotfiles/pg_service "$HOME/.config"
}
setup_config "nvim" setup_nvim_repo
setup_config "pg_service" setup_pg_service

setup_config "kitty"
setup_config "MangoHud"

setcfg "export PGSERVICEFILE" "=" "$HOME/.config/pg_service/.pg_service.conf" "/etc/profile.d/pg.sh"
setcfg "GTK_USE_PORTAL" "=" "1" "/etc/environment"
setcfg "MANGOHUD" "=" "1" "/etc/environment"


git config --global user.name >/dev/null || \
  safe_run git config --global user.name "Abdallemo"

git config --global user.email >/dev/null || \
  safe_run git config --global user.email "learn3038it@gmail.com"

davinci-distrobox-setup
