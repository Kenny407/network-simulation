set ns [new Simulator]

set out [open leakybucket.tr w]
$ns trace-all $out

set out2 [open lossrate.tr a]

proc finish {} {
  global ns R out out2 b lossRate dynamicN tokenRate
  puts "Burstiness: $b Time: $tokenRate  Queue Size: $dynamicN  R: $R  Loss Rate: $lossRate"
  puts $out2 "$b $tokenRate $dynamicN $R $lossRate"
  $ns flush-trace
  close $out
  close $out2
  exit 0
}

#packet size
set L 100

#ON period (ms)
set Ton 0.4

#OFF period (ms)
set Toff 0.6

#burstiness
set b [expr [expr $Ton + $Toff] / $Ton]

#source mean rate (Mb)
set meanRate 1

#define R as meanRate
set R [lindex $argv 0]

#token rate
set tokenRate [expr 1 / $R]
#set tokenRate 0.000362

#source peak rate
set peakRate [expr $meanRate * $b]Mb

# bucket size (packets)
set N 1500

#current N
set dynamicN 0

#nodes
set psource [$ns node]; # Poisson ON/OFF node
set ndest [$ns node];   # Destination Node

#link between the nodes
$ns simplex-link $psource $ndest 1Gb 0.000001ms DropTail

# token source queue
$ns queue-limit $psource $ndest $dynamicN

#Poisson Agent
set poissonSourceAgent [new Agent/UDP]
$poissonSourceAgent set fid_ 1
$ns attach-agent $psource $poissonSourceAgent

#destination node
set destAgent [new Agent/Null]
$ns attach-agent $ndest $destAgent

$ns connect $poissonSourceAgent $destAgent

#Poisson traffic
set poissonTraffic [new Application/Traffic/Exponential]
$poissonTraffic set packetSize_ $L
$poissonTraffic set rate_ $peakRate
$poissonTraffic set burst_time_ $Ton; # $Ton
$poissonTraffic set idle_time_ $Toff
$poissonTraffic attach-agent $poissonSourceAgent

#Calculation of Loss Rate
set nbemissions 0
set nblosses 0
set lossRate 0

proc tokenGenerator { } {
  global N dynamicN ns psource ndest tokenRate
  if { $dynamicN < $N } {
    set dynamicN [expr $dynamicN + 1]
    $ns queue-limit $psource $ndest $dynamicN
  }

  # call itself t times later
  $ns at [expr [$ns now] + $tokenRate] "tokenGenerator"
}

proc myproc { a } {
  global nbemissions nblosses lossRate dynamicN ns psource ndest
  set x [lindex $a 0]

  #enqueue
  if {$x == "+"} {
    set nbemissions [expr $nbemissions + 1]
    set lossRate [expr $nblosses * 1.0 / $nbemissions]
  }

  #drop
  if {$x == "d"} {
    set nblosses [expr $nblosses + 1]
    set lossRate [expr $nblosses * 1.0 / $nbemissions]
  }

  # a packet left
  if { $x == "-" } {
    # check if the queue can't get negative values
    if { $dynamicN > 0 } {
      set dynamicN [expr $dynamicN - 1 ]
      $ns queue-limit $psource $ndest $dynamicN
    }
  }
}

[$ns link $psource $ndest] trace-callback $ns "myproc"

$ns at 0.0 "$poissonTraffic start"; # start the poisson ON/OFF traffic
$ns at 0.0 "tokenGenerator";        # start the token generator
$ns at 100.0 "$poissonTraffic stop";# stop at 100s.
$ns at 100.0 "finish";              # stop running
$ns run;                            # run the program
