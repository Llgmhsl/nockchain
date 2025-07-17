/-  mine  /common/pow
/-  sp  /common/stark/prover
/-  *  /common/zoon
/=  *  /common/zeke
/=  *  /common/wrapper
=<  ((moat |) inner)
=>
  |%
  +$  mine-success
    $:  %command
        %pow
        =proof
        dig=tip5-hash-atom
        header=noun-digest:tip5
        nonce=noun-digest:tip5
    ==
  +$  effect  
    $%  [%mine-result (each [hash=noun-digest:tip5 mine-success] dig=noun-digest:tip5)]
        [%send wire=wire data=*] 
        [%log message=@t]
        [%reward miner-id=@ud]
        [%fork cord=@t vase=vase]
    ==
  +$  kernel-state  
    $:  %state
        version=%1
        miners=(map @ud miner-info)
        current-header=noun-digest:tip5
        current-target=bignum:bignum
        master=? 
        master-wire=wire
        mining-thread=?
        last-adjust=@da
        total-hash=@ud
    ==
  +$  miner-info
    $:  wire=wire
        pubkey=@ux
        hash-rate=@ud
    ==
  +$  cause  
    $%  [%0 header=noun-digest:tip5 nonce=noun-digest:tip5 target=bignum:bignum pow-len=@]
        [%new-block header=noun-digest:tip5]
        [%register-miner pubkey=@ux]
        [%submit-nonce miner-id=@ud nonce=@]
        [%new-header header=noun-digest:tip5 target=bignum:bignum]
        [%adjust-difficulty now=@da]
    ==
  --
|%
++  moat  (keep kernel-state)
++  inner
  |_  k=kernel-state
  
  ++  load
    |=  =kernel-state  kernel-state
  
  ++  peek
    |=  arg=*
    =/  pax  ((soft path) arg)
    ?~  pax  ~|(not-a-path+arg !!)
    ?+    pax  ~|(invalid-peek+pax !!)
        [%x %miners %status ~]  `[[%miners (lent miners.k)]~]
        [%x %hash-rate ~]       `[%hash-rate total-hash.k]~
    ==
  
  ++  poke
    |=  [wir=wire eny=@ our=@ux now=@da dat=*]
    ^-  [(list effect) k=kernel-state]
    =/  cause  ((soft cause) dat)
    ?~  cause
      ~>  %slog.[0 [%leaf "error: bad cause: {<dat>}"]]
      `k
    =/  cause  u.cause
    ?+    -.cause  `k
        %new-block
          =/  new-k  k(current-header header.cause, last-adjust now)
          =/  effects
            %-  %~  roll  miners.k
            |=  [id=@ud info=miner-info]
            [%send wire.info [%new-header header.cause current-target.k]]~
          :_  new-k
          [[%log "Broadcast new header to {<(lent miners.k)>} miners"] effects]
        
        %register-miner
          =/  new-id  (add 1 (lent miners.k))
          =/  new-miners  (~(put by miners.k) new-id [wir pubkey.cause 0])
          :_  k(miners new-miners)
          [[%log "Miner registered: ID={new-id}"]~]
        
        %submit-nonce
          =/  input=prover-input:sp  [%0 current-header.k nonce.cause pow-len:mine]
          =/  [prf=proof:sp dig=tip5-hash-atom]  (prove-block-inner:mine input)
          ?.  (check-target:mine dig current-target.k)
            :_  k
            [[%log "Rejected nonce from miner {miner-id.cause}"]~]
          =/  reward-effect  [%reward miner-id.cause]
          :_  k
          [[%log "Block mined by miner {miner-id.cause}"] reward-effect]
        
        %new-header
          ?:  mining-thread.k
            :_  k(mining-thread %.n)
            [[%fork %stop-mining ~]~]
          =/  task  [%0 header.cause 0 target.cause pow-len:mine]
          :_  k(current-header header.cause, current-target target.cause, mining-thread %.y)
          [[%fork %mining-thread !>(task)]~]
        
        %adjust-difficulty
          =/  time-diff  (sub now last-adjust.k)
          =/  target-hashrate  (div (mul total-hash.k 60) time-diff)  ;; 期望60秒出块
          =/  new-target  (div (mul current-target.k target-hashrate) ideal-hashrate)
          :_  k(current-target new-target, last-adjust now, total-hash 0)
          [[%log "Difficulty adjusted: {<new-target>}"]~]
    ==
  
  ++  task
    |=  [=wire =cord =vase]
    ?+  cord  ~
        %mining-thread
          =/  task  !<  cause  vase
          ?-  -.task
            %0
              =/  start-time  (now)
              =/  hashes  0
              |-  ^-  (quip move _state)
              =/  nonce  nonce.task
              =/  input=prover-input:sp  [%0 header.task nonce pow-len.task]
              =/  [prf=proof:sp dig=tip5-hash-atom]  (prove-block-inner:mine input)
              ?:  (check-target:mine dig target.task)
                :_  ~
                [[%send master-wire.k [%submit-nonce [our.k nonce]]]~]
              :: 每100万次哈希报告一次
              ?:  =(0 (mod hashes 1.000.000))
                :_  ~
                [[%send master-wire.k [%hash-report +(hashes)]]~]
              $(nonce +(nonce), hashes +(hashes))
          ==
        %stop-mining  ~
    ==
--
