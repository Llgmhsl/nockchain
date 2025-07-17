/-  miner-node
=>
  |%
  ++  kick  |=(* ~)
  ++  main
    |=  [~ ~]
    ^-  (list move)
    :_  ~
    [%pass /init %arvo %e %init /miner [%miner %no]]~
    [%pass /connect %dumb %connect 'MASTER_IP' 9650]~  # 替换为主节点IP
    [%pass /register %dumb %poke /miner [%register-miner our]]~
  --
|_  state=kernel-state:miner-node
  
  ++  poke-arvo
    |=  [=wire =sign-arvo]
    ^-  (quip move _..main)
    ?+    sign-arvo  [~ +>.$]
        [%e %init %miner state=kernel-state:miner-node]
          ~&  [%miner-started state]
          [~ +>.$(..main state)]
        
        [%d %connect ~]  :: 连接主节点成功
          :_  state(master-wire wire)
          [~ +>.$]
    ==
--
