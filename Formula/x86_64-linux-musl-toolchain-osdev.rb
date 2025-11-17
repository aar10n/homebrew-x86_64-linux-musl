class X8664LinuxMuslToolchainOsdev < Formula
  desc "Cross-compilation toolchain for x86_64-linux-musl target (osdev variant)"
  homepage "https://github.com/aar10n/x86_64-linux-musl"
  url "file:///dev/null"
  sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  version "12.1.0-osdev"
  license "MIT"

  # This is a wrapper formula that depends on the versioned formula
  depends_on "aar10n/x86_64-linux-musl/x86_64-linux-musl-toolchain-osdev@12"

  def install
    # This formula is a wrapper around the versioned formula
    # The actual toolchain is provided by the dependency

    # Get the versioned formula's opt_prefix
    versioned_formula = Formula["aar10n/x86_64-linux-musl/x86_64-linux-musl-toolchain-osdev@12"]

    # Create a marker file to indicate this is a wrapper installation
    (prefix/"WRAPPER_FORMULA").write <<~EOS
      This is a wrapper formula that provides the default (non-versioned) installation.

      The actual toolchain is provided by: x86_64-linux-musl-toolchain-osdev@12
      Toolchain location: #{versioned_formula.opt_prefix}
    EOS

    # Symlink only binaries, not entire directories (to avoid Homebrew post-processing issues)
    Dir.glob("#{versioned_formula.opt_bin}/*").each do |binary|
      bin.install_symlink binary
    end
  end

  test do
    # Test that the symlinked gcc works
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
    versioned_formula = Formula["aar10n/x86_64-linux-musl/x86_64-linux-musl-toolchain-osdev@12"]

    <<~EOS
      This is a wrapper formula for x86_64-linux-musl-toolchain-osdev@12.

      The x86_64-linux-musl toolchain has been installed to:
        #{opt_prefix}

      The actual toolchain is located at:
        #{versioned_formula.opt_prefix}

      Add the toolchain to your PATH:
        export PATH="#{opt_prefix}/bin:$PATH"

      Or use the cross-compilation prefix directly:
        x86_64-linux-musl-gcc hello.c -o hello

      The toolchain includes:
        - binutils
        - gcc
        - musl libc
    EOS
  end
end
