class ${FORMULA_CLASS} < Formula
  desc "Cross-compilation toolchain for x86_64-linux-musl target"
  homepage "https://github.com/aar10n/x86_64-linux-musl"
  url "https://github.com/aar10n/x86_64-linux-musl/archive/refs/tags/${VERSION_TAG}.tar.gz"
  sha256 "${SOURCE_SHA256}"
  license "MIT"

  bottle do
    root_url "https://github.com/aar10n/homebrew-x86_64-linux-musl/releases/download/${VERSION_TAG}"
    sha256 cellar: :any, arm64_sonoma: "${BOTTLE_SHA256}"
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

    # Set up local.mk to override installation directory
    local_mk = <<~EOS
      TOOL_ROOT = #{prefix}
      BUILD_DIR = #{buildpath}/build
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
    system "make", "autoconf", "binutils", "gcc", "musl"

    # Remove unprefixed autoconf binaries to avoid conflicts
    # autoconf is built as a prerequisite but shouldn't be in the final installation
    Dir.glob(prefix/"bin/autoconf*").each { |f| File.delete(f) }
    Dir.glob(prefix/"bin/autom4te*").each { |f| File.delete(f) }
    Dir.glob(prefix/"bin/auto{header,reconf,scan,update}").each { |f| File.delete(f) if File.exist?(f) }
    Dir.glob(prefix/"bin/ifnames").each { |f| File.delete(f) if File.exist?(f) }

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
        - GCC (C and C++ support)
        - musl libc
    EOS
  end
end
