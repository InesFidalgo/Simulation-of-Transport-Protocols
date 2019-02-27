# Lê o argumento dado pelo utilizador que vai definir o tamanho da janela 

if {$argc == 4} {
    set useTCP [lindex $argv 0]
    set cenario [ lindex $argv 1 ]
    set janela [ lindex $argv 2 ]
    set quebra [ lindex $argv 3 ]
} else {
    puts "Por favor insira (1)protocolo a usar; (2)cenario a aplicar ; (3)janela do TCP; (4) com ou sem quebra
    exit 1
}

set ns [new Simulator]
$ns rtproto DV

set nf [open out.nam w]
$ns namtrace-all $nf

set nt [open out.tr w]
$ns trace-all $nt


proc fim {} {
    global ns nf nt
    $ns flush-trace
    close $nf
    close $nt
    exec nam out.nam
    exit 0
}

$ns color 1 Red
$ns color 2 Blue

#Fontes - Servidor A e B
set serverA [$ns node]
set serverB [$ns node]

#Routers
set n1 [$ns node]
set n2 [$ns node]
set n5 [$ns node]
set n6 [$ns node]

#Receptor
set receptor [$ns node]

$ns duplex-link $serverA $n1 100Mb 10ms DropTail #A-1
$ns duplex-link $n1 $n2 1Gb 10ms DropTail   	 #1-2
$ns duplex-link $n2 $receptor 10Mb 3ms DropTail  #2-Receptor
$ns duplex-link $serverB $n5 10Mb 10ms DropTail  #B-5
$ns duplex-link $n5 $n6 1Gb 10ms DropTail   	 #5-6
$ns duplex-link $n1 $n5 5Mb 10ms DropTail   	 #1-5
$ns duplex-link $n2 $n6 10Mb 10ms DropTail  	 #2-6

#Filas
#3Mb=3145728; 3145728 / 1000 bytes (pacotes por omissão) ~~ 3146
$ns queue-limit $serverA $n1 3146 
#if {$useTCP==0} {
#	$ns queue-limit $n2 $receptor 3517
#}
#Quebra
if {$quebra==1} { 
	$ns rtmodel-at 0.6 down $n1 $n2
	$ns rtmodel-at 0.7 up $n1 $n2
}
#Display
$ns duplex-link-op $serverA $n1 orient right
$ns duplex-link-op $n1 $n2 orient right
$ns duplex-link-op $n2 $receptor orient right
$ns duplex-link-op $n1 $n5 orient down
$ns duplex-link-op $n2 $n6 orient down
$ns duplex-link-op $serverB $n5 orient right
$ns duplex-link-op $n5 $n6 orient right

$ns at 0.0 "$serverA label ServerA"
$ns at 0.0 "$n1 label R1"
$ns at 0.0 "$n2 label R2"
$ns at 0.0 "$receptor label Receptor"
$ns at 0.0 "$serverB label ServerB"
$ns at 0.0 "$n5 label R5"
$ns at 0.0 "$n6 label R6"
$serverA color red
$serverA shape hexagon
$serverB color red
$serverB shape hexagon
$receptor color blue
$receptor shape square
#End Display

$ns duplex-link-op $serverA $n1 queuePos 0.5
$ns duplex-link-op $n1 $n2 queuePos 0.5
$ns duplex-link-op $n2 $receptor queuePos 0.5
$ns duplex-link-op $serverB $n5 queuePos 0.5
$ns duplex-link-op $n5 $n6 queuePos 0.5
$ns duplex-link-op $n1 $n5 queuePos 0.5
$ns duplex-link-op $n2 $n6 queuePos 0.5

#Cria um agente Null e liga-o ao nó receptor(Receptor)
set null0 [new Agent/Null]
$ns attach-agent $receptor $null0

#escolhemos colocar cada pacote com tamanho de 3MB » 3145728 bytes
set pacotes 3145728

#####LIGAÇÃO SERVER B -> RECEPTOR#####
if {$cenario==2} {
	#Cria um agente UDP e liga-o ao nó serverB
	set udp0 [new Agent/UDP]
	$ns attach-agent $serverB $udp0
	$udp0 set class_ 1

	#Cria uma fonte de tráfego CBR e liga-a ao udp0
	set cbr0 [new Application/Traffic/CBR]
	$cbr0 set rate_ 5Mb
	$cbr0 attach-agent $udp0

	$ns connect $udp0 $null0
}
#####FIM LIGAÇÃO SERVER B -> RECEPTOR#####

# se for para usar UDP
if {$useTCP==0} { 

        set udp1 [new Agent/UDP]
        $ns attach-agent $serverA $udp1
        
        #Cria uma fonte de tráfego CBR e liga-a ao udp2
        set cbr1 [new Application/Traffic/CBR]
        $cbr1 attach-agent $udp1
        #transmitir um pacote de 3 MB
        $cbr1 set packetSize_ $pacotes
	$cbr1 set maxpkts_ 1
        $ns connect $udp1 $null0

        $udp1 set class_ 2

# se for para usar TCP
} elseif {$useTCP==1} {

        set tcp [$ns create-connection TCP $serverA TCPSink $receptor 1]
            $tcp set window_ $janela
	
	$ns attach-agent $serverA $tcp
        set cbr1 [new Application/Traffic/CBR]
        ## queremos enviar um pacote de 3MB
        $cbr1 set packetSize_ $pacotes
        $cbr1 set maxpkts_ 1
        $cbr1 attach-agent $tcp
               
        #definir cor » vermelho
        $tcp set class_ 2
} else {
	puts "Erro"
}

if {$cenario==2} {
$ns at 0.5 "$cbr0 start"
$ns at 10.0 "$cbr0 stop"
}
$ns at 0.5 "$cbr1 start"
$ns at 10.0 "$cbr1 stop"
$ns at 10.0 "fim"
$ns run



