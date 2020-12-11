class Simgrid < Formula
  include Language::Python::Shebang

  desc "Studies behavior of large-scale distributed systems"
  homepage "https://simgrid.org/"
  url "https://framagit.org/simgrid/simgrid/uploads/0365f13697fb26eae8c20fc234c5af0e/SimGrid-3.25.tar.gz"
  sha256 "0b5dcdde64f1246f3daa7673eb1b5bd87663c0a37a2c5dcd43f976885c6d0b46"
  revision 2

  livecheck do
    url "https://framagit.org/simgrid/simgrid.git"
    regex(/^v?(\d+(?:[._]\d+)+)$/i)
  end

  bottle do
    sha256 "beea9ed8a14d679d2f9aef9be80b61cfe152e0cc1078837ef6c1c1e5f5c04c94" => :big_sur
    sha256 "f735fe9ac565cd1fe49b9117be9ca64a3a15a8dd69dbbf2a4385a82bfd201b4e" => :catalina
    sha256 "9fa0989ffe0e2018e105f8a22ab9e9178bc456dd5430d8468866c6b57ed3bf26" => :mojave
    sha256 "eefddfa608d34b725af614af41a93ca017a761f877257300b182df0f56ad6bfe" => :high_sierra
  end

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "boost"
  depends_on "graphviz"
  depends_on "pcre"
  depends_on "python@3.9"

  def install
    # Avoid superenv shim references
    inreplace "src/smpi/smpicc.in", "@CMAKE_C_COMPILER@", "/usr/bin/clang"
    inreplace "src/smpi/smpicxx.in", "@CMAKE_CXX_COMPILER@", "/usr/bin/clang++"

    # FindPythonInterp is broken in CMake 3.19+
    # REMOVE ME AT VERSION BUMP (after 3.25)
    # https://framagit.org/simgrid/simgrid/-/issues/59
    # https://framagit.org/simgrid/simgrid/-/commit/3a987e0a881dc1a0bb5a6203814f7960a5f4b07e
    inreplace "CMakeLists.txt", "include(FindPythonInterp)", ""
    python = Formula["python@3.9"]
    python_version = python.version
    # We removed CMake's ability to find Python, so we have to point to it ourselves
    args = %W[
      -DPYTHONINTERP_FOUND=TRUE
      -DPYTHON_EXECUTABLE=#{python.opt_bin}/python3
      -DPYTHON_VERSION_STRING=#{python_version}
      -DPYTHON_VERSION_MAJOR=#{python_version.major}
      -DPYTHON_VERSION_MINOR=#{python_version.minor}
      -DPYTHON_VERSION_PATCH=#{python_version.patch}
    ]
    # End of local workaround, remove the above at version bump

    system "cmake", ".",
                    "-Denable_debug=on",
                    "-Denable_compile_optimizations=off",
                    "-Denable_fortran=off",
                    *std_cmake_args,
                    *args # Part of workaround, remove at version bump
    system "make", "install"

    bin.find { |f| rewrite_shebang detected_python_shebang, f }
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <stdio.h>
      #include <stdlib.h>
      #include <simgrid/engine.h>

      int main(int argc, char* argv[]) {
        printf("%f", simgrid_get_clock());
        return 0;
      }
    EOS

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lsimgrid",
                   "-o", "test"
    system "./test"
  end
end
