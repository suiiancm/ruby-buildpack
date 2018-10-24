package integration_test

import (
	"path/filepath"

	"github.com/cloudfoundry/libbuildpack/cutlass"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("running supply go buildpack before the ruby buildpack", func() {
	var app *cutlass.App
	AfterEach(func() {
		if app != nil {
			app.Destroy()
		}
		app = nil
	})

	Context("the app is pushed", func() {
		BeforeEach(func() {
			if ok, err := cutlass.ApiGreaterThan("2.65.1"); err != nil || !ok {
				Skip("API version does not have multi-buildpack support")
			}
			app = cutlass.New(filepath.Join(bpDir, "fixtures", "ruby_calls_go"))
			app.Buildpacks = []string{
				"https://github.com/cloudfoundry/go-buildpack#develop",
				"ruby_buildpack",
			}
			app.Disk = "1G"
		})

		It("finds the supplied dependency in the runtime container", func() {
			PushAppAndConfirm(app)

			Expect(app.Stdout.String()).To(ContainSubstring("Go Buildpack version"))
			Expect(app.Stdout.String()).To(MatchRegexp("Installing ruby \\d+\\.\\d+\\.\\d+"))

			Expect(app.GetBody("/")).To(MatchRegexp("RUBY_VERSION IS \\d+\\.\\d+\\.\\d+"))
			Expect(app.GetBody("/")).To(MatchRegexp("go version go\\d+\\.\\d+\\.\\d+"))
		})
	})
})
