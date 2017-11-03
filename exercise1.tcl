set ns [new Simulator]

set out [open statistics.tr a]

proc finish {} {
    global ns out lossRate sumPacks sumServ throughput received avgTime b meanRate K
    set avgPacksInSys [expr $sumPacks / [$ns now]]
    set avgInService [expr $sumServ / [$ns now]]
    set avgWaiting [expr $avgPacksInSys - $avgInService]
    set avgTime [expr $avgTime / $received]
    set little [expr $avgPacksInSys / $throughput]
    puts $out "##############################################################################"
    puts $out "for burstiness = $b, buffer size = $K and source mean rate = $meanRate Mb"
    puts $out "avg time spent in the system: $avgTime seconds"
    puts $out "value found by little's formula: $little"
    puts $out "lossRate: $lossRate" 
    puts $out "avg # of packets in system: $avgPacksInSys"
    puts $out "avg # of packets in service: $avgInService"
    puts $out "avg # of packets warning: $avgWaiting"
    puts $out "throughput of the system: $throughput packets/second"
    puts $out "##############################################################################"
    $ns flush-trace
    close $out 
    exit 0
}

#buffer size
set K 10
#burstiness = 4, K = 10
set b 4
#ON period (ms)
set Ton 1
#OFF period (ms)
set Toff [expr $b * $Ton - $Ton]ms
#packet size (byte)
set L 1000
#source mean rate (Mb)
set meanRate 40
#source peak rate
set peakRate [expr $meanRate * $b]Mb

#nodes
set nsource [$ns node]
set ndest [$ns node]

#link between the nodes
$ns simplex-link $nsource $ndest 150Mb 0ms DropTail
$ns queue-limit $nsource $ndest $K

#agents
set sourceAgent [new Agent/UDP]
$sourceAgent set fid_ 1
$ns attach-agent $nsource $sourceAgent

set destAgent [new Agent/Null]
$ns attach-agent $ndest $destAgent
$ns connect $sourceAgent $destAgent

#ON/OFF Traffic
set onOffTraffic [new Application/Traffic/Exponential]
$onOffTraffic set packetSize_ $L
$onOffTraffic set rate_ $peakRate
$onOffTraffic set burst_time_ 1ms
$onOffTraffic set idle_time_ $Toff
$onOffTraffic attach-agent $sourceAgent

#CALCULATIONS

#loss rate
set nbemissions 0
set nblosses 0
set lossRate 0

#total number of customers in the system
set packsInSys 0
set sumPacks 0
set lastModif 0

#packets being serviced
set inService 0 
set sumServ 0
set lastServ 0

#throughput 
set received 0
set throughput 0

#time 
array set eventTimes {}
set avgTime 0

proc myproc { a } {
    global nbemissions nblosses lossRate
    global packsInSys sumPacks lastModif
    global inService sumServ lastServ
    global received throughput
    global eventTimes avgTime
    global ns

    set event [lindex $a 0]
    set packetID [lindex $a 11]
    set eventTime [lindex $a 1]

    #enqueue 
    if {$event == "+"} {
        set nbemissions [expr $nbemissions + 1]
        set lossRate [expr $nblosses * 1.0 / $nbemissions]
        set sumPacks [expr $sumPacks + [expr [$ns now] - $lastModif] * $packsInSys]
        set packsInSys [expr $packsInSys + 1]
        set lastModif [$ns now]
        set eventTimes($packetID) $eventTime
    }

    #drop 
    if {$event == "d"} {
        set nblosses [expr $nblosses + 1]
        set lossRate [expr $nblosses * 1.0 / $nbemissions]
        set sumPacks [expr $sumPacks + [expr [$ns now] - $lastModif] * $packsInSys]
        set packsInSys [expr $packsInSys - 1]
        set lastModif [$ns now]
        set eventTimes($packetID) 0
    }

    #dequeue 
    if {$event == "-"} {
        set sumServ [expr $sumServ + [expr [$ns now] - $lastServ] * $inService]
        set inService [expr $inService + 1]
        set lastServ [$ns now]
    }

    #receive
    if {$event == "r"} {
        set received [expr $received + 1]
        set sumPacks [expr $sumPacks + [expr [$ns now] - $lastModif] * $packsInSys]
        set sumServ [expr $sumServ + [expr [$ns now] - $lastServ] * $inService]
        set packsInSys [expr $packsInSys - 1]
        set inService [expr $inService - 1]
        set lastModif [$ns now]
        set lastServ [$ns now]
        set throughput [expr $received / [$ns now]]
        set eventTimes($packetID) [expr $eventTime - $eventTimes($packetID)]
        set avgTime [expr $avgTime + $eventTimes($packetID)]
    }
}

[$ns link $nsource $ndest] trace-callback $ns "myproc"

$ns at 0.0 "$onOffTraffic start"
$ns at 100.0 "$onOffTraffic stop"
$ns at 100.0 "finish"
$ns run