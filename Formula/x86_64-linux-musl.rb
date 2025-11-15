class X8664LinuxMusl < Formula
  desc "Cross-compilation toolchain for x86_64-linux-musl target"
  homepage "https://github.com/aar10n/x86_64-linux-musl"
  url "https://github.com/aar10n/x86_64-linux-musl/archive/refs/tags/12.1.0"
  sha256 "5a02b02d1ff21a7086c9efc27d1c5782e3480c9b68285a421b0e492b522e7f56"
  license "MIT"

  bottle do
    root_url "https://github.com/aar10n/x86_64-linux-musl/releases/download/12.1.0"
    sha256 cellar: :any, arm64_sonoma: "ab7cc1777cc2f17707f50e20bbab176e67dd9efba0418e19b43e59c1287904e9"
  end

  depends_on "wget" => :build
  depends_on "coreutils" => :build
  depends_on "gnu-sed" => :build
  depends_on "make" => :build
  depends_on "texinfo" => :build
  depends_on "bison" => :build
  depends_on "flex" => :build
  depends_on "gcc@14" => :build
  depends_on "gmp"
  depends_on "mpfr"
  depends_on "libmpc"
  depends_on "isl"

  keg_only :provided_by_macos, "to avoid conflicts with other toolchains"

  def install
    # Use real GCC if available (not clang)
    gcc_14 = Formula["gcc@14"] if Formula["gcc@14"].any_version_installed?
    gcc_13 = Formula["gcc@13"] if Formula["gcc@13"].any_version_installed?
    gcc_12 = Formula["gcc@12"] if Formula["gcc@12"].any_version_installed?

    real_gcc = gcc_14 || gcc_13 || gcc_12

    unless real_gcc
      opoo "No GCC found. Attempting to use system compiler."
    end

    # Set up local.mk to override installation directory and musl source
    local_mk = <<~EOS
      TOOL_ROOT = #{prefix}
      BUILD_DIR = #{buildpath}/build
      MUSL_GIT_URL = git://git.musl-libc.org/musl
      MUSL_GIT_BRANCH = master
    EOS

    if real_gcc
      gcc_bin = "#{real_gcc.opt_bin}/gcc-#{real_gcc.version.major}"
      gxx_bin = "#{real_gcc.opt_bin}/g++-#{real_gcc.version.major}"
      local_mk += <<~EOS
        HOST_CC = #{gcc_bin}
        HOST_CXX = #{gxx_bin}
      EOS
    end

    (buildpath/"local.mk").write local_mk

    # Build the toolchain using make directly
    system "make", "autoconf", "binutils", "gcc", "musl", "libtool"

    # Verify installation
    raise "Toolchain installation failed" unless (prefix/"bin/x86_64-linux-musl-gcc").exist?
  end

  test do
    (testpath/"hello.c").write <<~EOS
      #include <stdio.h>
      int main() {
        printf("Hello, musl!\\n");
        return 0;
      }
    EOS

    system "#{bin}/x86_64-linux-musl-gcc", "-static", "hello.c", "-o", "hello"
    assert_predicate testpath/"hello", :exist?

    output = shell_output("file hello")
    assert_match(/ELF.*x86-64.*statically linked/, output)
  end

  def caveats
    <<~EOS
      The x86_64-linux-musl toolchain has been installed to:
        #{opt_prefix}

      Add the toolchain to your PATH:
        export PATH="#{opt_prefix}/bin:$PATH"

      Or use the cross-compilation prefix directly:
        x86_64-linux-musl-gcc hello.c -o hello

      The toolchain includes:
        - binutils 2.38 (assembler, linker, etc.)
        - GCC 12.1.0 (C and C++ support)
        - musl libc (official musl-libc.org source)
        - Additional build tools (autoconf, libtool)

      To compile static binaries:
        x86_64-linux-musl-gcc -static myprogram.c -o myprogram

      To see toolchain info:
        x86_64-linux-musl-gcc --version
        x86_64-linux-musl-ld --version
    EOS
  end
end
