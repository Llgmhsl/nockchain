/-  miner-node
=>
  |%
  ++  kick  |=(* ~)
  ++  main
    |=  [~ ~]
    ^-  (list move)
    :_  ~
    [%pass /init %arvo %e %init /miner [%miner %no]]~
    [%pass /connect %dumb %connect '192.168.124.103' 9650]~  # 主节点IP
    [%pass /register %dumb %poke /register [%register-miner 382x8BFuw5YDTMKgvaWwiyFmVhiJ2U5ZDNMY49hmiBFDQWdcQZkKEZpuL6iZW9uxH4Y2rj6htXyJvMFk1UXQiZaptKoAAx7DPZFmWKQ61DxKXmbjWK4dZjuZ
25Jb1W73mTaN]]~  # 矿工公钥
  --
|_  state=kernel-state:miner-node
++  poke-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip move _..main)
  ?+    sign-arvo  [~ +>.$]
      [%e %init %miner state=kernel-state:miner-node]
        ~&  [%miner-started state]
        [~ +>.$(..main state)]
      [%e %fact =cage]
        ~&  [%miner-event cage]
        [~ +>.$]
  ==
