{
  description = "Cia unix full";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        additional = pkgs.stdenv.mkDerivation {
          pname = "cia-tools-additional";
          version = "0.1.3";
          src = ./.;

          installPhase = ''
            mkdir -p $out/{bin,lib}
            cp ctrdecrypt ctrtool makerom $out/bin/
            chmod +x $out/bin/*
            cp seeddb.bin $out/lib 
          '';
        };
      in
      {

        packages = {
          inherit additional;

          default = pkgs.writeShellScriptBin "cia-unix" ''
            #!/usr/bin/env bash

            # Colors for output
            RED='\033[0;31m'
            GREEN='\033[0;32m'
            YELLOW='\033[1;33m'
            BLUE='\033[0;34m'
            BOLD='\033[1m'
            UNDERLINE='\033[4m'
            NC='\033[0m' # No Color

            # Log file
            LOG_FILE="/tmp/cia-unix.log"

            # Initialize log
            date -u > "$LOG_FILE"

            # Function to print colored output
            print_color() {
                local color=$1
                local text=$2
                echo -e "''${color}''${text}''${NC}"
            }

            # Function to log and print
            log_print() {
                echo "$1" | tee -a "$LOG_FILE"
            }

            # ROMs presence check
            cia_count=$(ls -1 *.cia 2>/dev/null | wc -l)
            ds_count=$(ls -1 *.3ds 2>/dev/null | wc -l)
            if [[ $cia_count -eq 0 ]] && [[ $ds_count -eq 0 ]]; then
                if [[ -f "$LOG_FILE" ]]; then
                    rm "$LOG_FILE"
                fi
                print_color "$RED" "No CIA/3DS roms were found."
                exit 1
            fi

            # Function to run a tool and log output
            run_tool() {
                local name=$1
                shift
                local args=("$@")
                
                local output
                output=$("$name" "''${args[@]}" 2>&1)
                local exit_code=$?
                
                log_print "$output"
                
                if [[ $exit_code -ne 0 ]]; then
                    print_color "$RED" "$name failed with exit code $exit_code"
                    exit $exit_code
                fi
                
                echo "$output"
            }

            # Function to check decryption status
            check_decrypt() {
                local name=$1
                local ext=$2
                
                if [[ -f "''${name}-decrypted.''${ext}" ]]; then
                    echo -e "$(print_color "$UNDERLINE" "Decryption completed")"
                else
                    echo -e "$(print_color "$UNDERLINE" "Decryption failed")"
                fi
            }

            # Function to generate arguments for makerom
            gen_args() {
                local name=$1
                local part_count=$2
                local args=()
                
                for ((partition=0; partition<part_count; partition++)); do
                    if [[ -f "''${name}.''${partition}.ncch" ]]; then
                        args+=("-i" "''${name}.''${partition}.ncch:''${partition}:''${partition}")
                    fi
                done
                
                echo "''${args[@]}"
            }

            # Cache cleanup function
            remove_cache() {
                log_print "Removing cache..."
                rm -f ./*-decfirst.cia
                rm -f ./*.ncch
            }

            # 3DS decrypting
            for ds in *.3ds; do
                # Skip if no files found
                [[ -e "$ds" ]] || continue
                
                # Skip if already decrypted
                if [[ "$ds" == *"decrypted"* ]]; then
                    continue
                fi
                
                dsn="''${ds%.3ds}"
                args=("-f" "cci" "-ignoresign" "-target" "p" "-o" "''${dsn}-decrypted.3ds")
                
                log_print "Decrypting: $(print_color "$BOLD" "$ds")..."
                run_tool "ctrdecrypt" "$ds"
                
                # Process ncch files
                for ncch in "''${dsn}".*.ncch; do
                    [[ -e "$ncch" ]] || continue
                    
                    i=0
                    case $ncch in
                        "''${dsn}.Main.ncch") i=0 ;;
                        "''${dsn}.Manual.ncch") i=1 ;;
                        "''${dsn}.DownloadPlay.ncch") i=2 ;;
                        "''${dsn}.Partition4.ncch") i=3 ;;
                        "''${dsn}.Partition5.ncch") i=4 ;;
                        "''${dsn}.Partition6.ncch") i=5 ;;
                        "''${dsn}.N3DSUpdateData.ncch") i=6 ;;
                        "''${dsn}.UpdateData.ncch") i=7 ;;
                    esac
                    args+=("-i" "''${ncch}:''${i}:''${i}")
                done
                
                log_print "Building decrypted ''${dsn} 3DS..."
                run_tool "makerom" "''${args[@]}"
                check_decrypt "$dsn" "3ds"
                remove_cache
            done

            # CIA decrypting
            for cia in *.cia; do
                # Skip if no files found
                [[ -e "$cia" ]] || continue
                
                # Skip if already decrypted
                if [[ "$cia" == *"decrypted"* ]]; then
                    continue
                fi
                
                log_print "Decrypting: $(print_color "$BOLD" "$cia")..."
                cutn="''${cia%.cia}"
                content=$(run_tool "ctrtool" "--seeddb=seeddb.bin" "$cia")
                
                # Check CIA type and process accordingly
                if echo "$content" | grep -qi "T.*d.*00040000"; then
                    log_print "CIA Type: Game"
                    run_tool "ctrdecrypt" "$cia"
                    
                    args=("-f" "cia" "-ignoresign" "-target" "p" "-o" "''${cutn}-decfirst.cia")
                    i=0
                    for ncch in $(ls -1 *.ncch 2>/dev/null | sort); do
                        [[ -e "$ncch" ]] || continue
                        args+=("-i" "''${ncch}:''${i}:''${i}")
                        ((i++))
                    done
                    run_tool "makerom" "''${args[@]}"
                    
                elif echo "$content" | grep -qi "T.*d.*0004000[eE]"; then
                    log_print "CIA Type: $(print_color "$BOLD" "Patch")"
                    run_tool "ctrdecrypt" "$cia"
                    
                    args=("-f" "cia" "-ignoresign" "-target" "p" "-o" "''${cutn} (Patch)-decrypted.cia")
                    patch_parts=$(ls -1 "''${cutn}."*.ncch 2>/dev/null | wc -l)
                    gen_args_output=$(gen_args "$cutn" "$patch_parts")
                    # Convert string to array
                    args+=("$gen_args_output")
                    
                    run_tool "makerom" "''${args[@]}"
                    check_decrypt "''${cutn} (Patch)" "cia"
                    
                elif echo "$content" | grep -qi "T.*d.*0004008[cC]"; then
                    log_print "CIA Type: $(print_color "$BOLD" "DLC")"
                    run_tool "ctrdecrypt" "$cia"
                    
                    args=("-f" "cia" "-dlc" "-ignoresign" "-target" "p" "-o" "''${cutn} (DLC)-decrypted.cia")
                    dlc_parts=$(ls -1 "''${cutn}."*.ncch 2>/dev/null | wc -l)
                    gen_args_output=$(gen_args "$cutn" "$dlc_parts")
                    args+=("$gen_args_output")
                    
                    run_tool "makerom" "''${args[@]}"
                    check_decrypt "''${cutn} (DLC)" "cia"
                else
                    log_print "Unsupported CIA"
                fi
                
                # Process decfirst.cia files
                for decfirst in *-decfirst.cia; do
                    [[ -e "$decfirst" ]] || continue
                    
                    cutn="''${decfirst%-decfirst.cia}"
                    
                    log_print "Building decrypted ''${cutn} CCI..."
                    run_tool "makerom" "-ciatocci" "''$decfirst" "-o" "''${cutn}-decrypted.cci"
                    check_decrypt "$cutn" "cci"
                done
                
                remove_cache
            done

            echo "Log saved to $LOG_FILE"
          '';
        };
      }
    );
}
