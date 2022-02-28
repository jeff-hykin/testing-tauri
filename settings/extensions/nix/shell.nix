# 
# how to add packages?
# 
    # you can search for them here: https://search.nixos.org/packages
    # to find them in the commandline use:
    #     nix-env -qP --available PACKAGE_NAME_HERE | cat
    # ex:
    #     nix-env -qP --available opencv
    #
    # NOTE: some things (like setuptools) just don't show up in the 
    # search results for some reason, and you just have to guess and check 🙃 

# Lets setup some definitions
let        
    # 
    # load most things from the nix.toml
    # 
    main = (builtins.import
        (builtins.getEnv
            ("__FORNIX_NIX_MAIN_CODE_PATH")
        )
    );
    
    # 
    # Rust
    # 
    mozOverlay = (main.import
        (main.fetchTarball
            ({url="https://github.com/mozilla/nixpkgs-mozilla/archive/7c1e8b1dd6ed0043fb4ee0b12b815256b0b9de6f.tar.gz";})
        )
    );
    mainPackagesIncludingRust = (main.import
        # <nixpkgs> but pinned
        (main.fetchTarball
            ({url="https://github.com/NixOS/nixpkgs/archive/c82b46413401efa740a0b994f52e9903a4f6dcd5.tar.gz";})
        )
        ({
            config = {};
            overlays = [ mozOverlay ];
        })
    );
    rustChannel = mainPackagesIncludingRust.rustChannelOf {
        channel = "nightly";
    };
    rust = (rustChannel.rust.override {
        targets = [
            "wasm32-unknown-unknown"
            "x86_64-unknown-linux-gnu"
            # wasm32-unknown-unknown    # wasm
            # aarch64-unknown-linux-gnu # ARM64 Linux (kernel 4.2, glibc 2.17+) 1
            # i686-pc-windows-gnu       # 32-bit MinGW (Windows 7+)
            # i686-pc-windows-msvc      # 32-bit MSVC (Windows 7+)
            # i686-unknown-linux-gnu    # 32-bit Linux (kernel 2.6.32+, glibc 2.11+)
            # x86_64-apple-darwin	      # 64-bit macOS (10.7+, Lion+)
            # x86_64-pc-windows-gnu     # 64-bit MinGW (Windows 7+)
            # x86_64-pc-windows-msvc    # 64-bit MSVC (Windows 7+)
            # x86_64-unknown-linux-gnu  # 64-bit Linux (kernel 2.6.32+, glibc 2.11+)
        ];
    });
    
    # just a helper
    emptyOptions = ({
        buildInputs = [];
        nativeBuildInputs = [];
        shellCode = "";
    });
    
    # 
    # Linux Only
    #
    linuxOnly = if main.stdenv.isLinux then ({
        buildInputs = [
            rust
            main.packages.pkgconfig
            main.packages.openssl
            main.packages.sass
            main.packages.glib
            main.packages.cairo
            main.packages.pango
            main.packages.atk
            main.packages.gdk-pixbuf
            main.packages.libsoup
            main.packages.webkitgtk
            main.packages.librsvg
            main.packages.patchelf
        ];
        nativeBuildInputs = [];
        shellCode = ''
            if [[ "$OSTYPE" == "linux-gnu" ]] 
            then
                true # add important (LD_LIBRARY_PATH, PATH, etc) nix-Linux code here
                # export EXTRA_CCFLAGS="$EXTRA_CCFLAGS:-I/usr/include"
                export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${main.makeLibraryPath [ main.packages.webkitgtk ]}"
                export CXXFLAGS="$CXXFLAGS:-DGLIB_SCHEMAS_DIR=${main.packages.glib.getSchemaPath main.packages.gsettings-desktop-schemas}"
                export XDG_DATA_DIRS="$XDG_DATA_DIRS:${main.packages.gsettings-desktop-schemas}:${main.packages.gsettings-desktop-schemas}/share:${main.packages.glib.getSchemaPath main.packages.gsettings-desktop-schemas}:${main.packages.glib.getSchemaPath main.packages.gsettings-desktop-schemas}/..:${main.packages.glib.getSchemaPath main.packages.gsettings-desktop-schemas}/../..:${main.packages.glib.getSchemaPath main.packages.gsettings-desktop-schemas}/../../.."
            fi
        '';
        # for python with CUDA 
        # 1. install cuda drivers on the main machine then
        # 2. include the following inside the shellCode if statement above
        #     export CUDA_PATH="${main.packages.cudatoolkit}"
        #     export EXTRA_LDFLAGS="-L/lib -L${main.packages.linuxPackages.nvidia_x11}/lib"
        #     export EXTRA_CCFLAGS="-I/usr/include"
        #     export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${main.packages.linuxPackages.nvidia_x11}/lib:${main.packages.ncurses5}/lib:/run/opengl-driver/lib"
        #     export LD_LIBRARY_PATH="$(${main.packages.nixGLNvidia}/bin/nixGLNvidia printenv LD_LIBRARY_PATH):$LD_LIBRARY_PATH"
        #     export LD_LIBRARY_PATH="${main.makeLibraryPath [ main.packages.glib ] }:$LD_LIBRARY_PATH"
        # 3. then add the following to the nix.toml file
        #    # 
        #    # Nvidia
        #    # 
        #    [[packages]]
        #    load = [ "nixGLNvidia",]
        #    onlyIf = [ [ "stdenv", "isLinux",],]
        #    # see https://discourse.nixos.org/t/opencv-with-cuda-in-nix-shell/7358/5
        #    from = { fetchGit = { url = "https://github.com/guibou/nixGL", rev = "7d6bc1b21316bab6cf4a6520c2639a11c25a220e" }, }
        # 
        #    [[packages]]
        #    load = [ "pkgconfig",]
        #    asNativeBuildInput = true
        #    onlyIf = [ [ "stdenv", "isLinux",],]
        # 
        #    [[packages]]
        #    load = [ "cudatoolkit",]
        #    onlyIf = [ [ "stdenv", "isLinux",],]
        #
        #    [[packages]]
        #    load = [ "libconfig",]
        #    asNativeBuildInput = true
        #    onlyIf = [ [ "stdenv", "isLinux",],]
        #
        #    [[packages]]
        #    load = [ "cmake",]
        #    asNativeBuildInput = true
        #    onlyIf = [ [ "stdenv", "isLinux",],]
        #
        #    [[packages]]
        #    load = [ "libGLU",]
        #    onlyIf = [ [ "stdenv", "isLinux",],]
        #
        #    [[packages]]
        #    load = [ "linuxPackages", "nvidia_x11",]
        #    onlyIf = [ [ "stdenv", "isLinux",],]
        #
        #    [[packages]]
        #    load = [ "stdenv", "cc",]
        #    onlyIf = [ [ "stdenv", "isLinux",],]
        #
        # 4. if you want opencv with cuda add the following to the nix.toml
        #    # 
        #    # opencv
        #    # 
        #    [[packages]]
        #    onlyIf = [ [ "stdenv", "isLinux",],]
        #    load = [ "opencv4",]
        #    override = { enableGtk3 = true, enableFfmpeg = true, enableCuda = true, enableUnfree = true, }
        #    # see https://discourse.nixos.org/t/opencv-with-cuda-in-nix-shell/7358/5
        #    from = { fetchGit = { url = "https://github.com/NixOS/nixpkgs/", rev = "a332da8588aeea4feb9359d23f58d95520899e3c" }, options = { config = { allowUnfree = true } }, }
    }) else emptyOptions;
    
    # 
    # Mac Only
    # 
    macOnly = if main.stdenv.isDarwin then ({
        buildInputs = [ rust ];
        nativeBuildInputs = [];
        shellCode = ''
            if [[ "$OSTYPE" = "darwin"* ]] 
            then
                true # add important nix-MacOS code here
                export EXTRA_CCFLAGS="$EXTRA_CCFLAGS:-I/usr/include:${main.packages.darwin.apple_sdk.frameworks.CoreServices}/Library/Frameworks/CoreServices.framework/Headers/"
            fi
        '';
    }) else emptyOptions;
    
# using the above definitions
in
    # 
    # create a shell
    # 
    main.packages.mkShell {
        # inside that shell, make sure to use these packages
        buildInputs =  main.project.buildInputs ++ macOnly.buildInputs ++ linuxOnly.buildInputs;
        
        nativeBuildInputs =  main.project.nativeBuildInputs ++ macOnly.nativeBuildInputs ++ linuxOnly.nativeBuildInputs;
        
        # run some bash code before starting up the shell
        shellHook = ''
            ${main.project.protectHomeShellCode}
            if [ "$FORNIX_DEBUG" = "true" ]; then
                echo "starting: 'shellHook' inside the 'settings/extensions/nix/shell.nix' file"
            fi
            ${linuxOnly.shellCode}
            ${macOnly.shellCode}
            
            # provide access to ncurses for nice terminal interactions
            # export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${main.packages.ncurses}/lib"
            
            if [ "$FORNIX_DEBUG" = "true" ]; then
                echo "finished: 'shellHook' inside the 'settings/extensions/nix/shell.nix' file"
                echo ""
                echo "Tools/Commands mentioned in 'settings/extensions/nix/nix.toml' are now available/installed"
            fi
        '';
    }
