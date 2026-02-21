package main

import (
	"iter"
	"strings"
	"testing"
)

func TestInfilt(t *testing.T) {
	test := func(name, input, output string, filter func(buf []byte) ([]byte, error)) {
		t.Run(name, func(t *testing.T) {
			buf, err := filter([]byte(input))
			if err != nil {
				t.Errorf("unexpected error: %v", err)
			}
			if act := string(buf); output != act {
				t.Errorf("wrong output:\n%s", act)
			}
		})
	}
	input := unindent(`
		; test

		[Section]
		sdfsdf,asdasd,dfgdfg


		[Section2]
		[Section2]
		dfkmgkldmfg,werwer
		[Section2]
		erktjnekjrntasd
	`)
	test("Passthrough",
		input,
		input,
		infilt(func(emit func(section string, line string), inf iter.Seq2[string, string]) error {
			for section, line := range inf {
				emit(section, line)
			}
			return nil
		}),
	)
	test("PassthroughImplicit",
		input,
		unindent(`
			; test

			[Section]
			sdfsdf,asdasd,dfgdfg


			[Section2]
			dfkmgkldmfg,werwer
			erktjnekjrntasd
		`),
		infilt(func(emit func(section string, line string), inf iter.Seq2[string, string]) error {
			for section, line := range inf {
				if line != "" {
					emit(section, line)
				}
			}
			return nil
		}),
	)
	test("RemoveSection",
		input,
		unindent(`
			; test

			[Section2]
			[Section2]
			dfkmgkldmfg,werwer
			[Section2]
			erktjnekjrntasd
		`),
		infilt(func(emit func(section string, line string), inf iter.Seq2[string, string]) error {
			for section, line := range inf {
				if section == "Section" {
					continue
				}
				emit(section, line)
			}
			return nil
		}),
	)
	test("RemoveLine",
		input,
		unindent(`
			; test

			[Section]


			[Section2]
			[Section2]
			dfkmgkldmfg,werwer
			[Section2]
		`),
		infilt(func(emit func(section string, line string), inf iter.Seq2[string, string]) error {
			for section, line := range inf {
				if strings.Contains(line, "asd") {
					continue
				}
				emit(section, line)
			}
			return nil
		}),
	)
	test("RemoveLineImplicit",
		input,
		unindent(`
			; test

			[Section]


			[Section2]
			dfkmgkldmfg,werwer
		`),
		infilt(func(emit func(section string, line string), inf iter.Seq2[string, string]) error {
			for section, line := range inf {
				if line == "" {
					continue
				}
				if strings.Contains(line, "asd") {
					continue
				}
				emit(section, line)
			}
			return nil
		}),
	)
	test("Complex",
		input,
		unindent(`
			; test

			[Section]
			sdfskjdfnksjndf
			ertert


			[Section2]
			dfkmgkldmfg,werwer
			[Section3]
			dflgmldkfmg
		`),
		infilt(func(emit func(section string, line string), inf iter.Seq2[string, string]) error {
			for section, line := range inf {
				if section == "Section" && line == "" {
					emit(section, "sdfskjdfnksjndf\n")
					emit(section, "ertert\n")
				}
				if line != "" {
					if strings.Contains(line, "asd") {
						continue
					}
					emit(section, line)
				}
			}
			emit("Section3", "dflgmldkfmg\n")
			return nil
		}),
	)
}
