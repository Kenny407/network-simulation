# network-simulation

This repository contains NS-2 simulations in language tickle (tcl). 
(Know anything related to NS-2?) Before you continue, you can learn more at [NS-2 wiki](https://www.isi.edu/nsnam/ns/)

The main purpose of this repo is to research how the different network queuing models at low-level work. 

With the help of NS-2 we can visualize and understand how packets are accepted or dropped, depending on several factors such as: Burstiness, the channel size (bandwidth), the queue size, and periods (depending on the model) and many more. 

After running each script, we can easily detect bottlenecks in the network, loss rates, that could occur in a real environment, with NS-2 we can also debug the loss of packets thanks to the visual graphs and controls over the simulation.

Also one thing to notice, we can receive a bursty traffic in one of our nodes, that could crash our entire architecture. We the implementation of this models, we can regulate and control the flow in the network. 

## Models

* ON/OFF model 

![ON/OFF](http://staff.um.edu.mt/jskl1/simweb/fig1.gif)

* Leaky bucket 

![Leaky bucket](https://www.researchgate.net/profile/Changcheng_Huang/publication/3642574/figure/fig1/AS:341751131852802@1458491227098/Equivalence-of-leaky-bucket-and-virtual-queue-in-terms-of-loss-rate.png)

* Hybrid of ON/OFF with Leaky Bucket
[_Picture pending_]
