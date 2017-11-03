set ns [new Simulator]

set out [open tracefile.tr w]
$ns trace-all $out

set out2 [open KVsLossRate.tr a]

proc finish {} {
    global ns out K lossRate out2
    puts $out2 "$K $lossRate"
    $ns flush-trace
    close $out
    close $out2
    exit 0
}

#Buffer size
set K [lindex $argv 0]
#burstiness 
set b 5
#ON period (ms)
set Ton 1
#OFF period (ms)
set Toff [expr $b * $Ton - $Ton]ms
#packet size (byte)
set L 1000
#source mean rate
set meanRate 20
#source peak rate
set peakRate [expr $meanRate * $b]Mb

#nodes
set onOffSrc [$ns node]
set poissonSrc [$ns node]
set na [$ns node]
set ndest [$ns node]

#link between the nodes
$ns simplex-link $onOffSrc $na 1Gb 0.00001ms DropTail
$ns simplex-link $poissonSrc $na 1Gb 0.00001ms DropTail
$ns simplex-link $na $ndest 70Mb 0.00001ms DropTail
$ns queue-limit $na $ndest $K

#Agents

#for ON/OFF Source
set onOffSrcAgent [new Agent/UDP]
$onOffSrcAgent set fid_ 1
$ns attach-agent $onOffSrc $onOffSrcAgent

set onOffDestAgent [new Agent/Null]
$ns attach-agent $ndest $onOffDestAgent 
$ns connect $onOffSrcAgent $onOffDestAgent

#for Poisson Source
set poissonSrcAgent [new Agent/UDP]
$poissonSrcAgent set fid_ 2
$ns attach-agent $poissonSrc $poissonSrcAgent

set poissonDestAgent [new Agent/Null]
$ns attach-agent $ndest $poissonDestAgent

$ns connect $poissonSrcAgent $poissonDestAgent

#ON/OFF Traffic
set onOffTraffic [new Application/Traffic/Exponential]
$onOffTraffic set packetSize_ $L
$onOffTraffic set rate_ $peakRate
$onOffTraffic set burst_time_ 1ms
$onOffTraffic set idle_time_ $Toff
$onOffTraffic attach-agent $onOffSrcAgent

#Poisson Traffic
set poissonTraffic [new Application/Traffic/Exponential]
$poissonTraffic set packetSize_ $L
$poissonTraffic set rate_ 9999Mb
$poissonTraffic set burst_time_ 0ms
$poissonTraffic set idle_time_ 0.4ms 
$poissonTraffic attach-agent $poissonSrcAgent

#Calculation of Loss Rate
set nbemissions 0
set nblosses 0
set lossRate 0

proc myproc { a } {
    global nbemissions nblosses lossRate
    set x [lindex $a 0]
    if { $x == "+"} {
        set nbemissions [expr $nbemissions + 1]
        set lossRate [expr $nblosses * 1.0 / $nbemissions]
    }

    if { $x == "d"} {
        set nblosses [expr $nblosses + 1]
        set lossRate [expr $nblosses * 1.0 / $nbemissions]
    }
}

[$ns link $na $ndest] trace-callback $ns "myproc"

$ns at 0.0 "$onOffTraffic start"
$ns at 0.0 "$poissonTraffic start"
$ns at 100.0 "$onOffTraffic stop"
$ns at 100.0 "$poissonTraffic stop"
$ns at 100.0 "finish"
$ns run