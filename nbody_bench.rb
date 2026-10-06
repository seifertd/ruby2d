# Headless benchmark of nbody.rb's physics (NBody#update), for comparing Ruby
# versions and JITs. Stubs just enough of Gosu to construct the window object
# without opening one, then loads nbody.rb unmodified apart from its
# `require 'gosu'` and final `.show` lines. The seed is fixed, so every run
# simulates the same bodies, and the final body count and energy printed at the
# end must match between runs -- a JIT must not change the answer.
#
#   ruby [--yjit] nbody_bench.rb UPDATES SCENARIO_ARGS...
#   ruby --yjit nbody_bench.rb 8 random 50 1
#   ruby --yjit nbody_bench.rb 20 moons 5 3
#   ruby --yjit nbody_bench.rb 20 solar
#
# Set NBODY_GC=1 to also report time spent in GC and objects allocated.
#
# Results, 2026-10-06, best of 3, Legion Y540 (i7-9750H):
#
#   scenario (updates)     3.4.9    3.4.9+YJIT   4.0.6    4.0.6+YJIT
#   random 50 1 (8)        6.27s    3.98s        6.03s    3.71s
#   moons 5 3 (20)         2.52s    1.60s        2.43s    1.50s
#   solar (20)             2.29s    1.45s        2.23s    1.36s
#
# YJIT is ~1.6x on either version; 3.4 -> 4.0 alone is only 4-7%.
#
# GC notes -- not done, this is a toy, but this is where the remaining time
# goes. Under YJIT, `random 50 1` spends 0.82s of 3.75s (22%) in GC after
# allocating 19 million objects, and a JIT can't speed that part up. Almost all
# of it comes from the O(n^2) pair loop in NBody#update:
#
#   * `( body2.pos - body.pos ).magnitude` builds a Vector (and an Array inside
#     Vector#-) just to get a distance, and the very next line computes the same
#     distance again with Math.sqrt. Computing dx, dy and d once as plain Floats
#     and reusing d for the potential energy removes both allocations.
#   * `acc_vect * scalar` goes through Vector#*, which does
#     `[@x, @y, @z].compact.map { ... }` -- two throwaway Arrays plus a new
#     Vector -- and `acc_vect` itself is a fresh Vector. Adding
#     dx / d * (G * m2 / d2) straight into body.acc.x and body.acc.y needs no
#     objects at all.
#   * Vector#initialize takes `*coords` and calls `coords.flatten!`, so every
#     Vector costs an extra Array. A fixed `initialize(x, y, z = nil)` (with the
#     Array form handled separately where it's actually used) avoids that.
#   * `barycenter` runs every tick and allocates two Vectors per body via
#     `body.pos * body.mass` and `+`; summing mass-weighted x and y as Floats
#     does the same without allocating.
#
# With the pair loop allocation-free, GC should mostly disappear from the
# profile and the YJIT speedup should grow well past 1.6x.
module Gosu
  class Window
    def initialize(*) = nil
    def caption=(_); end
  end
  class Font
    def initialize(*) = nil
  end
  def self.default_font_name = "stub"
end

updates = Integer(ARGV.shift)
srand(42)

path = File.expand_path("nbody.rb", __dir__)
src = File.read(path)
  .sub(/^require 'gosu'$/, "")                    # use the stub above instead
  .sub(/^NBody\.new\(600,600\)\.show\s*\z/, "")   # don't open a window
raise "could not strip the gosu/show lines" if src.include?(".show") || src.include?("require 'gosu'")

real_stdout = $stdout
$stdout = File.open(File::NULL, "w") # setup and collisions print a lot
eval(src, TOPLEVEL_BINDING, path)
sim = NBody.new(600, 600)

t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
updates.times { sim.update }
secs = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
$stdout = real_stdout

jit = defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled? ? "yjit" : "interp"
printf("%-6s %-7s %7.3fs  bodies=%d energy=%.10e\n",
       RUBY_VERSION, jit, secs, sim.bodies.size, sim.energy)
if ENV["NBODY_GC"]
  gc_secs = GC.stat(:time) / 1000.0
  printf("GC: %.2fs of %.2fs (%.0f%%), %d objects allocated\n",
         gc_secs, secs, 100 * gc_secs / secs, GC.stat(:total_allocated_objects))
end
