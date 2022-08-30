#DYNAMIC SOURCE ROUTING(DSR) PROTOCOL

#DEFINING OPTIONS
set val(chan) Channel/WirelessChannel ;     #CHANNEL TYPE
set val(prop) Propagation/TwoRayGround ;    #RADIO-PROPAGATION MODEL
set val(netif) Phy/WirelessPhy ;            #NETWORK INTERFACE TYPE
set val(mac) Mac/802_11 ;                   #MAC TYPE
set val(ifq) CMUPriQueue ;                  #INTERFACE QUEUE TYPE
set val(ll) LL ;                            #LINK LAYER TYPE
set val(ant) Antenna/OmniAntenna ;          #ANTENNA MODEL
set val(ifqlen) 50 ;                        #MAXIMUM PACKET IN ifq

#GETTING THE NUMBER OF NODES TO BE GENERATED FROM THE USER
puts "Enter the nodes to generate"
gets stdin MEE
puts "You entered the number of nodes as $MEE"
set val(nn) $MEE ;

#SETTING THE DSR PROTOCOL
set val(rp) DSR;

#BY CHANGING THE VALUE OF X AND Y, WE CAN GENERATE A DIFFERENT DISTANCE RANGE FOR THE NODE MOVEMENTS.
set val(x) 500 ; #X-DIMENSION OF TOPOGRAPHY
set val(y) 500 ; #Y-DIMENSION OF TOPOGRAPHY
set val(stop) 50 ; #TIME OF SIMULATION

#CREATING AN INSTANCE OF THE SIMULATOR
set ns [new Simulator]
set tracefd [open DSR.tr w]
set winFile [open DSR w]
set namtracefd [open DSR.nam w]
$ns trace-all $tracefd
$ns namtrace-all-wireless $namtracefd $val(x) $val(y)
$ns use-newtrace

#CREATING A TOPOLOGY OBJECT THAT KEEPS TRACK OF NUMBER OF ALL NODES WITHIN BOUNDARY
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

#CREATING "God (General Operations Director) is the object that is used to store global information about the state of the environment, network or nodes"
create-god $val(nn)

#CONFIGURING NODES
$ns node-config -adhocRouting $val(rp) \
 -llType $val(ll) \
 -macType $val(mac) \
 -ifqType $val(ifq) \
 -ifqLen $val(ifqlen) \
 -antType $val(ant) \
 -propType $val(prop) \
 -phyType $val(netif) \
 -channelType $val(chan) \
 -topoInstance $topo \
 -agentTrace ON \
 -routerTrace ON \
 -macTrace OFF \
 -movementTrace ON

#CREATING NODES
for {set i 0} {$i < $val(nn) } { incr i } \
{
set node_($i) [$ns node]
}

#ENABLING RANDOM MOTION OF NODES
for {set i 0} {$i < $val(nn) } { incr i } \
{
$node_($i) random-motion 1
$node_($i) start
}

#LABELLING THE NODES
$node_(0) label "Source"
$node_(2) label "Receiver"

#SETTING A TCP CONNECTION BETWEEN NODE_(0) AND NODE_(2)
set tcp [new Agent/TCP/Newreno]
$tcp set class_ 2
set sink [new Agent/TCPSink]
$ns attach-agent $node_(0) $tcp
$ns attach-agent $node_(2) $sink
$ns connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns at 10.0 "$ftp start"

# PRINTING WINDOW SIZE
proc plotWindow {tcpSource file} \
{
global ns
set time 0.01
set now [$ns now]
set cwnd [$tcpSource set cwnd_]
puts $file "$now $cwnd"
$ns at [expr $now+$time] "plotWindow $tcpSource $file"
}
$ns at 10.1 "plotWindow $tcp $winFile"

#DEFINING NODE INITIAL POSITION IN NAM
for {set i 0} {$i < $val(nn)} { incr i } \
{
$ns initial_node_pos $node_($i) 50
}

# TELLING THE NODES WHEN THE SIMULATION ENDS
for {set i 0} {$i < $val(nn) } { incr i } \
{
$ns at $val(stop) "$node_($i) reset";
}

#ENDING NAM
$ns at $val(stop) "$ns nam-end-wireless $val(stop)"
$ns at $val(stop) "stop"
$ns at 150.01 "puts \"end simulation\" ; $ns halt"
proc stop {} \
{
global ns tracefd namtracefd
 $ns flush-trace
 close $tracefd
 close $namtracefd
 exec nam DSR.nam &
 exit 0
}

#STARTING SIMULATION
$ns run
