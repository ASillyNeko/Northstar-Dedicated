//go:build linux && (amd64 || arm64)

// Command nswine creates a standalone wineprefix of a Wine 10.0 build for use
// with nswrap.
//
// We could build Wine ourselves if needed, but our changes aren't too intrusive
// and it's much simpler and faster to iterate this way. It also wasn't possible
// before with older versions of wine since they had bugs we needed to patch,
// and they weren't entirely modular out of the box to the same extent as Wine
// 10.
//
// It does not currently support cross-compiling since it needs to run wineboot
// to initialize the prefix.
//
// It supports x86_64, and arm64 (via fex arm64ec).
//
// The generated wineprefix works independently of the system wine.
//
// It forces the use of nulldrv for display and no audio driver.
//
// Optionally, it can remove a bunch of unused libraries and services to
// significantly reduce the size and number of processes.
//
// Optionally, it can copy non-libc system libs into the output folder for
// completely standalone usage on any glibc distro. The build host should be
// running Debian, as this is what the wine binaries were built on, and is also
// where this logic was tested.
//
// While there are no official ARM64 wine builds, hangover on 10.x is close
// enough, as it's mostly converged with official wine now, especially when only
// looking at non-WoW64 arm64ec and ignoring arm32/i386.
package main

import (
	"errors"
	"flag"
	"fmt"
	"io/fs"
	"iter"
	"log/slog"
	"maps"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"time"

	"github.com/lmittmann/tint"
)

var (
	Prefix   = flag.String("prefix", "/wine", "wine install prefix (will be modified in-place and must not contain non-wine files)")
	Output   = flag.String("output", "/opt/northstar-runtime", "output directory")
	Optimize = flag.Bool("optimize", false, "remove unused libraries and services")
	Debug    = flag.Bool("debug", false, "debug logging")
	Vendor   = flag.Bool("vendor", false, "copy native libs from the build host")
)

func main() {
	flag.Parse()

	level := slog.LevelInfo
	if *Debug {
		level = slog.LevelDebug
	}
	slog.SetDefault(slog.New(tint.NewHandler(os.Stdout, &tint.Options{
		AddSource:  true,
		TimeFormat: time.Kitchen,
		Level:      level,
	})))

	if err := run(); err != nil {
		slog.Error("failed", "error", err)
		os.Exit(1)
	}
}

