package main

import (
	"bufio"
	"bytes"
	"encoding/binary"
	"fmt"
	"io"
	"iter"
	"os"
	"regexp"
	"runtime"
	"slices"
	"strconv"
	"strings"
	"sync"
	"unicode/utf16"

	"github.com/rogpeppe/go-internal/diff"
	"github.com/willscott/pefile-go"
)

// architectures
const (
	amd64 = runtime.GOARCH == "amd64"
	arm64 = runtime.GOARCH == "arm64"
)

// arct returns the parameter corresponding to the current architecture.
func archt[T any](amd64, arm64 T) T {
	switch goarch := runtime.GOARCH; goarch {
	case "amd64":
		return amd64
	case "arm64":
		return arm64
	default:
		panic("unknown architecture " + goarch)
	}
}

// u8to16 converts utf8 to utf16.
func u8to16[T, U ~[]byte | ~string](str T) U {
	r := utf16.Encode([]rune(string(str)))
	b := make([]byte, 0, len(r)*2)
	for _, r := range r {
		b = binary.LittleEndian.AppendUint16(b, r)
	}
	return U(b)
}

// transform calls fn on the contents of the specified file, replacing it.
func transform(name string, fn func(buf []byte) ([]byte, error)) error {
	buf, err := os.ReadFile(name)
	if err != nil {
		return err
	}
	buf, err = fn(buf)
	if err != nil {
		return fmt.Errorf("transform %q: %w", name, err)
	}
	if err := os.WriteFile(name, buf, 0644); err != nil {
		return err
	}
	return nil
}

// trdiff wraps a transform to emit a colored diff.
func trdiff(fn func(buf []byte) ([]byte, error)) func(buf []byte) ([]byte, error) {
	return func(buf []byte) ([]byte, error) {
		old := slices.Clone(buf)
		new, err := fn(buf)
		if err != nil {
			return nil, err
		}
		colordiff(os.Stdout, "  \x1b[34m| ", "a", old, "b", new)
		return new, nil
	}
}

// infilt filters an INF file. Line will always be non-empty (it includes the
// trailing newline) unless the line is a section header. If a line is emitted
// with a different section, the section header is emitted automatically. If a
// line is emitted without a trailing newline, it is added. If a line is emitted
// without a section, the current section is assumed.
func infilt(fn func(emit func(section, line string), inf iter.Seq2[string, string]) error) func(buf []byte) ([]byte, error) {
	return func(buf []byte) ([]byte, error) {
		if bytes.Contains(buf, []byte("\r")) {
			return nil, fmt.Errorf("expected linux-style newlines")
		}
		in := func(yield func(string, string) bool) {
			var cur string
			for line := range bytes.Lines(buf) {
				if section, ok := bytes.CutPrefix(line, []byte{'['}); ok {
					if section, ok := bytes.CutSuffix(section, []byte{']', '\n'}); ok {
						cur = string(section)
						if !yield(cur, "") {
							return
						}
						continue
					}
				}
				if !yield(cur, string(line)) {
					return
				}
			}
		}
		var res bytes.Buffer
		var cur string
		if err := fn(func(section, line string) {
			if section == "" && line == "" {
				panic("emitted empty section/line")
			}
			if line != "" && !strings.HasSuffix(line, "\n") {
				panic("line must end with newline")
			}
			if section != "" && (line == "" || cur != section) {
				res.WriteString("[" + section + "]\n")
				cur = section
			}
			if line != "" {
				res.WriteString(line)
			}
		}, in); err != nil {
			return nil, fmt.Errorf("filter inf: %w", err)
		}
		return res.Bytes(), nil
	}
}

// unindent unindents a tab-indented multiline string.
func unindent(s string) string {
	s, ok := strings.CutPrefix(s, "\n")
	if !ok {
		panic("doesn't start on a new line")
	}

	d := strings.TrimLeft(s, "\t")
	if len(d) == len(s) {
		panic("doesn't start with an indented line")
	}
	d = s[:len(s)-len(d)]

	e := strings.TrimRight(s, "\t")
	if len(s)-len(e) != len(d)-1 {
		panic("last line isn't indented enough")
	}
	if !strings.HasSuffix(e, "\n") {
		panic("last line is indented too much")
	}
	s = e

	var b strings.Builder
	b.Grow(len(s))
	for l := range strings.Lines(s) {
		if l != "\n" {
			if l, ok = strings.CutPrefix(l, d); !ok {
				panic("line " + strconv.Quote(l) + " is not indented with " + strconv.Quote(d))
			}
		}
		b.WriteString(l)
	}
	return b.String()
}

// colordiff writes a coloured diff to w.
func colordiff(w io.Writer, indent string, oldName string, old []byte, newName string, new []byte) error {
	bw := bufio.NewWriter(w)
	if _, err := bw.WriteString("\x1b[2m"); err != nil {
		return err
	}
	for line := range bytes.Lines(diff.Diff(oldName, old, newName, new)) {
		if len(line) != 0 {
			if _, err := bw.WriteString(indent); err != nil {
				return err
			}
			var err error
			switch line[0] {
			default:
				_, err = bw.WriteString("\x1b[30m")
			case '-':
				_, err = bw.WriteString("\x1b[31m")
			case '+':
				_, err = bw.WriteString("\x1b[32m")
			}
			if err != nil {
				return err
			}
		}
		if _, err := bw.Write(bytes.TrimSuffix(line, []byte{'\n'})); err != nil {
			return err
		}
		if _, err := bw.WriteString("\x1b[0m\n"); err != nil {
			return err
		}
	}
	if _, err := bw.WriteString("\x1b[0m"); err != nil {
		return err
	}
	return bw.Flush()
}

// peImports gets the list of imported libraries for a DLL or EXE.
func peImports(name string) ([]string, error) {
	pe, err := pefile.NewPEFile(name)
	if err != nil {
		return nil, err
	}
	var libs []string
	for _, imp := range pe.ImportDescriptors {
		libs = append(libs, string(imp.Dll))
	}
	return libs, nil
}

var reCache sync.Map

func regex(re string) *regexp.Regexp {
	v, ok := reCache.Load(re)
	if !ok {
		v, _ = reCache.LoadOrStore(re, regexp.MustCompile(re))
	}
	return v.(*regexp.Regexp)
}
