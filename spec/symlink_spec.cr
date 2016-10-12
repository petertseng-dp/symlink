require "spec"
require "../symlink"

CASES = [
  {
    {
      "/bin/thing" => "/bin/thing-3",
      "/bin/thing-3" => "/bin/thing-3.2",
      "/bin/thing-3.2/include" => "/usr/include",
      "/usr/include/SDL" => "/usr/local/include/SDL",
    },
    "/bin/thing/include/SDL/stan",
    "/usr/local/include/SDL/stan",
  },
  {
    {
      "/home/elite/documents" => "/media/mmcstick/docs",
    },
    "/home/elite/documents/office",
    "/media/mmcstick/docs/office",
  },
  {
    {
      "/bin" => "/usr/bin",
      "/usr/bin" => "/usr/local/bin/",
      "/usr/local/bin/log" => "/var/log-2014",
    },
    "/bin/log/rc",
    "/var/log-2014/rc",
  },
  {
    {
      "/bin/thing" => "/bin/thing-3",
      "/bin/thing-3" => "/bin/thing-3.2",
      "/bin/thing/include" => "/usr/include",
      "/bin/thing-3.2/include/SDL" => "/usr/local/include/SDL",
    },
    "/bin/thing/include/SDL/stan",
    "/usr/local/include/SDL/stan",
  },
  {
    {
      "/bin" => "/usr/bin",
    },
    "/bin-but-not-really/data",
    "/bin-but-not-really/data",
  },
  {
    {
      "/bin" => "/usr/bin",
    },
    "/bin/application/bin/data",
    "/usr/bin/application/bin/data",
  },
]

FAIL_CASES = [
  {
    {
      "/etc" => "/tmp/etc",
      "/tmp/etc/" => "/etc/",
    },
    "/etc/modprobe.d/config/",
  },
]

[Symlinks, Filesystem].each { |class_under_test|
  describe class_under_test do
    it "resolves" do
      CASES.each { |links, input, expected|
        s = class_under_test.new
        links.each { |l| s.ln_s(*l) }
        s.readlink(input).should eq(expected)
      }
    end

    it "fails" do
      FAIL_CASES.each { |links, input|
        s = class_under_test.new
        links.each { |l| s.ln_s(*l) }
        expect_raises(Exception) { s.readlink(input) }
      }
    end
  end
}