func run() error {
	if v, _ := strconv.ParseBool(os.Getenv("NSWINE_UNSAFE")); !v {
		if v, _ := strconv.ParseBool(os.Getenv("DOCKER")); !v {
			return fmt.Errorf("this is not usually safe to run outside a container")
		}
	}

	slog.Info("getting wine version")
	var wineBuildID string
	if buf, err := exec.Command(filepath.Join(*Prefix, "bin/wine"), "--version").Output(); err != nil {
		if xx, ok := err.(*exec.ExitError); ok {
			err = fmt.Errorf("%v (stderr: %q)", err, xx.Stderr)
		}
		return err
	} else {
		wineBuildID = strings.TrimRight(string(buf), "\n")
	}
	slog.Info("got wine version", "build_id", wineBuildID)

	if *Optimize {
		slog.Info("removing non-essential executables")
		if err := filepath.WalkDir(filepath.Join(*Prefix, "bin"), func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			switch d.Name() {
			case "wine":
				return nil
			case "wineserver":
				return nil
			}
			slog.Debug("delete", "path", path)
			return os.Remove(path)
		}); err != nil {
			return err
		}
	}

	slog.Info("removing manpages")
	if err := os.RemoveAll(filepath.Join(*Prefix, "share/man")); err != nil {
		return err
	}
	slog.Info("removing doc")
	if err := os.RemoveAll(filepath.Join(*Prefix, "share/doc")); err != nil {
		return err
	}
	slog.Info("removing desktop entries")
	if err := os.RemoveAll(filepath.Join(*Prefix, "share/applications")); err != nil {
		return err
	}
	slog.Info("removing headers")
	if err := os.RemoveAll(filepath.Join(*Prefix, "include")); err != nil {
		return err
	}

	slog.Info("removing static libs")
	if err := filepath.WalkDir(filepath.Join(*Prefix, "lib/wine"), func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if filepath.Ext(path) != ".a" {
			return nil
		}
		return os.Remove(path)
	}); err != nil {
		return err
	}

	slog.Info("removing directshow filters")
	if err := filepath.WalkDir(filepath.Join(*Prefix, "lib/wine"), func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if filepath.Ext(path) != ".ax" {
			return nil
		}
		slog.Debug("delete", "path", path)
		return os.Remove(path)
	}); err != nil {
		return err
	}

	slog.Info("removing control panel items")
	if err := filepath.WalkDir(filepath.Join(*Prefix, "lib/wine"), func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if filepath.Ext(path) != ".cpl" {
			return nil
		}
		slog.Debug("delete", "path", path)
		return os.Remove(path)
	}); err != nil {
		return err
	}

	slog.Info("removing wine-mono and wine-gecko stubs")
	if err := filepath.WalkDir(filepath.Join(*Prefix, "lib/wine"), func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if !strings.HasPrefix(d.Name(), "mscoree.") && !strings.HasPrefix(d.Name(), "mshtml.") {
			return nil
		}
		slog.Debug("delete", "path", path)
		return os.Remove(path)
	}); err != nil {
		return err
	}

	slog.Info("removing winemenubuilder")
	if err := filepath.WalkDir(filepath.Join(*Prefix, "lib/wine"), func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if !strings.HasPrefix(d.Name(), "winemenubuilder.") {
			return nil
		}
		slog.Debug("delete", "path", path)
		return os.Remove(path)
	}); err != nil {
		return err
	}

	if *Optimize {
		slog.Info("removing unnecessary drivers")
		if err := filepath.WalkDir(filepath.Join(*Prefix, "lib/wine"), func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			switch filepath.Ext(path) {
			case ".sys":
			case ".drv":
			default:
				return nil
			}
			switch filepath.Base(path) {
			default:
				return fmt.Errorf("TODO: is the driver %s needed?", path)
			case "msacm32.drv":
				return nil // keep
			case "mountmgr.sys":
				return nil // keep mountmgr since it's used internally for a lot of stuff (e.g., virtual drive info, creating links)
			case "ksecdd.sys":
			case "winspool.drv":
			case "winebus.sys":
			case "tdi.sys":
			case "usbd.sys":
			case "nsiproxy.sys":
			case "cng.sys":
			case "ndis.sys":
			case "http.sys":
			case "mouhid.sys":
			case "winehid.sys":
			case "hidparse.sys":
			case "winepulse.drv":
			case "wineusb.sys":
			case "wineps.drv":
			case "scsiport.sys":
			case "fltmgr.sys":
			case "winealsa.drv":
			case "winexinput.sys":
			case "winex11.drv":
			case "hidclass.sys":
			case "winebth.sys":
			case "wmilib.sys":
			case "netio.sys":
			case "winewayland.drv":
			}
			slog.Debug("removing driver", "name", filepath.Base(path))
			return os.Remove(path)
		}); err != nil {
			return err
		}
	}

	if *Optimize {
		slog.Info("removing wow64 libs")
		if err := os.RemoveAll(filepath.Join(*Prefix, "lib/wine/i386-windows")); err != nil && !errors.Is(err, os.ErrNotExist) {
			return err
		}
		if err := os.RemoveAll(filepath.Join(*Prefix, "lib/wine/i386-unix")); err != nil && !errors.Is(err, os.ErrNotExist) {
			return err
		}

		slog.Info("removing unnecessary libs")
		if err := filepath.WalkDir(filepath.Join(*Prefix, "lib/wine"), func(path string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if d.IsDir() {
				return nil
			}
			if !slices.ContainsFunc([]string{
				// d3d/d2d/ddraw/dmusic/opengl/opencl/vulkan stuff (it's big,
				// and it's definitely completely useless without the
				// non-nulldrv graphics drivers anyways)
				"d3d",
				"d2d",
				"dxgi",
				"ddraw",
				"dmusic",
				"dplay",
				"qedit",
				"winevulkan",
				"wined3d",
				"opencl",
				"opengl",
				"vulkan",

				// xaudio/xactengine/xapofx/x3daudio
				"xaudio",
				"xactengine",
				"xapofx",
				"x3daudio",

				// wow64
				"wow64",

				// some more interactive stuff
				"comdlg32.",
				"riched20.",
				"ieframe.",
				"ieproxy.",
				"browseui.",
				"scrrun.",
				"cryptdlg.",
				"rasdlg.",
				"scarddlg.",
				"hhctrl.",
				"dhtmled.",
				"regedit.",
				"mshta.",

				// print/scan/telephony/smartcard/media/speech/webcam stuff
				"tapi32.",
				"sane.",
				"twain_32.",
				"gphoto2.",
				"wiaservc.",
				"sapi.",
				"twinapi.",
				"winprint.",
				"localspl.",
				"winscard.",
				"ctapi32.",
				"winegstreamer.",
				"wmphoto.",
				"msttsengine.",
				"qcap.",
				"wmp.",
				"windows.gaming.input.",
				"windows.media.speech.",
				"mfmediaengine.",
				"mfreadwrite.",

				// misc
				"msi.",
				"wscript.",
				"cscript.",
				"jscript.",
				"vbscript.",
				"dwrite.",
				"gdiplus.",
				"winhlp32.",
				"oledb32.",
				"odbc32.",
				"l3codeca.",
				"wpcap.",
			}, func(x string) bool {
				return strings.HasPrefix(d.Name(), x)
			}) {
				return nil
			}
			slog.Debug("removing", "name", d.Name())
			return os.Remove(path)
		}); err != nil {
			return err
		}

		if arm64 {
			slog.Info("removing 32-bit arm support")
			for _, name := range []string{
				"lib/libqemu-arm.so",
				"lib/libqemu-i386.so",
				"lib/libqemu-x86_64.so",
				"lib/wine/aarch64-unix/wowarmhw.so",
				"lib/wine/aarch64-unix/wowarmhw.so",
				"lib/wine/aarch64-windows/lib/wowarmhw.dll",
				"lib/wine/aarch64-windows/lib/wowarmhw.dll",
			} {
				path := filepath.Join(*Prefix, name)
				slog.Debug("delete", "path", path)
				if err := os.RemoveAll(path); err != nil {
					return err
				}
			}
		} else {
			slog.Info("removing 32-bit support")
			for _, name := range []string{
				"lib/wine/aarch64-windows/lib/wow64cpu.dll",
			} {
				path := filepath.Join(*Prefix, name)
				slog.Debug("delete", "path", path)
				if err := os.RemoveAll(path); err != nil {
					return err
				}
			}
		}

		slog.Info("removing dlls/exes which depend on removed stuff")
		if err := func() error {
			dir := filepath.Join(*Prefix, "lib/wine", archt("x86_64-windows", "aarch64-windows"))

			dis, err := os.ReadDir(dir)
			if err != nil {
				return err
			}

			uncase := map[string]string{}
			for _, di := range dis {
				uncase[strings.ToLower(di.Name())] = di.Name()
			}

			dlldeps := map[string][]string{}
			for _, di := range dis {
				if di.IsDir() {
					continue
				}
				switch filepath.Ext(di.Name()) {
				case ".dll":
				case ".exe":
				default:
					continue
				}
				if di.Name() == "explorer.exe" {
					continue // this one is special
				}
				deps, err := peImports(filepath.Join(dir, di.Name()))
				if err != nil {
					return fmt.Errorf("get deps for %q: %w", di.Name(), err)
				}
				for i, dep := range deps {
					deps[i] = strings.ToLower(dep)
				}
				dlldeps[strings.ToLower(di.Name())] = deps
				//fmt.Println(di.Name(), deps)
			}

			var it int
			for {
				remove := map[string][]string{}
				for _, name := range slices.Sorted(maps.Keys(dlldeps)) { // sorted so it's deterministic if there are errors
					for _, dep := range dlldeps[name] {
						if _, ok := dlldeps[dep]; !ok {
							remove[name] = append(remove[name], dep)
						}
					}
				}
				if len(remove) == 0 {
					break
				}
				for name, deps := range remove {
					slog.Debug("removing", "iteration", it, "name", name, "broken_deps", deps)
					if err := os.Remove(filepath.Join(dir, uncase[name])); err != nil {
						return err
					}
					delete(dlldeps, name)
				}
				it++
			}
			return nil
		}(); err != nil {
			return err
		}
	}

	slog.Info("patching wine.inf")
	// 	- mostly so wineboot doesn't complain as much or error out
	// 	- a little bit of extra tidying
	if err := transform(filepath.Join(*Prefix, "share/wine/wine.inf"),
		trdiff(infilt(func(emit func(section string, line string), inf iter.Seq2[string, string]) error {
			services := "BITS|EventLog|HTTP|MSI|NDIS|NsiProxy|RpcSs|ScardSvr|Spooler|Winmgmt|Sti|PlugPlay|WPFFontCache|LanmanServer|FontCache|TaskScheduler|wuau|Terminal"
			for section, line := range inf {
				{
					var keep bool
					switch {
					case strings.HasSuffix(section, "Install.NT"):
					case strings.HasSuffix(section, "Install.NT.Services"):
					case (!arm64 || *Optimize) && strings.HasSuffix(section, "Install.ntarm"):
					case (!arm64 || *Optimize) && strings.HasSuffix(section, "Install.ntarm.Services"):
					case !arm64 && strings.HasSuffix(section, "Install.ntarm64"):
					case !arm64 && strings.HasSuffix(section, "Install.ntarm64.Services"):
					case *Optimize && strings.Contains(section, "CurrentVersionWow64"):
					case *Optimize && strings.Contains(section, "Wow64Install"):
					case *Optimize && strings.Contains(section, "FakeDllsWin32"):
					case *Optimize && strings.Contains(section, "FakeDllsWow64"):
					case regex(`^(` + services + `)(Services?|ServiceKeys)$`).MatchString(section):
					default:
						keep = true
					}
					if !keep {
						continue // ignore entire section
					}
				}
				if line != "" {
					var keep bool
					switch {
					default:
						keep = true
					case strings.Contains(line, "winemenubuilder"):
					case *Optimize && section == "Tapi": // telephony
					case *Optimize && section == "DirectX":
					case *Optimize && regex(`CurrentVersionWow64.[^.]+,`).MatchString(line):
					case regex(`(^|[^a-z])wineps\.drv`).MatchString(line):
					case regex(`(^|[^a-z])(sane|gphoto2)\.ds`).MatchString(line):
					case regex(`(^|[^a-z])(input|winebus|winebth|winehid|mouhid|wineusb|winexinput)\.inf`).MatchString(line):
					case regex(`(^|[^a-z])(oledb32|msdaps|msdasql|msado15|winprint|sapi)\.dll`).MatchString(line):
					case regex(`(^|[^a-z])(wmplayer|wordpad|iexplore)\.exe`).MatchString(line):
					case regex(`^system\.ini,\s*(mci|drivers32|mail)`).MatchString(line):
					case regex(`^AddService=.+,(` + services + `)(Services?)$`).MatchString(section):
					}
					if !keep {
						continue // ignore section contents
					}
				}
				emit(section, line)
			}
			return nil
		})),
	); err != nil {
		return err
	}

	slog.Info("disabling automatic wineprefix updates")
	if err := os.WriteFile(filepath.Join(*Output, ".update-timestamp"), []byte("disable\n"), 0644); err != nil {
		return err
	}

	return nil
}
