/-  master-node
=>
  |%
  ++  kick  |=(* ~)
  ++  main
    |=  [~ ~]
    ^-  (list move)
    :_  ~
    [%pass /init %arvo %e %init /master [%master %yes]]~
    [%pass /difficulty-timer %arvo %b %wait (add ~s60 (now))]~
  --
|_  state=kernel-state:master-node
  
  ++  poke-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip move _..main)
    ?+    sign-arvo  [~ +>.$]
        [%e %init %master state=kernel-state:master-node]
          ~&  [%master-started state]
          [~ +>.$(..main state)]
        
        [%b %wake ~]  :: 难度调整定时器
          :_  +>.$
          [%pass /difficulty-adjust %poke /miner [%adjust-difficulty (now)]]~
          [%pass /difficulty-timer %arvo %b %wait (add ~s60 (now))]~
        
        [%d %connect ~]  :: 矿工连接
          ~&  [%miner-connected wire]
          [~ +>.$]
    ==
  
  ++  poke-miner
    |=  [dat=*]
    =/  cause  ((soft cause) dat)
    ?~  cause  [~ +>.$]
    ?-  -.u.cause
      %hash-report
        =/  miner-id  !>(miner-id.u.cause)
        =/  new-total  (add total-hash.state hashes.u.cause)
        :_  state(total-hash new-total)
        [~ +>.$]
    ==
--
